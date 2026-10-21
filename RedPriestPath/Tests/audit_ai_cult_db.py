#!/usr/bin/env python3
"""Apply AI cult SQL to a disposable Gameplay DB copy and audit references."""
from pathlib import Path
import argparse, sqlite3, zlib

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument("database",type=Path)
args=parser.parse_args()
connection=sqlite3.connect(args.database)
connection.create_function("Make_Hash",1,lambda value:zlib.crc32(str(value).encode("utf-8")))
try:
 connection.executescript((ROOT/"Gameplay/LOTM_AI_Cults.sql").read_text(encoding="utf-8"))
except sqlite3.Error:
 print("Units columns:",",".join(row[1] for row in connection.execute("PRAGMA table_info(Units)")))
 raise
checks={
 "effect rows":connection.execute("SELECT count(*) FROM LOTM_CultEffectRows").fetchone()[0],
 "effect tokens":connection.execute("SELECT count(DISTINCT Token) FROM LOTM_CultEffectRows").fetchone()[0],
 "cult modifiers":connection.execute("SELECT count(*) FROM Modifiers WHERE ModifierId LIKE 'LOTM_CULT_%'").fetchone()[0],
 "cult abilities":connection.execute("SELECT count(*) FROM UnitAbilities WHERE UnitAbilityType LIKE 'ABILITY_LOTM_CULT_%'").fetchone()[0],
 "war ability links":connection.execute("SELECT count(*) FROM UnitAbilityModifiers WHERE UnitAbilityType LIKE 'ABILITY_LOTM_CULT_%_WAR_%'").fetchone()[0],
 "pedia unit":connection.execute("SELECT count(*) FROM Units WHERE UnitType='UNIT_LOTM_CULT_FLESH_PUPPET'").fetchone()[0],
 "foreign key errors":len(connection.execute("PRAGMA foreign_key_check").fetchall()),
}
connection.close()
print("; ".join(f"{key}={value}" for key,value in checks.items()))
if (checks["effect rows"]!=70 or checks["effect tokens"]!=36
 or checks["cult modifiers"]!=150 or checks["cult abilities"]!=10
 or checks["war ability links"]!=8 or checks["pedia unit"]!=1
 or checks["foreign key errors"]!=0): raise SystemExit(1)
