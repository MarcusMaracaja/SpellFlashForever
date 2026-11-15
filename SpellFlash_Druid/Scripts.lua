-- SpellFlash_Druid / Scripts.lua
-- Orquestra mestre do módulo Druid do Forever (ALU 16001).
-- Detecção de spec por pontos via C_Traits (a árvore com mais pontos vence;
-- empate → Feral). Override por /sf → Druid.
local AddonName, AddonTable = ...

-- Expõe o módulo para o core (debug, /sf status)
_G.SpellFlash_Druid = AddonTable

if not AddonTable.ShouldUseRacial then AddonTable.ShouldUseRacial = function() return nil end end
if not AddonTable.ShouldUseTrinket then AddonTable.ShouldUseTrinket = function() return nil end end

local L = AddonTable.L
local SpellFlashAddon = SpellFlashAddon

local TREE_HINTS_DRUID = {
    FERAL = { "feral", "felino", "felina", "cat" },
    BAL = { "balance", "equilíbrio", "equilibrio" },
    REST = { "restau", "restor", "restaur" },
}

local function SpellName(id) return AddonTable.SpellName(id) end
local function Castable(name, ...)
    if type(AddonTable.Castable[name]) == "function" then
        return AddonTable.Castable[name](...)
    end
    return false
end
local function TryFlash(spellID, color, condition, englishName)
    if condition and condition() then
        if SpellFlashAddon.Flashable(SpellName(spellID)) and Castable(englishName) then
            SpellFlashAddon.FlashAction(SpellName(spellID), color)
            return true
        end
    end
    return false
end

-- Expõe p/ o motor declarativo (RunDeclaredRotation)
AddonTable.TryFlash = TryFlash
AddonTable.RotationModuleName = AddonName

local function GetComboPoints()
    if type(UnitComboPoint) == "function" then
        local ok, n = pcall(UnitComboPoint, "player")
        if ok and type(n) == "number" then return n end
    end
    if type(UnitPower) == "function" then
        local ok, n = pcall(UnitPower, "player", "combopoints")
        if ok and type(n) == "number" then return n end
    end
    return 0
end

local function GetAoECount()
    local okList, units = pcall(function()
        if type(C_NamePlate) == "table" and type(C_NamePlate.EnumerateUnits) == "function" then
            return { C_NamePlate.EnumerateUnits() }
        end
    end)
    if not okList or type(units) ~= "table" then return 1 end
    local n = 0
    for _, unit in ipairs(units) do
        local okE, canAttack = pcall(UnitCanAttack, "player", unit)
        if okE and canAttack then n = n + 1 end
        if n > 10 then return n end
    end
    return math.max(n, 1)
end

-- Forma atual do Druida (1 Cat / 2 Bear / 3 Moonkin / 0 caster)
local function IsPlayerMounted()
    if type(_G.IsMounted) == "function" and _G.IsMounted() then return true end
    if type(_G.IsInMountedState) == "function" and _G.IsInMountedState() then return true end
    return false
end

local function GetDruidForm()
    -- FORM (SpellFlashAddon.Form) não existe neste cliente (core SpellFlashForever).
    -- UnitPowerType é barato e disponível nos dois mundos:
    --   RAGE (1) -> Urso; ENERGIA (3) -> Gato; MANA (0) -> caster/Moonkin.
    if type(UnitPowerType) == "function" then
        local ok, pt = pcall(UnitPowerType, "player")
        if ok and tonumber(pt) then
            pt = tonumber(pt)
            if pt == 1 then return 2 end
            if pt == 3 then return 1 end
            return 0
        end
    end
    -- Fallback para a antiga API (caso algum dia exista neste cliente)
    if type(SpellFlashAddon.Form) == "function" then
        if SpellFlashAddon.Form(SpellName(768)) then return 1 end
        if SpellFlashAddon.Form(SpellName(5487)) then return 2 end
        if SpellFlashAddon.Form(SpellName(24858)) then return 3 end
    end
    return 0
end

local function IsBehind()
    if type(AddonTable.IsBehindTarget) == "function" then
        local ok, r = pcall(AddonTable.IsBehindTarget)
        if ok and r then return true end
    end
    return false
end

-- =====================================================
-- AURAS (self-buffs, buffs de alvo, debuffs ofensivos):
-- a crença por cast vive no core (Compat.lua) — aqui só
-- registramos o que este módulo usa e expomos wrappers.
-- =====================================================
local MARK_IDS    = { 1126, 5232, 6756, 5234, 8907, 9884, 9885 }
local THORNS_IDS  = { 467,  782,  1075, 8914, 9756, 9910 }
local ENRED_IDS   = { 16689, 16810, 16811, 16812, 16813, 17329 }
local ROAR_IDS    = { 99, 1735, 9490, 9747, 9898 }
AddonTable.ROAR_IDS = ROAR_IDS

if SpellFlashAddon and type(SpellFlashAddon.RegisterAuraBelief) == "function" then
    SpellFlashAddon.RegisterAuraBelief({
        { ids = MARK_IDS,   duration = 3600, unit = "auto"   }, -- alvo aliado ou self
        { ids = THORNS_IDS, duration = 600,  unit = "auto"   }, -- alvo aliado ou self
        { ids = ENRED_IDS,  duration = 45,   unit = "player" }, -- self-only
        { ids = ROAR_IDS,   duration = 30,   unit = "target" }, -- alvo ofensivo
    })
end

AddonTable.IsSelfMarkUp   = function() return SpellFlashAddon and SpellFlashAddon.AuraUp and SpellFlashAddon.AuraUp("player", MARK_IDS, "buff") or false end
AddonTable.IsSelfThornsUp = function() return SpellFlashAddon and SpellFlashAddon.AuraUp and SpellFlashAddon.AuraUp("player", THORNS_IDS, "buff") or false end
AddonTable.IsSelfEnredUp  = function() return SpellFlashAddon and SpellFlashAddon.AuraUp and SpellFlashAddon.AuraUp("player", ENRED_IDS, "buff") or false end
AddonTable.IsTargetMarkUp   = function() return SpellFlashAddon and SpellFlashAddon.AuraUp and SpellFlashAddon.AuraUp("target", MARK_IDS, "buff") or false end
AddonTable.IsTargetThornsUp = function() return SpellFlashAddon and SpellFlashAddon.AuraUp and SpellFlashAddon.AuraUp("target", THORNS_IDS, "buff") or false end
AddonTable.IsRoarUp         = function() return SpellFlashAddon and SpellFlashAddon.AuraUp and SpellFlashAddon.AuraUp("target", ROAR_IDS, "debuff") or false end

-- =====================================================
-- ROTATION SPECS (declaradas como DADO; editor /sf → Druid)
-- =====================================================
if AddonTable.RotationPredicates then
    AddonTable.RotationPredicates["behind"] = { label = L.pred_behind, fn = function(env) return IsBehind() end }
end

AddonTable.RotationSpecs = AddonTable.RotationSpecs or {}

AddonTable.RotationSpecs.CAT = {
    title = L.title_cat,
    -- SEM nó de forma: o jogador escolhe a forma; a rotação de Gato roda só quando
    -- em Cat Form (o hub despacha CAT/BEAR conforme env.form).
    nodes = AddonTable.ConcatCommonNodes(AddonTable.DruidCommonNodes, {
        { id = "pounce",   spellID = 9005, name = "Pounce",         color = "Yellow", condition = "pounce_condition" },
        { id = "rip",      spellID = 1079, name = "Rip",            color = "Yellow", condition = "combo5" },
        { id = "ferocious_bite", spellID = 22568, name = "Ferocious Bite", color = "Orange", condition = "combo5" },
        { id = "rake",     spellID = 1822, name = "Rake",           color = "Pink",   condition = "energy40" },
        { id = "shred",    spellID = 5221, name = "Shred",          color = "Yellow", condition = "behind" },
        { id = "claw",     spellID = 1082, name = "Claw",           color = "White",  condition = "always" },
    }),
}

AddonTable.RotationSpecs.BEAR = {
    title = L.title_bear,
    -- SEM nó de forma: o jogador escolhe a forma; a rotação de Urso roda quando
    -- em Bear Form (o hub despacha BEAR conforme env.form == 2).
    nodes = AddonTable.ConcatCommonNodes(AddonTable.DruidCommonNodes, {
        { id = "bash",     spellID = 5211, name = "Bash",           color = "Aqua",   condition = "target_casting" },
        { id = "frenzied_regeneration", spellID = 22842, name = "Frenzied Regeneration", color = "Green", condition = "my_hp35", passthrough = true },
        { id = "maul",     spellID = 6807, name = "Maul",           color = "Yellow", condition = "always" },
        { id = "swipe",    spellID = 779,  name = "Swipe (Bear)",   color = "Purple", condition = "aoe_and_enemy" },
        { id = "lacerate", spellID = 54802, name = "Lacerate",      color = "Pink",   condition = "has_enemy" },
        { id = "growl",    spellID = 6795, name = "Growl",          color = "Yellow", condition = "has_enemy" },
    }),
}

AddonTable.RotationSpecs.BAL = {
    title = "Balance",
    nodes = AddonTable.ConcatCommonNodes(AddonTable.DruidCommonNodes, {
        { id = "moonkin_form", spellID = 24858, name = "Moonkin Form", color = "Green", condition = "not_moonkin" },
        { id = "insect_swarm", spellID = 912,   name = "Insect Swarm", color = "Pink",  condition = "insect_swarm_missing" },
        { id = "moonfire",     spellID = 9835,  name = "Moonfire",     color = "Pink",  condition = "moonfire_missing" },
        { id = "starfire",     spellID = 8950,  name = "Starfire",     color = "Yellow", condition = "always" },
        { id = "wrath",        spellID = 5177,  name = "Wrath",        color = "Yellow", condition = "always" },
    }),
}

AddonTable.RotationSpecs.REST = {
    title = L.title_rest,
    nodes = AddonTable.ConcatCommonNodes(AddonTable.DruidCommonNodes, {
        { id = "frenzied_regeneration", spellID = 22842, name = "Frenzied Regeneration", color = "Green", condition = "always" },
        { id = "cat_form",    spellID = 768,   name = "Cat Form",    color = "Green",  condition = "bear_form" },
    }),
}

AddonTable.RotationSpecs.SELF = {
    title = "Self-buffs",
    -- Spec enxuta: só os self-buffs do prefixo comum (Mark of the Wild, Thorns).
    -- Usada quando Feral está em forma humana/caster (sem rotação de forma ativa).
    nodes = AddonTable.ConcatCommonNodes(AddonTable.DruidCommonNodes, {}),
}

-- =====================================================
-- ROTAÇÃO MESTRE
-- =====================================================
SpellFlashAddon.Spam[AddonName] = function(x)
    -- Só executa se o jogador for Druid
    local _, myClass = UnitClass("player")
    if myClass ~= "DRUID" then return end
    local env = {
        hasActiveEnemy = x.ActiveEnemy or (UnitExists("target") and UnitCanAttack("player", "target")),
        inCombat = SpellFlashAddon.InCombat and SpellFlashAddon.InCombat(),
        isMelee = AddonTable.IsInMeleeRange and AddonTable.IsInMeleeRange("target"),
        myHP = SpellFlashAddon.HealthPercent and SpellFlashAddon.HealthPercent("player") or 100,
        targetHP = SpellFlashAddon.HealthPercent and SpellFlashAddon.HealthPercent("target") or 100,
        rage = UnitPower("player") or 0,
        energy = ((function() local ok, p = pcall(UnitPower, "player", 3); if ok and tonumber(p) then return tonumber(p) end return 0 end)()),
        enemies = GetAoECount(),
        isAoE = GetAoECount() >= 2,
        isPvP = AddonTable.IsTargetEnemyPlayer and AddonTable.IsTargetEnemyPlayer("target") or false,
        targetCasting = AddonTable.IsTargetInterruptibleCasting and AddonTable.IsTargetInterruptibleCasting("target"),
        isCCd = SpellFlashAddon.IsCrowedControlled and SpellFlashAddon.IsCrowedControlled("player") or false,
        form = GetDruidForm(),
        combo = GetComboPoints(),
        mounted = IsPlayerMounted(),
        targetExists = UnitExists and UnitExists("target") and true or false,
        targetFriendlyAlive = (SpellFlashAddon and SpellFlashAddon.UnitFriendlyAndAlive and SpellFlashAddon.UnitFriendlyAndAlive("target")) or false,
    }

    -- =====================================================
    -- DETECÇÃO DE SPEC (override → pontos por árvore; empate → Feral)
    -- =====================================================
    local override = SpellFlashAddon.GetModuleConfig and SpellFlashAddon.GetModuleConfig(AddonName, "spec_override") or nil

    if AddonTable.TalentCountCache == nil then
        AddonTable.TalentCountCache = false
        AddonTable.TalentCountCache = SpellFlashAddon.CountTalentTreePoints and SpellFlashAddon.CountTalentTreePoints(TREE_HINTS_DRUID, { "FERAL", "BAL", "REST" }) or false
    end
    local counts = type(AddonTable.TalentCountCache) == "table" and AddonTable.TalentCountCache.counts or nil
    local pointsFeral, pointsBal, pointsRest = 0, 0, 0
    if counts then
        pointsFeral, pointsBal, pointsRest = tonumber(counts.FERAL) or 0, tonumber(counts.BAL) or 0, tonumber(counts.REST) or 0
    end

    local bestTree = nil
    if pointsFeral >= pointsBal and pointsFeral >= pointsRest and pointsFeral > 0 then
        bestTree = "FERAL"
    elseif pointsBal > pointsRest and pointsBal > 0 then
        bestTree = "BAL"
    elseif pointsRest > 0 then
        bestTree = "REST"
    end

    local isFeral, isBal, isRest, specSource
    if override == "FERAL" then isFeral, isBal, isRest, specSource = true, false, false, "override"
    elseif override == "BAL" then isFeral, isBal, isRest, specSource = false, true, false, "override"
    elseif override == "REST" then isFeral, isBal, isRest, specSource = false, false, true, "override"
    elseif bestTree == "FERAL" then isFeral, isBal, isRest, specSource = true, false, false, "Feral=" .. tostring(pointsFeral)
    elseif bestTree == "BAL" then isFeral, isBal, isRest, specSource = false, true, false, "Balance=" .. tostring(pointsBal)
    elseif bestTree == "REST" then isFeral, isBal, isRest, specSource = false, false, true, "Restoration=" .. tostring(pointsRest)
    else isFeral, isBal, isRest, specSource = true, false, false, L.dbg_default_spec .. " Feral" end

    -- Mensagem de Inicialização (uma vez por sessão) + saudação racial
    if not AddonTable.SpecMessageSent then
        local msg = "|cFF00FF00[SF Druid]|r "
        if isFeral then
            print(msg .. L.bless_cat)
        elseif isBal then
            print(msg .. L.bless_bal)
        else
            print(msg .. L.bless_rest)
        end
        print(msg.."|cFFCCCCCCspec:|r " .. tostring(specSource) .. " (Feral=" .. tostring(pointsFeral) .. " Balance=" .. tostring(pointsBal) .. " Restoration=" .. tostring(pointsRest) .. ")")
        if AddonTable.ShowRacialInfo and not AddonTable.RacialGreetingSent then
            AddonTable.ShowRacialInfo()
            AddonTable.RacialGreetingSent = true
        end
        AddonTable.SpecMessageSent = true
    end

    if not env.hasActiveEnemy then
        -- Sem alvo: a rotação declarativa ainda roda (os self-buffs do prefixo comum
        -- não exigem inimigo). Só os nós com condição has_enemy/etc ficam de fora.
        if isFeral then
            if env.form == 2 then rotKey = "BEAR"
            elseif env.form == 1 then rotKey = "CAT"
            else rotKey = "SELF" end
        elseif isBal then
            rotKey = "BAL"
        else
            rotKey = "REST"
        end
        local SF = _G["SpellFlashForever"]
        if SF and type(SF.RunDeclaredRotation) == "function" then
            SF.RunDeclaredRotation(AddonTable, rotKey, env)
        end
        return
    end

    -- =====================================================
    -- CC / PvP (racial + trinket via core)
    -- =====================================================
    if env.isCCd then
        local racialId = AddonTable.ShouldUseRacial()
        if racialId then
            local racialName = SpellName(racialId)
            if racialName and SpellFlashAddon.Flashable(racialName) then
                SpellFlashAddon.FlashAction(racialName, "Aqua")
                return
            end
        end
        local trinketId = AddonTable.ShouldUseTrinket(true)
        if trinketId then
            local trinketName = type(trinketId) == "number" and select(1, C_Item.GetItemInfo(trinketId)) or nil
            if trinketName and SpellFlashAddon.Flashable(trinketName) then
                SpellFlashAddon.FlashAction(trinketName, "Aqua")
                return
            end
        end
        return
    end

    -- Interrupção de último recurso: racial (Pisada de Guerra) — inimigo conjurando
    -- e Bash (interrupt da classe) em CD/indisponível; alvo precisa estar perto
    local interruptUnavailable = false
    if SpellFlashAddon and type(SpellFlashAddon.SpellCooldown) == "function" then
        local cdLeft = SpellFlashAddon.SpellCooldown(5211)
        interruptUnavailable = (cdLeft and select(1, cdLeft) > 0) and true or false
    end
    local interruptRacial = AddonTable.ShouldUseRacial and AddonTable.ShouldUseRacial("interrupt", interruptUnavailable)
    if interruptRacial then
        local racialName = SpellName(interruptRacial)
        if racialName and SpellFlashAddon.Flashable(racialName) then
            SpellFlashAddon.FlashAction(racialName, "Aqua")
            return
        end
    end

    -- =====================================================
    -- ROTAÇÃO POR SPEC — via motor declarativo (editor /sf → Druid)
    -- CAT e BEAR compartilham a spec FERAL; despacha conforme a forma ATUAL.
    -- Em forma não-feral (caster/moonkin), despacha SELF (só os self-buffs —
    -- Mark of the Wild / Thorns — já está documentado no comentário do SELF).
    -- =====================================================
    local rotKey
    if isFeral then
        if env.form == 2 then rotKey = "BEAR"
        elseif env.form == 1 then rotKey = "CAT"
        else rotKey = "SELF" end
    elseif isBal then
        rotKey = "BAL"
    else
        rotKey = "REST"
    end
    local SF = _G["SpellFlashForever"]
    if SF and type(SF.RunDeclaredRotation) == "function" then
        if SF.RunDeclaredRotation(AddonTable, rotKey, env) then return end
    end
end

-- Diagnóstico de talentos: /sftrees — mostra o que o cliente devolve por árvore
SLASH_SFDRUIDTREES1 = "/sftreesd"
SlashCmdList["SFDRUIDTREES"] = function()
    local function P(m) DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[SF Druid Trees]|r " .. tostring(m)) end
    if not (C_ClassTalents and C_Traits) then P(L.dbg_traits_absent) return end
    local r = SpellFlashAddon.CountTalentTreePoints and SpellFlashAddon.CountTalentTreePoints(TREE_HINTS_DRUID)
    if not r then P(L.dbg_count_na) return end
    for i, name in ipairs(r.names or {}) do
        P(tostring(i) .. ": " .. tostring(name))
    end
    P("counts:", "Feral=" .. tostring(r.counts and r.counts.FERAL) .. " Bal=" .. tostring(r.counts and r.counts.BAL) .. " Rest=" .. tostring(r.counts and r.counts.REST))
end

