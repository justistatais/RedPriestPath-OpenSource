#!/usr/bin/env python3
"""Build a deterministic Red Priest Path release-candidate archive."""

from __future__ import annotations

import argparse
from datetime import datetime, timedelta
import hashlib
import os
import subprocess
import sys
import zipfile
from pathlib import Path


VERSION = "0.1.0-rc.403"
RESOURCE_VERSION = 435
ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT.parent
DIST = WORKSPACE / "dist"
ARCHIVE = DIST / f"RedPriestPath-{VERSION}.zip"
MANIFEST = DIST / f"RedPriestPath-{VERSION}.MANIFEST.sha256"
ARCHIVE_HASH = DIST / f"RedPriestPath-{VERSION}.zip.sha256"
EXCLUDED_PARTS = {"__pycache__", ".git", "backups"}
EXCLUDED_SUFFIXES = {".pyc", ".pyo", ".civ6save"}

# Civ VI keys its Mods.sqlite scan record to the .modinfo filesystem timestamp.
# A single timestamp reused by every release can therefore leave a newer
# archive running with an older component table.  Keep archives reproducible,
# but advance the timestamp deterministically for every resource version.
ZIP_TIMESTAMP_EPOCH = datetime(2026, 7, 26, 0, 0, 0)
ZIP_TIMESTAMP = ZIP_TIMESTAMP_EPOCH + timedelta(minutes=RESOURCE_VERSION)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def release_files() -> list[Path]:
    files: list[Path] = []
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(ROOT)
        # Preserve prior audits in source; only the current repair audits are shipped.
        if relative.as_posix() in ("Art/ExperimentalArtQuarantine.json", "Art/LOTMArtMaterialAudit_rc374.json", "Art/LOTMArtMaterialAudit_rc376.json", "Art/LOTMGeometryAudit_rc376.json", "Art/LOTMArtMaterialAudit_rc377.json", "Art/LOTMGeometryAudit_rc377.json", "Art/LOTMHolyCitySigilsAudit_rc377.json"):
            continue
        if any(part in EXCLUDED_PARTS for part in relative.parts):
            continue
        if path.suffix.lower() in EXCLUDED_SUFFIXES:
            continue
        files.append(path)
    return sorted(files, key=lambda item: item.relative_to(ROOT).as_posix())


def default_gameplay_database() -> Path | None:
    local_app_data = os.environ.get("LOCALAPPDATA")
    if not local_app_data:
        return None
    return (
        Path(local_app_data)
        / "Firaxis Games"
        / "Sid Meier's Civilization VI"
        / "Cache"
        / "DebugGameplay.sqlite"
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--force",
        action="store_true",
        help="Replace an existing archive and hash files for this exact RC version.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DIST,
        help="Directory for candidate outputs; defaults to the workspace dist directory.",
    )
    parser.add_argument(
        "--database",
        type=Path,
        default=None,
        help=(
            "Read-only Civ VI DebugGameplay.sqlite used by database validators; "
            "defaults to the current user's LOCALAPPDATA Civ VI cache."
        ),
    )
    args = parser.parse_args()
    output_dir = args.output_dir.resolve()
    archive = output_dir / f"RedPriestPath-{VERSION}.zip"
    manifest = output_dir / f"RedPriestPath-{VERSION}.MANIFEST.sha256"
    archive_hash = output_dir / f"RedPriestPath-{VERSION}.zip.sha256"

    database = (args.database or default_gameplay_database())
    if database is None or not database.is_file():
        print(
            "Release build requires a readable Civ VI DebugGameplay.sqlite; "
            "pass --database or launch Civ VI once to create the LOCALAPPDATA cache.",
            file=sys.stderr,
        )
        return 2
    database = database.resolve()
    database_validators = {
        "test_rc403_storm_production.py",
        "test_rc402_rescue_storm.py",
        "test_rc401_governor_redemption.py",
        "test_rc392_god_blessings.py",
        "test_rc390_normal_balance.py",
        "test_rc388_ability_removal.py",
        "validate_magician_star.py",
        "validate_justice_governor.py",
        "validate_holy_city_art.py",
        "test_rc358_descent.py",
        "test_rc356_advanced_cities.py",
        "test_rc355_labels_units_icons.py",
        "test_rc354_project_completion.py",
        "test_rc352_potion_receipt.py",
        "test_rc349_runtime_events.py",
        "test_rc347_found_city_gate.py",
        "test_rc346_project_rules.py",
        "test_rc346_lifecycle_rules.py",
        "validate_artifact_effects.py",
        "validate_rescue_artifacts.py",
        "validate_rescue_city_database.py",
        "validate_rescue_defense_effects.py",
    }
    for validator in ("test_rc403_storm_production.py", "test_rc402_rescue_storm.py", "test_rc401_governor_redemption.py", "test_rc392_god_blessings.py", "test_rc391_cult_military.py", "test_rc390_normal_balance.py", "test_rc388_ability_removal.py", "test_magician_star_runtime.py", "validate_magician_star.py", "test_justice_story_runtime.py", "test_justice_story_ui.py", "validate_justice_governor.py", "test_rc360_normal_startup.py", "test_rc359_ending_ui.py", "test_rc358_descent.py", "test_rc357_gameplay_city_api.py", "test_rc356_advanced_cities.py", "test_rc355_labels_units_icons.py", "test_rc354_project_completion.py", "test_rc353_reload_recovery.py", "test_rc352_potion_receipt.py", "test_rc351_runtime_dispatch.py", "test_rc350_turn_safety.py", "test_rc349_runtime_events.py", "test_rc348_camp_artifacts.py", "test_rc348_barbarian_spawn.py", "test_rc347_found_city_gate.py", "test_rc346_project_rules.py", "test_rc346_lifecycle_rules.py", "test_rc346_thief_rule_guards.py", "test_rc346_path_rules.py", "test_rc345_quiet_diagnostics.py", "test_rc345_purification_layout.py", "test_rc343_lua51_diagnostics.py", "test_rc342_startup_trace.py", "test_rc342_ui_trace.py", "test_rc341_command_bootstrap.py", "validate_refactor_router.py", "validate_effects_runtime.py", "test_mp241_runtime.py", "validate_qd_cache_migration.py", "validate_gameplay_bundle.py", "validate.py", "validate_multiplayer_rc241.py", "validate_perfect_network_event_queue.py", "validate_ai_cults.py", "validate_artifact_effects.py", "validate_rc80_village.py", "validate_rc81_random_events.py", "validate_rc82_monsters.py", "validate_rc83_churches.py", "validate_ui_compatibility.py", "validate_thief_path.py", "validate_resource249_gameplay_baseline.py", "validate_rescue_artifacts.py", "validate_rescue_city_database.py", "validate_rescue_defense_effects.py", "validate_rescue_difficulty.py", "validate_rescue_phase1.py", "validate_rescue_phase2a.py", "validate_rescue_phase3.py", "validate_rescue_phase4.py", "validate_rescue_phase5.py", "validate_rescue_phase6.py", "validate_rescue_phase7.py", "validate_rescue_phase8.py", "validate_rescue_phase9.py", "validate_rescue_phase9_digestion.py", "validate_rescue_phase10a.py", "validate_rescue_phase10.py", "validate_god_models.py", "validate_models_v4.py", "test_holy_city_art_runtime.py", "validate_holy_city_art.py", "validate_art_materials.py", "validate_art_dependency_closure.py", "validate_holy_city_sigils.py", "validate_city_surface_bindings.py", "test_player_models_runtime.py", "validate_player_models.py"):
        command = [sys.executable, str(ROOT / "Tests" / validator)]
        if validator == "validate_rc80_village.py":
            command.extend(["--current-database", str(database)])
        elif validator == "validate_rescue_artifacts.py":
            command.extend(["--database", str(database)])
        elif validator in database_validators:
            command.append(str(database))
        validation = subprocess.run(
            command,
            cwd=WORKSPACE,
            # Imported test fixtures can consume the positional path before a
            # caller reads it. Preserve one selected read-only snapshot for
            # every fixture, including after a failed native load clears cache.
            env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1",
                 "LOTM_TEST_GAMEPLAY_DATABASE": str(database)},
            check=False,
        )
        if validation.returncode != 0:
            print(f"Release build aborted because {validator} failed.", file=sys.stderr)
            return validation.returncode

    outputs = (archive, manifest, archive_hash)
    existing = [path for path in outputs if path.exists()]
    if existing and not args.force:
        print(
            "Release output already exists; pass --force to replace only this RC: "
            + ", ".join(str(path) for path in existing),
            file=sys.stderr,
        )
        return 2

    output_dir.mkdir(parents=True, exist_ok=True)
    files = release_files()
    manifest_lines: list[str] = []
    temporary_archive = archive.with_name(archive.name + ".building")
    if temporary_archive.exists():
        temporary_archive.unlink()
    with zipfile.ZipFile(temporary_archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as bundle:
        for path in files:
            relative = path.relative_to(ROOT).as_posix()
            archive_name = f"RedPriestPath/{relative}"
            data = path.read_bytes()
            info = zipfile.ZipInfo(
                archive_name,
                date_time=ZIP_TIMESTAMP.timetuple()[:6],
            )
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            bundle.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
            manifest_lines.append(f"{sha256_bytes(data)}  {archive_name}")

    archive_digest = sha256_bytes(temporary_archive.read_bytes())
    temporary_archive.replace(archive)
    manifest.write_text("\n".join(manifest_lines) + "\n", encoding="utf-8", newline="\n")
    archive_hash.write_text(
        f"{archive_digest}  {archive.name}\n",
        encoding="utf-8",
        newline="\n",
    )

    print(f"Archive: {archive}")
    print(f"Files: {len(files)}")
    print(f"SHA256: {archive_digest}")
    print(f"ZIP timestamp: {ZIP_TIMESTAMP.isoformat(sep=' ')}")
    print(f"Manifest: {manifest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
