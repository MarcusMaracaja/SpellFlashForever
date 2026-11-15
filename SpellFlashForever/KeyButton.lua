-- SpellFlashForever / KeyButton.lua
-- Botão extra que mostra a tecla que deve ser apertada para a habilidade que
-- está brilhando na barra de ação.
--
-- PORTADO de: D:\wow lk\interface\addons\SpellFlashCore\KeyButton.lua (WotLK 3.3.5)
--
-- Adaptações necessárias para o WoW Forever (Interface 16001):
--   * Não existe SpellFlashCore no Forever: o hook é feito em s.FlashFrame
--     (motor próprio do SpellFlashForever) em vez de SpellFlashCore.FlashFrame.
--   * GetBindingKey(action) recebe o NOME da ação ("ACTIONBUTTON3") e não o
--     número do slot como no 3.3.5a. Os nomes por barra são os mesmos usados
--     pelo Hekili no Forever (Hekili/Engine/Sim/Events.lua): ACTIONBUTTON<n>,
--     MULTIACTIONBAR2BUTTON<n> ... MULTIACTIONBAR8BUTTON<n>.
--   * NUNCA lê button.action nem button._state_action: em SecureActionButton
--     esses campos são apontados como fonte de taint. A tecla é resolvida pelo
--     nome global do botão, pela FontString de hotkey e pela API de bindings,
--     sem tocar no botão seguro.
--   * GetSpellInfo/GetItemInfo/GetMacroInfo -> C_Spell/C_Item/C_Macro.
--   * Configuração em SpellFlashForeverDB.handle.key_button (o original usava
--     SpellFlashCoreAddonConfig, que não existe no Forever).

local addonName = "SpellFlashForever"
local s = _G[addonName]
if not s then return end
local L = s.L

local frame
local keyText
local lastSlot
local lastKey
local positioned = false
local debugEnabled = false
local enabled = true
local lastFlashTime = 0
local HIDE_DELAY = 2.5

local fontFile = "Fonts\\FRIZQT__.TTF"
if GameFontNormalLarge and GameFontNormalLarge.GetFont then
    local f = GameFontNormalLarge:GetFont()
    if type(f) == "string" then
        fontFile = f
    end
end

local function D(...)
    if debugEnabled then
        print("[SF KEY]", ...)
    end
end

-- Encurta teclas do numpad para "N": NUMPAD5 → N5, NUMPADPLUS → N+ etc.
-- Modificadores (SHIFT/CTRL/ALT) ficam intactos: "SHIFT-NUM5" → "SHIFT-N5".
local function ShortenKey(key)
    if type(key) ~= "string" or key == "" then return key end
    local upper = key:upper()
    -- ptBR: o cliente exibe o numpad como "TECLADO NÚMERO/NUM.." — remover os termos
    upper = upper:gsub("TECLADO%s*", "")
    upper = upper:gsub("NUMÉRICO", "N"):gsub("NUMERICO", "N"):gsub("NÚMERO", "N"):gsub("NUMERO", "N")
    upper = upper:gsub("NUMLOCK", "NL")
    -- Operadores específicos (com nome completo): feitos antes do prefixo geral
    upper = upper:gsub("NUMPADDECIMAL", "N."):gsub("NUMPADDIVIDE", "N/")
        :gsub("NUMPADMINUS", "N%-"):gsub("NUMPADMULTIPLY", "N*")
        :gsub("NUMPADPLUS", "N+")
    -- Prefixo NUMPAD genérico (dígitos 0-9)
    upper = upper:gsub("NUMPAD([0-9])", "N%1")
    -- Tolerância a "NUM" solto (ex.: hotkey lida do botão: "Num5", "Num 5", "NUM+")
    upper = upper:gsub("NUM%s*([0-9])", "N%1"):gsub("NUM%s*([+%*/%-%.])", "N%1")
    return (upper:gsub("%s+", ""))
end

local function Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r " .. tostring(msg))
    else
        print("SpellFlashForever:", msg)
    end
end

local function GetConfig()
    local db = _G.SpellFlashForeverDB
    if not db then return {} end
    if type(db.handle) ~= "table" then db.handle = {} end
    if type(db.handle.key_button) ~= "table" then db.handle.key_button = {} end
    return db.handle.key_button
end

-- Trava/destrava o arrastar (persistido em SpellFlashForeverDB.handle.key_button.locked)
local function IsLocked()
    return GetConfig().locked == true
end

function s.SetKeyButtonLocked(locked)
    local cfg = GetConfig()
    cfg.locked = locked and true or nil
    if locked then
        Print(L.key_lock)
    else
        Print(L.key_unlock)
    end
    return IsLocked()
end

function s.GetKeyButtonLocked()
    return IsLocked()
end

local function ApplyPosition(cfg)
    local x, y = cfg.x, cfg.y
    frame:ClearAllPoints()
    if x and y then
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
    end
    positioned = true
end

local function SavePosition(cfg)
    local left, bottom = frame:GetLeft(), frame:GetBottom()
    if left and bottom then
        cfg.x, cfg.y = left, bottom
    end
end

local function ShowKey(slot, key)
    local cfg = GetConfig()
    if not positioned then
        ApplyPosition(cfg)
    end
    local n = #ShortenKey(key)
    frame:SetWidth(math.max(46, 28 + n * 11))
    local size = 22
    if n > 2 then size = 16 end
    if n > 4 then size = 12 end
    if n > 6 then size = 10 end
    keyText:SetFont(fontFile, size, "OUTLINE")
    keyText:SetText(ShortenKey(key))
    lastSlot, lastKey, lastFlashTime = slot, key, GetTime()
    frame:SetAlpha(1)
    frame:Show()
end

-- ---------------------------------------------------------------------------
-- Descoberta do botão da barra
-- ---------------------------------------------------------------------------

-- Ordem das barras padrão da Blizzard (a mesma usada pelo SpellFlashForever
-- ao procurar o botão que corresponde ao slot). Para cada barra informamos o
-- prefixo do frame e o prefixo da AÇÃO DE BINDING, que é o nome aceito por
-- GetBindingKey no Forever (o Hekili usa exatamente estes nomes:
-- Hekili/Engine/Sim/Events.lua, GetBindingKey("ACTIONBUTTON"..i) e
-- GetBindingKey("MULTIACTIONBAR3BUTTON"..i) etc.).
local BAR_BINDINGS = {
    { frame = "ActionButton",              bind = "ACTIONBUTTON" },
    { frame = "MultiBarBottomLeftButton",  bind = "MULTIACTIONBAR2BUTTON" },
    { frame = "MultiBarBottomRightButton", bind = "MULTIACTIONBAR3BUTTON" },
    { frame = "MultiBarRightButton",       bind = "MULTIACTIONBAR4BUTTON" },
    { frame = "MultiBarLeftButton",        bind = "MULTIACTIONBAR5BUTTON" },
    { frame = "MultiBar5Button",           bind = "MULTIACTIONBAR6BUTTON" },
    { frame = "MultiBar6Button",           bind = "MULTIACTIONBAR7BUTTON" },
    { frame = "MultiBar7Button",           bind = "MULTIACTIONBAR8BUTTON" },
}

-- Nomes de ação candidatos para um slot (o frame e o binding). Vários
-- candidatos são testados porque a nomenclatura de binding varia entre as
-- barras e o cliente.
local function SlotCandidates(slot)
    if type(slot) ~= "number" then return nil end
    local index = slot
    for i = 1, #BAR_BINDINGS do
        if index <= 12 then
            local list = {}
            list[#list + 1] = BAR_BINDINGS[i].frame .. index
            list[#list + 1] = BAR_BINDINGS[i].bind .. index
            if i > 1 then
                -- Fallback usado pelo Hekili para a segunda barra
                list[#list + 1] = "ACTIONBUTTON" .. index
            end
            return list
        end
        index = index - 12
    end
    return nil
end

local function ButtonName(button)
    if not button or type(button.GetName) ~= "function" then return nil end
    local ok, name = pcall(button.GetName, button)
    if not ok or type(name) ~= "string" or name == "" then return nil end
    return name
end

-- ---------------------------------------------------------------------------
-- Resolução da tecla
-- ---------------------------------------------------------------------------

-- 1) Hotkey exibida no próprio botão (Blizzard padrão ou ElvUI).
local function ButtonHotKey(button)
    if not button then return nil end

    -- Addons de barra (ElvUI) expõem GetHotkey()
    if type(button.GetHotkey) == "function" then
        local ok, key = pcall(button.GetHotkey, button)
        if ok and type(key) == "string" and key ~= "" then
            D("  GetHotkey =", key)
            return key
        end
    end

    local name = ButtonName(button)
    if not name then return nil end

    -- FontString global do hotkey (padrão Blizzard): <nome>HotKey
    local hot = _G[name .. "HotKey"]
    if hot and type(hot.GetText) == "function" then
        local ok, text = pcall(hot.GetText, hot)
        if ok and type(text) == "string" and text ~= "" then
            -- Fora de alcance o Blizzard escreve RANGE_INDICATOR no lugar da tecla
            local rangeInd = type(RANGE_INDICATOR) == "string" and RANGE_INDICATOR or nil
            if not rangeInd or text ~= rangeInd then
                local cleaned = text:gsub("%s", "")
                if cleaned ~= "" then
                    D("  hotkey frame =", text)
                    return cleaned
                end
            end
        end
    end

    -- Filhos HotKey / HotKeyText
    for _, childName in ipairs({ "HotKey", "HotKeyText" }) do
        local f = button[childName]
        if f and type(f.GetText) == "function" then
            local ok, text = pcall(f.GetText, f)
            if ok and type(text) == "string" and text ~= "" then
                local cleaned = text:gsub("%s", "")
                if cleaned ~= "" then
                    D("  hotkey child =", text)
                    return cleaned
                end
            end
        end
    end

    return nil
end

-- 2) API de bindings: GetBindingKey recebe o NOME da ação no Forever.
local function BindingKeyForName(name)
    if not name or name == "" then return nil end
    if type(GetBindingKey) ~= "function" then return nil end

    local ok, key = pcall(GetBindingKey, name)
    if ok and type(key) == "string" and key ~= "" then
        D("  GetBindingKey(", name, ") =", key)
        return key
    end

    -- Binding de clique com o mouse no botão
    ok, key = pcall(GetBindingKey, "CLICK " .. name .. ":LeftButton")
    if ok and type(key) == "string" and key ~= "" then
        D("  GetBindingKey(CLICK ", name, ") =", key)
        return key
    end

    return nil
end

-- 3) Mapa reverso: tecla -> ação -> tecla. Útil quando o botão não está
--    registrado pelo nome (barras de addons) ou quando o binding é do tipo
--    "ACTIONBUTTON3".
local REVERSEMAP = {}
local REVERSEMAPVALID = false

local BASEKEYS = {
    "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=",
    "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]",
    "A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'",
    "Z", "X", "C", "V", "B", "N", "M", ",", ".", "/",
    "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
    "SPACE", "TAB", "ENTER", "ESCAPE", "BACKSPACE", "NUMLOCK", "SCROLLLOCK", "CAPSLOCK",
    "NUMPAD0", "NUMPAD1", "NUMPAD2", "NUMPAD3", "NUMPAD4", "NUMPAD5", "NUMPAD6",
    "NUMPAD7", "NUMPAD8", "NUMPAD9", "NUMPADDECIMAL", "NUMPADDIVIDE", "NUMPADMINUS",
    "NUMPADMULTIPLY", "NUMPADPLUS",
    "INSERT", "HOME", "PAGEUP", "DELETE", "END", "PAGEDOWN",
    "UP", "DOWN", "LEFT", "RIGHT",
    "MOUSEWHEELUP", "MOUSEWHEELDOWN", "BUTTON1", "BUTTON2", "BUTTON3", "BUTTON4", "BUTTON5",
    "GRAVE", "BACKSLASH",
}

local MODIFIERS = { "", "SHIFT-", "CTRL-", "ALT-", "SHIFT-CTRL-", "SHIFT-ALT-", "CTRL-ALT-" }

local function BuildReverseBindings()
    REVERSEMAP = {}
    if type(GetBindingAction) ~= "function" then
        REVERSEMAPVALID = true
        return
    end
    for _, m in ipairs(MODIFIERS) do
        for _, k in ipairs(BASEKEYS) do
            local key = m .. k
            local ok, action = pcall(GetBindingAction, key)
            if ok and type(action) == "string" and action ~= "" then
                local a = action:upper()
                if not REVERSEMAP[a] then
                    REVERSEMAP[a] = key
                end
            end
        end
    end
    REVERSEMAPVALID = true
end

local function KeyForAction(action)
    if not action or action == "" then return nil end
    if not REVERSEMAPVALID then
        BuildReverseBindings()
    end
    return REVERSEMAP[action:upper()]
end

-- Quando o jogador troca uma tecla, o mapa reverso precisa ser refeito.
-- Evento confirmado no Forever: Hekili/Engine/Sim/Events.lua usa UPDATE_BINDINGS.
do
    local bindingFrame = CreateFrame("Frame")
    bindingFrame:RegisterEvent("UPDATE_BINDINGS")
    bindingFrame:SetScript("OnEvent", function()
        REVERSEMAPVALID = false
        REVERSEMAP = {}
    end)
end

-- ---------------------------------------------------------------------------
-- Treat
-- ---------------------------------------------------------------------------

local function HandleFlash(button, slot)
    if not enabled then return end

    local name = ButtonName(button)
    D("flash em", tostring(name), "slot=", tostring(slot))

    -- 1) Tecla exibida no botão
    local key = ButtonHotKey(button)

    -- 2) Binding pelo nome do botão
    if not key and name then
        key = BindingKeyForName(name)
    end

    -- 3) Binding pelo slot (nomes de ação das barras padrão)
    if not key and slot then
        local candidates = SlotCandidates(slot)
        if candidates then
            for _, candidate in ipairs(candidates) do
                key = BindingKeyForName(candidate)
                if key then break end
            end
        end
    end

    -- 4) Mapa reverso (ação -> tecla)
    if not key and name then
        key = KeyForAction(name)
        if key then D("  reverse binding =", key) end
    end

    -- 5) Bindstring do botão (addons de barra como ElvUI)
    if not key and button and type(button.GetAttribute) == "function" then
        local ok, bindString = pcall(button.GetAttribute, button, "bindstring")
        if ok and type(bindString) == "string" and bindString ~= "" then
            key = BindingKeyForName(bindString)
        end
    end

    if not key then
        D("  nenhuma tecla encontrada - ocultando botão")
        lastFlashTime = 0
        lastSlot, lastKey = nil, nil
        frame:Hide()
        return
    end

    ShowKey(slot, key)
end

-- Hook: dispara quando o motor de flash realmente acende um botão.
-- A assinatura é (button, slot). O slot é opcional (o FlashFrame chamado
-- direto, sem slot, ainda resolve a tecla pelo nome do botão).
s.OnFlash = s.OnFlash or function() end
local previousOnFlash = s.OnFlash
s.OnFlash = function(button, slot)
    local ok, err = pcall(HandleFlash, button, slot)
    if not ok then
        Print(string.format(L.key_error, tostring(err)))
    end
    if previousOnFlash then
        pcall(previousOnFlash, button, slot)
    end
end

-- ---------------------------------------------------------------------------
-- Construção do frame
-- ---------------------------------------------------------------------------

frame = CreateFrame("Button", "SpellFlashKeyButton", UIParent)
frame:SetSize(46, 44)
frame:SetFrameStrata("HIGH")
frame:SetClampedToScreen(true)
frame:Hide()

local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
-- UI-Quickslot2 não existe em todas as versões do cliente: usa atlas quando
-- disponível e, senão, uma cor sólida (SetColorTexture é o caminho moderno).
if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("UI-Quickslot2") then
    bg:SetAtlas("UI-Quickslot2")
    bg:SetVertexColor(0.15, 0.15, 0.15)
else
    bg:SetColorTexture(0.08, 0.08, 0.08, 0.85)
end

local border = frame:CreateTexture(nil, "ARTWORK")
if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("UI-ActionButton-Border") then
    border:SetAtlas("UI-ActionButton-Border")
else
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
end
border:SetSize(64, 64)
border:SetPoint("CENTER")

keyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
keyText:SetPoint("CENTER", frame, "CENTER", 0, 1)
keyText:SetJustifyH("CENTER")
keyText:SetJustifyV("MIDDLE")
keyText:SetTextColor(1, 0.95, 0.7)

frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
    if not IsLocked() then
        self:StartMoving()
    end
end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SavePosition(GetConfig())
end)

frame:SetScript("OnUpdate", function(self)
    if lastFlashTime > 0 and GetTime() - lastFlashTime > HIDE_DELAY then
        lastFlashTime = 0
        self:Hide()
    end
end)

-- Tooltip: nome da habilidade/macro/item do slot + a tecla.
frame:SetScript("OnEnter", function(self)
    if not lastSlot or not lastKey then return end

    local actionType, id = GetActionInfo(lastSlot)
    if not actionType then return end

    GameTooltip:SetOwner(self, "ANCHOR_TOP")

    if actionType == "spell" then
        local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
        if info and info.name then
            GameTooltip:AddLine(info.name)
        end
    elseif actionType == "macro" then
        local macro
        if C_Macro and C_Macro.GetMacroInfo then
            local ok, info = pcall(C_Macro.GetMacroInfo, id)
            if ok and type(info) == "table" then macro = info.name end
        end
        if not macro and GetMacroInfo then
            local ok, name = pcall(GetMacroInfo, id)
            if ok then macro = name end
        end
        if macro then
            GameTooltip:AddLine(macro)
        end
    elseif actionType == "item" then
        local itemName
        if C_Item and C_Item.GetItemInfo then
            local ok, name = pcall(C_Item.GetItemInfo, id)
            if ok then itemName = name end
        end
        if not itemName and GetItemInfo then
            local ok, name = pcall(GetItemInfo, id)
            if ok then itemName = name end
        end
        if itemName then
            GameTooltip:AddLine(itemName)
        end
    end

    GameTooltip:AddLine(ShortenKey(lastKey), 1, 0.95, 0.7)
    GameTooltip:Show()
end)
frame:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

s.KeyButton = frame
s.IsKeyButtonEnabled = function() return enabled end
s.SetKeyButtonEnabled = function(value)
    enabled = value and true or false
    if not enabled then
        lastFlashTime = 0
        frame:Hide()
    end
    local cfg = GetConfig()
    cfg.enabled = enabled
    return enabled
end

-- Restaura o estado salvo (ligado/desligado) e a posição da sessão anterior.
do
    local cfg = GetConfig()
    if cfg.enabled == false then
        enabled = false
    end
    ApplyPosition(cfg)
end

-- ---------------------------------------------------------------------------
-- Slash command
-- ---------------------------------------------------------------------------

local function SlashHandler(msg)
    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()

    if msg == "" then
        Print(L.key_help)
        return
    end

    if msg == "off" then
        s.SetKeyButtonEnabled(false)
        Print(L.key_off_hint)
        return
    elseif msg == "on" then
        s.SetKeyButtonEnabled(true)
        Print(L.key_on)
        return
    end

    if msg == "lock" or msg == "travar" then
        s.SetKeyButtonLocked(true)
    elseif msg == "unlock" or msg == "mover" then
        s.SetKeyButtonLocked(false)
    elseif msg == "reset" then
        local cfg = GetConfig()
        cfg.x, cfg.y = nil, nil
        positioned = false
        ApplyPosition(cfg)
        Print(L.key_pos_reset)
    elseif msg == "hide" then
        frame:Hide()
        Print(L.key_hidden)
    elseif msg == "show" then
        positioned = false
        ApplyPosition(GetConfig())
        frame:Show()
        frame:SetAlpha(0.5)
        Print(L.key_shown)
    elseif msg == "debug" then
        debugEnabled = not debugEnabled
        if debugEnabled then
            Print(L.key_debug_on)
        else
            Print(L.key_debug_off)
        end
    else
        Print(L.key_commands)
    end
end

SLASH_SPELLFLASHKEY1 = "/sfkey"
SLASH_SPELLFLASHKEY2 = "/sfkeybutton"
SlashCmdList["SPELLFLASHKEY"] = SlashHandler
