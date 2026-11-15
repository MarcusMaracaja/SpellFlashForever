-- SpellFlash_Paladin / Functions.lua
-- Castable table do Paladin do Forever (Interface 16001). Forever POSSUI skills NOVAS
-- ainda não verificadas em jogo: Holy Strike (680), Holy Shield (28153),
-- Swift Judgement, Templar's Bulwark. IDs verificados pelo Spy (2026-11-14):
--   Judgement 20271 (nv4) · Righteous Fury 25780 (nv16) · Seal of Command 20915 (nv30)
--   Seal of Righteousness 20289 (nv26) · Hammer of Wrath 24275 (nv44) · Seal of Crs 20308
--   NOTA: Templar's Bulwark e Swift Judgement (PROT) ainda NÃO tem ID confirmado —
--   quando aparecer in-game, adicionar com /dump GetSpellInfo(id).
-- Estrutura igual aos outros módulos: AddonTable.Castable["Nome"](Fn) → bool.

local AddonName, AddonTable = ...
local L = AddonTable.L
local SFBF = _G["SpellFlashForever"]

AddonTable.Castable = AddonTable.Castable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.Castable)) or {}
AddonTable.VehicleCastable = AddonTable.VehicleCastable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.VehicleCastable)) or {}
AddonTable.ItemCastable = AddonTable.ItemCastable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.ItemCastable)) or {}

print(string.format(L.mod_loaded, "Paladin", L.mod_load_functions))

local function SpellName(id) return AddonTable.SpellName(id) end
local Buff = SpellFlashAddon.CheckBuff
local Casting = SpellFlashAddon.CastingOrChanneling
local MeleeDistance = SpellFlashAddon.MeleeDistance
local CheckCastable = SpellFlashAddon.CheckIfSpellCastable

local function MeleeOK()
    if not AddonTable.IsInMeleeRange then return true end
    local r = AddonTable.IsInMeleeRange("target")
    return r == nil or r == true
end

-- =====================================================
-- SEALS / SELF-BUFFS
-- =====================================================
AddonTable.Castable["Righteous Fury"] = function()
    local z = {}
    z.SpellID = 25780
    z.SpellName = SpellName(25780)
    z.Buff = z.SpellName
    z.BuffUnit = "player"
    return CheckCastable(z)
end
AddonTable.Castable["Seal of Command"] = function()
    local z = {}
    z.SpellID = 20915
    z.SpellName = SpellName(20915)
    z.Buff = z.SpellName
    z.BuffUnit = "player"
    return CheckCastable(z)
end
AddonTable.Castable["Seal of Righteousness"] = function()
    local z = {}
    z.SpellID = 20289
    z.SpellName = SpellName(20289)
    z.Buff = z.SpellName
    z.BuffUnit = "player"
    return CheckCastable(z)
end
AddonTable.Castable["Holy Shield"] = function()
    local z = {}
    z.SpellID = 28153
    z.SpellName = SpellName(28153)
    z.Buff = z.SpellName
    z.BuffUnit = "player"
    return CheckCastable(z)
end

-- =====================================================
-- DANO / AMEAÇA
-- =====================================================
AddonTable.Castable["Consecration"] = function()
    local z = {}
    z.SpellID = 20116
    z.SpellName = SpellName(20116)
    z.NoRangeCheck = 1
    return CheckCastable(z)
end
AddonTable.Castable["Judgement"] = function()
    local z = {}
    z.SpellID = 20271
    z.SpellName = SpellName(20271)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Holy Strike"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellID = 680
    z.SpellName = SpellName(680)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Hammer of Wrath"] = function()
    local z = {}
    z.SpellID = 24275
    z.SpellName = SpellName(24275)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Exorcism"] = function()
    local z = {}
    z.SpellID = 10308
    z.SpellName = SpellName(10308)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Hammer of Justice"] = function()
    if not Casting(nil, "target", 1) then return false end
    local z = {}
    z.SpellID = 853
    z.SpellName = SpellName(853)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end

-- =====================================================
-- ROTATION PREDICATES (editor visual / declaração de rotação)
-- =====================================================
AddonTable.RotationPredicates = AddonTable.RotationPredicates or {}
local P = AddonTable.RotationPredicates
P["always"]        = { label = L.pred_always, fn = function(env) return true end }
P["is_aoe"]        = { label = L.pred_aoe2, fn = function(env) return env.isAoE and true or false end }
P["aoe_and_enemy"] = { label = L.pred_aoe_and_enemy, fn = function(env) return env.isAoE and env.hasActiveEnemy and true or false end }
P["has_enemy"]     = { label = L.pred_has_enemy, fn = function(env) return env.hasActiveEnemy and true or false end }
P["enemy_casting"] = { label = L.pred_casting_stun,
    fn = function(env)
        if not env.hasActiveEnemy then return false end
        return AddonTable.IsTargetInterruptibleCasting and AddonTable.IsTargetInterruptibleCasting("target") and true or false
    end }
P["target_hp20"]   = { label = L.pred_target_hp20, fn = function(env) return (env.targetHP or 100) < 20 end }
P["undead_or_demon"] = { label = L.pred_undead_or_demon,
    fn = function(env)
        if not env.hasActiveEnemy then return false end
        local t = UnitCreatureType and UnitCreatureType("target")
        if type(t) ~= "string" then return false end
        local low = t:lower()
        return (low:find("undead") or low:find("morto") or low:find("demon")
            or low:find("demônio") or low:find("demoní")) and true or false
    end }
P["not_righteous_fury_up"] = { label = L.pred_prot_fury,
    fn = function(env)
        if env.spec ~= "PROT" then return false end
        return not (AddonTable.IsSelfBuffUp and AddonTable.IsSelfBuffUp(25780)) and true or false
    end }
P["holy_shield_missing"] = { label = L.pred_prot_shield,
    fn = function(env)
        if env.spec ~= "PROT" then return false end
        return not (AddonTable.IsSelfBuffUp and AddonTable.IsSelfBuffUp(28153)) and true or false
    end }
P["seal_of_command_missing"] = { label = L.pred_ret_seal,
    fn = function(env)
        if env.spec ~= "RET" then return false end
        return not (AddonTable.IsSelfBuffUp and AddonTable.IsSelfBuffUp(20915)) and true or false
    end }

-- =====================================================
-- Prefixo COMUM a PROT/RET (Hammer of Justice vs casts)
-- =====================================================
AddonTable.PaladinCommonNodes = {
    { id = "hammer_of_justice", spellID = 853, name = "Hammer of Justice", color = "Aqua", condition = "enemy_casting" },
}

function AddonTable.ConcatCommonNodes(common, nodes)
    local out = {}
    for _, n in ipairs(common or {}) do out[#out + 1] = n end
    for _, n in ipairs(nodes or {}) do out[#out + 1] = n end
    return out
end
