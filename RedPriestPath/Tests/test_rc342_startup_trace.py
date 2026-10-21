#!/usr/bin/env python3
"""Exercise temporary tracing in real Lua; these are not native Civ VI tests."""
from pathlib import Path
import re
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
try:
    from lupa.lua51 import LuaRuntime
except ImportError:
    sys.path.insert(0, str(ROOT.parent / ".tmp" / "refactor-rc340-python"))
    from lupa.lua51 import LuaRuntime

# Lua 5.4 accepts the empty statements rejected in Civ VI's resource 374 logs.
# Use the strict Lua 5.1 grammar, not lupa's latest backend, for these checks.

from generate_startup_trace import header, helper_source, runtime_files, runtime_source, statements, strip_trace


HARNESS = r'''
-- Test-only packing helpers keep assertions concise on Lua 5.1. The actual
-- tracing helper supplies its own compatible Pack/unpack implementation.
table.pack = function(...) return {n=select('#',...),...}; end;
table.unpack = unpack;
logs = {}; timeline = {};
function print(line)
    logs[#logs+1] = line;
    timeline[#timeline+1] = "T:" .. line;
end
function NewEvent()
    local e = { listeners = {}, operations = {}, marker = "original" };
    e.Add = function(callback)
        e.operations[#e.operations+1] = { "add", callback };
        e.listeners[#e.listeners+1] = callback;
        return nil, "added", nil, 4;
    end;
    e.Remove = function(callback)
        e.operations[#e.operations+1] = { "remove", callback };
        for index=#e.listeners,1,-1 do
            if e.listeners[index] == callback then table.remove(e.listeners,index); end;
        end;
        return nil, "removed", nil;
    end;
    e.Fire = function(...)
        local result;
        local stop = #e.listeners;
        for index=1,stop do result = table.pack(e.listeners[index](...)); end;
        if result ~= nil then return table.unpack(result,1,result.n); end;
    end;
    return setmetatable(e,{__call=function(_,...) return e.Fire(...); end});
end
Events = { Tick=NewEvent() };
GameEvents = { Started=NewEvent() };
LuaEvents = { Choice=NewEvent() };
function Poison()
    return setmetatable({}, {__index=function(_,key) error("unexpected engine access "..key); end});
end
Game=Poison(); GameConfiguration=Poison(); PlayerManager=Poison();
Players=Poison(); PlayersVisibility=Poison(); Map=Poison(); UI=Poison();
function Native(tag,...)
    timeline[#timeline+1] = "N:" .. tag;
    if tag == "explode" then error(nativeFailure); end;
    return ...;
end
'''


class TraceTests(unittest.TestCase):
    def lua(self, enabled=True):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(HARNESS)
        # Diagnostic behavior fixtures opt in explicitly. The shipped helper is
        # quiet by default; changing it must not silently stop testing wrappers.
        source, replaced = re.subn(r"Enabled=(?:true|false)",
                                  "Enabled=" + ("true" if enabled else "false"),
                                  helper_source(), count=1)
        self.assertEqual(replaced, 1)
        lua.execute(source)
        return lua

    def test_registration_remove_readd_identity_order_and_original_tables(self):
        lua = self.lua()
        lua.execute(r'''
local real = Events.Tick;
local originalAdd, originalRemove = real.Add, real.Remove;
local originalSourceMeta, originalEventMeta = getmetatable(Events), getmetatable(real);
local calls = {};
local a = function() calls[#calls+1]="a"; end;
local b = function() calls[#calls+1]="b"; end;
local external = function() calls[#calls+1]="external"; end;
real.Add(external);
local proxy = LOTM_StartupTrace.Events(Events,"fixture","Events");
assert(proxy.Tick == proxy.Tick and proxy.Missing == nil);
assert(proxy.Tick.marker == "original");
proxy.Tick.Add(a); proxy.Tick.Add(b); proxy.Tick.Add(a);
assert(real.operations[2][2] == real.operations[4][2], "duplicate callback identity changed");
assert(real.operations[2][2] ~= a, "enabled callback not wrapped");
proxy.Tick();
assert(table.concat(calls,",") == "external,a,b,a");
proxy.Tick.Remove(a);
assert(real.operations[5][2] == real.operations[2][2]);
calls = {}; proxy.Tick(); assert(table.concat(calls,",") == "external,b");
proxy.Tick.Add(a);
assert(real.operations[6][2] == real.operations[2][2], "re-added callback got a new wrapper");
proxy.Tick.Remove(external);
assert(real.operations[7][2] == external, "unwrapped removal must forward original identity");
calls = {}; proxy.Tick(); assert(table.concat(calls,",") == "b,a");
assert(Events.Tick == real and real.Add == originalAdd and real.Remove == originalRemove);
assert(getmetatable(Events) == originalSourceMeta and getmetatable(real) == originalEventMeta);
assert(rawget(Events,"Missing") == nil and rawget(real,"proxy") == nil);
''')

    def test_nil_arguments_and_multiple_returns_survive_callbacks_add_remove_and_fire(self):
        lua = self.lua()
        lua.execute(r'''
local proxy = LOTM_StartupTrace.Events(Events,"fixture","Events");
local payload = {};
local function callback(...)
    local values=table.pack(...);
    assert(values.n==5 and values[1]==nil and values[2]==payload
        and values[3]==nil and values[4]==false and values[5]==nil);
    return nil,payload,nil,false,nil;
end
local added=table.pack(proxy.Tick.Add(callback));
assert(added.n==4 and added[1]==nil and added[2]=="added" and added[3]==nil and added[4]==4);
local result=table.pack(proxy.Tick(nil,payload,nil,false,nil));
assert(result.n==5 and result[1]==nil and result[2]==payload
    and result[3]==nil and result[4]==false and result[5]==nil);
local removed=table.pack(proxy.Tick.Remove(callback));
assert(removed.n==3 and removed[1]==nil and removed[2]=="removed" and removed[3]==nil);
''')

    def test_callback_error_object_propagates_and_no_false_end_is_logged(self):
        lua = self.lua()
        lua.execute(r'''
local failure={}; local later=false;
local proxy=LOTM_StartupTrace.Events(Events,"fixture","Events");
proxy.Tick.Add(function() error(failure); end);
proxy.Tick.Add(function() later=true; end);
logs={};
local ok,details=pcall(proxy.Tick.Fire);
assert(ok==false and rawequal(details,failure) and not later);
assert(#logs==1 and logs[1]:find("EVENT BEGIN Events.Tick#1",1,true));
''')

    def test_registration_and_removal_errors_propagate_unchanged(self):
        lua = self.lua()
        lua.execute(r'''
local addFailure,removeFailure={},{};
Events.Tick.Add=function() error(addFailure); end;
Events.Tick.Remove=function() error(removeFailure); end;
local proxy=LOTM_StartupTrace.Events(Events,"fixture","Events");
local callback=function() end;
local ok,details=pcall(proxy.Tick.Add,callback);
assert(not ok and details==addFailure);
assert(#logs==1 and logs[1]:find("REGISTER BEFORE",1,true));
ok,details=pcall(proxy.Tick.Remove,callback);
assert(not ok and details==removeFailure);
''')

    def test_disabled_helper_returns_original_events_and_prints_nothing(self):
        lua = self.lua(enabled=False)
        lua.execute(r'''
assert(LOTM_StartupTrace.Events(Events,"fixture","Events")==Events);
assert(LOTM_StartupTrace.Events(nil,"fixture","Events")==nil);
local callback=function() return nil,2,nil; end;
LOTM_StartupTrace.Events(Events,"fixture","Events").Tick.Add(callback);
assert(Events.Tick.listeners[1]==callback);
local result=table.pack(Events.Tick()); assert(result.n==3 and result[2]==2);
LOTM_StartupTrace.Mark("fixture","disabled",{});
assert(#logs==0);
''')
        source = runtime_source("Events.Tick.Add(function() return nil,2,nil; end);", "disabled", detailed=True)
        lua.execute(source)
        self.assertEqual(lua.eval("#logs"), 0)

    def test_scalar_logging_never_invokes_table_or_userdata_tostring(self):
        lua = self.lua()

        class Sentinel:
            def __str__(self):
                raise AssertionError("userdata __str__ must not be called")

        lua.globals().sentinel = Sentinel()
        lua.execute(r'''
assert(type(sentinel)=="userdata");
debug.setmetatable(sentinel,{__tostring=function() error("userdata tostring invoked"); end});
local value=setmetatable({}, {__tostring=function() error("table tostring invoked"); end});
LOTM_StartupTrace.Mark("fixture","values",sentinel,value,function() end,nil,false,12,"a\nb\tc\rd");
assert(#logs==1 and logs[1]:find("<userdata>|<table>|<function>|nil|false|12|a b c d",1,true));
assert(not logs[1]:find("\n",1,true));
''')

    def test_helper_uses_no_engine_property_clock_or_random_api(self):
        source = helper_source()
        code = "\n".join(line.split("--", 1)[0] for line in source.splitlines())
        self.assertIsNone(re.search(
            r"\b(?:Game|GameConfiguration|PlayerManager|Players|Map|UI|Calendar|Automation|os)\s*[.:\[]"
            r"|\bmath\s*\.\s*random(?:seed)?\b|\bGetProperty\b|\bSetProperty\b", code
        ))
        lua = self.lua()
        lua.execute('LOTM_StartupTrace.Mark("fixture","pure",1,nil,false);')
        self.assertEqual(lua.eval("#logs"), 1)

    def test_statement_native_order_short_circuit_inline_if_and_early_return(self):
        source = r'''
local function run(flag)
    local one=Native("first",4);
    local nope=false and Native("never");
    local yes=true or Native("never");
    if flag and Native("condition",true) then Native("body"); return nil,one,nil; end
    Native("tail");
    return 9,nil;
end
result=table.pack(run(true));
assert(result.n==3 and result[1]==nil and result[2]==4 and result[3]==nil);
'''
        lua = self.lua()
        lua.execute(runtime_source(source, "semantics", detailed=True))
        lua.execute(r'''
local calls={};
for _,line in ipairs(timeline) do if line:sub(1,2)=="N:" then calls[#calls+1]=line; end end
assert(table.concat(calls,",")=="N:first,N:condition,N:body");
''')
        self.assertEqual(strip_trace(runtime_source(source, "semantics", detailed=True)), source)

    def test_local_scopes_shadowing_closures_colon_calls_and_multireturn(self):
        source = r'''
local outside="outside";
local obj={n=3};
function obj:Native(tag,...) assert(self==obj); Native(tag); return ...; end
local function evaluate()
    local outside=Native("initializer",outside);
    local captured;
    do local outside=Native("inner","inside"); captured=function() return outside; end; end
    local a,b,c=obj:Native("method",nil,false,nil);
    assert(outside=="outside" and captured()=="inside" and a==nil and b==false and c==nil);
    return obj:Native("return",nil,"done",nil);
end
result=table.pack(evaluate());
assert(result.n==3 and result[1]==nil and result[2]=="done" and result[3]==nil);
'''
        for traced in (False, True):
            with self.subTest(traced=traced):
                lua = self.lua()
                lua.execute(runtime_source(source, "scope", detailed=True) if traced else source)
                lua.execute(r'''
local calls={};
for _,line in ipairs(timeline) do if line:sub(1,2)=="N:" then calls[#calls+1]=line; end end
assert(table.concat(calls,",")=="N:initializer,N:inner,N:method,N:return");
''')

    def test_loop_break_repeat_and_no_extra_native_calls(self):
        source = r'''
local count=0;
for i=1,3 do if i==2 then break; end; Native("for",i); end
while Native("condition",count<2) do count=count+1; Native("while",count); end
repeat count=count-1; Native("repeat",count); until Native("until",count==0)
assert(count==0);
'''
        snapshots = []
        for traced in (False, True):
            lua = self.lua()
            lua.execute(runtime_source(source, "loops", detailed=True) if traced else source)
            snapshots.append(lua.eval('function() local out={}; for _,line in ipairs(timeline) do '
                                      'if line:sub(1,2)=="N:" then out[#out+1]=line; end end; '
                                      'return table.concat(out,","); end')())
        self.assertEqual(snapshots[0], snapshots[1])

    def test_native_error_preserves_object_and_has_no_after_or_later_call(self):
        source = 'Native("first");\nNative("explode");\nNative("later");\n'
        lua = self.lua()
        lua.execute("nativeFailure={};")
        instrumented = runtime_source(source, "failure", detailed=True)
        lua.globals().traced_source = instrumented
        lua.execute(r'''
local chunk,parseError=loadstring(traced_source); assert(chunk,parseError);
local ok,details=pcall(chunk); assert(not ok and details==nativeFailure);
local exploded=false;
for index,line in ipairs(timeline) do
    assert(line~="N:later");
    if line=="N:explode" then
        exploded=true;
        assert(timeline[index-1]:find("point=BEFORE L2C0:",1,true));
        assert(index==#timeline,"trace continued after native error");
    end;
end;
assert(exploded);
''')

    def test_chunk_return_and_nil_multireturn_are_not_changed(self):
        lua = self.lua()
        source = 'Native("chunk"); return nil, "done", nil'
        actual = lua.execute(runtime_source(source, "chunk", detailed=True))
        self.assertEqual(actual, (None, "done", None))
        lua.execute(r'''
local found=false;
for _,line in ipairs(logs) do
    if line:find("RETURN BEFORE",1,true) then found=true; end;
    assert(not line:find("CONTEXT END",1,true),"unreachable chunk end was logged");
end;
assert(found);
''')

    def test_statement_and_runtime_stripping_restore_exact_input_and_are_idempotent(self):
        fixtures = (
            "local a=Native('a',1); -- trailing comment without newline",
            "-- comments\r\nlocal a = Native('a', 'x;y');\r\n",
            "\nlocal function chosen() if Native('cond',true) then return Native('ret',nil,1); end end\nchosen();\n",
            "local s=[=[line one\nline two]=];\nNative(s);\n",
        )
        for source in fixtures:
            with self.subTest(source=source[:45]):
                self.assertEqual(strip_trace(statements(source, "reversible")), source)
                generated = runtime_source(source, "reversible", detailed=True)
                self.assertEqual(strip_trace(generated), source)
                self.assertEqual(runtime_source(generated, "reversible", detailed=True), generated)

    def test_function_selection_skips_search_body_but_keeps_selected_function(self):
        source = ('local function search() Native("search"); return 1; end\n'
                  'local function chosen() Native("chosen"); return search(); end\n'
                  'chosen();\n')
        detailed = statements(source, "selected", ("chosen",))
        self.assertEqual(strip_trace(detailed), source)
        self.assertNotIn("BEFORE L1", detailed)
        self.assertIn("BEFORE L2", detailed)
        self.assertIn("BEFORE L3", detailed)
        lua = self.lua()
        lua.execute(header("selected", embed=False) + detailed)

    def test_civ_type_annotations_keep_source_offsets_and_semantics(self):
        source = ('local value :number=Native("value",3);\n'
                  'local function compute(flag:boolean, text:string)\n'
                  '  if flag then return Native(text,value); end; return 0;\n'
                  'end\n'
                  'assert(compute(true,"typed")==3);\n')
        generated = runtime_source(source, "typed", detailed=True)
        self.assertEqual(strip_trace(generated), source)
        self.assertIn("BEFORE L3C2:", generated)
        parseable = re.sub(r"\s*:\s*(?:boolean|number|string|table)\b", "", generated)
        lua = self.lua()
        lua.execute(parseable)

    def test_actual_ui_and_bridge_files_are_fresh_and_compile(self):
        checked = subprocess.run(
            [sys.executable, "-B", str(ROOT / "Tests/generate_startup_trace.py"), "--check"],
            cwd=ROOT.parent, capture_output=True, text=True,
            encoding="utf-8", errors="replace", timeout=90,
        )
        self.assertEqual(checked.returncode, 0, checked.stdout + checked.stderr)
        lua = self.lua()
        paths = runtime_files()
        self.assertTrue(any(path.name == "LOTM_RESCUE_CityBootstrap.lua" for path in paths))
        self.assertTrue(any(path.name == "LOTM_QD_MultiplayerCompat.lua" for path in paths))
        self.assertTrue(any(path.name == "LOTM_MP241_PreMainBootstrap.lua" for path in paths))
        for path in paths:
            with self.subTest(file=path.name):
                source = path.read_text(encoding="utf-8")
                self.assertIn('"CONTEXT BEGIN"', source)
                self.assertIn('"CONTEXT END"', source)
                parseable = re.sub(r"\s*:\s*(?:boolean|number|string|table)\b", "", source)
                compiled = lua.eval("function(s) local chunk,err=loadstring(s); return chunk~=nil,err; end")(parseable)
                self.assertEqual(compiled, (True, None), compiled)

    def test_three_actual_phase_outputs_compile_without_executing_gameplay(self):
        from generate_gameplay_bundle import generate_phase_router

        lua = self.lua()
        for module in ("LOTM_RESCUE_Phase1", "LOTM_RESCUE_Phase2Test", "LOTM_RESCUE_Phase3"):
            with self.subTest(module=module):
                source = generate_phase_router(module)
                self.assertLess(len(source.encode("utf-8")), 250_000)
                compiled = lua.eval("function(s) local chunk,err=loadstring(s); return chunk~=nil,err; end")(source)
                self.assertEqual(compiled, (True, None), compiled)


if __name__ == "__main__":
    unittest.main(verbosity=2)
