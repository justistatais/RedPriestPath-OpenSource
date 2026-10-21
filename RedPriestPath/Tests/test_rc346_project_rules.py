#!/usr/bin/env python3
"""Apply the advancement manifest to an in-memory copy of Civ VI's database.

These checks cover real database rows and referential integrity. They cannot
claim that native production availability/resource refresh passed in-game.
"""
from pathlib import Path
import os
import re
import sqlite3
import sys
import unittest
import zlib

ROOT = Path(__file__).resolve().parents[1]
SQL = (ROOT / "Gameplay/LOTM_PathProjectRules.sql").read_text(encoding="utf-8")
DATABASE = Path(os.environ.get("LOCALAPPDATA", "")) / "Firaxis Games" / "Sid Meier's Civilization VI" / "Cache" / "DebugGameplay.sqlite"
if len(sys.argv) > 1 and Path(sys.argv[1]).suffix.lower() in {".sqlite", ".sqlite3", ".db"}:
    DATABASE = Path(sys.argv.pop(1))


def advancement_types(db):
    """Select the actual potion/ceremony inventory, excluding repeatable skills."""
    return {
        row[0] for row in db.execute("SELECT ProjectType FROM Projects WHERE ProjectType LIKE 'PROJECT_LOTM_%'")
        if row[0].endswith("_POTION") or row[0] in {
            "PROJECT_LOTM_RP_WAR_FESTIVAL", "PROJECT_LOTM_RP_WAR_FESTIVAL_UNCONSECRATED",
            "PROJECT_LOTM_PP_CIVILIZATION_ASCENSION", "PROJECT_LOTM_PP_CIVILIZATION_ASCENSION_UNCONSECRATED",
            "PROJECT_LOTM_BE_ENTHRONEMENT", "PROJECT_LOTM_BE_ENTHRONEMENT_UNCONSECRATED",
            "PROJECT_LOTM_TP_ERROR_APOTHEOSIS",
        }
    }


class ProjectRulesDatabaseTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(DATABASE.is_file(), f"Civ VI database is missing: {DATABASE}")
        self.db = sqlite3.connect(":memory:")
        with sqlite3.connect(f"file:{DATABASE.as_posix()}?mode=ro", uri=True) as source:
            source.backup(self.db)
        self.db.create_function("Make_Hash", 1, lambda value: zlib.crc32(str(value).encode("utf-8")))
        self.db.execute("PRAGMA foreign_keys=ON")
        self.before = list(self.db.execute(
            "SELECT ProjectType,Cost,MaxPlayerInstances,PrereqTech,PrereqCivic,UnlocksFromEffect FROM Projects ORDER BY ProjectType"
        ))

    def tearDown(self):
        self.db.close()

    def apply(self):
        self.db.executescript(SQL)

    def test_complete_actual_potion_and_ceremony_inventory(self):
        expected = advancement_types(self.db)
        self.assertEqual(len(expected), 39)
        self.apply()
        actual = {row[0] for row in self.db.execute("SELECT ProjectType FROM LOTM_PathProjectRules")}
        self.assertEqual(actual, expected)
        self.assertEqual(dict(self.db.execute(
            "SELECT PathType,COUNT(*) FROM LOTM_PathProjectRules GROUP BY PathType"
        )), {"PATH_RED_PRIEST": 10, "PATH_PERFECT": 10, "PATH_BLACK_EMPEROR": 10, "PATH_THIEF": 9})

    def test_only_adjacent_sequences_and_exclusive_church_variants(self):
        self.apply()
        for path, source, target, church in self.db.execute(
            "SELECT PathType,FromSequence,ToSequence,ChurchRequired FROM LOTM_PathProjectRules"
        ):
            self.assertIn(source, range(1, 10))
            self.assertEqual(target, source - 1)
            self.assertIn(church, {-1, 0, 1})
            if source > 1 or path == "PATH_THIEF":
                self.assertEqual(church, -1)
        for path in ("PATH_RED_PRIEST", "PATH_PERFECT", "PATH_BLACK_EMPEROR"):
            variants = self.db.execute(
                "SELECT ChurchRequired FROM LOTM_PathProjectRules WHERE PathType=? AND FromSequence=1 ORDER BY ChurchRequired", (path,)
            ).fetchall()
            self.assertEqual(variants, [(0,), (1,)])

    def test_modifier_project_mappings_and_flags_are_unique(self):
        self.apply()
        rows = self.db.execute(
            "SELECT r.ModifierId,r.ProjectType,r.UnlockFlag,m.Permanent,a.Value "
            "FROM LOTM_PathProjectRules r JOIN Modifiers m ON m.ModifierId=r.ModifierId "
            "LEFT JOIN ModifierArguments a ON a.ModifierId=r.ModifierId AND a.Name='ProjectType'"
        ).fetchall()
        self.assertEqual(len(rows), 39)
        self.assertEqual(len({row[2] for row in rows}), 39)
        for modifier, project, flag, permanent, target in rows:
            self.assertEqual(target, project, modifier)
            self.assertEqual(permanent, 0, modifier)
            self.assertTrue(flag.endswith("_UNLOCKED"), flag)

    def test_every_manifest_modifier_and_flag_matches_source_lua(self):
        # Execute the actual selector and constants rather than reproducing
        # its mapping in Python. This catches a valid SQL row that silently
        # disagrees with Lifecycle (such as CHAOS vs CHAOS_MENTOR).
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            sys.path.insert(0, str(ROOT.parent / ".tmp" / "refactor-rc340-python"))
            from lupa.lua51 import LuaRuntime
        from generate_gameplay_bundle import lua_function_span

        source = (ROOT / "Scripts/LOTM_RP_Lifecycle.lua").read_text(encoding="utf-8")
        constants = re.findall(r'local\s+[A-Z_0-9]+\s*:\s*string\s*=\s*"[^"\n]*"\s*;', source)
        properties = re.search(r"local LOTM_RP_PROPERTIES\s*:\s*table\s*=\s*\{.*?\n\};", source, re.S)
        self.assertIsNotNone(properties)
        begin, end = lua_function_span(source, "GetProjectUnlock")
        chunk = "\n".join(constants) + "\n" + properties.group() + "\n" + source[begin:end]
        chunk += r'''
            return function(path, sequence, church)
                local player = {};
                function player:GetProperty(key)
                    if key == LOTM_RP_PROPERTIES.Path then return path; end
                    if key == LOTM_RP_PROPERTIES.TrueGodChurch then return church; end
                    error("Unexpected property in project selector: " .. tostring(key));
                end
                return GetProjectUnlock(player, sequence);
            end
        '''
        chunk = re.sub(r"\s*:\s*(?:boolean|number|string|table)\b", "", chunk)
        select = LuaRuntime(unpack_returned_tuples=True).execute(chunk)
        self.apply()
        for project, path, sequence, modifier, flag, church in self.db.execute(
            "SELECT ProjectType,PathType,FromSequence,ModifierId,UnlockFlag,ChurchRequired FROM LOTM_PathProjectRules"
        ):
            for actual_church in ((0, 1) if church == -1 else (church,)):
                with self.subTest(project=project, church=actual_church):
                    self.assertEqual(select(path, sequence, actual_church), (modifier, flag))

    def test_gate_resource_is_native_prerequisite_and_never_spawns(self):
        self.apply()
        rows = self.db.execute(
            "SELECT r.ProjectType,r.GateResourceType,p.PrereqResource,t.Kind,s.ResourceClassType,s.Frequency,s.LakeEligible "
            "FROM LOTM_PathProjectRules r JOIN Projects p ON p.ProjectType=r.ProjectType "
            "JOIN Resources s ON s.ResourceType=r.GateResourceType JOIN Types t ON t.Type=r.GateResourceType"
        ).fetchall()
        self.assertEqual(len(rows), 39)
        self.assertEqual(len({row[1] for row in rows}), 39)
        for project, gate, requirement, kind, category, frequency, lake in rows:
            self.assertEqual(gate, "RESOURCE_LOTM_PROJECT_GATE_" + project.removeprefix("PROJECT_LOTM_"))
            self.assertEqual(requirement, gate)
            self.assertEqual((kind, category, frequency, lake), ("KIND_RESOURCE", "RESOURCECLASS_BONUS", 0, 0))
        self.assertEqual(self.db.execute("PRAGMA foreign_key_check").fetchall(), [])

    def test_cost_technology_instances_and_repeatable_projects_preserved(self):
        protected = list(self.db.execute(
            "SELECT ModifierId,Permanent FROM Modifiers WHERE ModifierId IN "
            "('LOTM_BE_MOD_ALLOW_TRANSFORMATION_PROJECT','LOTM_TP_MOD_ALLOW_FAITH_TRANSFER','LOTM_RESCUE_P10_ALLOW_WAR_GOD_RELIC') ORDER BY ModifierId"
        ))
        self.apply()
        self.assertEqual(self.before, list(self.db.execute(
            "SELECT ProjectType,Cost,MaxPlayerInstances,PrereqTech,PrereqCivic,UnlocksFromEffect FROM Projects ORDER BY ProjectType"
        )))
        self.assertEqual(protected, list(self.db.execute(
            "SELECT ModifierId,Permanent FROM Modifiers WHERE ModifierId IN "
            "('LOTM_BE_MOD_ALLOW_TRANSFORMATION_PROJECT','LOTM_TP_MOD_ALLOW_FAITH_TRANSFER','LOTM_RESCUE_P10_ALLOW_WAR_GOD_RELIC') ORDER BY ModifierId"
        )))

    def test_reapplying_is_idempotent(self):
        self.apply()
        before = list(self.db.execute("SELECT * FROM LOTM_PathProjectRules ORDER BY ProjectType"))
        counts = {table: self.db.execute(f"SELECT COUNT(*) FROM {table}").fetchone() for table in ("Projects", "Modifiers", "Resources", "Types")}
        self.apply()
        self.assertEqual(before, list(self.db.execute("SELECT * FROM LOTM_PathProjectRules ORDER BY ProjectType")))
        for table, count in counts.items():
            self.assertEqual(count, self.db.execute(f"SELECT COUNT(*) FROM {table}").fetchone())

    def test_missing_mode_content_does_not_create_projects_or_resource_types(self):
        # Work in a disposable schema fixture: a mode may not define Thief.
        # No source or live database is mutated by this test.
        db = sqlite3.connect(":memory:")
        try:
            db.executescript("""
                CREATE TABLE Projects(ProjectType TEXT PRIMARY KEY,PrereqResource TEXT);
                CREATE TABLE Modifiers(ModifierId TEXT PRIMARY KEY,Permanent INTEGER);
                CREATE TABLE Types(Type TEXT PRIMARY KEY,Kind TEXT);
                CREATE TABLE Resources(ResourceType TEXT PRIMARY KEY,Name TEXT,ResourceClassType TEXT,Frequency INTEGER,LakeEligible INTEGER);
                INSERT INTO Projects VALUES('PROJECT_LOTM_RP_PROVOKER_POTION',NULL);
                INSERT INTO Modifiers VALUES('LOTM_RP_MOD_ALLOW_PROVOKER_PROJECT',1);
            """)
            db.executescript(SQL)
            self.assertEqual(db.execute("SELECT COUNT(*) FROM LOTM_PathProjectRules").fetchone(), (1,))
            self.assertEqual(db.execute("SELECT COUNT(*) FROM Resources").fetchone(), (1,))
            self.assertEqual(db.execute("SELECT COUNT(*) FROM Types WHERE Type LIKE '%TP_%'").fetchone(), (0,))
            self.assertEqual(db.execute("SELECT COUNT(*) FROM Projects").fetchone(), (1,))
        finally:
            db.close()


if __name__ == "__main__":
    unittest.main(verbosity=2)
