-- SpellFlash_Warrior / Functions.lua
-- Castable table do Warrior do Forever (Interface 16001), IDs verificados em
-- warcraftmaps.com ("In the game files", patch 1.60.1) / wowhead forever.
-- Estrutura em árvore de delegações: helpers genéricos vivem no core; aqui só
-- ficam os Castables e isShieldEquipped/currentStance do Warrior.

local AddonName, AddonTable = ...
local L = AddonTable.L
local SFBF = _G["SpellFlashForever"]

AddonTable.Castable = AddonTable.Castable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.Castable)) or {}
AddonTable.VehicleCastable = AddonTable.VehicleCastable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.VehicleCastable)) or {}
AddonTable.ItemCastable = AddonTable.ItemCastable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.ItemCastable)) or {}

print(string.format(L.mod_loaded, "Warrior", L.mod_load_functions))

local function SpellName(id) return AddonTable.SpellName(id) end
local Buff = SpellFlashAddon.CheckBuff
local MeleeDistance = SpellFlashAddon.MeleeDistance
local Casting = SpellFlashAddon.CastingOrChanneling
local CheckCastable = SpellFlashAddon.CheckIfSpellCastable

-- Distância melee relevante: nil/true = pode ser uso; false = fora de alcance
local function MeleeOK()
    if not AddonTable.IsInMeleeRange then return true end
    local r = AddonTable.IsInMeleeRange("target")
    return r == nil or r == true
end

-- =====================================================
-- POSTURAS (Stances)
-- =====================================================
AddonTable.Castable["Battle Stance"] = function()
    local z = {}
    z.SpellName = SpellName(2457)
    if SpellFlashAddon.Form and SpellFlashAddon.Form(SpellName(2457)) then return false end
    return CheckCastable(z)
end
AddonTable.Castable["Defensive Stance"] = function()
    local z = {}
    z.SpellName = SpellName(71)
    if SpellFlashAddon.Form and SpellFlashAddon.Form(SpellName(71)) then return false end
    return CheckCastable(z)
end
AddonTable.Castable["Berserker Stance"] = function()
    local z = {}
    z.SpellName = SpellName(2458)
    if SpellFlashAddon.Form and SpellFlashAddon.Form(SpellName(2458)) then return false end
    return CheckCastable(z)
end

-- =====================================================
-- GAP CLOSER / OPENING
-- =====================================================
AddonTable.Castable["Charge"] = function()
    local z = {}
    z.SpellName = SpellName(100)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Intercept"] = function()
    local z = {}
    z.SpellName = SpellName(20252)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Bloodrage"] = function()
    local z = {}
    z.SpellName = SpellName(2687)
    return CheckCastable(z)
end
AddonTable.Castable["Berserker Rage"] = function()
    local z = {}
    z.SpellName = SpellName(18499)
    return CheckCastable(z)
end
AddonTable.Castable["Recklessness"] = function()
    local z = {}
    z.SpellName = SpellName(1719)
    z.NotIfActive = 1
    return CheckCastable(z)
end
AddonTable.Castable["Retaliation"] = function()
    local z = {}
    z.SpellName = SpellName(20230)
    z.NotIfActive = 1
    return CheckCastable(z)
end
AddonTable.Castable["Death Wish"] = function()
    local z = {}
    z.SpellName = SpellName(12292)
    z.NotIfActive = 1
    return CheckCastable(z)
end
AddonTable.Castable["Last Stand"] = function()
    local z = {}
    z.SpellName = SpellName(12975)
    return CheckCastable(z)
end
AddonTable.Castable["Shield Wall"] = function()
    local z = {}
    z.SpellName = SpellName(871)
    return CheckCastable(z)
end
AddonTable.Castable["Battle Shout"] = function()
    local z = {}
    z.SpellName = SpellName(6673)
    z.Buff = z.SpellName
    return CheckCastable(z)
end
AddonTable.Castable["Demoralizing Shout"] = function()
    local z = {}
    z.SpellName = SpellName(1160)
    z.Debuff = z.SpellName
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Challenging Shout"] = function()
    local z = {}
    z.SpellName = SpellName(1161)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Intimidating Shout"] = function()
    local z = {}
    z.SpellName = SpellName(5246)
    z.NotIfActive = 1
    return CheckCastable(z)
end
AddonTable.Castable["Piercing Howl"] = function()
    local z = {}
    z.SpellName = SpellName(12323)
    z.NotIfActive = 1
    return CheckCastable(z)
end

-- =====================================================
-- ATAQUES / DANO
-- =====================================================
AddonTable.Castable["Attack"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(6603) -- Auto Attack
    z.EnemyTargetNeeded = 1
    z.NotIfActive = 1
    return CheckCastable(z)
end
AddonTable.Castable["Heroic Strike"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(78)
    z.EnemyTargetNeeded = 1
    z.NotIfActive = 1
    return CheckCastable(z)
end
AddonTable.Castable["Slam"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(1464)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Cleave"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(845)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Mortal Strike"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(12294)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Overpower"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(7384)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Whirlwind"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(1680)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Execute"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(5308)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Rend"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(772)
    z.EnemyTargetNeeded = 1
    z.MyDebuff = z.SpellName
    return CheckCastable(z)
end
AddonTable.Castable["Hamstring"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(1715)
    z.EnemyTargetNeeded = 1
    z.Debuff = z.SpellName
    return CheckCastable(z)
end
AddonTable.Castable["Pummel"] = function()
    if not Casting(nil, "target", 1) then return false end
    local z = {}
    z.SpellName = SpellName(6552)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Bloodthirst"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(23881)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Concussion Blow"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(12809)
    z.EnemyTargetNeeded = 1
    z.NotIfActive = 1
    return CheckCastable(z)
end

-- =====================================================
-- PROTEÇÃO / AMEÇA
-- =====================================================
AddonTable.Castable["Sunder Armor"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(7386)
    z.EnemyTargetNeeded = 1
    z.MyDebuff = z.SpellName
    return CheckCastable(z)
end
AddonTable.Castable["Shield Slam"] = function()
    if not MeleeOK() then return false end
    if not AddonTable.IsShieldEquipped() then return false end
    local z = {}
    z.SpellName = SpellName(23922)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Shield Bash"] = function()
    if not Casting(nil, "target", 1) then return false end
    if not AddonTable.IsShieldEquipped() then return false end
    local z = {}
    z.SpellName = SpellName(72)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Revenge"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(6572)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Shield Block"] = function()
    if not AddonTable.IsShieldEquipped() then return false end
    local z = {}
    z.SpellName = SpellName(2565)
    z.NotIfActive = 1
    return CheckCastable(z)
end
AddonTable.Castable["Thunder Clap"] = function()
    local z = {}
    z.SpellName = SpellName(6343)
    z.NoRangeCheck = 1
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Taunt"] = function()
    local z = {}
    z.SpellName = SpellName(355)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Throw"] = function()
    local z = {}
    z.SpellName = SpellName(5541)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Sweeping Strikes"] = function()
    local z = {}
    z.SpellName = SpellName(12328)
    z.NotIfActive = 1
    return CheckCastable(z)
end

-- =====================================================
-- UTILIDADE / AGREÇÃO
-- =====================================================
function AddonTable.IsShieldEquipped()
    local offhandLink = GetInventoryItemLink and GetInventoryItemLink("player", 17)
    if offhandLink then
        local _, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(offhandLink)
        if itemEquipLoc == "INVTYPE_SHIELD" then return true end
    end
    return false
end

-- Postura atual: 0 desconhecido, 1 Battle, 2 Defensive, 3 Berserker
function AddonTable.GetCurrentStance()
    if SpellFlashAddon.Form then
        if SpellFlashAddon.Form(SpellName(2457)) then return 1 end
        if SpellFlashAddon.Form(SpellName(71)) then return 2 end
        if SpellFlashAddon.Form(SpellName(2458)) then return 3 end
    end
    return 0
end

-- Copiar continua sendo útil não para este módulo, mas como exemplo de agnosticidade
-- =====================================================
-- ROTATION PREDICATES (editor visual / declaração de rotação)
-- Predicados oferecidos no menu de condição da GUI (/sf → Warrior).
-- =====================================================
AddonTable.RotationPredicates = AddonTable.RotationPredicates or {}
local P = AddonTable.RotationPredicates
P["always"]        = { label = L.pred_always, fn = function(env) return true end }
P["has_enemy"]     = { label = L.pred_has_enemy, fn = function(env) return env.hasActiveEnemy and true or false end }
P["in_combat"]     = { label = L.pred_in_combat, fn = function(env) return env.inCombat and true or false end }
P["not_in_combat"] = { label = L.pred_out_combat, fn = function(env) return not env.inCombat and true or false end }
P["is_pvp"]        = { label = "PvP", fn = function(env) return env.isPvP and true or false end }
P["pvp_and_enemy"] = { label = L.pred_pvp_attackable, fn = function(env) return env.isPvP and env.hasActiveEnemy and true or false end }
P["is_aoe"]        = { label = L.pred_aoe2, fn = function(env) return env.isAoE and true or false end }
P["aoe_and_enemy"] = { label = L.pred_aoe_and_enemy, fn = function(env) return env.isAoE and env.hasActiveEnemy and true or false end }
P["target_casting"] = { label = L.pred_target_casting, fn = function(env) return env.targetCasting and true or false end }
P["target_casting_not_berserker"] = { label = L.pred_cast_not_berserker,
    fn = function(env) return env.targetCasting and env.currentStance ~= 3 and true or false end }
P["target_casting_berserker"] = { label = L.pred_cast_berserker,
    fn = function(env) return env.targetCasting and env.currentStance == 3 and true or false end }
P["target_casting_defensive"] = { label = L.pred_cast_defensive,
    fn = function(env) return env.targetCasting and env.currentStance == 2 and true or false end }
P["target_casting_and_shield"] = { label = L.pred_cast_shield,
    fn = function(env) return env.targetCasting and env.hasShield and true or false end }
P["not_stance_berserker"] = { label = L.pred_not_berserker,
    fn = function(env) return env.currentStance ~= 3 and true or false end }
P["not_battle_stance_away"] = { label = L.pred_out_battle_stance,
    fn = function(env) return (not env.inCombat) and env.currentStance ~= 1 and true or false end }
P["target_hp20"]   = { label = L.pred_target_hp20, fn = function(env) return (env.targetHP or 100) < 20 end }
P["my_hp35"]       = { label = L.pred_my_hp35, fn = function(env) return (env.myHP or 100) < 35 end }
P["rage40"]        = { label = L.pred_rage40, fn = function(env) return (env.rage or 0) >= 40 end }
P["rage40_and_enemy"] = { label = L.pred_rage_enemy,
    fn = function(env) return (env.rage or 0) >= 40 and env.hasActiveEnemy and true or false end }
P["has_shield"]    = { label = L.pred_shield_attackable,
    fn = function(env) return env.hasShield and env.hasActiveEnemy and true or false end }
P["has_shield_only"] = { label = L.pred_shield, fn = function(env) return env.hasShield and true or false end }
P["opener_stance"] = { label = L.pred_out_attackable_battle,
    fn = function(env) return (not env.inCombat) and env.hasActiveEnemy and env.currentStance ~= 1 and true or false end }
P["opener_charge"] = { label = L.pred_out_attackable,
    fn = function(env) return (not env.inCombat) and env.hasActiveEnemy and true or false end }
P["not_in_combat_shout_missing"] = { label = L.pred_out_shout,
    fn = function(env)
        if env.inCombat then return false end
        return not (SpellFlashAddon.CheckBuff and SpellFlashAddon.CheckBuff(6673, "player")) and true or false
    end }

-- Postura certa (pós-Tactical Mastery baseline do Forever: trocar de postura é barato)
P["not_berserker_combat"] = { label = L.pred_combat_not_berserker,
    fn = function(env) return env.inCombat and env.currentStance ~= 3 and true or false end }
P["not_defensive_stance"] = { label = L.pred_not_defensive,
    fn = function(env) return env.currentStance ~= 2 and true or false end }

-- AoE com Rage suficiente para os commits caros (pooling)
P["aoe_rage40_and_enemy"] = { label = L.pred_aoe_rage40,
    fn = function(env) return env.isAoE and (env.rage or 0) >= 40 and env.hasActiveEnemy and true or false end }
P["aoe_rage45_and_enemy"] = { label = L.pred_aoe_rage45,
    fn = function(env) return env.isAoE and (env.rage or 0) >= 45 and env.hasActiveEnemy and true or false end }

-- =====================================================
-- Prefixo COMUM a todas as specs de Warrior (buffs / stances / interrupt)
-- Antes hardcoded no hub (Scripts.lua); agora nós declarados —
-- aparecem (e são editáveis) na rotação de Arms, Fury e Protection.
-- =====================================================
AddonTable.WarriorCommonNodes = {
    { id = "battle_shout",  spellID = 6673, name = "Battle Shout",    color = "Green",   condition = "not_in_combat_shout_missing" },
    { id = "berserker_stance", spellID = 2458, name = "Berserker Stance", color = "Green", condition = "target_casting_not_berserker" },
    { id = "pummel",        spellID = 6552, name = "Pummel",          color = "Aqua",    condition = "target_casting" },
}

function AddonTable.ConcatCommonNodes(common, nodes)
    local out = {}
    for _, n in ipairs(common or {}) do out[#out + 1] = n end
    for _, n in ipairs(nodes or {}) do out[#out + 1] = n end
    return out
end

if not AddonTable.CheckCollectable then AddonTable.CheckCollectable = false end
