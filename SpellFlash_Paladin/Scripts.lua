-- SpellFlash_Paladin / Scripts.lua
-- Orquestra mestre do módulo Paladin (Interface 16001). Apenas PROT (tank) e RET (DPS)
-- são suportados; Holy cai no silêncio (rode /sf → Paladin para forçar).
-- Detecção de spec por pontos em árvore (C_Traits; empate → RET). Override em /sf → Paladin.
local AddonName, AddonTable = ...

_G.SpellFlash_Paladin = AddonTable

if not AddonTable.ShouldUseRacial then AddonTable.ShouldUseRacial = function() return nil end end
if not AddonTable.ShouldUseTrinket then AddonTable.ShouldUseTrinket = function() return nil end end

local L = AddonTable.L
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
-- AURAS PRÓPRIAS: crença por cast no core (AuraUp / RegisterAuraBelief).
--   Righteous Fury:  30 min no Forever (regra vanilla; confirmar in-game)
--   Holy Shield:     12 s (Forever; confirmar in-game)
--   Seal of Command / Seal of Righteousness: 30 min
-- =====================================================
local SELF_BUFF_DURATIONS = { [25780] = 1800, [28153] = 12, [20915] = 1800, [20289] = 1800 }

if SpellFlashAddon and type(SpellFlashAddon.RegisterAuraBelief) == "function" then
    for id, dur in pairs(SELF_BUFF_DURATIONS) do
        SpellFlashAddon.RegisterAuraBelief({ { ids = { id }, duration = dur, unit = "player" } })
    end
end

AddonTable.IsSelfBuffUp = function(spellID)
    if not (SpellFlashAddon and SpellFlashAddon.AuraUp) then return false end
    return SpellFlashAddon.AuraUp("player", { spellID }, "buff")
end

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
        isProt, isRet, isHoly, specSource = false, true, false, L.dbg_default_spec .. " Retribution" end

    if not AddonTable.SpecMessageSent then
        local msg = "|cFF00FF00[SF Paladin]|r "
        if isProt then
            print(msg .. L.bless_prot_pal)
        elseif isRet then
            print(msg .. L.bless_ret)
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

    -- Interrupção de último recurso: racial (Pisada de Guerra) — inimigo conjurando
    -- e Hammer of Justice (interrupt da classe) em CD; alvo precisa estar perto
    local interruptUnavailable = false
    if SpellFlashAddon and type(SpellFlashAddon.SpellCooldown) == "function" then
        local cdLeft = SpellFlashAddon.SpellCooldown(853)
        interruptUnavailable = (cdLeft and select(1, cdLeft) > 0) and true or false
    end
    local interruptRacial = AddonTable.ShouldUseRacial and AddonTable.ShouldUseRacial("interrupt", interruptUnavailable)
    if interruptRacial then
        local racialName = SpellName(interruptRacial)
        if racialName and SpellFlashAddon.Flashable(racialName) then
            SpellFlashAddon.FlashAction(racialName, "Aqua")
            return
        end
    end

    if isProt and AddonTable.RunPROTRotation then if AddonTable.RunPROTRotation(env) then return end
    elseif isRet and AddonTable.RunRETRotation then if AddonTable.RunRETRotation(env) then return end end
end

SLASH_SFPALADINTREES1 = "/sftreesp"
SlashCmdList["SFPALADINTREES"] = function()
    local function P(m) DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[SF Paladin Trees]|r " .. tostring(m)) end
    if not (C_ClassTalents and C_Traits) then P(L.dbg_traits_absent) return end
    local r = SpellFlashAddon.CountTalentTreePoints and SpellFlashAddon.CountTalentTreePoints(TREE_HINTS_PALADIN)
    if not r then P(L.dbg_count_na) return end
    for i, name in ipairs(r.names or {}) do
        P(tostring(i) .. ": " .. tostring(name))
    end
    P("counts:", "PROT=" .. tostring(r.counts and r.counts.PROT) .. " RET=" .. tostring(r.counts and r.counts.RET) .. " HOLY=" .. tostring(r.counts and r.counts.HOLY))
end
