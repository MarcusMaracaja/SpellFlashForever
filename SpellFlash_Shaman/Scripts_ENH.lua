-- SpellFlash_Shaman / Scripts_ENH.lua
-- Rotação ENHANCEMENT declarada como DADO (RotationSpecs + RotationPredicates).
-- Melhor-esforço; foco do projeto é Elemental. Baseada no guia Enhancement pós-tuning
-- 2026-11-03 (leprestore, atualizado 2026-11-04; patch 1.60.1):
--   Stormstrike (17364): 150% do dano normalizado de arma, CD 6s (antes 100% / 8s);
--     buffa o próximo Lightning Bolt/Chain Lightning/Earth Shock no alvo.
--   Maelstrom Weapon (5 pilhas, 5/5 talento) → Lightning Bolt instantâneo e grátis
--     (só Lightning Bolt — não Chain Lightning, não Healing Wave); proc dobrado no tuning.
--   Rage of the Farseer (425336, nv40): +30% velocidade de ataque por 25s (não é Haste).
--   Flurry: 6/12/18/24/30% de velocidade pós-crit. Mental Dexterity: 50/100/150% do
--     Intellect vira AP. Improved Ghost Wolf movido para a 4ª fileira (15 pontos Enh).
-- Shocks compartilham cooldown — Earth Shock gasto em dano = sem interrupt.
-- O editor de rotação do /sf (aba Shaman) edita esta declaração por personagem.

local AddonName, AddonTable = ...
local L = AddonTable.L
AddonTable.RotationModuleName = AddonName
AddonTable.RotationPredicates = AddonTable.RotationPredicates or {}
AddonTable.RotationSpecs = AddonTable.RotationSpecs or {}

local function SpellName(id) return AddonTable.SpellName(id) end

-- Pilha de Maelstrom Weapon no jogador (o buff é aura; pode vir secret em combate —
-- nesse caso a contagem cai para 0 e o addon não sugere o burst instantâneo).
local MAELSTROM_AURAS = { [408498] = true, [408505] = true }

local function GetMaelstromStacks()
    if not (C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function") then return 0 end
    for i = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
        if not ok or not aura then break end
        local okS, sp = pcall(function() return aura.spellId end)
        local spId
        if okS and type(sp) == "number" and not (_G.issecretvalue and issecretvalue(sp)) then spId = sp end
        if spId and MAELSTROM_AURAS[spId] then
            local okN, n = pcall(function() return aura.applications end)
            local nApps = okN and tonumber(n) or 1
            return nApps or 1
        end
    end
    return 0
end

local P = AddonTable.RotationPredicates
-- condições reutilizadas do ELE (mesmo arquivo não; mas podem já existir):
P["aoe_mana15"] = { label = L.pred_aoe_mana15,
    fn = function(env) return env.isAoE and (env.manaPct or 0) > 15 end }
P["maelstrom5"]  = { label = L.pred_maelstrom5,
    fn = function(env) return GetMaelstromStacks() >= 5 end }
P["not_melee"]   = { label = L.pred_ranged_melee_out,
    fn = function(env) return not env.isMelee and true or false end }

AddonTable.RotationSpecs.ENH = {
    title = "Enhancement",
    nodes = AddonTable.ConcatCommonNodes(AddonTable.ShamanCommonNodes, {
        { id = "stormstrike",    spellID = 17364, name = "Stormstrike",   color = "Yellow", condition = "melee_combat" },
        { id = "lightning_bolt_burst", spellID = 403,   name = "Lightning Bolt", color = "Yellow", condition = "maelstrom5" },
        { id = "rage_of_the_farseer", spellID = 425336, name = "Rage of the Farseer", color = "Yellow", condition = "melee_combat" },
        { id = "flame_shock",    spellID = 8050,  name = "Flame Shock",   color = "Pink",   condition = "flame_shock_missing" },
        { id = "chain_lightning", spellID = 421,  name = "Chain Lightning", color = "Purple", condition = "cl_ok" },
        { id = "mana_spring",    spellID = 5675,  name = "Mana Spring Totem", color = "Green", condition = "mana_spring_missing" },
        { id = "lightning_bolt", spellID = 403,   name = "Lightning Bolt", color = "White",  condition = "not_melee" },
    }),
}

function AddonTable.RunENHRotation(env)
    local SF = _G["SpellFlashForever"]
    if SF and type(SF.RunDeclaredRotation) == "function" then
        return SF.RunDeclaredRotation(AddonTable, "ENH", env)
    end
    return false
end
