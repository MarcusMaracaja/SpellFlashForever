-- SpellFlash_Warrior / Scripts_Arms.lua
-- Rotação Arms declarada como DADO (RotationSpecs + RotationPredicates).
-- O editor /sf → Warrior edita esta declaração por personagem.
-- Prioridade: Execute <20% > Mortal Strike > Overpower > Slam > Rend > Whirlwind/Sweep AoE > Hamstring PvP > Heroic Strike > Attack.
-- (Pummel/Break-stance ficam no hub Scripts.lua, acima da spec.)
local AddonName, AddonTable = ...
AddonTable.RotationModuleName = AddonName
AddonTable.RotationSpecs = AddonTable.RotationSpecs or {}

AddonTable.RotationSpecs.ARMS = {
    title = "Arms",
    nodes = AddonTable.ConcatCommonNodes(AddonTable.WarriorCommonNodes, {
        { id = "opener_battle_stance", spellID = 2457, name = "Battle Stance",  color = "Green",  condition = "opener_stance" },
        { id = "opener_charge",        spellID = 100,  name = "Charge",         color = "Yellow", condition = "opener_charge" },
        { id = "execute",              spellID = 5308, name = "Execute",        color = "Orange", condition = "target_hp20" },
        { id = "mortal_strike",        spellID = 12294, name = "Mortal Strike", color = "Yellow", condition = "has_enemy" },
        { id = "overpower",            spellID = 7384, name = "Overpower",      color = "Yellow", condition = "has_enemy" },
        { id = "slam",                 spellID = 1464, name = "Slam",           color = "Yellow", condition = "has_enemy" },
        { id = "rend",                 spellID = 772,  name = "Rend",           color = "Pink",   condition = "has_enemy", passthrough = true },
        { id = "whirlwind",            spellID = 1680, name = "Whirlwind",      color = "Purple", condition = "aoe_and_enemy" },
        { id = "sweeping_strikes",     spellID = 12328, name = "Sweeping Strikes", color = "Yellow", condition = "aoe_and_enemy" },
        { id = "hamstring",            spellID = 1715, name = "Hamstring",      color = "Pink",   condition = "pvp_and_enemy", passthrough = true },
        { id = "heroic_strike",        spellID = 78,   name = "Heroic Strike",  color = "White",  condition = "rage40_and_enemy" },
        { id = "attack",               spellID = 6603, name = "Attack",         color = "White",  condition = "has_enemy" },
    }),
}

function AddonTable.RunArmsRotation(env)
    if env.isPvP and env.isCCd then return false end
    local SF = _G["SpellFlashForever"]
    if SF and type(SF.RunDeclaredRotation) == "function" then
        return SF.RunDeclaredRotation(AddonTable, "ARMS", env)
    end
    return false
end
