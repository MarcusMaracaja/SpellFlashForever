-- SpellFlash_Shaman / Scripts.lua
-- Orquestra mestre do módulo Shaman (Elemental e Enhancement) + detecção de spec
-- (pontos por árvore via C_Traits — ordem ELE > ENH; ordinals do WotLK via core
-- CountTalentTreePoints; assinatura = Stormstrike (ENH); override /sf > Shaman).
-- Preferência do projeto: Elemental (roteiro base = Hunter SV).
local AddonName, AddonTable = ...

local TREE_HINTS_SHAMAN = {
    ELE = { "element", "elementar", "elemental", "comet-root", "reason-of-storm" },
    ENH = { "enhanc", "enhance", "aperfe", "enhe", "power of the storm" },
    REST = { "restau", "restaur", "restor", "heal" },
}

-- Expose o módulo pro core (debug, /sf status)
_G.SpellFlash_Shaman = AddonTable

local InCombat = SpellFlashAddon.InCombat

-- Fallbacks (o core cobre os de verdade: delegações em Localization.lua)
if not AddonTable.ShouldUseRacial then AddonTable.ShouldUseRacial = function() return nil end end
if not AddonTable.ShouldUseTrinket then AddonTable.ShouldUseTrinket = function() return nil end end

local L = AddonTable.Localize
local Buff = SpellFlashAddon.CheckBuff
local Debuff = SpellFlashAddon.CheckDebuff
local HealthPercent = SpellFlashAddon.HealthPercent

local function SpellName(id)
    return AddonTable.SpellName(id)
end

AddonTable.CheckCastable = function(English_Spell_Name, ...)
    if type(AddonTable.Castable) == "table" and type(AddonTable.Castable[English_Spell_Name]) == "function" then
        return AddonTable.Castable[English_Spell_Name](...)
    end
    return false
end

AddonTable.FlashCooldown = 0.2
AddonTable.FlashCD = {}

AddonTable.RawFlash = function(SpellName, color)
    if AddonTable.TickFlashUsed then return false end
    local now = GetTime()
    if AddonTable.FlashCD[SpellName] and now - AddonTable.FlashCD[SpellName] < AddonTable.FlashCooldown then
        return false
    end
    AddonTable.TickFlashUsed = true
    AddonTable.FlashCD[SpellName] = now
    SpellFlashAddon.FlashAction(SpellName, color)
    return true
end

AddonTable.TryFlash = function(spellID, color, condition, englishName)
    if AddonTable.TickFlashUsed then return false end
    if AddonTable.IsPressSuppressed and AddonTable.IsPressSuppressed(AddonTable.SpellName(spellID)) then return false end
    -- Flashable por ID numérico (o cliente resolve por spellbook/FAMILIES; não depende
    -- do round-trip nome→ID, que falha para IDs que não resolvem em C_Spell.GetSpellInfo)
    local known = SpellFlashAddon.Flashable(spellID)
    if condition() and known and AddonTable.CheckCastable(englishName) then
        return AddonTable.RawFlash(AddonTable.SpellName(spellID), color)
    end
    return false
end

-- ======== Apagamento imediato ao USAR (pressionar botão/tecla) ========
AddonTable.PressSuppress = {}
AddonTable.ButtonsHooked = nil

AddonTable.OnSpinPressed = function(button)
    if not button then return end
    local action
    if button.GetAttribute then
        action = button:GetAttribute("action")
    end
    if not action then return end
    local actionType, id = GetActionInfo(tonumber(action) or action)
    if actionType == "spell" and id and id ~= "" then
        AddonTable.PressSuppress[id] = GetTime() + 0.6
    end
end

AddonTable.IsPressSuppressed = function(SpellName)
    if not SpellName or SpellName == "" then return false end
    local untilTime = AddonTable.PressSuppress[SpellName]
    return not not (untilTime and GetTime() < untilTime)
end

AddonTable.HookActionButtonPress = function()
    if AddonTable.ButtonsHooked then return end
    AddonTable.ButtonsHooked = true
    local ok, err = pcall(function()
        if type(SecureActionButton_OnClick) == "function" then
            hooksecurefunc("SecureActionButton_OnClick", function(self)
                pcall(AddonTable.OnSpinPressed, self)
            end)
        else
            local prefixes = { "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton", "MultiBarLeftButton", "PetActionButton", "StanceButton" }
            for p = 1, #prefixes do
                for i = 1, 12 do
                    local btn = _G[prefixes[p] .. i]
                    if btn and not btn.SpellFlashPressHooked then
                        btn.SpellFlashPressHooked = true
                        hooksecurefunc(btn, "Click", function(self)
                            pcall(AddonTable.OnSpinPressed, self)
                        end)
                    end
                end
            end
        end
    end)
    if not ok then
        AddonTable.ButtonsHooked = nil
    end
end

-- =====================================================
-- CRENÇA POR CAST: Flame Shock (auras do alvo são secret em combate)
-- Mesmo padrão do Serpent Sting/Wing Clip do Hunter:
--   1) registra cast do jogador (RegisterUnitEvent + nome normalizado)
--   2) vincula ao SLOT do alvo (contador que muda em PLAYER_TARGET_CHANGED)
--   3) expira sozinho (duração do vanilla/Forever: 12 s + margem → 15 s)
--   4) na dúvida, NÃO sugere (ausência não é informação)
-- =====================================================
local targetSlot = 0
AddonTable.FlameShockBelief = AddonTable.FlameShockBelief or { applied = false, slot = 0, expires = 0 }
local FLAMESHOCK_BELIEF_DURATION = 15

-- Crença por cast para os SELF-BUFFS (auras secretas em combate; mesma receita de 07-auras-secretas-e-crenca.md):
--   Lightning Shield: 10 min de aura no vanilla/Forever → 600 s
--   Flametongue/Windfury Weapon (imbue): 5 min → 300 s
--   API positiva (fora de combate) vence a crença; na dúvida, NÃO sugere.
local SELF_BUFF_DURATIONS = { [324] = 600, [8024] = 300, [8232] = 300 }
AddonTable.SelfBuffBelief = AddonTable.SelfBuffBelief or {}

AddonTable.IsSelfBuffUp = function(spellID)
    local name = SpellName(spellID)
    if not name then return false end
    -- 1) API legível (fora de combate) vence sempre
    if Buff then
        local okB, up = pcall(Buff, name, "player")
        if okB and up then return true end
    end
    -- 2) Em combate a leitura vem secret → crença do próprio cast decide
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        local expires = AddonTable.SelfBuffBelief and AddonTable.SelfBuffBelief[spellID]
        if expires and (type(GetTime) == "function") and GetTime() < expires then
            return true
        end
    end
    return false
end

AddonTable.IsFlameShockUp = function(unit)
    unit = unit or "target"
    if unit == "target" then
        local b = AddonTable.FlameShockBelief
        if b and b.applied and b.slot == targetSlot then
            if type(GetTime) == "function" and GetTime() < b.expires then
                return true
            end
            b.applied = false
        end
    end
    return Debuff and Debuff(SpellName(8050), unit)
end

-- =====================================================
-- TOTEM PÚBLICO (detecção por NOME localizado — GetTotemInfo)
-- =====================================================
AddonTable.IsTotemActiveByName = function(name)
    if type(name) ~= "string" or name == "" then return false end
    for i = 1, 4 do
        local haveTotem, totemName = GetTotemInfo(i)
        if haveTotem and totemName == name then return true end
    end
    return false
end

local trackerFrame = CreateFrame("Frame")
trackerFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
trackerFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
trackerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

-- Nomes normalizados para casar casts (chave: nome base minúsculo, sem sufixo de grau)
local function NormSpellName(s)
    if type(s) ~= "string" then return nil end
    return (s:gsub("%s*%b()%s*$", ""):gsub("%s*$", ""):lower())
end
local flameNameNorm = NormSpellName(SpellName(8050))
local selfBuffNameNorm = {} -- nome normalizado -> spellID
for id in pairs(SELF_BUFF_DURATIONS) do
    local n = NormSpellName(SpellName(id))
    if n then selfBuffNameNorm[n] = id end
end

trackerFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        targetSlot = targetSlot + 1
        AddonTable.FlameShockBelief.applied = false
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _, _, spellID = ...
        if type(spellID) == "number" and C_Spell and type(C_Spell.GetSpellInfo) == "function" then
            local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
            local castName = ok and info and info.name
            local norm = NormSpellName(castName)
            if norm then
                if norm == flameNameNorm then
                    AddonTable.FlameShockBelief.applied = true
                    AddonTable.FlameShockBelief.slot = targetSlot
                    AddonTable.FlameShockBelief.expires = (type(GetTime) == "function" and GetTime() or 0) + FLAMESHOCK_BELIEF_DURATION
                end
                local buffID = selfBuffNameNorm[norm]
                if buffID then
                    if not AddonTable.SelfBuffBelief then AddonTable.SelfBuffBelief = {} end
                    AddonTable.SelfBuffBelief[buffID] = (type(GetTime) == "function" and GetTime() or 0) + SELF_BUFF_DURATIONS[buffID]
                end
            end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- fim de combate: nada a limpar por ora (crenças já expiram sozinhas)
    end
end)

-- =====================================================
-- CONTAGEM DE INIMIGOS (nameplates — sem combat log)
-- =====================================================
local function GetAoECount()
    local okList, units = pcall(function()
        if type(C_NamePlate) == "table" and type(C_NamePlate.EnumerateUnits) == "function" then
            return { C_NamePlate.EnumerateUnits() }
        end
    end)
    if not okList or type(units) ~= "table" then return 1 end
    local n = 0
    for _, unit in ipairs(units) do
        local okE, canAttack = pcall(UnitCanAttack, "player", unit)
        if okE and canAttack then n = n + 1 end
        if n > 10 then return n end
    end
    return math.max(n, 1)
end

-- =====================================================
-- ROTAÇÃO MESTRE
-- =====================================================
SpellFlashAddon.Spam[AddonName] = function(x)
    -- Só executa se o jogador for Shaman
    local _, myClass = UnitClass("player")
    if myClass ~= "SHAMAN" then return end
    -- O driver do Compat passa a tabela x (ActiveEnemy/Enemy/NoCC/...); calculamos
    -- o estado direto do alvo (mais confiável e independente de x).
    if IsMounted() then return end

    -- Estado de cast: não interromper casts/canalizações
    if type(UnitCastingInfo) == "function" then
        local okCast, name = pcall(UnitCastingInfo, "player")
        if okCast and name then return end
    end
    if type(UnitChannelInfo) == "function" then
        local okChan, name = pcall(UnitChannelInfo, "player")
        if okChan and name then return end
    end

    local targetDead = (function()
        local ok, d = pcall(UnitIsDeadOrGhost, "target")
        return ok and d or false
    end)()
    local canAttackTarget = (function()
        if not UnitExists("target") then return false end
        if targetDead then return false end
        local ok, can = pcall(UnitCanAttack, "player", "target")
        if not ok or (_G.issecretvalue and issecretvalue(can)) then return true end
        return can and true or false
    end)()

    local targetDistance = AddonTable.TargetDistance and AddonTable.TargetDistance("target") or nil
    local isMelee = (function()
        if targetDistance ~= nil then return targetDistance <= 10 end
        local meleeRange = AddonTable.IsInMeleeRange and AddonTable.IsInMeleeRange("target")
        return meleeRange == true
    end)()

    AddonTable.TickFlashUsed = nil
    pcall(AddonTable.HookActionButtonPress)

    local manaPct = SpellFlashAddon.PowerPercent and SpellFlashAddon.PowerPercent("player", 0) or 100
    local env = {
        hasActiveEnemy = canAttackTarget,
        inCombat = InCombat and InCombat() or false,
        isMelee = isMelee,
        isPvP = AddonTable.IsTargetEnemyPlayer and AddonTable.IsTargetEnemyPlayer("target") or false,
        mana = SpellFlashAddon.Power and SpellFlashAddon.Power("player", 0) or 0,
        manaMax = SpellFlashAddon.MaxPower and SpellFlashAddon.MaxPower("player", 0) or 0,
        myHP = HealthPercent("player") or 100,
        targetHP = HealthPercent("target") or 100,
        enemies = GetAoECount(),
        isAoE = GetAoECount() >= 2,
        targetDistance = targetDistance,
        tooCloseForRanged = (targetDistance ~= nil) and (targetDistance <= 10) or (targetDistance == nil and isMelee == true) or false,
        manaPct = manaPct,
        petAlive = false,
    }

    -- =====================================================
    -- DETECÇÃO DE SPEC (override → pontos ELE/ENH; ordinals ELE>ENH>REST)
    -- =====================================================
    local override = SpellFlashAddon.GetModuleConfig and SpellFlashAddon.GetModuleConfig(AddonName, "spec_override") or nil

    if AddonTable.TalentCountCache == nil then
        AddonTable.TalentCountCache = false
        AddonTable.TalentCountCache = SpellFlashAddon.CountTalentTreePoints and SpellFlashAddon.CountTalentTreePoints(TREE_HINTS_SHAMAN, { "ELE", "ENH", "REST" }) or false
    end
    local counts = type(AddonTable.TalentCountCache) == "table" and AddonTable.TalentCountCache.counts or nil
    local pointsELE, pointsENH = 0, 0
    if counts then
        pointsELE, pointsENH = tonumber(counts.ELE) or 0, tonumber(counts.ENH) or 0
    end

    local bestTree = nil
    if pointsELE > pointsENH then
        bestTree = "ELE"
    elseif pointsENH > pointsELE then
        bestTree = "ENH"
    elseif pointsENH > 0 or pointsELE > 0 then
        bestTree = "ELE" -- empate/híbrido: Elemental (spec em desenvolvimento)
    end

    local isELE, isENH, specSource
    if override == "ELE" then isELE, isENH, specSource = true, false, "override"
    elseif override == "ENH" then isELE, isENH, specSource = false, true, "override"
    elseif bestTree == "ELE" then isELE, isENH, specSource = true, false, "Elemental=" .. tostring(pointsELE)
    elseif bestTree == "ENH" then isELE, isENH, specSource = false, true, "Enhancement=" .. tostring(pointsENH)
    elseif SpellFlashAddon.IsSpellKnown and SpellFlashAddon.IsSpellKnown(17364) then
        isELE, isENH, specSource = false, true, "ENH(17364=Stormstrike)"
    else
        isELE, isENH, specSource = true, false, "padrão Elemental"
    end
    -- Estampa a spec no env (a declaração de nós de prefixo comum usa env.spec)
    env.spec = isENH and "ENH" or "ELE"

    -- Mensagem de inicialização (uma vez por sessão) + saudação racial
    if not AddonTable.SpecMessageSent then
        local msg = "|cFF00FF00[SF Shaman]|r "
        if isENH then
            print(msg.."|cFF69CCF0Enhancement:|r Podem dobrar o ferro — a tempestade responde aos seus punhos!")
        else
            print(msg.."|cFFFF8000Elemental:|r Aberração elemental — a tempestade lhe obedece!")
        end
        print(msg.."|cFFCCCCCCspec:|r " .. tostring(specSource) .. " (Elemental=" .. tostring(pointsELE) .. " Enhancement=" .. tostring(pointsENH) .. ")")
        if AddonTable.ShowRacialInfo and not AddonTable.RacialGreetingSent then
            AddonTable.ShowRacialInfo()
            AddonTable.RacialGreetingSent = true
        end
        AddonTable.SpecMessageSent = true
    end

    -- =====================================================
    -- FORA DE COMBATE / INTERRUPÇÃO / SELF-BUFFS em falta
    -- Tudo isso virou nós de prefixo comum na declaração
    -- (ShamanCommonNodes) — editável em /sf → Shaman → Rotação.
    -- =====================================================

    -- =====================================================
    -- CC / PvP
    -- =====================================================
    if SpellFlashAddon.IsCrowedControlled and SpellFlashAddon.IsCrowedControlled("player") then
        local racialId = AddonTable.ShouldUseRacial()
        if racialId then
            local racialName = SpellName(racialId)
            if racialName and SpellFlashAddon.Flashable(racialName) then
                SpellFlashAddon.FlashAction(racialName, "Aqua")
                return
            end
        end
        local trinketId = AddonTable.ShouldUseTrinket(true)
        if trinketId then
            local trinketName = type(trinketId) == "number" and select(1, C_Item.GetItemInfo(trinketId)) or nil
            if trinketName and SpellFlashAddon.Flashable(trinketName) then
                SpellFlashAddon.FlashAction(trinketName, "Aqua")
                return
            end
        end
        if TryFlash(8143, "Aqua", function() return true end, "Tremor Totem") then return end
    end

    -- =====================================================
    -- INTERRUPÇÃO: virou o nó "earth_shock_interrupt" (prefixo comum,
    -- editável em /sf → Shaman → Rotação).
    -- =====================================================

    -- =====================================================
    -- SELF-BUFFS: viraram os nós "lightning_shield" / "flametongue_weapon" /
    -- "windfury_weapon" / "strength_of_earth" (prefixo comum, editável).
    -- =====================================================

    -- =====================================================
    -- DESPACHO POR SPEC
    -- =====================================================
    if isENH and AddonTable.RunENHRotation then
        if AddonTable.RunENHRotation(env) then return end
    elseif AddonTable.RunELERotation then
        if AddonTable.RunELERotation(env) then return end
    end
end

-- Diagnóstico de talentos: /sftreessh — mostra o que o cliente devolve por árvore
SLASH_SFSHAMTREES1 = "/sftreessh"
SlashCmdList["SFSHAMTREES"] = function()
    local function P(m) DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[SF Shaman Trees]|r " .. tostring(m)) end
    if not (C_ClassTalents and C_Traits) then P("C_ClassTalents/C_Traits ausentes") return end
    local r = SpellFlashAddon.CountTalentTreePoints and SpellFlashAddon.CountTalentTreePoints(TREE_HINTS_SHAMAN)
    if not r then P("Contagem indisponível") return end
    for i, name in ipairs(r.names or {}) do
        P(tostring(i) .. ": " .. tostring(name))
    end
    P("counts:", "ELE=" .. tostring(r.counts and r.counts.ELE) .. " ENH=" .. tostring(r.counts and r.counts.ENH) .. " REST=" .. tostring(r.counts and r.counts.REST))
end

print('|cFF00FF00[SF Shaman]|r Scripts Core Carregado!')
