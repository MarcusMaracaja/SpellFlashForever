-- SpellFlashForever / MinimapButton.lua
-- Botão no minimapa para abrir/fechar o menu principal sem escrever comando.
-- Clique esquerdo: abre/fecha o /sf (GUI). Clique direito: abre também (mesma coisa).
-- Segurar e arrastar: muda o ângulo do botão no anel do minimapa.
-- Estado (visível/escondido + ângulo) em SpellFlashForeverDB.handle.minimap_button.
-- Sem dependências externas.

local addonName = "SpellFlashForever"
local s = _G[addonName]
if not s then return end

local function GetConfig()
    local db = _G.SpellFlashForeverDB
    if type(db) ~= "table" then return {} end
    if type(db.handle) ~= "table" then db.handle = {} end
    if type(db.handle.minimap_button) ~= "table" then db.handle.minimap_button = {} end
    return db.handle.minimap_button
end

local frame = nil

local function UpdatePosition()
    if not frame then return end
    local cfg = GetConfig()
    local angle = math.rad(cfg.angle or 200)
    local radius = (Minimap:GetWidth() / 2) + 10
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function Build()
    if frame then return end
    local b = CreateFrame("Button", "SpellFlashForeverMinimapButton", Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    b:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            local cfg = GetConfig()
            cfg.angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
            UpdatePosition()
        end)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    b:SetScript("OnClick", function(_, button)
        if s.ToggleGUI then
            s.ToggleGUI()
        end
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("SpellFlashForever", 1, 0.82, 0)
        GameTooltip:AddLine("Clique para abrir/fechar o menu.", 1, 1, 1, true)
        GameTooltip:AddLine("Arraste para reposicionar. Use /sfminimap para esconder/mostrar.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local overlay = b:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")

    local background = b:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("TOPLEFT", 7, -5)

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(19, 19)
    icon:SetTexture("Interface\\Icons\\Ability_Hunter_SteadyShot")
    if not icon:GetTexture() then
        icon:SetTexture("Interface\\Icons\\Ability_Marksmanship")
    end
    icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
    icon:SetPoint("TOPLEFT", 6, -6)

    frame = b
    UpdatePosition()

    local cfg = GetConfig()
    if cfg.hidden then
        b:Hide()
    else
        b:Show()
    end
end

-- Toggle: mostrar/esconder o botão
function s.ToggleMinimapButton()
    local cfg = GetConfig()
    cfg.hidden = not (cfg.hidden and true or false)
    if frame then
        if cfg.hidden then
            frame:Hide()
        else
            frame:Show()
        end
    end
    return not cfg.hidden
end

-- Mostrar
function s.ShowMinimapButton()
    local cfg = GetConfig()
    cfg.hidden = nil
    if frame then frame:Show() end
end

-- Esconder
function s.HideMinimapButton()
    local cfg = GetConfig()
    cfg.hidden = true
    if frame then frame:Hide() end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    Build()
end)

SLASH_SFMINIMAP1 = "/sfminimap"
SLASH_SFMINIMAP2 = "/sfmm"
SlashCmdList["SFMINIMAP"] = function(msg)
    msg = msg and msg:lower():gsub("^%s+", ""):gsub("%s+$", "") or ""
    if msg == "show" or msg == "mostrar" or msg == "on" then
        s.ShowMinimapButton()
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r botão do minimapa mostrado.")
        return
    elseif msg == "hide" or msg == "esconder" or msg == "off" then
        s.HideMinimapButton()
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r botão do minimapa escondido.")
        return
    end
    local shown = s.ToggleMinimapButton()
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlashForever:|r botão do minimapa " .. (shown and "mostrado" or "escondido") .. ".")
end
