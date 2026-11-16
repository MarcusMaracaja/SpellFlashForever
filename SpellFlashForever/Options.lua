-- SpellFlashForever / Options.lua
-- Interface gráfica Standalone e integração com o sistema de opções do WoW Forever.

local addonName = "SpellFlashForever"
local s = _G[addonName]
if not s then return end
local L = s.L
local ADDON_VERSION = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version"))
    or (GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")) or "1.8.0"

local registeredTabs = {}
local tabButtons = {}
local tabFrames = {}
local activeTabID = "general"
local mainFrame = nil

-- API para registrar abas modulares (ex: Hunter, Rogue, Warrior, etc.)
-- `class` (opcional): classe em que a aba é visível (ex.: "HUNTER"). Sem `class`,
-- a aba é sempre exibida (usado pela aba Geral).
function s.RegisterConfigTab(id, title, builderFunc, class)
    for _, tab in ipairs(registeredTabs) do
        if tab.id == id then
            tab.title = title
            tab.builder = builderFunc
            tab.class = class
            return
        end
    end
    registeredTabs[#registeredTabs + 1] = { id = id, title = title, builder = builderFunc, class = class }
    if mainFrame and mainFrame:IsShown() and s.RefreshGUI then
        s.RefreshGUI()
    end
end

local function TabVisible(tab)
    if not tab.class then return true end
    local _, playerClass = UnitClass("player")
    return playerClass == tab.class
end

-- Helpers para controles de UI
local function CreateCheck(parent, name, label, tooltip, x, y, getFunc, setFunc)
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetSize(24, 24)
    -- Label na engine moderna (Interface 16001): UICheckButtonTemplate NAO cria
    -- $parentText e o CheckButton nao expoe GetFontString() neste cliente
    -- (confirmado em ShortestPathForever/HunterSmartTrack). O label e' um
    -- FontString separado, ancorado a direita da caixa.
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    fs:SetJustifyH("LEFT")
    fs:SetText(label)
    cb.label = fs
    cb:SetChecked(getFunc())
    cb:SetScript("OnClick", function(self)
        setFunc(self:GetChecked())
    end)
    if tooltip then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine(tooltip, 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return cb
end

local function CreateSlider(parent, name, label, minVal, maxVal, step, x, y, getFunc, setFunc, formatFunc, tooltip)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetWidth(260)
    slider:SetHeight(16)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    if slider.SetObeyStepNumbers then
        slider:SetObeyStepNumbers(true)
    end

    local currentVal = getFunc() or minVal
    slider:SetValue(currentVal)

    local text = _G[slider:GetName() .. "Text"]
    local low = _G[slider:GetName() .. "Low"]
    local high = _G[slider:GetName() .. "High"]

    if low then low:SetText(tostring(minVal)) end
    if high then high:SetText(tostring(maxVal)) end

    local function UpdateText(val)
        if text then
            local formatted = formatFunc and formatFunc(val) or tostring(val)
            text:SetText(label .. ": " .. formatted)
        end
    end
    UpdateText(currentVal)

    slider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value + 0.5)
        setFunc(rounded)
        UpdateText(rounded)
    end)

    if tooltip then
        slider:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine(tooltip, 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        slider:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    return slider
end

-- Conteúdo da Aba Geral
local function BuildGeneralTab(parent)
    local db = SpellFlashForeverDB
    local handle = db and db.handle or {}

    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L.opt_general_title)

    local desc = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    desc:SetText(L.opt_general_desc)

    local y = -58

    -- 1. Ativar Flashing
    CreateCheck(parent, "SFBF_GUI_Flashing", L.opt_flash_enable,
        L.opt_flash_enable_tt, 16, y,
        function() return not handle.spell_flashing_off end,
        function(val) handle.spell_flashing_off = (not val) or nil end
    )
    y = y - 30

    -- 2. Tipos de brilho
    CreateCheck(parent, "SFBF_GUI_FlashBorder", L.opt_flash_border,
        L.opt_flash_border_tt, 16, y,
        function() return handle.flash_mode == "border" end,
        function(val) handle.flash_mode = val and "border" or "overlay" end
    )
    y = y - 30

    CreateCheck(parent, "SFBF_GUI_FlashSolid", L.opt_flash_solid,
        L.opt_flash_solid_tt, 16, y,
        function() return not not handle.flash_solid end,
        function(val) handle.flash_solid = val and true or nil end
    )
    y = y - 30

    -- 3. Mesma cor para todos os brilhos
    CreateCheck(parent, "SFBF_GUI_SingleColor", L.opt_single_color,
        L.opt_single_color_tt, 16, y,
        function() return not not handle.flash_single_color end,
        function(val)
            handle.flash_single_color = val and true or nil
            if val and not handle.flash_single_color_color then handle.flash_single_color_color = "yellow" end
        end
    )
    y = y - 26

    -- Linha de cores (rádio-botão, 2 colunas x 5 linhas)
    local colorChoices = {
        { key = "yellow", label = L.col_yellow, hex = "|cffffff00" },
        { key = "white",  label = L.col_white,  hex = "|cffffffff" },
        { key = "red",    label = L.col_red,    hex = "|cffff2020" },
        { key = "green",  label = L.col_green,  hex = "|cff20ff20" },
        { key = "blue",   label = L.col_blue,   hex = "|cff2020ff" },
        { key = "aqua",   label = L.col_aqua,   hex = "|cff20ffff" },
        { key = "orange", label = L.col_orange, hex = "|cffff8000" },
        { key = "purple", label = L.col_purple, hex = "|cffff20ff" },
        { key = "pink",   label = L.col_pink,   hex = "|cffff40a0" },
        { key = "gray",   label = L.col_gray,   hex = "|cff7f7f7f" },
    }
    for i, choice in ipairs(colorChoices) do
        local col = math.floor((i - 1) / 5)
        local row = (i - 1) % 5
        local xOff = 40 + col * 170
        local yOff = y - row * 22
        local cb = CreateFrame("CheckButton", "SFBF_GUI_SColor_" .. choice.key, parent, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, yOff)
        cb:SetSize(20, 20)
        local labelFs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        labelFs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        labelFs:SetJustifyH("LEFT")
        labelFs:SetText(choice.hex .. choice.label .. "|r")
        cb.label = labelFs
        cb:SetChecked(handle.flash_single_color_color == choice.key)
        cb:SetScript("OnClick", function(self)
            handle.flash_single_color_color = choice.key
            for _, other in ipairs(colorChoices) do
                local otherCb = _G["SFBF_GUI_SColor_" .. other.key]
                if otherCb and otherCb ~= self then otherCb:SetChecked(false) end
            end
        end)
    end
    y = y - (5 * 22 + 8)

    -- 2. Suprimir alcance
    CreateCheck(parent, "SFBF_GUI_Range", L.opt_suppress_range,
        L.opt_suppress_range_tt, 16, y,
        function() return not not handle.suppress_range_check end,
        function(val) handle.suppress_range_check = val or nil end
    )
    y = y - 30

    -- 3. Suprimir movimento
    CreateCheck(parent, "SFBF_GUI_Speed", L.opt_suppress_speed,
        L.opt_suppress_speed_tt, 16, y,
        function() return not not handle.suppress_speed_check end,
        function(val) handle.suppress_speed_check = val or nil end
    )
    y = y - 30

    -- 4. Desativar detecção de imunidade
    CreateCheck(parent, "SFBF_GUI_Immune", L.opt_disable_immune,
        L.opt_disable_immune_tt, 16, y,
        function() return not not handle.auto_mob_immune_detection_off end,
        function(val) handle.auto_mob_immune_detection_off = val or nil end
    )
    y = y - 44

    -- 5. Slider de Tamanho do Flash (%)
    CreateSlider(parent, "SFBF_GUI_Slider_Size", L.opt_flash_size, 100, 400, 10, 20, y,
        function() return s.GetFlashSize and s.GetFlashSize() or 240 end,
        function(val) if s.SetFlashSize then s.SetFlashSize(val) end end,
        function(val) return val .. "%" end
    )
    y = y - 48

    -- 6. Slider de Brilho do Flash (%)
    CreateSlider(parent, "SFBF_GUI_Slider_Bright", L.opt_flash_bright, 10, 100, 5, 20, y,
        function() return s.GetFlashBrightness and s.GetFlashBrightness() or 100 end,
        function(val) if s.SetFlashBrightness then s.SetFlashBrightness(val) end end,
        function(val) return val .. "%" end
    )
    y = y - 40

    -- (também para o modo borda)
    CreateSlider(parent, "SFBF_GUI_Slider_BorderWidth", L.opt_flash_border_width, 0, 60, 1, 20, y,
        function() return s.GetFlashBorderWidth and s.GetFlashBorderWidth() or 12 end,
        function(val) if s.SetFlashBorderWidth then s.SetFlashBorderWidth(val) end end,
        function(val) return val .. "px" end,
        L.opt_flash_border_width_tt
    )
    y = y - 48

    -- Botão no minimapa (mostra/esconde)
    CreateCheck(parent, "SFBF_GUI_MinimapButton", L.opt_minimap,
        L.opt_minimap_tt, 16, y,
        function()
            local db = SpellFlashForeverDB and SpellFlashForeverDB.handle and SpellFlashForeverDB.handle.minimap_button
            if db and db.hidden then return false end
            return true
        end,
        function(val)
            if val then
                if s.ShowMinimapButton then s.ShowMinimapButton() end
            else
                if s.HideMinimapButton then s.HideMinimapButton() end
            end
        end
    )
    y = y - 36

    -- Botão que mostra a tecla da habilidade em destaque
    CreateCheck(parent, "SFBF_GUI_KeyButton", L.opt_keybutton,
        L.opt_keybutton_tt, 16, y,
        function() return (s.IsKeyButtonEnabled and s.IsKeyButtonEnabled()) and true or false end,
        function(val) if s.SetKeyButtonEnabled then s.SetKeyButtonEnabled(val) end end
    )
    y = y - 32

    -- Trava do botão de tecla (não arrasta) — persistido
    CreateCheck(parent, "SFBF_GUI_KeyButtonLocked", L.opt_keybutton_lock,
        L.opt_keybutton_lock_tt, 16, y,
        function() return (s.GetKeyButtonLocked and s.GetKeyButtonLocked()) and true or false end,
        function(val) if s.SetKeyButtonLocked then s.SetKeyButtonLocked(val) end end
    )
    y = y - 36

    -- Avisos de habilidade com rank desatualizado na action bar (pré-marcado)
    CreateCheck(parent, "SFBF_GUI_BarRankWarnings", L.opt_bar_rank_warnings,
        nil, 16, y,
        function()
            local db = SpellFlashForeverDB and SpellFlashForeverDB.handle
            if db and db.bar_rank_warnings == false then return false end
            return true
        end,
        function(val)
            local db = SpellFlashForeverDB
            db.handle = db.handle or {}
            db.handle.bar_rank_warnings = val and nil or false
        end
    )
    y = y - 36

    -- Botão Testar Flash
    local testBtn = CreateFrame("Button", "SFBF_GUI_TestButton", parent, "UIPanelButtonTemplate")
    testBtn:SetPoint("TOPLEFT", 16, y)
    testBtn:SetSize(140, 24)
    testBtn:SetText(L.opt_test_button)
    testBtn:SetScript("OnClick", function()
        local btn = _G["ActionButton1"]
        if btn and s.FlashFrame then
            local size = s.GetFlashSize and s.GetFlashSize() or 240
            local bright = s.GetFlashBrightness and s.GetFlashBrightness() or 100
            s.FlashFrame(btn, "yellow", size, bright, false, nil, false, false)
            DEFAULT_CHAT_FRAME:AddMessage(L.opt_test_msg)
        else
            DEFAULT_CHAT_FRAME:AddMessage(L.opt_test_fail)
        end
    end)

    -- Botão Salvar Configurações (reforça a escrita no banco e confirma no chat)
    local saveBtn = CreateFrame("Button", "SFBF_GUI_SaveButton", parent, "UIPanelButtonTemplate")
    saveBtn:SetPoint("TOPLEFT", testBtn, "TOPRIGHT", 12, 0)
    saveBtn:SetSize(180, 24)
    saveBtn:SetText(L.opt_save_button)
    saveBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.opt_save_button_tt or L.opt_save_button)
        GameTooltip:Show()
    end)
    saveBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    saveBtn:SetScript("OnClick", function()
        if s.SaveAllSettings and s.SaveAllSettings() then
            DEFAULT_CHAT_FRAME:AddMessage(L.opt_saved)
        end
    end)
end

-- Conteúdo da Aba Sobre
local function BuildAboutTab(parent)
    -- Logo circular no topo (128x128, máscara circular)
    local logo = parent:CreateTexture(nil, "ARTWORK")
    logo:SetSize(96, 96)
    logo:SetPoint("TOPLEFT", 16, -12)
    logo:SetTexture("Interface\\AddOns\\SpellFlashForever\\Textures\\SpellFlashForever_Icon.tga")

    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 12, -18)
    title:SetText("|cff33ff99SpellFlash Forever|r")

    local version = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    version:SetText(string.format(L.about_version, ADDON_VERSION))

    local function AddSection(anchorTo, yOffset, header, body)
        local h = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        h:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, yOffset)
        h:SetText("|cffffd700" .. header .. "|r")
        local b = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        b:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -4)
        b:SetWidth(400)
        b:SetJustifyH("LEFT")
        b:SetJustifyV("TOP")
        b:SetNonSpaceWrap(true)
        b:SetText(body)
        return b
    end

    local s1 = AddSection(logo, -4, L.about_what_is,
        L.about_what_is_body)

    local s2 = AddSection(s1, -14, L.about_includes,
        L.about_includes_body)

    local s3 = AddSection(s2, -14, L.about_howto,
        L.about_howto_body)

    local s4 = AddSection(s3, -14, L.about_credits,
        L.about_credits_body)

    local s5 = AddSection(s4, -14, L.about_thanks,
        L.about_thanks_body)
end

-- Seleção de Abas (ignora abas ocultas pela classe do jogador)
local function SelectTab(tabID)
    for _, tab in ipairs(registeredTabs) do
        if tab.id == tabID and not TabVisible(tab) then
            tabID = "general" -- aba da classe errada: volta para Geral
            break
        end
    end
    activeTabID = tabID
    for id, f in pairs(tabFrames) do
        if id == tabID then
            f:Show()
        else
            f:Hide()
        end
    end
    for id, btn in pairs(tabButtons) do
        if id == tabID then
            btn:Disable()
        else
            btn:Enable()
        end
    end
end

-- Construção da Janela Principal Standalone
local function CreateMainGUI()
    if mainFrame then return mainFrame end

    local f = CreateFrame("Frame", "SpellFlashForeverMainFrame", UIParent, "BackdropTemplate")
    f:SetSize(460, 620)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("DIALOG")

    -- Visual estilo Blizzard Dialog
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    f:SetBackdropColor(0, 0, 0, 0.9)

    -- Barra de Título / Cabeçalho
    local titleBg = f:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBg:SetWidth(280)
    titleBg:SetHeight(48)
    titleBg:SetPoint("TOP", f, "TOP", 0, 12)

    local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", titleBg, "TOP", 0, -14)
    titleText:SetText("|cff33ff99SpellFlash Forever|r")

    -- Botão Fechar [X] — desenhado no código (sempre visível, destacado em vermelho)
    local closeBtn = CreateFrame("Button", "SFBF_GUI_CloseButton", f)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetSize(24, 24)
    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    closeBg:SetVertexColor(0.55, 0.08, 0.08, 0.9)
    local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
    closeX:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    closeX:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
    closeX:SetText("X")
    closeX:SetTextColor(1, 1, 1)
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    closeBtn:SetScript("OnEnter", function() closeX:SetTextColor(1, 0.85, 0.2) end)
    closeBtn:SetScript("OnLeave", function() closeX:SetTextColor(1, 1, 1) end)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Fecha com a tecla ESC
    tinsert(UISpecialFrames, "SpellFlashForeverMainFrame")

    -- Barra de Abas (Tabs)
    local tabContainer = CreateFrame("Frame", nil, f)
    tabContainer:SetPoint("TOPLEFT", 12, -32)
    tabContainer:SetSize(436, 30)
    f.tabContainer = tabContainer

    -- Container de Conteúdo — com barra de rolagem vertical da janela inteira
    -- (abas ficam sempre visíveis; a área rolável fica abaixo delas)
    local scroll = CreateFrame("ScrollFrame", "SpellFlashForeverMainFrameScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -64)
    scroll:SetPoint("BOTTOMRIGHT", -12, 12)
    local content = CreateFrame("Frame", "SpellFlashForeverMainFrameScrollChild", scroll)
    content:SetSize(424, 1400)
    scroll:SetScrollChild(content)
    f.content = content
    f.scroll = scroll

    mainFrame = f
    s.MainGUI = f

    s.RefreshGUI()
    SelectTab("general")

    return f
end

function s.RefreshGUI()
    if not mainFrame then return end

    -- Constrói / atualiza os botões das abas (apenas as visíveis para a classe do jogador)
    local xOffset = 0
    for _, tab in ipairs(registeredTabs) do
        if TabVisible(tab) then
            local id = tab.id
            if not tabButtons[id] then
                local btn = CreateFrame("Button", nil, mainFrame.tabContainer, "UIPanelButtonTemplate")
                btn:SetSize(100, 22)
                btn:SetPoint("TOPLEFT", mainFrame.tabContainer, "TOPLEFT", xOffset, 0)
                btn:SetText(tab.title)
                btn:SetScript("OnClick", function()
                    SelectTab(id)
                end)
                tabButtons[id] = btn
            else
                tabButtons[id]:Show()
                tabButtons[id]:ClearAllPoints()
                tabButtons[id]:SetPoint("TOPLEFT", mainFrame.tabContainer, "TOPLEFT", xOffset, 0)
            end

            if not tabFrames[id] then
                local frame = CreateFrame("Frame", nil, mainFrame.content)
                frame:SetAllPoints(mainFrame.content)
                if tab.builder then
                    tab.builder(frame)
                end
                tabFrames[id] = frame
            end
            xOffset = xOffset + 104
        elseif tabButtons[tab.id] then
            tabButtons[tab.id]:Hide()
        end
    end
end

function s.ToggleGUI()
    local gui = CreateMainGUI()
    if gui:IsShown() then
        gui:Hide()
    else
        gui:Show()
        SelectTab(activeTabID or "general")
    end
end

function s.OpenOptions()
    local gui = CreateMainGUI()
    gui:Show()
    SelectTab(activeTabID or "general")
end

-- Registra as abas padrão: Geral e Sobre
s.RegisterConfigTab("general", L.tab_general, BuildGeneralTab)
s.RegisterConfigTab("about", L.tab_about, BuildAboutTab)

-- Integração de fallback com o painel de Opções nativo do WoW
local function CreateBlizzardSettingsCategory()
    if _G["SpellFlashForeverOptionsPanel"] then return end

    local panel = CreateFrame("Frame", "SpellFlashForeverOptionsPanel", UIParent)
    panel.name = "SpellFlash Forever"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff33ff99SpellFlash Forever|r")

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText(L.settings_hint)

    local openBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    openBtn:SetPoint("TOPLEFT", 16, -60)
    openBtn:SetSize(220, 30)
    openBtn:SetText(L.settings_open)
    openBtn:SetScript("OnClick", function()
        s.OpenOptions()
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local categoryID = Settings.RegisterCanvasLayoutCategory(panel, "SpellFlash Forever")
        Settings.RegisterAddOnCategory(categoryID)
        s.SettingsCategory = categoryID
        s.SettingsCategoryID = categoryID
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

-- Carregamento e Slash Commands
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    CreateBlizzardSettingsCategory()
end)

SLASH_SPELLFLASH1 = "/sf"
SLASH_SPELLFLASH2 = "/spellflash"
SlashCmdList["SPELLFLASH"] = function(msg)
    if msg and (msg == "menu" or msg == "options" or msg == "config" or msg == "") then
        s.ToggleGUI()
    elseif SlashCmdList["SPELLFLASHFOREVER"] then
        SlashCmdList["SPELLFLASHFOREVER"](msg)
    end
end
