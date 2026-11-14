local AddonName, AddonTable = ...

local TREE_HINTS_HUNTER = {
    BM = { "beast", "feras", "fera", "besta" },
    MM = { "marksman", "precis", "tirador", "sniper" },
    SV = { "surviv", "sobreviv" },
}
-- Expose o módulo pro SpellFlashForever (core) para consultas (/sf status → GetDetectedRace)
_G.SpellFlash_Hunter = AddonTable

local InCombat = SpellFlashAddon.InCombat

-- Middle-man e Utilitários Compartilhados (Fallback)
if not AddonTable.ShouldUseRacial then AddonTable.ShouldUseRacial = function() return nil end end

-- Nome + cache localizado vive em Localization.lua (AddonTable.SpellName)

AddonTable.CheckCastable = function(English_Spell_Name, ...)
    if type(AddonTable.Castable) == "table" and type(AddonTable.Castable[English_Spell_Name]) == "function" then
        return AddonTable.Castable[English_Spell_Name](...)
    end
    return false
end

AddonTable.FlashCooldown = 0.2
AddonTable.FlashCD = {}

AddonTable.RawFlash = function(SpellName, color)
    if AddonTable.TickFlashUsed then return false end
    local now = GetTime()
    if AddonTable.FlashCD[SpellName] and now - AddonTable.FlashCD[SpellName] < AddonTable.FlashCooldown then
        return false
    end
    AddonTable.TickFlashUsed = true
    AddonTable.FlashCD[SpellName] = now
    SpellFlashAddon.FlashAction(SpellName, color)
    return true
end

AddonTable.TryFlash = function(spellID, color, condition, englishName)
    if AddonTable.TickFlashUsed then return false end
    if AddonTable.IsPressSuppressed(AddonTable.SpellName(spellID)) then return false end
    if condition() and SpellFlashAddon.Flashable(AddonTable.SpellName(spellID)) and AddonTable.CheckCastable(englishName) then
        return AddonTable.RawFlash(AddonTable.SpellName(spellID), color)
    end
    return false
end

-- ======== Apagamento imediato ao USAR (pressionar botão/tecla) ========
-- Em 3.3.5, mouse E tecla (binding) disparam o Click protegido do botão
-- de ação. Ao detectar o uso, suprime o flash daquela spell por um curto
-- intervalo, forçando o apagamento sem esperar o evento de cast.
AddonTable.PressSuppress = {}

AddonTable.ButtonsHooked = nil

AddonTable.OnSpinPressed = function(button)
    if not button then return end
    local action
    if button.GetAttribute then
        action = button:GetAttribute("action")
    end
    if not action then return end
    local actionType, id = GetActionInfo(tonumber(action) or action)
    if actionType == "spell" and id and id ~= "" then
        AddonTable.PressSuppress[id] = GetTime() + 0.6
    end
end

AddonTable.IsPressSuppressed = function(SpellName)
    if not SpellName or SpellName == "" then return false end
    local untilTime = AddonTable.PressSuppress[SpellName]
    return not not (untilTime and GetTime() < untilTime)
end

AddonTable.HookActionButtonPress = function()
    if AddonTable.ButtonsHooked then return end
    AddonTable.ButtonsHooked = true
    local ok, err = pcall(function()
        if type(SecureActionButton_OnClick) == "function" then
            hooksecurefunc("SecureActionButton_OnClick", function(self)
                pcall(AddonTable.OnSpinPressed, self)
            end)
        else
            local prefixes = { "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton", "MultiBarLeftButton", "PetActionButton", "StanceButton" }
            for p = 1, #prefixes do
                for i = 1, 12 do
                    local btn = _G[prefixes[p] .. i]
                    if btn and not btn.SpellFlashPressHooked then
                        btn.SpellFlashPressHooked = true
                        hooksecurefunc(btn, "Click", function(self)
                            pcall(AddonTable.OnSpinPressed, self)
                        end)
                    end
                end
            end
        end
    end)
    if not ok then
        AddonTable.ButtonsHooked = nil
    end
end

-- Verifica se o jogador está sob efeito de veneno
local function IsPoisoned()
    if not (C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function") then
        return false
    end
    for i = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HARMFUL")
        if not ok or not aura then return false end
        if _G.issecretvalue and issecretvalue(aura.dispelName) then break end
        if (aura.dispelName == "Poison" or aura.dispelName == "Veneno") then
            return true
        end
    end
    return false
end


-- =====================================================
-- RASTREADOR DE ALVOS (simplificado)
-- NOTA: COMBAT_LOG_EVENT_UNFILTERED é proibido neste cliente (ADDON FORBIDDEN),
-- então não dá para contar inimigos interagindo com o grupo. O rastreamento
-- usa o alvo atual como aproximação (mesmo comportamento da correção H-0014).
-- =====================================================
local activeEnemies = {}

-- Frame para escutar eventos de combate
local trackerFrame = CreateFrame("Frame")
trackerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
trackerFrame:RegisterEvent("UNIT_PET")
trackerFrame:RegisterEvent("UNIT_DIED")
trackerFrame:RegisterEvent("UI_ERROR_MESSAGE")
trackerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
trackerFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
trackerFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

-- Atualiza o estado de morte do pet (usado para distinguir "pet morto sem corpo"
-- de "pet dispensado/estábulo", onde Revive Pet é o correto ao invés de Call Pet)
local function UpdatePetState()
    local ok, exists = pcall(UnitExists, "pet")
    local ok2, dead = pcall(UnitIsDeadOrGhost, "pet")
    AddonTable.PetIsDead = ok and exists and ok2 and dead or false
end

-- =====================================================
-- CRENÇA: Marca do Caçador (spell 1130) aplicada por nós
-- Em combate as auras do alvo são secret neste cliente → não dá para
-- confirmar a marca pela API. Rastreamos NOSSO cast (filtro "player" do
-- RegisterUnitEvent) e guardamos a crença por alvo (slot incrementa a cada
-- troca de alvo: alvo novo = marca desconhecida).
-- =====================================================
local markBeliefSlot = 0
AddonTable.MarkBelief = AddonTable.MarkBelief or { slot = 0, active = false }

local function IsMarkedByUs()
    return AddonTable.MarkBelief.active and AddonTable.MarkBelief.slot == markBeliefSlot
end

-- Crença de aspectos: auras são secret em combate, então rastreamos NOSSO
-- último aspecto (filtro "player"). É um aspecto por vez (regra do cliente).
local ASPECT_BASE_NAMES = nil
local function AspectBaseName(n)
    if type(n) ~= "string" then return "" end
    return n:gsub("%s*%b()%s*$", ""):lower()
end
local function IsAspectName(name)
    if not ASPECT_BASE_NAMES then
        ASPECT_BASE_NAMES = {}
        -- ids de aspectos conhecidos (montanha-russa de ranks é por nome)
        local ids = { 5118, 13159, 13161, 13163, 13165, 20043, 34074, 61846 } -- Cheetah, Pack, Beast, Monkey, Hawk, Wild, Viper, Dragonhawk
        for _, id in ipairs(ids) do
            local base = AspectBaseName(AddonTable.SpellName(id))
            if base ~= "" then ASPECT_BASE_NAMES[base] = true end
        end
    end
    return ASPECT_BASE_NAMES[AspectBaseName(name)] == true
end

-- Crença: Serpent Sting (spell 1978) aplicada por nós no alvo atual.
-- Em combate as auras do alvo são secret → lemos nosso cast (filtro "player")
-- e o vinculamos ao alvo/slot atual; expira sozinho após 15 s.
AddonTable.SerpentStingBelief = AddonTable.SerpentStingBelief or { slot = 0, applied = false, expires = 0 }

-- Crença: Wing Clip (spell 2974) nós aplicamos no alvo atual.
-- Mesmo padrão da Serpent/Marca; Wing Clip snarea por ~12 s.
local WING_CLIP_SNARE_DURATION = 12
AddonTable.WingClipBelief = AddonTable.WingClipBelief or { slot = 0, applied = false, expires = 0 }

-- Verifica se o wing clip está ativo no alvo atual (crença > reserva legível).
function AddonTable.IsWingClipActive(unit)
    unit = unit or "target"
    if unit ~= "target" then
        return SpellFlashAddon.CheckDebuff(AddonTable.SpellName(2974), unit)
    end
    local b = AddonTable.WingClipBelief
    if b and b.applied and b.slot == markBeliefSlot then
        if type(GetTime) == "function" and GetTime() < b.expires then
            return true
        end
        b.applied = false -- expirou
    end
    -- fallback: tenta ler a aura (funciona fora de combate)
    return SpellFlashAddon.CheckDebuff(AddonTable.SpellName(2974), unit)
end

-- Verifica se o serpent sting está ativo no alvo atual (crença > reserva legível).
function AddonTable.IsSerpentStingActive(unit)
    unit = unit or "target"
    if unit ~= "target" then
        return SpellFlashAddon.CheckDebuff(AddonTable.SpellName(1978), unit, true)
    end
    local b = AddonTable.SerpentStingBelief
    if b and b.applied and b.slot == markBeliefSlot then
        if type(GetTime) == "function" and GetTime() < b.expires then
            return true
        end
        b.applied = false -- expirou
    end
    -- fallback: tenta ler a aura (funciona fora de combate)
    return SpellFlashAddon.CheckDebuff(AddonTable.SpellName(1978), unit, true)
end

trackerFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        -- Alvo novo: a marca dele é desconhecida; serpent sting e wing clip idem
        markBeliefSlot = markBeliefSlot + 1
        if AddonTable.SerpentStingBelief then
            AddonTable.SerpentStingBelief.applied = false
        end
        if AddonTable.WingClipBelief then
            AddonTable.WingClipBelief.applied = false
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- Assinatura neste cliente: (unit, castGUID, spellID), filtro "player"
        local _, _, spellID = ...
        if type(spellID) == "number" and C_Spell and type(C_Spell.GetSpellInfo) == "function" then
            local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
            local castName = ok and info and info.name
            local markName = AddonTable.SpellName(1130)
            if castName and markName then
                if AspectBaseName(castName) == AspectBaseName(markName) then
                    AddonTable.MarkBelief.active = true
                    AddonTable.MarkBelief.slot = markBeliefSlot
                end
            end
            -- Registro do último aspecto nosso (crença para as auras secret)
            if castName and IsAspectName(castName) then
                AddonTable.AspectBelief = AddonTable.AspectBelief or {}
                AddonTable.AspectBelief.active = true
                AddonTable.AspectBelief.name = AspectBaseName(castName)
            end
            -- Registro do Wing Clip aplicado no alvo atual (crença secreta)
            local wingName = AddonTable.SpellName(2974)
            if castName and wingName and AspectBaseName(castName) == AspectBaseName(wingName) then
                AddonTable.WingClipBelief.applied = true
                AddonTable.WingClipBelief.slot = markBeliefSlot
                AddonTable.WingClipBelief.expires = (type(GetTime) == "function" and GetTime() or 0) + WING_CLIP_SNARE_DURATION
            end
            -- Registro do Serpent Sting aplicado no alvo atual (crença secreta)
            local stingName = AddonTable.SpellName(1978)
            if castName and stingName and AspectBaseName(castName) == AspectBaseName(stingName) then
                AddonTable.SerpentStingBelief.applied = true
                AddonTable.SerpentStingBelief.slot = markBeliefSlot
                AddonTable.SerpentStingBelief.expires = (type(GetTime) == "function" and GetTime() or 0) + 15
            end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Zera o combate ao sair de combate
        for k in pairs(activeEnemies) do
            activeEnemies[k] = nil
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Nova sessão: crença de aspectos/serpent sting/marca/wing clip desconhecidas
        AddonTable.AspectBelief = nil
        AddonTable.SerpentStingBelief = { slot = markBeliefSlot, applied = false, expires = 0 }
        AddonTable.WingClipBelief = { slot = markBeliefSlot, applied = false, expires = 0 }
        if AddonTable.MarkBelief then
            AddonTable.MarkBelief.active = false
        end
        UpdatePetState()
    elseif event == "UNIT_PET" then
        local unit = ...
        -- O argumento pode vir "secret string" (taint do cliente Forever): nunca comparar
        -- diretamente — UnitIsUnit() dentro de um pcall é seguro.
        if type(unit) == "string" then
            local ok, same = pcall(UnitIsUnit, unit, "player")
            if ok and same then
                UpdatePetState()
            end
        end
    elseif event == "UNIT_DIED" then
        -- O pet morreu (mesmo que o corpo desapareça depois, continuamos sabendo)
        local unit = ...
        -- Linha 291 era `unit == "pet"` -> erro "attempt to compare local 'unit' (a secret
        -- string value)". Blindar com pcall + UnitIsUnit como no UNIT_PET acima.
        if type(unit) == "string" then
            local ok, same = pcall(UnitIsUnit, unit, "pet")
            if ok and same then
                AddonTable.PetIsDead = true
            end
        end
    elseif event == "UI_ERROR_MESSAGE" then
        -- Backup: "Your pet is dead" / "Seu ajudante está morto" ao tentar Call Pet
        local message = tostring(... or ""):lower()
        if (message:find("pet") and message:find("dead")) or (message:find("ajudante") and (message:find("mort") or message:find("morreu"))) then
            AddonTable.PetIsDead = true
        end
    end
end)

local function GetAoECount()
    if _G.MaxDps and type(_G.MaxDps.SmartAoe) == "function" then
        return _G.MaxDps:SmartAoe() or 1
    end
    
    local now = GetTime()
    local count = 0
    for guid, timestamp in pairs(activeEnemies) do
        if now - timestamp <= 6 then
            count = count + 1
        else
            activeEnemies[guid] = nil -- Pruning automático de mobs que saíram de combate/distância
        end
    end
    
    -- Fallback de segurança: Garante que se você tiver um alvo inimigo ativo em combate,
    -- a contagem nunca seja zero.
    if count == 0 and UnitExists("target") and UnitCanAttack("player", "target") and InCombat() then
        count = 1
    end
    
    return count
end

-- Verifica se qualquer membro do grupo ou raide está em combate
local function IsGroupInCombat()
    if UnitAffectingCombat("player") or UnitAffectingCombat("pet") then return true end
    
    local numParty = AddonTable.GetNumPartyMembers()
    if numParty > 0 then
        for i = 1, numParty do
            if UnitAffectingCombat("party"..i) or UnitAffectingCombat("partypet"..i) then
                return true
            end
        end
    end
    
    local numRaid = AddonTable.GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            if UnitAffectingCombat("raid"..i) or UnitAffectingCombat("raidpet"..i) then
                return true
            end
        end
    end
    
    return false
end

SpellFlashAddon.Spam[AddonName] = function(NoCC, ActiveEnemy, PetAlive, PetActiveEnemy, instanceType, PetNoCC)
    -- Só executa se o jogador for um Caçador
    local _, myClass = UnitClass("player")
    if myClass ~= "HUNTER" then return end
    -- Compat: o driver do SpellFlashForever passa a tabela de variáveis como
    -- primeiro argumento (mesmo contrato do RunSpam do WotLK, que chamava v(x)).
    if type(NoCC) == "table" then
        local t = NoCC
        NoCC = t.NoCC
        ActiveEnemy = t.ActiveEnemy
        PetAlive = t.PetAlive
        PetActiveEnemy = t.PetActiveEnemy
        instanceType = t.InstanceType
        PetNoCC = t.PetNoCC
    end
    AddonTable.TickFlashUsed = nil
    pcall(AddonTable.HookActionButtonPress)
    if IsMounted() then return end
    
    -- Se estiver castando ou canalizando (Montar, Volley, etc), não recomenda nada para não interromper
    if type(UnitCastingInfo) == "function" then
        local okCast, name = pcall(UnitCastingInfo, "player")
        if okCast and name then return end
    end
    if type(UnitChannelInfo) == "function" then
        local okChan, name = pcall(UnitChannelInfo, "player")
        if okChan and name then return end
    end

    -- Cálculos de Distância robustos (API moderna + sonda por slot)
    local wingClipName = AddonTable.SpellName(2974)
    local mongooseName = AddonTable.SpellName(1495)
    local autoShotName = AddonTable.SpellName(75)

    -- Distância REAL ao alvo (jardas, via UnitDistanceSquared) — quando disponível,
    -- ela vence qualquer sondagem por slot. Sem alvo, distancia = nil.
    local targetDistance = AddonTable.TargetDistance and AddonTable.TargetDistance("target") or nil

    local isMelee = false
    -- Prioridade 1: distância medida na fita (yards <= 10 ≈ melee + zona morta)
    if targetDistance ~= nil then
        isMelee = targetDistance <= 10
    else
        -- Fallback: slot de "Atacar"/"Tiro Automático" (o caminho validado)
        local meleeRange = AddonTable.IsInMeleeRange and AddonTable.IsInMeleeRange("target")
        if meleeRange == nil then
            if wingClipName and SpellFlashAddon.IsSpellKnown(wingClipName) then
                meleeRange = SpellFlashAddon.IsSpellInRange(wingClipName, "target") == 1
            elseif mongooseName and SpellFlashAddon.IsSpellKnown(mongooseName) then
                meleeRange = SpellFlashAddon.IsSpellInRange(mongooseName, "target") == 1
            else
                meleeRange = AddonTable.SafeInteractDistance("target", 3)
            end
        end
        isMelee = meleeRange and true or false
    end

    local inAutoShotRange = autoShotName and SpellFlashAddon.IsSpellInRange(autoShotName, "target") == 1
    local dist = targetDistance or ((isMelee and 5) or (AddonTable.SafeInteractDistance("target", 3) and 15) or (inAutoShotRange and 35) or 100)

    local env = {
        myHP = SpellFlashAddon.HealthPercent("player") or 100,
        targetHP = SpellFlashAddon.HealthPercent("target") or 100,
        manaPct = SpellFlashAddon.PowerPercent("player", 0) or 0,
        isPvP = (function()
            if not (type(UnitIsPlayer) == "function" and UnitIsPlayer("target")) then return false end
            local okCUA, canAttack = pcall(UnitCanAttack, "player", "target")
            if not okCUA or (_G.issecretvalue and issecretvalue(canAttack)) then return false end
            return canAttack and true or false
        end)(),
        isBoss = string.find(string.lower(UnitClassification("target") or ""), "boss"),
        hasActiveEnemy = (function()
            -- Alvo morto/fantasma nunca é inimigo ativo; UnitCanAttack ilegível
            -- (secret/tainted) é tratado como atacável (não bloqueia a rotação).
            if not UnitExists("target") then return false end
            local okD, dead = pcall(UnitIsDeadOrGhost, "target")
            if okD and dead then return false end
            local okCA, canAttack = pcall(UnitCanAttack, "player", "target")
            if not okCA or (_G.issecretvalue and issecretvalue(canAttack)) then return true end
            return canAttack and true or false
        end)() or ActiveEnemy,
        isMelee = isMelee,
        -- tooCloseForRanged: alvo na zona morta/melee (0-10 jardas), preferindo distância medida
        tooCloseForRanged = (targetDistance ~= nil)
            and (targetDistance <= 10)
            or (UnitExists("target") and not inAutoShotRange and dist < 15),
        petAlive = UnitExists("pet") and not UnitIsDeadOrGhost("pet"),
        targetDistance = dist,
        isAoE = GetAoECount() >= 2
    }

    -- PRIORIDADE 0: Sobrevivência Global (Poções)
    -- (Cooldowns de consumível ficam por conta da rotação da spec / do KeyButton)
    if SpellFlashAddon.CheckGlobalPotions and SpellFlashAddon.CheckGlobalPotions() then return end

    -- =====================================================
    -- DETECÇÃO DE SPEC
    -- Ordem: 1) override manual (/sf > Hunter) → 2) spells assinatura (Counterattack=SV,
    -- Bestial Wrath=BM, Sniper Shot=MM) — pois names de árvore não existem no client;
    -- 3) pontos por árvore via C_Traits (desempate); 4) override else padrão SV.
    -- =====================================================
    local override = SpellFlashAddon.GetModuleConfig and SpellFlashAddon.GetModuleConfig("SpellFlash_Hunter", "spec_override") or nil

    -- Varredura de talentos (uma vez por sessão) via core (CountTalentTreePoints):
    -- soma pontos por árvore do Hunter; a árvore com MAIS PONTOS vence; empate → SV.
    if AddonTable.TalentCountCache == nil then
        AddonTable.TalentCountCache = false
        AddonTable.TalentCountCache = SpellFlashAddon.CountTalentTreePoints and SpellFlashAddon.CountTalentTreePoints(TREE_HINTS_HUNTER, { "SV", "MM", "BM" }) or false
    end

    local counts = type(AddonTable.TalentCountCache) == "table" and AddonTable.TalentCountCache.counts or nil
    local pointsBM, pointsMM, pointsSV = 0, 0, 0
    if counts then
        pointsBM, pointsMM, pointsSV = tonumber(counts.BM) or 0, tonumber(counts.MM) or 0, tonumber(counts.SV) or 0
    end

    local bestTree = nil
    if pointsBM > pointsMM and pointsBM > pointsSV then
        bestTree = "BM"
    elseif pointsMM > pointsBM and pointsMM > pointsSV then
        bestTree = "MM"
    elseif pointsBM > 0 or pointsMM > 0 or pointsSV > 0 then
        bestTree = "SV" -- empate/híbrido: SV (spec do usuário)
    end

    local specName, specID = nil, nil
    if C_SpecializationInfo and type(C_SpecializationInfo.GetSpecialization) == "function" then
        local okSpec, spec = pcall(C_SpecializationInfo.GetSpecialization)
        if okSpec and type(spec) == "number" and type(C_SpecializationInfo.GetSpecializationInfo) == "function" then
            local okInfo, id, name = pcall(C_SpecializationInfo.GetSpecializationInfo, spec)
            if okInfo then specID, specName = id, name end
        end
    end

    -- O Forever não devolve nomes de árvore (C_Traits.GetTreeInfo → "(sem nome)"),
    -- então o desempate sozinho não distingue. Combinamos com spells assinatura:
    -- Counterattack (SV) / Bestial Wrath (BM) / Sniper Shot (MM — ID Forever 1310786).
    local isBM, isMM, isSV, specSource
    if override == "BM" then isBM, isMM, isSV, specSource = true, false, false, "override"
    elseif override == "MM" then isBM, isMM, isSV, specSource = false, true, false, "override"
    elseif override == "SV" then isBM, isMM, isSV, specSource = false, false, true, "override"
    elseif bestTree == "BM" then isBM, isMM, isSV, specSource = true, false, false, "Feras=" .. tostring(pointsBM)
    elseif bestTree == "MM" then isBM, isMM, isSV, specSource = false, true, false, "Precisão=" .. tostring(pointsMM)
    elseif bestTree == "SV" then isBM, isMM, isSV, specSource = false, false, true, "Sobrevivência=" .. tostring(pointsSV)
    elseif SpellFlashAddon.IsSpellKnown(19306) then isBM, isMM, isSV, specSource = false, false, true, "SV(19306)"
    elseif SpellFlashAddon.IsSpellKnown(19574) then isBM, isMM, isSV, specSource = true, false, false, "BM(19574)"
    elseif SpellFlashAddon.IsSpellKnown(1310786) then isBM, isMM, isSV, specSource = false, true, false, "MM(1310786)"
    else isBM, isMM, isSV, specSource = false, false, true, "padrão SV" end

    -- Mensagem de Inicialização (inclui o que o cliente devolveu de spec)
    if not AddonTable.SpecMessageSent or (isSV or isMM or isBM) and AddonTable.CurrentSpec == "Low Level" then
        local msg = "|cFF00FF00[SF Hunter]|r "
        if isBM then
            print(msg.."|cFFFF8000Mestre das Feras:|r O vínculo com seu pet é sua maior arma! Destrua-os!")
        elseif isMM then
            print(msg.."|cFF69CCF0Atirador de Elite:|r Precisão mortal a quilômetros de distância! Fogo neles!")
        elseif isSV then
            print(msg.."|cFFABD473Sobrevivência:|r Mestre das armadilhas e do veneno! Prepare a emboscada!")
        else
            print(msg.."|cFFCCCCCCRecruta Hunter:|r Aprendendo os caminhos da selva... Sobreviva!")
        end
        print(msg.."|cFFCCCCCCspec:|r " .. tostring(specSource) .. " (Feras=" .. tostring(pointsBM) .. " MM=" .. tostring(pointsMM) .. " SV=" .. tostring(pointsSV) .. ")")
        -- Saudação racial na mesma via PROVADA (print no load/PLAYER_* não aparece no cliente)
        if AddonTable.ShowRacialInfo and not AddonTable.RacialGreetingSent then
            AddonTable.ShowRacialInfo()
            AddonTable.RacialGreetingSent = true
        end
        AddonTable.SpecMessageSent = true
        AddonTable.CurrentSpec = isBM and "BM" or isMM and "MM" or isSV and "SV" or "Low Level"
    end

    -- =====================================================
    -- DANÇA DOS ASPECTOS (GLOBAL)
    -- =====================================================
    local function ManageAspectsGlobal()
        if IsMounted() then return false end

        local groupInCombat = IsGroupInCombat()
        local isPvPEnv = env.isPvP or instanceType == "pvp" or instanceType == "arena"

        -- 1. COMPORTAMENTO FORA DE COMBATE
        if not groupInCombat then
            if not isPvPEnv then
                -- PvE: Sugere mobilidade automaticamente
                -- No WotLK, AddonTable.GetNumPartyMembers() não inclui você (0-4). AddonTable.GetNumRaidMembers() inclui (1-40).
                local numParty = AddonTable.GetNumPartyMembers() or 0
                local numRaid = AddonTable.GetNumRaidMembers() or 0
                local inGroup = numParty > 0 or numRaid > 1

                if inGroup then
                    -- Prioridade em Grupo: Matilha (Pack). 
                    -- Não brilha se QUALQUER pessoa no grupo já estiver provendo o buff.
                    if not AddonTable.IsPackActive() then
                        return AddonTable.TryFlash(13159, "White", function() return true end, "Aspect of the Pack")
                    end
                else
                    -- Prioridade Solo: Guepardo (Cheetah).
                    if not AddonTable.IsCheetahActive() then
                        return AddonTable.TryFlash(5118, "White", function() return true end, "Aspect of the Cheetah")
                    end
                end
            end
            return false -- Em PvP fora de combate, não recomenda nada (vontade própria)
        end

        -- 2. COMPORTAMENTO EM COMBATE (Player ou Grupo)
        if groupInCombat then
            -- =====================================================
            -- PRIORIDADES DE ASPECTOS EM COMBATE
            -- =====================================================

            -- 2. Prioridade 1: Envenenado (Aspect of the Wild)
            if IsPoisoned() and not AddonTable.IsWildActive() then
                return AddonTable.TryFlash(20043, "Green", function() return true end, "Aspect of the Wild")
            end

            -- 3. Prioridade 2: Em Melee
            if env.tooCloseForRanged then
                if AddonTable.SafeUnitIsUnit("targettarget", "player") then
                    -- Sendo Alvo (Monkey para Esquiva)
                    if not AddonTable.IsMonkeyActive() then
                        return AddonTable.TryFlash(13163, "Green", function() return true end, "Aspect of the Monkey")
                    end
                else
                    -- Não sendo Alvo (Beast)
                    if not AddonTable.IsBeastActive() then
                        return AddonTable.TryFlash(13161, "Green", function() return true end, "Aspect of the Beast")
                    end
                end
            end

            -- 4. Prioridade 3: Voltar ao Dano (Hawk)
            -- Se estiver em Cheetah ou Pack em combate, forçamos a saída para evitar Daze,
            -- mesmo que a mana não esteja acima de 70%.
            local isDangerousAspect = AddonTable.IsCheetahActive() or AddonTable.IsPackActive()
            if not env.tooCloseForRanged and (env.manaPct > 70 or not AddonTable.IsAspectActive() or isDangerousAspect) then
                if not AddonTable.IsHawkActive() then
                    return AddonTable.TryFlash(13165, "White", function() return true end, "Aspect of the Hawk")
                end
            end
        end
        return false
    end

    if ManageAspectsGlobal() then return end

    -- =====================================================
    -- RACIAL E TRINKETS (Sincronizado com o Warrior)
    -- =====================================================
    -- Verifica situações de CC, vida baixa ou burst para brilhar raciais e trinkets
    local racialId = AddonTable.ShouldUseRacial and AddonTable.ShouldUseRacial()
    if racialId then
        local racialName = AddonTable.SpellName(racialId)
        if racialName and SpellFlashAddon.Flashable(racialName) then
            AddonTable.RawFlash(racialName, "Aqua")
        end
    end
    local trinketId = AddonTable.ShouldUseTrinket and AddonTable.ShouldUseTrinket()
    if trinketId then
        local trinketName = nil
        if C_Item and type(C_Item.GetItemInfo) == "function" then
            local ok, name = pcall(C_Item.GetItemInfo, trinketId)
            if ok then trinketName = name end
        end
        if trinketName and SpellFlashAddon.Flashable(trinketName) then
            AddonTable.RawFlash(trinketName, "Aqua")
        end
    end

    -- Utilidades Comuns (Pet, Aspectos, etc.)
    -- Curar/Chamar Pet piscam JUNTO com a rotação (não bloqueiam)
    if env.petAlive then
        local isMending = SpellFlashAddon.CheckBuff(AddonTable.SpellName(136), "pet")
        if SpellFlashAddon.HealthPercent("pet") < 70 and not isMending then
            AddonTable.TryFlash(136, "Green", function() return true end, "Mend Pet")
        end
    else
        -- Revive Pet: fora do vanilla (ID não confirmado); Call Pet cobre a chamada
        -- de pet estáburo/dispensado.
        AddonTable.TryFlash(883, "Green", function() return true end, "Call Pet")
    end

    -- Hunter's Mark Inteligente
    -- Em combate a aura é ilegível (secret); confiamos no nosso cast (crença).
    local marked = IsMarkedByUs() or SpellFlashAddon.CheckDebuff(AddonTable.SpellName(1130), "target")
    if env.hasActiveEnemy and not marked then
        if AddonTable.TryFlash(1130, "Pink", function() return true end, "Hunter's Mark") then end
    end

    -- (Tranquilizing Shot não existe no vanilla — removido)

    -- 3. CONCUSSIVE SHOT INTELIGENTE (PvP ou Aggro)
    if env.hasActiveEnemy and not env.isMelee and not AddonTable.IsConcussiveShot("target") and not SpellFlashAddon.IsCrowedControlled("target") then
        -- Em PvP: Brilha sempre (prioridade de controle). Em PvE: Apenas se o alvo estiver focado em você ou sem alvo.
        local shouldSlow = env.isPvP or (InCombat() and (AddonTable.SafeUnitIsUnit("targettarget", "player") or not UnitExists("targettarget")))
        if shouldSlow and AddonTable.TryFlash(5116, "Yellow", function() return true end, "Concussive Shot") then end
    end

    -- 4. MISDIRECTION (Aggro Management)
    -- Removido daqui para ser tratado com a prioridade correta dentro de cada script de especialização.
    -- Isso evita que o MD brilhe acima de um Kill Shot ou Explosive Shot de emergência.

    -- Chamada dos Scripts de Rotação
    if isBM and AddonTable.RunBMRotation then if AddonTable.RunBMRotation(env) then return end
    elseif isMM and AddonTable.RunMMRotation then if AddonTable.RunMMRotation(env) then return end
    elseif isSV and AddonTable.RunSVRotation then if AddonTable.RunSVRotation(env) then return end end

    -- Auto-Shot (Filler se nada estiver brilhando e estiver em alcance)
    if env.hasActiveEnemy and not env.isMelee and not SpellFlashAddon.AutoShoot and not AddonTable.TickFlashUsed and not AddonTable.IsPressSuppressed(AddonTable.SpellName(75)) then
        AddonTable.TickFlashUsed = true
        SpellFlashAddon.FlashAction(AddonTable.SpellName(75), "White")
    end
end

-- Diagnóstico de talentos: /sftrees — mostra o que o cliente devolve por árvore.
SLASH_SFHUNTERTREES1 = "/sftrees"
SlashCmdList["SFHUNTERTREES"] = function()
    local function P(m) DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[SF Huntrees]|r " .. tostring(m)) end
    if not (C_ClassTalents and C_Traits) then P("C_ClassTalents/C_Traits ausentes") return end
    local okCfg, cfg = pcall(C_ClassTalents.GetActiveConfigID)
    P("cfg=" .. tostring(okCfg and cfg) .. " (ok=" .. tostring(okCfg) .. ")")
    local okInfo, info = pcall(C_Traits.GetConfigInfo, cfg)
    P("configInfo tipo=" .. tostring(type(info)))
    if type(info) == "table" then
        local keys = {}
        for k, v in pairs(info) do keys[#keys + 1] = tostring(k) .. "=" .. tostring(v) end
        P("configInfo: " .. table.concat(keys, ", "))
        if type(info.treeIDs) == "table" then
            for i, treeID in ipairs(info.treeIDs) do
                P("tree[" .. i .. "] id=" .. tostring(treeID))
                if C_Traits.GetTreeInfo then
                    local okT, ti = pcall(C_Traits.GetTreeInfo, cfg, treeID)
                    if okT and type(ti) == "table" then
                        local tk = {}
                        for k, v in pairs(ti) do
                            local vs = tostring(v)
                            if #vs > 40 then vs = vs:sub(1, 40) .. "…" end
                            tk[#tk + 1] = tostring(k) .. "=" .. vs
                        end
                        P("   treeInfo: " .. table.concat(tk, ", "))
                    else
                        P("   treeInfo: erro/nil")
                    end
                end
                local okN, nodes = pcall(C_Traits.GetTreeNodes, treeID)
                P("   nodes=" .. tostring(type(nodes) == "table" and #nodes or tostring(nodes)))
                if type(nodes) == "table" then
                    local total = 0
                    for _, nodeID in ipairs(nodes) do
                        local okNI, ni = pcall(C_Traits.GetNodeInfo, cfg, nodeID)
                        if okNI and type(ni) == "table" then
                            local rank = tonumber(ni.currentRank) or tonumber(ni.ranksPurchased) or tonumber(ni.activeRank) or 0
                            total = total + rank
                        end
                    end
                    P("   pontos=" .. tostring(total))
                end
            end
        end
    end
end

-- Diagnóstico de distância: /sfdist — mostra o que o cliente devolve pra distância e pros testes.
SLASH_SFDISTD1 = "/sfdist"
SlashCmdList["SFDISTD"] = function()
    local function P(m) DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[SF Aidist]|r " .. tostring(m)) end
    if type(UnitDistanceSquared) == "function" then
        local ok, sq, checked = pcall(UnitDistanceSquared, "target")
        P("UnitDistanceSquared: ok=" .. tostring(ok) .. " squared=" .. tostring(sq) .. " checked=" .. tostring(checked))
        if ok and type(sq) == "number" and sq >= 0 then
            P("  => distancia = " .. tostring(math.sqrt(sq)) .. " yd")
        end
    else
        P("UnitDistanceSquared: ausente")
    end
    if type(UnitInRange) == "function" then
        local ok, r, c = pcall(UnitInRange, "target")
        P("UnitInRange: ok=" .. tostring(ok) .. " inRange=" .. tostring(r) .. " checked=" .. tostring(c))
    else
        P("UnitInRange: ausente")
    end
    P("target=" .. tostring((function() local ok, n = pcall(UnitName, "target"); return ok and n or "<?>" end)()))
    P("IsInMeleeRange = " .. tostring(AddonTable.IsInMeleeRange and AddonTable.IsInMeleeRange("target")))
    P("TargetDistance = " .. tostring(AddonTable.TargetDistance and AddonTable.TargetDistance("target")))
    P("IsSpellInRange(Wing Clip) = " .. tostring(SpellFlashAddon.IsSpellInRangeEx and SpellFlashAddon.IsSpellInRangeEx(AddonTable.SpellName(2974), "target")))
    P("IsSpellInRange(Auto Shot) = " .. tostring(SpellFlashAddon.IsSpellInRangeEx and SpellFlashAddon.IsSpellInRangeEx(AddonTable.SpellName(75), "target")))
    P("SafeInteractDistance(3) = " .. tostring(AddonTable.SafeInteractDistance and AddonTable.SafeInteractDistance("target", 3)))
    P("AttackSlot = " .. tostring(SpellFlashAddon.FindActionSlot and SpellFlashAddon.FindActionSlot(6603)))
    if C_ActionBar and type(C_ActionBar.IsAttackAction) == "function" then
        P("C_ActionBar.IsAttackAction existe (usado para localizar o slot de Atacar)")
    else
        P("C_ActionBar.IsAttackAction AUSENTE")
    end
end

print('|cFF00FF00[SF Hunter]|r Scripts Core Carregado!')