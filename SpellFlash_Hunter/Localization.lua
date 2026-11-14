-- SpellFlash_Hunter / Localization.lua
-- Tabela de localização do módulo (extensão Forever).
local AddonName, AddonTable = ...
local L = setmetatable({}, { __index = function(_, key) return key end })
AddonTable.Localize = L

local SFBF = _G["SpellFlashForever"] -- SpellFlashForever carrega antes (Dependency)

-- Os utilitários SpellName/SafeInteractDistance/SafeUnitIsUnit/GetNumPartyMembers/
-- GetNumRaidMembers migraram para o SpellFlashForever (SharedFunctions.lua, H-0083).
-- Sistema racial/trinket vive no core (SpellFlashForever/RacialHandler.lua, H-0084) — H-0084
AddonTable.ShouldUseRacial = SFBF and SFBF.ShouldUseRacial
AddonTable.ShouldUseTrinket = SFBF and SFBF.ShouldUseTrinket
AddonTable.GetDetectedRace = SFBF and SFBF.GetDetectedRace
AddonTable.ShowRacialInfo = SFBF and SFBF.ShowRacialInfo
AddonTable.SpellNameToID = (SFBF and SFBF.SpellNameToID) or {}
AddonTable.SpellName = SFBF and SFBF.SpellName
AddonTable.SafeInteractDistance = SFBF and SFBF.SafeInteractDistance
AddonTable.SafeUnitIsUnit = SFBF and SFBF.SafeUnitIsUnit
AddonTable.GetNumPartyMembers = SFBF and SFBF.GetNumPartyMembers
AddonTable.GetNumRaidMembers = SFBF and SFBF.GetNumRaidMembers

if GetLocale() == "frFR" then -- French


elseif GetLocale() == "deDE" then -- German


elseif GetLocale() == "koKR" then -- Korean


elseif GetLocale() == "esMX" then -- Latin American Spanish


elseif GetLocale() == "ruRU" then -- Russian


elseif GetLocale() == "zhCN" then -- Simplified Chinese


elseif GetLocale() == "esES" then -- Spanish


elseif GetLocale() == "zhTW" then -- Traditional Chinese

end
