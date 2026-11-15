-- SpellFlash_Druid / Options.lua
-- Registro da aba "Druid" na GUI /sf (mesmo padrão da aba Hunter).
local AddonName, AddonTable = ...
local SFBF = _G["SpellFlashForever"]
local L = (SFBF and SFBF.L) or setmetatable({}, { __index = function(_, k) return k end })

local function GetModuleOff()
    if not (SFBF and SFBF.GetModuleConfig) then return false end
    return not not SFBF.GetModuleConfig(AddonName, "spell_flashing_off")
end

local function SetModuleOff(value)
    if not (SFBF and SFBF.SetModuleConfig) then return end
    SFBF.SetModuleConfig(AddonName, "spell_flashing_off", value and true or nil)
end

local function GetSpecOverride()
    if not (SFBF and SFBF.GetModuleConfig) then return nil end
    return SFBF.GetModuleConfig(AddonName, "spec_override")
end

local function SetSpecOverride(value)
    if not (SFBF and SFBF.SetModuleConfig) then return end
    SFBF.SetModuleConfig(AddonName, "spec_override", value)
end

local function CreateCheck(parent, anchor, offsetY, label, getFunc, setFunc)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, offsetY)
    cb:SetSize(24, 24)

    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    fs:SetJustifyH("LEFT")
    fs:SetText(label)
    cb.label = fs
    cb:SetChecked(getFunc())
    cb:SetScript("OnClick", function(self)
        setFunc(self:GetChecked())
    end)
    return cb
end

local function BuildDruidTab(parent)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cffff7d0bDruid|r")

    local desc = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    desc:SetWidth(420)
    desc:SetJustifyH("LEFT")
    desc:SetText(string.format(L.mod_desc_abilities, "Druid"))

    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
    cb:SetSize(24, 24)

    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    fs:SetJustifyH("LEFT")
    fs:SetText(string.format(L.mod_toggle, "Druid"))
    cb.label = fs
    cb:SetChecked(not GetModuleOff())
    cb:SetScript("OnClick", function(self)
        SetModuleOff(not self:GetChecked())
    end)

    local hint = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 0, -12)
    hint:SetWidth(420)
    hint:SetJustifyH("LEFT")
    hint:SetText(L.mod_toggle_hint)

    local specTitle = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    specTitle:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -18)
    specTitle:SetText(L.mod_spec_title)

    local specBoxes = {}
    local function SetSpecExclusive(target)
        return function(checked)
            local cur = GetSpecOverride()
            if checked then
                SetSpecOverride(target)
            elseif cur == target then
                SetSpecOverride(nil)
            end
            for value, box in pairs(specBoxes) do
                box:SetChecked(GetSpecOverride() == value)
            end
        end
    end

    specBoxes["FERAL"] = CreateCheck(parent, specTitle, -8, L.spec_feral,
        function() return GetSpecOverride() == "FERAL" end, SetSpecExclusive("FERAL"))
    specBoxes["BAL"] = CreateCheck(parent, specBoxes["FERAL"], -8, L.spec_balance,
        function() return GetSpecOverride() == "BAL" end, SetSpecExclusive("BAL"))
    specBoxes["REST"] = CreateCheck(parent, specBoxes["BAL"], -8, L.spec_resto,
        function() return GetSpecOverride() == "REST" end, SetSpecExclusive("REST"))

    local specHint = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    specHint:SetPoint("TOPLEFT", specBoxes["REST"], "BOTTOMLEFT", 0, -12)
    specHint:SetWidth(420)
    specHint:SetJustifyH("LEFT")
    specHint:SetText(L.mod_druid_spec_hint)

    -- Editor de rotação (Modelo A: cards) — dentro da aba da classe, por personagem
    if SFBF and type(SFBF.BuildRotationEditor) == "function" then
        SFBF.BuildRotationEditor(parent, specHint, AddonName, AddonTable)
    end
end

if SFBF and type(SFBF.RegisterConfigTab) == "function" then
    SFBF.RegisterConfigTab("druid", "Druid", BuildDruidTab, "DRUID")
else
    print(string.format(L.mod_not_available, "Druid", "Druid"))
end

print(string.format(L.mod_loaded, "Druid", L.mod_load_options))
