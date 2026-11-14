-- SpellFlash_Shaman / Scripts_ELE.lua
-- Rotação ELEMENTAL declarada como DADO (RotationSpecs + RotationPredicates).
-- O editor de rotação do /sf (aba Shaman) edita esta declaração por personagem.
-- Padrão = guia Elemental do Forever pós-tuning 2026-11-03 (wowhead/leprestore/
-- wowtbc, patch 1.60.1); IDs/ranks da tabela Forever do usuário (Nv 1-60, 2026-11-13, H-0121)
-- cross-checada com Spy\List.lua em 2026-11-14 (H-0133).
--
-- NÃO existem no Forever / foram removidos do módulo:
--   Thunderstorm, Water Shield, Riptide, Call of Thunder (passivo; nada a sugerir),
--   Elemental Devastation (passivo). **Lava Burst REMOVIDO do jogo no tuning
--   2026-11-03** — nó "lava_burst" removido em H-0133.
-- **Lightning Mastery** (16166; antes "Elemental Mastery"): 15s de -0.5s no cast de
--   Lightning Bolt + Chain Lightning sem CD; recarga 3min.
-- Fire Nova existe e está no AoE (H-0121; gate: totem de fogo ativo — nó "fire_nova").
-- Chain Lightning: 2.5s cast, mana ~225% do LB → gate "cl_ok" (AoE ou mana >= 50% ou
--   Clearcasting 16246). Ver PESQUISA_ROTACAO_FOREVER.md.

local AddonName, AddonTable = ...
AddonTable.RotationModuleName = AddonName
AddonTable.RotationPredicates = AddonTable.RotationPredicates or {}
AddonTable.RotationSpecs = AddonTable.RotationSpecs or {}

local function SpellName(id) return AddonTable.SpellName(id) end

-- O cliente não expõe "está parado/castando" de forma nua: IsPlayerMoving()
-- existe em algumas engines; só usamos se existir; nunca inventamos movimento.
local function IsMoving()
    if type(IsPlayerMoving) == "function" then
        local ok, moving = pcall(IsPlayerMoving)
        return ok and moving == true
    end
    return false
end

-- Timer de combate para Mana Spring (luta > 45 s): PLAYER_REGEN_DISABLED/ENABLED
local elemCombatStart
local manaSpringFrame = CreateFrame("Frame")
manaSpringFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
manaSpringFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
manaSpringFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        elemCombatStart = type(GetTime) == "function" and GetTime() or nil
    else
        elemCombatStart = nil
    end
end)

local function FireTotemUp()
    if not AddonTable.IsTotemActiveByName then return true end
    return AddonTable.IsTotemActiveByName(SpellName(3599)) or AddonTable.IsTotemActiveByName(SpellName(8190))
end

local P = AddonTable.RotationPredicates

P["always"]             = { label = "sempre", fn = function(env) return true end }
P["is_moving"]          = { label = "em movimento", fn = function(env) return IsMoving() end }
P["in_combat"]          = { label = "em combate", fn = function(env) return env.inCombat and true or false end }
P["aoe"]                = { label = "AoE (2+ inimigos)", fn = function(env) return env.isAoE and true or false end }
P["not_aoe"]            = { label = "alvo único", fn = function(env) return not env.isAoE and true or false end }
P["has_enemy"]          = { label = "alvo atacável", fn = function(env) return env.hasActiveEnemy and true or false end }
P["mana_above15"]       = { label = "mana acima de 15%", fn = function(env) return (env.manaPct or 0) > 15 end }
P["mana_above40"]       = { label = "mana acima de 40%", fn = function(env) return (env.manaPct or 0) > 40 end }
P["ranged"]             = { label = "fora de alcance melee", fn = function(env) return not env.tooCloseForRanged and true or false end }
P["flame_shock_missing"] = { label = "Flame Shock ausente (alvo atacável, mana ok)",
    fn = function(env)
        return env.hasActiveEnemy and (env.manaPct or 0) > 15 and not AddonTable.IsFlameShockUp("target")
    end }
P["aoe_fire_totem_up"]  = { label = "AoE com totem de fogo ativo",
    fn = function(env)
        return env.isAoE and (env.manaPct or 0) > 15 and FireTotemUp()
    end }
P["aoe_fire_totem_missing"] = { label = "AoE e falta totem de fogo (Magma)",
    fn = function(env)
        return env.isAoE and not (AddonTable.IsTotemActiveByName and AddonTable.IsTotemActiveByName(SpellName(8190)))
    end }
P["st_fire_totem_missing"] = { label = "alvo único e falta totem de fogo (Searing)",
    fn = function(env)
        return not env.isAoE and not (AddonTable.IsTotemActiveByName and AddonTable.IsTotemActiveByName(SpellName(3599)))
    end }
P["mana_spring_missing"] = { label = "Mana Spring ausente (luta longa ou mana < 50%)",
    fn = function(env)
        if not AddonTable.IsTotemActiveByName then return false end
        if AddonTable.IsTotemActiveByName(SpellName(5675)) then return false end
        local longFight = elemCombatStart and (type(GetTime) == "function") and (GetTime() - elemCombatStart > 45)
        return ((env.manaPct or 100) < 50 or longFight) and true or false
    end }

AddonTable.RotationSpecs.ELE = {
    title = "Elemental",
    nodes = AddonTable.ConcatCommonNodes(AddonTable.ShamanCommonNodes, {
        { id = "earth_shock_move", spellID = 8042,  name = "Earth Shock",     color = "White",  condition = "is_moving" },
        { id = "lightning_mastery", spellID = 16166, name = "Lightning Mastery", color = "Yellow", condition = "in_combat" },
        { id = "magma_totem",      spellID = 8190,  name = "Magma Totem",    color = "Purple", condition = "aoe_fire_totem_missing" },
        { id = "searing_totem",    spellID = 3599,  name = "Searing Totem",  color = "Green",  condition = "st_fire_totem_missing" },
        { id = "mana_spring",      spellID = 5675,  name = "Mana Spring Totem", color = "Green", condition = "mana_spring_missing" },
        { id = "flame_shock",      spellID = 8050,  name = "Flame Shock",    color = "Pink",   condition = "flame_shock_missing" },
        { id = "chain_lightning",  spellID = 421,   name = "Chain Lightning", color = "Purple", condition = "cl_ok" },
        { id = "fire_nova",        spellID = 1535,  name = "Fire Nova",      color = "Orange", condition = "aoe_fire_totem_up" },
        { id = "lightning_bolt",   spellID = 403,   name = "Lightning Bolt", color = "White",  condition = "ranged" },
    }),
}

function AddonTable.RunELERotation(env)
    local SF = _G["SpellFlashForever"]
    if SF and type(SF.RunDeclaredRotation) == "function" then
        return SF.RunDeclaredRotation(AddonTable, "ELE", env)
    end
    return false
end
