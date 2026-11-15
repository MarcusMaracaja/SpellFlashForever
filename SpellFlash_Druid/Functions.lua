-- SpellFlash_Druid / Functions.lua
-- Castable table do Druid do Forever (Interface 16001). Arquitetura igual à dos
-- outros módulos: AddonTable.Castable["Name"](Fn) → spell se puder ser sugerida.
-- IDs verificados via wowhead/forever/forever-tavern confirmados (10 de 12 sinalizados);
-- IDs vanilla mantidos quando a origem confirma (Cat Form, Rip, Shred, Claw, Maul,
-- FB 22568, etc.). O Flashable() silencia qualquer ID errado — nunca quebra nada.

local AddonName, AddonTable = ...
local L = AddonTable.L
local SFBF = _G["SpellFlashForever"]

AddonTable.Castable = AddonTable.Castable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.Castable)) or {}
AddonTable.VehicleCastable = AddonTable.VehicleCastable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.VehicleCastable)) or {}
AddonTable.ItemCastable = AddonTable.ItemCastable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.ItemCastable)) or {}

print(string.format(L.mod_loaded, "Druid", L.mod_load_functions))

local function SpellName(id) return AddonTable.SpellName(id) end
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
AddonTable.Castable["Mark of the Wild"] = function()
    local z = {}
    z.SpellName = SpellName(1126)
    z.Buff = z.SpellName
    z.BuffUnit = "player"
    return CheckCastable(z)
end
AddonTable.Castable["Nature's Grasp"] = function()
    local z = {}
    z.SpellID = 16689
    z.SpellName = SpellName(16689)
    z.Buff = z.SpellName
    z.BuffUnit = "player"
    return CheckCastable(z)
end
AddonTable.Castable["Thorns"] = function()
    local z = {}
    z.SpellID = 467
    z.SpellName = SpellName(467)
    z.Buff = z.SpellName
    z.BuffUnit = "player"
    return CheckCastable(z)
end
AddonTable.Castable["Barkskin"] = function()
    local z = {}
    z.SpellName = SpellName(22812)
    z.Buff = z.SpellName
    return CheckCastable(z)
end
AddonTable.Castable["Demoralizing Roar"] = function()
    local z = {}
    z.SpellID = 99                      -- rank 1; o core resolve o maior rank conhecido pela família {99,1735,9490,9747,9898}
    z.SpellName = SpellName(99)
    z.Debuff = z.SpellName              -- não sugere se o alvo já tiver o debuff (qualquer fonte)
    z.EnemyTargetNeeded = 1
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
P["always"]          = { label = L.pred_always, fn = function(env) return true end }
P["has_enemy"]       = { label = L.pred_has_enemy, fn = function(env) return env.hasActiveEnemy and true or false end }
P["not_cat_form"]    = { label = L.pred_not_cat_form, fn = function(env) return env.form == 0 and true or false end }
P["bear_form"]       = { label = L.pred_bear_form, fn = function(env) return env.form == 2 and true or false end }
P["mark_missing"]    = { label = L.pred_mark_missing,
    fn = function(env)
        if env.form == 1 or env.form == 2 then return false end -- não pode em Cat/Bear
        if env.mounted then return false end                     -- não sugere montado
        if env.targetExists then
            -- alvo selecionado: sugere só se for aliado vivo e estiver SEM o buff
            return (env.targetFriendlyAlive and not (AddonTable.IsTargetMarkUp and AddonTable.IsTargetMarkUp())) and true or false
        end
        -- sem alvo selecionado: self-buff, só se o jogador estiver SEM o buff
        return (AddonTable.IsSelfMarkUp and AddonTable.IsSelfMarkUp() or false) == false
    end }
P["thorns_missing"]  = { label = L.pred_thorns_missing,
    fn = function(env)
        if env.form == 1 or env.form == 2 then return false end -- não pode em Cat/Bear
        if env.mounted then return false end                     -- não sugere montado
        if env.targetExists then
            return (env.targetFriendlyAlive and not (AddonTable.IsTargetThornsUp and AddonTable.IsTargetThornsUp())) and true or false
        end
        return (AddonTable.IsSelfThornsUp and AddonTable.IsSelfThornsUp() or false) == false
    end }
P["enred_missing"]  = { label = L.pred_natures_grasp_missing,
    fn = function(env)
        if env.mounted then return false end                     -- não sugere montado
        return (AddonTable.IsSelfEnredUp and AddonTable.IsSelfEnredUp() or false) == false
    end }
P["demoralizing_roar_missing"] = { label = L.pred_roar_missing,
    fn = function(env)
        if env.form ~= 2 then return false end                   -- Rugido só em Bear
        if not env.hasActiveEnemy then return false end          -- precisa de inimigo
        if AddonTable.IsRoarUp and AddonTable.IsRoarUp() then return false end
        return true
    end }

-- Prefixo COMUM a todas as specs de Druid: self-buffs do Druid.
AddonTable.DruidCommonNodes = {
    { id = "mark_of_the_wild", spellID = 1126, name = "Mark of the Wild", color = "White", condition = "mark_missing", passthrough = true },
    { id = "thorns",           spellID = 467,  name = "Thorns",          color = "White", condition = "thorns_missing", passthrough = true },
    { id = "natures_grasp",    spellID = 16689, name = "Nature's Grasp", color = "White", condition = "enred_missing", passthrough = true },
    { id = "demoralizing_roar", spellID = 99,  name = "Demoralizing Roar", color = "Green", condition = "demoralizing_roar_missing", passthrough = true }, -- só Bear; passthrough: brilha junto com a rotação
}

function AddonTable.ConcatCommonNodes(common, nodes)
    local out = {}
    for _, n in ipairs(common or {}) do out[#out + 1] = n end
    for _, n in ipairs(nodes or {}) do out[#out + 1] = n end
    return out
end
P["not_moonkin"]     = { label = L.pred_not_moonkin, fn = function(env) return env.form ~= 3 and true or false end }
P["target_casting"]  = { label = L.pred_target_casting, fn = function(env) return env.targetCasting and true or false end }
P["pounce_condition"] = { label = L.pred_cat_form_combo,
    fn = function(env) return env.form == 1 and (env.energy or 0) >= 40 and not env.isPvP and true or false end }
P["combo5"]          = { label = L.pred_combo5, fn = function(env) return (env.combo or 0) >= 5 end }
P["energy40"]        = { label = L.pred_energy40, fn = function(env) return (env.energy or 0) >= 40 end }
P["my_hp35"]         = { label = L.pred_my_hp35, fn = function(env) return (env.myHP or 100) < 35 end }
P["insect_swarm_missing"] = { label = L.pred_insect_swarm_missing,
    fn = function(env) return not SpellFlashAddon.CheckDebuff(SpellName(912), "target") and true or false end }
P["moonfire_missing"] = { label = L.pred_moonfire_missing,
    fn = function(env) return not SpellFlashAddon.CheckDebuff(SpellName(9835), "target") and true or false end }
