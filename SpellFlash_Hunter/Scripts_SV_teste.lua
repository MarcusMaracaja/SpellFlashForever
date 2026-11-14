-- SpellFlash_Hunter / Scripts_SV_teste.lua
-- SIMPLIFICADO: Hunter's Mark sempre (combate ou não) + perto/longe via env

local AddonName, AddonTable = ...

_G.SpellFlashHunterShared = _G.SpellFlashHunterShared or {}
AddonTable = _G.SpellFlashHunterShared

AddonTable.__diagFiles = AddonTable.__diagFiles or {}
AddonTable.__diagFiles["Scripts_SV_teste.lua"] = tostring(AddonTable)

if not AddonTable then return end
if select(2, UnitClass("player")) ~= "HUNTER" then return end

local s = _G["SpellFlashForever"]
if not s then return end

-- IDs da Marca do Caçador (todos os ranks do Forever)
local HUNTERS_MARK_IDS = { 1130, 14323, 14324, 14325, 1213268 }

-- -----------------------------------------------------------
-- Verifica se o alvo TEM Marca do Caçador
-- Lê debuffs diretamente, sempre (combate ou não)
-- -----------------------------------------------------------
local function alvoTemMarca()
    if not UnitExists("target") then return false end
    if UnitIsDeadOrGhost("target") then return false end

    local api = C_UnitAuras
    if not api or type(api.GetDebuffDataByIndex) ~= "function" then
        return false
    end

    for i = 1, 40 do
        local ok, d = pcall(api.GetDebuffDataByIndex, "target", i, "HARMFUL")
        if not ok or d == nil then break end
        if type(d) == "table" then
            for _, id in ipairs(HUNTERS_MARK_IDS) do
                if d.spellId == id then
                    return true
                end
            end
        end
    end

    return false
end

-- -----------------------------------------------------------
-- Aplica Marca do Caçador
-- -----------------------------------------------------------
local function aplicarMarca()
    local markID = 1130
    local markName = AddonTable.SpellName and AddonTable.SpellName(markID) or nil
    if not markName or markName == "" then return false end

    if s.DebugFlash then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SF TEST]|r Aplicando Marca do Caçador (ID " .. markID .. ")")
    end

    s.FlashAction(markID, "Pink")
    return true
end

-- -----------------------------------------------------------
-- Entry point chamado pelo Spam (Scripts.lua)
-- Recebe env com: inCombat, inMelee, hasActiveEnemy
-- -----------------------------------------------------------
function AddonTable.RunSVRotation(env)
    if not env then return false end

    -- Só com alvo inimigo vivo
    if not env.hasActiveEnemy then return false end
    if UnitIsDeadOrGhost("target") then return false end

    local inCombat = env.inCombat or false
    local inMelee = env.inMelee or false

    -- -----------------------------------------------------------
    -- HUNTER'S MARK: recomendar se o alvo NÃO tem a marca
    -- Sempre, independente de combate, melee ou ranged
    -- -----------------------------------------------------------
    if not alvoTemMarca() then
        return aplicarMarca()
    end

    -- Debug de perto/longe (apenas informativo)
    if s.DebugFlash then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SF TEST]|r Combate=" .. tostring(inCombat)
            .. " | Melee=" .. tostring(inMelee == true) .. " | TemMarca=true")
    end

    return false
end

AddonTable.RunSVRotation = AddonTable.RunSVRotation

print("|cFF00FF00[SF Hunter]|r Scripts_SV_teste.lua carregado (Mark sempre + env.inMelee/inCombat)")
