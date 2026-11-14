-- SpellFlash_Hunter / Scripts_MM.lua
-- Marksmanship declarada como DADO (RotationSpecs + RotationPredicates).
-- O editor /sf → Hunter edita esta declaração por personagem.
-- Ordem: prefixo COMUM de melee/dead-zone (AddonTable.HunterMeleeNodes) +
-- cadeia do guia MM Forever:
--   Scatter Shot → Rapid Fire/Sniper Shot → Aimed (ST) → Multi-Shot/Volley (AoE) →
--   Stings (Viper/Scorpid PvP / Serpent) → Arcane Shot.
local AddonName, AddonTable = ...
AddonTable.RotationModuleName = AddonName
AddonTable.RotationSpecs = AddonTable.RotationSpecs or {}

AddonTable.RotationSpecs.MM = {
    title = "Marksmanship",
    nodes = AddonTable.ConcatCommonNodes(AddonTable.HunterMeleeNodes, {
        { id = "scatter_shot",   spellID = 19503,   name = "Scatter Shot",   color = "Red",    condition = "enemy_interruptible_not_cc_not_too_close" },
        { id = "rapid_fire",     spellID = 3045,    name = "Rapid Fire",     color = "Yellow", condition = "enemy_in_combat_not_too_close", passthrough = true },
        { id = "sniper_shot",    spellID = 1310786, name = "Sniper Shot",    color = "Yellow", condition = "enemy_in_combat_not_too_close", passthrough = true },
        { id = "aimed_shot",     spellID = 19434,   name = "Aimed Shot",     color = "Yellow", condition = "not_aoe_not_too_close" },
        { id = "multi_shot",     spellID = 2643,    name = "Multi-Shot",     color = "Purple", condition = "is_aoe" },
        { id = "volley",         spellID = 1510,    name = "Volley",         color = "Purple", condition = "aoe_not_pvp_mana15" },
        { id = "viper_sting",    spellID = 3034,    name = "Viper Sting",    color = "Green",  condition = "viper_pvp_mana" },
        { id = "scorpid_sting",  spellID = 3043,    name = "Scorpid Sting",  color = "Green",  condition = "scorpid_pvp_melee" },
        { id = "serpent_sting",  spellID = 1978,    name = "Serpent Sting",  color = "Yellow", condition = "no_serpent_mm" },
        { id = "arcane_shot",    spellID = 3044,    name = "Arcane Shot",    color = "Yellow", condition = "not_too_close_ranged" },
    }),
}

function AddonTable.RunMMRotation(env)
    local SF = _G["SpellFlashForever"]
    if SF and type(SF.RunDeclaredRotation) == "function" then
        return SF.RunDeclaredRotation(AddonTable, "MM", env)
    end
    return false
end
