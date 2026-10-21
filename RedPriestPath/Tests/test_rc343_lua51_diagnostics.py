#!/usr/bin/env python3
"""Guard diagnostic instrumentation against Lua 5.1 empty-statement regressions.

Civ VI/HavokScript is not the embedded test VM. Lua 5.1 nevertheless catches
the ``unexpected symbol near ';'`` syntax rejected by the actual r374 logs,
which our previous Lua 5.4-only compilation accepted. No native game runs here.
"""
from pathlib import Path
import re
import sys
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
try:
    from lupa.lua51 import LuaRuntime
except ImportError:
    sys.path.insert(0, str(ROOT.parent / ".tmp" / "refactor-rc340-python"))
    from lupa.lua51 import LuaRuntime

from generate_startup_trace import helper_source, runtime_files, runtime_source, strip_trace


HARNESS = r'''
logs={}; calls={}; failure={};
function print(line) logs[#logs+1]=line; end
function Pack(...) return {n=select('#',...),...}; end
function Native(tag,...)
    calls[#calls+1]=tag;
    if tag=='explode' then error(failure); end
    return ...;
end
function Poison()
    return setmetatable({}, {__index=function(_,key) error('unexpected engine read '..key); end});
end
Game=Poison(); GameConfiguration=Poison(); PlayerManager=Poison();
Players=Poison(); PlayersVisibility=Poison(); Map=Poison(); UI=Poison();
Events={}; GameEvents={}; LuaEvents={};
'''


def standard_lua(source):
    """Only remove Civ's four known type annotations; retain every semicolon."""
    return re.sub(r"\s*:\s*(?:boolean|number|string|table)\b", "", source)


def targets():
    return runtime_files() + [ROOT / "Scripts" / name for name in (
        "LOTM_MP241_Phase1.lua", "LOTM_MP241_Phase2.lua", "LOTM_MP241_Phase3.lua",
        "LOTM_RP_Gameplay_Bundle.lua", "LOTM_MP241_MainBundle.lua",
    )]


class Lua51DiagnosticsTests(unittest.TestCase):
    def lua(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        self.assertEqual(lua.eval("_VERSION"), "Lua 5.1")
        lua.execute(HARNESS)
        # These grammar/error-boundary fixtures intentionally exercise full
        # tracing, even when the published helper defaults to quiet mode.
        source, replaced = re.subn(r"Enabled=(?:true|false)", "Enabled=true",
                                  helper_source(), count=1)
        self.assertEqual(replaced, 1)
        lua.execute(source)
        return lua

    def compile(self, source, name):
        lua = LuaRuntime(unpack_returned_tuples=True)
        return lua.eval("function(s,n) local f,e=loadstring(s,n); return f~=nil,e; end")(
            standard_lua(source), name
        )

    def run_fixture(self, source, expected_calls):
        generated = runtime_source(source, "lua51-fixture", detailed=True)
        self.assertEqual(strip_trace(generated), source)
        self.assertEqual(runtime_source(generated, "lua51-fixture", detailed=True), generated)
        for label, candidate in (("original", source), ("instrumented", generated)):
            with self.subTest(version=label):
                lua = self.lua()
                lua.execute(standard_lua(candidate))
                self.assertEqual(lua.eval("table.concat(calls, ',')"), expected_calls)

    def test_legacy_after_point_reproduces_actual_empty_statement_error(self):
        source = 'Native("first");\nNative("second");\n'
        # This is the r374 insertion rule around the original first call. The
        # AFTER point terminated itself before the original source semicolon.
        legacy = (
            'LOTM_StartupTrace.Mark("legacy","BEFORE"); '
            'Native("first")'
            'LOTM_StartupTrace.Mark("legacy","AFTER"); '
            ';\nNative("second");\n'
        )
        ok, error = self.compile(legacy, "r374-double-semicolon")
        self.assertFalse(ok)
        self.assertIn("unexpected symbol near ';'", error)
        self.run_fixture(source, "first,second")

    def test_terminators_comments_consecutive_calls_and_block_ends(self):
        fixtures = (
            'Native("a"); Native("b");',
            'Native("a") Native("b")',
            'Native("a"); Native("b")',
            'Native("a") Native("b");',
            'Native("a"); -- trailing comment\nNative("b");',
            'Native("a") -- trailing comment\nNative("b")',
            'Native("a") --[[between call and terminator]]; Native("b");',
            'Native("a")\n;\nNative("b");',
            'if true then Native("a"); end; Native("b");',
            'if false then Native("never"); else Native("a") end Native("b")',
            'do Native("a"); end; Native("b");',
            'do Native("a") end Native("b")',
            'Native("a"); (function() Native("b"); end)();',
            'Native("a") --[[preserve separator]]; (function() Native("b") end)()',
            'local function f() Native("a"); end; f(); Native("b");',
            'local function f() Native("a") end f() Native("b")',
            'Native("a"); Native("b"); -- EOF comment without newline',
            'Native("a") Native("b") -- EOF comment without newline',
            'Native("a");\r\nNative("b");\r\n',
        )
        for index, source in enumerate(fixtures):
            with self.subTest(fixture=index):
                self.run_fixture(source, "a,b")

    def test_assignment_scope_colon_calls_and_multiple_returns(self):
        self.run_fixture(r'''
local outside='outer'; local object={};
function object:Call(tag,...) assert(self==object); return Native(tag,...); end
local function run()
    local outside=Native('init',outside);
    local capture;
    do local outside=Native('shadow','inner'); capture=function() return outside; end; end
    assert(outside=='outer' and capture()=='inner');
    local a,b,c=object:Call('method',nil,false,nil);
    assert(a==nil and b==false and c==nil);
    return object:Call('return',nil,9,nil);
end
local value=Pack(run());
assert(value.n==3 and value[1]==nil and value[2]==9 and value[3]==nil);
''', "init,shadow,method,return")

    def test_short_circuit_and_early_return_do_not_add_native_calls(self):
        self.run_fixture(r'''
local function run(flag)
    local never=false and Native('never');
    local yes=true or Native('never');
    if flag and Native('condition',true) then Native('body'); return nil,4,nil; end;
    Native('tail'); return 9;
end
local value=Pack(run(true));
assert(value.n==3 and value[1]==nil and value[2]==4 and value[3]==nil);
''', "condition,body")

    def test_loops_break_and_repeat_conditions_keep_order(self):
        self.run_fixture(r'''
local count=0;
for i=1,3 do if i==2 then break; end; Native('for'); end;
while Native('condition',count<2) do count=count+1; Native('while'); end;
repeat count=count-1; Native('repeat'); until Native('until',count==0);
assert(count==0);
''', "for,condition,while,condition,while,condition,repeat,until,repeat,until")

    def test_native_error_object_and_stop_boundary_are_preserved(self):
        source = 'Native("first");\nNative("explode");\nNative("later");\n'
        for traced in (False, True):
            with self.subTest(traced=traced):
                lua = self.lua()
                lua.globals().candidate = runtime_source(source, "error", detailed=True) if traced else source
                lua.execute(r'''
local chunk,details=loadstring(candidate); assert(chunk,details);
local ok,details=pcall(chunk);
assert(not ok and rawequal(details,failure));
assert(table.concat(calls,',')=='first,explode');
''')
                if traced:
                    self.assertIn("BEFORE L2C0:", lua.eval("logs[#logs]"))

    def test_chunk_returns_remain_legal_and_keep_trailing_nil(self):
        for terminator in ("", ";"):
            with self.subTest(terminator=terminator):
                source = 'Native("chunk"); return nil,"done",nil' + terminator
                lua = self.lua()
                result = lua.execute(runtime_source(source, "chunk", detailed=True))
                self.assertEqual(result, (None, "done", None))
                self.assertEqual(lua.eval("table.concat(calls, ',')"), "chunk")
                self.assertNotIn("CONTEXT END", lua.eval("logs[#logs]"))

    def test_annotations_do_not_hide_semicolon_errors(self):
        self.run_fixture(r'''
local value:number=Native('value',3);
local function run(flag:boolean,text:string)
    if flag then return Native(text,value); end; return 0;
end
assert(run(true,'typed')==3);
''', "value,typed")
        self.assertEqual(standard_lua("local value:number=1;;"), "local value=1;;")

    def test_all_45_current_ui_and_standalone_files_compile(self):
        paths = runtime_files()
        self.assertEqual(len(paths), 45, "update this explicit coverage count if runtime actions change")
        for path in paths:
            with self.subTest(file=path.name):
                self.assertLess(path.stat().st_size, 500_000)
                source = path.read_text(encoding="utf-8-sig")
                self.assertIn('"CONTEXT BEGIN"', source)
                ok, error = self.compile(source, path.name)
                self.assertTrue(ok, error)

    def test_all_three_actual_phase_files_and_two_bundles_compile(self):
        for path in targets()[-5:]:
            with self.subTest(file=path.name):
                self.assertLess(path.stat().st_size, 3_000_000)
                ok, error = self.compile(path.read_text(encoding="utf-8-sig"), path.name)
                self.assertTrue(ok, error)

    def test_published_rc341_baseline_compiles_all_42_targets(self):
        archive = ROOT.parent / "dist/RedPriestPath-0.1.0-rc.341.zip"
        self.assertLess(archive.stat().st_size, 100_000_000)
        with zipfile.ZipFile(archive) as bundle:
            for path in targets():
                # CampAction was first activated in resource 379; historical
                # controls preserve the original 42 active targets.
                if path.name in {"LOTM_RESCUE_CampAction.lua", "LOTM_RESCUE_RuntimeEvents.lua", "LOTM_JUSTICE_Story.lua", "LOTM_MS_Governors.lua", "LOTM_GodBlessingFX.lua", "LOTM_StormBlessing.lua", "LOTM_StormWorldInput.lua", "LOTM_RESCUE_GovernorDetailsPanel.lua"}: continue
                name = "RedPriestPath/" + path.relative_to(ROOT).as_posix()
                with self.subTest(file=path.name):
                    self.assertLess(bundle.getinfo(name).file_size, 3_000_000)
                    ok, error = self.compile(bundle.read(name).decode("utf-8-sig"), name)
                    self.assertTrue(ok, error)

    def test_published_rc342_regression_is_specific_and_reproducible(self):
        archive = ROOT.parent / "dist/RedPriestPath-0.1.0-rc.342.zip"
        self.assertLess(archive.stat().st_size, 100_000_000)
        passed = set()
        failed = set()
        with zipfile.ZipFile(archive) as bundle:
            for path in targets():
                # CampAction was first activated in resource 379; historical
                # controls preserve the original 42 active targets.
                if path.name in {"LOTM_RESCUE_CampAction.lua", "LOTM_RESCUE_RuntimeEvents.lua", "LOTM_JUSTICE_Story.lua", "LOTM_MS_Governors.lua", "LOTM_GodBlessingFX.lua", "LOTM_StormBlessing.lua", "LOTM_StormWorldInput.lua", "LOTM_RESCUE_GovernorDetailsPanel.lua"}: continue
                name = "RedPriestPath/" + path.relative_to(ROOT).as_posix()
                self.assertLess(bundle.getinfo(name).file_size, 3_000_000)
                ok, error = self.compile(bundle.read(name).decode("utf-8-sig"), name)
                if ok:
                    passed.add(path.name)
                else:
                    failed.add(path.name)
                    self.assertIn("unexpected symbol near ';'", error, name)
        self.assertEqual(passed, {
            "LOTM_RESCUE_CityBootstrap.lua", "LOTM_RP_Gameplay_Bundle.lua", "LOTM_MP241_MainBundle.lua"
        })
        self.assertEqual(len(failed), 39)


if __name__ == "__main__":
    unittest.main(verbosity=2)
