#!/usr/bin/env python3
"""Apply the Rescue city XML rows to a DebugGameplay database copy."""
from __future__ import annotations

import argparse
import sqlite3
import xml.etree.ElementTree as ET
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
    # DebugGameplay's Types trigger calls the engine-provided SQL helper.
    db.create_function("Make_Hash", 1, lambda value: zlib.crc32(str(value).encode("utf-8")))
    db.execute("PRAGMA foreign_keys=ON")
    root = ET.parse(ROOT / "Gameplay/LOTM_RESCUE_City.xml").getroot()
    tables = (
        "Types", "DynamicModifiers", "Buildings", "BuildingModifiers",
        "Modifiers", "ModifierArguments",
    )
    for table in tables:
        for row in root.findall(f"./{table}/Row"):
            columns = list(row.attrib)
            values = [
                1 if row.attrib[column].lower() == "true"
                else 0 if row.attrib[column].lower() == "false"
                else row.attrib[column]
                for column in columns
            ]
            placeholders = ",".join("?" for _ in columns)
            # DebugGameplay.sqlite may already include the currently installed
            # mod rows.  Replace those same primary-key rows in the disposable
            # in-memory copy so this validator remains safe to rerun.
            db.execute(
                f"INSERT OR REPLACE INTO {table} ({','.join(columns)}) VALUES ({placeholders})",
                values,
            )
    errors = db.execute("PRAGMA foreign_key_check").fetchall()
    assert not errors, errors
    assert db.execute(
        "SELECT InternalOnly FROM Buildings WHERE BuildingType=?",
        ("BUILDING_LOTM_RESCUE_SEAL_CORE",),
    ).fetchone() == (1,)
    assert db.execute(
        "SELECT ModifierType FROM Modifiers WHERE ModifierId=?",
        ("LOTM_RESCUE_SEAL_LOYALTY_LOCK",),
    ).fetchone() == ("MODIFIER_SINGLE_CITY_ADJUST_IDENTITY_PER_TURN",)
    assert db.execute(
        "SELECT Value FROM ModifierArguments WHERE ModifierId=? AND Name='Amount'",
        ("LOTM_RESCUE_SEAL_LOYALTY_LOCK",),
    ).fetchone() == ("10000",)
    print("Rescue formal-city database rows applied; foreign-key errors=0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
