-- Normal-mode late pass. Defaults preserve every original owner requirement.
-- Only an explicit synchronized removal gives its player a blocking resource.
CREATE TABLE IF NOT EXISTS LOTM_TP_RemovableModifiers (
 ModifierId TEXT PRIMARY KEY, ResourceType TEXT NOT NULL,
 GateRequirement TEXT NOT NULL, GateSet TEXT NOT NULL, OriginalOwnerSet TEXT);
INSERT OR IGNORE INTO LOTM_TP_RemovableModifiers
SELECT DISTINCT m.ModifierId,'RESOURCE_LOTM_TP_REMOVED_'||m.ModifierId,
 'LOTM_TP_KEEP_'||m.ModifierId,'LOTM_TP_KEEP_SET_'||m.ModifierId,m.OwnerRequirementSetId
FROM CivilizationTraits ct JOIN Traits t USING(TraitType)
JOIN TraitModifiers tm USING(TraitType) JOIN Modifiers m USING(ModifierId)
WHERE COALESCE(t.Description,'')<>''
AND NOT EXISTS(SELECT 1 FROM Units WHERE TraitType=t.TraitType)
AND NOT EXISTS(SELECT 1 FROM Buildings WHERE TraitType=t.TraitType)
AND NOT EXISTS(SELECT 1 FROM Districts WHERE TraitType=t.TraitType)
AND NOT EXISTS(SELECT 1 FROM Improvements WHERE TraitType=t.TraitType);
INSERT OR IGNORE INTO Types(Type,Kind)
 SELECT ResourceType,'KIND_RESOURCE' FROM LOTM_TP_RemovableModifiers;
INSERT OR IGNORE INTO Resources(ResourceType,Name,ResourceClassType,Frequency,SeaFrequency,LakeEligible)
 SELECT ResourceType,'LOC_LOTM_TP_REMOVED_ABILITY','RESOURCECLASS_BONUS',0,0,0 FROM LOTM_TP_RemovableModifiers;
INSERT OR IGNORE INTO Requirements(RequirementId,RequirementType,Inverse)
 SELECT GateRequirement,'REQUIREMENT_PLAYER_HAS_RESOURCE_OWNED',1 FROM LOTM_TP_RemovableModifiers;
INSERT OR IGNORE INTO RequirementArguments(RequirementId,Name,Value)
 SELECT GateRequirement,'ResourceType',ResourceType FROM LOTM_TP_RemovableModifiers;
INSERT OR IGNORE INTO RequirementSets(RequirementSetId,RequirementSetType)
 SELECT GateSet,'REQUIREMENTSET_TEST_ALL' FROM LOTM_TP_RemovableModifiers;
INSERT OR IGNORE INTO RequirementSetRequirements(RequirementSetId,RequirementId)
 SELECT GateSet,GateRequirement FROM LOTM_TP_RemovableModifiers;
INSERT OR IGNORE INTO Requirements(RequirementId,RequirementType)
 SELECT GateRequirement||'_ORIGINAL','REQUIREMENT_REQUIREMENTSET_IS_MET'
 FROM LOTM_TP_RemovableModifiers WHERE OriginalOwnerSet IS NOT NULL;
INSERT OR IGNORE INTO RequirementArguments(RequirementId,Name,Value)
 SELECT GateRequirement||'_ORIGINAL','RequirementSetId',OriginalOwnerSet
 FROM LOTM_TP_RemovableModifiers WHERE OriginalOwnerSet IS NOT NULL;
INSERT OR IGNORE INTO RequirementSetRequirements(RequirementSetId,RequirementId)
 SELECT GateSet,GateRequirement||'_ORIGINAL' FROM LOTM_TP_RemovableModifiers WHERE OriginalOwnerSet IS NOT NULL;
UPDATE Modifiers SET OwnerRequirementSetId=(SELECT GateSet FROM LOTM_TP_RemovableModifiers r WHERE r.ModifierId=Modifiers.ModifierId)
 WHERE ModifierId IN (SELECT ModifierId FROM LOTM_TP_RemovableModifiers);
