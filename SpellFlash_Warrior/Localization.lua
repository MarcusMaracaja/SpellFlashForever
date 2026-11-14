-- SpellFlash_Warrior / Localization.lua
-- Tabela L + delegações para o core (SharedFunctions / RacialHandler).
local AddonName, AddonTable = ...
local L = setmetatable({}, { __index = function(_, key) return key end })
AddonTable.Localize = L

local SFBF = _G["SpellFlashForever"] -- SpellFlashForever carrega antes (Dependency)

-- Utilitários genéricos vivem no core (SharedFunctions.lua / RacialHandler.lua) — delegar.
AddonTable.SpellNameToID = (SFBF and SFBF.SpellNameToID) or {}
AddonTable.SpellName = SFBF and SFBF.SpellName
AddonTable.ItemName = SFBF and SFBF.ItemName
AddonTable.HighestKnownRank = SFBF and SFBF.HighestKnownRank
AddonTable.ActionSlotRange = SFBF and SFBF.ActionSlotRange
AddonTable.TargetDistance = SFBF and SFBF.TargetDistance
AddonTable.SafeInteractDistance = SFBF and SFBF.SafeInteractDistance
AddonTable.SafeUnitIsUnit = SFBF and SFBF.SafeUnitIsUnit
AddonTable.GetNumPartyMembers = SFBF and SFBF.GetNumPartyMembers
AddonTable.GetNumRaidMembers = SFBF and SFBF.GetNumRaidMembers
AddonTable.IsTargetEnemyPlayer = SFBF and SFBF.IsTargetEnemyPlayer
AddonTable.IsTargetInterruptibleCasting = SFBF and SFBF.IsTargetInterruptibleCasting
AddonTable.IsTargetImmune = SFBF and SFBF.IsTargetImmune
AddonTable.IsInMeleeRange = SFBF and SFBF.IsInMeleeRange

-- Sistema racial/trinket vive no core (RacialHandler.lua)
AddonTable.ShouldUseRacial = SFBF and SFBF.ShouldUseRacial
AddonTable.ShouldUseTrinket = SFBF and SFBF.ShouldUseTrinket
AddonTable.GetDetectedRace = SFBF and SFBF.GetDetectedRace
AddonTable.ShowRacialInfo = SFBF and SFBF.ShowRacialInfo

if GetLocale() == "frFR" then -- French


elseif GetLocale() == "deDE" then -- German


elseif GetLocale() == "koKR" then -- Korean


elseif GetLocale() == "esMX" then -- Latin American Spanish


elseif GetLocale() == "ruRU" then -- Russian


elseif GetLocale() == "zhCN" then -- Simplified Chinese


elseif GetLocale() == "esES" then -- Spanish


elseif GetLocale() == "zhTW" then -- Traditional Chinese

end
