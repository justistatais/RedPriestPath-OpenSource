-- Random status abilities and polarity-split one-player-turn artifact leases.
INSERT OR IGNORE INTO Types (Type,Kind) VALUES
('ABILITY_LOTM_WORLD_HOLDER_GOOD','KIND_ABILITY'),
('ABILITY_LOTM_WORLD_HOLDER_UNSTABLE','KIND_ABILITY');

INSERT OR IGNORE INTO UnitAbilities (UnitAbilityType,Name,Description,Inactive) VALUES
('ABILITY_LOTM_WORLD_HOLDER_GOOD','LOC_LOTM_WORLD_EVENT_HOLDER_GOOD','LOC_LOTM_WORLD_EVENT_HOLDER_GOOD_DESC',1),
('ABILITY_LOTM_WORLD_HOLDER_UNSTABLE','LOC_LOTM_WORLD_EVENT_HOLDER_UNSTABLE','LOC_LOTM_WORLD_EVENT_HOLDER_UNSTABLE_DESC',1);

INSERT OR IGNORE INTO TypeTags (Type,Tag) VALUES
('ABILITY_LOTM_WORLD_HOLDER_GOOD','CLASS_RECON'),
('ABILITY_LOTM_WORLD_HOLDER_UNSTABLE','CLASS_RECON');

INSERT OR IGNORE INTO Modifiers (ModifierId,ModifierType,Permanent) VALUES
('LOTM_WORLD_HOLDER_GOOD_STRENGTH','MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH',0),
('LOTM_WORLD_HOLDER_GOOD_MOVE','MODIFIER_UNIT_ADJUST_MOVEMENT',0),
('LOTM_WORLD_HOLDER_UNSTABLE_STRENGTH','MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH',0),
('LOTM_WORLD_HOLDER_UNSTABLE_MOVE','MODIFIER_UNIT_ADJUST_MOVEMENT',0);

INSERT OR IGNORE INTO ModifierArguments (ModifierId,Name,Value) VALUES
('LOTM_WORLD_HOLDER_GOOD_STRENGTH','Amount','5'),
('LOTM_WORLD_HOLDER_GOOD_MOVE','Amount','1'),
('LOTM_WORLD_HOLDER_UNSTABLE_STRENGTH','Amount','-5'),
('LOTM_WORLD_HOLDER_UNSTABLE_MOVE','Amount','-1');

INSERT OR IGNORE INTO UnitAbilityModifiers (UnitAbilityType,ModifierId) VALUES
('ABILITY_LOTM_WORLD_HOLDER_GOOD','LOTM_WORLD_HOLDER_GOOD_STRENGTH'),
('ABILITY_LOTM_WORLD_HOLDER_GOOD','LOTM_WORLD_HOLDER_GOOD_MOVE'),
('ABILITY_LOTM_WORLD_HOLDER_UNSTABLE','LOTM_WORLD_HOLDER_UNSTABLE_STRENGTH'),
('ABILITY_LOTM_WORLD_HOLDER_UNSTABLE','LOTM_WORLD_HOLDER_UNSTABLE_MOVE');

-- Match the mod's existing Hunter/Provoker combat-preview presentation.
INSERT OR IGNORE INTO ModifierStrings (ModifierId,Context,Text) VALUES
('LOTM_WORLD_HOLDER_GOOD_STRENGTH','Preview','LOC_LOTM_WORLD_PREVIEW_HOLDER_GOOD_STRENGTH'),
('LOTM_WORLD_HOLDER_UNSTABLE_STRENGTH','Preview','LOC_LOTM_WORLD_PREVIEW_HOLDER_UNSTABLE_STRENGTH');

CREATE TABLE IF NOT EXISTS LOTM_ArtifactTurnLeases81 (
 ArtifactType TEXT PRIMARY KEY NOT NULL,
 PositiveResourceType TEXT NOT NULL UNIQUE,
 NegativeResourceType TEXT NOT NULL UNIQUE,
 PositiveRequirementId TEXT NOT NULL UNIQUE,
 NegativeRequirementId TEXT NOT NULL UNIQUE,
 PositiveRequirementSetId TEXT NOT NULL UNIQUE,
 NegativeRequirementSetId TEXT NOT NULL UNIQUE,
 LegacyRequirementSetId TEXT NOT NULL UNIQUE
);

INSERT OR REPLACE INTO LOTM_ArtifactTurnLeases81
SELECT ArtifactType,LeaseResourceType||'_POS',LeaseResourceType||'_NEG',
 LeaseRequirementId||'_POS',LeaseRequirementId||'_NEG',
 LeaseRequirementSetId||'_POS',LeaseRequirementSetId||'_NEG',LegacyRequirementSetId
FROM LOTM_ArtifactTurnLeases76;

INSERT OR IGNORE INTO Types (Type,Kind)
SELECT PositiveResourceType,'KIND_RESOURCE' FROM LOTM_ArtifactTurnLeases81
UNION ALL SELECT NegativeResourceType,'KIND_RESOURCE' FROM LOTM_ArtifactTurnLeases81;

INSERT OR IGNORE INTO Resources (ResourceType,Name,ResourceClassType,Frequency,LakeEligible)
SELECT PositiveResourceType,'LOC_LOTM_PP_ARTIFACTS_TITLE','RESOURCECLASS_BONUS',0,0 FROM LOTM_ArtifactTurnLeases81
UNION ALL SELECT NegativeResourceType,'LOC_LOTM_PP_ARTIFACTS_TITLE','RESOURCECLASS_BONUS',0,0 FROM LOTM_ArtifactTurnLeases81;

INSERT OR IGNORE INTO Requirements (RequirementId,RequirementType)
SELECT PositiveRequirementId,'REQUIREMENT_PLAYER_HAS_RESOURCE_OWNED' FROM LOTM_ArtifactTurnLeases81
UNION ALL SELECT NegativeRequirementId,'REQUIREMENT_PLAYER_HAS_RESOURCE_OWNED' FROM LOTM_ArtifactTurnLeases81;

INSERT OR IGNORE INTO RequirementArguments (RequirementId,Name,Value)
SELECT PositiveRequirementId,'ResourceType',PositiveResourceType FROM LOTM_ArtifactTurnLeases81
UNION ALL SELECT NegativeRequirementId,'ResourceType',NegativeResourceType FROM LOTM_ArtifactTurnLeases81;

INSERT OR IGNORE INTO RequirementSets (RequirementSetId,RequirementSetType)
SELECT PositiveRequirementSetId,'REQUIREMENTSET_TEST_ALL' FROM LOTM_ArtifactTurnLeases81
UNION ALL SELECT NegativeRequirementSetId,'REQUIREMENTSET_TEST_ALL' FROM LOTM_ArtifactTurnLeases81;

INSERT OR IGNORE INTO RequirementSetRequirements (RequirementSetId,RequirementId)
SELECT PositiveRequirementSetId,PositiveRequirementId FROM LOTM_ArtifactTurnLeases81
UNION ALL SELECT NegativeRequirementSetId,NegativeRequirementId FROM LOTM_ArtifactTurnLeases81;

-- Every modifier is assigned explicitly by semantic polarity. Scripted effects
-- use the same split in LOTM_PP_Artifacts.lua.
CREATE TABLE IF NOT EXISTS LOTM_ArtifactModifierPolarity81 (
 ModifierId TEXT PRIMARY KEY NOT NULL,
 ArtifactType TEXT NOT NULL,
 Polarity TEXT NOT NULL CHECK (Polarity IN ('POS','NEG'))
);

INSERT OR REPLACE INTO LOTM_ArtifactModifierPolarity81
SELECT modifier.ModifierId,COALESCE(ownerMap.ArtifactType,subjectMap.ArtifactType),
 CASE WHEN modifier.ModifierId LIKE 'LOTM_PP_FX_GOLDEN_GPP%'
  OR modifier.ModifierId IN (
   'LOTM_PP_FX_GEAR_FOOD','LOTM_PP_FX_ASTROLABE_FAITH','LOTM_PP_FX_ASTROLABE_CULTURE',
   'LOTM_PP_FX_FURNACE_GOLD','LOTM_PP_FX_FURNACE_AMENITY','LOTM_PP_FX_BLUEPRINT_FOOD',
   'LOTM_PP_FX_BLUEPRINT_GROWTH','LOTM_PP_FX_CASKET_CULTURE','LOTM_PP_FX_STELE_PRODUCTION',
   'LOTM_RP_ART_EMBER_AMENITY','LOTM_RP_ART_LETTER_PEACE_GOLD','LOTM_RP_ART_BANNER_GOLD',
   'LOTM_RP_ART_SCRIPTURE_PEACE_PRODUCTION','LOTM_RP_ART_WEATHER_FOOD','LOTM_RP_ART_WEATHER_AMENITY',
   'LOTM_RP_ART_CROWN_DEFENSE','LOTM_BE_ART_BRIBE_DOMESTIC_FOOD',
    'LOTM_BE_ART_BRIBE_DOMESTIC_PRODUCTION','LOTM_BE_ART_BRIBE_LEGACY_FOOD_COMPENSATION',
    'LOTM_BE_ART_BRIBE_LEGACY_PRODUCTION_COMPENSATION','LOTM_BE_ART_BRIBE_ZERO_ALL_FOOD',
    'LOTM_BE_ART_BRIBE_ZERO_ALL_PRODUCTION','LOTM_BE_ART_BRIBE_RESTORE_INTERNATIONAL_FOOD',
    'LOTM_BE_ART_BRIBE_RESTORE_INTERNATIONAL_PRODUCTION',
    'LOTM_BE_ART_BRIBE_LEGACY_FOOD_COMPENSATION_CANCEL_237',
    'LOTM_BE_ART_BRIBE_LEGACY_PRODUCTION_COMPENSATION_CANCEL_237',
    'LOTM_BE_ART_BRIBE_ZERO_DESTINATION_FOOD_237',
    'LOTM_BE_ART_BRIBE_ZERO_DESTINATION_PRODUCTION_237','LOTM_BE_ART_TAX_CULTURE',
   'LOTM_BE_ART_ENTROPY_CULTURE','LOTM_BE_ART_ORDER_PRODUCTION',
   'LOTM_BE_ART_CODEX_GOLD_FLAT','LOTM_BE_ART_FEAST_GOLD_FLAT',
   'LOTM_BE_ART_FRENZY_GOLD_FLAT','LOTM_PP_FX_STELE_GOLD_FLAT')
  OR modifier.ModifierId LIKE 'LOTM_BE_ART_BRIBE_CANCEL_DISTRICT_%_238'
  OR modifier.ModifierId LIKE 'LOTM_BE_ART_BRIBE_RESTORE_DISTRICT_%_239'
  OR modifier.ModifierId IN ('LOTM_BE_ART_BRIBE_DOMESTIC_FOOD_FIXED_239','LOTM_BE_ART_BRIBE_DOMESTIC_PRODUCTION_FIXED_239')
 THEN 'NEG' ELSE 'POS' END
FROM Modifiers modifier
LEFT JOIN LOTM_ArtifactTurnLeases76 ownerMap ON ownerMap.LegacyRequirementSetId=modifier.OwnerRequirementSetId
LEFT JOIN LOTM_ArtifactTurnLeases76 subjectMap ON subjectMap.LegacyRequirementSetId=modifier.SubjectRequirementSetId
WHERE (modifier.ModifierId LIKE 'LOTM_PP_FX_%' OR modifier.ModifierId LIKE 'LOTM_RP_ART_%' OR modifier.ModifierId LIKE 'LOTM_BE_ART_%')
 AND modifier.ModifierId NOT LIKE '%_LEASE%' AND modifier.ModifierId NOT LIKE '%_COUNTER'
 AND (ownerMap.ArtifactType IS NOT NULL OR subjectMap.ArtifactType IS NOT NULL);

INSERT OR IGNORE INTO Modifiers
 (ModifierId,ModifierType,RunOnce,Permanent,OwnerRequirementSetId,SubjectRequirementSetId)
SELECT modifier.ModifierId||'_LEASE81_'||polarity.Polarity,modifier.ModifierType,0,0,
 CASE WHEN ownerMap.ArtifactType IS NULL THEN modifier.OwnerRequirementSetId
      WHEN polarity.Polarity='NEG' THEN lease.NegativeRequirementSetId ELSE lease.PositiveRequirementSetId END,
 CASE WHEN subjectMap.ArtifactType IS NULL THEN modifier.SubjectRequirementSetId
      WHEN polarity.Polarity='NEG' THEN lease.NegativeRequirementSetId ELSE lease.PositiveRequirementSetId END
FROM LOTM_ArtifactModifierPolarity81 polarity
JOIN Modifiers modifier ON modifier.ModifierId=polarity.ModifierId
JOIN LOTM_ArtifactTurnLeases81 lease ON lease.ArtifactType=polarity.ArtifactType
LEFT JOIN LOTM_ArtifactTurnLeases76 ownerMap ON ownerMap.LegacyRequirementSetId=modifier.OwnerRequirementSetId
LEFT JOIN LOTM_ArtifactTurnLeases76 subjectMap ON subjectMap.LegacyRequirementSetId=modifier.SubjectRequirementSetId;

INSERT OR IGNORE INTO ModifierArguments (ModifierId,Name,Value)
SELECT arguments.ModifierId||'_LEASE81_'||polarity.Polarity,arguments.Name,arguments.Value
FROM LOTM_ArtifactModifierPolarity81 polarity
JOIN ModifierArguments arguments ON arguments.ModifierId=polarity.ModifierId;
