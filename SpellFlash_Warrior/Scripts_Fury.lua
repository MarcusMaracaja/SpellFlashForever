-- SpellFlash_Warrior / Scripts_Fury.lua
-- Rotação Fury declarada como DADO (RotationSpecs + RotationPredicates).
-- O editor /sf → Warrior edita esta declaração por personagem.
-- Prioridade: Bloodrage > Death Wish > Whirlwind AoE > Execute <20% > Bloodthirst > Recklessness > Sweeping Strikes > Hamstring PvP > Heroic Strike > Attack.
-- (Pummel/Break-stance ficam no hub Scripts.lua, acima da spec.)
local AddonName, AddonTable = ...
AddonTable.RotationModuleName = AddonName
AddonTable.RotationSpecs = AddonTable.RotationSpecs or {}

AddonTable.RotationSpecs.FURY = {
    title = "Fury",
    nodes = AddonTable.ConcatCommonNodes(AddonTable.WarriorCommonNodes, {
        { id = "bloodrage",       spellID = 2687,  name = "Bloodrage",      color = "Green",  condition = "in_combat", passthrough = true },
        { id = "death_wish",      spellID = 12292, name = "Death Wish",     color = "Orange", condition = "has_enemy", passthrough = true },
        { id = "whirlwind",       spellID = 1680,  name = "Whirlwind",      color = "Purple", condition = "aoe_and_enemy" },
        { id = "execute",         spellID = 5308,  name = "Execute",        color = "Orange", condition = "target_hp20" },
        { id = "bloodthirst",     spellID = 23881, name = "Bloodthirst",    color = "Yellow", condition = "has_enemy" },
        { id = "recklessness",    spellID = 1719,  name = "Recklessness",   color = "Yellow", condition = "has_enemy", passthrough = true },
        { id = "sweeping_strikes", spellID = 12328, name = "Sweeping Strikes", color = "Yellow", condition = "aoe_and_enemy", passthrough = true },
        { id = "hamstring",       spellID = 1715,  name = "Hamstring",      color = "Pink",   condition = "pvp_and_enemy", passthrough = true },
        { id = "heroic_strike",   spellID = 78,    name = "Heroic Strike",  color = "White",  condition = "rage40_and_enemy" },
        { id = "attack",          spellID = 6603,  name = "Attack",         color = "White",  condition = "has_enemy" },
    }),
}

function AddonTable.RunFuryRotation(env)
    if env.isPvP and env.isCCd then return false end
    local SF = _G["SpellFlashForever"]
    if SF and type(SF.RunDeclaredRotation) == "function" then
        return SF.RunDeclaredRotation(AddonTable, "FURY", env)
    end
    return false
end
