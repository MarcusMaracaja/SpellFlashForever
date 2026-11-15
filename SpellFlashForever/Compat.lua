-- SpellFlashForever / Compat.lua
-- Camada de compatibilidade: expõe, no objeto SpellFlashForever (_G["SpellFlashForever"]),
-- a API que os módulos de classe do SpellFlash (WotLK 3.3.5) esperam em `SpellFlashAddon`.
-- O objetivo é NÃO tocar na lógica da rotação dos módulos; adaptar só a infraestrutura.
-- Tudo aqui usa a API moderna (Interface 16001) e pcall + issecretvalue como fail-safe.

local addonName = "SpellFlashForever"
local s = _G[addonName]
if not s then
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SF]|r Compat: SpellFlashForever table missing.")
    end
    return
end
local L = s.L

-- ---------------------------------------------------------------------------
-- Helpers locais
-- ---------------------------------------------------------------------------

local function CopyTableLocal(t)
    local out = {}
    if type(t) == "table" then
        for k, v in pairs(t) do out[k] = v end
    end
    return out
end

local function StripRankLocal(name)
    if type(name) ~= "string" then return "" end
    name = name:gsub("%s*%b()%s*$", "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    return name
end

local function IsSecret(v)
    local issecret = _G.issecretvalue
    return issecret and issecret(v) or false
end

local function SafeNumber(fn, fallback)
    local ok, v = pcall(fn)
    if not ok then return fallback end
    if _G.issecretvalue and issecretvalue(v) then return fallback end
    if type(v) ~= "number" then return fallback end
    return v
end

local function SafeInteractDistance(unit, dist)
    if type(CheckInteractDistance) ~= "function" then return nil end
    local ok, result = pcall(CheckInteractDistance, unit, dist)
    if not ok then return nil end
    if IsSecret(result) then return nil end
    return result and true or false
end
s.SafeInteractDistance = SafeInteractDistance

local function SafeUnitIsUnit(a, b)
    if type(UnitIsUnit) ~= "function" then return false end
    local ok, result = pcall(UnitIsUnit, a, b)
    if not ok then return false end
    if IsSecret(result) then return false end
    return not not result
end

-- ---------------------------------------------------------------------------
-- Tabelas que o SpellFlash antigo expunha (vazias por padrão)
-- ---------------------------------------------------------------------------

s.CopyTable = CopyTableLocal
s.Castable = s.Castable or {}
s.VehicleCastable = s.VehicleCastable or {}
s.ItemCastable = s.ItemCastable or {}

-- ---------------------------------------------------------------------------
-- Leitura de auras (buffs/debuffs)
-- Em combate a leitura pode vir *secret*; nesse caso retornamos false
-- (fail-safe: "não confirmado", nunca "confirmado").
-- ---------------------------------------------------------------------------

local AURA_HELPFUL = "HELPFUL"
local AURA_HARMFUL = "HARMFUL"

-- Percorre as auras de `unit` com o filtro dado até `max`.
-- fn(aura) -> true interrompe com sucesso.
-- Retorna: found (bool), readable (bool: false = leitura vazia/secret)
local function AuraWalk(unit, filter, max, fn)
    if not C_UnitAuras or type(C_UnitAuras.GetAuraDataByIndex) ~= "function" then
        return false, false
    end
    if not UnitExists(unit) then
        return false, true
    end
    for i = 1, (max or 40) do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, filter)
        if not ok then
            return false, false
        end
        if aura == nil then
            return false, true -- varredura completa
        end
        if IsSecret(aura.name) then
            return false, false -- inlegível neste contexto
        end
        local matched = false
        local ok2, ret = pcall(fn, aura)
        if ok2 and ret then
            matched = true
        end
        if matched then
            return true, true
        end
    end
    return false, true
end

local function AuraNameMatches(auraName, wanted)
    if type(auraName) ~= "string" or type(wanted) ~= "string" then return false end
    return StripRankLocal(auraName):lower() == StripRankLocal(wanted):lower()
end

-- CheckBuff(SpellName, unit, mine) / CheckDebuff(SpellName, unit, mine)
-- SpellName pode ser string, número (ID) ou tabela de strings.
-- mine=true exige sourceUnit == "player".
local function CheckAura(filter, defaultUnit, SpellName, unit, mine)
    unit = unit or defaultUnit
    if not UnitExists(unit) then return false end

    -- Normaliza para lista de nomes
    local wanted = {}
    local function AddWanted(w)
        if type(w) == "number" then
            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(w)
            w = info and info.name or tostring(w)
        end
        if type(w) == "string" and w ~= "" then
            wanted[#wanted + 1] = w
        end
    end
    if type(SpellName) == "table" then
        for _, w in ipairs(SpellName) do AddWanted(w) end
    else
        AddWanted(SpellName)
    end
    if #wanted == 0 then return false end

    local found = AuraWalk(unit, filter, 40, function(aura)
        for _, w in ipairs(wanted) do
            if AuraNameMatches(aura.name, w) then
                if not mine then return true end
                local source = aura.sourceUnit
                if source == nil or IsSecret(source) then
                    -- source ilegível: não dá para confirmar que é nossa
                    return false
                end
                return SafeUnitIsUnit(source, "player") or SafeUnitIsUnit(source, "pet")
            end
        end
        return false
    end)
    return found and true or false
end

function s.CheckBuff(SpellName, unit, mine)
    return CheckAura(AURA_HELPFUL, "player", SpellName, unit, mine)
end

function s.CheckDebuff(SpellName, unit, mine)
    return CheckAura(AURA_HARMFUL, "target", SpellName, unit, mine)
end

-- Alias usados por módulos antigos (maiúsculas/minúsculas de conveniência)
s.Buff = s.CheckBuff
s.Debuff = s.CheckDebuff

-- ---------------------------------------------------------------------------
-- CC / imobilização / controle
-- Listas mínimas enUS+ptBR; sem leitura possível, fail-safe false.
-- ---------------------------------------------------------------------------

local BREAK_ON_DAMAGE = {
    "Sap", "Golpe de Matraca",
    "Kidney Shot", "Golpe no Rim",
    "Gouge", "Soneca",
    "Hammer of Justice", "Martelo da Justiça",
    "Bash",
    "Intimidation", "Intimidação",
    "Pounce", "Surra",
    "Cheap Shot", "Ataque Furtivo",
    "Cyclone", "Ciclone",
    "Hibernate", "Hibernar",
    "Wyvern Sting", "Picada de Mantícora",
    "Polymorph", "Polimorfia",
    "Blind", "Cegueira",
    "Freeze", "Congelar",
    "Scatter Shot", "Disparo Espalhado",
}

local MOVEMENT_IMPAIRING = {
    "Root", "Enraizar", "Entangling Roots", "Raízes Enredadeiras",
    "Frost Nova", "Nova de Gelo",
    "Earthbind", "Ligação Terrena",
    "Wing Clip", "Cortar Asas",
    "Concussive Shot", "Tiro Sufocante", "Disparo Concussivo",
    "Hamstring", "Desestabilizar Tendão",
    "Slowing Poison", "Veneno de Lentidão",
    "Conflagrate", "Conflagrar",
}

function s.BreakOnDamageCC(unit)
    return CheckAura(AURA_HARMFUL, "target", BREAK_ON_DAMAGE, unit, false)
end

function s.ImmunityDebuff(unit)
    return false
end

function s.NoDamageCC(unit)
    return s.BreakOnDamageCC(unit) or s.ImmunityDebuff(unit)
end

function s.Feared(unit)
    return CheckAura(AURA_HARMFUL, "target", {
        "Fear", "Medo", "Psychic Scream", "Grito Psíquico",
        "Intimidating Shout", "Brado Intimidador",
        "Howl of Terror", "Uivo de Terror",
        "Seduction", "Sedução",
    }, unit, false)
end

-- (mantém a grafia antiga com o typo "Crowed" que os módulos usam)
function s.CrowedControlled(unit)
    return s.NoDamageCC(unit) or s.Feared(unit)
end

function s.IsCrowedControlled(unit)
    return s.CrowedControlled(unit)
end

function s.Rooted(unit)
    return CheckAura(AURA_HARMFUL, "target", MOVEMENT_IMPAIRING, unit, false)
end

function s.MovementImpaired(unit)
    return s.Rooted(unit) or CheckAura(AURA_HARMFUL, "target", MOVEMENT_IMPAIRING, unit, false)
end

function s.IsMovementImpaired(unit)
    return s.MovementImpaired(unit)
end

function s.Poisoned(unit)
    return false -- leitura de auras por tipo (Poison) não disponível de forma confiável
end

-- ---------------------------------------------------------------------------
-- Spells: conhecimento, alcance, custo, cooldown, usabilidade
-- ---------------------------------------------------------------------------

local function SpellIDFromName(name)
    if type(name) ~= "string" then return nil end
    return s.SpellNameToID and (s.SpellNameToID[name] or s.SpellNameToID[StripRankLocal(name)]) or nil
end

-- ---------------------------------------------------------------------------
-- Famílias de rank do Hunter (baseadas no pack Hekili_Hunter do Forever):
-- no cliente, só o rank ATUAL está no livro de feitiços; os ranks de base
-- (rank 1 etc.) respondem "desconhecido". Para a rotação, "conhecido" =
-- "qualquer rank da família conhecido".
-- ---------------------------------------------------------------------------

local FAMILIES = {
    { 3044, 14281, 14282, 14283, 14284, 14285, 14286, 14287 }, -- Arcane Shot
    { 19434, 20900, 20901, 20902, 20903, 20904 },               -- Aimed Shot
    { 1978, 13549, 13550, 13551, 13552, 13553, 13554, 13555, 25295 }, -- Serpent Sting
    { 1130, 14323, 14324, 14325, 1213268 },                     -- Hunter's Mark
    { 2973, 14260, 14261, 14262, 14263, 14264, 14265, 14266 },  -- Raptor Strike
    { 1495, 14269, 14270, 14271 },                              -- Mongoose Bite
    { 2974, 1310180, 14267, 14268 },                            -- Wing Clip
    { 13165, 14318, 14319, 14320, 14321, 14322, 25296 },        -- Aspect of the Hawk
    { 13161, 1299445, 1299446, 1299447 },                       -- Aspect of the Beast
    { 13795, 14302, 14303, 14304, 14305 },                      -- Immolation Trap
    { 13813, 14310, 14311, 14312 },                             -- Explosive Trap (melhor esforço)
    -- Shaman (1.60.1; famílias permitem "conhecido"/CD em qualquer rank).
    -- Ranks conferidos na tabela Forever do usuário (Nv 1-60) + Spy\List.lua:
    -- (Lava Burst removido do jogo no tuning de 2026-11-03 — família 51505 removida em H-0133)
    { 403, 529, 548, 915, 943, 6041, 10391, 10392, 15207, 15208 }, -- Lightning Bolt
    { 421, 930, 2860, 10605 },                                   -- Chain Lightning
    { 8050, 8052, 8053, 10447, 10448, 29228 },                   -- Flame Shock
    { 8042, 8044, 8045, 8046, 10412, 10413, 10414 },             -- Earth Shock
    { 1535, 8498, 8499, 11314, 11315 },                          -- Fire Nova (tabela Forever, Nv 12/22/32/42/52; Spy confirma)
    { 3599, 6363, 6364, 6365, 10437, 10438 },                    -- Searing Totem
    { 8190, 10585, 10586, 10587 },                               -- Magma Totem
    { 324, 325, 905, 945, 8134, 10431, 10432 },                  -- Lightning Shield
    { 8024, 8027, 8030, 16339, 16341, 16342 },                   -- Flametongue Weapon
    { 8232, 8235, 10486, 16362 },                                -- Windfury Weapon
    { 8075, 8160, 8161, 10442, 25361 },                          -- Strength of Earth Totem
    { 5675, 10495, 10496, 10497 },                               -- Mana Spring Totem
    { 8143 },                                                    -- Tremor Totem
    { 8177 },                                                    -- Grounding Totem
    { 17364 },                                                   -- Stormstrike (talento Enhancement; 150% normalizado, 6s CD pós-tuning 2026-11-03)
    { 16166 },                                                   -- Talento Ele 16166 ("Lightning Mastery"; antes "Elemental Mastery"; -0.5s LB, CL sem CD, 15s)
    { 425336 },                                                  -- Talento Enh 425336 (Rage of the Farseer; +30% vel. ataque 25s)
    -- Paladin (Forever 1.60.1): IDs vanilla/verification cross-check Spy\List.lua 2026-11-14
    { 20271 },                                                   -- Judgement (único rank)
    { 20116, 20922, 20924 },                                     -- Consecration (ranks 20/40/60)
    { 680 },                                                     -- Holy Strike (novo Forever; VERIFICAR EM JOGO)
    { 24275 },                                                   -- Hammer of Wrath (único)
    { 10308 },                                                   -- Exorcism (único)
    { 20915 },                                                   -- Seal of Command (único)
    { 20289 },                                                   -- Seal of Righteousness (único)
    { 25780 },                                                   -- Righteous Fury (único)
    { 28153 },                                                   -- Holy Shield (VERIFICAR EM JOGO)
    { 853 },                                                      -- Hammer of Justice (único)
    -- Priest (Forever 1.60.1): cross-check Spy\List.lua 2026-11-14 (Holy Strike-like não há ranks)
    { 15473 },                                                   -- Shadowform (único)
    { 8921, 8924, 8925, 8926, 8927, 8928, 8929, 9833, 9834, 9835 }, -- Moonfire (10 ranks Forever)
    { 589, 594, 970, 3449 },                                     -- Shadow Word: Pain (1-4)
    { 8092, 8102, 8103, 8104, 8105 },                            -- Mind Blast (1-5)
    { 2944 },                                                     -- Devouring Plague (novo Forever; VERIFICAR)
    { 1309595 },                                                  -- Shadow Word: Death (novo Forever; VERIFICAR)
    { 15407 },                                                    -- Mind Flay (talento Shadow)
    { 15286 },                                                    -- Vampiric Embrace (talento Shadow)
    { 585 },                                                      -- Smite (único; ranks posteriores não nomeados)
    { 14914 },                                                    -- Holy Fire (talento)
    { 402174 },                                                   -- Penance (talento; novo; VERIFICAR)
    { 14751 },                                                    -- Inner Focus (talento)
    -- Druid (Forever 1.60.1): ranks conferidos no Questing.wiki/Wowhead Forever (2026-11-14)
    { 1126, 5232, 6756, 5234, 8907, 9884, 9885 },               -- Mark of the Wild (7 ranks)
    { 467, 782, 1075, 8914, 9756, 9910 },                       -- Thorns (6 ranks)
    { 16689, 16810, 16811, 16812, 16813, 17329 },               -- Nature's Grasp / Enredamento (6 ranks)
    { 22812 },                                                   -- Barkskin (única)
    { 29166 },                                                   -- Innervate (única)
    { 18562 },                                                   -- Swiftmend (única)
}

local familyOf = {}
for _, fam in ipairs(FAMILIES) do
    for _, id in ipairs(fam) do
        familyOf[id] = fam
    end
end

-- Maior rank conhecido da família, ou nil
local function HighestKnownInFamily(fam)
    if C_SpellBook and type(C_SpellBook.IsSpellKnownOrInSpellBook) == "function" then
        for i = #fam, 1, -1 do
            local ok, known = pcall(C_SpellBook.IsSpellKnownOrInSpellBook, fam[i])
            if ok and known == true then return fam[i] end
        end
    end
    if C_SpellBook and type(C_SpellBook.IsSpellKnown) == "function" then
        for i = #fam, 1, -1 do
            local ok, known = pcall(C_SpellBook.IsSpellKnown, fam[i])
            if ok and known == true then return fam[i] end
        end
    end
    return nil
end

-- Resolve qualquer rank para o rank conhecido da família (para CD/alcance)
local function ResolveKnownID(id)
    if type(id) ~= "number" then return id end
    local fam = familyOf[id]
    if fam then
        return HighestKnownInFamily(fam)
    end
    return id
end
s.ResolveKnownID = ResolveKnownID

-- Resolve qualquer rank para o nome/ID do rank conhecido (para a UI da barra)
local function KnownRankOf(id)
    local fam = familyOf[id]
    if not fam then return id end
    return HighestKnownInFamily(fam)
end

function s.IsSpellKnown(nameOrID)
    local id = type(nameOrID) == "number" and nameOrID or SpellIDFromName(nameOrID)
    if id then
        -- Spell com família de ranks: conhecido = qualquer rank da família
        local fam = familyOf[id]
        if fam then
            return HighestKnownInFamily(fam) ~= nil
        end
        -- Este cliente expõe IsSpellKnownOrInSpellBook(spellID[, spellBank, includeOverrides])
        if C_SpellBook and type(C_SpellBook.IsSpellKnownOrInSpellBook) == "function" then
            local ok, result = pcall(C_SpellBook.IsSpellKnownOrInSpellBook, id)
            if ok then return not not result end
        end
        if C_SpellBook and type(C_SpellBook.IsSpellKnown) == "function" then
            local ok, result = pcall(C_SpellBook.IsSpellKnown, id)
            if ok then return not not result end
        end
        return true
    end
    if type(nameOrID) == "string" and nameOrID:match("^%d+$") then
        return false
    end
    if type(GetSpellInfo) == "function" and type(nameOrID) == "string" then
        local ok, result = pcall(GetSpellInfo, nameOrID)
        if ok and result then return true end
    end
    return false
end

function s.SpellHasRange(spellName)
    local id = type(spellName) == "number" and spellName or SpellIDFromName(spellName)
    if not id then
        if type(spellName) == "string" and spellName:match("^%d+$") then
            return false
        end
        return true -- desconhecido: assume que tem alcance (não bloqueia)
    end
    if not C_Spell or type(C_Spell.GetSpellInfo) ~= "function" then return true end
    local ok, info = pcall(C_Spell.GetSpellInfo, id)
    if not ok or not info then return true end
    return (info.maxRange or 0) > 0
end

s.SpellInRange = s.IsSpellInRange

function s.CurrentSpell(spellName)
    return s.IsCurrentSpell and s.IsCurrentSpell(spellName) or false
end

function s.SpellCost(spellName, powerType)
    local id = type(spellName) == "number" and spellName or SpellIDFromName(spellName)
    if not id then return 0 end
    if not C_Spell or type(C_Spell.GetSpellPowerCost) ~= "function" then
        return 0
    end
    local ok, result = pcall(C_Spell.GetSpellPowerCost, id)
    if not ok or result == nil then return 0 end
    if type(result) == "number" then return result end
    if type(result) == "table" then
        local first = result[1]
        if type(first) == "table" then
            return first.cost or first.manaCost or 0
        end
        return result.cost or result.manaCost or 0
    end
    return 0
end

function s.UsableSpell(spellName)
    local id = type(spellName) == "number" and spellName or SpellIDFromName(spellName)
    if id and C_Spell and type(C_Spell.IsSpellUsable) == "function" then
        local ok, isUsable, notEnoughPower = pcall(C_Spell.IsSpellUsable, id)
        if ok then
            return isUsable and true or false, not not notEnoughPower
        end
    end
    if type(IsUsableSpell) == "function" then
        local ok, a, b = pcall(IsUsableSpell, spellName)
        if ok then
            return a and true or false, not not b
        end
    end
    return true, false
end

function s.UsesMana(unit)
    unit = unit or "target"
    if type(UnitPowerType) == "function" and UnitPowerType(unit) == 0 then
        return true
    end
    if type(UnitPowerMax) == "function" then
        local ok, maxMana = pcall(UnitPowerMax, unit, 0)
        return ok and (maxMana or 0) > 0 or false
    end
    return true -- desconhecido: assume que usa mana
end

function s.AllDebuffSlotsUsed(unit)
    return false -- fail-safe: nunca bloqueia por "slots de debuff cheios"
end

function s.AuraDelay(SpellName, unit)
    return false -- timers de aura não são rastreados neste cliente
end

-- ---------------------------------------------------------------------------
-- Cast em andamento / canalização
-- ---------------------------------------------------------------------------

function s.GetCasting(spellName, unit)
    unit = unit or "player"
    if type(UnitCastingInfo) == "function" then
        local ok, _, _, _, _, startTimeMS, endTimeMS = pcall(UnitCastingInfo, unit)
        if ok and endTimeMS and startTimeMS then
            local remaining = ((endTimeMS or 0) - (GetTime and GetTime() * 1000 or 0)) / 1000
            if remaining > 0 then return remaining end
            return 0
        end
    end
    return nil
end

function s.CastingOrChanneling(spellName, unit, interruptible, noSubName)
    local casting = s.GetCasting(spellName, unit or "player")
    if casting then return casting end
    if type(UnitChannelInfo) == "function" then
        local ok, _, _, _, _, endTimeMS, _, notInterruptible = pcall(UnitChannelInfo, unit or "player")
        if ok and endTimeMS then
            if interruptible == nil or notInterruptible == nil or notInterruptible == not interruptible then
                local remaining = ((endTimeMS or 0) - (GetTime and GetTime() * 1000 or 0)) / 1000
                if remaining > 0 then return remaining end
                return 0
            end
        end
    end
    return nil
end

function s.Casting(spellName, unit, interruptible, noSubName)
    return s.CastingOrChanneling(spellName, unit, interruptible, noSubName)
end

function s.MeleeDistance(unit)
    local meleeID = (_G.SpellFlashForever and { DEATHKNIGHT = 45902, DRUID = 1082, HUNTER = 2973, PALADIN = 35395, ROGUE = 1752, SHAMAN = 8017, WARRIOR = 78 })[select(2, UnitClass("player")) or ""]
    if meleeID and s.IsSpellKnown(meleeID) then
        local r = s.IsSpellInRange(meleeID, unit or "target")
        return r and true or false
    end
    local d = SafeInteractDistance(unit or "target", 3)
    return d and true or false
end

-- Cooldown pelo slot da barra de ação (resposta do próprio cliente pro botão).
-- Robusto: independe de rank/nome; usa C_ActionBar.GetActionCooldown quando existir.
function s.ActionCooldown(slot)
    if not slot then return 0, 0 end
    if C_ActionBar and type(C_ActionBar.GetActionCooldown) == "function" then
        local ok, info = pcall(C_ActionBar.GetActionCooldown, slot)
        if ok and type(info) == "table" then
            local start = SafeNumber(function() return info.startTime end, nil)
                or SafeNumber(function() return info.cooldownStartTime end, nil)
                or 0
            local duration = SafeNumber(function() return info.duration end, nil)
                or SafeNumber(function() return info.cooldownDuration end, nil)
                or 0
            local isActive = info.isActive == true
            local remaining = SafeNumber(function() return info.timeUntilEndOfStartRecovery end, nil)
            if remaining ~= nil and remaining > 0 then
                return remaining, math.max(1.6, duration > 0 and duration or 1.6)
            end
            local now = SafeNumber(function() return GetTime() end, 0) or 0
            local timeLeft = start + duration - now
            if isActive and timeLeft <= 0 then
                timeLeft = (duration > 0 and math.max(1.6, duration)) or 5
            end
            if timeLeft > 0 then
                if duration <= 1.5 then duration = 1.6 end
                return timeLeft, duration
            end
            if duration > 1.5 and start == 0 then return duration, duration end
            return 0, 0
        end
    end
    -- Fallback: GetActionCooldownDuration (pode ser Duration object ou número)
    if C_ActionBar and type(C_ActionBar.GetActionCooldownDuration) == "function" then
        local ok, d = pcall(C_ActionBar.GetActionCooldownDuration, slot)
        if ok then
            if type(d) == "number" and d > 0 then return d, d end
        end
    end
    return 0, 0
end

function s.CheckGlobalPotions()
    return false -- poções ficam a cargo do próprio módulo
end

-- ---------------------------------------------------------------------------
-- Inimigos / alvo ativo
-- ---------------------------------------------------------------------------

function s.Enemy(unit)
    unit = unit or "target"
    local okE, exists = pcall(UnitExists, unit)
    if not okE or not exists then return false end
    local ok, canAttack = pcall(UnitCanAttack, "player", unit)
    -- Ilegível/secret neste cliente (checagem tainted): não bloqueia a rotação;
    -- se a resposta é ilegível, tratamos como "atacável".
    if not ok or (_G.issecretvalue and issecretvalue(canAttack)) then canAttack = true end
    if not canAttack then return false end
    -- Mas alvo morto/fantasma nunca é inimigo válido (leitura confiável)
    local ok2, dead = pcall(UnitIsDeadOrGhost, unit)
    if ok2 and dead then return false end
    return true
end

function s.ActiveEnemy(unit)
    unit = unit or "target"
    if not s.Enemy(unit) then return false end
    local ok, inCombat = pcall(function()
        return UnitAffectingCombat and UnitAffectingCombat("player") or InCombatLockdown()
    end)
    local isPlayer = false
    if type(UnitIsPlayer) == "function" then
        local ok3, r = pcall(UnitIsPlayer, unit)
        if ok3 then isPlayer = not not r end
    end
    return (ok and inCombat) or isPlayer or false
end

function s.IsActiveEnemy(unit)
    return s.ActiveEnemy(unit)
end

-- ---------------------------------------------------------------------------
-- Imunidades (sem banco de dados no Forever: fail-safe false)
-- ---------------------------------------------------------------------------

function s.Immune(spellName, unit)
    return false
end

-- ---------------------------------------------------------------------------
-- Auto Shot (auto-repeater)
-- ---------------------------------------------------------------------------

-- Preenchido pelos eventos START/STOP_AUTOREPEAT_SPELL no driver abaixo.

-- ---------------------------------------------------------------------------
-- CheckIfSpellCastable(z) — coração do SpellFlash antigo, portado com fail-safe
-- ---------------------------------------------------------------------------

local GLOBAL_COOLDOWN_SPELL = ({
    DEATHKNIGHT = 45902, DRUID = 5176, HUNTER = 3044, MAGE = 133, PALADIN = 635,
    PRIEST = 585, ROGUE = 1752, SHAMAN = 403, WARLOCK = 686, WARRIOR = 772,
})[select(2, UnitClass("player")) or ""] or 2973

local function TargetOrFocusCompat(unit)
    if unit then return unit end
    if type(IsModifiedClick) == "function" and IsModifiedClick("FOCUSCAST") then return "focus" end
    return "target"
end

-- TargetIsSelf: helper local para não depender de UnitIsUnit em mapas
-- restritos (onde UnitIsUnit devolve secret).
local function TargetIsSelf(unit)
    if not unit then return false end
    return SafeUnitIsUnit(unit, "player")
end

function s.CheckIfSpellCastable(InfoArray)
    local z = InfoArray
    if type(z) ~= "table" then return false end

    if type(z.SpellID) == "number" then
        z.SpellName = s.SpellName and s.SpellName(z.SpellID) or tostring(z.SpellID)
    elseif type(z.SpellName) == "number" then
        z.SpellID = z.SpellName
        z.SpellName = s.SpellName and s.SpellName(z.SpellID) or tostring(z.SpellID)
    end
    if not z.SpellName then
        return false
    end
    -- Nome-base sem sufixo de grau ("(Grau 2)"): usado nas consultas de CD/usabilidade,
    -- que resolvem pelo cache s.SpellNameToID (chaveado pelo nome sem grau).
    local baseName = StripRankLocal(z.SpellName)

    local spellID = z.SpellID
    if not spellID and type(z.SpellName) == "string" then
        spellID = SpellIDFromName(z.SpellName)
    end

    if spellID then
        if not s.IsSpellKnown(spellID) then return false end
    elseif not s.HasSpell(z.SpellName) then
        return false
    end

    z.Unit = TargetOrFocusCompat(z.Unit)

    if z.EnemyTargetNeeded and s.Immune(spellID or z.SpellName, z.Unit) then
        return false
    end

    local lag = 0
    if type(GetNetStats) == "function" then
        local ok, _, _, latency = pcall(GetNetStats)
        if ok and type(latency) == "number" then
            lag = latency / 1000
        end
    end

    local castingTimeLeft = s.GetCasting(nil, "player") or 0
    local isUsable, notEnoughPower = s.UsableSpell(baseName)
    local cooldown = 0
    local duration = 0
    -- Preferência: cooldown por spellID no rank conhecido (funciona — /sfcd mostrou
    -- timeLeft=27.8, dur=30). Slot da barra entra como REFORÇO (confirma o CD), não
    -- como única fonte: se o slot reportar algo diferente, o maior vence — nunca
    -- deixar CD real passar.
    local knownID = s.ResolveKnownID and s.ResolveKnownID(spellID) or spellID
    local cdID = knownID or spellID
    local cooldown, duration = 0, 0
    if s.SpellCooldown and cdID then
        local cd, dur = s.SpellCooldown(cdID)
        cooldown = cd or 0
        duration = dur or 0
    end
    local actionSlot = nil
    if knownID and s.FindActionSlot then
        actionSlot = s.FindActionSlot(knownID)
    end
    if actionSlot and s.ActionCooldown then
        local sc, sd = s.ActionCooldown(actionSlot)
        if sc and sc > (cooldown or 0) then
            cooldown, duration = sc, sd or duration
        end
    end
    local globalcooldown = 0
    if GLOBAL_COOLDOWN_SPELL and s.SpellCooldown then
        local gcd = s.SpellCooldown(GLOBAL_COOLDOWN_SPELL)
        globalcooldown = gcd or 0
    end
    local Aura = z.Debuff or z.Buff or z.MyDebuff or z.MyBuff
    -- Observação: o custo de mana é coberto por s.UsableSpell (C_Spell.IsSpellUsable devolve notEnoughPower).

    return ((z.EvenIfNotUsable or isUsable) and not notEnoughPower)
        and (z.NoRangeCheck or TargetIsSelf(z.Unit) or not s.SpellHasRange(baseName) or (s.SpellInRange(baseName, z.Unit) == 1))
        and (cooldown <= lag + castingTimeLeft or (globalcooldown == 0 and duration <= 1.5) or (globalcooldown > 0 and cooldown <= globalcooldown))
        and ((not z.NotIfActive and not Aura) or (not s.CurrentSpell(baseName) and not s.CastingOrChanneling(baseName, "player")) or (not Aura and (s.CastingOrChanneling(baseName, "player") or 0) <= lag))
        and (not z.EnemyTargetNeeded or s.Enemy(z.Unit))
        and (not z.TargetThatUsesManaNeeded or s.UsesMana(z.Unit))
        and (not z.DebuffSlotNeeded or not s.AllDebuffSlotsUsed(z.Unit))
        and (not z.Debuff or (not s.AuraDelay(z.Debuff, z.Unit) and not s.CheckDebuff(z.Debuff, z.BuffUnit or z.Unit or "target", z.MyDebuff == z.Debuff and true or nil)))
        and (not z.Buff or (not s.AuraDelay(z.Buff, z.Unit) and not s.CheckBuff(z.Buff, z.BuffUnit or z.Unit or "target", z.MyBuff == z.Buff and true or nil)))
        and (not z.MyDebuff or (not s.AuraDelay(z.MyDebuff, z.Unit) and not s.CheckDebuff(z.MyDebuff, z.BuffUnit or z.Unit or "target", true)))
        and (not z.MyBuff or (not s.AuraDelay(z.MyBuff, z.Unit) and not s.CheckBuff(z.MyBuff, z.BuffUnit or z.Unit or "target", true)))
end

-- ---------------------------------------------------------------------------
-- Flashable: spell conhecida e utilizável (o "piscar" ainda passa por
-- CheckIfSpellCastable no próprio módulo).
-- ---------------------------------------------------------------------------

function s.Flashable(spellName)
    if not spellName then return false end
    if s.IsSpellKnown(spellName) == false then return false end
    return true
end

-- ---------------------------------------------------------------------------
-- Driver do Spam: chama s.Spam[...] a cada ~0.2 s com a mesma tabela `x`
-- que o RunSpam do SpellFlash (WotLK) montava.
-- ---------------------------------------------------------------------------

local spamElapsed = 0
local spamInterval = 0.2

local function BuildSpamVars()
    local x = {}
    x.ActiveEnemy = s.ActiveEnemy("target")
    x.Enemy = x.ActiveEnemy or s.Enemy("target")
    x.NoCC = x.ActiveEnemy or not s.NoDamageCC("target")
    local okPet, petAlive = pcall(function()
        if not UnitExists("pet") then return false end
        local hp = UnitHealth("pet")
        return hp == nil or hp > 0
    end)
    x.PetAlive = okPet and petAlive or false
    x.PetActiveEnemy = x.PetAlive and s.ActiveEnemy("pettarget") or false
    x.PetNoCC = (not x.PetAlive) or x.PetActiveEnemy or not s.BreakOnDamageCC("pettarget")
    if type(IsInInstance) == "function" then
        local ok, inInstance, instanceType = pcall(IsInInstance)
        x.InInstance = ok and inInstance or false
        x.InstanceType = ok and instanceType or nil
    else
        x.InInstance = false
        x.InstanceType = nil
    end
    x.Lag = 0
    x.DoubleLag = 0
    return x
end

local driver = CreateFrame("Frame", "SpellFlashForeverSpamDriver", UIParent)
driver:SetScript("OnUpdate", function(self, elapsed)
    spamElapsed = spamElapsed + (elapsed or 0)
    if spamElapsed < spamInterval then return end
    spamElapsed = 0

    if SpellFlashForeverDB and SpellFlashForeverDB.handle and SpellFlashForeverDB.handle.spell_flashing_off then
        return
    end
    if type(s.Spam) ~= "table" or not next(s.Spam) then return end

    local x = BuildSpamVars()
    for moduleName, fn in pairs(s.Spam) do
        if type(fn) == "function" then
            -- Respeita o toggle individual do módulo (aba no /sf)
            local moduleOff = s.GetModuleConfig and s.GetModuleConfig(moduleName, "spell_flashing_off")
            if not moduleOff then
                local ok, err = pcall(fn, x)
                if not ok and s.DebugFlash then
                    DEFAULT_CHAT_FRAME:AddMessage(string.format(L.compat_module_failed, tostring(moduleName), tostring(err)))
                end
            end
        end
    end
end)
driver:RegisterEvent("START_AUTOREPEAT_SPELL")
driver:RegisterEvent("STOP_AUTOREPEAT_SPELL")
driver:SetScript("OnEvent", function(self, event)
    if event == "START_AUTOREPEAT_SPELL" then
        s.AutoShoot = 1
    elseif event == "STOP_AUTOREPEAT_SPELL" then
        s.AutoShoot = nil
    end
end)

-- ---------------------------------------------------------------------------
-- Global compatível com os módulos WotLK
-- ---------------------------------------------------------------------------

_G.SpellFlashAddon = s

DEFAULT_CHAT_FRAME:AddMessage(L.compat_loaded)
