-- SpellFlash_Warrior / Localization.lua
-- As strings visíveis do módulo vivem no núcleo: SpellFlashForever/Locales.lua (s.L).
-- Aqui ficam apenas a exportação de `L` e a delegação de utilitários do core.
local AddonName, AddonTable = ...

local SFBF = _G["SpellFlashForever"] -- SpellFlashForever carrega antes (Dependency)

local L = (SFBF and SFBF.L) or setmetatable({}, { __index = function(_, key) return key end })
AddonTable.L = L
AddonTable.Localize = L -- legado: o código portado referencia AddonTable.Localize

-- Utilitários genéricos vivem no core (SharedFunctions.lua) — delegar.
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
