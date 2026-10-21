-- Normal mode only. Native nuclear resolution, with no new fallout.
INSERT OR IGNORE INTO Types(Type,Kind) VALUES
 ('WMD_LOTM_LIGHTNING_STORM','KIND_WMD'),
 ('UNIT_LOTM_STORM_MANIFESTATION','KIND_UNIT');
INSERT OR REPLACE INTO WMDs
 (WeaponType,Name,BlastRadius,FalloutDuration,AffectPopulation,AffectImprovements,
  AffectBuildings,AffectUnits,AffectResources,AffectRoutes,ICBMStrikeRange,Maintenance)
 SELECT 'WMD_LOTM_LIGHTNING_STORM','LOC_LOTM_STORM_NAME',BlastRadius,0,
  AffectPopulation,AffectImprovements,AffectBuildings,AffectUnits,AffectResources,
  AffectRoutes,999,0 FROM WMDs WHERE WeaponType='WMD_NUCLEAR_DEVICE';

-- Legacy definition only: resource428 prepared saves need exact-ID cleanup.
-- New casts use the city's native ICBM command and never create this unit.
-- Keep the old definition stable for saved native objects.
INSERT OR REPLACE INTO Units
 (UnitType,Name,Description,BaseSightRange,BaseMoves,Combat,RangedCombat,Range,
  Bombard,Domain,FormationClass,Cost,CanCapture,CanTrain,Maintenance,Stackable,
  WMDCapable,IgnoreMoves,CanEarnExperience,PromotionClass,ZoneOfControl)
 SELECT 'UNIT_LOTM_STORM_MANIFESTATION','LOC_LOTM_STORM_NAME',
  'LOC_LOTM_STORM_DESCRIPTION',0,1,Combat,0,999,0,Domain,FormationClass,1,
  0,0,0,1,1,1,0,PromotionClass,0 FROM Units WHERE UnitType='UNIT_BOMBER';
