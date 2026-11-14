-- SpellFlashForever / RotationEditor.lua
-- Editor visual de rotação (Modelo A: cadeia de cards) + motor de declaração.
-- Cada módulo declara suas rotações como DADO:
--   AddonTable.RotationSpecs = { ELE = { title = "Elemental", nodes = {...} }, ... }
--   AddonTable.RotationPredicates = { chave = { label = "...", fn = function(env) ... end } }
--   AddonTable.RotationModuleName = AddonName
-- Este arquivo implementa:
--   1) Persistência POR PERSONAGEM (SpellFlashForeverCharDB.rotation[module][specKey])
--   2) Merge personalizado x padrão (padrão do guia é sempre o fallback/reset)
--   3) Runner RunDeclaredRotation (avalia nós em ORDEM; mesmo TryFlash do módulo)
--   4) Filtros FINOS em cascata numerada (1 Combate, 2 Ambiente, 3 Alvo,
--      4 Alcance, 5 Recurso, 6 Área) - cada nó tem seus próprios filtros
--   5) GUI BuildRotationEditor (seção colapsável na aba da classe; scroll;
--      cards com x habilitar, ícone clicável-flash, ^v, inspetor de filtros,
--      botões Gravar e Compartilhar (exportar/importar string - estilo Hekili))
-- Nada de secure templates: é configuração, não ação de combate.

local addonName = "SpellFlashForever"
local s = _G[addonName]
if not s then return end

-- ---------------------------------------------------------------------------
-- Filtros finos: 6 eixos independentes (0 = "qualquer/ambos", sempre passa)
-- ---------------------------------------------------------------------------

local FILTER_AXES = {
    { key = "combat",   label = "1. Combate",
      options = { { 0, "ambos" }, { 1, "em combate" }, { 2, "fora de combate" } } },
    { key = "env",      label = "2. Ambiente",
      options = { { 0, "ambos" }, { 1, "PvE" }, { 2, "PvP" } } },
    { key = "target",   label = "3. Alvo",
      options = { { 0, "qualquer" }, { 1, "atacável" }, { 2, "conjurando" }, { 3, "sem alvo atacável" } } },
    { key = "range",    label = "4. Alcance",
      options = { { 0, "qualquer" }, { 1, "ranged (> dead zone)" }, { 2, "melee / dead zone" }, { 3, "na dead zone" } } },
    { key = "resource", label = "5. Recurso",
      options = { { 0, "qualquer" }, { 1, "mana > 15%" }, { 2, "mana > 40%" }, { 3, "mana > 50%" }, { 4, "rage >= 40" }, { 5, "energia >= 40" }, { 6, "combo >= 5" } } },
    { key = "aoe",      label = "6. Área",
      options = { { 0, "qualquer" }, { 1, "AoE (2+)" }, { 2, "alvo único" } } },
}

local FILTER_EVALS = {
    combat   = function(env, v) if v == 1 then return env.inCombat and true or false end if v == 2 then return not env.inCombat and true or false end return true end,
    env      = function(env, v) if v == 1 then return not env.isPvP and true or false end if v == 2 then return env.isPvP and true or false end return true end,
    target   = function(env, v) if v == 1 then return env.hasActiveEnemy and true or false end if v == 2 then return env.targetCasting and true or false end if v == 3 then return not env.hasActiveEnemy and true or false end return true end,
    range    = function(env, v)
        local tooClose = env.tooCloseForRanged == true
        local melee = env.isMelee == true
        if v == 1 then return not tooClose and not melee and true or false end
        if v == 2 then return (tooClose or melee) and true or false end
        if v == 3 then return (tooClose and not melee) and true or false end
        return true
    end,
    resource = function(env, v)
        if v == 1 then return (env.manaPct or 0) > 15 end
        if v == 2 then return (env.manaPct or 0) > 40 end
        if v == 3 then return (env.manaPct or 0) > 50 end
        if v == 4 then return (env.rage or 0) >= 40 end
        if v == 5 then return (env.energy or 0) >= 40 end
        if v == 6 then return (env.combo or 0) >= 5 end
        return true
    end,
    aoe      = function(env, v) if v == 1 then return env.isAoE and true or false end if v == 2 then return not env.isAoE and true or false end return true end,
}

local function FilterPass(env, filter)
    if type(filter) ~= "table" then return true end
    for _, axis in ipairs(FILTER_AXES) do
        local v = tonumber(filter[axis.key]) or 0
        if v ~= 0 then
            local fn = FILTER_EVALS[axis.key]
            if fn and not fn(env, v) then return false end
        end
    end
    return true
end
s.NodeFilterPass = FilterPass

local function DeepCopyFilter(f)
    if type(f) ~= "table" then return nil end
    local out = {}
    for _, axis in ipairs(FILTER_AXES) do
        local v = tonumber(f[axis.key]) or 0
        if v ~= 0 then out[axis.key] = v end
    end
    if next(out) then return out end
    return nil
end

local function DeepCopyNode(n)
    return { id = n.id, spellID = n.spellID, name = n.name, color = n.color, condition = n.condition, enabled = n.enabled ~= false, passthrough = n.passthrough == true, filter = DeepCopyFilter(n.filter) }
end

-- ---------------------------------------------------------------------------
-- Banco por personagem
-- ---------------------------------------------------------------------------

local function CharDB()
    local db = _G.SpellFlashForeverCharDB
    if type(db) ~= "table" then
        db = {}
        _G.SpellFlashForeverCharDB = db
    end
    db.rotation = db.rotation or {}
    return db
end

-- Rotação EFETIVA: padrão do módulo sobrescrito pelo custom salvo.
-- Custom guarda {id, enabled, condition, filter}; o resto vem do padrão.
-- Nós novos (atualização do módulo) entram no FIM, ligados.
local function GetEffective(spec, moduleName, specKey)
    local db = CharDB()
    local custom = db.rotation[moduleName] and db.rotation[moduleName][specKey]
    if not custom or type(custom.nodes) ~= "table" or #custom.nodes == 0 then
        local out = {}
        for _, n in ipairs(spec.nodes) do out[#out + 1] = DeepCopyNode(n) end
        return out
    end

    local byID = {}
    for _, n in ipairs(spec.nodes) do byID[n.id] = n end

    local merged, seen = {}, {}
    for _, cn in ipairs(custom.nodes) do
        local base = cn and byID[cn.id]
        if base then
            merged[#merged + 1] = {
                id = base.id,
                spellID = base.spellID,
                name = base.name,
                color = base.color,
                condition = (type(cn.condition) == "string" and cn.condition ~= "" and cn.condition) or base.condition,
                enabled = cn.enabled ~= false,
                passthrough = base.passthrough,
                filter = DeepCopyFilter(cn.filter) or DeepCopyFilter(base.filter),
            }
            seen[cn.id] = true
        end
    end
    for _, base in ipairs(spec.nodes) do
        if not seen[base.id] then merged[#merged + 1] = DeepCopyNode(base) end
    end
    return merged
end

s.GetEffectiveRotation = GetEffective

local function SerializeEffective(effective)
    local nodes = {}
    for _, n in ipairs(effective) do
        nodes[#nodes + 1] = { id = n.id, enabled = n.enabled ~= false, condition = n.condition, filter = DeepCopyFilter(n.filter) }
    end
    return { v = 1, nodes = nodes }
end

function s.SaveEffectiveRotation(moduleName, specKey, effective)
    local db = CharDB()
    db.rotation[moduleName] = db.rotation[moduleName] or {}
    db.rotation[moduleName][specKey] = SerializeEffective(effective)
end

function s.ResetRotation(moduleName, specKey)
    local db = CharDB()
    if db.rotation[moduleName] then
        db.rotation[moduleName][specKey] = nil
    end
end

-- ---------------------------------------------------------------------------
-- Runner: primeiro nó habilitado com filtros + condição verdadeira e castável vence.
-- ---------------------------------------------------------------------------

function s.RunDeclaredRotation(moduleAddon, specKey, env)
    if type(moduleAddon) ~= "table" then return false end
    local specs = moduleAddon.RotationSpecs
    if type(specs) ~= "table" then return false end
    local spec = specs[specKey]
    if not spec then return false end
    local TryFlash = moduleAddon.TryFlash
    if type(TryFlash) ~= "function" then return false end

    local moduleName = moduleAddon.RotationModuleName
    if not moduleName then return false end

    local nodes = GetEffective(spec, moduleName, specKey)
    local preds = type(moduleAddon.RotationPredicates) == "table" and moduleAddon.RotationPredicates or {}

    for _, node in ipairs(nodes) do
        if node.enabled ~= false then
            if FilterPass(env, node.filter) then
                local pass = true
                if node.condition and node.condition ~= "" then
                    local p = preds[node.condition]
                    if type(p) == "table" and type(p.fn) == "function" then
                        local ok, r = pcall(p.fn, env)
                        pass = ok and r and true or false
                    else
                        pass = true
                    end
                end
                if pass then
                    if TryFlash(node.spellID, node.color, function() return true end, node.name) then
                        if not node.passthrough then return true end
                    end
                end
            end
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Compartilhamento: string de rotação (estilo Hekili) - exportar/importar
-- Formato: !SFROT-1!<base64("SFR1\nmodule|spec\nid|onOff|cond|c,e,t,r,s,a\n...")>
-- ---------------------------------------------------------------------------

local B64_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

local function B64Encode(data)
    local out, i, n = {}, 1, #data
    while i <= n do
        local b1, b2, b3 = data:byte(i), data:byte(i + 1) or 0, data:byte(i + 2) or 0
        local v = b1 * 65536 + b2 * 256 + b3
        out[#out + 1] = B64_ALPHABET:sub(math.floor(v / 262144) % 64 + 1, math.floor(v / 262144) % 64 + 1)
        out[#out + 1] = B64_ALPHABET:sub(math.floor(v / 4096) % 64 + 1, math.floor(v / 4096) % 64 + 1)
        if data:byte(i + 1) then out[#out + 1] = B64_ALPHABET:sub(math.floor(v / 64) % 64 + 1, math.floor(v / 64) % 64 + 1) end
        if data:byte(i + 2) then out[#out + 1] = B64_ALPHABET:sub(v % 64 + 1, v % 64 + 1) end
        i = i + 3
    end
    return table.concat(out)
end

local function B64Decode(str)
    str = (str or ""):gsub("%s+", "")
    local lut = {}
    for i = 1, #B64_ALPHABET do lut[B64_ALPHABET:sub(i, i)] = i - 1 end
    local out, buffer, bits = {}, 0, 0
    for i = 1, #str do
        local v = lut[str:sub(i, i)]
        if v == nil then return nil, "caractere inválido: '" .. str:sub(i, i) .. "'" end
        buffer = buffer * 64 + v
        bits = bits + 6
        if bits >= 8 then
            bits = bits - 8
            out[#out + 1] = string.char(math.floor(buffer / (2 ^ bits)) % 256)
            buffer = buffer % (2 ^ bits)
        end
    end
    return table.concat(out)
end

-- Exporta a rotação efetiva de um spec como string de compartilhamento.
function s.ExportRotationString(moduleAddon, moduleName, specKey)
    local specs = type(moduleAddon) == "table" and moduleAddon.RotationSpecs
    local spec = specs and specs[specKey]
    if not spec then return nil, "spec desconhecido: " .. tostring(specKey) end
    local effective = GetEffective(spec, moduleName, specKey)
    local lines = { "SFR1", moduleName .. "|" .. specKey }
    for _, n in ipairs(effective) do
        local f = n.filter or {}
        lines[#lines + 1] = table.concat({ n.id, n.enabled == false and "0" or "1", n.condition or "",
            string.format("%d,%d,%d,%d,%d,%d", tonumber(f.combat) or 0, tonumber(f.env) or 0, tonumber(f.target) or 0, tonumber(f.range) or 0, tonumber(f.resource) or 0, tonumber(f.aoe) or 0) }, "|")
    end
    return "!SFROT-1!" .. B64Encode(table.concat(lines, "\n"))
end

-- Importa de uma string; substitui a rotação personalizada do spec.
-- Retorna true, msg. Nós desconhecidos são ignorados (com contagem).
function s.ImportRotationString(moduleAddon, moduleName, specKey, data)
    local raw = type(data) == "string" and (data:gsub("%s+", "")) or ""
    local payload = raw:match("^!SFROT%-1!(.+)$")
    if not payload then return false, "prefixo !SFROT-1! não encontrado" end
    local text, err = B64Decode(payload)
    if not text then return false, "decodificação falhou: " .. tostring(err) end
    local lines = {}
    for line in (text .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = line end
    if #lines < 2 or lines[1] ~= "SFR1" then return false, "cabeçalho SFR1 não encontrado" end
    local mName, mSpec = lines[2]:match("^([^|]+)|(.*)$")
    if mName ~= moduleName then return false, "rotação é de outro módulo (" .. tostring(mName) .. ")" end
    if mSpec ~= specKey then return false, "rotação é de outra spec (" .. tostring(mSpec) .. ")" end

    local specs = moduleAddon.RotationSpecs
    local spec = specs and specs[specKey]
    local byID = {}
    for _, n in ipairs(spec.nodes) do byID[n.id] = n end

    local imported, unknown = {}, 0
    for i = 3, #lines do
        local id, onOff, cond, filterStr = lines[i]:match("^([^|]+)|([^|]*)|([^|]*)|(.-)$")
        if id then
            if byID[id] then
                local filter
                if filterStr then
                    local c, e, t, r, sr, a = filterStr:match("^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
                    if c then filter = DeepCopyFilter({ combat = c, env = e, target = t, range = r, resource = sr, aoe = a }) end
                end
                local condition = (cond or "")
                if condition ~= "" and not condition:match("^[%w_%-]+$") then condition = "" end -- segurança: predicados s
                imported[#imported + 1] = { id = id, enabled = onOff ~= "0", condition = condition, filter = filter }
            else
                unknown = unknown + 1
            end
        end
    end
    if #imported == 0 then return false, "nenhum nó reconhecido na string" end

    local db = CharDB()
    db.rotation[moduleName] = db.rotation[moduleName] or {}
    db.rotation[moduleName][specKey] = { v = 1, nodes = imported }
    local msg = "Rotação importada (" .. #imported .. " nós"
    if unknown > 0 then msg = msg .. "; " .. unknown .. " desconhecido(s) ignorado(s)" end
    return true, msg .. ")"
end

-- ---------------------------------------------------------------------------
-- GUI - cards em cadeia (seção colapsável na aba da classe)
-- Cada habilidade mostra ABAIXO dela as condições atuais, e ao lado dela
-- um botão [+] (adicionar condição) e um [-] (remover condição).
-- ---------------------------------------------------------------------------

local ROW_H, ROW_GAP = 44, 2

local function SpellTexture(spellID)
    if C_Spell and type(C_Spell.GetSpellTexture) == "function" then
        local ok, tex = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and tex then return tex end
    end
    if type(GetSpellTexture) == "function" then
        local ok, tex = pcall(GetSpellTexture, spellID)
        if ok and tex then return tex end
    end
    return nil
end

local function PredicateLabel(preds, key)
    if not key or key == "" then return "sempre" end
    local p = preds[key]
    local label = (p and p.label) or key
    if #label > 28 then label = label:sub(1, 24) .. "..." end
    return label
end

local function NodeConditionText(node, preds)
    local parts = {}
    if node.condition and node.condition ~= "" then
        local p = preds and preds[node.condition]
        parts[#parts + 1] = "Espec.: " .. ((p and p.label) or node.condition)
    end
    if type(node.filter) == "table" then
        for _, axis in ipairs(FILTER_AXES) do
            local v = tonumber(node.filter[axis.key])
            if v and v ~= 0 then
                for _, opt in ipairs(axis.options) do
                    if opt[1] == v then parts[#parts + 1] = opt[2] break end
                end
            end
        end
    end
    if #parts == 0 then return "|cff888888- sem condicoes -|r" end
    local text = table.concat(parts, ", ")
    if #text > 60 then text = text:sub(1, 57) .. "..." end
    return "|cffffcc00" .. text .. "|r"
end

local function FilterValue(node, key)
    return tonumber(node.filter and node.filter[key]) or 0
end

local function ToggleFilterValue(node, key, value)
    node.filter = DeepCopyFilter(node.filter) or {}
    if value == 0 then node.filter[key] = nil
    elseif tonumber(node.filter[key]) == value then node.filter[key] = nil
    else node.filter[key] = value end
    if not next(node.filter) then node.filter = nil end
end

function s.BuildRotationEditor(parent, anchorFrame, moduleName, moduleAddon)
    if not parent or not moduleAddon then return nil end
    local specs = moduleAddon.RotationSpecs
    if type(specs) ~= "table" or not next(specs) then return nil end

    local toggle = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    toggle:SetSize(300, 22)
    toggle:SetPoint("TOPLEFT", anchorFrame or parent, "BOTTOMLEFT", 0, -16)
    toggle:SetText("Rotação personalizada +")

    local section = CreateFrame("Frame", nil, parent)
    section:SetPoint("TOPLEFT", toggle, "BOTTOMLEFT", 0, -4)
    section:SetSize(400, 10)
    section:Hide()

    local title = section:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetText("|cff33ff99Rotação da aba (editável)|r")

    local desc = section:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    desc:SetWidth(380)
    desc:SetJustifyH("LEFT")
    desc:SetText("Ordem abaixo = prioridade. Padrao = guia do projeto; mudancas salvas por personagem. Toque em + para adicionar condicao, em - para remover. Use as setas ^ e v para subir/descer; o check liga/desliga; clicar no icone testa o flash.")

    local state = { specKey = nil }
    for specKey in pairs(specs) do state.specKey = state.specKey or specKey end

    -- botões de spec — quebra em várias linhas quando muitos specs (até 5 specs: 400px)
    local specButtons = {}
    local sx, sy = 0, 0
    local BTN_W = 120
    local GAP = 4
    local MAX_W = 400
    for specKey, spec in pairs(specs) do
        if sx + BTN_W > MAX_W then
            sx = 0
            sy = sy - 24 -- próxima linha de botões
        end
        local btn = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
        btn:SetSize(BTN_W, 20)
        btn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", sx, -8 + sy)
        btn:SetText(spec.title or specKey)
        btn.specKey = specKey
        specButtons[specKey] = btn
        sx = sx + (BTN_W + GAP)
    end

    -- host dos cards — ancorado abaixo dos botões de spec (que pode ter quebrado em linhas)
    local cardsHost = CreateFrame("Frame", nil, section)
    cardsHost:SetSize(396, 10)
    cardsHost:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -8 - 22 + sy)

    local cards = {}

    local function SaveOrder()
        local eff = {}
        for i, card in ipairs(cards) do eff[i] = card.node end
        s.SaveEffectiveRotation(moduleName, state.specKey, eff)
    end

    local function Relayout()
        local cy = 0
        for _, card in ipairs(cards) do
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", cardsHost, "TOPLEFT", 0, cy)
            cy = cy - (ROW_H + ROW_GAP)
        end
        cardsHost:SetHeight(math.max(1, -cy) + 4)
    end

    -- ------------------------------------------------------------------
    -- Seletor de condições com ROLAGEM (dropdown próprio; MenuUtil não rola)
    -- ------------------------------------------------------------------
    local pickerSingleton

    local function GetPicker()
        if pickerSingleton then return pickerSingleton end
        local p = CreateFrame("Frame", "SpellFlashForeverRotationPicker", UIParent, "BackdropTemplate")
        p:SetSize(280, 250)
        p:SetFrameStrata("DIALOG")
        p:SetFrameLevel(400)
        p:SetClampedToScreen(true)
        p:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
        local title = p:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        title:SetPoint("TOP", 0, -10)
        p.title = title

        local scroll = CreateFrame("ScrollFrame", nil, p, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 8, -28)
        scroll:SetPoint("BOTTOMRIGHT", -8, 8)
        local child = CreateFrame("Frame", nil, scroll)
        child:SetSize(236, 1)
        scroll:SetScrollChild(child)
        p.child = child
        p.rows = {}
        tinsert(UISpecialFrames, "SpellFlashForeverRotationPicker")
        pickerSingleton = p
        return p
    end

    local function RebuildPickerRows(p, items, afterAction)
        for _, r in ipairs(p.rows) do r:Hide(); r:SetParent(nil) end
        p.rows = {}
        local y = 0
        for _, item in ipairs(items) do
            local row
            if item.header then
                row = CreateFrame("Frame", nil, p.child)
                local fs = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
                fs:SetPoint("LEFT", 4, 0)
                fs:SetWidth(230)
                fs:SetJustifyH("LEFT")
                fs:SetText(item.header)
                row:SetHeight(16)
                row:SetWidth(236)
            else
                row = CreateFrame("Button", nil, p.child)
                row:SetSize(236, 20)
                row:SetHighlightTexture("Interface\\BUTTONS\\ButtonHilight-Square", "ADD")
                local fs = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
                fs:SetPoint("LEFT", 4, 0)
                fs:SetWidth(228)
                fs:SetJustifyH("LEFT")
                fs:SetText((item.checked and "[x] " or "    ") .. item.label)
                row:SetScript("OnClick", function()
                    if item.action then item.action() end
                    if afterAction then afterAction() end
                end)
            end
            row:SetPoint("TOPLEFT", p.child, "TOPLEFT", 0, y)
            y = y + ((item.header and 16 or 20) + 1)
            p.rows[#p.rows + 1] = row
        end
        p.child:SetHeight(math.max(1, -y))
    end

    -- getItems(): devolve a lista ATUAL de itens (marca o que esta ativo)
    local function ShowPicker(anchorBtn, titleText, getItems, afterAction)
        local p = GetPicker()
        if p:IsShown() and p.owner == anchorBtn then p:Hide(); return end
        p.owner = anchorBtn
        p.title:SetText(titleText)
        local function rebuild()
            RebuildPickerRows(p, getItems(), function()
                if afterAction then afterAction() end
                rebuild()
            end)
        end
        rebuild()
        p:ClearAllPoints()
        p:SetPoint("TOPRIGHT", anchorBtn, "TOPLEFT", -2, 8)
        p:Show()
    end

    local function SortedPredicateKeys(preds)
        local keys = {}
        for k in pairs(preds) do keys[#keys + 1] = k end
        table.sort(keys)
        return keys
    end

    local function BuildAddItems(node, preds)
        local items = {}
        local function Header(t) items[#items + 1] = { header = t } end
        local function Item(label, active, action)
            items[#items + 1] = { label = label, checked = active and true or false, action = action }
        end
        for _, axis in ipairs(FILTER_AXES) do
            Header(axis.label)
            for _, opt in ipairs(axis.options) do
                local value, label = opt[1], opt[2]
                if value ~= 0 then
                    Item(label, FilterValue(node, axis.key) == value, function()
                        ToggleFilterValue(node, axis.key, value)
                    end)
                end
            end
        end
        Header("Especial (do guia)")
        Item("- sempre -", (not node.condition or node.condition == ""), function() node.condition = "" end)
        for _, key in ipairs(SortedPredicateKeys(preds)) do
            local pl = preds[key]
            Item((pl and pl.label) or key, node.condition == key, function() node.condition = key end)
        end
        Header("------------------------")
        Item("Apagar todas as condicoes", false, function()
            node.condition = ""
            node.filter = nil
        end)
        return items
    end

    local function BuildRemoveItems(node, preds)
        local items = {}
        local function Header(t) items[#items + 1] = { header = t } end
        local function Item(label, action)
            items[#items + 1] = { label = label, action = action }
        end
        local any = false
        if node.condition and node.condition ~= "" then
            Item("Especial: " .. PredicateLabel(preds, node.condition), function() node.condition = "" end)
            any = true
        end
        if type(node.filter) == "table" then
            for _, axis in ipairs(FILTER_AXES) do
                local v = tonumber(node.filter[axis.key])
                if v and v ~= 0 then
                    for _, opt in ipairs(axis.options) do
                        if opt[1] == v then
                            Item(axis.label .. ": " .. opt[2], function()
                                node.filter[axis.key] = nil
                                if not next(node.filter) then node.filter = nil end
                            end)
                            any = true
                            break
                        end
                    end
                end
            end
        end
        if not any then Header("(nenhuma condicao ativa)") end
        Header("------------------------")
        Item("Apagar todas as condicoes", function()
            node.condition = ""
            node.filter = nil
        end)
        return items
    end

    local function OpenAddMenu(btn, node, refresh)
        local preds = type(moduleAddon.RotationPredicates) == "table" and moduleAddon.RotationPredicates or {}
        ShowPicker(btn, "Adicionar condicao", function()
            return BuildAddItems(node, preds)
        end, refresh)
    end

    local function OpenRemoveMenu(btn, node, refresh)
        local preds = type(moduleAddon.RotationPredicates) == "table" and moduleAddon.RotationPredicates or {}
        ShowPicker(btn, "Remover condicao", function()
            return BuildRemoveItems(node, preds)
        end, refresh)
    end

    local function BuildCards()
        for _, card in ipairs(cards) do
            card:Hide()
            card:SetParent(nil)
        end
        cards = {}

        local spec = specs[state.specKey]
        local nodes = GetEffective(spec, moduleName, state.specKey)
        local preds = type(moduleAddon.RotationPredicates) == "table" and moduleAddon.RotationPredicates or {}

        for _, node in ipairs(nodes) do
            local card = CreateFrame("Frame", nil, cardsHost)
            card:SetSize(392, ROW_H)

            -- linha 1: liga/desliga + ícone + nome + [+][-] + ^v
            local cb = CreateFrame("CheckButton", nil, card, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -2)
            cb:SetSize(17, 17)
            cb:SetChecked(node.enabled ~= false)

            local iconBtn = CreateFrame("Button", nil, card)
            iconBtn:SetSize(21, 21)
            iconBtn:SetPoint("TOPLEFT", cb, "TOPRIGHT", 2, 0)
            local tex = SpellTexture(node.spellID)
            iconBtn:SetNormalTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
            iconBtn:SetPushedTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
            iconBtn:SetHighlightTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark", "ADD")
            iconBtn:GetNormalTexture():SetTexCoord(0.08, 0.92, 0.08, 0.92)
            iconBtn:GetPushedTexture():SetTexCoord(0.08, 0.92, 0.08, 0.92)
            iconBtn:GetHighlightTexture():SetTexCoord(0.08, 0.92, 0.08, 0.92)
            iconBtn:GetNormalTexture():SetDesaturated(node.enabled == false)
            iconBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(tostring(node.name), 1, 1, 1)
                GameTooltip:AddLine("Clique: testa o flash na barra de ação", 0.6, 0.8, 1)
                GameTooltip:Show()
            end)
            iconBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            iconBtn:SetScript("OnClick", function()
                local SFA = _G.SpellFlashAddon
                if not (SFA and SFA.FlashAction) then return end
                -- "Conhecido" vale para o rank ATUAL no livro do jogador; o spellID do
                -- nó pode ser de um rank anterior (mais baixo) que o cliente responde
                -- como "não conhecido". Aceite também pelo nome da magia (minúsculo, como
                -- vem do book/SpellNameToID) — resolução sempre válida no cliente.
                if SFA.IsSpellKnown and node.spellID and not SFA.IsSpellKnown(node.spellID) then
                    local localized = moduleAddon and type(moduleAddon.SpellName) == "function" and moduleAddon.SpellName(node.spellID) or nil
                    local okByName = (node.name and SFA.IsSpellKnown(node.name))
                        or (localized and SFA.IsSpellKnown(localized))
                    if not okByName then
                        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[SF Rot]|r Você não conhece esta magia ainda.")
                        return
                    end
                end
                pcall(SFA.FlashAction, node.spellID, node.color or "Yellow")
            end)

            local nameFS = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            nameFS:SetPoint("TOPLEFT", iconBtn, "TOPRIGHT", 5, -3)
            nameFS:SetWidth(150)
            nameFS:SetJustifyH("LEFT")
            nameFS:SetJustifyV("MIDDLE")
            nameFS:SetText((node.enabled == false and "|cff888888" or "|cffffffff") .. tostring(node.name) .. "|r")

            local addBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
            addBtn:SetSize(28, 20)
            addBtn:SetPoint("TOPLEFT", card, "TOPLEFT", 202, -1)
            addBtn:SetText("+")

            local removeBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
            removeBtn:SetSize(28, 20)
            removeBtn:SetPoint("LEFT", addBtn, "RIGHT", 3, 0)
            removeBtn:SetText("-")

            local up = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
            up:SetSize(18, 19)
            up:SetPoint("TOPRIGHT", card, "TOPRIGHT", -21, -1)
            up:SetText("^")
            local down = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
            down:SetSize(18, 19)
            down:SetPoint("TOPRIGHT", card, "TOPRIGHT", -1, -1)
            down:SetText("v")

            -- linha 2: condições atuais da habilidade (sempre visível)
            local condFS = card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
            condFS:SetPoint("TOPLEFT", card, "TOPLEFT", 46, -23)
            condFS:SetWidth(340)
            condFS:SetJustifyH("LEFT")
            condFS:SetJustifyV("MIDDLE")
            condFS:SetText(NodeConditionText(node, preds))

            card.node = node
            card.cb = cb
            card.iconBtn = iconBtn
            card.nameFS = nameFS
            card.addBtn = addBtn
            card.removeBtn = removeBtn
            card.condFS = condFS

            local function RefreshColors()
                local nTex = iconBtn:GetNormalTexture()
                if nTex then nTex:SetDesaturated(node.enabled == false) end
                nameFS:SetText((node.enabled == false and "|cff888888" or "|cffffffff") .. tostring(node.name) .. "|r")
            end
            local function RefreshCond()
                condFS:SetText(NodeConditionText(node, preds))
                RefreshColors()
                SaveOrder()
            end
            card.RefreshCond = RefreshCond

            cb:SetScript("OnClick", function(self)
                node.enabled = self:GetChecked() and true or false
                RefreshColors()
                SaveOrder()
            end)

            addBtn:SetScript("OnClick", function(self)
                OpenAddMenu(self, node, RefreshCond)
            end)
            removeBtn:SetScript("OnClick", function(self)
                OpenRemoveMenu(self, node, RefreshCond)
            end)

            up:SetScript("OnClick", function()
                for i, c in ipairs(cards) do
                    if c == card and i > 1 then
                        cards[i], cards[i - 1] = cards[i - 1], cards[i]
                        SaveOrder()
                        Relayout()
                        return
                    end
                end
            end)
            down:SetScript("OnClick", function()
                for i, c in ipairs(cards) do
                    if c == card and i < #cards then
                        cards[i], cards[i + 1] = cards[i + 1], cards[i]
                        SaveOrder()
                        Relayout()
                        return
                    end
                end
            end)

            cards[#cards + 1] = card
        end
        Relayout()
    end

    local function RefreshSpecButtons()
        for key, btn in pairs(specButtons) do
            if key == state.specKey then
                btn:SetText("[" .. (specs[key].title or key) .. "]")
            else
                btn:SetText(specs[key].title or key)
            end
        end
    end

    for key, btn in pairs(specButtons) do
        btn:SetScript("OnClick", function()
            state.specKey = key
            RefreshSpecButtons()
            BuildCards()
        end)
    end

    -- ------------------------------------------------------------------
    -- Rodapé: Restaurar / Gravar / Compartilhar (exportar-importar)
    -- ------------------------------------------------------------------
    local reset = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
    reset:SetSize(150, 22)
    reset:SetPoint("TOPLEFT", cardsHost, "BOTTOMLEFT", 0, -10)
    reset:SetText("Restaurar padrão")
    reset:SetScript("OnClick", function()
        s.ResetRotation(moduleName, state.specKey)
        BuildCards()
    end)

    local saveBtn = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
    saveBtn:SetSize(110, 22)
    saveBtn:SetPoint("TOPLEFT", reset, "BOTTOMLEFT", 0, -6)
    saveBtn:SetText("Gravar rotação")
    saveBtn:SetScript("OnClick", function()
        SaveOrder()
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[SF Rot]|r Rotação gravada (por personagem) para " .. tostring(moduleName) .. " / " .. tostring(state.specKey) .. ".")
    end)

    local shareBtn = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
    shareBtn:SetSize(110, 22)
    shareBtn:SetPoint("LEFT", saveBtn, "RIGHT", 6, 0)
    shareBtn:SetText("Compartilhar")

    local sharePanel = CreateFrame("Frame", nil, section)
    sharePanel:SetPoint("TOPLEFT", saveBtn, "BOTTOMLEFT", 0, -10)
    sharePanel:SetSize(396, 340)
    sharePanel:Hide()

    local shareTitle = sharePanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    shareTitle:SetPoint("TOPLEFT", 0, 0)
    shareTitle:SetText("|cff33ff99Compartilhar rotação|r (formato !SFROT-1!, estilo Hekili)")

    local expLabel = sharePanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    expLabel:SetPoint("TOPLEFT", shareTitle, "BOTTOMLEFT", 0, -8)
    expLabel:SetText("Sua rotação - copie e envie:")

    local exportBox = CreateFrame("EditBox", nil, sharePanel, "InputBoxTemplate")
    exportBox:SetMultiLine(true)
    exportBox:SetAutoFocus(false)
    exportBox:SetFontObject(GameFontHighlightSmall)
    exportBox:SetSize(380, 54)
    exportBox:SetPoint("TOPLEFT", expLabel, "BOTTOMLEFT", 0, -4)
    exportBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local selectAllBtn = CreateFrame("Button", nil, sharePanel, "UIPanelButtonTemplate")
    selectAllBtn:SetSize(120, 18)
    selectAllBtn:SetPoint("TOPLEFT", exportBox, "BOTTOMLEFT", 0, -6)
    selectAllBtn:SetText("Selecionar tudo")
    selectAllBtn:SetScript("OnClick", function()
        exportBox:SetFocus()
        exportBox:HighlightText()
    end)

    local impLabel = sharePanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    impLabel:SetPoint("TOPLEFT", selectAllBtn, "BOTTOMLEFT", 0, -8)
    impLabel:SetText("Importar - cole a rotação de alguém aqui:")

    local importBox = CreateFrame("EditBox", nil, sharePanel, "InputBoxTemplate")
    importBox:SetMultiLine(true)
    importBox:SetAutoFocus(false)
    importBox:SetFontObject(GameFontHighlightSmall)
    importBox:SetSize(380, 54)
    importBox:SetPoint("TOPLEFT", impLabel, "BOTTOMLEFT", 0, -4)
    importBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local importBtn = CreateFrame("Button", nil, sharePanel, "UIPanelButtonTemplate")
    importBtn:SetSize(130, 20)
    importBtn:SetPoint("TOPLEFT", importBox, "BOTTOMLEFT", 0, -6)
    importBtn:SetText("Importar rotação")
    importBtn:SetScript("OnClick", function()
        local text = importBox:GetText()
        local ok, why = false, "falhou"
        pcall(function()
            ok, why = s.ImportRotationString(moduleAddon, moduleName, state.specKey, text)
        end)
        if ok then
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[SF Rot]|r " .. tostring(why))
            importBox:SetText("")
            BuildCards()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SF Rot]|r Importar falhou: " .. tostring(why))
        end
    end)

    local shareHint = sharePanel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    shareHint:SetPoint("TOPLEFT", importBtn, "BOTTOMLEFT", 0, -6)
    shareHint:SetWidth(380)
    shareHint:SetJustifyH("LEFT")
    shareHint:SetText("Importa só a spec desta aba. Nós desconhecidos são ignorados. A importação substitui a sua rotação personalizada atual desta spec (restaurar padrão reverte).")

    shareBtn:SetScript("OnClick", function()
        if sharePanel:IsShown() then
            sharePanel:Hide()
            shareBtn:SetText("Compartilhar")
        else
            local exportStr = s.ExportRotationString(moduleAddon, moduleName, state.specKey)
            exportBox:SetText(exportStr or "")
            sharePanel:Show()
            shareBtn:SetText("Compartilhar -")
        end
    end)

    RefreshSpecButtons()
    BuildCards()

    local expanded = false
    toggle:SetScript("OnClick", function()
        expanded = not expanded
        if expanded then
            section:Show()
            toggle:SetText("Rotação personalizada -")
        else
            section:Hide()
            toggle:SetText("Rotação personalizada +")
        end
    end)

    return section
end
