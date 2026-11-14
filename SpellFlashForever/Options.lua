-- SpellFlashForever / Options.lua
-- Interface gráfica Standalone e integração com o sistema de opções do WoW Forever.

local addonName = "SpellFlashForever"
local s = _G[addonName]
if not s then return end

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

local function CreateSlider(parent, name, label, minVal, maxVal, step, x, y, getFunc, setFunc, formatFunc)
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

    return slider
end

-- Conteúdo da Aba Geral
local function BuildGeneralTab(parent)
    local db = SpellFlashForeverDB
    local handle = db and db.handle or {}

    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff33ff99Configurações Gerais|r")

    local desc = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    desc:SetText("Ajuste as opções visuais e comportamento de sugestões.")

    local y = -58

    -- 1. Ativar Flashing
    CreateCheck(parent, "SFBF_GUI_Flashing", "Ativar Sugestões de Feitiços (Spell Flashing)",
        "Pisca as habilidades recomendadas nas barras de ação.", 16, y,
        function() return not handle.spell_flashing_off end,
        function(val) handle.spell_flashing_off = (not val) or nil end
    )
    y = y - 30

    -- 2. Tipos de brilho
    CreateCheck(parent, "SFBF_GUI_FlashBorder", "Brilho de contorno (borda)",
        "Pisca a borda do botão em vez do brilho de estrela sobreposto.", 16, y,
        function() return handle.flash_mode == "border" end,
        function(val) handle.flash_mode = val and "border" or "overlay" end
    )
    y = y - 30

    CreateCheck(parent, "SFBF_GUI_FlashSolid", "Cor sólida (sem transparência)",
        "Mantém o brilho na opacidade máxima, sem esmaecer.", 16, y,
        function() return not not handle.flash_solid end,
        function(val) handle.flash_solid = val and true or nil end
    )
    y = y - 30

    -- 3. Mesma cor para todos os brilhos
    CreateCheck(parent, "SFBF_GUI_SingleColor", "Mesma cor para todos os brilhos",
        "Quando ligado, todos os flashes usam a cor escolhida e ignoram a cor individual.", 16, y,
        function() return not not handle.flash_single_color end,
        function(val)
            handle.flash_single_color = val and true or nil
            if val and not handle.flash_single_color_color then handle.flash_single_color_color = "yellow" end
        end
    )
    y = y - 26

    -- Linha de cores (rádio-botão, 2 colunas x 5 linhas)
    local colorChoices = {
        { key = "yellow", label = "Amarelo", hex = "|cffffff00" },
        { key = "white",  label = "Branco",  hex = "|cffffffff" },
        { key = "red",    label = "Vermelho", hex = "|cffff2020" },
        { key = "green",  label = "Verde",   hex = "|cff20ff20" },
        { key = "blue",   label = "Azul",    hex = "|cff2020ff" },
        { key = "aqua",   label = "Ciano",   hex = "|cff20ffff" },
        { key = "orange", label = "Laranja", hex = "|cffff8000" },
        { key = "purple", label = "Roxo",    hex = "|cffff20ff" },
        { key = "pink",   label = "Rosa",    hex = "|cffff40a0" },
        { key = "gray",   label = "Cinza",   hex = "|cff7f7f7f" },
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
    CreateCheck(parent, "SFBF_GUI_Range", "Suprimir verificação de alcance",
        "Piscar botões mesmo se o alvo estiver fora de alcance.", 16, y,
        function() return not not handle.suppress_range_check end,
        function(val) handle.suppress_range_check = val or nil end
    )
    y = y - 30

    -- 3. Suprimir movimento
    CreateCheck(parent, "SFBF_GUI_Speed", "Suprimir verificação de movimento",
        "Piscar botões mesmo durante movimento.", 16, y,
        function() return not not handle.suppress_speed_check end,
        function(val) handle.suppress_speed_check = val or nil end
    )
    y = y - 30

    -- 4. Desativar detecção de imunidade
    CreateCheck(parent, "SFBF_GUI_Immune", "Desativar detecção automática de imunidade",
        "Não registrar imunidades de criaturas contra tipos de magia.", 16, y,
        function() return not not handle.auto_mob_immune_detection_off end,
        function(val) handle.auto_mob_immune_detection_off = val or nil end
    )
    y = y - 44

    -- 5. Slider de Tamanho do Flash (%)
    CreateSlider(parent, "SFBF_GUI_Slider_Size", "Tamanho do Flash", 100, 400, 10, 20, y,
        function() return s.GetFlashSize and s.GetFlashSize() or 240 end,
        function(val) if s.SetFlashSize then s.SetFlashSize(val) end end,
        function(val) return val .. "%" end
    )
    y = y - 48

    -- 6. Slider de Brilho do Flash (%)
    CreateSlider(parent, "SFBF_GUI_Slider_Bright", "Brilho / Opacidade do Flash", 10, 100, 5, 20, y,
        function() return s.GetFlashBrightness and s.GetFlashBrightness() or 100 end,
        function(val) if s.SetFlashBrightness then s.SetFlashBrightness(val) end end,
        function(val) return val .. "%" end
    )
    y = y - 40

    -- Botão no minimapa (mostra/esconde)
    CreateCheck(parent, "SFBF_GUI_MinimapButton", "Mostrar botão no minimapa",
        "Exibe um botão no minimapa que abre/fecha este menu. Arraste-o para reposicionar. Use /sfminimap para igualmente esconder/mostrar.", 16, y,
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
    CreateCheck(parent, "SFBF_GUI_KeyButton", "Mostrar botão com a tecla da habilidade",
        "Exibe um botão extra mostrando a tecla que deve ser apertada para a habilidade que está brilhando.", 16, y,
        function() return (s.IsKeyButtonEnabled and s.IsKeyButtonEnabled()) and true or false end,
        function(val) if s.SetKeyButtonEnabled then s.SetKeyButtonEnabled(val) end end
    )
    y = y - 32

    -- Trava do botão de tecla (não arrasta) — persistido
    CreateCheck(parent, "SFBF_GUI_KeyButtonLocked", "Travar o botão de tecla (não arrasta)",
        "Impede que o botão de tecla seja arrastado por engano. Use junto com 'Mostrar botão com a tecla da habilidade'.", 16, y,
        function() return (s.GetKeyButtonLocked and s.GetKeyButtonLocked()) and true or false end,
        function(val) if s.SetKeyButtonLocked then s.SetKeyButtonLocked(val) end end
    )
    y = y - 36

    -- Botão Testar Flash
    local testBtn = CreateFrame("Button", "SFBF_GUI_TestButton", parent, "UIPanelButtonTemplate")
    testBtn:SetPoint("TOPLEFT", 16, y)
    testBtn:SetSize(140, 24)
    testBtn:SetText("Testar Flash")
    testBtn:SetScript("OnClick", function()
        local btn = _G["ActionButton1"]
        if btn and s.FlashFrame then
            local size = s.GetFlashSize and s.GetFlashSize() or 240
            local bright = s.GetFlashBrightness and s.GetFlashBrightness() or 100
            s.FlashFrame(btn, "yellow", size, bright, false, nil, false, false)
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlash Forever:|r Testando flash no Botão 1.")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SpellFlash Forever:|r Botão 1 não encontrado para teste.")
        end
    end)
end

-- Conteúdo da Aba Sobre
local function BuildAboutTab(parent)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff33ff99SpellFlash Forever|r")

    local version = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    version:SetText("Versão 1.3.0-forever · WoW Forever (Interface 16001)")

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

    local s1 = AddSection(version, -12, "O que é",
        "O SpellFlash Forever é um assistente de rotação para o WoW Forever. A cada 0,2s ele avalia seu alvo, sua spec, seus talentos, sua mana, seu alcance e o estado do combate — e faz piscar na barra de ação a habilidade que você deveria usar agora.\n\nCada habilidade pisca com a cor da sua função: dano principal (amarelo), AoE (roxo), interrupção/controle (ciano), defensivo (vermelho), utilidade (verde) e situacional (rosa/laranja).")

    local s2 = AddSection(s1, -14, "O que inclui",
        "• Núcleo SpellFlashForever: driver de sugestões, crenças de auras em combate, editor visual de rotação por personagem (/sf, seção \"Rotação personalizada\" em cada aba de classe), botão de tecla nos botões, botão de minimapa.\n• Módulos de classe: Hunter, Shaman, Warrior e Druid — cada um com a rotação recomendada do Forever como padrão, editável por personagem.\n• Um erro por vez; toda mudança é registrada no histórico do projeto.")

    local s3 = AddSection(s2, -14, "Como usar",
        "/sf abre (e fecha) esta janela. A aba de cada classe tem o toggle do módulo, a detecção de spec (com override) e o editor de rotação. /sf status mostra o estado do módulo. /sfminimap alterna o botão no minimapa.")

    local s4 = AddSection(s3, -14, "Créditos — criação",
        "|cffffffffMarcus|r — criação e direção do projeto SpellFlash Forever.\n\n|cffffffffInkling 2 Small Free (OpenCode)|r — parceiro de tecnologia e desenvolvimento: inteligência artificial usada como par de programação (pesquisas, arquitetura, código, testes e documentação).\n\nSpellFlash original (WotLK 3.3.5a): Exalter (Druid), BigRedBrent (Warrior), SF Community (Shaman) e comunidade SpellFlash. Este projeto é um port/derivado, com profundo retrabalho de arquitetura e de rotação para o Forever.")

    local s5 = AddSection(s4, -14, "Agradecimentos",
        "Ao time do WoW Forever, à comunidade de teoria de rotações e a quem testou o addon em jogo e reportou cada erro — cada correção virou uma entrada no histórico do projeto.")
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

    -- Botão Fechar [X]
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
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
s.RegisterConfigTab("general", "Geral", BuildGeneralTab)
s.RegisterConfigTab("about", "Sobre", BuildAboutTab)

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
    desc:SetText("Clique no botão abaixo para abrir a janela completa de configurações do SpellFlash Forever.")

    local openBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    openBtn:SetPoint("TOPLEFT", 16, -60)
    openBtn:SetSize(220, 30)
    openBtn:SetText("Abrir Menu SpellFlash Forever")
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
