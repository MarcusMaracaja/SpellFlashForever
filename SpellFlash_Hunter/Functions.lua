local AddonName, AddonTable = ...

local L = AddonTable.L
local SFBF = _G["SpellFlashForever"]

AddonTable.Castable = AddonTable.Castable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.Castable)) or {}
AddonTable.VehicleCastable = AddonTable.VehicleCastable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.VehicleCastable)) or {}
AddonTable.ItemCastable = AddonTable.ItemCastable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.ItemCastable)) or {}

-- Diagnóstico de cooldown: /sfcd <spellID> — mostra o que o cliente devolve.
SLASH_SFCD1 = "/sfcd"
SlashCmdList["SFCD"] = function(msg)
    local function P(m) DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[SF CD]|r " .. tostring(m)) end
    local id = tonumber(((msg or ""):gsub("%s+", "")))
    if not id then P(L.cd_usage) return end
    P(string.format(L.cd_spellid, tostring(id), tostring(AddonTable.SpellName and AddonTable.SpellName(id))))

    if C_Spell and type(C_Spell.GetSpellCooldown) == "function" then
        local knownID = SpellFlashAddon and SpellFlashAddon.ResolveKnownID and SpellFlashAddon.ResolveKnownID(id) or id
        if knownID ~= id then
            P(string.format(L.cd_resolve_known, tostring(knownID)))
            local okK, infoK = pcall(C_Spell.GetSpellCooldown, knownID)
            P(string.format(L.cd_getcooldown_rank, tostring(knownID), tostring(okK), type(infoK)))
            if okK and type(infoK) == "table" then
                for k, v in pairs(infoK) do
                    P(string.format(L.cd_rank_info, tostring(k), tostring(v), type(v)))
                end
            end
            local tlK, durK = SpellFlashAddon and SpellFlashAddon.SpellCooldown and SpellFlashAddon.SpellCooldown(knownID)
            P(string.format(L.cd_spellcooldown_rank, tostring(knownID), tostring(tlK), tostring(durK)))
        end
    end

    if C_Spell and type(C_Spell.GetSpellCooldown) == "function" then
        local ok, info = pcall(C_Spell.GetSpellCooldown, id)
        P(string.format(L.cd_getcooldown_raw, tostring(id), tostring(ok), type(info)))
        if ok and type(info) == "table" then
            for k, v in pairs(info) do
                P(string.format(L.cd_info, tostring(k), tostring(v), type(v)))
            end
        elseif ok and info ~= nil then
            P(string.format(L.cd_return, tostring(info)))
        end
    else
        P(L.cd_getcooldown_absent)
    end

    if C_Spell and type(C_Spell.GetSpellCooldownDuration) == "function" then
        local ok, d = pcall(C_Spell.GetSpellCooldownDuration, id)
        P(string.format(L.cd_duration, tostring(ok), type(d), tostring(d)))
        ok, d = pcall(C_Spell.GetSpellCooldownDuration, id, true)
        P(string.format(L.cd_duration_ignoredcf, tostring(ok), type(d), tostring(d)))
    end

    if SpellFlashAddon and SpellFlashAddon.SpellCooldown then
        local tl, dur = SpellFlashAddon.SpellCooldown(id)
        P(string.format(L.cd_raw, tostring(id), tostring(tl), tostring(dur)))
    end

    if SpellFlashAddon and SpellFlashAddon.ResolveKnownID then
        local knownID = SpellFlashAddon.ResolveKnownID(id)
        local slot = SpellFlashAddon.FindActionSlot and SpellFlashAddon.FindActionSlot(knownID)
        P(string.format(L.cd_action_slot, tostring(slot)))
        if slot and SpellFlashAddon.ActionCooldown then
            local sc, sd = SpellFlashAddon.ActionCooldown(slot)
            P(string.format(L.cd_cooldown_slot, tostring(sc), tostring(sd)))
        end
    end

    -- Veredito da própria rotação: o SpellFlashAddon.CheckIfSpellCastable retornaria true/false
    if SpellFlashAddon and SpellFlashAddon.CheckIfSpellCastable then
        local okSample, sample = pcall(function()
            local name = AddonTable.SpellName and AddonTable.SpellName(id)
            if not name then return L.cd_not_found end
            local z = { SpellName = name }
            return SpellFlashAddon.CheckIfSpellCastable(z)
        end)
        P(string.format(L.cd_simulated, tostring(sample)))
    end
end

print(string.format(L.mod_loaded, "Hunter", L.mod_load_functions))

-- Os utilitários de alcance/distância/ranks/kit nome + GetNumPartyMembers/GetNumRaidMembers
-- migraram para o SpellFlashForever (SharedFunctions.lua, H-0083). Delegação abaixo.
AddonTable.HighestKnownRank = (SFBF and SFBF.HighestKnownRank)
AddonTable.ActionSlotRange = (SFBF and SFBF.ActionSlotRange)
AddonTable.IsInMeleeRange = (SFBF and SFBF.IsInMeleeRange)
AddonTable.TargetDistance = (SFBF and SFBF.TargetDistance)
AddonTable.ItemName = (SFBF and SFBF.ItemName)

-- TargetDistance/IsInMeleeRange também migraram para o core (H-0083):
-- AddonTable.TargetDistance / AddonTable.IsInMeleeRange vêm da delegação acima.

local function SpellName(GlobalSpellID)
    return AddonTable.SpellName(GlobalSpellID)
end
local function ItemName(GlobalItemID)
    if SFBF and SFBF.ItemName then return SFBF.ItemName(GlobalItemID) end
    return nil
end

local Buff = SpellFlashAddon.CheckBuff
local Debuff = SpellFlashAddon.CheckDebuff
local Casting = SpellFlashAddon.CastingOrChanneling
local MeleeDistance = SpellFlashAddon.MeleeDistance
local InCombat = SpellFlashAddon.InCombat
local IsCurrentSpellGlobal = (type(IsCurrentSpell) == "function" and IsCurrentSpell) or (SFBF and SFBF.IsCurrentSpell) or function() return false end

function AddonTable.IsStingPushed()
    return SpellFlashAddon.AuraDelay(SpellName(1978))
        or SpellFlashAddon.AuraDelay(SpellName(3034))
        or SpellFlashAddon.AuraDelay(SpellName(3043))
        or IsCurrentSpellGlobal(SpellName(1978))
        or IsCurrentSpellGlobal(SpellName(3034))
        or IsCurrentSpellGlobal(SpellName(3043))
end

function AddonTable.IsStung(unit, any)
    -- Serpent Sting nosso: em combate a aura é secreta → usar crença por cast
    if AddonTable.IsSerpentStingActive and AddonTable.IsSerpentStingActive(unit) then
        return true
    end
    return Debuff({SpellName(3034), SpellName(3043)}, unit, not any)
end

function AddonTable.IsClipped(unit)
    -- Em combate a aura é secreta: podemos acreditar no nosso wing clip (ranked cross-language)
    if AddonTable.IsWingClipActive and AddonTable.IsWingClipActive(unit) then
        return true
    end
    return Debuff(SpellName(2974), unit)
end
function AddonTable.IsConcussiveShot(unit) return Debuff(SpellName(5116), unit) end
function AddonTable.IsMarked(unit) return Debuff(SpellName(1130), unit, nil, true) end
function AddonTable.IsScatterShot(unit) return Debuff(SpellName(19503), unit) end
function AddonTable.IsSniperTrainingActive() return Buff(SpellName(53302)) end
function AddonTable.IsExplosiveTrapActive() return Buff(SpellName(13813), "player") end -- Verifica se armadilha está pronta
function AddonTable.IsBlackArrowActive(unit) return Debuff(SpellName(3674), unit, true) end

-- Verifica se um aspecto nosso está ativo: primeiro a aura (funciona fora de
-- combate); se ilegível (secret em combate), usa a crença do último cast nosso.
local function StripName(n)
    if type(n) ~= "string" then return "" end
    return n:gsub("%s*%b()%s*$", ""):lower()
end

function AddonTable.IsAspectIDActive(id)
    local name = AddonTable.SpellName(id)
    if SpellFlashAddon.CheckBuff(name, "player") then return true end
    local b = AddonTable.AspectBelief
    return not not (b and b.active and b.name == StripName(name))
end

function AddonTable.IsBeastActive() return AddonTable.IsAspectIDActive(13161) end
function AddonTable.IsHawkActive() return AddonTable.IsAspectIDActive(13165) end
function AddonTable.IsMonkeyActive() return AddonTable.IsAspectIDActive(13163) end
function AddonTable.IsCheetahActive() return AddonTable.IsAspectIDActive(5118) end
function AddonTable.IsWildActive() return AddonTable.IsAspectIDActive(20043) end
function AddonTable.IsPackActive() return AddonTable.IsAspectIDActive(13159) end

function AddonTable.IsAspectActive()
    return AddonTable.IsHawkActive() or AddonTable.IsMonkeyActive()
        or AddonTable.IsCheetahActive() or AddonTable.IsBeastActive()
        or AddonTable.IsWildActive() or AddonTable.IsPackActive()
end

function AddonTable.GiveAspect()
    if AddonTable.IsHawkActive() then return SpellName(13165)
    elseif AddonTable.IsMonkeyActive() then return SpellName(13163)
    elseif AddonTable.IsCheetahActive() then return SpellName(5118)
    elseif AddonTable.IsBeastActive() then return SpellName(13161)
    elseif AddonTable.IsWildActive() then return SpellName(20043)
    elseif AddonTable.IsPackActive() then return SpellName(13159)
    end
end

function AddonTable.IsTrueshotActive(unit, mine) return Buff(SpellName(19506), unit, mine) end
function AddonTable.IsFeignDeath(unit)
    unit = unit or "player"
    local ok, hp = pcall(UnitHealth, unit)
    if not ok or hp == nil or hp > 0 then return false end
    local ok2, dead = pcall(UnitIsDeadOrGhost, unit)
    return ok2 and not dead or false
end
function AddonTable.IsRapidFireActive() return Buff(SpellName(3045)) end

-- Auto Shot
AddonTable.Castable["Auto Shot"] = function()
    if SpellFlashAddon.AutoShoot then return false end
    local z = {}
    z.SpellName = SpellName(75)
    z.EnemyTargetNeeded = 1
    z.NotIfActive = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

-- Auto Attack
AddonTable.Castable["Attack"] = function()
    -- Alcance pelo slot de "Atacar" (IsActionInRange) ou sondagem por ranks
    local inRange = AddonTable.IsInMeleeRange and AddonTable.IsInMeleeRange("target")
    if inRange == nil then
        inRange = AddonTable.SafeInteractDistance("target", 3)
    end
    if not inRange then return false end

    local z = {}
    z.SpellName = SpellName(6603)
    z.EnemyTargetNeeded = 1
    z.NotIfActive = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

-- Aspectos (Viper e Dragonhawk não existem no Forever — removidos)
AddonTable.Castable["Aspect of the Hawk"] = function()
    local z = {}
    z.SpellName = SpellName(13165)
    z.Buff = z.SpellName
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Aspect of the Monkey"] = function()
    local z = {}
    z.SpellName = SpellName(13163)
    z.Buff = z.SpellName
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Aspect of the Beast"] = function()
    local z = {}
    z.SpellName = SpellName(13161)
    z.Buff = z.SpellName
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Aspect of the Wild"] = function()
    local z = {}
    z.SpellName = SpellName(20043)
    z.MyBuff = z.SpellName
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Aspect of the Cheetah"] = function()
    local z = {}
    z.SpellName = SpellName(5118)
    z.Buff = z.SpellName
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Aspect of the Pack"] = function()
    local z = {}
    z.SpellName = SpellName(13159)
    z.Buff = z.SpellName
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

-- Stings
AddonTable.Castable["Serpent Sting"] = function()
    -- Já aplicado por nós? (auras secret em combate → usar crença)
    if AddonTable.IsSerpentStingActive and AddonTable.IsSerpentStingActive("target") then
        return false
    end
    local z = {}
    z.SpellName = SpellName(1978)
    z.MyDebuff = z.SpellName
    z.DebuffSlotNeeded = 1
    -- EnemyTargetNeeded removido para ignorar banco de dados de imunidade impreciso
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Viper Sting"] = function()
    local z = {}
    z.SpellName = SpellName(3034)
    z.MyDebuff = z.SpellName
    z.DebuffSlotNeeded = 1
    z.TargetThatUsesManaNeeded = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Scorpid Sting"] = function()
    local z = {}
    z.SpellName = SpellName(3043)
    z.NoRangeCheck = 1 -- Validação manual no Script para priorizar Aggro/PvP
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
-- Shots
AddonTable.Castable["Aimed Shot"] = function()
    local z = {}
    z.SpellName = SpellName(19434)
    z.EnemyTargetNeeded = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Tranquilizing Shot"] = function()
    local z = {}
    z.SpellName = SpellName(19801)
    z.EnemyTargetNeeded = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Arcane Shot"] = function()
    local z = {}
    z.SpellName = SpellName(3044)
    z.EnemyTargetNeeded = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Multi-Shot"] = function()
    local z = {}
    z.SpellName = SpellName(2643)
    z.EnemyTargetNeeded = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Concussive Shot"] = function()
    local z = {}
    z.SpellName = SpellName(5116)
    z.Debuff = z.SpellName
    z.EnemyTargetNeeded = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Scatter Shot"] = function()
    local z = {}
    z.SpellName = SpellName(19503)
    z.EnemyTargetNeeded = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Rapid Fire"] = function()
    local z = {}
    z.SpellName = SpellName(3045)
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Bestial Wrath"] = function()
    local z = {}
    z.SpellName = SpellName(19574)
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Intimidation"] = function()
    if not UnitExists("pettarget") or SpellFlashAddon.IsCrowedControlled("pettarget") then return false end
    local z = {}
    z.SpellName = SpellName(19577)
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Mend Pet"] = function()
    local z = {}
    z.SpellName = SpellName(136)
    z.Buff = z.SpellName
    z.BuffUnit = "pet"
    z.NotIfActive = 1 -- Não recomenda se o HoT já estiver rodando
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Call Pet"] = function()
    -- Pet morto (mesmo sem corpo): Call Pet falharia com "Your pet is dead"
    if AddonTable.PetIsDead then return false end
    if UnitExists("pet") and not UnitIsDead("pet") then return false end
    local z = {}
    z.SpellName = SpellName(883)
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Revive Pet"] = function()
    -- Se o pet existe e está vivo, não há o que reviver.
    if UnitExists("pet") and not UnitIsDeadOrGhost("pet") then return false end
    -- Pet inexistente e nunca detectado como morto (dispensado/estábulo): nada a reviver.
    if not UnitExists("pet") and not AddonTable.PetIsDead then return false end

    local z = {}
    z.SpellName = SpellName(34497)
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Volley"] = function()
    local z = {}
    z.SpellName = SpellName(1510)
    z.EnemyTargetNeeded = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

-- HUNTER'S MARK (CORRIGIDO)
AddonTable.Castable["Hunter's Mark"] = function()
    local z = {}
    z.SpellName = SpellName(1130)
    z.EnemyTargetNeeded = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

-- TRUESHOT AURA (CORRIGIDO)
AddonTable.Castable["Trueshot Aura"] = function()
    local z = {}
    z.SpellName = SpellName(19506)
    z.MyBuff = z.SpellName
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

-- Armadilhas
AddonTable.Castable["Freezing Trap"] = function()
    local z = {}
    z.SpellName = SpellName(1499)
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Frost Trap"] = function()
    local z = {}
    z.SpellName = SpellName(13809)
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Explosive Trap"] = function()
    local z = {}
    z.SpellName = SpellName(13813)
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Immolation Trap"] = function()
    local z = {}
    z.SpellName = SpellName(13795)
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
-- Rastreamento (Tracking)
AddonTable.Castable["Track Beasts"] = function()
    local z = { SpellName = SpellName(1494) }
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Track Humanoids"] = function()
    local z = { SpellName = SpellName(19883) }
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Track Undead"] = function()
    local z = { SpellName = SpellName(19884) }
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Track Dragonkin"] = function()
    local z = { SpellName = SpellName(19882) }
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Track Elementals"] = function()
    local z = { SpellName = SpellName(19880) }
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Track Demons"] = function()
    local z = { SpellName = SpellName(19878) }
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Track Giants"] = function()
    local z = { SpellName = SpellName(19879) }
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Track Hidden"] = function()
    local z = { SpellName = SpellName(19885) }
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

function AddonTable.IsCorrectTrackingActive(spellID)
    local targetName = AddonTable.SpellName(spellID)
    if not targetName then return false end

    -- API moderna (Interface 16001): C_Minimap.GetNumTrackingTypes / C_Minimap.GetTrackingInfo
    local getNum = C_Minimap and C_Minimap.GetNumTrackingTypes
    local getInfo = C_Minimap and C_Minimap.GetTrackingInfo
    if type(getNum) == "function" and type(getInfo) == "function" then
        for i = 1, getNum() do
            local ok, info = pcall(getInfo, i)
            if ok and type(info) == "table" and info.name == targetName then
                return not not info.active
            end
        end
        return false
    end

    -- Fallback legado (se existir)
    if type(GetNumTrackingTypes) == "function" and type(GetTrackingInfo) == "function" then
        for i = 1, GetNumTrackingTypes() do
            local name, _, active = GetTrackingInfo(i)
            if name == targetName then
                return not not active
            end
        end
    end
    return false
end

function AddonTable.IsTargetTranquilizable(unit)
    unit = unit or "target"
    local okCA, canAttack = pcall(UnitCanAttack, "player", unit)
    if not okCA or not canAttack then return false end
    
    -- Se o alvo estiver sob imunidades totais (Bubble/Ice Block), o tiro falhará.
    if AddonTable.IsTargetImmune(unit) then return false end

    for i = 1, 40 do
        local aura = nil
        local name, debuffType = nil, nil
        if C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function" then
            local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
            if ok and data then
                name = data.name
                debuffType = data.dispelName -- em alguns clientes: tipo de magia do efeito
                if _G.issecretvalue and issecretvalue(name) then break end
            else
                break
            end
        elseif type(UnitBuff) == "function" then
            local ok, n, _, _, _, dt = pcall(UnitBuff, unit, i)
            if ok then name, debuffType = n, dt end
        end
        if not name then break end
        
        -- 1. Dispela Efeitos Mágicos (Funciona em todos)
        if debuffType == "Magic" then return true end
        
        -- 2. Dispela Frenzy/Enrage (Apenas NPCs no WotLK)
        local lowerName = string.lower(name)
        if (lowerName:find("frenzy") or lowerName:find("frenesim") or lowerName:find("enrage") or lowerName:find("enraivecer"))
           and not lowerName:find("berserk") and not UnitIsPlayer(unit) then
            return true
        end
    end
    return false
end

-- Melee
AddonTable.Castable["Raptor Strike"] = function()
    local inRange = AddonTable.IsInMeleeRange and AddonTable.IsInMeleeRange("target")
    if inRange == nil then
        inRange = AddonTable.SafeInteractDistance("target", 3) -- nil em combate (protegida)
    end
    if not inRange then return false end

    local z = {}
    z.SpellName = SpellName(2973)
    z.EnemyTargetNeeded = 1
    z.NotIfActive = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Mongoose Bite"] = function()
    local inRange = AddonTable.IsInMeleeRange and AddonTable.IsInMeleeRange("target")
    if inRange == nil then
        inRange = AddonTable.SafeInteractDistance("target", 3) -- nil em combate (protegida)
    end
    if not inRange then return false end

    local z = {}
    z.SpellName = SpellName(1495)
    z.EnemyTargetNeeded = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Counterattack"] = function()
    local z = {}
    z.SpellName = SpellName(19306)
    z.EnemyTargetNeeded = 1
    z.NotIfActive = 1
    z.NoRangeCheck = 1 -- A verificação de alcance já é feita pelo IsSpellInRange no Script
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Wing Clip"] = function()
    local z = {}
    z.SpellName = SpellName(2974)
    z.Debuff = z.SpellName
    z.EnemyTargetNeeded = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

-- Defensivos
AddonTable.Castable["Disengage"] = function()
    local z = {}
    z.SpellName = SpellName(781)
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Deterrence"] = function()
    local z = {}
    z.SpellName = SpellName(19263) -- Deterrence no Forever (Survival, tree 3)
    return SpellFlashAddon.CheckIfSpellCastable(z)
end
AddonTable.Castable["Feign Death"] = function()
    if AddonTable.IsFeignDeath() then return false end
    local z = {}
    z.SpellName = SpellName(5384)
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

-- IsTargetEnemyPlayer/IsTargetInterruptibleCasting/IsTargetImmune migraram para o
-- core (SharedFunctions.lua, H-0083). Delgação abaixo.
AddonTable.IsTargetEnemyPlayer = SFBF and SFBF.IsTargetEnemyPlayer
AddonTable.IsTargetInterruptibleCasting = SFBF and SFBF.IsTargetInterruptibleCasting
AddonTable.IsTargetImmune = SFBF and SFBF.IsTargetImmune

-- =====================================================
-- ROTATION PREDICATES (editor visual / declaração de rotação)
-- Predicados oferecidos no menu de condição da GUI (/sf → Hunter).
-- =====================================================
AddonTable.RotationPredicates = AddonTable.RotationPredicates or {}
local P = AddonTable.RotationPredicates
P["always"]           = { label = L.pred_always, fn = function(env) return true end }
P["not_too_close_ranged"] = { label = L.pred_ranged, fn = function(env) return not env.tooCloseForRanged and true or false end }
P["has_enemy"]        = { label = L.pred_has_enemy, fn = function(env) return env.hasActiveEnemy and true or false end }
P["in_combat"]        = { label = L.pred_in_combat, fn = function(env) return env.inCombat and true or false end }
P["is_aoe"]           = { label = L.pred_aoe2, fn = function(env) return env.isAoE and true or false end }
P["aoe_not_too_close"] = { label = L.pred_aoe_dead_zone,
    fn = function(env) return env.isAoE and not env.tooCloseForRanged and true or false end }
P["aoe_not_pvp_mana15"] = { label = L.pred_aoe_pve_mana15,
    fn = function(env) return env.isAoE and not env.isPvP and (env.manaPct or 100) > 15 end }
P["not_aoe_not_too_close"] = { label = L.pred_single_dead_zone,
    fn = function(env) return env.hasActiveEnemy and not env.tooCloseForRanged and not env.isAoE and true or false end }
P["enemy_in_combat_not_too_close"] = { label = L.pred_enemy_combat_dead_zone,
    fn = function(env)
        return env.hasActiveEnemy and not env.tooCloseForRanged and (type(UnitAffectingCombat) == "function" and UnitAffectingCombat("player")) and true or false
    end }
P["enemy_interruptible_not_cc_not_too_close"] = { label = L.pred_interruptible_nocc,
    fn = function(env)
        if not (env.hasActiveEnemy and not env.tooCloseForRanged) then return false end
        if SpellFlashAddon.IsCrowedControlled and SpellFlashAddon.IsCrowedControlled("target") then return false end
        return AddonTable.IsTargetInterruptibleCasting and AddonTable.IsTargetInterruptibleCasting("target") and true or false
    end }
P["pet_interruptible"] = { label = L.pred_pet_interruptible,
    fn = function(env)
        if not (env.hasActiveEnemy and not env.tooCloseForRanged) then return false end
        if not env.petAlive then return false end
        if SpellFlashAddon.IsCrowedControlled and SpellFlashAddon.IsCrowedControlled("target") then return false end
        return AddonTable.IsTargetInterruptibleCasting and AddonTable.IsTargetInterruptibleCasting("target") and true or false
    end }
P["pvp_target_mana"]   = { label = L.pred_pvp_target_mana,
    fn = function(env)
        if not (env.isPvP and env.hasActiveEnemy) then return false end
        return type(UnitPowerType) == "function" and UnitPowerType("target") == 0 and true or false
    end }
P["pvp_target_melee_class"] = { label = L.pred_pvp_target_melee,
    fn = function(env)
        if not (env.isPvP and env.hasActiveEnemy) then return false end
        local _, cls = UnitClass("target")
        return (cls == "WARRIOR" or cls == "ROGUE") and true or false
    end }
P["no_viper_sting"]    = { label = L.pred_no_viper,
    fn = function(env) return not SpellFlashAddon.CheckDebuff(SpellName(3034), "target", true) and true or false end }
P["no_scorpid_sting"]  = { label = L.pred_no_scorpid,
    fn = function(env) return not SpellFlashAddon.CheckDebuff(SpellName(3043), "target", true) and true or false end }
P["viper_pvp_mana"]    = { label = L.pred_pvp_viper,
    fn = function(env)
        if not P["pvp_target_mana"].fn(env) then return false end
        return not SpellFlashAddon.CheckDebuff(SpellName(3034), "target", true) and true or false
    end }
P["scorpid_pvp_melee"] = { label = L.pred_pvp_scorpid,
    fn = function(env)
        if not P["pvp_target_melee_class"].fn(env) then return false end
        return not SpellFlashAddon.CheckDebuff(SpellName(3043), "target", true) and true or false
    end }
P["no_serpent_sting"]  = { label = L.pred_no_serpent,
    fn = function(env)
        return env.hasActiveEnemy and not env.isMelee and not (AddonTable.IsStung and AddonTable.IsStung("target")) and true or false
    end }
P["no_any_sting"]      = { label = L.pred_no_any_sting,
    fn = function(env)
        if not (env.hasActiveEnemy and not env.tooCloseForRanged) then return false end
        if AddonTable.IsSerpentStingActive and AddonTable.IsSerpentStingActive("target") then return false end
        if SpellFlashAddon.CheckDebuff(SpellName(3034), "target", true) then return false end
        if SpellFlashAddon.CheckDebuff(SpellName(3043), "target", true) then return false end
        return true
    end }
P["melee_or_close"]    = { label = L.pred_melee_dead_zone,
    fn = function(env) return (env.tooCloseForRanged or env.isMelee) and true or false end }
P["dead_zone_not_melee"] = { label = L.pred_dead_zone_not_melee,
    fn = function(env) return env.tooCloseForRanged and not env.isMelee and true or false end }
P["pvp_not_clipped_melee"] = { label = L.pred_pvp_no_clip,
    fn = function(env)
        if not (env.tooCloseForRanged or env.isMelee) then return false end
        if not env.isPvP then return false end
        return not (AddonTable.IsClipped and AddonTable.IsClipped("target")) and true or false
    end }
P["melee_enemy_interruptible"] = { label = L.pred_melee_interruptible,
    fn = function(env)
        if not (env.isMelee and env.hasActiveEnemy) then return false end
        return AddonTable.IsTargetInterruptibleCasting and AddonTable.IsTargetInterruptibleCasting("target") and true or false
    end }
P["within_8_aoe"]      = { label = L.pred_within_8_aoe,
    fn = function(env) return env.targetDistance and env.targetDistance <= 8 and env.hasActiveEnemy and env.isAoE end }
P["within_8_st"]       = { label = L.pred_within_8_st,
    fn = function(env) return env.targetDistance and env.targetDistance <= 8 and env.hasActiveEnemy and not env.isAoE end }
P["no_serpent_pve"]    = { label = L.pred_pve_no_serpent,
    fn = function(env)
        if not (env.hasActiveEnemy and not env.isMelee and not env.isPvP) then return false end
        return not (AddonTable.IsStung and AddonTable.IsStung("target")) and true or false
    end }
P["no_serpent_mm"]     = { label = L.pred_no_serpent_belief,
    fn = function(env)
        if not (env.hasActiveEnemy and not env.isMelee) then return false end
        return not (AddonTable.IsSerpentStingActive and AddonTable.IsSerpentStingActive("target")) and true or false
    end }
P["pvp_hp30"]          = { label = L.pred_pvp_hp30,
    fn = function(env)
        if not env.isPvP then return false end
        local hp = env.myHP or 100
        if hp >= 30 then return false end
        return not (SpellFlashAddon.CheckBuff and SpellFlashAddon.CheckBuff(SpellName(19263), "player")) and true or false
    end }

-- =====================================================
-- Prefixo COMUM a todas as specs de Hunter (melee / dead zone)
-- Antes hardcoded em HandleMeleeAndKiting; agora nós declarados —
-- aparecem (e são editáveis) na rotação de SV, BM e MM.
-- Ordem original preservada (Disengage → dano → kiting → traps).
-- =====================================================
AddonTable.HunterMeleeNodes = {
    { id = "disengage",      spellID = 781,   name = "Disengage",      color = "Red",    condition = "dead_zone_not_melee" },
    { id = "counterattack",  spellID = 19306, name = "Counterattack",  color = "Yellow", condition = "melee_or_close" },
    { id = "mongoose_bite",  spellID = 1495,  name = "Mongoose Bite",  color = "Yellow", condition = "melee_or_close" },
    { id = "raptor_strike",  spellID = 2973,  name = "Raptor Strike",  color = "Yellow", condition = "melee_or_close" },
    { id = "wing_clip",      spellID = 2974,  name = "Wing Clip",      color = "Pink",   condition = "pvp_not_clipped_melee" },
    { id = "freezing_trap",  spellID = 1499,  name = "Freezing Trap",  color = "Aqua",   condition = "melee_enemy_interruptible" },
    { id = "explosive_trap", spellID = 13813, name = "Explosive Trap", color = "Purple", condition = "within_8_aoe" },
    { id = "immolation_trap", spellID = 13795, name = "Immolation Trap", color = "Purple", condition = "within_8_st" },
}

-- Concatena o prefixo comum de melee aos nós específicos da spec
function AddonTable.ConcatCommonNodes(common, nodes)
    local out = {}
    for _, n in ipairs(common or {}) do out[#out + 1] = n end
    for _, n in ipairs(nodes or {}) do out[#out + 1] = n end
    return out
end