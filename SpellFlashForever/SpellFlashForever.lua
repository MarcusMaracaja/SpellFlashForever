-- SpellFlashForever
-- Adaptado do SpellFlash (WotLK 3.3.5, v5.65) para o WoW Forever (Interface 16001).
-- Fornece a funcionalidade core de flash de botoes de acao e API para modulos de classe.
-- Sem dependencias externas (usa apenas API nativa do WoW).

local addonName = "SpellFlashForever"
local addon = CreateFrame("Frame", addonName, UIParent)
_G[addonName] = addon

-- ---------------------------------------------------------------------------
-- SavedVariables
-- ---------------------------------------------------------------------------

SpellFlashForeverDB = SpellFlashForeverDB or {}
local db = SpellFlashForeverDB

if not db.handle then
    db.handle = {
        spell_flashing_off = nil,
        flash_size_percent = nil,
        flash_brightness_percent = nil,
        disable_macro_flashing = nil,
        suppress_range_check = nil,
        suppress_speed_check = nil,
        enable_blinking = nil,
        auto_mob_immune_detection_off = nil,
        use_all_class_modules = nil,
        selected_class_module = nil,
    }
end

local s = addon
s.Spam = {}
s.UpdatedVariables = {}
local SPELLDELAY = {}
local CLASS = select(2, UnitClass("player"))
local RACE = select(2, UnitRace("player")):upper():gsub("[^A-Z]", ""):gsub("^SCOURGE$", "UNDEAD")

-- Constantes
local DEFAULT_FLASH_SIZE_PERCENT = 240
local DEFAULT_FLASH_BRIGHTNESS_PERCENT = 100

local FLASH_SIZE_PERCENT = DEFAULT_FLASH_SIZE_PERCENT
local FLASH_BRIGHTNESS_PERCENT = DEFAULT_FLASH_BRIGHTNESS_PERCENT

-- Tabela de feitiços de GCD por classe (para detecção de alcance de corpo a corpo)
local MELEESPELL = {
    DEATHKNIGHT = 45902,
    DRUID = 1082,
    HUNTER = 2973,
    PALADIN = 35395,
    ROGUE = 1752,
    SHAMAN = 73899,
    WARRIOR = 78,
}

local GLOBALCOOLDOWNSPELL = {
    DEATHKNIGHT = 45902,
    DRUID = 5176,
    HUNTER = 883,
    MAGE = 133,
    PALADIN = 635,
    PRIEST = 585,
    ROGUE = 1752,
    SHAMAN = 403,
    WARLOCK = 686,
    WARRIOR = 772,
}

-- Dummies IDs
local DUMMY_ID_NUMBERS = {
    ["1921"] = "Combat Dummy",
    ["32542"] = "Disciple's Training Dummy",
    ["25297"] = "Drill Dummy",
    ["32546"] = "Ebon Knight's Training Dummy",
    ["17059"] = "Hellfire Combat Dummy",
    ["17060"] = "Hellfire Combat Dummy Small",
    ["17578"] = "Hellfire Training Dummy",
    ["32547"] = "Highlord's Nemesis Trainer",
    ["32541"] = "Initiate's Training Dummy",
    ["32545"] = "Initiate's Training Dummy",
    ["33229"] = "Melee Target",
    ["19139"] = "Nagrand Target Dummy",
    ["16211"] = "Naxxramas Combat Dummy",
    ["42328"] = "Practice Dummy",
    ["25225"] = "Practice Dummy",
    ["31146"] = "Raider's Training Dummy",
    ["18504"] = "Silvermoon Practice Dummy",
    ["43560"] = "Smilin' Timmy Sticks",
    ["4952"] = "Theramore Combat Dummy",
    ["38038"] = "Tiki Target",
    ["44171"] = "Training Dummy",
    ["48304"] = "Training Dummy",
    ["44937"] = "Training Dummy",
    ["44389"] = "Training Dummy",
    ["44614"] = "Training Dummy",
    ["44548"] = "Training Dummy",
    ["44703"] = "Training Dummy",
    ["44794"] = "Training Dummy",
    ["44820"] = "Training Dummy",
    ["44848"] = "Training Dummy",
    ["32666"] = "Training Dummy",
    ["32667"] = "Training Dummy",
    ["31144"] = "Training Dummy",
    ["46647"] = "Training Dummy",
    ["5652"] = "Undercity Practice Dummy",
    ["32543"] = "Veteran's Training Dummy",
}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- Cache de nome -> ID de spell, preenchido sempre que SpellName(id) é chamado com um número
local spellNameToID = {}
s.SpellNameToID = spellNameToID

local function SpellName(id, noSubName)
    if type(id) == "number" then
        local info = C_Spell and C_Spell.GetSpellInfo(id)
        if not info then return tostring(id) end
        local name = info.name
        spellNameToID[name] = id
        local subName = C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(id)
        if not noSubName and subName and subName ~= "" then
            return name .. "(" .. subName .. ")"
        end
        return name
    end
    return id
end

local function ItemName(id)
    if type(id) == "number" then
        return C_Item and C_Item.GetItemInfo(id)
    end
    return id
end

local function CopyTable(table)
    local t = {}
    if type(table) == "table" then
        for k, v in pairs(table) do t[k] = v end
    end
    return t
end

local function UnitIsDummy(unit)
    local guid = UnitGUID(unit)
    if not guid then return nil end
    local type = ({[0]="player", [3]="npc", [4]="pet", [5]="vehicle"})[tonumber(guid:sub(5,5), 16) % 8]
    if type == "npc" then
        local id = tonumber(guid:sub(7, 10), 16)
        if id then
            return DUMMY_ID_NUMBERS[tostring(id)]
        end
    end
    return nil
end

local function TargetOrFocus(unit)
    if unit then return unit end
    if IsModifiedClick and IsModifiedClick("FOCUSCAST") then return "focus" end
    return "target"
end

-- ---------------------------------------------------------------------------
-- Variaveis e configuracao
-- ---------------------------------------------------------------------------

local function CheckVariables()
    local player = UnitName("player")
    if not player then return end
    local realm = GetRealmName()
    local server = C_CVar and C_CVar.GetCVar("realmList") or (GetCVar and GetCVar("realmList")) or ""
    server = server:lower()

    if not db.SERVER then db.SERVER = {} end
    if not db.SERVER[server] then db.SERVER[server] = {} end
    if not db.SERVER[server].REALM then db.SERVER[server].REALM = {} end
    if not db.SERVER[server].REALM[realm] then db.SERVER[server].REALM[realm] = {} end
    if not db.SERVER[server].REALM[realm].PLAYER then db.SERVER[server].REALM[realm].PLAYER = {} end
    if not db.SERVER[server].REALM[realm].PLAYER[player] then db.SERVER[server].REALM[realm].PLAYER[player] = {} end
    if not db.SERVER[server].REALM[realm].PLAYER[player].MODULE then db.SERVER[server].REALM[realm].PLAYER[player].MODULE = {} end
    if not db.SERVER[server].Immune then db.SERVER[server].Immune = {} end
    if not db.SERVER[server].Immune[CLASS] then db.SERVER[server].Immune[CLASS] = {} end
    if not db.SERVER[server].ImmuneIgnore then db.SERVER[server].ImmuneIgnore = {} end

    FLASH_SIZE_PERCENT = db.SERVER[server].REALM[realm].PLAYER[player].flash_size_percent or DEFAULT_FLASH_SIZE_PERCENT
    FLASH_BRIGHTNESS_PERCENT = db.SERVER[server].REALM[realm].PLAYER[player].flash_brightness_percent or DEFAULT_FLASH_BRIGHTNESS_PERCENT
end

-- ---------------------------------------------------------------------------
-- Flash core (fallback nativo sem dependencias)
-- ---------------------------------------------------------------------------

local COLORTABLE = {
    white = {r=1, g=1, b=1},
    yellow = {r=1, g=1, b=0},
    purple = {r=1, g=0, b=1},
    blue = {r=0, g=0, b=1},
    orange = {r=1, g=0.5, b=0.25},
    aqua = {r=0, g=1, b=1},
    green = {r=0.1, g=1, b=0.1},
    red = {r=1, g=0.1, b=0.1},
    pink = {r=0.9, g=0.4, b=0.4},
    gray = {r=0.5, g=0.5, b=0.5},
}

local FlashOverlays = {}

-- Configuração (handle do SpellFlashForeverDB)
local function GetHandle()
    local db = _G.SpellFlashForeverDB
    if type(db) ~= "table" then return {} end
    if type(db.handle) ~= "table" then db.handle = {} end
    return db.handle
end

-- Modo de flash: "overlay" (estrela sobre o botão) ou "border" (contorno/borda).
local function ResolveFlashMode()
    return GetHandle().flash_mode == "border" and "border" or "overlay"
end

-- Se o modo "uma cor só" estiver ativo, ignora a cor passada e usa a do handle.
local function ResolveFlashColor(color)
    local cfg = GetHandle()
    if cfg.flash_single_color then
        local key = cfg.flash_single_color_color or "yellow"
        if COLORTABLE[key] then
            return key
        end
        return "yellow"
    end
    return color
end

local function FlashFrameOnUpdate(self, elapsed)
    self.TimeSinceLastUpdate = (self.TimeSinceLastUpdate or 0) + elapsed
    if self.TimeSinceLastUpdate >= (self.UpdateInterval or 0.02) then
        local delta = self.TimeSinceLastUpdate
        self.TimeSinceLastUpdate = 0
        if self.show then
            -- Se é modo sólido, mantenha o modificador em 1 (sem fade).
            if not self.Solid then
                self.modifier = (self.modifier or 1) - (self.modifier or 1) * delta * 2.0
            else
                self.modifier = 1
            end
            local alpha = self.FixedBrightness and self.FlashBrightness or (self.modifier * self.FlashBrightness)
            if self.modifier < 0.05 or alpha <= 0 then
                self.show = false
                self:SetAlpha(0)
                self:Hide()
            else
                local baseW = self.targetWidth or 36
                local baseH = self.targetHeight or 36
                local scale = self.FixedSize and self.FlashSize or (self.modifier * self.FlashSize)
                self.FlashTexture:SetHeight(math.max(8, baseH * scale))
                self.FlashTexture:SetWidth(math.max(8, baseW * scale))
                self.FlashTexture:SetAlpha(math.min(1, math.max(0, alpha)))
            end
        else
            self:Hide()
        end
    end
end

local function GetFlashOverlay(frame, mode)
    if not frame then return nil end
    local frameName = frame:GetName()
    if not frameName or frameName == "" then return nil end
    mode = (mode == "border") and "border" or "overlay"

    local key = frameName .. "::" .. mode
    if not FlashOverlays[key] then
        -- Criado como filho direto de UIParent para NUNCA poluir (taint) botões de ação seguros
        local ff = CreateFrame("Frame", "SFBF_Overlay_" .. frameName .. "_" .. mode, UIParent)
        ff:SetAllPoints(frame)
        ff:EnableMouse(false)
        ff:SetFrameStrata("HIGH")
        ff:SetFrameLevel(math.max(1, (frame:GetFrameLevel() or 10) + 5))
        ff:SetAlpha(0)
        ff.FlashTexture = ff:CreateTexture(nil, "OVERLAY")
        if mode == "border" then
            ff.FlashTexture:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            ff.FlashTexture:SetAllPoints(ff)
        else
            ff.FlashTexture:SetTexture("Interface\\Cooldown\\star4")
            ff.FlashTexture:SetPoint("CENTER", ff, "CENTER")
        end
        ff.FlashTexture:SetBlendMode("ADD")
        ff.UpdateInterval = 0.02
        ff.TimeSinceLastUpdate = 0
        ff:SetScript("OnUpdate", FlashFrameOnUpdate)
        FlashOverlays[key] = ff
    end

    local ff = FlashOverlays[key]
    ff.targetWidth = frame:GetWidth() or 36
    ff.targetHeight = frame:GetHeight() or 36
    return ff
end

-- `slot` é opcional: quando informado (veio da busca por slot na barra), o
-- KeyButton usa para montar o tooltip e como reserva na resolução da tecla.
local function FlashFrame(frame, color, size, brightness, blink, texture, fixedSize, fixedBrightness, slot)
    if not frame or not frame:IsVisible() then return false end

    -- Resolve modo de flash e cor única (painel Geral)
    local cfg = GetHandle()
    local mode = ResolveFlashMode()
    color = ResolveFlashColor(color)
    if cfg.flash_solid then
        fixedBrightness = true
    end
    if mode == "border" then
        fixedSize = true
    end

    local ff = GetFlashOverlay(frame, mode)
    if not ff then return false end

    ff.FlashModifier = 1
    ff.modifier = 1
    ff.FixedSize = fixedSize or false
    -- No modo borda o tamanho é sempre o do botão, independente do percentual
    ff.FlashSize = (mode == "border") and 1 or ((size or FLASH_SIZE_PERCENT or 240) / 100)
    ff.FixedBrightness = fixedBrightness or false
    ff.Solid = not not cfg.flash_solid
    ff.FlashBrightness = (brightness or FLASH_BRIGHTNESS_PERCENT or 100) / 100

    local w = ff.targetWidth or 36
    local h = ff.targetHeight or 36
    if w <= 0 then w = 36 end
    if h <= 0 then h = 36 end

    ff.FlashTexture:SetHeight(h * ff.FlashSize)
    ff.FlashTexture:SetWidth(w * ff.FlashSize)
    ff.FlashTexture:SetAlpha(math.min(1, 1 * ff.FlashBrightness))
    if type(color) == "table" then
        ff.FlashTexture:SetVertexColor(color.r or 1, color.g or 1, color.b or 1)
    elseif type(color) == "string" then
        local c = COLORTABLE[color:lower()]
        if c then
            ff.FlashTexture:SetVertexColor(c.r or 1, c.g or 1, c.b or 1)
        else
            ff.FlashTexture:SetVertexColor(1, 1, 1)
        end
    else
        ff.FlashTexture:SetVertexColor(1, 1, 1)
    end
    ff:SetAlpha(1)
    ff.show = true
    ff:Show()

    -- Avisa os interested parties (ex.: KeyButton) que um botão ACENDEU.
    -- O hook só recebe o frame e o slot: nada do SecureActionButton é lido
    -- aqui, para não contaminar (taint) o botão seguro.
    if s.OnFlash then
        local ok, err = pcall(s.OnFlash, frame, slot)
        if not ok and s.DebugFlash then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SF DEBUG]|r Erro no OnFlash: " .. tostring(err))
        end
    end

    return true
end

s.FlashFrame = FlashFrame

-- Remove o sufixo de grau/rank/rango do fim do nome, preservando o resto.
-- Ex: "Marca do Caçador(Grau 1)" -> "Marca do Caçador"
-- Usa %b() (parênteses balanceados) em vez de um padrão manual: funciona
-- igual em qualquer idioma, pois não depende do texto "Grau"/"Rank".
local function StripRank(name)
    if type(name) ~= "string" then return "" end
    name = name:gsub("%s*%b()%s*$", "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    return name
end

local function NormalizeSpellName(name)
    return StripRank(name):lower()
end

-- ID numérico vindo de GetActionInfo (alguns clientes devolvem string).
local function ToActionID(id)
    if type(id) == "number" then return id end
    if type(id) == "string" then return tonumber(id) end
    return nil
end

-- Procura por nome (com normalização de grau) -- fallback para compatibilidade
local function FindActionButtonByName(spellName)
    if not spellName then return nil end
    local normalized = NormalizeSpellName(spellName)
    if normalized == "" then return nil end
    for i = 1, 180 do
        local actionType, id = GetActionInfo(i)
        if actionType == "spell" then
            local name = SpellName(ToActionID(id) or id)
            if NormalizeSpellName(name) == normalized then return i end
        elseif actionType == "item" then
            local name = ItemName(ToActionID(id) or id)
            if NormalizeSpellName(name) == normalized then return i end
        elseif actionType == "macro" then
            local mName = GetActionText and GetActionText(i)
            if NormalizeSpellName(mName) == normalized then return i end
        end
    end
    return nil
end

-- A spell vinculada ao macro (GetMacroSpell devolve ID ou nome, conforme o
-- cliente). Aceita os dois formatos.
local function MacroSpellMatches(getter, macroIndex, spellID, targetName)
    if type(getter) ~= "function" then return false end
    local ok, value = pcall(getter, macroIndex)
    if not ok or value == nil then return false end
    local valueID = ToActionID(value)
    if valueID and valueID == spellID then return true end
    if type(value) == "string" and targetName ~= ""
        and NormalizeSpellName(value) == targetName then
        return true
    end
    return false
end

-- Slot da ação de ataque automático ("Atacar"). No Forever a API oficial é
-- C_ActionBar.IsAttackAction(actionID) (confirmado no binário); o global
-- nunca existiu. GetActionInfo(slot) devolve "attack" como fallback.
local IsAttackAction = (C_ActionBar and C_ActionBar.IsAttackAction) or IsAttackAction

local function FindAttackActionSlot()
    if type(IsAttackAction) == "function" then
        for i = 1, 180 do
            local ok, isAttack = pcall(IsAttackAction, i)
            if ok and isAttack == true then return i end
        end
    end
    if type(GetActionInfo) == "function" then
        for i = 1, 180 do
            local ok, actionType = pcall(GetActionInfo, i)
            if ok and actionType == "attack" then return i end
        end
    end
    return nil
end

-- Procura por ID numérico do spell -- profissional: funciona em qualquer idioma, qualquer grau
local function FindActionButtonByID(spellID)
    if not spellID or type(spellID) ~= "number" then return nil end

    -- 0) Ataque automático (6603): ação especial, não é um slot "spell" comum.
    if spellID == 6603 then
        local attackSlot = FindAttackActionSlot()
        if attackSlot then return attackSlot end
    end

    local targetName = NormalizeSpellName(SpellName(spellID))
    local spellIDText = tostring(spellID)

    -- 1) Correspondência exata de ID (a barra guarda exatamente este rank).
    for i = 1, 180 do
        local actionType, id = GetActionInfo(i)
        if actionType == "spell" and ToActionID(id) == spellID then return i end
    end

    -- 2) Fallback por nome-base normalizado: a barra pode guardar OUTRO rank
    --    da mesma spell (ex.: Serpent Sting 25295 no lugar de 1978). O nome
    --    base é igual entre os ranks e vem no idioma do cliente, então a
    --    comparação continua funcionando em qualquer locale.
    if targetName ~= "" then
        for i = 1, 180 do
            local actionType, id = GetActionInfo(i)
            if actionType == "spell" then
                local name = SpellName(ToActionID(id) or id)
                if NormalizeSpellName(name) == targetName then return i end
            end
        end
    end

    -- 3) Macros: nome do macro, spell vinculada ou corpo do macro.
    --    No Forever um slot de macro devolve type="macro" e id=índice do macro;
    --    a spell em si não aparece no GetActionInfo, então precisa deste passo.
    for i = 1, 180 do
        local actionType, id = GetActionInfo(i)
        if actionType == "macro" then
            local macroIndex = ToActionID(id)
            local macroName = GetActionText and GetActionText(i)

            if targetName ~= "" and type(macroName) == "string"
                and NormalizeSpellName(macroName) == targetName then
                return i
            end

            if macroIndex then
                if MacroSpellMatches(GetMacroSpell, macroIndex, spellID, targetName) then
                    return i
                end
                if C_Macro and MacroSpellMatches(C_Macro.GetMacroSpell, macroIndex, spellID, targetName) then
                    return i
                end

                if GetMacroBody then
                    local ok, body = pcall(GetMacroBody, macroIndex)
                    if not ok or type(body) ~= "string" then body = nil end
                    if not body and type(macroName) == "string" then
                        local ok2, body2 = pcall(GetMacroBody, macroName)
                        if ok2 and type(body2) == "string" then body = body2 end
                    end
                    if body then
                        local lower = body:lower()
                        -- ID como token inteiro (evita casar 1130 dentro de 11305).
                        local idPattern = "%f[%d]" .. spellIDText .. "%f[%D]"
                        if (targetName ~= "" and lower:find(targetName, 1, true))
                            or lower:find(idPattern) then
                            return i
                        end
                    end
                end
            end
        end
    end

    return nil
end

-- Cache de slot por spellID. Invalidado quando a barra muda, para não varrer
-- 180 slots a cada ciclo do Spam (o Spam roda várias vezes por segundo).
local actionSlotCache = {}
do
    local cacheFrame = CreateFrame("Frame")
    cacheFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    cacheFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    cacheFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    cacheFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    cacheFrame:SetScript("OnEvent", function() wipe(actionSlotCache) end)
end

--- Slot da barra de ação que contém a spell (qualquer rank ou macro dela).
--- Usado para o alcance via IsActionInRange: o cliente responde pelo que está
--- REALMENTE na barra, sem depender de ID/rank (que no Forever pode devolver
--- resposta errada em C_Spell.IsSpellInRange).
--- @param spellID number
--- @return number|nil
function s.FindActionSlot(spellID)
    if type(spellID) ~= "number" then return nil end

    local cached = actionSlotCache[spellID]
    if cached ~= nil then
        return cached or nil
    end

    local slot = FindActionButtonByID(spellID) or FindActionButtonByName(SpellName(spellID))
    actionSlotCache[spellID] = slot or false
    return slot
end

-- Diagnóstico: lista, uma única vez por sessão, os slots ocupados da barra.
-- Ajuda a descobrir se a spell está como spell, macro, item etc. quando o
-- slot não é encontrado.
local dumpedActionSlots = false
local lastMissingPrint = {}

local function DumpActionSlots()
    if dumpedActionSlots then return end
    dumpedActionSlots = true

    local parts = {}
    for i = 1, 180 do
        local actionType, id = GetActionInfo(i)
        if actionType then
            local label = i .. "=" .. tostring(actionType) .. ":" .. tostring(id)
            if actionType == "spell" then
                label = label .. ":" .. tostring(SpellName(ToActionID(id) or id))
            elseif actionType == "macro" then
                label = label .. ":" .. tostring(GetActionText and GetActionText(i))
            end
            parts[#parts + 1] = label
            if #parts >= 30 then
                parts[#parts + 1] = "..."
                break
            end
        end
    end

    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SF DEBUG]|r Slots ocupados: " .. table.concat(parts, " | "))
    end
end

local function PrintMissingSlot(spellName)
    if not s.DebugFlash then return end
    local key = tostring(spellName)
    local now = GetTime()
    local last = lastMissingPrint[key]
    if last and now - last < 5 then return end
    lastMissingPrint[key] = now
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SF DEBUG]|r Nenhum slot na barra de ação encontrado para '" .. key .. "'.")
    end
    DumpActionSlots()
end

function s.FlashAction(spellName, color, size, brightness, blink, noMacros, texture, fixedSize, fixedBrightness)
    if db.handle and db.handle.spell_flashing_off then return end

    -- Sistema autônomo com overlays no UIParent (100% livre de taint e Action Blocked)
    if type(spellName) == "table" then
        for _, name in ipairs(spellName) do
            s.FlashAction(name, color, size, brightness, blink, noMacros, texture, fixedSize, fixedBrightness)
        end
        return
    end
    if not spellName then return end

    -- Determinar se é ID numérico ou nome
    local isID = type(spellName) == "number"
    local spellID = isID and spellName or nil
    local name = isID and SpellName(spellName) or spellName
    if not name or name == "" then return end

    -- Procurar slot na barra: prioridade para ID (profissional, idioma-independente).
    -- Se o ID não achar (rank diferente, macro, etc.), cai no nome normalizado.
    local slot
    if spellID then
        slot = FindActionButtonByID(spellID)
        if not slot then
            slot = FindActionButtonByName(name)
        end
    else
        slot = FindActionButtonByName(name)
    end

    if slot then
        local barNames = {
            "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
            "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button"
        }
        local found = false
        for _, bar in ipairs(barNames) do
            for i = 1, 12 do
                local b = _G[bar .. i]
                if b and b:IsVisible() then
                    local bAction = b.action
                    if not bAction and b.GetPagedID then
                        local ok, id = pcall(b.GetPagedID, b)
                        if ok then bAction = id end
                    end
                    if ToActionID(bAction) == slot then
                        local flashed = FlashFrame(b, color, size, brightness, blink, texture, fixedSize, fixedBrightness, slot)
                        if flashed then
                            found = true
                        end
                    end
                end
            end
        end
        if not found and s.DebugFlash then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SF DEBUG]|r Slot " .. slot .. " encontrado para '" .. name .. "' mas nenhum botão de barra corresponde.")
        end
    else
        PrintMissingSlot(name)
    end
end

function s.FlashItem(itemName, color, size, brightness, blink, noMacros, texture, fixedSize, fixedBrightness)
    s.FlashAction(itemName, color, size, brightness, blink, noMacros, texture, fixedSize, fixedBrightness)
end

-- ---------------------------------------------------------------------------
-- API pública (estilo SpellFlash)
-- ---------------------------------------------------------------------------

function s.SpellName(id, noSubName)
    return SpellName(id, noSubName)
end

function s.ItemName(id)
    return ItemName(id)
end

function s.HasSpell(spellName)
    local name = SpellName(spellName)
    if type(name) ~= "string" or name == "" then return false end

    -- Se temos o ID em cache (SpellName foi chamado antes com esse ID numérico),
    -- verifique se o player conhece o feitiço. Usa s.IsSpellKnown (Compat.lua),
    -- que entende famílias de rank do Forever.
    local spellID = spellNameToID[name]
    if spellID then
        if s.IsSpellKnown then
            return s.IsSpellKnown(spellID)
        end
        -- Tentar C_SpellBook.IsSpellKnown primeiro
        if C_SpellBook and C_SpellBook.IsSpellKnown then
            local ok, result = pcall(function() return C_SpellBook.IsSpellKnown(spellID) end)
            if ok then return result end
        end
        -- Fallback: C_Spell.GetSpellInfo retorna info se o spell existe no client
        if C_Spell and C_Spell.GetSpellInfo then
            local ok, info = pcall(function() return C_Spell.GetSpellInfo(spellID) end)
            if ok and info ~= nil then return true end
        end
        -- Se chegou aqui, assumir que é conhecido (está na barra de ação)
        return true
    end

    -- Fallback para clients antigos onde GetSpellInfo aceita nome
    if GetSpellInfo then
        local ok, result = pcall(function() return GetSpellInfo(name) end)
        if ok and result ~= nil then return true end
    end

    return false
end

function s.HasItem(itemName)
    local name = ItemName(itemName)
    return type(name) == "string" and name ~= "" and (C_Item.GetItemCount and C_Item.GetItemCount(name) or GetItemCount(name)) > 0
end

-- Normaliza a resposta nativa de alcance: true (dentro), false (fora),
-- nil (desconhecido/segredo). No Forever C_Spell.IsSpellInRange devolve
-- BOOLEANO (o Hekili compara com == true); a API global antiga devolvia
-- 1/0/nil. As duas formas são aceitas.
local function RangeAnswer(result)
    if result == nil then return nil end
    local issecret = _G.issecretvalue
    if issecret and issecret(result) then return nil end
    if result == true or result == 1 then return true end
    if result == false or result == 0 then return false end
    return nil
end

--- Resposta estrita de alcance: true/false/nil (sem converter nil em
--- "em alcance"). Usada por sondagens de melee, onde um nil NÃO pode ser
--- interpretado como positivo (senão todo alvo pareceria corpo a corpo).
function s.IsSpellInRangeEx(spellName, unit)
    local target = TargetOrFocus(unit)

    local spellID, base
    if type(spellName) == "number" then
        spellID = spellName
        base = SpellName(spellName, true)
    else
        base = StripRank(tostring(spellName))
        spellID = spellNameToID[tostring(spellName)] or spellNameToID[base]
    end

    local function ByID(id)
        if not id or not C_Spell or type(C_Spell.IsSpellInRange) ~= "function" then return nil end
        local ok, result = pcall(C_Spell.IsSpellInRange, id, target)
        if not ok then return nil end
        return RangeAnswer(result)
    end

    local function ByName(name)
        if type(name) ~= "string" or name == "" or not C_Spell or type(C_Spell.IsSpellInRange) ~= "function" then
            return nil
        end
        local ok, result = pcall(C_Spell.IsSpellInRange, name, target)
        if not ok then return nil end
        return RangeAnswer(result)
    end

    local answer
    if type(spellName) == "number" then
        -- ID primeiro (rank exato); se não responder, tenta o nome-base.
        answer = ByID(spellID)
        if answer == nil then answer = ByName(base) end
    else
        -- Só a forma por nome: o cliente resolve o rank conhecido sozinho.
        -- NÃO cair para o ID em cache aqui — ele pode ser de outro rank e
        -- devolver resposta errada no Forever (foi o bug do melee a 30 yd).
        answer = ByName(base)
    end
    if answer ~= nil then return answer end

    -- API global legada (1/0/nil), se existir no cliente.
    if type(IsSpellInRange) == "function" and base and base ~= "" then
        local ok, result = pcall(IsSpellInRange, base, target)
        if ok then
            local legacy = RangeAnswer(result)
            if legacy ~= nil then return legacy end
        end
    end

    return nil
end

function s.IsSpellInRange(spellName, unit)
    local answer = s.IsSpellInRangeEx(spellName, unit)
    if answer == nil then return 1 end -- desconhecido = em alcance (padrão Hekili)
    return answer and 1 or 0
end

function s.IsUsableSpell(spellName)
    local name = SpellName(spellName)
    if not name then return false end
    return IsUsableSpell and IsUsableSpell(name) or false
end

function s.IsCurrentSpell(spellName)
    local name = SpellName(spellName)
    if not name then return false end
    return IsCurrentSpell and IsCurrentSpell(name) or false
end

function s.InCombat()
    return not not InCombatLockdown()
end

-- Leitura segura de números secretos (UnitHealth/UnitPower/GetSpellCooldown etc.).
-- Neste cliente a leitura pode vir *secret* com a execução marcada (tainted):
-- comparar/aritmetizar num secret estoura erro. Aqui tudo vira pcall +
-- issecretvalue; quando ilegível, devolve `fallback` (fail-safe do chamador).
local function SafeNumber(fn, fallback)
    local ok, v = pcall(fn)
    if not ok then return fallback end
    if _G.issecretvalue and issecretvalue(v) then return fallback end
    if type(v) ~= "number" then return fallback end
    return v
end

function s.Health(unit)
    local u = TargetOrFocus(unit)
    return SafeNumber(function() return UnitHealth(u) end, nil)
end

function s.MaxHealth(unit)
    local u = TargetOrFocus(unit)
    return SafeNumber(function() return UnitHealthMax(u) end, nil)
end

function s.HealthPercent(unit)
    local u = TargetOrFocus(unit)
    -- Ilegível (secret/tainted): assume cheio (100) para não disparar "vida baixa" indevida.
    local h = SafeNumber(function() return UnitHealth(u) end, nil)
    local m = SafeNumber(function() return UnitHealthMax(u) end, nil)
    if not h or not m or m == 0 then return 100 end
    return (h / m) * 100
end

function s.Power(unit, powerType)
    local u = TargetOrFocus(unit)
    return SafeNumber(function() return UnitPower(u, powerType) end, nil)
end

function s.MaxPower(unit, powerType)
    local u = TargetOrFocus(unit)
    return SafeNumber(function() return UnitPowerMax(u, powerType) end, nil)
end

function s.PowerPercent(unit, powerType)
    local u = TargetOrFocus(unit)
    local p = SafeNumber(function() return UnitPower(u, powerType) end, nil)
    local m = SafeNumber(function() return UnitPowerMax(u, powerType) end, nil)
    if not p or not m or m == 0 then return 100 end
    return (p / m) * 100
end

function s.CastingTime(spellName)
    local name = SpellName(spellName)
    if not name then return 0 end
    local spellID = spellNameToID[name] or (type(spellName) == "number" and spellName)
    if spellID and C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and info then
            local ct = SafeNumber(function() return info.castTime end, 0) or 0
            return ct / 1000
        end
        return 0
    end
    -- fallback global
    if type(GetSpellInfo) == "function" then
        local ok, _, _, _, _, _, castTime = pcall(GetSpellInfo, name)
        local ct = SafeNumber(function() return castTime end, 0) or 0
        return ct / 1000
    end
    return 0
end

function s.SpellCooldown(spellName)
    if not spellName then return nil end
    local name = SpellName(spellName)
    -- Sempre resolve para o rank conhecido (o cliente não devolve CD para rank desconhecido)
    local rawID = spellNameToID[name]
    if not rawID and type(spellName) == "number" then
        rawID = spellName
    end
    local spellID = s.ResolveKnownID and s.ResolveKnownID(rawID) or rawID
    if spellID and C_Spell and C_Spell.GetSpellCooldown then
        local ok, info = pcall(C_Spell.GetSpellCooldown, spellID)
        if ok and type(info) == "table" then
            -- Este cliente usa nomes de campo variados no spellCooldownInfo:
            -- aceita startTime OU cooldownStartTime por segurança.
            local start = SafeNumber(function() return info.startTime end, nil)
                or SafeNumber(function() return info.cooldownStartTime end, nil)
                or 0
            local duration = SafeNumber(function() return info.duration end, nil)
                or SafeNumber(function() return info.cooldownDuration end, nil)
                or 0
            local isActive = info.isActive == true
            local now = SafeNumber(function() return GetTime() end, 0) or 0
            -- timeUntilEndOfStartRecovery é o restante computado pelo cliente — autoritativo,
            -- independente do relógio. Use-o quando existir; senão calcula pelo start.
            local remaining = SafeNumber(function() return info.timeUntilEndOfStartRecovery end, nil)
            -- nunca devolver duration <= 1.5: a verificação da rotação trata cooldown curto
            -- como GCD e libera o cast; o CD real é longo neste cliente.
            if remaining ~= nil and remaining > 0 then
                return remaining, math.max(1.6, duration > 0 and duration or 1.6)
            end
            local timeLeft = start + duration - now
            if isActive and timeLeft <= 0 then
                timeLeft = (duration > 0 and math.max(1.6, duration)) or 5
            end
            if timeLeft > 0 then
                if duration <= 1.5 then duration = 1.6 end
                return timeLeft, duration
            end
            -- Se não tem start, mas tem duração > 1.5, pode ser CD em andamento longo não datado
            if duration > 1.5 and (start == 0) then
                return duration, duration
            end
            return 0, 0
        end
    end
    -- fallback global (pode não existir no Forever)
    if type(GetSpellCooldown) == "function" then
        local ok, start, duration = pcall(GetSpellCooldown, name)
        if ok then
            start = SafeNumber(function() return start end, 0) or 0
            duration = SafeNumber(function() return duration end, 0) or 0
            local now = SafeNumber(function() return GetTime() end, 0) or 0
            local timeLeft = start + duration - now
            if timeLeft > 0 then return timeLeft, duration end
        end
    end
    return 0, 0
end

function s.ItemCooldown(itemName)
    if not itemName then return nil end
    local itemID = itemName
    if type(itemID) ~= "number" then
        if C_Item and type(C_Item.GetItemInfoInstant) == "function" then
            local ok, info = pcall(C_Item.GetItemInfoInstant, itemID)
            if ok and type(info) == "table" then itemID = info.itemID end
        end
        if type(itemID) ~= "number" and type(GetItemInfoInstant) == "function" then
            local ok, _, _, _, _, _, id = pcall(GetItemInfoInstant, itemID)
            if ok and type(id) == "number" then itemID = id end
        end
        if type(itemID) ~= "number" then
            -- itemID não resolvido: C_Item.GetItemCooldown abaixo decide (fail-safe 0,0)
            itemID = nil
        end
    end
    if itemID then
        if C_Item and C_Item.GetItemCooldown then
            local ok, start, duration = pcall(C_Item.GetItemCooldown, itemID)
            if ok and start then
                start = SafeNumber(function() return start end, 0) or 0
                duration = SafeNumber(function() return duration end, 0) or 0
                local now = SafeNumber(function() return GetTime() end, 0) or 0
                local timeLeft = start + duration - now
                if timeLeft > 0 then return timeLeft, duration end
            end
        end
        -- fallback global
        if type(GetItemCooldown) == "function" then
            local ok, s2, d2 = pcall(GetItemCooldown, itemID)
            if ok then
                s2 = SafeNumber(function() return s2 end, 0) or 0
                d2 = SafeNumber(function() return d2 end, 0) or 0
                local now = SafeNumber(function() return GetTime() end, 0) or 0
                local timeLeft = s2 + d2 - now
                if timeLeft > 0 then return timeLeft, d2 end
            end
        end
    end
    return 0, 0
end

function s.SpellDelay(spellName)
    local count = 0
    if type(spellName) == "table" then
        for _, v in ipairs(spellName) do
            count = count + (s.SpellDelay(v) or 0)
        end
    else
        local name = SpellName(spellName)
        if name then count = count + (SPELLDELAY[name] or 0) end
    end
    if count > 0 then return count end
    return nil
end

-- ---------------------------------------------------------------------------
-- Getters, Setters e Configurações Modulares
-- ---------------------------------------------------------------------------

function s.GetFlashSize()
    return FLASH_SIZE_PERCENT
end

function s.SetFlashSize(val)
    FLASH_SIZE_PERCENT = tonumber(val) or DEFAULT_FLASH_SIZE_PERCENT
    local player = UnitName("player")
    local realm = GetRealmName()
    local server = C_CVar and C_CVar.GetCVar("realmList") or (GetCVar and GetCVar("realmList")) or ""
    server = server:lower()
    if db.SERVER and db.SERVER[server] and db.SERVER[server].REALM and db.SERVER[server].REALM[realm] and db.SERVER[server].REALM[realm].PLAYER and db.SERVER[server].REALM[realm].PLAYER[player] then
        db.SERVER[server].REALM[realm].PLAYER[player].flash_size_percent = FLASH_SIZE_PERCENT
    end
end

function s.GetFlashBrightness()
    return FLASH_BRIGHTNESS_PERCENT
end

function s.SetFlashBrightness(val)
    FLASH_BRIGHTNESS_PERCENT = tonumber(val) or DEFAULT_FLASH_BRIGHTNESS_PERCENT
    local player = UnitName("player")
    local realm = GetRealmName()
    local server = C_CVar and C_CVar.GetCVar("realmList") or (GetCVar and GetCVar("realmList")) or ""
    server = server:lower()
    if db.SERVER and db.SERVER[server] and db.SERVER[server].REALM and db.SERVER[server].REALM[realm] and db.SERVER[server].REALM[realm].PLAYER and db.SERVER[server].REALM[realm].PLAYER[player] then
        db.SERVER[server].REALM[realm].PLAYER[player].flash_brightness_percent = FLASH_BRIGHTNESS_PERCENT
    end
end

function s.GetModuleConfig(moduleName, config)
    if not moduleName or moduleName == "" then return nil end
    local mod = moduleName:lower()
    if db.handle and db.handle.MODULE and db.handle.MODULE[mod] then
        return db.handle.MODULE[mod][config]
    end
    return nil
end

function s.SetModuleConfig(moduleName, config, value)
    if not moduleName or moduleName == "" then return end
    local mod = moduleName:lower()
    if not db.handle.MODULE then db.handle.MODULE = {} end
    if not db.handle.MODULE[mod] then db.handle.MODULE[mod] = {} end
    db.handle.MODULE[mod][config] = value
end

function s.ClearAllModuleConfigs(moduleName)
    if not moduleName or moduleName == "" then return end
    local mod = moduleName:lower()
    if db.handle.MODULE and db.handle.MODULE[mod] then
        db.handle.MODULE[mod] = {}
    end
end

function s.OpenOptions()
    if s.ToggleGUI then
        s.ToggleGUI()
        return
    end
    if s.MainGUI then
        s.MainGUI:Show()
        return
    end
    if s.SettingsCategoryID and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(s.SettingsCategoryID)
        return
    end
    if InterfaceOptionsFrame_OpenToCategory and _G["SpellFlashForeverOptionsPanel"] then
        InterfaceOptionsFrame_OpenToCategory(_G["SpellFlashForeverOptionsPanel"])
    end
end

-- ---------------------------------------------------------------------------
-- Eventos e inicializacao
-- ---------------------------------------------------------------------------

local initialized = false

addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("PLAYER_ENTERING_WORLD")
addon:RegisterEvent("ADDON_LOADED")

addon:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        CheckVariables()
    elseif event == "PLAYER_LOGIN" then
        CheckVariables()
        initialized = true

        -- Registra categoria principal no sistema de Settings moderno (Interface 16001)
        if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
            local panel = CreateFrame("Frame", "SpellFlashForeverOptionsPanel", UIParent)
            panel.name = "SpellFlashForever"
            local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
            s.SettingsCategory = category
            s.SettingsCategoryID = category and category:GetID() or nil
            s.SettingsCategoryObject = category
            if s.SettingsCategoryID then
                DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r Categoria registrada. ID: " .. s.SettingsCategoryID)
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000SpellFlashForever:|r ERRO: SettingsCategoryID é nil!")
            end
            Settings.RegisterAddOnCategory(category)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000SpellFlashForever:|r Settings API não disponível!")
        end

        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r carregado (Classe: " .. CLASS .. "). Digite |cffffcc00/sf|r para abrir o menu.")
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not initialized then
            CheckVariables()
            initialized = true
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r carregado (Classe: " .. CLASS .. "). Digite |cffffcc00/sf|r para abrir o menu.")
        end
    end
end)

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------

SLASH_SPELLFLASHFOREVER1 = "/sfbyferal"
SLASH_SPELLFLASHFOREVER2 = "/sflashbyferal"

SlashCmdList["SPELLFLASHFOREVER"] = function(msg)
    msg = msg and msg:lower() or ""
    local handle = db.handle

    if msg == "" or msg == "menu" or msg == "options" or msg == "config" then
        if s.ToggleGUI then
            s.ToggleGUI()
        elseif s.OpenOptions then
            s.OpenOptions()
        end
        return
    end

    if msg == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever|r comandos:")
        DEFAULT_CHAT_FRAME:AddMessage("  /sf ou /sfbyferal        - Abrir/fechar a janela visual de configurações")
        DEFAULT_CHAT_FRAME:AddMessage("  /sfbyferal flash <nome>  - Flashar um feitiço/item")
        DEFAULT_CHAT_FRAME:AddMessage("  /sfbyferal size <n>      - Tamanho do flash (atual: " .. FLASH_SIZE_PERCENT .. ")")
        DEFAULT_CHAT_FRAME:AddMessage("  /sfbyferal bright <n>    - Brilho do flash (atual: " .. FLASH_BRIGHTNESS_PERCENT .. ")")
        DEFAULT_CHAT_FRAME:AddMessage("  /sfbyferal off           - Desativar flash de feitiços")
        DEFAULT_CHAT_FRAME:AddMessage("  /sfbyferal on            - Ativar flash de feitiços")
        DEFAULT_CHAT_FRAME:AddMessage("  /sfbyferal status        - Mostrar status")
        DEFAULT_CHAT_FRAME:AddMessage("  /sfbyferal key [on|off]  - Botão que mostra a tecla da habilidade (use /sfkey)")
        return
    end

    if msg:match("^flash%s+(.+)$") then
        local name = msg:match("^flash%s+(.+)$")
        if handle.spell_flashing_off then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000SpellFlashForever:|r flash está desativado. Use /sfbyferal on")
            return
        end
        s.FlashAction(name, "yellow", 240, 100, true)
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r flashando: " .. name)
        return
    end

    if msg == "size" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r tamanho atual: " .. FLASH_SIZE_PERCENT)
        return
    end

    if msg:match("^size%s+(%d+)$") then
        FLASH_SIZE_PERCENT = tonumber(msg:match("^size%s+(%d+)$")) or DEFAULT_FLASH_SIZE_PERCENT
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r tamanho definido: " .. FLASH_SIZE_PERCENT)
        return
    end

    if msg:match("^bright%s+(%d+)$") then
        FLASH_BRIGHTNESS_PERCENT = tonumber(msg:match("^bright%s+(%d+)$")) or DEFAULT_FLASH_BRIGHTNESS_PERCENT
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r brilho definido: " .. FLASH_BRIGHTNESS_PERCENT)
        return
    end

    if msg == "off" then
        handle.spell_flashing_off = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r flash de feitiços desativado")
        return
    end

    if msg == "on" then
        handle.spell_flashing_off = nil
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r flash de feitiços ativado")
        return
    end

    if msg == "status" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r classe: " .. CLASS .. " | raca: " .. RACE)
        local hunterApi = _G["SpellFlash_Hunter"]
        local hunterRace = hunterApi and hunterApi.GetDetectedRace and hunterApi.GetDetectedRace()
        if hunterRace then
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r Hunter raça detectada: " .. tostring(hunterRace))
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r flash off: " .. tostring(handle.spell_flashing_off))
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r tamanho: " .. FLASH_SIZE_PERCENT .. " | brilho: " .. FLASH_BRIGHTNESS_PERCENT)
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r debug: " .. tostring(s.DebugFlash))
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r botão de tecla: " .. tostring(s.IsKeyButtonEnabled and s.IsKeyButtonEnabled()))
        return
    end

    -- Botão de tecla (atalho para /sfkey)
    if msg == "key" then
        if SlashCmdList["SPELLFLASHKEY"] then
            SlashCmdList["SPELLFLASHKEY"](nil)
        end
        return
    end

    if msg:match("^key%s+(.+)$") then
        if SlashCmdList["SPELLFLASHKEY"] then
            SlashCmdList["SPELLFLASHKEY"](msg:match("^key%s+(.+)$"))
        end
        return
    end

    if msg == "debug" then
        s.DebugFlash = not s.DebugFlash
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r debug " .. (s.DebugFlash and "ativado" or "desativado"))
        return
    end

    if msg == "traits" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r === C_Traits / C_ClassTalents ===")
        if C_Traits then
            local methods = {}
            for k, v in pairs(C_Traits) do
                if type(v) == "function" then table.insert(methods, k) end
            end
            table.sort(methods)
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r C_Traits: " .. table.concat(methods, ", "))
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000SpellFlashForever:|r C_Traits: nil")
        end
        if C_ClassTalents then
            local methods = {}
            for k, v in pairs(C_ClassTalents) do
                if type(v) == "function" then table.insert(methods, k) end
            end
            table.sort(methods)
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r C_ClassTalents: " .. table.concat(methods, ", "))
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000SpellFlashForever:|r C_ClassTalents: nil")
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r === fim ===")
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000SpellFlashForever:|r comando desconhecido: " .. msg .. ". Use /sfbyferal help")
end
