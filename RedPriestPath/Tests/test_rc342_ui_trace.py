#!/usr/bin/env python3
"""Run the actual diagnostic bootstrap UI with native-call recording stubs.

These tests verify guards, request deduplication and diagnostic boundaries.
They do not establish whether Civilization VI survives a native hosted start.
"""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
try:
    from lupa import LuaRuntime
except ImportError:
    sys.path.insert(0, str(ROOT.parent / ".tmp" / "refactor-rc340-python"))
    from lupa import LuaRuntime

UI_SOURCE = ROOT / "UI/LOTM_RESCUE_CityBootstrap.lua"
BASELINE = ROOT.parent / "backups/rc342-startup-trace/RedPriestPath/UI/LOTM_RESCUE_CityBootstrap.lua"

HARNESS = r'''
calls={}; requests={}; trace={}; logs={}; props={};
network=true; rescue=true; localID=0; requestResult=true; reenter=false;
function Native(name,...)
    local parts={name};
    for i=1,select('#',...) do parts[#parts+1]=tostring(select(i,...)); end;
    calls[#calls+1]=table.concat(parts,'|');
    if failAt==name then error('simulated native failure at '..name); end;
end
function Event(name)
    local e={handlers={}};
    e.Add=function(fn) Native('Event.Add',name); e.handlers[#e.handlers+1]=fn; end;
    e.Fire=function(...) for _,fn in ipairs(e.handlers) do fn(...); end; end;
    return e;
end
Events={LoadScreenClose=Event('LoadScreenClose'),LocalPlayerTurnBegin=Event('LocalPlayerTurnBegin'),
    PlayerTurnActivated=Event('PlayerTurnActivated'),GameCoreEventPublishComplete=Event('GameCoreEventPublishComplete')};
print=function(value) logs[#logs+1]=value; end;
LOTM_StartupTrace.Mark=function(context,point,...)
    assert(context=='CityBootstrap' or context=='LOTM_RESCUE_CityBootstrap');
    for i=1,select('#',...) do
        local t=type(select(i,...));
        assert(t=='nil' or t=='number' or t=='string' or t=='boolean','diagnostic received '..t);
    end;
    trace[#trace+1]=point;
end;
function HasTrace(point)
    for _,item in ipairs(trace) do if item==point then return true; end; end;
    return false;
end
function CountTrace(point)
    local count=0; for _,item in ipairs(trace) do if item==point then count=count+1; end; end;
    return count;
end
function ClearTrace() trace={}; end
Game={
    GetLocalPlayer=function() Native('Game.GetLocalPlayer'); return localID; end,
    GetProperty=function(key) Native('Game.GetProperty',key); return props[key]; end,
    SetProperty=function() error('UI must not modify Gameplay properties'); end
};
GameConfiguration={
    IsAnyMultiplayer=function() Native('GameConfiguration.IsAnyMultiplayer'); return network; end,
    GetValue=function(key) Native('GameConfiguration.GetValue',key); return rescue; end
};
GameInfo={Resources={RESOURCE_LOTM_RESCUE_ALLY_BANNER={Index=1}}};
function Player(id,human)
    local p={id=id,alive=true,major=true,human=human,active=true};
    for _,entry in ipairs({{'IsAlive','alive'},{'IsMajor','major'},{'IsHuman','human'},
                           {'IsTurnActive','active'},{'GetID','id'}}) do
        local name,key=entry[1],entry[2];
        p[name]=function(self) Native('Player.'..name,self.id); return self[key]; end;
    end;
    return p;
end
Players={[0]=Player(0,true),[1]=Player(1,false),[2]=Player(2,true)};
candidates={Players[1],Players[0],Players[2]};
PlayerManager={GetAliveMajors=function() Native('PlayerManager.GetAliveMajors'); return candidates; end};
PlayerOperations={EXECUTE_SCRIPT=55};
UI={RequestPlayerOperation=function(id,operation,args)
    Native('UI.RequestPlayerOperation',id,operation,args.OnStart,args.Trigger);
    requests[#requests+1]={id=id,operation=operation,command=args.OnStart,trigger=args.Trigger};
    if reenter then Events.GameCoreEventPublishComplete.Fire(); end;
    if requestError~=nil then error(requestError); end;
    return requestResult;
end};
function Ready(serial)
    props.LOTM_RESCUE_PHASE2A_STATE='READY'; props.LOTM_RESCUE_PHASE2A_VERSION=11;
    props.LOTM_MP241_MAIN_LOAD_SERIAL=serial or 0;
end
'''


class UIStartupTraceTests(unittest.TestCase):
    def runtime(self, setup="", source=UI_SOURCE):
        lua = LuaRuntime(unpack_returned_tuples=True)
        # Keep the real event proxy when the generated UI header is present;
        # replace only Mark to inspect the handwritten diagnostic points.
        lua.execute((ROOT / "Scripts/LOTM_StartupTrace.lua").read_text(encoding="utf-8-sig"))
        lua.execute(HARNESS)
        lua.execute(setup)
        lua.execute(source.read_text(encoding="utf-8-sig"))
        return lua

    def test_all_early_return_reasons_and_native_boundaries(self):
        scenarios = [
            ("", "Events.LocalPlayerTurnBegin.Fire()", "Submit.RETURN.load_screen_open"),
            ("GameInfo.Resources={}; rescue=false", "Events.LoadScreenClose.Fire()", "Submit.RETURN.not_rescue"),
            ("localID=-1", "Events.LoadScreenClose.Fire()", "GetRequestingPlayer.RETURN.no_player"),
            ("Players[0]=nil", "Events.LoadScreenClose.Fire()", "GetRequestingPlayer.RETURN.no_player"),
            ("Players[0].alive=false", "Events.LoadScreenClose.Fire()", "GetRequestingPlayer.RETURN.dead"),
            ("Players[0].major=false", "Events.LoadScreenClose.Fire()", "GetRequestingPlayer.RETURN.not_major"),
            ("Players[0].human=false", "Events.LoadScreenClose.Fire()", "GetRequestingPlayer.RETURN.not_human"),
            ("localID=2", "Events.LoadScreenClose.Fire()", "GetRequestingPlayer.RETURN.not_elected"),
            ("Players[0].active=false", "Events.LoadScreenClose.Fire()", "GetRequestingPlayer.RETURN.inactive"),
            ("network=false; Ready()", "Events.LoadScreenClose.Fire()", "Submit.RETURN.ready_singleplayer"),
        ]
        for setup, action, expected in scenarios:
            with self.subTest(reason=expected, setup=setup):
                lua = self.runtime(setup)
                lua.execute(action)
                self.assertTrue(lua.globals().HasTrace(expected))
                self.assertEqual(0, len(lua.globals().requests))
                event = "LocalPlayerTurnBegin" if "LocalPlayer" in action else "LoadScreenClose"
                self.assertTrue(lua.globals().HasTrace("Event." + event + ".RETURN"))
                self.assertIn(lua.globals().trace[len(lua.globals().trace)],
                              ["Event." + event + ".RETURN", "EVENT END Events." + event + "#1"])

    def test_false_and_error_results_release_reservation_for_retry(self):
        for setup in ["requestResult=false", "requestError='native request rejected'",
                      "requestError=setmetatable({}, {__tostring=function() error('must not stringify object') end})"]:
            with self.subTest(setup=setup):
                lua = self.runtime(setup)
                lua.execute(r'''
                    Events.LoadScreenClose.Fire();
                    assert(#requests==1);
                    assert(HasTrace('Request.RequestPlayerOperation.BEFORE'));
                    assert(HasTrace('Request.RequestPlayerOperation.RETURN'));
                    assert(HasTrace('Request.RETURN.failed'));
                    assert(HasTrace('Submit.RETURN.city_request_failed'));
                    requestResult=true; requestError=nil;
                    Events.LocalPlayerTurnBegin.Fire();
                    Events.LocalPlayerTurnBegin.Fire();
                    assert(#requests==2);
                    assert(CountTrace('Submit.RETURN.city_submitted')==1);
                    assert(HasTrace('Submit.RETURN.city_already_submitted'));
                ''')

    def test_success_and_nil_results_do_not_resubmit_on_publish_reentry(self):
        for setup in ["reenter=true", "reenter=true; requestResult=nil"]:
            with self.subTest(setup=setup):
                lua = self.runtime(setup)
                lua.execute(r'''
                    Events.LoadScreenClose.Fire();
                    Events.LocalPlayerTurnBegin.Fire();
                    Events.PlayerTurnActivated.Fire(0);
                    Events.PlayerTurnActivated.Fire(2);
                    Events.GameCoreEventPublishComplete.Fire();
                    assert(#requests==1);
                    assert(HasTrace('GetRequestingPlayer.RETURN.player'));
                    assert(HasTrace('GetRequestingPlayer.Candidate.SKIP.not_human'));
                    assert(HasTrace('Request.RETURN.accepted'));
                    assert(HasTrace('Event.PlayerTurnActivated.SKIP.not_local'));
                    assert(CountTrace('Request.RequestPlayerOperation.BEFORE')==1);
                    assert(CountTrace('Request.RequestPlayerOperation.RETURN')==1);
                    assert(HasTrace('NeedsBootstrap.StateProperty.BEFORE'));
                    assert(HasTrace('NeedsBootstrap.StateProperty.RETURN'));
                    assert(HasTrace('NeedsBootstrap.VersionProperty.BEFORE'));
                    assert(HasTrace('NeedsBootstrap.VersionProperty.RETURN'));
                ''')

    def test_main_retry_serial_and_acknowledgements(self):
        lua = self.runtime()
        lua.execute(r'''
            Events.LoadScreenClose.Fire();
            assert(#requests==1);
            Ready(7); requestResult=false;
            Events.GameCoreEventPublishComplete.Fire();
            assert(#requests==2 and HasTrace('Submit.RETURN.main_request_failed'));
            assert(HasTrace('Ack.City.READY'));
            requestResult=true; reenter=true;
            Events.LocalPlayerTurnBegin.Fire();
            assert(#requests==3);
            props.LOTM_MP241_MAIN_LOAD_STATE='LOADED';
            Events.GameCoreEventPublishComplete.Fire();
            assert(not HasTrace('Ack.Main.COMPLETE'));
            props.LOTM_MP241_MAIN_LOAD_SERIAL=8;
            Events.GameCoreEventPublishComplete.Fire();
            Events.GameCoreEventPublishComplete.Fire();
            assert(#requests==3 and CountTrace('Ack.Main.COMPLETE')==1);
            assert(HasTrace('Submit.MainSerialProperty.BEFORE'));
            assert(HasTrace('Submit.MainSerialProperty.RETURN.expected'));
            assert(HasTrace('Ack.MainStateProperty.BEFORE'));
            assert(HasTrace('Ack.MainStateProperty.RETURN'));
            assert(HasTrace('Ack.MainSerialProperty.BEFORE'));
            assert(HasTrace('Ack.MainSerialProperty.RETURN'));
        ''')

    def test_configuration_fallback_and_candidate_short_circuit(self):
        lua = self.runtime("GameInfo.Resources={}; rescue=1; Players[1].alive=false")
        lua.execute(r'''
            Events.LoadScreenClose.Fire();
            assert(#requests==1);
            assert(HasTrace('IsRescueModeConfigured.GetValue.BEFORE'));
            assert(HasTrace('IsRescueModeConfigured.GetValue.RETURN'));
            assert(HasTrace('IsRescueModeConfigured.RETURN.configured'));
            assert(HasTrace('GetRequestingPlayer.Candidate.SKIP.dead'));
            for _,call in ipairs(calls) do assert(call~='Player.IsHuman|1'); end;
        ''')
        for setup, point in [("GameConfiguration=nil; Ready()", "IsNetworkGame.RETURN.no_configuration"),
                             ("GameConfiguration.IsAnyMultiplayer=nil; Ready()", "IsNetworkGame.RETURN.no_api")]:
            lua = self.runtime(setup)
            lua.execute("Events.LoadScreenClose.Fire()")
            self.assertTrue(lua.globals().HasTrace(point))

    def test_native_failure_leaves_before_marker_without_return(self):
        probes = [
            ("Game.GetLocalPlayer", "GetRequestingPlayer.GetLocalPlayer"),
            ("Player.IsAlive", "GetRequestingPlayer.IsAlive"),
            ("Player.IsMajor", "GetRequestingPlayer.IsMajor"),
            ("Player.IsHuman", "GetRequestingPlayer.IsHuman"),
            ("GameConfiguration.IsAnyMultiplayer", "IsNetworkGame.IsAnyMultiplayer"),
            ("PlayerManager.GetAliveMajors", "GetRequestingPlayer.GetAliveMajors"),
            ("Player.GetID", "GetRequestingPlayer.Candidate.GetID"),
            ("Player.IsTurnActive", "GetRequestingPlayer.IsTurnActive"),
        ]
        for api, point in probes:
            with self.subTest(api=api):
                lua = self.runtime()
                lua.globals().failAt = api
                lua.execute("eventOK=pcall(Events.LoadScreenClose.Fire)")
                self.assertFalse(lua.globals().eventOK)
                self.assertTrue(lua.globals().HasTrace(point + ".BEFORE"))
                self.assertFalse(lua.globals().HasTrace(point + ".RETURN"))
                self.assertEqual(0, len(lua.globals().requests))

    def test_success_result_never_stringifies_userdata(self):
        class OpaqueResult:
            def __str__(self):
                raise AssertionError("logger must not stringify userdata")

        lua = self.runtime()
        lua.globals().requestResult = OpaqueResult()
        lua.execute("Events.LoadScreenClose.Fire(); assert(#requests==1); assert(HasTrace('Request.RETURN.accepted'))")

    @unittest.skipUnless(BASELINE.exists(), "pre-diagnostic UI backup is outside the installed mod")
    def test_diagnostics_preserve_original_native_call_order_and_requests(self):
        scenarios = [
            ("", "Events.LocalPlayerTurnBegin.Fire(); Events.LoadScreenClose.Fire(); Events.LocalPlayerTurnBegin.Fire()"),
            ("Players[0].active=false", "Events.LoadScreenClose.Fire(); Players[0].active=true; Events.PlayerTurnActivated.Fire(0)"),
            ("localID=-1", "Events.LoadScreenClose.Fire(); Events.GameCoreEventPublishComplete.Fire()"),
            ("Players[0].alive=false", "Events.LoadScreenClose.Fire()"),
            ("Players[0].major=false", "Events.LoadScreenClose.Fire()"),
            ("Players[0].human=false", "Events.LoadScreenClose.Fire()"),
            ("localID=2", "Events.LoadScreenClose.Fire(); Ready(); Events.GameCoreEventPublishComplete.Fire()"),
            ("GameInfo.Resources={}; rescue=false", "Events.LoadScreenClose.Fire(); Events.GameCoreEventPublishComplete.Fire()"),
            ("GameInfo.Resources={}; rescue=1; Players[1].alive=false", "Events.LoadScreenClose.Fire()"),
            ("GameConfiguration=nil; Ready()", "Events.LoadScreenClose.Fire()"),
            ("GameConfiguration.IsAnyMultiplayer=nil; Ready()", "Events.LoadScreenClose.Fire()"),
            ("requestResult=false", "Events.LoadScreenClose.Fire(); requestResult=true; Events.LocalPlayerTurnBegin.Fire()"),
            ("requestError='failure'", "Events.LoadScreenClose.Fire(); requestError=nil; Events.LocalPlayerTurnBegin.Fire()"),
            ("reenter=true", "Events.LoadScreenClose.Fire(); Ready(7); Events.GameCoreEventPublishComplete.Fire(); props.LOTM_MP241_MAIN_LOAD_STATE='LOADED'; props.LOTM_MP241_MAIN_LOAD_SERIAL=8; Events.GameCoreEventPublishComplete.Fire()"),
            ("Ready(5); reenter=true", "Events.LoadScreenClose.Fire(); Events.PlayerTurnActivated.Fire(2); Events.GameCoreEventPublishComplete.Fire()"),
            ("Ready(); network=false", "Events.LoadScreenClose.Fire(); Events.GameCoreEventPublishComplete.Fire()"),
        ]
        for setup, action in scenarios:
            with self.subTest(setup=setup, action=action):
                snapshots = []
                for source in [BASELINE, UI_SOURCE]:
                    lua = self.runtime(setup, source)
                    lua.execute(action)
                    calls = list(lua.globals().calls.values())
                    requests = [dict(request.items()) for request in lua.globals().requests.values()]
                    snapshots.append((calls, requests, dict(lua.globals().props.items())))
                self.assertEqual(*snapshots)


if __name__ == "__main__":
    unittest.main()
