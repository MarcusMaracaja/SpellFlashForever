-- SpellFlash_Druid / Functions.lua
-- Castable table do Druid do Forever (Interface 16001). Arquitetura igual à dos
-- outros módulos: AddonTable.Castable["Name"](Fn) → spell se puder ser sugerida.
-- IDs verificados via wowhead/forever/forever-tavern confirmados (10 de 12 sinalizados);
-- IDs vanilla mantidos quando a origem confirma (Cat Form, Rip, Shred, Claw, Maul,
-- FB 22568, etc.). O Flashable() silencia qualquer ID errado — nunca quebra nada.

local AddonName, AddonTable = ...
local L = AddonTable.Localize
local SFBF = _G["SpellFlashForever"]

AddonTable.Castable = AddonTable.Castable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.Castable)) or {}
AddonTable.VehicleCastable = AddonTable.VehicleCastable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.VehicleCastable)) or {}
AddonTable.ItemCastable = AddonTable.ItemCastable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.ItemCastable)) or {}

print('|cFF00FF00[SF Druid]|r Functions carregado!')

local function SpellName(id) return AddonTable.SpellName(id) end
local Buff = SpellFlashAddon.CheckBuff
local CheckCastable = SpellFlashAddon.CheckIfSpellCastable

-- Distância melee relevante: nil/true = pode usar; false = fora de alcance
local function MeleeOK()
    if not AddonTable.IsInMeleeRange then return true end
    local r = AddonTable.IsInMeleeRange("target")
    return r == nil or r == true
end

-- =====================================================
-- FORMAS (Shapeshifts)
-- =====================================================
AddonTable.Castable["Cat Form"] = function()
    local z = {}
    z.SpellName = SpellName(768)
    if SpellFlashAddon.Form and SpellFlashAddon.Form(SpellName(768)) then return false end
    return CheckCastable(z)
end
AddonTable.Castable["Bear Form"] = function()
    local z = {}
    z.SpellName = SpellName(5487)
    if SpellFlashAddon.Form and SpellFlashAddon.Form(SpellName(5487)) then return false end
    return CheckCastable(z)
end
AddonTable.Castable["Dire Bear Form"] = function()
    local z = {}
    z.SpellName = SpellName(9634)
    if SpellFlashAddon.Form and SpellFlashAddon.Form(SpellName(9634)) then return false end
    return CheckCastable(z)
end
AddonTable.Castable["Moonkin Form"] = function()
    local z = {}
    z.SpellName = SpellName(24858)
    if SpellFlashAddon.Form and SpellFlashAddon.Form(SpellName(24858)) then return false end
    return CheckCastable(z)
end
AddonTable.Castable["Travel Form"] = function()
    local z = {}
    z.SpellName = SpellName(783)
    if SpellFlashAddon.Form and SpellFlashAddon.Form(SpellName(783)) then return false end
    return CheckCastable(z)
end
AddonTable.Castable["Aquatic Form"] = function()
    local z = {}
    z.SpellName = SpellName(1066)
    if SpellFlashAddon.Form and SpellFlashAddon.Form(SpellName(1066)) then return false end
    return CheckCastable(z)
end

-- =====================================================
-- FERAL (Cat / Bear PvE)
-- =====================================================
AddonTable.Castable["Claw"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(1082)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Maul"] = function() -- bear: custo 15 rage, next attack
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(6807)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Growl"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(6795)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Shred"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(5221)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Rake"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(1822)
    z.EnemyTargetNeeded = 1
    z.MyDebuff = z.SpellName
    return CheckCastable(z)
end
AddonTable.Castable["Rip"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(1079)
    z.EnemyTargetNeeded = 1
    z.MyDebuff = z.SpellName
    return CheckCastable(z)
end
AddonTable.Castable["Ferocious Bite"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(22568)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Bash"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(5211)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Enrage"] = function()
    local z = {}
    z.SpellName = SpellName(5229)
    z.Buff = z.SpellName
    return CheckCastable(z)
end
AddonTable.Castable["Frenzied Regeneration"] = function()
    if SpellFlashAddon.HealthPercent and SpellFlashAddon.HealthPercent("player") >= 80 then return false end
    local z = {}
    z.SpellName = SpellName(22842)
    return CheckCastable(z)
end
AddonTable.Castable["Swipe (Bear)"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(779)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Pounce"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(9005)
    z.EnemyTargetNeeded = 1
    z.Debuff = z.SpellName
    return CheckCastable(z)
end
AddonTable.Castable["Primal Bite"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(54805)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Shifting Power"] = function()
    local z = {}
    z.SpellName = SpellName(54804)
    return CheckCastable(z)
end
AddonTable.Castable["Lacerate"] = function()
    if not MeleeOK() then return false end
    local z = {}
    z.SpellName = SpellName(54802)
    z.EnemyTargetNeeded = 1
    z.MyDebuff = z.SpellName
    return CheckCastable(z)
end

-- =====================================================
-- BALANCE (caster)
-- =====================================================
AddonTable.Castable["Wrath"] = function()
    local z = {}
    z.SpellName = SpellName(5177)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Starfire"] = function()
    local z = {}
    z.SpellName = SpellName(8950)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Moonfire"] = function()
    local z = {}
    z.SpellName = SpellName(9835)
    z.EnemyTargetNeeded = 1
    z.MyDebuff = z.SpellName
    return CheckCastable(z)
end
AddonTable.Castable["Insect Swarm"] = function()
    local z = {}
    z.SpellName = SpellName(912)
    z.EnemyTargetNeeded = 1
    z.MyDebuff = z.SpellName
    return CheckCastable(z)
end
AddonTable.Castable["Hurricane"] = function()
    local z = {}
    z.SpellName = SpellName(16914)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Hibernate"] = function()
    local z = {}
    z.SpellName = SpellName(2637)
    z.EnemyTargetNeeded = 1
    return CheckCastable(z)
end
AddonTable.Castable["Entangling Roots"] = function()
    local z = {}
    z.SpellName = SpellName(339)
    z.EnemyTargetNeeded = 1
    z.MyDebuff = z.SpellName
    return CheckCastable(z)
end

-- =====================================================
-- UTILIDADE / MANTIMENTOS
-- =====================================================
AddonTable.Castable["Thorns"] = function()
    local z = {}
    z.SpellName = SpellName(467)
    z.Buff = z.SpellName
    z.Unit = "player"
    return CheckCastable(z)
end
AddonTable.Castable["Barkskin"] = function()
    local z = {}
    z.SpellName = SpellName(22812)
    z.Buff = z.SpellName
    return CheckCastable(z)
end
AddonTable.Castable["Innervate"] = function()
    local z = {}
    z.SpellName = SpellName(29166)
    return CheckCastable(z)
end
AddonTable.Castable["Prowl"] = function()
    local z = {}
    z.SpellName = SpellName(5215)
    z.NotIfActive = 1
    return CheckCastable(z)
end
AddonTable.Castable["Dash"] = function()
    local z = {}
    z.SpellName = SpellName(1850)
    return CheckCastable(z)
end
AddonTable.Castable["Swiftmend"] = function()
    local z = {}
    z.SpellName = SpellName(18562)
    return CheckCastable(z)
end

-- =====================================================
-- ROTATION PREDICATES (editor visual / declaração de rotação)
-- Predicados oferecidos no menu de condição da GUI (/sf → Druid).
-- =====================================================
AddonTable.RotationPredicates = AddonTable.RotationPredicates or {}
local P = AddonTable.RotationPredicates
P["always"]          = { label = "sempre", fn = function(env) return true end }
P["has_enemy"]       = { label = "alvo atacável", fn = function(env) return env.hasActiveEnemy and true or false end }
P["not_cat_form"]    = { label = "você NÃO está em forma de animal (Cat Form)", fn = function(env) return env.form == 0 and true or false end }
P["bear_form"]       = { label = "você está em Bear Form", fn = function(env) return env.form == 2 and true or false end }
P["not_moonkin"]     = { label = "você NÃO está em Moonkin Form", fn = function(env) return env.form ~= 3 and true or false end }
P["target_casting"]  = { label = "alvo conjurando", fn = function(env) return env.targetCasting and true or false end }
P["pounce_condition"] = { label = "Cat Form, 40+ de energia, PvE",
    fn = function(env) return env.form == 1 and (env.energy or 0) >= 40 and not env.isPvP and true or false end }
P["combo5"]          = { label = "5 pontos de combo", fn = function(env) return (env.combo or 0) >= 5 end }
P["energy40"]        = { label = "40+ de energia", fn = function(env) return (env.energy or 0) >= 40 end }
P["my_hp35"]         = { label = "você abaixo de 35%", fn = function(env) return (env.myHP or 100) < 35 end }
P["insect_swarm_missing"] = { label = "Insect Swarm ausente no alvo",
    fn = function(env) return not SpellFlashAddon.CheckDebuff(SpellName(912), "target") and true or false end }
P["moonfire_missing"] = { label = "Moonfire ausente no alvo",
    fn = function(env) return not SpellFlashAddon.CheckDebuff(SpellName(9835), "target") and true or false end }
