-- Normal-mode-only numeric overrides. Shared rescue definitions stay intact.
UPDATE ModifierArguments SET Value='15'
 WHERE ModifierId='LOTM_RP_MOD_HUNTER_COMBAT' AND Name='Amount';
UPDATE ModifierArguments SET Value='20'
 WHERE ModifierId='LOTM_RP_MOD_PROVOKER_GARRISON_STRENGTH' AND Name='Amount';
UPDATE ModifierArguments SET Value='20'
 WHERE ModifierId='LOTM_RP_MOD_IRONBLOOD_FRIENDLY_STRENGTH_EFFECT_V2' AND Name='Amount';
