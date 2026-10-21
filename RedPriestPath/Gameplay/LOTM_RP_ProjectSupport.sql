-- MODIFIER_PLAYER_ALLOW_PROJECT is a Firaxis dynamic modifier introduced by
-- optional official content. Define it idempotently so the Red Priest path
-- works with Gathering Storm alone and also coexists with that content.
INSERT OR IGNORE INTO Types (Type, Kind)
VALUES ('MODIFIER_PLAYER_ALLOW_PROJECT', 'KIND_MODIFIER');

INSERT OR IGNORE INTO DynamicModifiers (ModifierType, CollectionType, EffectType)
VALUES (
	'MODIFIER_PLAYER_ALLOW_PROJECT',
	'COLLECTION_OWNER',
	'EFFECT_ADD_PLAYER_PROJECT_AVAILABILITY'
);
