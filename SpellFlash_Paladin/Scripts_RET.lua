-- SpellFlash_Paladin / Scripts_RET.lua
-- Rotação RETRIBUTION (DPS, duas mãos) declarada como DADO (RotationSpecs + RotationPredicates).
-- O editor /sf → Paladin edita esta declaração por personagem.
-- Prioridade (Forever p1.60.1, pós-rework SimC): manter Selo (Seal of Command) > Holy
-- Strike (10s CD; renova Judgement via Sacred Arbiter) > Judgement > Hammer of Wrath
-- (<20%) > Exorcism (morto-vivo/demônio) > Consecration (AoE).
-- NÃO sugerimos trocas de Selo automáticas (Unsealed Wrath = decisão do jogador).
-- Fontes: leprestore (Retribution guide, atualizado 2026-11-04) / wowhead Forever.
-- Holy Strike (680) e Unsealed Wrath (1310735) → novos no Forever; VERIFICAR EM JOGO.

local AddonName, AddonTable = ...
AddonTable.RotationModuleName = AddonName
AddonTable.RotationPredicates = AddonTable.RotationPredicates or {}
AddonTable.RotationSpecs = AddonTable.RotationSpecs or {}

AddonTable.RotationSpecs.RET = {
    title = "Retribution",
    nodes = AddonTable.ConcatCommonNodes(AddonTable.PaladinCommonNodes, {
        { id = "seal_of_command", spellID = 20915, name = "Seal of Command", color = "Green", condition = "seal_of_command_missing", passthrough = true },
        { id = "holy_strike",     spellID = 680,   name = "Holy Strike",    color = "Yellow", condition = "has_enemy" },
        { id = "judgement",       spellID = 20271, name = "Judgement",      color = "Yellow", condition = "has_enemy" },
        { id = "hammer_of_wrath", spellID = 24275, name = "Hammer of Wrath", color = "Orange", condition = "target_hp20" },
        { id = "exorcism",        spellID = 10308, name = "Exorcism",       color = "Yellow", condition = "undead_or_demon" },
        { id = "consecration",    spellID = 20116, name = "Consecration",   color = "Purple", condition = "aoe_and_enemy" },
    }),
}

function AddonTable.RunRETRotation(env)
    if env.isPvP and env.isCCd then return false end
    local SF = _G["SpellFlashForever"]
    if SF and type(SF.RunDeclaredRotation) == "function" then
        return SF.RunDeclaredRotation(AddonTable, "RET", env)
    end
    return false
end
