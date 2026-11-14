-- SpellFlash_Paladin / Scripts_PROT.lua
-- Rotação PROTECTION (tank) declarada como DADO (RotationSpecs + RotationPredicates).
-- O editor /sf → Paladin edita esta declaração por personagem.
-- Prioridade (Forever p1.60.1): Righteous Fury > Holy Shield > Consecration > Holy Strike
-- > Judgement (taunt w/ Seal of Fury) > Exorcism (só morto-vivo/demônio) >
-- Hammer of Wrath (<20% alvo).
-- Fontes: wowtbc.gg ( Protection rotation ) / mobalytics (Protection guide, rotação ST/AoE).
-- IDs Forever NOVOS (Holy Strike, Holy Shield, Templar's Bulwark) → marcados como
-- VERIFICAR EM JOGO nos comentários; o client verificado pelo Spy (2026-11-14):
--   Judgement 20271 (nv4), Righteous Fury 25780 (nv16).

local AddonName, AddonTable = ...
AddonTable.RotationModuleName = AddonName
AddonTable.RotationPredicates = AddonTable.RotationPredicates or {}
AddonTable.RotationSpecs = AddonTable.RotationSpecs or {}

AddonTable.RotationSpecs.PROT = {
    title = "Protection",
    nodes = AddonTable.ConcatCommonNodes(AddonTable.PaladinCommonNodes, {
        { id = "righteous_fury", spellID = 25780, name = "Righteous Fury", color = "Green", condition = "not_righteous_fury_up", passthrough = true },
        { id = "holy_shield",    spellID = 28153, name = "Holy Shield",    color = "Green", condition = "holy_shield_missing", passthrough = true },
        { id = "consecration",   spellID = 20116, name = "Consecration",   color = "Purple", condition = "has_enemy" },
        { id = "holy_strike",    spellID = 680,   name = "Holy Strike",    color = "Yellow", condition = "has_enemy" },
        { id = "judgement",      spellID = 20271, name = "Judgement",      color = "Yellow", condition = "has_enemy" },
        { id = "exorcism",       spellID = 10308, name = "Exorcism",       color = "Yellow", condition = "undead_or_demon" },
        { id = "hammer_of_wrath", spellID = 24275, name = "Hammer of Wrath", color = "Orange", condition = "target_hp20" },
    }),
}

function AddonTable.RunPROTRotation(env)
    if env.isPvP and env.isCCd then return false end
    local SF = _G["SpellFlashForever"]
    if SF and type(SF.RunDeclaredRotation) == "function" then
        return SF.RunDeclaredRotation(AddonTable, "PROT", env)
    end
    return false
end
