#!/usr/bin/env python3
"""Validate either the historical rc.80 scope or the current village database."""
from __future__ import annotations

import argparse
import hashlib
import sqlite3
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RC79_SHA256 = "4D5D765C25DBE325211E50F42DA3B7ECB5FB786A8602877B61DD1D4E0DC81C64"
ALLOWED_CHANGED = {
    "CHANGELOG.md", "README.md", "RedPriestPath.modinfo", "VERSION.md", "WORKLOG.md",
    "Scripts/LOTM_PP_Artifacts.lua", "Scripts/LOTM_RP_Gameplay.lua",
    "Tests/build_release.py", "Tests/validate.py",
    "Text/en_US/LOTM_RP_GameplayText.xml",
    "Text/zh_Hans_CN/LOTM_RP_GameplayText.xml",
    "Text/Selected/LOTM_RP_Selected_en_US.xml",
    "Text/Selected/LOTM_RP_Selected_zh_Hans_CN.xml",
}
ALLOWED_ADDED = {
    "Gameplay/LOTM_WORLD_GoodyHuts.sql",
    "Scripts/LOTM_WORLD_GoodyHuts.lua",
    "UI/LOTM_WORLD_Popup.lua",
    "UI/LOTM_WORLD_Popup.xml",
    "Tests/validate_rc80_village.py",
}
NATIVE_GOODY_HUTS = (
    "GOODYHUT_CULTURE", "GOODYHUT_DIPLOMACY", "GOODYHUT_FAITH",
    "GOODYHUT_GOLD", "GOODYHUT_MILITARY", "GOODYHUT_SCIENCE",
    "GOODYHUT_SURVIVORS",
)
CUSTOM_GOODY_HUT = "GOODYHUT_LOTM_WORLD_GATHERING"
CUSTOM_GOODY_SUBTYPE = "GOODYHUT_LOTM_WORLD_GATHERING_REWARD"
CUSTOM_MARKER = "LOTM_WORLD_GOODY_GATHERING_MARKER"


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def compare_scope(baseline_zip: Path) -> None:
    if digest(baseline_zip.read_bytes()) != RC79_SHA256:
        raise AssertionError("rc.79 baseline SHA-256 mismatch")
    with zipfile.ZipFile(baseline_zip) as archive:
        old = {
            name.removeprefix("RedPriestPath/"): digest(archive.read(name))
            for name in archive.namelist()
            if not name.endswith("/")
        }
    new = {
        path.relative_to(ROOT).as_posix(): digest(path.read_bytes())
        for path in ROOT.rglob("*") if path.is_file() and "__pycache__" not in path.parts
    }
    added = set(new) - set(old)
    removed = set(old) - set(new)
    changed = {name for name in set(old) & set(new) if old[name] != new[name]}
    if removed:
        raise AssertionError(f"unexpected removals from rc.79: {sorted(removed)}")
    if added != ALLOWED_ADDED:
        raise AssertionError(f"unexpected added files: {sorted(added ^ ALLOWED_ADDED)}")
    unexpected = changed - ALLOWED_CHANGED
    if unexpected:
        raise AssertionError(f"unexpected modified files: {sorted(unexpected)}")
    print(f"PASS: rc.79 scope changed={len(changed)} added={len(added)} removed=0")


def validate_database(game_root: Path) -> None:
    schema = game_root / "Base" / "Assets" / "Gameplay" / "Data" / "Schema" / "01_GameplaySchema.sql"
    db = sqlite3.connect(":memory:")
    try:
        db.executescript(schema.read_text(encoding="utf-8-sig"))
        db.executemany(
            "INSERT INTO GoodyHuts(GoodyHutType,Weight) VALUES(?,100)",
            ((name,) for name in NATIVE_GOODY_HUTS),
        )
        db.executescript((ROOT / "Gameplay" / "LOTM_WORLD_GoodyHuts.sql").read_text(encoding="utf-8"))
        native_sum = db.execute(
            "SELECT SUM(Weight) FROM GoodyHuts WHERE GoodyHutType LIKE 'GOODYHUT_%' "
            "AND GoodyHutType<>'GOODYHUT_LOTM_WORLD_GATHERING'"
        ).fetchone()[0]
        custom = db.execute(
            "SELECT Weight,ShowMoment FROM GoodyHuts WHERE GoodyHutType='GOODYHUT_LOTM_WORLD_GATHERING'"
        ).fetchone()
        subtype = db.execute(
            "SELECT Weight,ModifierID FROM GoodyHutSubTypes WHERE SubTypeGoodyHut='GOODYHUT_LOTM_WORLD_GATHERING_REWARD'"
        ).fetchone()
        if native_sum != 91 or custom != (49, 0) or subtype != (100, "LOTM_WORLD_GOODY_GATHERING_MARKER"):
            raise AssertionError(f"unexpected village rows native={native_sum} custom={custom} subtype={subtype}")
    finally:
        db.close()
    print("PASS: village SQL executes with exclusive configured weights 65:35")


def validate_current_database(database: Path) -> None:
    """Read the loaded Gameplay DB without applying SQL or historical scope checks."""
    database = database.expanduser().resolve()
    if not database.is_file():
        raise AssertionError(f"current Gameplay database not found: {database}")

    db = sqlite3.connect(database.as_uri() + "?mode=ro", uri=True)
    try:
        db.execute("PRAGMA query_only=ON")

        custom_types = db.execute(
            "SELECT Type,Kind FROM Types "
            "WHERE Type LIKE 'GOODYHUT_LOTM_WORLD_%' ORDER BY Type"
        ).fetchall()
        expected_types = [(CUSTOM_GOODY_HUT, "KIND_GOODY_HUT")]
        if custom_types != expected_types:
            raise AssertionError(
                f"unexpected current village Types rows: {custom_types}"
            )

        category_rows = db.execute(
            "SELECT GoodyHutType,ImprovementType,Weight,ShowMoment "
            "FROM GoodyHuts WHERE ImprovementType='IMPROVEMENT_GOODY_HUT' "
            "ORDER BY GoodyHutType"
        ).fetchall()
        expected_categories = sorted(
            [(name, "IMPROVEMENT_GOODY_HUT", 13, 1) for name in NATIVE_GOODY_HUTS]
            + [(CUSTOM_GOODY_HUT, "IMPROVEMENT_GOODY_HUT", 49, 0)]
        )
        if category_rows != expected_categories:
            raise AssertionError(
                f"unexpected current village category rows: {category_rows}"
            )
        native_weight = sum(row[2] for row in category_rows if row[0] in NATIVE_GOODY_HUTS)
        custom_weight = next(row[2] for row in category_rows if row[0] == CUSTOM_GOODY_HUT)
        if (native_weight, custom_weight) != (91, 49) \
                or native_weight * 35 != custom_weight * 65:
            raise AssertionError(
                "current village category ratio is not exactly 65:35: "
                f"native={native_weight} custom={custom_weight}"
            )

        subtype_rows = db.execute(
            "SELECT GoodyHut,SubTypeGoodyHut,Description,Weight,ModifierID,"
            "UpgradeUnit,Turn,Experience,Heal,Relic,Trader,MinOneCity,RequiresUnit "
            "FROM GoodyHutSubTypes "
            "WHERE GoodyHut LIKE 'GOODYHUT_LOTM_WORLD_%' "
            "OR SubTypeGoodyHut LIKE 'GOODYHUT_LOTM_WORLD_%' "
            "OR ModifierID LIKE 'LOTM_WORLD_GOODY_%' "
            "ORDER BY GoodyHut,SubTypeGoodyHut"
        ).fetchall()
        expected_subtypes = [(
            CUSTOM_GOODY_HUT, CUSTOM_GOODY_SUBTYPE, "", 100, CUSTOM_MARKER,
            0, 0, 0, 0, 0, 0, 0, 0,
        )]
        if subtype_rows != expected_subtypes:
            raise AssertionError(
                f"unexpected current village subtype rows: {subtype_rows}"
            )

        modifier_rows = db.execute(
            "SELECT ModifierId,ModifierType,RunOnce,NewOnly,Permanent,Repeatable,"
            "OwnerRequirementSetId,SubjectRequirementSetId,OwnerStackLimit,SubjectStackLimit "
            "FROM Modifiers WHERE ModifierId LIKE 'LOTM_WORLD_GOODY_%' "
            "ORDER BY ModifierId"
        ).fetchall()
        expected_modifiers = [(
            CUSTOM_MARKER, "MODIFIER_PLAYER_ADJUST_PROPERTY", 1, 0, 1, 0,
            None, None, None, None,
        )]
        if modifier_rows != expected_modifiers:
            raise AssertionError(
                f"unexpected current village marker rows: {modifier_rows}"
            )

        argument_rows = db.execute(
            "SELECT ModifierId,Name,Type,Value,Extra,SecondExtra "
            "FROM ModifierArguments WHERE ModifierId LIKE 'LOTM_WORLD_GOODY_%' "
            "ORDER BY ModifierId,Name"
        ).fetchall()
        expected_arguments = [
            (CUSTOM_MARKER, "Amount", "ARGTYPE_IDENTITY", "1", None, None),
            (
                CUSTOM_MARKER, "Key", "ARGTYPE_IDENTITY",
                "LOTM_WORLD_GOODY_GATHERING_COUNT", None, None,
            ),
        ]
        if argument_rows != expected_arguments:
            raise AssertionError(
                f"unexpected current village marker arguments: {argument_rows}"
            )
    finally:
        db.close()

    print(
        "PASS: current Gameplay village categories are exact "
        "nativeWeight=91 customWeight=49 ratio=65:35"
    )
    print("PASS: current Gameplay village subtype/property marker chain is exact")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--game-root", type=Path)
    parser.add_argument("--baseline-zip", type=Path)
    parser.add_argument(
        "--current-database",
        type=Path,
        help=(
            "Read-only current DebugGameplay.sqlite contract check; skips the "
            "historical rc.79 scope comparison and source-SQL execution."
        ),
    )
    args = parser.parse_args()

    if args.current_database is not None:
        if args.game_root is not None or args.baseline_zip is not None:
            parser.error(
                "--current-database cannot be combined with historical-mode arguments"
            )
        validate_current_database(args.current_database)
        print("PASS: current release village database contract")
        return 0

    if args.game_root is None or args.baseline_zip is None:
        parser.error(
            "historical mode requires both --game-root and --baseline-zip; "
            "use --current-database for a current release database"
        )
    compare_scope(args.baseline_zip.resolve())
    validate_database(args.game_root.resolve())
    print("PASS: clean rc.80 artifact/village contract")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        raise
