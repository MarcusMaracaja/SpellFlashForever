-- SpellFlash_Hunter / Options.lua
-- Registro de uma aba "Hunter" na GUI do SpellFlashForever (/sf).
-- Substitui o antigo painel XML (Interface 30300) por um CheckButton moderno.
local AddonName, AddonTable = ...
local SFBF = _G["SpellFlashForever"]
local L = (SFBF and SFBF.L) or setmetatable({}, { __index = function(_, k) return k end })

-- Respeitado pelo driver do SpellFlashForever (Compat.lua): se ligado, o módulo não é chamado.
local function GetModuleOff()
    if not (SFBF and SFBF.GetModuleConfig) then return false end
    return not not SFBF.GetModuleConfig(AddonName, "spell_flashing_off")
end

local function SetModuleOff(value)
    if not (SFBF and SFBF.SetModuleConfig) then return end
    SFBF.SetModuleConfig(AddonName, "spell_flashing_off", value and true or nil)
end

-- Override manual de spec: "BM" | "MM" | "SV" | nil (automático)
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

local function BuildHunterTab(parent)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff33ff99Hunter|r")

    local desc = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    desc:SetWidth(400)
    desc:SetJustifyH("LEFT")
    desc:SetText(string.format(L.mod_desc_abilities, "Hunter"))

    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
    cb:SetSize(24, 24)

    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    fs:SetJustifyH("LEFT")
    fs:SetText(string.format(L.mod_toggle, "Hunter"))
    cb.label = fs
    cb:SetChecked(not GetModuleOff())
    cb:SetScript("OnClick", function(self)
        SetModuleOff(not self:GetChecked())
    end)

    local hint = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 0, -12)
    hint:SetWidth(400)
    hint:SetJustifyH("LEFT")
    hint:SetText(L.mod_toggle_hint_long)

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
            -- Redesenha as 3 caixas para ficarem mutuamente exclusivas
            for value, box in pairs(specBoxes) do
                box:SetChecked(GetSpecOverride() == value)
            end
        end
    end

    specBoxes["BM"] = CreateCheck(parent, specTitle, -8, L.spec_bm,
        function() return GetSpecOverride() == "BM" end, SetSpecExclusive("BM"))
    specBoxes["MM"] = CreateCheck(parent, specBoxes["BM"], -8, L.spec_mm,
        function() return GetSpecOverride() == "MM" end, SetSpecExclusive("MM"))
    specBoxes["SV"] = CreateCheck(parent, specBoxes["MM"], -8, L.spec_sv,
        function() return GetSpecOverride() == "SV" end, SetSpecExclusive("SV"))

    local specHint = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    specHint:SetPoint("TOPLEFT", specBoxes["SV"], "BOTTOMLEFT", 0, -12)
    specHint:SetWidth(400)
    specHint:SetJustifyH("LEFT")
    specHint:SetText(L.mod_hunter_spec_hint)

    -- Editor de rotação (Modelo A: cards) — dentro da aba da classe, por personagem
    if SFBF and type(SFBF.BuildRotationEditor) == "function" then
        SFBF.BuildRotationEditor(parent, specHint, AddonName, AddonTable)
    end
end

if SFBF and type(SFBF.RegisterConfigTab) == "function" then
    SFBF.RegisterConfigTab("hunter", "Hunter", BuildHunterTab, "HUNTER")
else
    print(string.format(L.mod_not_available, "Hunter", "Hunter"))
end

print(string.format(L.mod_loaded, "Hunter", L.mod_load_options))
