#!/usr/bin/env python3
"""Read-only helper for auditing artifact effect definitions in the live DB."""
from __future__ import annotations

import sqlite3
import sys
import zlib
import re
from pathlib import Path


db = Path(sys.argv[1])
source = sqlite3.connect(f"file:{db.as_posix()}?mode=ro", uri=True)
if len(sys.argv) > 2:
    connection = sqlite3.connect(":memory:")
    source.backup(connection)
    connection.create_function("Make_Hash", 1, lambda value: zlib.crc32(str(value).encode("utf-8")))
    connection.execute("PRAGMA foreign_keys=OFF")
    candidate = Path(sys.argv[2]).read_text(encoding="utf-8")
    marker = "-- rc.76 complete 21-artifact audit."
    if marker in candidate:
        candidate = marker + candidate.split(marker, 1)[1]
    connection.executescript(candidate)
    connection.execute("PRAGMA foreign_keys=ON")
    errors = connection.execute("PRAGMA foreign_key_check").fetchall()
    print("loaded candidate SQL; foreign keys", errors)
    for table, rowid, _, _ in errors:
        if table == "Modifiers":
            print("bad modifier", connection.execute("SELECT ModifierId,OwnerRequirementSetId,SubjectRequirementSetId FROM Modifiers WHERE rowid=?", (rowid,)).fetchone())
    print("lease76 modifiers", connection.execute("SELECT count(*) FROM Modifiers WHERE ModifierId LIKE '%_LEASE76'").fetchone()[0])
    if len(sys.argv) > 3:
        lua = Path(sys.argv[3]).read_text(encoding="utf-8")
        block = lua.split("local EFFECT_MODIFIERS :table = {", 1)[1].split("};", 1)[0]
        wanted = set(re.findall(r'"(LOTM_(?:PP_FX|RP_ART|BE_ART)_[A-Z0-9_]+)"', block))
        actual = {row[0][:-8] for row in connection.execute("SELECT ModifierId FROM Modifiers WHERE ModifierId LIKE '%_LEASE76'")}
        print("lua effect count", len(wanted), "missing-db", sorted(wanted-actual), "unattached-db", sorted(actual-wanted))
else:
    connection = source
for name in ("PLAYER_IS_AT_PEACE", "PLAYER_IS_AT_WAR", "REQUIRES_PLAYER_IS_AT_WAR"):
    print("requirement-name", name,
          connection.execute("SELECT count(*) FROM RequirementSets WHERE RequirementSetId=?", (name,)).fetchone()[0],
          connection.execute("SELECT count(*) FROM Requirements WHERE RequirementId=?", (name,)).fetchone()[0])
ids = (
    "ALLIANCE_ADD_GOLD_TO_ORIGIN_TRADE_ROUTE",
    "DEMOCRACY_TRADEROUTEFOODTOALLY",
    "DEMOCRACY_TRADEROUTEPRODUCTIONTOALLY",
    "RAID_DOUBLEPILLAGEIMPROVE",
    "SACK_DOUBLEPILLAGEDISTRICT",
    "FASCISM_WAR_WEARINESS",
    "EMISSARY_IDENTITY_PRESSURE_TO_FOREIGN_CITIES",
    "SECRET_SOCIETY_VAMPIRES_ADVANCED_PILLAGING",
)
marks = ",".join("?" for _ in ids)
for row in connection.execute(
    f"""SELECT m.ModifierId,m.ModifierType,m.OwnerRequirementSetId,
               m.SubjectRequirementSetId,a.Name,a.Value
          FROM Modifiers m LEFT JOIN ModifierArguments a USING(ModifierId)
         WHERE m.ModifierId IN ({marks})
         ORDER BY m.ModifierId,a.Name""",
    ids,
):
    print(" | ".join("" if value is None else str(value) for value in row))

print("-- relevant modifier types --")
for row in connection.execute(
    """SELECT ModifierType,CollectionType,EffectType
         FROM DynamicModifiers
        WHERE ModifierType LIKE '%TRADE_ROUTE%YIELD%'
           OR ModifierType LIKE '%PILLAGE%'
           OR ModifierType LIKE '%WAR_WEARINESS%'
           OR ModifierType LIKE '%MAINTENANCE%'
           OR ModifierType LIKE '%LOYALTY%PRESSURE%'
        ORDER BY ModifierType"""
):
    print(" | ".join("" if value is None else str(value) for value in row))

print("-- identity pressure examples --")
for row in connection.execute(
    """SELECT m.ModifierId,m.ModifierType,a.Name,a.Value
         FROM Modifiers m LEFT JOIN ModifierArguments a USING(ModifierId)
        WHERE m.ModifierType LIKE '%IDENTITY_PRESSURE%'
        ORDER BY m.ModifierId,a.Name LIMIT 120"""
):
    print(" | ".join("" if value is None else str(value) for value in row))

print("-- generic route examples --")
for row in connection.execute(
    """SELECT m.ModifierId,m.ModifierType,a.Name,a.Value
         FROM Modifiers m LEFT JOIN ModifierArguments a USING(ModifierId)
        WHERE m.ModifierType IN ('MODIFIER_PLAYER_ADJUST_TRADE_ROUTE_YIELD',
          'MODIFIER_PLAYER_ADJUST_TRADE_ROUTE_YIELD_FOR_DOMESTIC',
          'MODIFIER_PLAYER_ADJUST_TRADE_ROUTES_CITY_STATE_YIELD')
        ORDER BY m.ModifierId,a.Name LIMIT 160"""
):
    print(" | ".join("" if value is None else str(value) for value in row))
