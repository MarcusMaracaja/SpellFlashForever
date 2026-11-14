-- SpellFlash_Hunter / Scripts_SV.lua
-- Sobrevivência declarada como DADO (RotationSpecs + RotationPredicates).
-- O editor /sf → Hunter edita esta declaração por personagem.
-- Ordem: prefixo COMUM de melee/dead-zone (AddonTable.HunterMeleeNodes) +
-- cadeia ranged do guia SV Forever:
--   Deterrence → Scatter Shot → Rapid Fire → Viper/Scorpid (PvP) →
--   Multi-Shot/Aimed → Serpent → Arcane → Volley.
local AddonName, AddonTable = ...
AddonTable.RotationModuleName = AddonName
AddonTable.RotationSpecs = AddonTable.RotationSpecs or {}

AddonTable.RotationSpecs.SV = {
    title = "Survival",
    nodes = AddonTable.ConcatCommonNodes(AddonTable.HunterMeleeNodes, {
        { id = "deterrence",    spellID = 19263, name = "Deterrence",    color = "Red",    condition = "pvp_hp30" },
        { id = "scatter_shot",  spellID = 19503, name = "Scatter Shot",  color = "Aqua",   condition = "enemy_interruptible_not_cc_not_too_close" },
        { id = "rapid_fire",    spellID = 3045,  name = "Rapid Fire",    color = "Yellow", condition = "enemy_in_combat_not_too_close", passthrough = true },
        { id = "viper_sting",   spellID = 3034,  name = "Viper Sting",   color = "Green",  condition = "viper_pvp_mana" },
        { id = "scorpid_sting", spellID = 3043,  name = "Scorpid Sting", color = "Green",  condition = "scorpid_pvp_melee" },
        { id = "multi_shot",    spellID = 2643,  name = "Multi-Shot",    color = "Yellow", condition = "aoe_not_too_close" },
        { id = "aimed_shot",    spellID = 19434, name = "Aimed Shot",    color = "Yellow", condition = "not_aoe_not_too_close" },
        { id = "serpent_sting", spellID = 1978,  name = "Serpent Sting", color = "Yellow", condition = "no_serpent_pve" },
        { id = "arcane_shot",   spellID = 3044,  name = "Arcane Shot",   color = "Yellow", condition = "not_too_close_ranged" },
        { id = "volley",        spellID = 1510,  name = "Volley",        color = "Purple", condition = "aoe_not_pvp_mana15" },
    }),
}

function AddonTable.RunSVRotation(env)
    local SF = _G["SpellFlashForever"]
    if SF and type(SF.RunDeclaredRotation) == "function" then
        return SF.RunDeclaredRotation(AddonTable, "SV", env)
    end
    return false
end
