-- SpellFlashForever / SharedFunctions.lua
-- Utilitários compartilhados por TODOS os módulos de classe (Hunter hoje; BM/MM e
-- qualquer implementação futura também). Stateless: sem frames, sem eventos, sem
-- estado por sessão. Tudo fail-open com pcall + issecretvalue.
-- Convenção: funções exportadas no mesmo facade de sempre (s = SpellFlashForever /
-- _G.SpellFlashAddon). Os módulos de classe delegam com AddonTable.X = SpellFlashAddon.X.

local addonName = "SpellFlashForever"
local s = _G[addonName]
if not s then
    if DEFAULT_CHAT_FRAME then
        -- Locales.lua ainda não carregou aqui só se a TOC estiver quebrada;
        -- mensagem mínima para depuração.
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SF]|r SharedFunctions: SpellFlashForever table missing.")
    end
    return
end
local L = s.L

local IsSecret = _G.issecretvalue and function(v) return _G.issecretvalue(v) end or function() return false end
local function StripParens(name)
    if type(name) ~= "string" then return "" end
    return (name:gsub("%s*%b()%s*$", ""))
end

-- ---------------------------------------------------------------------------
-- Nomes de feitiços / itens + cache nome -> ID (substitui GetSpellInfo global).
-- ---------------------------------------------------------------------------
s.SpellNameToID = s.SpellNameToID or {}

function s.SpellName(id)
    if type(id) ~= "number" then return id end
    if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
        local ok, info = pcall(C_Spell.GetSpellInfo, id)
        if ok and info and info.name then
            s.SpellNameToID[info.name] = id
            return info.name
        end
    end
    return tostring(id)
end

function s.ItemName(id)
    if type(id) ~= "number" then return id end
    if C_Item and type(C_Item.GetItemInfo) == "function" then
        local ok, name = pcall(C_Item.GetItemInfo, id)
        if ok and name then return name end
    end
    if type(GetItemInfo) == "function" then
        local ok, name = pcall(GetItemInfo, id)
        if ok and name then return name end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Rank de família: maior rank conhecido (varre da maior p/ menor).
-- ---------------------------------------------------------------------------
local function HighestKnownRank(ids)
    if C_SpellBook and type(C_SpellBook.IsSpellKnownOrInSpellBook) == "function" then
        for i = #ids, 1, -1 do
            local ok, known = pcall(C_SpellBook.IsSpellKnownOrInSpellBook, ids[i])
            if ok and known == true then return ids[i] end
        end
    end
    if C_SpellBook and type(C_SpellBook.IsSpellKnown) == "function" then
        for i = #ids, 1, -1 do
            local ok, known = pcall(C_SpellBook.IsSpellKnown, ids[i])
            if ok and known == true then return ids[i] end
        end
    end
    return nil
end
s.HighestKnownRank = HighestKnownRank

-- ---------------------------------------------------------------------------
-- Alcance físico e de barra de ação (IsActionInRange do Forever: true/1/false/0,
-- nil, secret ? desconhecido). Wing Clip como sondagem (Hunter; outras classes
-- podem passar outra lista).
-- ---------------------------------------------------------------------------
local AUTO_ATTACK_ID = 6603
local AUTO_SHOT_ID   = 75
local WING_CLIP      = { 2974, 1310180, 14267, 14268 } -- inclui row de nível 12 do Forever

local function RangeAnswer(v)
    if v == nil then return nil end
    if IsSecret(v) then return nil end
    if v == true or v == 1 then return true end
    if v == false or v == 0 then return false end
    return nil
end

local IsActionInRangeNS = (C_ActionBar and C_ActionBar.IsActionInRange) or IsActionInRange

local function ActionSlotRange(slot, unit)
    if not slot or type(IsActionInRangeNS) ~= "function" then return nil end
    local ok, result = pcall(IsActionInRangeNS, slot, unit)
    if ok then
        local answer = RangeAnswer(result)
        if answer ~= nil then return answer end
    end
    ok, result = pcall(IsActionInRangeNS, slot)
    if ok then return RangeAnswer(result) end
    return nil
end
s.ActionSlotRange = ActionSlotRange

-- Distância ao alvo em jardas (DF: UnitDistanceSquared, squared; exige checked=true)
function s.TargetDistance(unit)
    unit = unit or "target"
    if type(UnitDistanceSquared) ~= "function" then return nil end
    if not UnitExists(unit) then return nil end
    local ok, squared, checked = pcall(UnitDistanceSquared, unit)
    if not ok then return nil end
    if IsSecret(squared) then return nil end
    if checked ~= true then return nil end
    if type(squared) ~= "number" or squared < 0 then return nil end
    return math.sqrt(squared)
end

-- true = melee; false = ranged; nil = desconhecido
-- Orbit: slot de "Atacar" -> sondagem Wing Clip -> slot de "Tiro Automático"
-- invertido -> (fora de combate) interação física. Sem chute.
function s.IsInMeleeRange(unit, probeRanks)
    unit = unit or "target"
    probeRanks = probeRanks or WING_CLIP
    if not UnitExists(unit) then return nil end

    local attackSlot = s.FindActionSlot and s.FindActionSlot(AUTO_ATTACK_ID)
    local attackRange = ActionSlotRange(attackSlot, unit)
    if attackRange ~= nil then return attackRange end

    if s.IsSpellInRangeEx then
        local known = HighestKnownRank(probeRanks)
        if known then
            local r = s.IsSpellInRangeEx(known, unit)
            if r == true then return true end
        end
    end

    local autoShotSlot = s.FindActionSlot and s.FindActionSlot(AUTO_SHOT_ID)
    local autoShotRange = ActionSlotRange(autoShotSlot, unit)
    if autoShotRange == true then return false end
    if autoShotRange == false then return true end

    if not (type(InCombatLockdown) == "function" and InCombatLockdown()) and s.SafeInteractDistance then
        return s.SafeInteractDistance(unit, 3)
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Falha-segura de API de combate (subidas antigas do cliente):
-- CheckInteractDistance protegido em combate; UnitIsUnit secret em instâncias.
-- ---------------------------------------------------------------------------
function s.SafeInteractDistance(unit, dist)
    if type(InCombatLockdown) == "function" and InCombatLockdown() then return nil end
    if type(CheckInteractDistance) ~= "function" then return nil end
    local ok, result = pcall(CheckInteractDistance, unit, dist)
    if not ok then return nil end
    if IsSecret(result) then return nil end
    return result and true or false
end

function s.SafeUnitIsUnit(a, b)
    if type(UnitIsUnit) ~= "function" then return false end
    local ok, r = pcall(UnitIsUnit, a, b)
    if not ok then return false end
    if IsSecret(r) then return false end
    return not not r
end

-- Substitutos modernos de GetNumPartyMembers/GetNumRaidMembers (removidos).
-- party = membros além de você (0-4); raid = total incluindo você (1-40).
function s.GetNumPartyMembers()
    if type(IsInRaid) == "function" and IsInRaid() then return 0 end
    if type(GetNumGroupMembers) ~= "function" then return 0 end
    return math.max(0, GetNumGroupMembers() - 1)
end

function s.GetNumRaidMembers()
    if type(IsInRaid) == "function" and IsInRaid() then
        return (type(GetNumGroupMembers) == "function" and GetNumGroupMembers()) or 0
    end
    return 0
end

-- ---------------------------------------------------------------------------
-- Alvo: tipos comuns entre todas as classes.
-- ---------------------------------------------------------------------------
function s.IsTargetEnemyPlayer(unit)
    unit = unit or "target"
    return UnitIsPlayer(unit) and UnitCanAttack("player", unit)
end

-- Alvo está conjurando algo interrompível? (qualquer classe)
function s.IsTargetInterruptibleCasting(unit)
    unit = unit or "target"
    local okCA, canAttack = pcall(UnitCanAttack, "player", unit)
    if not okCA or not canAttack then return false end
    if type(UnitCastingInfo) == "function" then
        local ok, name, _, _, _, _, _, _, notInterruptible = pcall(UnitCastingInfo, unit)
        if ok and name then
            if IsSecret(notInterruptible) then return false end
            return not notInterruptible
        end
    end
    if type(UnitChannelInfo) == "function" then
        local ok, name, _, _, _, _, _, _, notInterruptible = pcall(UnitChannelInfo, unit)
        if ok and name then
            if IsSecret(notInterruptible) then return false end
            return not notInterruptible
        end
    end
    return false
end

-- Alvo está imune (lista de IDs de imunidade + CheckBuff, para qualquer classe;
-- se omitida, usa a lista padrão: Ice Block, Divine Shield, Hand of Protection,
-- Cyclone, Banish, Deterrence, Dispersion, Cloak of Shadows)
local DEFAULT_IMMUNITIES = { 45438, 642, 1022, 33786, 710, 19263, 47585, 31224 }
function s.IsTargetImmune(unit, immunities)
    unit = unit or "target"
    immunities = immunities or DEFAULT_IMMUNITIES
    for _, id in ipairs(immunities) do
        local spellName = s.SpellName(id)
        if spellName and s.CheckBuff and s.CheckBuff(spellName, unit) then return true end
    end
    return false
end

-- =====================================================
-- ALVO ALIADO E VIVO (posições: buffar alvo amigo, heal em alvo amigo).
-- Qualquer unidade que exista, seja aliada e esteja viva dá true.
-- =====================================================
function s.UnitFriendlyAndAlive(unit)
    unit = unit or "target"
    if not (UnitExists and UnitExists(unit)) then return false end
    local dead = false
    if type(UnitIsDeadOrGhost) == "function" then
        local ok, d = pcall(UnitIsDeadOrGhost, unit)
        if ok and d then dead = true end
    elseif type(UnitIsDead) == "function" then
        local ok, d = pcall(UnitIsDead, unit)
        if ok and d then dead = true end
    end
    if dead then return false end
    if type(UnitIsFriend) ~= "function" then return true end -- sem API: não bloqueia
    local ok, f = pcall(UnitIsFriend, "player", unit)
    return ok and (f and true or false) or false
end

-- =====================================================
-- DETECÇÃO DE SPEC CLASS-AGNÓSTICA (pontos por árvore)
-- Trees do cliente Forever (configId → treeIDs → nós); a árvore com mais
-- pontos vence. 'treeHints': mapa chave→lista de tokens (substrings,
-- case-insensitive) contra o nome localizado da árvore.
-- 'ordinalFallback': array opcional de specs para casar os treeIDs quando o
-- nome não é dedutível - ex.: Hunter {"SV","MM","BM"}; Warrior {"ARMS","FURY","PROT"};
-- Shaman {"ELE","ENH","REST"}; Druid {"FERAL","BAL","REST"}.
-- =====================================================
function s.CountTalentTreePoints(treeHints, ordinalFallback)
    local out = false
    pcall(function()
        if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID
            and C_Traits and C_Traits.GetConfigInfo and C_Traits.GetTreeNodes
            and C_Traits.GetNodeInfo) then
            return
        end
        local cfg = C_ClassTalents.GetActiveConfigID()
        if type(cfg) ~= "number" then return end
        local info = C_Traits.GetConfigInfo(cfg)
        if type(info) ~= "table" or type(info.treeIDs) ~= "table" then return end

        local counts = {}
        for k in pairs(treeHints or {}) do counts[k] = 0 end
        counts.unknown = 0

        -- Hint keys alphabetilizado é kept como último fallback
        local hintKeys = {}
        for k in pairs(treeHints or {}) do hintKeys[#hintKeys + 1] = k end
        table.sort(hintKeys)
        local function hintAt(i)
            if ordinalFallback and ordinalFallback[i] then return ordinalFallback[i] end
            return hintKeys[i]
        end

        local function Classify(name)
            if type(name) ~= "string" then return nil end
            local n = name:lower()
            for spec, tokens in pairs(treeHints or {}) do
                for _, t in ipairs(tokens) do
                    if n:find(t, 1, true) then return spec end
                end
            end
            return nil
        end

        local names = {}
        for i = 1, #info.treeIDs do
            local treeID = info.treeIDs[i]
            local treeInfo = nil
            if C_Traits.GetTreeInfo then
                local ok, ti = pcall(C_Traits.GetTreeInfo, cfg, treeID)
                if ok then treeInfo = ti end
            end
            local treeName = treeInfo and (treeInfo.displayName or treeInfo.name)
            local spec = Classify(treeName) or hintAt(i) or "unknown"
            local total = 0
            local nodes = C_Traits.GetTreeNodes(treeID)
            if type(nodes) == "table" then
                for _, nodeID in ipairs(nodes) do
                    local ni = C_Traits.GetNodeInfo(cfg, nodeID)
                    local r = type(ni) == "table"
                        and (tonumber(ni.currentRank) or tonumber(ni.ranksPurchased) or tonumber(ni.activeRank))
                        or 0
                    total = total + (r or 0)
                end
            end
            counts[spec] = (counts[spec] or 0) + total
            names[i] = (type(treeName) == "string" and treeName) or L.shared_unnamed
        end
        out = { counts = counts, names = names }
    end)
    if out then return out end
    return nil
end
