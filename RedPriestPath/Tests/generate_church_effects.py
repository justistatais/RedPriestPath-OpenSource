#!/usr/bin/env python3
"""Generate rc.83 church modifier bundles from compact, reviewable effect vectors."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Gameplay" / "LOTM_WORLD_Churches.sql"

# (modifier type, arguments, optional subject requirement set, preview text)
Effect = tuple[str, dict[str, object], str | None, str | None]


def city_yield(yield_type: str, amount: int, req: str | None = None) -> Effect:
    return ("MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER", {"YieldType": yield_type, "Amount": amount}, req, None)


def capital_yield(yield_type: str, amount: int) -> Effect:
    return ("MODIFIER_PLAYER_CAPITAL_CITY_ADJUST_CITY_YIELD_CHANGE", {"YieldType": yield_type, "Amount": amount}, None, None)


def trade(yield_type: str, amount: int) -> Effect:
    return ("MODIFIER_PLAYER_ADJUST_TRADE_ROUTE_YIELD", {"YieldType": yield_type, "Amount": amount}, None, None)


def harbor_origin_trade(yield_type: str, amount: int) -> Effect:
    return ("MODIFIER_PLAYER_CITIES_ADJUST_TRADE_ROUTE_YIELD_TO_OTHERS", {"YieldType": yield_type, "Amount": amount}, "LOTM_CHURCH_REQSET_CITY_HAS_HARBOR", None)


def unit(amount: int, kind: str, req: str | None = None, text: str | None = None) -> Effect:
    types = {"MOVE": "MODIFIER_PLAYER_UNITS_ADJUST_MOVEMENT", "SIGHT": "MODIFIER_PLAYER_UNIT_ADJUST_SIGHT", "COMBAT": "MODIFIER_PLAYER_UNITS_ADJUST_COMBAT_STRENGTH"}
    # MODIFIER_PLAYER_UNIT_ADJUST_SIGHT uses COLLECTION_OWNER: it is valid on
    # a promotion/unit ability, but does not enumerate units when attached
    # directly to a player.  Preserve zero-valued legacy slots and let the
    # synchronized Fool unit-ability reconciler apply real sight values.
    effective_amount = 0 if kind == "SIGHT" else amount
    return (types[kind], {"Amount": effective_amount}, req, text if kind == "COMBAT" else None)


def night_friendly_combat_slot() -> Effect:
    # Resource 116 put UNIT_IN_OWNER_TERRITORY on the player-combat collection.
    # That collection has no concrete unit/plot subject, so the requirement
    # never resolves in combat.  Keep a zero-valued legacy slot to preserve the
    # generated bundle numbering; synchronized Lua now gives combat units a
    # Firaxis Cossack-style unit ability whose child modifier owns this check.
    return ("MODIFIER_PLAYER_UNITS_ADJUST_COMBAT_STRENGTH", {"Amount": 0}, None, None)


def amenities(amount: int, req: str | None = None) -> Effect:
    return ("MODIFIER_PLAYER_CITIES_ADJUST_POLICY_AMENITY", {"Amount": amount}, req, None)


def loyalty(amount: int) -> Effect:
    return ("MODIFIER_PLAYER_CITIES_ADJUST_IDENTITY_PER_TURN", {"Amount": amount}, None, None)


def gp(amount: int) -> Effect:
    return ("MODIFIER_PLAYER_ADJUST_GREAT_PERSON_POINTS_PERCENT", {"Amount": amount}, None, None)


def maintenance(amount: int) -> Effect:
    return ("MODIFIER_PLAYER_ADJUST_UNIT_MAINTENANCE_DISCOUNT", {"Amount": amount}, None, None)


def city_defense(amount: int) -> Effect:
    # Firaxis' stock type is COLLECTION_OWNER because the Palace/Victor owns it
    # as a concrete city.  Church bundles are attached to a player, so enumerate
    # that player's cities explicitly while reusing the same city-defense effect.
    return ("MODIFIER_LOTM_CHURCH_PLAYER_CITIES_ADJUST_INNER_DEFENSE", {"Amount": amount}, None, None)


def district_yield(yield_type: str, amount: int, req: str) -> Effect:
    return ("MODIFIER_PLAYER_DISTRICTS_ADJUST_YIELD_CHANGE", {"YieldType": yield_type, "Amount": amount}, req, None)


def building_yield(building_type: str, yield_type: str, amount: int) -> Effect:
    return ("MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE", {"BuildingType": building_type, "YieldType": yield_type, "Amount": amount}, None, None)


def plot_yield(yield_type: str, amount: int, req: str) -> Effect:
    return ("MODIFIER_PLAYER_ADJUST_PLOT_YIELD", {"YieldType": yield_type, "Amount": amount}, req, None)


def spy_defense(amount: int) -> Effect:
    return ("MODIFIER_PLAYER_ADJUST_SPY_BONUS", {"Offense": "false", "Amount": amount}, None, None)


def naval_production(amount: int) -> list[Effect]:
    # The engine's tag/era production modifier has no "all eras" sentinel.  Emit
    # the complete naval promotion-class x era matrix so raiders, carriers,
    # ranged and melee ships from every ruleset era are covered.
    classes = ("PROMOTION_CLASS_NAVAL_MELEE", "PROMOTION_CLASS_NAVAL_RANGED", "PROMOTION_CLASS_NAVAL_RAIDER", "PROMOTION_CLASS_NAVAL_CARRIER")
    eras = ("ERA_ANCIENT", "ERA_CLASSICAL", "ERA_MEDIEVAL", "ERA_RENAISSANCE", "ERA_INDUSTRIAL", "ERA_MODERN", "ERA_ATOMIC", "ERA_INFORMATION", "ERA_FUTURE")
    return [("MODIFIER_PLAYER_CITIES_ADJUST_UNIT_TAG_ERA_PRODUCTION", {"UnitPromotionClass": unit_class, "EraType": era, "Amount": amount}, None, None) for unit_class in classes for era in eras]


def invert(effects: list[Effect]) -> list[Effect]:
    out: list[Effect] = []
    for modifier_type, args, req, text in effects:
        inverse = dict(args)
        if "Amount" in inverse:
            inverse["Amount"] = -int(inverse["Amount"])
        out.append((modifier_type, inverse, req, text))
    return out


REQ_SCOUT = "LOTM_CHURCH_REQSET_SCOUT"
REQ_NOT_SCOUT = "LOTM_CHURCH_REQSET_NOT_SCOUT"
REQ_NAVAL = "LOTM_CHURCH_REQSET_NAVAL"
REQ_LAND_WATER = "LOTM_CHURCH_REQSET_LAND_ON_WATER"
REQ_OWN = "LOTM_CHURCH_REQSET_OWN_TERRITORY_COMBAT"
REQ_HARBOR = "LOTM_CHURCH_REQSET_CITY_HAS_HARBOR"
REQ_HOLY = "DISTRICT_IS_HOLY_SITE"
REQ_THEATER = "DISTRICT_IS_THEATER"
REQ_OCEAN = "LOTM_CHURCH_REQSET_OCEAN"
REQ_IMPROVED_SEA_BONUS = "LOTM_CHURCH_REQSET_IMPROVED_SEA_BONUS"
REQ_IMPROVED_SEA_LUXURY = "LOTM_CHURCH_REQSET_IMPROVED_SEA_LUXURY"
REQ_IMPROVED_SEA_STRATEGIC = "LOTM_CHURCH_REQSET_IMPROVED_SEA_STRATEGIC"

states: dict[str, list[Effect]] = {}


def permanent(church: str, tier: int, effects: list[Effect]) -> None:
    states[f"LOTM_CHURCH_{church}_PERM_{tier}_ON"] = effects
    states[f"LOTM_CHURCH_{church}_PERM_{tier}_OFF"] = invert(effects)


def blessing(church: str, tier: int, strength: str, effects: list[Effect]) -> None:
    states[f"LOTM_CHURCH_{church}_BLESS_{tier}_{strength}_ON"] = effects
    states[f"LOTM_CHURCH_{church}_BLESS_{tier}_{strength}_OFF"] = invert(effects)


# Permanent effects are absolute bands because Lua replaces the previous band.
fool1 = [capital_yield("YIELD_CULTURE", 4), capital_yield("YIELD_FAITH", 4), unit(1, "MOVE", REQ_SCOUT), unit(2, "SIGHT", REQ_SCOUT), unit(1, "SIGHT", REQ_NOT_SCOUT)]
fool3 = fool1 + [city_yield("YIELD_CULTURE", 5), city_yield("YIELD_GOLD", 5), trade("YIELD_GOLD", 3), trade("YIELD_CULTURE", 1), gp(15)]
fool6 = fool1 + [city_yield("YIELD_CULTURE", 5), city_yield("YIELD_GOLD", 5), trade("YIELD_GOLD", 6), trade("YIELD_CULTURE", 1), gp(35), unit(1, "MOVE"), unit(1, "SIGHT")]
permanent("FOOL", 1, fool1); permanent("FOOL", 3, fool3); permanent("FOOL", 6, fool6)

night1 = [capital_yield("YIELD_FAITH", 4), capital_yield("YIELD_CULTURE", 4), amenities(2, "LOTM_CHURCH_REQSET_CAPITAL_CITY")]
night_districts = [district_yield("YIELD_FAITH", 2, REQ_HOLY), district_yield("YIELD_CULTURE", 2, REQ_THEATER)]
for building in ("BUILDING_SHRINE", "BUILDING_TEMPLE", "BUILDING_PRASAT", "BUILDING_STAVE_CHURCH", "BUILDING_CATHEDRAL", "BUILDING_DAR_E_MEHR", "BUILDING_GURDWARA", "BUILDING_MEETING_HOUSE", "BUILDING_MOSQUE", "BUILDING_PAGODA", "BUILDING_STUPA", "BUILDING_SYNAGOGUE", "BUILDING_WAT"):
    night_districts.append(building_yield(building, "YIELD_FAITH", 2))
for building in ("BUILDING_AMPHITHEATER", "BUILDING_MUSEUM_ART", "BUILDING_MUSEUM_ARTIFACT", "BUILDING_BROADCAST_CENTER", "BUILDING_FILM_STUDIO", "BUILDING_MARAE"):
    night_districts.append(building_yield(building, "YIELD_CULTURE", 2))
night3 = night1 + night_districts + [amenities(1), loyalty(2), night_friendly_combat_slot()]
night6 = night1 + night_districts + [amenities(3), loyalty(5), night_friendly_combat_slot(), spy_defense(1)]
permanent("NIGHT", 1, night1); permanent("NIGHT", 3, night3); permanent("NIGHT", 6, night6)

storm1 = [capital_yield("YIELD_GOLD", 5), capital_yield("YIELD_PRODUCTION", 2), unit(1, "MOVE", REQ_NAVAL), unit(3, "COMBAT", REQ_NAVAL, "LOC_LOTM_CHURCH_STORM_COMBAT_PREVIEW")]
storm_harbor = [district_yield("YIELD_GOLD", 3, "DISTRICT_IS_HARBOR"), district_yield("YIELD_PRODUCTION", 2, "DISTRICT_IS_HARBOR")]
for building in ("BUILDING_LIGHTHOUSE", "BUILDING_SHIPYARD", "BUILDING_SEAPORT"):
    storm_harbor.extend([building_yield(building, "YIELD_GOLD", 2), building_yield(building, "YIELD_PRODUCTION", 1)])
storm_resources=[]
for req in (REQ_IMPROVED_SEA_BONUS,REQ_IMPROVED_SEA_LUXURY,REQ_IMPROVED_SEA_STRATEGIC): storm_resources.extend([plot_yield("YIELD_FOOD",1,req),plot_yield("YIELD_GOLD",2,req)])
storm3 = storm1[:-1] + [unit(5, "COMBAT", REQ_NAVAL, "LOC_LOTM_CHURCH_STORM_COMBAT_PREVIEW")] + storm_harbor + storm_resources
storm6 = [capital_yield("YIELD_GOLD", 5), capital_yield("YIELD_PRODUCTION", 2), unit(2, "MOVE", REQ_NAVAL), unit(10, "COMBAT", REQ_NAVAL, "LOC_LOTM_CHURCH_STORM_COMBAT_PREVIEW")] + storm_harbor + storm_resources + [unit(2, "MOVE", REQ_LAND_WATER), city_yield("YIELD_PRODUCTION", 15, REQ_HARBOR), city_yield("YIELD_GOLD", 15, REQ_HARBOR), harbor_origin_trade("YIELD_GOLD", 8)]
permanent("STORM", 1, storm1); permanent("STORM", 3, storm3); permanent("STORM", 6, storm6)


def fool_effects(values: dict[str, int]) -> list[Effect]:
    effects: list[Effect] = []
    for key, yield_type in (("food", "YIELD_FOOD"), ("production", "YIELD_PRODUCTION"), ("gold", "YIELD_GOLD"), ("science", "YIELD_SCIENCE"), ("culture", "YIELD_CULTURE"), ("faith", "YIELD_FAITH")):
        if values.get(key): effects.append(city_yield(yield_type, values[key]))
    if values.get("gp"): effects.append(gp(values["gp"]))
    if values.get("move"): effects.append(unit(values["move"], "MOVE"))
    if values.get("sight"): effects.append(unit(values["sight"], "SIGHT"))
    if values.get("combat"): effects.append(unit(values["combat"], "COMBAT", None, "LOC_LOTM_CHURCH_FOOL_COMBAT_PREVIEW"))
    if values.get("maintenance"): effects.append(maintenance(values["maintenance"]))
    for key, yield_type in (("trade_gold", "YIELD_GOLD"), ("trade_culture", "YIELD_CULTURE"), ("trade_science", "YIELD_SCIENCE")):
        if values.get(key): effects.append(trade(yield_type, values[key]))
    return effects


blessing("FOOL", 6, "FULL", fool_effects(dict(culture=50, gold=50, gp=100, move=2, sight=2, trade_gold=10)))
blessing("FOOL", 6, "HALF", fool_effects(dict(culture=25, gold=25, gp=50, move=1, sight=1, trade_gold=5)))
blessing("FOOL", 10, "FULL", fool_effects(dict(production=50, culture=75, gold=75, gp=150, move=3, combat=10, maintenance=50, trade_gold=15)))
blessing("FOOL", 10, "HALF", fool_effects(dict(production=25, culture=37, gold=37, gp=75, move=1, combat=5, maintenance=25, trade_gold=7)))
blessing("FOOL", 15, "FULL", fool_effects(dict(food=50, production=100, gold=100, science=50, culture=100, faith=50, gp=300, move=5, combat=20, sight=3, trade_gold=25, trade_culture=5, trade_science=5)))
blessing("FOOL", 15, "HALF", fool_effects(dict(food=25, production=50, gold=50, science=25, culture=50, faith=25, gp=150, move=2, combat=10, sight=1, trade_gold=12, trade_culture=2, trade_science=2)))


def night_effects(culture: int, faith: int, amenity: int, loyalty_value: int, combat: int, move: int = 0, defense: int = 0) -> list[Effect]:
    effects = [city_yield("YIELD_CULTURE", culture), city_yield("YIELD_FAITH", faith), amenities(amenity), loyalty(loyalty_value), night_friendly_combat_slot()]
    if move: effects.append(unit(move, "MOVE", REQ_OWN))
    if defense: effects.append(city_defense(defense))
    return effects


blessing("NIGHT", 6, "FULL", night_effects(50, 50, 5, 20, 15, 1) + [spy_defense(2)]); blessing("NIGHT", 6, "HALF", night_effects(25, 25, 2, 10, 7) + [spy_defense(1)])
blessing("NIGHT", 10, "FULL", night_effects(75, 100, 8, 50, 25, 2)); blessing("NIGHT", 10, "HALF", night_effects(37, 50, 4, 25, 12, 1))
blessing("NIGHT", 15, "FULL", night_effects(150, 200, 15, 99, 40, 3, 20)); blessing("NIGHT", 15, "HALF", night_effects(75, 100, 7, 49, 20, 1, 10))


def storm_effects(combat: int, move: int, production: int, gold: int, trade_gold: int, embarked: int, naval_prod: int = 0, ocean: tuple[int, int, int] | None = None) -> list[Effect]:
    effects = [unit(combat, "COMBAT", REQ_NAVAL, "LOC_LOTM_CHURCH_STORM_COMBAT_PREVIEW"), unit(move, "MOVE", REQ_NAVAL), city_yield("YIELD_PRODUCTION", production, REQ_HARBOR), city_yield("YIELD_GOLD", gold, REQ_HARBOR), harbor_origin_trade("YIELD_GOLD", trade_gold), unit(embarked, "MOVE", REQ_LAND_WATER)]
    if naval_prod: effects.extend(naval_production(naval_prod))
    if ocean:
        effects.extend([plot_yield("YIELD_FOOD", ocean[0], REQ_OCEAN), plot_yield("YIELD_PRODUCTION", ocean[1], REQ_OCEAN), plot_yield("YIELD_GOLD", ocean[2], REQ_OCEAN)])
    return effects


blessing("STORM", 6, "FULL", storm_effects(20, 4, 50, 50, 20, 3)); blessing("STORM", 6, "HALF", storm_effects(10, 2, 25, 25, 10, 1))
blessing("STORM", 10, "FULL", storm_effects(30, 5, 100, 100, 30, 4, ocean=(2,3,5))); blessing("STORM", 10, "HALF", storm_effects(15, 2, 50, 50, 15, 2, ocean=(1,1,2)))
blessing("STORM", 15, "FULL", storm_effects(50, 7, 200, 200, 50, 5, 200, ocean=(3,5,10))); blessing("STORM", 15, "HALF", storm_effects(25, 3, 100, 100, 25, 2, 100, ocean=(1,2,5)))


def sql_quote(value: object) -> str:
    return "'" + str(value).replace("'", "''") + "'"


lines = [
    "-- Generated by Tests/generate_church_effects.py. Do not hand edit.",
    "INSERT OR IGNORE INTO Types(Type,Kind) VALUES ('MODIFIER_LOTM_CHURCH_PLAYER_CITIES_ADJUST_INNER_DEFENSE','KIND_MODIFIER');",
    "INSERT OR IGNORE INTO DynamicModifiers(ModifierType,CollectionType,EffectType) VALUES ('MODIFIER_LOTM_CHURCH_PLAYER_CITIES_ADJUST_INNER_DEFENSE','COLLECTION_PLAYER_CITIES','EFFECT_ADJUST_CITY_INNER_DEFENSE');",
    "INSERT OR REPLACE INTO Colors(Type,Color) VALUES ('COLOR_LOTM_CHURCH_FOOL','245,245,255,255'),('COLOR_LOTM_CHURCH_NIGHT','185,170,255,255'),('COLOR_LOTM_CHURCH_STORM','55,235,225,255');",
    "INSERT OR IGNORE INTO Requirements(RequirementId,RequirementType,Inverse) VALUES",
    "('LOTM_CHURCH_REQ_SCOUT','REQUIREMENT_UNIT_TAG_MATCHES',0),",
    "('LOTM_CHURCH_REQ_NOT_SCOUT','REQUIREMENT_UNIT_TAG_MATCHES',1),",
    "('LOTM_CHURCH_REQ_NAVAL','REQUIREMENT_UNIT_DOMAIN_MATCHES',0),",
    "('LOTM_CHURCH_REQ_LAND','REQUIREMENT_UNIT_DOMAIN_MATCHES',0),",
    "('LOTM_CHURCH_REQ_WATER','REQUIREMENT_PLOT_TERRAIN_CLASS_MATCHES',0),",
    "('LOTM_CHURCH_REQ_OWN','REQUIREMENT_UNIT_IN_OWNER_TERRITORY',0),",
    "('LOTM_CHURCH_REQ_COMBAT','REQUIREMENT_UNIT_FORMATION_CLASS_MATCHES',1),",
    "('LOTM_CHURCH_REQ_HARBOR','REQUIREMENT_CITY_HAS_DISTRICT',0),",
    "('LOTM_CHURCH_REQ_CAPITAL','REQUIREMENT_CITY_IS_ORIGINAL_CAPITAL',0),",
    "('LOTM_CHURCH_REQ_OCEAN','REQUIREMENT_PLOT_TERRAIN_TYPE_MATCHES',0);",
    "INSERT OR IGNORE INTO Requirements(RequirementId,RequirementType) VALUES ('LOTM_CHURCH_REQ_WATER_CLASS','REQUIREMENT_PLOT_TERRAIN_CLASS_MATCHES'),('LOTM_CHURCH_REQ_RESOURCE_BONUS','REQUIREMENT_PLOT_IMPROVED_RESOURCE_CLASS_TYPE_MATCHES'),('LOTM_CHURCH_REQ_RESOURCE_LUXURY','REQUIREMENT_PLOT_IMPROVED_RESOURCE_CLASS_TYPE_MATCHES'),('LOTM_CHURCH_REQ_RESOURCE_STRATEGIC','REQUIREMENT_PLOT_IMPROVED_RESOURCE_CLASS_TYPE_MATCHES');",
    "INSERT OR IGNORE INTO RequirementArguments(RequirementId,Name,Value) VALUES",
    "('LOTM_CHURCH_REQ_SCOUT','Tag','CLASS_RECON'),",
    "('LOTM_CHURCH_REQ_NOT_SCOUT','Tag','CLASS_RECON'),",
    "('LOTM_CHURCH_REQ_NAVAL','DomainType','DOMAIN_SEA'),",
    "('LOTM_CHURCH_REQ_LAND','DomainType','DOMAIN_LAND'),",
    "('LOTM_CHURCH_REQ_WATER','TerrainClass','TERRAIN_CLASS_WATER'),",
    "('LOTM_CHURCH_REQ_COMBAT','FormationClass','FORMATION_CLASS_CIVILIAN'),",
    "('LOTM_CHURCH_REQ_HARBOR','DistrictType','DISTRICT_HARBOR'),",
    "('LOTM_CHURCH_REQ_OCEAN','TerrainType','TERRAIN_OCEAN');",
    "INSERT OR IGNORE INTO RequirementArguments(RequirementId,Name,Value) VALUES ('LOTM_CHURCH_REQ_WATER_CLASS','TerrainClass','TERRAIN_CLASS_WATER'),('LOTM_CHURCH_REQ_RESOURCE_BONUS','ResourceClassType','RESOURCECLASS_BONUS'),('LOTM_CHURCH_REQ_RESOURCE_LUXURY','ResourceClassType','RESOURCECLASS_LUXURY'),('LOTM_CHURCH_REQ_RESOURCE_STRATEGIC','ResourceClassType','RESOURCECLASS_STRATEGIC');",
    "INSERT OR IGNORE INTO RequirementSets(RequirementSetId,RequirementSetType) VALUES",
    "('LOTM_CHURCH_REQSET_SCOUT','REQUIREMENTSET_TEST_ALL'),('LOTM_CHURCH_REQSET_NOT_SCOUT','REQUIREMENTSET_TEST_ALL'),",
    "('LOTM_CHURCH_REQSET_NAVAL','REQUIREMENTSET_TEST_ALL'),('LOTM_CHURCH_REQSET_LAND_ON_WATER','REQUIREMENTSET_TEST_ALL'),",
    "('LOTM_CHURCH_REQSET_OWN_TERRITORY_COMBAT','REQUIREMENTSET_TEST_ALL'),('LOTM_CHURCH_REQSET_CITY_HAS_HARBOR','REQUIREMENTSET_TEST_ALL'),",
    "('LOTM_CHURCH_REQSET_CAPITAL_CITY','REQUIREMENTSET_TEST_ALL'),('LOTM_CHURCH_REQSET_OCEAN','REQUIREMENTSET_TEST_ALL'),('LOTM_CHURCH_REQSET_IMPROVED_SEA_BONUS','REQUIREMENTSET_TEST_ALL'),('LOTM_CHURCH_REQSET_IMPROVED_SEA_LUXURY','REQUIREMENTSET_TEST_ALL'),('LOTM_CHURCH_REQSET_IMPROVED_SEA_STRATEGIC','REQUIREMENTSET_TEST_ALL');",
    "INSERT OR IGNORE INTO RequirementSetRequirements(RequirementSetId,RequirementId) VALUES",
    "('LOTM_CHURCH_REQSET_SCOUT','LOTM_CHURCH_REQ_SCOUT'),('LOTM_CHURCH_REQSET_NOT_SCOUT','LOTM_CHURCH_REQ_NOT_SCOUT'),",
    "('LOTM_CHURCH_REQSET_NAVAL','LOTM_CHURCH_REQ_NAVAL'),('LOTM_CHURCH_REQSET_LAND_ON_WATER','LOTM_CHURCH_REQ_LAND'),('LOTM_CHURCH_REQSET_LAND_ON_WATER','LOTM_CHURCH_REQ_WATER'),",
    "('LOTM_CHURCH_REQSET_OWN_TERRITORY_COMBAT','LOTM_CHURCH_REQ_OWN'),('LOTM_CHURCH_REQSET_OWN_TERRITORY_COMBAT','LOTM_CHURCH_REQ_COMBAT'),",
    "('LOTM_CHURCH_REQSET_CITY_HAS_HARBOR','LOTM_CHURCH_REQ_HARBOR'),('LOTM_CHURCH_REQSET_CAPITAL_CITY','LOTM_CHURCH_REQ_CAPITAL'),('LOTM_CHURCH_REQSET_OCEAN','LOTM_CHURCH_REQ_OCEAN'),('LOTM_CHURCH_REQSET_IMPROVED_SEA_BONUS','LOTM_CHURCH_REQ_WATER_CLASS'),('LOTM_CHURCH_REQSET_IMPROVED_SEA_BONUS','LOTM_CHURCH_REQ_RESOURCE_BONUS'),('LOTM_CHURCH_REQSET_IMPROVED_SEA_LUXURY','LOTM_CHURCH_REQ_WATER_CLASS'),('LOTM_CHURCH_REQSET_IMPROVED_SEA_LUXURY','LOTM_CHURCH_REQ_RESOURCE_LUXURY'),('LOTM_CHURCH_REQSET_IMPROVED_SEA_STRATEGIC','LOTM_CHURCH_REQ_WATER_CLASS'),('LOTM_CHURCH_REQSET_IMPROVED_SEA_STRATEGIC','LOTM_CHURCH_REQ_RESOURCE_STRATEGIC');",
]

modifier_rows: list[str] = []
argument_rows: list[str] = []
string_rows: list[str] = []
for state, effects in sorted(states.items()):
    for number, (modifier_type, args, req, preview) in enumerate(effects, 1):
        modifier_id = f"{state}__{number:03d}"
        modifier_rows.append(f"({sql_quote(modifier_id)},{sql_quote(modifier_type)},{sql_quote(req) if req else 'NULL'},1)")
        for name, value in args.items():
            argument_rows.append(f"({sql_quote(modifier_id)},{sql_quote(name)},{sql_quote(value)})")
        if preview:
            string_rows.append(f"({sql_quote(modifier_id)},'Preview',{sql_quote(preview)})")

lines.append("INSERT OR REPLACE INTO Modifiers(ModifierId,ModifierType,SubjectRequirementSetId,Permanent) VALUES\n" + ",\n".join(modifier_rows) + ";")
lines.append("INSERT OR REPLACE INTO ModifierArguments(ModifierId,Name,Value) VALUES\n" + ",\n".join(argument_rows) + ";")
lines.append("INSERT OR REPLACE INTO ModifierStrings(ModifierId,Context,Text) VALUES\n" + ",\n".join(string_rows) + ";")
lines.append("""-- Fool sight is synchronized through unit abilities.  This mirrors the
-- proven Night-church structure: the ability owns a unit-level sight modifier,
-- so COLLECTION_OWNER is the concrete unit rather than the player object.
INSERT OR IGNORE INTO Types(Type,Kind) VALUES
('ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_1','KIND_ABILITY'),('ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_2','KIND_ABILITY'),('ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_3','KIND_ABILITY'),('ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_4','KIND_ABILITY'),('ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_5','KIND_ABILITY'),('ABILITY_LOTM_CHURCH_FOOL_RECON_SIGHT_1','KIND_ABILITY');
-- Copy every actual unit class tag to the all-unit abilities.  CLASS_ALL_UNITS
-- alone has no Unit TypeTags in the base database and is not a safe filter.
INSERT OR IGNORE INTO TypeTags(Type,Tag)
SELECT ability.Type,unit_tags.Tag
FROM (SELECT Type FROM Types WHERE Type LIKE 'ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_%') ability
CROSS JOIN (SELECT DISTINCT tt.Tag FROM TypeTags tt JOIN Units u ON u.UnitType=tt.Type) unit_tags;
INSERT OR IGNORE INTO TypeTags(Type,Tag) VALUES ('ABILITY_LOTM_CHURCH_FOOL_RECON_SIGHT_1','CLASS_RECON');
INSERT OR REPLACE INTO UnitAbilities(UnitAbilityType,Name,Description,Inactive)
SELECT Type,'LOC_LOTM_CHURCH_FOOL_NAME','LOC_LOTM_CHURCH_FOOL_PERM_1',1 FROM Types WHERE Type LIKE 'ABILITY_LOTM_CHURCH_FOOL_%_SIGHT_%';
INSERT OR REPLACE INTO Modifiers(ModifierId,ModifierType,Permanent) VALUES
('LOTM_CHURCH_FOOL_ALL_SIGHT_1_MOD','MODIFIER_PLAYER_UNIT_ADJUST_SIGHT',1),('LOTM_CHURCH_FOOL_ALL_SIGHT_2_MOD','MODIFIER_PLAYER_UNIT_ADJUST_SIGHT',1),('LOTM_CHURCH_FOOL_ALL_SIGHT_3_MOD','MODIFIER_PLAYER_UNIT_ADJUST_SIGHT',1),('LOTM_CHURCH_FOOL_ALL_SIGHT_4_MOD','MODIFIER_PLAYER_UNIT_ADJUST_SIGHT',1),('LOTM_CHURCH_FOOL_ALL_SIGHT_5_MOD','MODIFIER_PLAYER_UNIT_ADJUST_SIGHT',1),('LOTM_CHURCH_FOOL_RECON_SIGHT_1_MOD','MODIFIER_PLAYER_UNIT_ADJUST_SIGHT',1);
INSERT OR REPLACE INTO ModifierArguments(ModifierId,Name,Value) VALUES
('LOTM_CHURCH_FOOL_ALL_SIGHT_1_MOD','Amount','1'),('LOTM_CHURCH_FOOL_ALL_SIGHT_2_MOD','Amount','2'),('LOTM_CHURCH_FOOL_ALL_SIGHT_3_MOD','Amount','3'),('LOTM_CHURCH_FOOL_ALL_SIGHT_4_MOD','Amount','4'),('LOTM_CHURCH_FOOL_ALL_SIGHT_5_MOD','Amount','5'),('LOTM_CHURCH_FOOL_RECON_SIGHT_1_MOD','Amount','1');
INSERT OR REPLACE INTO UnitAbilityModifiers(UnitAbilityType,ModifierId) VALUES
('ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_1','LOTM_CHURCH_FOOL_ALL_SIGHT_1_MOD'),('ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_2','LOTM_CHURCH_FOOL_ALL_SIGHT_2_MOD'),('ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_3','LOTM_CHURCH_FOOL_ALL_SIGHT_3_MOD'),('ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_4','LOTM_CHURCH_FOOL_ALL_SIGHT_4_MOD'),('ABILITY_LOTM_CHURCH_FOOL_ALL_SIGHT_5','LOTM_CHURCH_FOOL_ALL_SIGHT_5_MOD'),('ABILITY_LOTM_CHURCH_FOOL_RECON_SIGHT_1','LOTM_CHURCH_FOOL_RECON_SIGHT_1_MOD');""")
lines.append("""INSERT OR IGNORE INTO Types(Type,Kind) VALUES
('ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_5','KIND_ABILITY'),('ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_10','KIND_ABILITY'),('ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_20','KIND_ABILITY'),('ABILITY_LOTM_CHURCH_NIGHT_ENEMY_MOVE_1','KIND_ABILITY'),('ABILITY_LOTM_CHURCH_NIGHT_ENEMY_MOVE_2','KIND_ABILITY');
INSERT OR IGNORE INTO TypeTags(Type,Tag) SELECT Type,'CLASS_ALL_COMBAT_UNITS' FROM Types WHERE Type LIKE 'ABILITY_LOTM_CHURCH_NIGHT_ENEMY_%';
INSERT OR REPLACE INTO UnitAbilities(UnitAbilityType,Name,Description,Inactive) VALUES
('ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_5','LOC_LOTM_CHURCH_NIGHT_ENEMY_NAME','LOC_LOTM_CHURCH_NIGHT_ENEMY_DESC',1),('ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_10','LOC_LOTM_CHURCH_NIGHT_ENEMY_NAME','LOC_LOTM_CHURCH_NIGHT_ENEMY_DESC',1),('ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_20','LOC_LOTM_CHURCH_NIGHT_ENEMY_NAME','LOC_LOTM_CHURCH_NIGHT_ENEMY_DESC',1),('ABILITY_LOTM_CHURCH_NIGHT_ENEMY_MOVE_1','LOC_LOTM_CHURCH_NIGHT_ENEMY_NAME','LOC_LOTM_CHURCH_NIGHT_ENEMY_DESC',1),('ABILITY_LOTM_CHURCH_NIGHT_ENEMY_MOVE_2','LOC_LOTM_CHURCH_NIGHT_ENEMY_NAME','LOC_LOTM_CHURCH_NIGHT_ENEMY_DESC',1);
INSERT OR REPLACE INTO Modifiers(ModifierId,ModifierType,Permanent) VALUES
('LOTM_CHURCH_NIGHT_ENEMY_COMBAT_5_MOD','MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH',1),('LOTM_CHURCH_NIGHT_ENEMY_COMBAT_10_MOD','MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH',1),('LOTM_CHURCH_NIGHT_ENEMY_COMBAT_20_MOD','MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH',1),('LOTM_CHURCH_NIGHT_ENEMY_MOVE_1_MOD','MODIFIER_PLAYER_UNIT_ADJUST_MOVEMENT',1),('LOTM_CHURCH_NIGHT_ENEMY_MOVE_2_MOD','MODIFIER_PLAYER_UNIT_ADJUST_MOVEMENT',1);
INSERT OR REPLACE INTO ModifierArguments(ModifierId,Name,Value) VALUES
('LOTM_CHURCH_NIGHT_ENEMY_COMBAT_5_MOD','Amount','-5'),('LOTM_CHURCH_NIGHT_ENEMY_COMBAT_10_MOD','Amount','-10'),('LOTM_CHURCH_NIGHT_ENEMY_COMBAT_20_MOD','Amount','-20'),('LOTM_CHURCH_NIGHT_ENEMY_MOVE_1_MOD','Amount','-1'),('LOTM_CHURCH_NIGHT_ENEMY_MOVE_2_MOD','Amount','-2');
INSERT OR REPLACE INTO UnitAbilityModifiers(UnitAbilityType,ModifierId) VALUES
('ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_5','LOTM_CHURCH_NIGHT_ENEMY_COMBAT_5_MOD'),('ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_10','LOTM_CHURCH_NIGHT_ENEMY_COMBAT_10_MOD'),('ABILITY_LOTM_CHURCH_NIGHT_ENEMY_COMBAT_20','LOTM_CHURCH_NIGHT_ENEMY_COMBAT_20_MOD'),('ABILITY_LOTM_CHURCH_NIGHT_ENEMY_MOVE_1','LOTM_CHURCH_NIGHT_ENEMY_MOVE_1_MOD'),('ABILITY_LOTM_CHURCH_NIGHT_ENEMY_MOVE_2','LOTM_CHURCH_NIGHT_ENEMY_MOVE_2_MOD');
INSERT OR REPLACE INTO ModifierStrings(ModifierId,Context,Text) VALUES
('LOTM_CHURCH_NIGHT_ENEMY_COMBAT_5_MOD','Preview','LOC_LOTM_CHURCH_NIGHT_ENEMY_PREVIEW'),('LOTM_CHURCH_NIGHT_ENEMY_COMBAT_10_MOD','Preview','LOC_LOTM_CHURCH_NIGHT_ENEMY_PREVIEW'),('LOTM_CHURCH_NIGHT_ENEMY_COMBAT_20_MOD','Preview','LOC_LOTM_CHURCH_NIGHT_ENEMY_PREVIEW');""")
lines.append("""-- Friendly-territory combat uses the same subject structure as the
-- Firaxis Cossack: a unit ability owns a unit-level combat modifier, and the
-- unit-level child evaluates UNIT_IN_OWNER_TERRITORY against its actual plot.
INSERT OR IGNORE INTO Types(Type,Kind) VALUES
('ABILITY_LOTM_CHURCH_NIGHT_HOME_PERM_5','KIND_ABILITY'),('ABILITY_LOTM_CHURCH_NIGHT_HOME_PERM_10','KIND_ABILITY'),('ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_7','KIND_ABILITY'),('ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_12','KIND_ABILITY'),('ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_15','KIND_ABILITY'),('ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_20','KIND_ABILITY'),('ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_25','KIND_ABILITY'),('ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_40','KIND_ABILITY');
INSERT OR IGNORE INTO TypeTags(Type,Tag) SELECT Type,'CLASS_ALL_COMBAT_UNITS' FROM Types WHERE Type LIKE 'ABILITY_LOTM_CHURCH_NIGHT_HOME_%';
INSERT OR REPLACE INTO UnitAbilities(UnitAbilityType,Name,Description,Inactive)
SELECT Type,'LOC_LOTM_CHURCH_NIGHT_NAME','LOC_LOTM_CHURCH_NIGHT_HOME_ABILITY_DESCRIPTION',1 FROM Types WHERE Type LIKE 'ABILITY_LOTM_CHURCH_NIGHT_HOME_%';
INSERT OR REPLACE INTO Modifiers(ModifierId,ModifierType,SubjectRequirementSetId,Permanent) VALUES
('LOTM_CHURCH_NIGHT_HOME_PERM_5_MOD','MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH','LOTM_CHURCH_REQSET_OWN_TERRITORY_COMBAT',1),('LOTM_CHURCH_NIGHT_HOME_PERM_10_MOD','MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH','LOTM_CHURCH_REQSET_OWN_TERRITORY_COMBAT',1),('LOTM_CHURCH_NIGHT_HOME_BLESS_7_MOD','MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH','LOTM_CHURCH_REQSET_OWN_TERRITORY_COMBAT',1),('LOTM_CHURCH_NIGHT_HOME_BLESS_12_MOD','MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH','LOTM_CHURCH_REQSET_OWN_TERRITORY_COMBAT',1),('LOTM_CHURCH_NIGHT_HOME_BLESS_15_MOD','MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH','LOTM_CHURCH_REQSET_OWN_TERRITORY_COMBAT',1),('LOTM_CHURCH_NIGHT_HOME_BLESS_20_MOD','MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH','LOTM_CHURCH_REQSET_OWN_TERRITORY_COMBAT',1),('LOTM_CHURCH_NIGHT_HOME_BLESS_25_MOD','MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH','LOTM_CHURCH_REQSET_OWN_TERRITORY_COMBAT',1),('LOTM_CHURCH_NIGHT_HOME_BLESS_40_MOD','MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH','LOTM_CHURCH_REQSET_OWN_TERRITORY_COMBAT',1);
INSERT OR REPLACE INTO ModifierArguments(ModifierId,Name,Value) VALUES
('LOTM_CHURCH_NIGHT_HOME_PERM_5_MOD','Amount','5'),('LOTM_CHURCH_NIGHT_HOME_PERM_10_MOD','Amount','10'),('LOTM_CHURCH_NIGHT_HOME_BLESS_7_MOD','Amount','7'),('LOTM_CHURCH_NIGHT_HOME_BLESS_12_MOD','Amount','12'),('LOTM_CHURCH_NIGHT_HOME_BLESS_15_MOD','Amount','15'),('LOTM_CHURCH_NIGHT_HOME_BLESS_20_MOD','Amount','20'),('LOTM_CHURCH_NIGHT_HOME_BLESS_25_MOD','Amount','25'),('LOTM_CHURCH_NIGHT_HOME_BLESS_40_MOD','Amount','40');
INSERT OR REPLACE INTO UnitAbilityModifiers(UnitAbilityType,ModifierId) VALUES
('ABILITY_LOTM_CHURCH_NIGHT_HOME_PERM_5','LOTM_CHURCH_NIGHT_HOME_PERM_5_MOD'),('ABILITY_LOTM_CHURCH_NIGHT_HOME_PERM_10','LOTM_CHURCH_NIGHT_HOME_PERM_10_MOD'),('ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_7','LOTM_CHURCH_NIGHT_HOME_BLESS_7_MOD'),('ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_12','LOTM_CHURCH_NIGHT_HOME_BLESS_12_MOD'),('ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_15','LOTM_CHURCH_NIGHT_HOME_BLESS_15_MOD'),('ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_20','LOTM_CHURCH_NIGHT_HOME_BLESS_20_MOD'),('ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_25','LOTM_CHURCH_NIGHT_HOME_BLESS_25_MOD'),('ABILITY_LOTM_CHURCH_NIGHT_HOME_BLESS_40','LOTM_CHURCH_NIGHT_HOME_BLESS_40_MOD');
INSERT OR REPLACE INTO ModifierStrings(ModifierId,Context,Text)
SELECT ModifierId,'Preview','LOC_LOTM_CHURCH_NIGHT_COMBAT_PREVIEW' FROM Modifiers WHERE ModifierId LIKE 'LOTM_CHURCH_NIGHT_HOME_%_MOD';""")
OUT.write_text("\n\n".join(lines) + "\n", encoding="utf-8", newline="\n")
print(f"wrote {OUT} states={len(states)} modifiers={len(modifier_rows)}")
