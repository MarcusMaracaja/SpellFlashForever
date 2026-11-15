-- SpellFlash_Shaman / Functions.lua
-- Castable table do Shaman Forever (Interface 16001). IDs verificados em
-- warcraftmaps.com / foreverdb.app / wowhead ("In the game files", patch 1.60.1)
-- e em D:\wow lk (referência redirecionada; ranks foram conferidos).
-- Arquitetura igual ao SpellFlash_Hunter: AddonTable.Castable["Name"](Fn) → spell -
-- cada função devolve true se a magia pode ser sugerida.
-- IDs de rank base → o FAMILIES do Compat resolve o rank CONHECIDO (Forever só
-- tem o rank atual no livro; ranks antigos respondem "desconhecido").
-- Tabela de ranks Forever (NÍVEL 1-60) conferida pelo usuário em 2026-11-13
-- (cross-check Spy\List.lua): registrado no histórico H-0121.

local AddonName, AddonTable = ...
local L = AddonTable.L
local SFBF = _G["SpellFlashForever"]

AddonTable.Castable = AddonTable.Castable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.Castable)) or {}
AddonTable.VehicleCastable = AddonTable.VehicleCastable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.VehicleCastable)) or {}
AddonTable.ItemCastable = AddonTable.ItemCastable or (SFBF and SFBF.CopyTable and SFBF.CopyTable(SFBF.ItemCastable)) or {}

print(string.format(L.mod_loaded, "Shaman", L.mod_load_functions))

local function SpellName(id) return AddonTable.SpellName(id) end
local AddonCastable = AddonTable.Castable

-- =====================================================
-- BUFFS (imbues/escudo): recomendados sempre (a detecção de "já tem"
-- avalia antes/durante o combate) — a crença de cast no core (AuraUp,
-- H-0168) é o que bloqueia a sugestão após o cast; a API positiva fura
-- primeiro fora de combate.
-- =====================================================
AddonCastable["Lightning Shield"] = function()
    local z = {}
    z.SpellID = 324
    z.SpellName = SpellName(324)
    z.Buff = z.SpellName
    z.BuffUnit = "player"
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

AddonCastable["Flametongue Weapon"] = function()
    local z = {}
    z.SpellID = 8024
    z.SpellName = SpellName(8024)
    z.Buff = z.SpellName
    z.BuffUnit = "player"
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

AddonCastable["Windfury Weapon"] = function()
    local z = {}
    z.SpellID = 8232
    z.SpellName = SpellName(8232)
    z.Buff = z.SpellName
    z.BuffUnit = "player"
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

-- =====================================================
-- TOTENS (sugestão fora/em combate; detecção por NOME — GetTotemInfo)
-- =====================================================
AddonCastable["Searing Totem"] = function()
    local z = {}
    z.SpellID = 3599
    z.SpellName = SpellName(3599)
    z.NoRangeCheck = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

AddonCastable["Magma Totem"] = function()
    local z = {}
    z.SpellID = 8190
    z.SpellName = SpellName(8190)
    z.NoRangeCheck = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

AddonCastable["Strength of Earth Totem"] = function()
    local z = {}
    z.SpellID = 8075
    z.SpellName = SpellName(8075)
    z.NoRangeCheck = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

AddonCastable["Mana Spring Totem"] = function()
    local z = {}
    z.SpellID = 5675
    z.SpellName = SpellName(5675)
    z.NoRangeCheck = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

AddonCastable["Tremor Totem"] = function()
    local z = {}
    z.SpellID = 8143
    z.SpellName = SpellName(8143)
    z.NoRangeCheck = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

AddonCastable["Grounding Totem"] = function()
    local z = {}
    z.SpellID = 8177
    z.SpellName = SpellName(8177)
    z.NoRangeCheck = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

-- =====================================================
-- DANO — ELEMENTAL (caster) / ENHANCEMENT (melee)
-- Ranks Forever (tabela do usuário, Nv 1-60, 2026-11-13; cross-check Spy\List.lua):
--   Lightning Bolt: 403(1) 529(8) 548(14) 915(20) 943(26) 6041(32) 10391(38) 10392(44) 15207(50) 15208(56)
--   Chain Lightning: 421(32) 930(40) 2860(48) 10605(56)  [2.5s cast; mana ~225% do LB; treina nv32]
--   Flame Shock:     8050(10) 8052(18) 8053(28) 10447(40) 10448(52) 29228(60)
--   Earth Shock:     8042(4) 8044(8) 8045(14) 8046(24) 10412(36) 10413(48) 10414(60)
--   Fire Nova:       1535(12) 8498(22) 8499(32) 11314(42) 11315(52)
--   Stormstrike:     17364 (nv40, talento Enhancement; 150% normalizado, 6s CD pós-tuning 2026-11-03)
--   Lightning Mastery: 16166 (nv40, talento Ele — antes "Elemental Mastery"; -0.5s LB + CL sem CD, 15s, CD 3min)
--   Rage of the Farseer: 425336 (nv40, talento Enh; +30% vel. ataque 25s)
--   Lava Burst: REMOVIDO do jogo no tuning de 2026-11-03 (família 51505 removida do Compat em H-0133)
--   Searing Totem:   3599(10) 6363(20) 6364(30) 6365(40) 10437(50) 10438(60)
--   Magma Totem:     8190(26) 10585(36) 10586(46) 10587(56)
--   Lightning Shield:324(8) 325(16) 905(24) 945(32) 8134(40) 10431(48) 10432(56)
--   Flametongue W.:  8024(10) 8027(18) 8030(26) 16339(36) 16341(46) 16342(56)
--   Windfury W.:     8232(30) 8235(40) 10486(50) 16362(60)
--   Strength of Earth:8075(10) 8160(24) 8161(38) 10442(52) 25361(60)
--   Mana Spring:     5675(26) 10495(36) 10496(46) 10497(56)
-- =====================================================
AddonCastable["Lightning Bolt"] = function()
    local z = {}
    z.SpellID = 403
    z.SpellName = SpellName(403)
    z.EnemyTargetNeeded = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

AddonCastable["Chain Lightning"] = function()
    local z = {}
    z.SpellID = 421
    z.SpellName = SpellName(421)
    z.EnemyTargetNeeded = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

-- Lava Burst REMOVIDO do Forever no tuning de 2026-11-03 (família 51505 removida do Compat).

-- Fire Nova (PvE AoE; IDs Forever confirmados na tabela do usuário — reintroduzida
-- na rotação Elemental AoE por decisão do usuário, H-0121). Sem alvo necessário
-- (nova centrada no jogador); exige totem de fogo ativo (checado na rotação).
AddonCastable["Fire Nova"] = function()
    local z = {}
    z.SpellID = 1535
    z.SpellName = SpellName(1535)
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

AddonCastable["Earth Shock"] = function()
    local z = {}
    z.SpellID = 8042
    z.SpellName = SpellName(8042)
    z.EnemyTargetNeeded = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

AddonCastable["Flame Shock"] = function()
    local z = {}
    z.SpellID = 8050
    z.SpellName = SpellName(8050)
    z.MyDebuff = z.SpellName
    z.EnemyTargetNeeded = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

-- Lightning Mastery (16166, nv40, talento Ele — antes "Elemental Mastery"):
-- -0.5s no cast de Lightning Bolt e Chain Lightning sem cooldown durante 15s; CD 3min.
AddonCastable["Elemental Mastery"] = function()
    local z = {}
    z.SpellID = 16166
    z.SpellName = SpellName(16166)
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

-- Rage of the Farseer (425336, nv40, talento Enh): +30% velocidade de ataque por 25s.
AddonCastable["Rage of the Farseer"] = function()
    local z = {}
    z.SpellID = 425336
    z.SpellName = SpellName(425336)
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

-- Stormstrike (Enhancement; talento nv40): melee; pós-tuning 2026-11-03 = 150% do dano
-- normalizado de arma em 6s de CD (antes 100% / 8s). Buffa o próximo Lightning Bolt/
-- Chain Lightning/Earth Shock no alvo.
AddonCastable["Stormstrike"] = function()
    if AddonTable.IsInMeleeRange and not AddonTable.IsInMeleeRange("target") then return false end
    local z = {}
    z.SpellID = 17364
    z.SpellName = SpellName(17364)
    z.EnemyTargetNeeded = 1
    return SpellFlashAddon.CheckIfSpellCastable(z)
end

-- NOTA: "Fire Nova" (IDs Forever 1535/8498/8499/11314/11315 — tabela do usuário,
-- 2026-11-13) foi REINTRODUZIDA na rotação Elemental AoE por decisão do usuário
-- (H-0121), com gate em totem de fogo ativo (Searing/Magma). Antes (H-0117) havia
-- sido removida por falta de prova em jogo.

-- =====================================================
-- Prefixo COMUM a ELE/ENH (interrupt + self-buffs + SoE)
-- Antes hardcoded no hub (Scripts.lua); agora nós declarados —
-- aparecem (e são editáveis) na rotação de Elemental e Enhancement.
-- =====================================================
AddonTable.RotationPredicates = AddonTable.RotationPredicates or {}
local P = AddonTable.RotationPredicates
P["enemy_casting"] = { label = L.pred_casting_interrupt,
    fn = function(env)
        if not env.hasActiveEnemy then return false end
        return AddonTable.IsTargetInterruptibleCasting and AddonTable.IsTargetInterruptibleCasting("target") and true or false
    end }

-- Clearcasting (Elemental Focus, 16246): aura de jogador que torna o próximo cast
-- de Lightning gratuito/crítico — justificativa para gastar o Chain Lightning.
local CLEARCASTING_ID = 16246
local function HasClearcasting()
    if not (C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function") then return false end
    for i = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
        if not ok or not aura then break end
        local okS, sp = pcall(function() return aura.spellId end)
        if okS and type(sp) == "number" and not (_G.issecretvalue and issecretvalue(sp)) and sp == CLEARCASTING_ID then
            return true
        end
    end
    return false
end
P["has_clearcasting"] = { label = L.pred_clearcasting,
    fn = function(env) return HasClearcasting() end }
-- Gate do Chain Lightning pós-tuning (mana ~225% do LB): só com AoE, mana >= 50% ou Clearcasting.
P["cl_ok"] = { label = L.pred_chain_lightning_ok,
    fn = function(env)
        if env.isAoE then return (env.manaPct or 0) > 15 end
        if (env.manaPct or 0) >= 50 then return true end
        return HasClearcasting()
    end }
P["is_melee"]      = { label = L.pred_melee_range, fn = function(env) return env.isMelee and true or false end }
P["melee_combat"]  = { label = L.pred_melee_combat, fn = function(env) return env.isMelee and env.inCombat and true or false end }
P["is_ele"]           = { label = "Elemental", fn = function(env) return env.spec == "ELE" end }
P["is_enh"]           = { label = "Enhancement", fn = function(env) return env.spec == "ENH" end }
P["not_lightning_shield_up"] = { label = L.pred_lightning_shield,
    fn = function(env) return not AddonTable.IsSelfBuffUp(324) end }
P["not_flametongue_up_ele"] = { label = L.pred_ele_flametongue,
    fn = function(env) return env.spec == "ELE" and not AddonTable.IsSelfBuffUp(8024) end }
P["not_windfury_up_enh"] = { label = L.pred_enh_windfury,
    fn = function(env) return env.spec == "ENH" and not AddonTable.IsSelfBuffUp(8232) end }
P["is_enh_not_soe_up"]  = { label = L.pred_enh_earth,
    fn = function(env)
        if env.spec ~= "ENH" then return false end
        if not AddonTable.IsTotemActiveByName then return true end
        return not AddonTable.IsTotemActiveByName(SpellName(8075))
    end }

AddonTable.ShamanCommonNodes = {
    { id = "earth_shock_interrupt", spellID = 8042, name = "Earth Shock (interrupt)", color = "Aqua", condition = "enemy_casting" },
    { id = "lightning_shield",      spellID = 324,  name = "Lightning Shield",  color = "Green",  condition = "not_lightning_shield_up" },
    { id = "flametongue_weapon",    spellID = 8024, name = "Flametongue Weapon", color = "Green", condition = "not_flametongue_up_ele" },
    { id = "windfury_weapon",       spellID = 8232, name = "Windfury Weapon",   color = "Green",  condition = "not_windfury_up_enh" },
    { id = "strength_of_earth",     spellID = 8075, name = "Strength of Earth Totem", color = "Green", condition = "is_enh_not_soe_up" },
}

function AddonTable.ConcatCommonNodes(common, nodes)
    local out = {}
    for _, n in ipairs(common or {}) do out[#out + 1] = n end
    for _, n in ipairs(nodes or {}) do out[#out + 1] = n end
    return out
end
