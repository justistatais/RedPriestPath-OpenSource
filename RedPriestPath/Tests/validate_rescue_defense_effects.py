#!/usr/bin/env python3
"""Validate rescue purification combat/wall effects and AI wall priorities."""
from __future__ import annotations

import argparse
import sqlite3
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("database", type=Path)
    args = parser.parse_args()

    source = sqlite3.connect(f"file:{args.database.as_posix()}?mode=ro", uri=True)
    db = sqlite3.connect(":memory:")
    source.backup(db)
    db.create_function("Make_Hash", 1, lambda value: zlib.crc32(str(value).encode("utf-8")))
    db.execute("PRAGMA foreign_keys=ON")
    db.executescript((ROOT / "Gameplay/LOTM_RESCUE_Thief.sql").read_text(encoding="utf-8"))
    db.executescript((ROOT / "Gameplay/LOTM_RESCUE_Phase9.sql").read_text(encoding="utf-8"))

    expected_abilities = {
        f"LOTM_RESCUE_PURIFICATION_MADNESS_{amount}" for amount in range(5, 51, 5)
    }
    tagged = {
        row[0]
        for row in db.execute(
            "SELECT Type FROM TypeTags WHERE Tag='CLASS_ALL_COMBAT_UNITS' "
            "AND Type LIKE 'LOTM_RESCUE_PURIFICATION_MADNESS_%'"
        )
    }
    assert tagged == expected_abilities, (tagged, expected_abilities)

    for amount in range(5, 51, 5):
        ability = f"LOTM_RESCUE_PURIFICATION_MADNESS_{amount}"
        modifier = f"{ability}_MOD"
        assert db.execute(
            "SELECT ModifierId FROM UnitAbilityModifiers WHERE UnitAbilityType=?",
            (ability,),
        ).fetchone() == (modifier,)
        assert db.execute(
            "SELECT Value FROM ModifierArguments WHERE ModifierId=? AND Name='Amount'",
            (modifier,),
        ).fetchone() == (str(-amount),)

    assert db.execute(
        "SELECT CollectionType,EffectType FROM DynamicModifiers "
        "WHERE ModifierType='MODIFIER_PLAYER_CITIES_ADJUST_OUTER_DEFENSE'"
    ).fetchone() == ("COLLECTION_PLAYER_CITIES", "EFFECT_ADJUST_CITY_OUTER_DEFENSE")
    assert db.execute(
        "SELECT ModifierType FROM Modifiers WHERE ModifierId='LOTM_RESCUE_PURIF_WALL_PLUS'"
    ).fetchone() == ("MODIFIER_PLAYER_CITIES_ADJUST_OUTER_DEFENSE",)
    assert db.execute(
        "SELECT Value FROM ModifierArguments WHERE ModifierId='LOTM_RESCUE_PURIF_WALL_PLUS' AND Name='Amount'"
    ).fetchone() == ("5",)
    for level in range(1, 11):
        modifier = f"LOTM_RESCUE_PURIF_WALL_LEVEL_{level}"
        assert db.execute(
            "SELECT ModifierType FROM Modifiers WHERE ModifierId=?", (modifier,)
        ).fetchone() == ("MODIFIER_PLAYER_CITIES_ADJUST_OUTER_DEFENSE",)
        assert db.execute(
            "SELECT Value FROM ModifierArguments WHERE ModifierId=? AND Name='Amount'",
            (modifier,),
        ).fetchone() == (str(level * 5),)

    for level in range(1, 11):
        modifier = f"LOTM_RESCUE_PURIF_ARMY_LEVEL_{level}"
        assert db.execute(
            "SELECT ModifierType,SubjectRequirementSetId FROM Modifiers WHERE ModifierId=?",
            (modifier,),
        ).fetchone() == (
            "MODIFIER_LOTM_RP_PLAYER_UNITS_ADJUST_BASE_COMBAT_STRENGTH",
            "LOTM_RESCUE_REQSET_COMBAT_V2",
        )
        assert db.execute(
            "SELECT Value FROM ModifierArguments WHERE ModifierId=? AND Name='Amount'",
            (modifier,),
        ).fetchone() == (str(level * 5),)

    wall_rows = {
        row[0]
        for row in db.execute(
            "SELECT Item FROM AiFavoredItems WHERE ListType='LOTM_RESCUE_P9_MAJOR_WALL_BUILDINGS' "
            "AND Favored=1"
        )
    }
    assert wall_rows == {"BUILDING_WALLS", "BUILDING_CASTLE", "BUILDING_STAR_FORT"}
    assert db.execute(
        "SELECT Favored,Value FROM AiFavoredItems "
        "WHERE ListType='LOTM_RESCUE_P9_MAJOR_CITY_DEFENSE_PSEUDOYIELDS' "
        "AND Item='PSEUDOYIELD_CITY_DEFENSES'"
    ).fetchone() == (1, 100)
    assert not db.execute("PRAGMA foreign_key_check").fetchall()

    lua = (ROOT / "Scripts/LOTM_RESCUE_Thief.lua").read_text(encoding="utf-8")
    for token in (
        "local VERSION = 6;",
        "local MADNESS_EFFECT_VERSION = 1;",
        "local WALL_EFFECT_VERSION = 3;",
        "local ARMY_EFFECT_VERSION = 2;",
        "LOTM_RESCUE_MADNESS_EFFECT_MIGRATION_VERSION",
        "abilityTag=CLASS_ALL_COMBAT_UNITS",
        "modifierType=MODIFIER_PLAYER_CITIES_ADJUST_OUTER_DEFENSE",
        "exactLevelModifier=true",
        "LOTM_RESCUE_ARMY_MODIFIER_MIGRATION_VERSION",
        "modifierType=MODIFIER_LOTM_RP_PLAYER_UNITS_ADJUST_BASE_COMBAT_STRENGTH",
    ):
        assert token in lua, token

    print("PASS: rescue combat suppression, wall buff, and AI wall priorities")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
