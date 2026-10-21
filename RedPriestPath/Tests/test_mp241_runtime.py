#!/usr/bin/env python3
"""Execute the MP adapter/bridge/UI in Lua with bounded Civ VI API stubs.

Requires lupa (Lua 5.4/5.5); this checks callback behavior, not Civ VI native
mutation safety or a real network session.
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


HARNESS = r'''
props = {}; writes = {}; requests = {}; logs = {}; network = true;
configured = true; marker = false; turn = 4; localID = 1; includes = 0;
function Event()
    local e = { listeners = {} };
    e.Add = function(fn) e.listeners[#e.listeners+1] = fn; end;
    e.Fire = function(...)
        local stop = #e.listeners;
        for i=1,stop do e.listeners[i](...); end;
    end;
    return e;
end
function EventCollection()
    return setmetatable({}, {__index=function(t,k) local e=Event(); rawset(t,k,e); return e; end});
end
Events = EventCollection(); GameEvents = EventCollection();
GameConfiguration = {
    IsAnyMultiplayer=function() return network; end,
    GetValue=function(key) if key=='GAMEMODE_LOTM_RESCUE' then return configured; end; return 2468; end
};
MapConfiguration = { GetValue=function() return 1234; end };
GameInfo = { Resources=setmetatable({}, {__index=function(_,k)
    if marker and k=='RESOURCE_LOTM_RESCUE_ALLY_BANNER' then return {}; end
end}) };
Game = {
    GetProperty=function(k) return props[k]; end,
    SetProperty=function(k,v) writes[#writes+1]={k,v}; props[k]=v; end,
    GetCurrentGameTurn=function() return turn; end,
    GetLocalPlayer=function() return localID; end
};
function Player(id,human,alive,major)
    local p={id=id,human=human,alive=alive,major=major,active=true};
    p.GetID=function(self) return self.id; end;
    p.IsHuman=function(self) return self.human; end;
    p.IsAlive=function(self) return self.alive; end;
    p.IsMajor=function(self) return self.major; end;
    p.IsTurnActive=function(self) return self.active; end;
    return p;
end
Players = { [0]=Player(0,false,true,true), [1]=Player(1,true,true,true),
    [2]=Player(2,true,true,true), [3]=Player(3,true,false,true), [4]=Player(4,true,true,false) };
PlayerManager = { GetAliveMajors=function() return {Players[2],Players[0],Players[1]}; end };
UI = { RequestPlayerOperation=function(id,operation,args)
    if rejectRequest then return false; end;
    if throwRequest then error('request failed'); end;
    requests[#requests+1]={id=id,command=args.OnStart,trigger=args.Trigger};
    if onRequest then onRequest(); end;
end };
PlayerOperations = { EXECUTE_SCRIPT=55 };
print = function(text) logs[#logs+1]=text; end;
include = function(name)
    assert(name=='LOTM_MP241_MainBundle'); includes=includes+1;
    if onInclude then onInclude(); end;
    if failInclude then error('partial include failed'); end;
    if not silentInclude then LOTM_MP241_MAIN_READY=true; end;
end;
function Ready()
    props.LOTM_RESCUE_PHASE2A_STATE='READY'; props.LOTM_RESCUE_PHASE2A_VERSION=11;
end
'''


class MultiplayerRuntimeTests(unittest.TestCase):
    def runtime(self, setup=""):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(HARNESS)
        lua.execute(setup)
        return lua

    def load(self, lua, relative):
        lua.execute((ROOT / relative).read_text(encoding="utf-8-sig"))

    def test_adapter_only_mutates_in_synchronized_callbacks(self):
        lua = self.runtime()
        self.load(lua, "Scripts/LOTM_MP241_Compat.lua")
        lua.execute(r'''
            calls={};
            LOTM_MP_TurnSync.Add(function(id,first) assert(first); calls[#calls+1]='turn:'..id; end,'Test');
            LOTM_MP_TurnSync.RunStartup(function() calls[#calls+1]='startup'; end,'Test');
            assert(#calls==0 and #writes==0);
            assert(#Events.PlayerTurnActivated.listeners==0);
            Events.PlayerTurnActivated.Fire(1,true); assert(#calls==0);
            GameEvents.PlayerTurnStarted.Fire(1);
            assert(calls[1]=='startup' and calls[2]=='turn:1');
            GameEvents.PlayerTurnStarted.Fire(1); assert(#calls==2);
            GameEvents.PlayerTurnStarted.Fire(2); assert(#calls==3);
            turn=turn+1; GameEvents.PlayerTurnStarted.Fire(1); assert(#calls==4);
        ''')

    def test_turn_guards_reentry_duplicate_registration_invalid_ids_and_reload(self):
        lua = self.runtime()
        self.load(lua, "Scripts/LOTM_MP241_Compat.lua")
        lua.execute(r'''
            count=0;
            function Handler(id) count=count+1; GameEvents.PlayerTurnStarted.Fire(id); end;
            assert(LOTM_MP_TurnSync.Add(Handler,'Dedup'));
            assert(not LOTM_MP_TurnSync.AddSynchronized(Handler,'Dedup'));
            GameEvents.PlayerTurnStarted.Fire(nil);
            GameEvents.PlayerTurnStarted.Fire(-1);
            GameEvents.PlayerTurnStarted.Fire(1.5);
            assert(count==0 and #writes==0);
            GameEvents.PlayerTurnStarted.Fire(1); assert(count==1);
            LOTM_MP_TurnSync=nil; GameEvents=EventCollection();
        ''')
        self.load(lua, "Scripts/LOTM_MP241_Compat.lua")
        lua.execute(r'''
            assert(LOTM_MP_TurnSync.Add(Handler,'Dedup'));
            GameEvents.PlayerTurnStarted.Fire(1); assert(count==1);
            turn=turn+1; GameEvents.PlayerTurnStarted.Fire(1); assert(count==2);
        ''')

    def test_missing_native_property_can_return_zero_lua_values(self):
        lua = self.runtime("Game.GetProperty=function(key) if props[key]~=nil then return props[key]; end; end")
        self.load(lua, "Scripts/LOTM_MP241_Compat.lua")
        lua.execute(r'''
            count=0; LOTM_MP_TurnSync.Add(function() count=count+1; end,'NoReturn');
            GameEvents.PlayerTurnStarted.Fire(1); assert(count==1);
        ''')

    def test_failures_do_not_replay_partial_mutations(self):
        lua = self.runtime()
        self.load(lua, "Scripts/LOTM_MP241_Compat.lua")
        lua.execute(r'''
            partial=0; normal=0; startup=0;
            LOTM_MP_TurnSync.Add(function() partial=partial+1; error('partial'); end,'Partial');
            LOTM_MP_TurnSync.Add(function() normal=normal+1; end,'Normal');
            LOTM_MP_TurnSync.RunStartup(function() startup=startup+1; error('startup partial'); end,'Normal');
            GameEvents.PlayerTurnStarted.Fire(1); GameEvents.PlayerTurnStarted.Fire(1);
            assert(partial==1 and normal==0 and startup==1);
            turn=turn+1; GameEvents.PlayerTurnStarted.Fire(1);
            assert(partial==2 and normal==0 and startup==1);
            assert(not LOTM_MP_TurnSync.RunPendingStartups());
        ''')

    def test_startup_once_per_context_and_false_is_not_failure(self):
        lua = self.runtime()
        self.load(lua, "Scripts/LOTM_MP241_Compat.lua")
        lua.execute(r'''
            count=0;
            LOTM_MP_TurnSync.RunStartup(function() count=count+1; return false; end,'OnlyStartup');
            assert(LOTM_MP_TurnSync.RunPendingStartups());
            assert(LOTM_MP_TurnSync.RunPendingStartups());
            GameEvents.PlayerTurnStarted.Fire(1); assert(count==1);
        ''')

    def test_bridge_mode_gate_and_request_validation(self):
        for setup in ("network=false", "configured=false; marker=false"):
            with self.subTest(setup=setup):
                lua = self.runtime(setup)
                self.load(lua, "Scripts/LOTM_MP241_PreMainBootstrap.lua")
                lua.execute("assert(#GameEvents.LOTM_MP241_Command_LoadMain.listeners==0 and #writes==0)")
        for config in ("true", "1", "'1'", "false; marker=true"):
            with self.subTest(config=config):
                lua = self.runtime("configured=" + config)
                self.load(lua, "Scripts/LOTM_MP241_PreMainBootstrap.lua")
                lua.execute(r'''
                    local e=GameEvents.LOTM_MP241_Command_LoadMain;
                    assert(#e.listeners==1 and includes==0 and #writes==0);
                    e.Fire(1); assert(includes==0);
                    Ready(); props.LOTM_RESCUE_PHASE2A_VERSION=10;
                    e.Fire(1); assert(includes==0);
                    Ready(); e.Fire(nil); e.Fire(-1); e.Fire(0); e.Fire(3); e.Fire(4);
                    assert(includes==0);
                    GameEvents.LOTM_RESCUE_Command_BootstrapCity.Fire(1); assert(includes==0);
                    e.Fire(1); assert(includes==1 and props.LOTM_MP241_MAIN_LOAD_STATE=='LOADED');
                ''')

    def test_bridge_loaded_save_reentry_and_duplicate_include(self):
        lua = self.runtime("Ready(); props.LOTM_MP241_MAIN_LOAD_STATE='LOADED'")
        self.load(lua, "Scripts/LOTM_MP241_PreMainBootstrap.lua")
        self.load(lua, "Scripts/LOTM_MP241_PreMainBootstrap.lua")
        lua.execute(r'''
            local e=GameEvents.LOTM_MP241_Command_LoadMain;
            assert(#e.listeners==1);
            onInclude=function() e.Fire(1); end;
            e.Fire(1); e.Fire(2); assert(includes==1);
            assert(props.LOTM_MP241_MAIN_LOAD_SERIAL==2);
        ''')

    def test_bridge_failed_partial_include_is_not_retried(self):
        lua = self.runtime("Ready(); failInclude=true")
        self.load(lua, "Scripts/LOTM_MP241_PreMainBootstrap.lua")
        lua.execute(r'''
            local e=GameEvents.LOTM_MP241_Command_LoadMain;
            e.Fire(1); e.Fire(2);
            assert(includes==1 and props.LOTM_MP241_MAIN_LOAD_STATE=='FAILED');
            assert(props.LOTM_MP241_MAIN_LOAD_FAILURE=='INCLUDE_OR_STARTUP_FAILED');
        ''')

    def test_bridge_silent_include_failure_requires_bundle_ready_sentinel(self):
        lua = self.runtime("Ready(); silentInclude=true")
        self.load(lua, "Scripts/LOTM_MP241_PreMainBootstrap.lua")
        lua.execute(r'''
            local e=GameEvents.LOTM_MP241_Command_LoadMain;
            e.Fire(1); e.Fire(2);
            assert(includes==1 and props.LOTM_MP241_MAIN_LOAD_STATE=='FAILED');
            assert(props.LOTM_MP241_MAIN_LOAD_FAILURE=='INCLUDE_OR_STARTUP_FAILED');
        ''')

    def test_bridge_catches_up_only_synchronized_started_players_once(self):
        lua = self.runtime("Ready()")
        self.load(lua, "Scripts/LOTM_MP241_Compat.lua")
        self.load(lua, "Scripts/LOTM_MP241_PreMainBootstrap.lua")
        lua.execute(r'''
            calls={};
            onInclude=function()
                LOTM_MP_TurnSync.Add(function(id) calls[#calls+1]='turn:'..id; end,'CatchUp');
                LOTM_MP_TurnSync.RunStartup(function() calls[#calls+1]='startup'; end,'Setup');
            end;
            GameEvents.PlayerTurnStarted.Fire(2); GameEvents.PlayerTurnStarted.Fire(1);
            assert(props.LOTM_MP241_STARTED_PLAYERS=='1,2' and #calls==0);
            GameEvents.LOTM_MP241_Command_LoadMain.Fire(1);
            assert(calls[1]=='startup' and calls[2]=='turn:1' and calls[3]=='turn:2');
            GameEvents.LOTM_MP241_Command_LoadMain.Fire(2);
            GameEvents.PlayerTurnStarted.Fire(1); assert(#calls==3);
            turn=turn+1; GameEvents.PlayerTurnStarted.Fire(2);
            assert(#calls==4 and props.LOTM_MP241_STARTED_PLAYERS=='2');
        ''')

    def test_bridge_save_restore_catchup_preserves_completed_turn_dedup(self):
        lua = self.runtime(r'''
            Ready(); props.LOTM_MP241_STARTED_TURN=turn; props.LOTM_MP241_STARTED_PLAYERS='2,1';
            props.LOTM_MP241_TURN_CatchUp_1=turn;
        ''')
        self.load(lua, "Scripts/LOTM_MP241_Compat.lua")
        self.load(lua, "Scripts/LOTM_MP241_PreMainBootstrap.lua")
        lua.execute(r'''
            calls={};
            onInclude=function() LOTM_MP_TurnSync.Add(function(id) calls[#calls+1]=id; end,'CatchUp'); end;
            GameEvents.LOTM_MP241_Command_LoadMain.Fire(2);
            assert(#calls==1 and calls[1]==2);
        ''')

    def test_bridge_old_save_without_started_snapshot_does_not_guess_from_ui(self):
        lua = self.runtime("Ready(); localID=1; props.LOTM_MP241_STARTED_TURN=turn-1; props.LOTM_MP241_STARTED_PLAYERS='1,2'")
        self.load(lua, "Scripts/LOTM_MP241_Compat.lua")
        self.load(lua, "Scripts/LOTM_MP241_PreMainBootstrap.lua")
        lua.execute(r'''
            count=0;
            onInclude=function() LOTM_MP_TurnSync.Add(function() count=count+1; end,'CatchUp'); end;
            GameEvents.LOTM_MP241_Command_LoadMain.Fire(1); assert(count==0);
            GameEvents.PlayerTurnStarted.Fire(2); assert(count==1);
        ''')

    def test_ui_new_game_separate_commands_once_and_no_authoritative_writes(self):
        lua = self.runtime()
        self.load(lua, "UI/LOTM_RESCUE_CityBootstrap.lua")
        lua.execute(r'''
            Events.GameCoreEventPublishComplete.Fire(); Events.LocalPlayerTurnBegin.Fire();
            assert(#requests==0);
            onRequest=function() Events.GameCoreEventPublishComplete.Fire(); end;
            Events.LoadScreenClose.Fire(); Events.LoadScreenClose.Fire();
            assert(#requests==1 and requests[1].command=='LOTM_RESCUE_Command_BootstrapCity');
            Ready(); Events.GameCoreEventPublishComplete.Fire();
            assert(#requests==2 and requests[2].command=='LOTM_MP241_Command_LoadMain');
            props.LOTM_MP241_MAIN_LOAD_STATE='LOADED';
            Events.GameCoreEventPublishComplete.Fire(); Events.LocalPlayerTurnBegin.Fire();
            assert(#requests==2 and #writes==0);
        ''')

    def test_ui_ready_save_and_turn_fallback_request_main_without_city_bootstrap(self):
        for previous in ("LOADED", "FAILED", "WAITING"):
            with self.subTest(previous=previous):
                lua = self.runtime("Ready(); props.LOTM_MP241_MAIN_LOAD_STATE='" + previous + "'")
                self.load(lua, "UI/LOTM_RESCUE_CityBootstrap.lua")
                lua.execute(r'''
                    Events.LoadScreenClose.Fire(); Events.GameCoreEventPublishComplete.Fire();
                    assert(#requests==1 and requests[1].command=='LOTM_MP241_Command_LoadMain');
                    for _,line in ipairs(logs) do assert(not line:find('post%-241 main acknowledged')); end;
                    props.LOTM_MP241_MAIN_LOAD_SERIAL=1; props.LOTM_MP241_MAIN_LOAD_STATE='LOADED';
                    Events.GameCoreEventPublishComplete.Fire();
                    local acknowledgements=0;
                    for _,line in ipairs(logs) do
                        if line:find('post%-241 main acknowledged state=LOADED') then acknowledgements=acknowledgements+1; end;
                    end;
                    assert(acknowledgements==1);
                ''')

    def test_ui_only_stable_alive_active_human_submits(self):
        for player in (-1, 0, 2, 3, 4):
            with self.subTest(player=player):
                lua = self.runtime("localID=" + str(player))
                self.load(lua, "UI/LOTM_RESCUE_CityBootstrap.lua")
                lua.execute("Events.LoadScreenClose.Fire(); assert(#requests==0)")
        lua = self.runtime("Players[1].active=false")
        self.load(lua, "UI/LOTM_RESCUE_CityBootstrap.lua")
        lua.execute(r'''
            Events.LoadScreenClose.Fire(); assert(#requests==0);
            Players[1].active=true; Events.PlayerTurnActivated.Fire(1); assert(#requests==1);
        ''')

    def test_ui_nonanchor_can_restore_main_context_and_loaded_peer_ack_is_consistent(self):
        lua = self.runtime("Ready(); localID=2; props.LOTM_MP241_MAIN_LOAD_SERIAL=7; props.LOTM_MP241_MAIN_LOAD_STATE='LOADED'")
        self.load(lua, "UI/LOTM_RESCUE_CityBootstrap.lua")
        lua.execute(r'''
            Events.LoadScreenClose.Fire(); assert(#requests==1);
            assert(requests[1].id==2 and requests[1].command=='LOTM_MP241_Command_LoadMain');
            props.LOTM_MP241_MAIN_LOAD_SERIAL=9; Events.GameCoreEventPublishComplete.Fire();
            local acknowledgements=0;
            for _,line in ipairs(logs) do
                if line:find('post%-241 main acknowledged state=LOADED') then acknowledgements=acknowledgements+1; end;
            end;
            assert(acknowledgements==1);
        ''')
        loaded = self.runtime("Ready(); props.LOTM_MP241_MAIN_LOAD_SERIAL=6")
        fresh = self.runtime("Ready(); props.LOTM_MP241_MAIN_LOAD_SERIAL=7; props.LOTM_MP241_MAIN_LOAD_STATE='LOADED'")
        self.load(loaded, "Scripts/LOTM_MP241_PreMainBootstrap.lua")
        self.load(fresh, "Scripts/LOTM_MP241_PreMainBootstrap.lua")
        loaded.execute("GameEvents.LOTM_MP241_Command_LoadMain.Fire(1)")
        for peer in (loaded, fresh):
            peer.execute("GameEvents.LOTM_MP241_Command_LoadMain.Fire(2)")
            peer.execute("assert(includes==1 and props.LOTM_MP241_MAIN_LOAD_SERIAL==8 and props.LOTM_MP241_MAIN_LOAD_STATE=='LOADED')")

    def test_ui_ordinary_mode_and_single_player_isolation(self):
        lua = self.runtime("configured=false; marker=false")
        self.load(lua, "UI/LOTM_RESCUE_CityBootstrap.lua")
        lua.execute("Events.LoadScreenClose.Fire(); assert(#requests==0)")
        lua = self.runtime("network=false")
        self.load(lua, "UI/LOTM_RESCUE_CityBootstrap.lua")
        lua.execute(r'''
            Events.LoadScreenClose.Fire(); assert(#requests==1);
            Ready(); Events.GameCoreEventPublishComplete.Fire(); assert(#requests==1);
        ''')

    def test_ui_rejected_operation_can_retry(self):
        lua = self.runtime("rejectRequest=true")
        self.load(lua, "UI/LOTM_RESCUE_CityBootstrap.lua")
        lua.execute(r'''
            Events.LoadScreenClose.Fire(); assert(#requests==0);
            rejectRequest=false; Events.GameCoreEventPublishComplete.Fire(); assert(#requests==1);
        ''')


if __name__ == "__main__":
    unittest.main(verbosity=2)
