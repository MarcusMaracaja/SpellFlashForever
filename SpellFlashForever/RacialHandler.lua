-- SpellFlashForever / RacialHandler.lua
-- Sistema racial/trinket para TODAS as classes do Forever (detecção, situações de
-- CC/vida baixa/burst, sugestão de racial). Movido do SpellFlash_Hunter para o core.
local s = _G["SpellFlashForever"]
if not s then return end
local L = s.L
local Debug = false

local RacialData = {
    Human = {
        name = L.race_human,
        greeting = L.race_greet_human,
        activeRacial = { id = 59752, name = "Every Man for Himself", situations = { stun = true, burst = true, damageSpike = true } }
    },
    Dwarf = {
        name = L.race_dwarf,
        greeting = L.race_greet_dwarf,
        activeRacial = { id = 20594, name = "Stoneform", situations = { damageSpike = true, lowHp = true, burst = true } }
    },
    NightElf = {
        name = L.race_nightelf,
        greeting = L.race_greet_nightelf,
        activeRacial = { id = 20580, name = "Shadowmeld", situations = { dodgeOrReset = true, enemyCasting = true, lowHp = true } }
    },
    Gnome = {
        name = L.race_gnome,
        greeting = L.race_greet_gnome,
        activeRacial = { id = 20589, name = "Escape Artist", situations = { root = true, burst = true, dodgeOrReset = true } }
    },
    Orc = {
        name = L.race_orc,
        greeting = L.race_greet_orc,
        activeRacial = { id = 20572, name = "Blood Fury", situations = { burst = true } }
    },
    Undead = {
        name = L.race_undead,
        greeting = L.race_greet_undead,
        activeRacial = { id = 7744, name = "Will of the Forsaken", situations = { fear = true, charm = true, sleep = true } }
    },
    Tauren = {
        name = L.race_tauren,
        greeting = L.race_greet_tauren,
        activeRacial = { id = 20549, name = "War Stomp", situations = { multiTarget = true, enemyCasting = true, lowHp = true } }
    },
    Troll = {
        name = L.race_troll,
        greeting = L.race_greet_troll,
        -- Forever usa IDs vanilla: Berserking = 20554 (verificado em warcraftmaps "In the game files", 11/nov)
        activeRacial = { id = 20554, name = "Berserking", situations = { lowHp = true, burst = true } }
    },
    -- Skyborne — a nova raça do WoW Forever (duas variantes, uma por facção):
    --   High Order (Alliance, CléRACE 95): Read Ley Line (1259705) — +100% regen HP/Mana por 30s
    --   Windshaper (Horde, CléRace 96):   Skysight (1259686) — +10% movement/mounted speed por 30s
    --   Walk on Air (Both, 1259416) — ambos ganham glide de 10 s (situational, não incluído por padrão)
    HighOrderSkyborne = {
        name = L.race_highorder,
        greeting = L.race_greet_highorder,
        activeRacial = { id = 1259705, name = "Read Ley Line", situations = { lowHp = true, burst = true, damageSpike = true } }
    },
    WindshaperSkyborne = {
        name = L.race_windshaper,
        greeting = L.race_greet_windshaper,
        activeRacial = { id = 1259686, name = "Skysight", situations = { dodgeOrReset = true, damageSpike = true, burst = true, dodgeOrReset = true } }
    },
}

local playerRace, playerRacial, playerRaceName

-- Normaliza um nome de raça (remove acentos, junta palavras) para casamento robusto.
local function NormalizeRaceName(s)
    if type(s) ~= "string" then return "" end
    local t = s:lower()
    t = t:gsub("á", "a"):gsub("à", "a"):gsub("â", "a"):gsub("ã", "a"):gsub("ä", "a")
    t = t:gsub("é", "e"):gsub("è", "e"):gsub("ê", "e"):gsub("ë", "e")
    t = t:gsub("í", "i"):gsub("ì", "i"):gsub("î", "i"):gsub("ï", "i")
    t = t:gsub("ó", "o"):gsub("ò", "o"):gsub("ô", "o"):gsub("õ", "o"):gsub("ö", "o")
    t = t:gsub("ú", "u"):gsub("ù", "u"):gsub("û", "u"):gsub("ü", "u")
    t = t:gsub("ç", "c"):gsub("ñ", "n")
    return (t:gsub("%s+", ""))
end

-- Construído a partir de RacialData + aliases ptBR (nome de exibição)
local RACE_INDEX = {}
for raceEn, _ in pairs(RacialData) do
    RACE_INDEX[NormalizeRaceName(raceEn)] = raceEn
end
-- Aliases: nome localizado do cliente → chave interna
local RACE_ALIASES = {
    scourge = "Undead", mortovivos = "Undead", mortovivo = "Undead", morto = "Undead", undead = "Undead", ["morto-vivo"] = "Undead",
    humano = "Human", human = "Human",
    anao = "Dwarf", dwarf = "Dwarf",
    elfonoturno = "NightElf", nightelf = "NightElf",
    gnome = "Gnome",
    orc = "Orc",
    tauren = "Tauren",
    troll = "Troll",
    -- Skyborne (nova raça do WoW Forever; duas variantes, uma por facção).
    -- UnitRace("player") devolve (nome localizado, token/raceID).
    highorderskyborne = "HighOrderSkyborne", highorder = "HighOrderSkyborne",
    skybornealliance = "HighOrderSkyborne",
    windshaperskyborne = "WindshaperSkyborne", windshaper = "WindshaperSkyborne",
    skybornehorde = "WindshaperSkyborne",
}

local function DetectPlayerRace()
    local okR, _, raceFileStr = pcall(UnitRace, "player")
    if not okR or type(raceFileStr) ~= "string" then
        raceFileStr = "Unknown"
    end
    local key = NormalizeRaceName(raceFileStr)
    local raceKey = RACE_INDEX[key] or RACE_ALIASES[key]
    if raceKey then
        local data = RacialData[raceKey]
        playerRace = raceKey
        playerRacial = data.activeRacial
        playerRaceName = data.name
        print(string.format("|cFF00FF00[SpellFlashForever]|r %s", data.greeting))
        return
    end
    playerRace = "Unknown"
    playerRacial = nil
    print(string.format(L.race_unmapped, raceFileStr))
end

DetectPlayerRace()

-- Saudação uma vez por sessão: PLAYER_ENTERING_WORLD dispara no login real E
-- no /reload (PLAYER_LOGIN não dispara em /reload). Trava `greeted` garante
-- uma única impressão por sessão de Lua (a cada zone-in subsequente não repete).
-- O print no load (linha ~120) fica como alternativa adicional.
local greetFrame = CreateFrame("Frame")
greetFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
greetFrame:RegisterEvent("PLAYER_LOGIN")
greetFrame:SetScript("OnEvent", function(self, event)
    if self.greeted then return end
    if playerRace and RacialData[playerRace] then
        print(string.format("|cFF00FF00[SpellFlashForever]|r %s", RacialData[playerRace].greeting))
        self.greeted = true
    end
end)

-- Lê os debuffs do jogador via C_UnitAuras (API moderna). Devolve lista de
-- nomes; em contextos ilegíveis (secret em combate) devolve {} e false.
local function PlayerDebuffNames()
    if not (C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function") then
        return {}, false
    end
    local names = {}
    for i = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HARMFUL")
        if not ok or not aura then break end
        if _G.issecretvalue and issecretvalue(aura.name) then
            return names, false
        end
        names[#names + 1] = aura.name
    end
    return names, true
end

local function PlayerHasDebuffMatching(patterns)
    local names, readable = PlayerDebuffNames()
    if not readable then return false end
    for _, name in ipairs(names) do
        local lowerName = string.lower(name)
        for _, pat in ipairs(patterns) do
            if string.find(lowerName, string.lower(pat), 1, true) then
                return true, name
            end
        end
    end
    return false
end


local function IsFeared()
    return not not PlayerHasDebuffMatching({"Fear", "Medo", "Psychic Scream", "Grito Psíquico", "Intimidating Shout", "Brado Intimidador", "Howl of Terror", "Uivo de Terror", "Seduction", "Sedução"})
end

local function IsStunned()
    local names, readable = PlayerDebuffNames()
    if not readable then return false end
    -- Sap nunca é stun removível por raciais
    for _, name in ipairs(names) do
        if name == "Sap" or name == "Golpe de Matraca" then return false end
    end
    return not not PlayerHasDebuffMatching({ "Stun", "Atordoar", "Hammer of Justice", "Martelo da Justiça", "Bash", "Intimidation", "Kidney Shot", "Golpe no Rim", "Pounce", "Surra", "Concussion Blow", "Murro" })
end

local function IsCharmed()
    -- Sem leitura confiável de sourceUnit: qualquer charme no jogador conta
    -- (não dá para excluir charme próprio com a API moderna neste cliente).
    return not not PlayerHasDebuffMatching({"Charm", "Encantamento", "Mind Control", "Controle Mental", "Dominate", "Dominar", "Seduction"})
end

local function IsSleeping()
    return not not PlayerHasDebuffMatching({"Sleep", "Sono", "Hibernation", "Hibernar", "Wyvern Sting", "Picada de Mantícora", "Slumber", "Adormecer"})
end

local function IsRooted()
    return not not PlayerHasDebuffMatching({"Root", "Raíz", "Enraizar", "Frost Nova", "Nova de Gelo", "Entangling Roots", "Raízes Enredadeiras", "Earthbind", "Ligação Terrena", "Freeze", "Congelar"})
end

local function IsRemovableCC()
    return IsStunned() or IsFeared() or IsCharmed() or IsSleeping() or IsRooted()
end

-- GetHealthPercent é fornecido pelo core (SpellFlashAddon.HealthPercent, secret-safe) — H-0083
local GetHealthPercent = SpellFlashAddon.HealthPercent

-- IsEnemyCasting é fornecido pelo core (SpellFlashAddon.IsTargetInterruptibleCasting) — H-0083
local IsEnemyCasting = SpellFlashAddon.IsTargetInterruptibleCasting

-- Cooldown restante em segundos (0 se pode usar). NUNCA confiar em valores secret;
-- qualquer falha vira 0 (fail-open: considera pronto).
local function RacialCooldownRemaining(spellId)
    if not (C_Spell and type(C_Spell.GetSpellCooldown) == "function") then return 0 end
    local ok, info = pcall(C_Spell.GetSpellCooldown, spellId)
    if not ok or type(info) ~= "table" then return 0 end
    local okAll, result = pcall(function()
        local function numOrNil(v)
            if _G.issecretvalue and issecretvalue(v) then return nil end
            return tonumber(v)
        end
        -- timeUntilEndOfStartRecovery é o campo-canônico neste cliente
        local direct = numOrNil(info.timeUntilEndOfStartRecovery)
        if direct and direct > 0 then return direct end
        -- Fallback com startTime/duration
        local startT = numOrNil(info.startTime) or 0
        local dur = numOrNil(info.duration) or 0
        local ready = (GetTime and GetTime() or 0)
        local remain = startT + dur - ready
        if remain > 0 then return remain end
        -- isActive=true (sem tempo confiável): bloqueia com estimativa conservadora
        if info.isActive == true then return 5 end
        return 0
    end)
    if okAll and type(result) == "number" then return result end
    return 0
end

-- O jogador conhece o racial? (raciais geralmente NÃO aparecem no livro de
-- feitiços do vanilla/Forever — IsSpellKnown!=true NÃO pode ser decisivo;
-- tratar o "não" como fail-open, senão o racial nunca é recomendado)
local function SpellKnown(spellId)
    if C_SpellBook and type(C_SpellBook.IsSpellKnown) == "function" then
        local ok, known = pcall(C_SpellBook.IsSpellKnown, spellId)
        if ok and known == true then return true end
    end
    -- Fallback: informação existe nesse cliente
    if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellId)
        if ok and info ~= nil then return true end
    end
    return true -- fail-open: deixar recomendar (cliente-friendly)
end

function s.ShouldUseRacial()
    if not playerRacial or not playerRacial.id then return nil end
    local spellId = playerRacial.id
    local spellName = (s.SpellName and s.SpellName(spellId)) or tostring(spellId)
    -- Conhecimento do livro
    if not SpellKnown(spellId) then return nil end
    -- Cooldown
    if RacialCooldownRemaining(spellId) > 0 then return nil end
    -- Usabilidade: só o false booleano EXPLÍCITO bloqueia; nil (cliente-friendly) deixa passar
    if C_Spell and type(C_Spell.IsSpellUsable) == "function" then
        local ok, usable = pcall(C_Spell.IsSpellUsable, spellId)
        if ok and usable == false then return nil end
    elseif type(IsUsableSpell) == "function" then
        local ok, usable = pcall(IsUsableSpell, spellName)
        if ok and usable == false then return nil end
    end
    local situations = playerRacial.situations
    if situations.stun and IsStunned() then return spellId end
    if situations.fear and IsFeared() then return spellId end
    if situations.charm and IsCharmed() then return spellId end
    if situations.sleep and IsSleeping() then return spellId end
    if situations.root and IsRooted() then return spellId end
    local hp = GetHealthPercent("player")
    if situations.lowHp and hp < 35 then return spellId end
    if situations.damageSpike and hp < 60 then return spellId end
    if situations.burst and type(UnitAffectingCombat) == "function" and UnitAffectingCombat("player") then
        if UnitExists("target") then
            local okCUA, canAttack = pcall(UnitCanAttack, "player", "target")
            if okCUA and canAttack then
                if GetHealthPercent("target") > 20 then return spellId end
            end
        end
    end
    if situations.castInterrupt and IsEnemyCasting("target") then
        if playerRace == "BloodElf" then
            -- Arcane Torrent só funciona em melee (8yd radius)
            if s.SafeInteractDistance and s.SafeInteractDistance("target", 3) then return spellId end
        else
            return spellId
        end
    end
    if situations.dodgeOrReset and hp < 40 then return spellId end
    return nil
end

local TrinketIds = { 19506, 20166, 42292, 42300, 42293, 42301 }
function s.ShouldUseTrinket(forceIfNoRacial)
    if not forceIfNoRacial and s.ShouldUseRacial() then return nil end
    if not IsRemovableCC() then return nil end
    for _, itemId in ipairs(TrinketIds) do
        local itemName = nil
        if C_Item and type(C_Item.GetItemInfo) == "function" then
            local ok, name = pcall(C_Item.GetItemInfo, itemId)
            if ok then itemName = name end
        end
        if not itemName and type(GetItemInfo) == "function" then
            local ok, name = pcall(GetItemInfo, itemId)
            if ok then itemName = name end
        end
        if itemName then
            local usable = true
            if type(IsUsableItem) == "function" then
                local ok, u = pcall(IsUsableItem, itemId)
                if ok and not u then usable = false end
            end
            if usable then
                local ready = true
                if C_Item and type(C_Item.GetItemCooldown) == "function" then
                    local ok, start, duration = pcall(C_Item.GetItemCooldown, itemId)
                    if ok and type(start) == "number" and start > 0 and (start + (duration or 0)) > (GetTime and GetTime() or 0) then
                        ready = false
                    end
                elseif type(GetItemCooldown) == "function" then
                    local ok, start, duration = pcall(GetItemCooldown, itemId)
                    if ok and type(start) == "number" and start > 0 and (start + (duration or 0)) > (GetTime and GetTime() or 0) then
                        ready = false
                    end
                end
                if ready then return itemId end
            end
        end
    end
    return nil
end

function s.GetDetectedRace()
    return playerRace, playerRaceName, playerRacial
end

function s.ShowRacialInfo()
    local data = RacialData[playerRace]
    if data then print(string.format("|cFF00FF00[SpellFlashForever]|r %s", data.greeting)) end
end

-- Diagnóstico: /sfdracial — despeja cada gate do ShouldUseRacial() p/ depuração
-- (não altera nada; só lê). Use com um alvo escolhido, em combate e fora.
local function safeS(v)
    if _G.issecretvalue and issecretvalue(v) then return "<secret>" end
    return tostring(v)
end

SLASH_SFDRACIAL1 = "/sfdracial"
SlashCmdList["SFDRACIAL"] = function()
    local function P(m) DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[SF Racial]|r " .. tostring(m)) end
    P(string.format(L.drc_race, safeS(playerRace), safeS(playerRacial and playerRacial.id), safeS(playerRacial and playerRacial.name)))
    if playerRacial and playerRacial.id then
        local spellId = playerRacial.id
        if C_SpellBook and type(C_SpellBook.IsSpellKnown) == "function" then
            local ok, known = pcall(C_SpellBook.IsSpellKnown, spellId)
            P(string.format(L.drc_known_ok, tostring(ok), safeS(known)))
        else
            P(L.drc_known_absent)
        end
        if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
            local ok, info = pcall(C_Spell.GetSpellInfo, spellId)
            P(string.format(L.drc_info, tostring(ok), safeS(ok and info and info.name)))
        end
        if C_Spell and type(C_Spell.GetSpellCooldown) == "function" then
            local ok, cd = pcall(C_Spell.GetSpellCooldown, spellId)
            if ok and type(cd) == "table" then
                for k, v in pairs(cd) do P(string.format(L.drc_cooldown_table, safeS(k), safeS(v))) end
            else
                P(string.format(L.drc_cooldown_ok, tostring(ok)))
            end
        end
        if C_Spell and type(C_Spell.IsSpellUsable) == "function" then
            local ok, usable, power = pcall(C_Spell.IsSpellUsable, spellId)
            P(string.format(L.drc_usable, tostring(ok), safeS(usable), safeS(power)))
        end
        P(string.format(L.drc_spellknown, tostring(SpellKnown(spellId))))
        P(string.format(L.drc_cooldown_remaining, tostring(RacialCooldownRemaining(spellId))))
        P(string.format(L.drc_incombat, tostring(UnitAffectingCombat and UnitAffectingCombat("player"))))
        if UnitExists("target") then
            local okCUA, canAttack = pcall(UnitCanAttack, "player", "target")
            P(string.format(L.drc_canattack, tostring(okCUA), safeS(canAttack)))
        else
            P(L.drc_no_target)
        end
        P(string.format(L.drc_should, safeS(s.ShouldUseRacial())))
    end
end