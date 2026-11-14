-- SpellFlash_Warrior / Scripts_Protection.lua
-- Rotação Protection declarada como DADO (RotationSpecs + RotationPredicates).
-- O editor /sf → Warrior edita esta declaração por personagem.
-- Prioridade: Shield Slam > Revenge > Sunder Armor > Shield Bash (cast) > Thunder Clap AoE > Shield Block > Challenging Shout (AoE) > Shield Wall/Last Stand <35% > Retaliation > Attack.
-- (Pummel em Defensive Stance fica no hub Scripts.lua, acima da spec; o hub
-- dispara Pummel fora de Defensive também — comportamento herdado, inalterado.)
local AddonName, AddonTable = ...
AddonTable.RotationModuleName = AddonName
AddonTable.RotationSpecs = AddonTable.RotationSpecs or {}

AddonTable.RotationSpecs.PROT = {
    title = "Protection",
    nodes = AddonTable.ConcatCommonNodes(AddonTable.WarriorCommonNodes, {
        { id = "shield_slam",     spellID = 23922, name = "Shield Slam",    color = "Yellow", condition = "has_shield" },
        { id = "revenge",         spellID = 6572,  name = "Revenge",        color = "Yellow", condition = "has_enemy" },
        { id = "sunder_armor",    spellID = 7386,  name = "Sunder Armor",   color = "Pink",   condition = "has_enemy" },
        { id = "shield_bash",     spellID = 72,    name = "Shield Bash",    color = "Aqua",   condition = "target_casting_and_shield" },
        { id = "thunder_clap",    spellID = 6343,  name = "Thunder Clap",   color = "Purple", condition = "aoe_and_enemy" },
        { id = "shield_block",    spellID = 2565,  name = "Shield Block",   color = "Green",  condition = "has_shield_only", passthrough = true },
        { id = "challenging_shout", spellID = 1161, name = "Challenging Shout", color = "Red", condition = "aoe_and_enemy" },
        { id = "shield_wall",     spellID = 871,   name = "Shield Wall",    color = "Red",    condition = "my_hp35" },
        { id = "last_stand",      spellID = 12975, name = "Last Stand",     color = "Red",    condition = "my_hp35" },
        { id = "retaliation",     spellID = 20230, name = "Retaliation",    color = "Orange", condition = "has_enemy", passthrough = true },
        { id = "attack",          spellID = 6603,  name = "Attack",         color = "White",  condition = "has_enemy" },
    }),
}

function AddonTable.RunProtectionRotation(env)
    if env.isPvP and env.isCCd then return false end
    local SF = _G["SpellFlashForever"]
    if SF and type(SF.RunDeclaredRotation) == "function" then
        return SF.RunDeclaredRotation(AddonTable, "PROT", env)
    end
    return false
end
