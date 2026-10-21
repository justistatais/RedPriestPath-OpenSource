#!/usr/bin/env python3
"""Exercise quiet release diagnostics in Lua 5.1, without running native Civ VI.

The high-frequency fixtures compare native-call order and counts, not wall time.
They prevent diagnostic work from returning to ordinary UI/event processing;
actual load time and map movement still need an in-game check.
"""
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
try:
    from lupa.lua51 import LuaRuntime
except ImportError:
    sys.path.insert(0, str(ROOT.parent / ".tmp" / "refactor-rc340-python"))
    from lupa.lua51 import LuaRuntime

from generate_startup_trace import (
    diagnostics_enabled, helper_source, runtime_files, runtime_source, strip_trace,
)


EVENT_HARNESS = r'''
logs={}; calls={};
function print(value) logs[#logs+1]=value; end
function Pack(...) return {n=select('#',...),...}; end
function Event()
    local event={listeners={}};
    event.Add=function(callback)
        event.listeners[#event.listeners+1]=callback;
        return nil,'added',nil;
    end;
    event.Remove=function(callback)
        for index=#event.listeners,1,-1 do
            if event.listeners[index]==callback then table.remove(event.listeners,index); end;
        end;
    end;
    event.Fire=function(...)
        local result;
        for _,callback in ipairs(event.listeners) do result=Pack(callback(...)); end;
        if result then return unpack(result,1,result.n); end;
    end;
    return setmetatable(event,{__call=function(_,...) return event.Fire(...); end});
end
function Poison()
    return setmetatable({}, {__index=function(_,key) error('unexpected engine access '..key); end});
end
Game=Poison(); Players=Poison(); PlayerManager=Poison(); Map=Poison();
UI=Poison(); GameConfiguration=Poison(); PlayersVisibility=Poison();
Events={Tick=Event()}; GameEvents={Started=Event()}; LuaEvents={Changed=Event()};
'''


CEREMONY_HARNESS = EVENT_HARNESS + r'''
function Record(name,...)
    local values={name};
    for index=1,select('#',...) do
        local value=select(index,...);
        values[#values+1]=type(value)=='function' and '<callback>' or tostring(value);
    end;
    calls[#calls+1]=table.concat(values,'|');
end
local function Control(name)
    local methods={};
    for _,method in ipairs({'SetHide','SetInputHandler','SetShowHandler','SetShutdown',
        'RegisterEndCallback','RegisterCallback','SetSizeVal','SetSizeX','SetOffsetY',
        'SetTexture'}) do
        local key=method;
        methods[key]=function(_,...) Record(name..'.'..key,...); end;
    end;
    return methods;
end
ContextPtr=Control('ContextPtr');
Controls={};
for _,name in ipairs({'CeremonyAnimation','ContinueButton','CeremonyBackdrop','GradientT',
    'GradientB','CeremonyMark','CeremonyTitle','CeremonyLine1','CeremonyLine2',
    'CeremonyLine3','CeremonyLine4'}) do Controls[name]=Control(name); end;
UIManager={GetScreenSizeVal=function() Record('UIManager.GetScreenSizeVal'); return 1920,1080; end};
IconManager={FindIconAtlas=function(_,name,size)
    Record('IconManager.FindIconAtlas',name,size); return 0,0,'fixture.dds';
end};
Mouse={eLClick=1}; SystemUpdateUI={ScreenResize=11};
Events={SystemUpdateUI=Event()};
LuaEvents={LOTM_RP_Sequence0Ceremony_Request=Event()};
'''


def standard_lua(source):
    return re.sub(r"\s*:\s*(?:boolean|number|string|table)\b", "", source)


class QuietDiagnosticsTests(unittest.TestCase):
    def runtime(self, harness=EVENT_HARNESS, enabled=None):
        lua = LuaRuntime(unpack_returned_tuples=True)
        self.assertEqual(lua.eval('_VERSION'), 'Lua 5.1')
        lua.execute(harness)
        source = helper_source()
        if enabled is not None:
            source, count = re.subn(r"Enabled=(?:true|false)",
                                   "Enabled=" + str(enabled).lower(), source, count=1)
            self.assertEqual(count, 1)
        lua.execute(source)
        return lua

    def test_published_helper_is_disabled_and_mark_does_not_format_values(self):
        self.assertFalse(diagnostics_enabled())
        lua = self.runtime()
        lua.execute(r'''
assert(LOTM_StartupTrace.Enabled==false);
local bad=setmetatable({}, {__tostring=function() error('formatted quiet value'); end});
local originalTostring=tostring;
tostring=function() error('quiet logger converted a scalar'); end;
for index=1,5000 do LOTM_StartupTrace.Mark('quiet','ignored',index,false,nil,bad); end;
tostring=originalTostring;
assert(#logs==0);
''')

    def test_disabled_event_buses_keep_identity_and_skip_all_wrapper_work(self):
        lua = self.runtime()
        lua.execute(r'''
local markCalls=0;
LOTM_StartupTrace.Mark=function() markCalls=markCalls+1; end;
local nativeCalls=0;
local function callback(index,...)
    nativeCalls=nativeCalls+1;
    local args=Pack(...);
    assert(args.n==3 and args[1]==nil and args[2]==false and args[3]==nil);
    return nil,index,nil;
end
for _,entry in ipairs({{Events,'Tick'},{GameEvents,'Started'},{LuaEvents,'Changed'}}) do
    local bus,name=entry[1],entry[2];
    local original=bus[name];
    local originalAdd,originalRemove=original.Add,original.Remove;
    local published=LOTM_StartupTrace.Events(bus,'quiet','bus');
    assert(rawequal(published,bus));
    local added=Pack(published[name].Add(callback));
    assert(added.n==3 and added[1]==nil and added[2]=='added' and added[3]==nil);
    assert(original.listeners[1]==callback);
    for index=1,5000 do
        local value=Pack(published[name](index,nil,false,nil));
        assert(value.n==3 and value[1]==nil and value[2]==index and value[3]==nil);
    end;
    published[name].Remove(callback); assert(#original.listeners==0);
    published[name].Add(callback); assert(original.listeners[1]==callback);
    assert(bus[name]==original and original.Add==originalAdd and original.Remove==originalRemove);
end;
assert(nativeCalls==15000 and markCalls==0 and #logs==0);
assert(LOTM_StartupTrace.Events(nil,'quiet','missing')==nil);
''')

    def test_disabled_callbacks_preserve_error_object_and_stop_dispatch(self):
        lua = self.runtime()
        lua.execute(r'''
local failure={}; local later=false;
local first=function() error(failure); end;
local bus=LOTM_StartupTrace.Events(Events,'quiet','Events');
bus.Tick.Add(first); bus.Tick.Add(function() later=true; end);
local ok,value=pcall(bus.Tick.Fire);
assert(not ok and rawequal(value,failure) and not later);
assert(Events.Tick.listeners[1]==first and #logs==0);
''')

    def test_actual_system_update_ui_has_no_diagnostics_or_added_native_calls(self):
        path = ROOT / 'UI/LOTM_RP_Sequence0Ceremony.lua'
        published = path.read_text(encoding='utf-8-sig')
        snapshots = []
        for name, source in (('original', strip_trace(published)), ('published', published)):
            with self.subTest(mode=name):
                lua = self.runtime(CEREMONY_HARNESS)
                lua.execute(standard_lua(source))
                lua.execute(r'''
assert(#Events.SystemUpdateUI.listeners==1);
-- Ignore setup work and exercise the real OnUpdateUI callback. Ordinary
-- updates must not resize; actual screen resize still performs its native work.
calls={}; logs={};
for index=1,5000 do
    Events.SystemUpdateUI.Fire(0);
    if index%1000==0 then Events.SystemUpdateUI.Fire(SystemUpdateUI.ScreenResize); end;
end;
assert(#logs==0);
''')
                snapshots.append(list(lua.globals().calls.values()))
        self.assertEqual(snapshots[0], snapshots[1])
        self.assertEqual(snapshots[1].count('UIManager.GetScreenSizeVal'), 5)
        self.assertTrue(any(call.startswith('CeremonyMark.SetTexture') for call in snapshots[1]))

    def test_published_files_omit_statement_probes_but_keep_context_diagnostics(self):
        paths = runtime_files() + [ROOT / 'Scripts' / name for name in (
            'LOTM_MP241_Phase1.lua', 'LOTM_MP241_Phase2.lua', 'LOTM_MP241_Phase3.lua',
            'LOTM_RP_Gameplay_Bundle.lua', 'LOTM_MP241_MainBundle.lua',
        )]
        self.assertEqual(len(paths), 50)  # God blessing contexts plus the rescue governor details panel.
        lua = self.runtime()
        compile_source = lua.eval('function(source) local f,e=loadstring(source); return f~=nil,e; end')
        for path in paths:
            with self.subTest(file=path.name):
                source = path.read_text(encoding='utf-8-sig')
                self.assertNotIn('--[[RC342]]', source)
                self.assertIn('Enabled=false', source)
                self.assertIn('LOTM_StartupTrace.Mark', source)
                valid, error = compile_source(standard_lua(source))
                self.assertTrue(valid, error)

    def test_explicit_detailed_generation_still_records_real_event_boundaries(self):
        source = '''local function OnTick(value)
    calls[#calls+1]=value;
    return nil,value,nil;
end
Events.Tick.Add(OnTick);
'''
        detailed = runtime_source(source, 'diagnostic-fixture', detailed=True)
        self.assertIn('--[[RC342]]', detailed)
        self.assertEqual(strip_trace(detailed), source)
        lua = self.runtime(enabled=True)
        lua.execute(detailed)
        lua.execute(r'''
for index=1,50 do
    local result=Pack(Events.Tick.Fire(index));
    assert(result.n==3 and result[1]==nil and result[2]==index and result[3]==nil);
end;
assert(#calls==50 and #logs>100);
local begins,ends=0,0;
for _,line in ipairs(logs) do
    if line:find('EVENT BEGIN Events.Tick#1',1,true) then begins=begins+1; end;
    if line:find('EVENT END Events.Tick#1',1,true) then ends=ends+1; end;
end;
assert(begins==50 and ends==50);
''')


if __name__ == '__main__':
    unittest.main(verbosity=2)
