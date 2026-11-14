-- SpellFlash_Paladin / Scripts.lua
-- Orquestra mestre do módulo Paladin (Interface 16001). Apenas PROT (tank) e RET (DPS)
-- são suportados; Holy cai no silêncio (rode /sf → Paladin para forçar).
-- Detecção de spec por pontos em árvore (C_Traits; empate → RET). Override em /sf → Paladin.
local AddonName, AddonTable = ...

_G.SpellFlash_Paladin = AddonTable

if not AddonTable.ShouldUseRacial then AddonTable.ShouldUseRacial = function() return nil end end
if not AddonTable.ShouldUseTrinket then AddonTable.ShouldUseTrinket = function() return nil end end

local L = AddonTable.Localize
local SpellFlashAddon = SpellFlashAddon

local TREE_HINTS_PALADIN = {
    PROT = { "prot", "prote", "protec", "escudo", "shield", "guard" },
    RET  = { "retrib", "retribut", "julg", "judge", "judgement" },
    HOLY = { "holy", "sag", "sagr", "santo", "cura" },
}

local function SpellName(id) return AddonTable.SpellName(id) end
local function Castable(name, ...)
    if type(AddonTable.Castable[name]) == "function" then
        return AddonTable.Castable[name](...)
    end
    return false
end
local function TryFlash(spellID, color, condition, englishName)
    if condition and condition() then
        if SpellFlashAddon.Flashable(SpellName(spellID)) and Castable(englishName) then
            SpellFlashAddon.FlashAction(SpellName(spellID), color)
            return true
        end
    end
    return false
end

AddonTable.TryFlash = TryFlash

-- Contagem de inimigos perto (nameplates) — mesmo padrão do Warrior/Shaman
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
-- CRENÇA POR CAST para self-buffs (auras secretas em combate)
--   Righteous Fury:  30 min no Forever (regra vanilla; confirmar in-game)
--   Holy Shield:     12 s (Forever; confirmar in-game)
--   Seal of Command / Seal of Righteousness: 30 min
-- =====================================================
local SELF_BUFF_DURATIONS = { [25780] = 1800, [28153] = 12, [20915] = 1800, [20289] = 1800 }
AddonTable.SelfBuffBelief = AddonTable.SelfBuffBelief or {}

local Buff = SpellFlashAddon.CheckBuff

AddonTable.IsSelfBuffUp = function(spellID)
    local name = SpellName(spellID)
    if not name then return false end
    if Buff then
        local okB, up = pcall(Buff, name, "player")
        if okB and up then return true end
    end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        local expires = AddonTable.SelfBuffBelief and AddonTable.SelfBuffBelief[spellID]
        if expires and (type(GetTime) == "function") and GetTime() < expires then
            return true
        end
    end
    return false
end

local trackerFrame = CreateFrame("Frame")
trackerFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
local function NormSpellName(s)
    if type(s) ~= "string" then return nil end
    return (s:gsub("%s*%b()%s*$", ""):gsub("%s*$", ""):lower())
end
local selfBuffNameNorm = {}
for id in pairs(SELF_BUFF_DURATIONS) do
    local n = NormSpellName(SpellName(id))
    if n then selfBuffNameNorm[n] = id end
end
trackerFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local nameNorm = NormSpellName(type(...) == "string" and select(1, ...) or nil)
        local id = nameNorm and selfBuffNameNorm[nameNorm]
        if id and type(GetTime) == "function" then
            AddonTable.SelfBuffBelief = AddonTable.SelfBuffBelief or {}
            AddonTable.SelfBuffBelief[id] = GetTime() + SELF_BUFF_DURATIONS[id]
        end
    end
end)

-- =====================================================
-- ROTAÇÃO MESTRE
-- =====================================================
SpellFlashAddon.Spam[AddonName] = function(x)
    local _, myClass = UnitClass("player")
    if myClass ~= "PALADIN" then return end
    local env = {
        hasActiveEnemy = x.ActiveEnemy or (UnitExists("target") and UnitCanAttack("player", "target")),
        inCombat = SpellFlashAddon.InCombat and SpellFlashAddon.InCombat(),
        isMelee = AddonTable.IsInMeleeRange and AddonTable.IsInMeleeRange("target"),
        myHP = SpellFlashAddon.HealthPercent and SpellFlashAddon.HealthPercent("player") or 100,
        targetHP = SpellFlashAddon.HealthPercent and SpellFlashAddon.HealthPercent("target") or 100,
        enemies = GetAoECount(),
        isAoE = GetAoECount() >= 2,
        isPvP = AddonTable.IsTargetEnemyPlayer and AddonTable.IsTargetEnemyPlayer("target") or false,
        isBoss = (UnitClassification and string.find(string.lower(UnitClassification("target") or ""), "boss")) ~= nil,
        targetCasting = AddonTable.IsTargetInterruptibleCasting and AddonTable.IsTargetInterruptibleCasting("target"),
        isCCd = SpellFlashAddon.IsCrowedControlled and SpellFlashAddon.IsCrowedControlled("player") or false,
    }

    -- =====================================================
    -- DETECÇÃO DE SPEC (override → pontos por árvore; empate → RET)
    -- =====================================================
    local override = SpellFlashAddon.GetModuleConfig and SpellFlashAddon.GetModuleConfig(AddonName, "spec_override") or nil

    if AddonTable.TalentCountCache == nil then
        AddonTable.TalentCountCache = false
        AddonTable.TalentCountCache = SpellFlashAddon.CountTalentTreePoints and SpellFlashAddon.CountTalentTreePoints(TREE_HINTS_PALADIN, { "PROT", "RET", "HOLY" }) or false
    end
    local counts = type(AddonTable.TalentCountCache) == "table" and AddonTable.TalentCountCache.counts or nil
    local pointsProt, pointsRet, pointsHoly = 0, 0, 0
    if counts then
        pointsProt, pointsRet, pointsHoly = tonumber(counts.PROT) or 0, tonumber(counts.RET) or 0, tonumber(counts.HOLY) or 0
    end

    local bestTree = nil
    if pointsProt >= pointsRet and pointsProt >= pointsHoly and pointsProt > 0 then
        bestTree = "PROT"
    elseif pointsRet >= pointsHoly and pointsRet > 0 then
        bestTree = "RET"
    elseif pointsHoly > 0 then
        bestTree = "HOLY"
    end

    local isProt, isRet, isHoly, specSource
    if override == "PROT" then isProt, isRet, isHoly, specSource = true, false, false, "override"
    elseif override == "RET" then isProt, isRet, isHoly, specSource = false, true, false, "override"
    elseif bestTree == "PROT" then isProt, isRet, isHoly, specSource = true, false, false, "Protection=" .. tostring(pointsProt)
    elseif bestTree == "RET" then isProt, isRet, isHoly, specSource = false, true, false, "Retribution=" .. tostring(pointsRet)
    elseif bestTree == "HOLY" then isProt, isRet, isHoly, specSource = false, false, true, "Holy=" .. tostring(pointsHoly)
    elseif SpellFlashAddon.IsSpellKnown and SpellFlashAddon.IsSpellKnown(680) then
        isProt, isRet, isHoly, specSource = false, true, false, "Ret(Holy Strike 680)"
    else
        isProt, isRet, isHoly, specSource = false, true, false, "padrão Retribution" end

    if not AddonTable.SpecMessageSent then
        local msg = "|cFF00FF00[SF Paladin]|r "
        if isProt then
            print(msg.."|cFFFFD700Protection:|r Baluarte da Luz — sua muralha não cairá!")
        elseif isRet then
            print(msg.."|cFFFF8000Retribution:|r Pela Luz — cada golpe é um julgamento!")
        else
            print(msg.."|cFF00BFFFHoly:|r spec Holy não suportada por esta rotação; use /sf > Paladin para forçar PROT ou RET.")
        end
        print(msg.."|cFFCCCCCCspec:|r " .. tostring(specSource) .. " (Prot=" .. tostring(pointsProt) .. " Ret=" .. tostring(pointsRet) .. " Holy=" .. tostring(pointsHoly) .. ")")
        if AddonTable.ShowRacialInfo and not AddonTable.RacialGreetingSent then
            AddonTable.ShowRacialInfo()
            AddonTable.RacialGreetingSent = true
        end
        AddonTable.SpecMessageSent = true
    end

    if not env.hasActiveEnemy then
        if isProt and AddonTable.RunPROTRotation then AddonTable.RunPROTRotation(env)
        elseif isRet and AddonTable.RunRETRotation then AddonTable.RunRETRotation(env) end
        return
    end

    if env.isCCd then
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
        return
    end

    if isProt and AddonTable.RunPROTRotation then if AddonTable.RunPROTRotation(env) then return end
    elseif isRet and AddonTable.RunRETRotation then if AddonTable.RunRETRotation(env) then return end end
end

SLASH_SFPALADINTREES1 = "/sftreesp"
SlashCmdList["SFPALADINTREES"] = function()
    local function P(m) DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[SF Paladin Trees]|r " .. tostring(m)) end
    if not (C_ClassTalents and C_Traits) then P("C_ClassTalents/C_Traits ausentes") return end
    local r = SpellFlashAddon.CountTalentTreePoints and SpellFlashAddon.CountTalentTreePoints(TREE_HINTS_PALADIN)
    if not r then P("Contagem indisponível") return end
    for i, name in ipairs(r.names or {}) do
        P(tostring(i) .. ": " .. tostring(name))
    end
    P("counts:", "PROT=" .. tostring(r.counts and r.counts.PROT) .. " RET=" .. tostring(r.counts and r.counts.RET) .. " HOLY=" .. tostring(r.counts and r.counts.HOLY))
end
