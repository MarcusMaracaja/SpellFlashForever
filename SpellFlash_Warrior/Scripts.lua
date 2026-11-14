-- SpellFlash_Warrior / Scripts.lua
-- Orquestra mestre do módulo Warrior do Forever (Interface 16001).
-- Detecção de spec por pontos em árvore via C_Traits (a árvore com mais pontos
-- vence; empate → Arms). Override manual em /sf → Warrior.
local AddonName, AddonTable = ...

-- Expõe o módulo para o core (debug, /sf status → GetDetectedRace)
_G.SpellFlash_Warrior = AddonTable

if not AddonTable.ShouldUseRacial then AddonTable.ShouldUseRacial = function() return nil end end
if not AddonTable.ShouldUseTrinket then AddonTable.ShouldUseTrinket = function() return nil end end

local L = AddonTable.Localize
local SpellFlashAddon = SpellFlashAddon

local TREE_HINTS_WARRIOR = {
    ARMS = { "arms", "armas", "weapon", "metal", "blade" },
    FURY = { "fury", "fúria", "furia" },
    PROT = { "protect", "prote", "guard", "guardi" },
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

-- Expõe p/ o motor declarativo (RunDeclaredRotation)
AddonTable.TryFlash = TryFlash

-- Contagem de inimigos perto (nameplates) — mesmo padrão usado no Shaman
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
    -- Só executa se o jogador for Warrior
    local _, myClass = UnitClass("player")
    if myClass ~= "WARRIOR" then return end
    local env = {
        hasActiveEnemy = x.ActiveEnemy or (UnitExists("target") and UnitCanAttack("player", "target")),
        inCombat = SpellFlashAddon.InCombat and SpellFlashAddon.InCombat(),
        isMelee = AddonTable.IsInMeleeRange and AddonTable.IsInMeleeRange("target"),
        myHP = SpellFlashAddon.HealthPercent and SpellFlashAddon.HealthPercent("player") or 100,
        targetHP = SpellFlashAddon.HealthPercent and SpellFlashAddon.HealthPercent("target") or 100,
        rage = UnitPower("player") or 0,
        enemies = GetAoECount(),
        isAoE = GetAoECount() >= 2,
        hasShield = AddonTable.IsShieldEquipped and AddonTable.IsShieldEquipped() or false,
        currentStance = AddonTable.GetCurrentStance and AddonTable.GetCurrentStance() or 0,
        isPvP = AddonTable.IsTargetEnemyPlayer and AddonTable.IsTargetEnemyPlayer("target") or false,
        isBoss = (UnitClassification and string.find(string.lower(UnitClassification("target") or ""), "boss")) ~= nil,
        targetCasting = AddonTable.IsTargetInterruptibleCasting and AddonTable.IsTargetInterruptibleCasting("target"),
        isCCd = SpellFlashAddon.IsCrowedControlled and SpellFlashAddon.IsCrowedControlled("player") or false,
    }

    -- =====================================================
    -- DETECÇÃO DE SPEC (override → pontos por árvore; empate → Arms)
    -- =====================================================
    local override = SpellFlashAddon.GetModuleConfig and SpellFlashAddon.GetModuleConfig(AddonName, "spec_override") or nil

    if AddonTable.TalentCountCache == nil then
        AddonTable.TalentCountCache = false
        AddonTable.TalentCountCache = SpellFlashAddon.CountTalentTreePoints and SpellFlashAddon.CountTalentTreePoints(TREE_HINTS_WARRIOR, { "ARMS", "FURY", "PROT" }) or false
    end
    local counts = type(AddonTable.TalentCountCache) == "table" and AddonTable.TalentCountCache.counts or nil
    local pointsArms, pointsFury, pointsProt = 0, 0, 0
    if counts then
        pointsArms, pointsFury, pointsProt = tonumber(counts.ARMS) or 0, tonumber(counts.FURY) or 0, tonumber(counts.PROT) or 0
    end

    local bestTree = nil
    if pointsArms >= pointsFury and pointsArms >= pointsProt and pointsArms > 0 then
        bestTree = "ARMS"
    elseif pointsFury > pointsProt and pointsFury > 0 then
        bestTree = "FURY"
    elseif pointsProt > 0 then
        bestTree = "PROT"
    end

    local isArms, isFury, isProt, specSource
    if override == "ARMS" then isArms, isFury, isProt, specSource = true, false, false, "override"
    elseif override == "FURY" then isArms, isFury, isProt, specSource = false, true, false, "override"
    elseif override == "PROT" then isArms, isFury, isProt, specSource = false, false, true, "override"
    elseif bestTree == "ARMS" then isArms, isFury, isProt, specSource = true, false, false, "Arms=" .. tostring(pointsArms)
    elseif bestTree == "FURY" then isArms, isFury, isProt, specSource = false, true, false, "Fury=" .. tostring(pointsFury)
    elseif bestTree == "PROT" then isArms, isFury, isProt, specSource = false, false, true, "Protection=" .. tostring(pointsProt)
    elseif SpellFlashAddon.IsSpellKnown and SpellFlashAddon.IsSpellKnown(23922) then
        isArms, isFury, isProt, specSource = false, false, true, "Prot(23922)"
    elseif SpellFlashAddon.IsSpellKnown and SpellFlashAddon.IsSpellKnown(23881) then
        isArms, isFury, isProt, specSource = false, true, false, "Fury(23881)"
    elseif SpellFlashAddon.IsSpellKnown and SpellFlashAddon.IsSpellKnown(12294) then
        isArms, isFury, isProt, specSource = true, false, false, "Arms(12294)"
    else
        isArms, isFury, isProt, specSource = true, false, false, "padrão Arms" end

    -- Mensagem de Inicialização (uma vez por sessão) + saudação racial
    if not AddonTable.SpecMessageSent then
        local msg = "|cFF00FF00[SF Warrior]|r "
        if isArms then
            print(msg.."|cFF69CCF0Arms:|r Ode ao eixo da guerra — que cada golpe seja uma sentença!")
        elseif isFury then
            print(msg.."|cFFFF8000Fury:|r Sangue na lâmina — a fúria te revigorará!")
        else
            print(msg.."|cFF ABD473Protection:|r Baluarte — sua muralha nunca cairá!")
        end
        print(msg.."|cFFCCCCCCspec:|r " .. tostring(specSource) .. " (Arms=" .. tostring(pointsArms) .. " Fury=" .. tostring(pointsFury) .. " Protection=" .. tostring(pointsProt) .. ")")
        if AddonTable.ShowRacialInfo and not AddonTable.RacialGreetingSent then
            AddonTable.ShowRacialInfo()
            AddonTable.RacialGreetingSent = true
        end
        AddonTable.SpecMessageSent = true
    end

    if not env.hasActiveEnemy then
        -- Sem alvo: a cadeia declarada ainda cobre Battle Shout (fora de
        -- combate) e stances/interrupt; o resto da spec exige alvo/estado.
        -- (Fallback autossuficiência fica por conta da declaração agora.)
        if isArms and AddonTable.RunArmsRotation then AddonTable.RunArmsRotation(env)
        elseif isFury and AddonTable.RunFuryRotation then AddonTable.RunFuryRotation(env)
        elseif isProt and AddonTable.RunProtectionRotation then AddonTable.RunProtectionRotation(env) end
        return
    end

    -- =====================================================
    -- CC / PvP (racial + trinket via core)
    -- =====================================================
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

    -- Interrupção (Pummel/Berserker Stance) agora faz parte da declaração
    -- (prefixo comum WarriorCommonNodes, editável em /sf → Warrior).

    -- =====================================================
    -- Chamada da Spec
    -- =====================================================
    if isArms and AddonTable.RunArmsRotation then if AddonTable.RunArmsRotation(env) then return end
    elseif isFury and AddonTable.RunFuryRotation then if AddonTable.RunFuryRotation(env) then return end
    elseif isProt and AddonTable.RunProtectionRotation then if AddonTable.RunProtectionRotation(env) then return end end
end

-- Diagnóstico de talentos: /sftrees — mostra a árvore localizada vista pelo cliente
SLASH_SFWARRIORTREES1 = "/sftreesw"
SlashCmdList["SFWARRIORTREES"] = function()
    local function P(m) DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[SF Warrior Trees]|r " .. tostring(m)) end
    if not (C_ClassTalents and C_Traits) then P("C_ClassTalents/C_Traits ausentes") return end
    local r = SpellFlashAddon.CountTalentTreePoints and SpellFlashAddon.CountTalentTreePoints(TREE_HINTS_WARRIOR)
    if not r then P("Contagem indisponível") return end
    for i, name in ipairs(r.names or {}) do
        P(tostring(i) .. ": " .. tostring(name))
    end
    P("counts:", "ARMS=" .. tostring(r.counts and r.counts.ARMS) .. " FURY=" .. tostring(r.counts and r.counts.FURY) .. " PROT=" .. tostring(r.counts and r.counts.PROT))
end

