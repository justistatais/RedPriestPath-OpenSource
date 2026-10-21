#!/usr/bin/env python3
"""Execute real rescue cleanup and camp creation Lua 5.1, including rc347 controls."""
from __future__ import annotations

import hashlib
from pathlib import Path
import sys
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
try:
    from lupa.lua51 import LuaRuntime
except ImportError:
    sys.path.insert(0, str(ROOT.parent / ".tmp" / "refactor-rc340-python"))
    from lupa.lua51 import LuaRuntime

BASELINE_HASHES = {
    "LOTM_WORLD_Barbarians": "eca8114e5206d7ee78a1bb45aaa2df8a78b9e564571898cbe1997141fcb2908f",
    "LOTM_RESCUE_Phase5": "cb84b5f64d995ea20cf287f19b614704f485d87d5beee4c9548291cc7e85f954",
}


def source(module: str, old=False):
    if not old:
        return (ROOT / "Scripts" / (module + ".lua")).read_text(encoding="utf-8-sig")
    with zipfile.ZipFile(ROOT.parent / "dist/RedPriestPath-0.1.0-rc.347.zip") as archive:
        data = archive.read("RedPriestPath/Scripts/" + module + ".lua")
    assert hashlib.sha256(data).hexdigest() == BASELINE_HASHES[module]
    return data.decode("utf-8-sig")


FIXTURE = r'''
rescue=true; network=false; creating=false; phaseCreating=false; turn=5
props={}; live={}; scanCount=0; killed={}; lookupCount=0; nativeCalls={}; turnCalls={}
function print(...) end
Game={GetProperty=function(k) return props[k] end, SetProperty=function(k,v) props[k]=v end,
 GetCurrentGameTurn=function() return turn end}
LOTM_MP_TurnSync={IsRescueModeConfigured=function() return rescue end,
 IsNetworkGame=function() return network end,
 AddSynchronized=function(fn) turnHandler=fn end,RunStartup=function(fn) startup=fn end}
LOTM_WORLD_Monsters={IsCreating=function() return creating end}
LOTM_RESCUE_Phase10={IsCreating=function() return phaseCreating end}
GameInfo={Units={},Resources={},Features={},Improvements={IMPROVEMENT_BARBARIAN_CAMP={Index=5}},
 BarbarianTribes={TRIBE_MELEE={Index=10,DefenderTag='CLASS_RANGED'}}}
for index,name in ipairs({'UNIT_WARRIOR','UNIT_LOTM_RESCUE_LOST_CONTROL_LOW',
 'UNIT_LOTM_RESCUE_LOST_CONTROL_MID','UNIT_LOTM_RESCUE_LOST_CONTROL_HIGH',
 'UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR','UNIT_LOTM_RESCUE_OUTER_GOD_MINION'}) do
 local row={Index=index,UnitType=name,Combat=20,BaseMoves=2}
 GameInfo.Units[index]=row; GameInfo.Units[name]=row
end
GameInfo.Technologies={}
function Player(id)
 local player={id=id}
 function player:GetID() return self.id end
 function player:GetUnits()
  if noCollection then return nil end
  scanCount=scanCount+1
  return {Members=function()
   local ids={}; for id,u in pairs(live) do if u.owner==self.id then ids[#ids+1]=id end end
   table.sort(ids,function(a,b) return a>b end)
   local i=0; return function() i=i+1; if ids[i]~=nil then return ids[i],live[ids[i]] end end
  end}
 end
 return player
end
Players={[63]=Player(63),[62]=Player(62),[0]=Player(0)}
PlayerManager={GetAliveBarbarians=function() if noRoster then return nil end return {Players[63],Players[62]} end}
function Unit(id,kind,p,owner)
 local unit={id=id,kind=kind or 1,props=p or {},owner=owner or 63,plot=0}
 function unit:GetID() return self.id end
 function unit:GetOwner() return self.owner end
 function unit:GetType() return self.kind end
 function unit:GetProperty(k) return self.props[k] end
 live[id]=unit; return unit
end
UnitManager={Kill=function(u)
 if killError then error('native kill unavailable') end
 if killFalse then return false end
 killed[#killed+1]=u.owner..':'..u.id; live[u.id]=nil
end,GetUnit=function(owner,id) local u=live[id]; return u~=nil and u.owner==owner and u or nil end}
plots={}
for index=0,7 do
 local plot={index=index,improvement=-1}
 function plot:GetIndex() return self.index end
 function plot:GetX() return self.index end
 function plot:GetY() return 0 end
 function plot:IsWater() return false end
 function plot:IsHills() return false end
 function plot:GetFeatureType() return -1 end
 function plot:GetImprovementType() return self.improvement end
 plots[index]=plot
end
Map={GetAdjacentPlot=function(x,y,d) return plots[d+1] end}
Units={GetUnitsInPlot=function(plot)
 lookupCount=lookupCount+1; local result={}
 for _,u in pairs(live) do if u.plot==plot.index then result[#result+1]=u end end
 return result
end}
manager={CreateTribeOfType=function(_,kind,index)
 nativeCalls[#nativeCalls+1]='camp'; plots[index].improvement=5; return 11
end,CreateTribeUnits=function(_,tribe,tag,count,index,range)
 nativeCalls[#nativeCalls+1]='defender'; assert(tribe==11 and tag=='CLASS_RANGED' and count==1 and range==1)
 Unit(100,1).plot=index; return true
end}
'''


def runtime(old=False, phase=False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(FIXTURE)
    lua.execute(source("LOTM_WORLD_Barbarians", old))
    if phase:
        lua.execute(source("LOTM_RESCUE_Phase5", old) + "\nAPI={CreateCamp=CreateCamp};")
    return lua


def workshop_runtime(old=False):
    from test_rc348_camp_artifacts import HARNESS, source as workshop_source
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(HARNESS + r'''
    kills=0; killFails=false; sections={}
    local makeUnit=Unit
    function Unit(owner,id)
     local u=makeUnit(owner,id); u.props={}; u.kind=1
     function u:GetProperty(k) return self.props[k] end
     function u:SetProperty(k,v) self.props[k]=v; propertyWrites=propertyWrites+1 end
     function u:GetType() return self.kind end
     return u
    end
    UnitManager.Kill=function(u)
     if killFails then return false end
     kills=kills+1; units[u.owner..":"..u.id]=nil
    end
    GameInfo.Units.UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR={Index=5}
    GameInfo.Units.UNIT_LOTM_RESCUE_OUTER_GOD_MINION={Index=6}
    LOTM_WORLD_Monsters={IsCreating=function() return false end,
     IsMonster=function(u) return (u.props.LOTM_WORLD_MONSTER_SERIAL or 0)>0 end}
    LOTM_UnitAddedPerf={MarkSection=function(k) sections[k]=(sections[k] or 0)+1 end}
    ''')
    lua.execute(source("LOTM_WORLD_Barbarians", old))
    lua.execute(workshop_source(old) + r'''
    SpawnAPI={add=OnUnitAdded,removed=OnUnitRemoved,boundary=ProcessNetworkLocalUnitAdditions,
      queue=QueueLocalNetworkUnitAdded,localQueue=function() return m_networkUnitAdditionsLocal end};
    ''')
    return lua


class IncrementalNativeSuppressionTests(unittest.TestCase):
    def test_removed_then_reused_id_is_checked_at_next_boundary(self):
        for old, expected in ((True, 0), (False, 1)):
            lua = workshop_runtime(old)
            lua.execute("SpawnAPI.removed(63,8); Unit(63,8); SpawnAPI.add(63,8,21,46); turn=7; SpawnAPI.boundary(0)")
            self.assertEqual(lua.eval("kills"), expected)

    def test_add_then_remove_then_reused_id_is_not_lost_as_cancelled(self):
        for old, expected in ((True, 0), (False, 1)):
            lua = workshop_runtime(old)
            lua.execute("Unit(63,8); SpawnAPI.add(63,8,21,46); SpawnAPI.removed(63,8); Unit(63,8); SpawnAPI.add(63,8,22,46); turn=7; SpawnAPI.boundary(0)")
            self.assertEqual(lua.eval("kills"), expected)

    def test_ambiguous_add_observations_do_not_lose_rescue_cleanup(self):
        for old, expected in ((True, 0), (False, 1)):
            lua = workshop_runtime(old)
            lua.execute("Unit(63,8); SpawnAPI.add(63,8,21,46); SpawnAPI.add(63,8,22,46); turn=7; SpawnAPI.boundary(0)")
            self.assertEqual(lua.eval("kills"), expected)

    def test_ordinary_source_or_generation_marker_cannot_exempt_rescue(self):
        for prop in ("LOTM_PP_WORKSHOP_SOURCE", "LOTM_PP_WORKSHOP_MP_UNIT_GENERATION"):
            for old, expected in ((True, 0), (False, 1)):
                lua = workshop_runtime(old)
                lua.execute(f"u=Unit(63,8); u.props.{prop}=12; SpawnAPI.add(63,8,21,46); turn=7; SpawnAPI.boundary(0)")
                self.assertEqual(lua.eval("kills"), expected, prop)

    def test_stale_filtered_observation_cannot_exempt_current_normal_unit(self):
        for old, expected in ((True, 0), (False, 1)):
            lua = workshop_runtime(old)
            lua.execute("u=Unit(63,8); u.props.LOTM_WORLD_MONSTER_SERIAL=1; SpawnAPI.add(63,8,21,46); u.props={}; turn=7; SpawnAPI.boundary(0)")
            self.assertEqual(lua.eval("kills"), expected)

    def test_local_events_write_nothing_and_do_not_remove_until_sync_next_turn(self):
        lua = workshop_runtime()
        lua.execute("""
        Unit(63,8); SpawnAPI.add(63,8,21,46); SpawnAPI.removed(63,8); SpawnAPI.add(63,8,22,46)
        assert(kills==0 and propertyWrites==0)
        SpawnAPI.boundary(0); assert(kills==0 and propertyWrites==0)
        turn=7; SpawnAPI.boundary(1); assert(kills==0 and propertyWrites==0)
        SpawnAPI.boundary(0); assert(kills==1)
        """)

    def test_native_failure_retries_without_new_add_callback_and_survives_reload(self):
        lua = workshop_runtime()
        lua.execute("Unit(63,8); SpawnAPI.add(63,8,21,46); killFails=true; turn=7; SpawnAPI.boundary(0); assert(kills==0)")
        pending = lua.eval("properties.LOTM_RESCUE_NATIVE_PENDING_UNITS")
        self.assertEqual(pending, "63:8")
        reloaded = workshop_runtime()
        reloaded.globals().properties["LOTM_RESCUE_NATIVE_PENDING_UNITS"] = pending
        reloaded.execute("Unit(63,8); turn=8; SpawnAPI.boundary(0); assert(kills==1 and properties.LOTM_RESCUE_NATIVE_PENDING_UNITS==nil)")
        lua.execute("killFails=false; turn=8; SpawnAPI.boundary(0); assert(kills==1)")

    def test_reused_id_now_belongs_to_monster_or_final_unit_is_protected(self):
        for protection in ("u.props.LOTM_WORLD_MONSTER_SERIAL=8", "u.props.LOTM_RESCUE_CENTER_MONSTER=1", "u.kind=5", "u.kind=6"):
            lua = workshop_runtime()
            lua.execute(f"Unit(63,8); SpawnAPI.add(63,8,21,46); u=Unit(63,8); {protection}; turn=7; SpawnAPI.boundary(0); assert(kills==0)")

    def test_durable_only_identity_keeps_candidate_until_properties_or_index_resolve(self):
        for real_monster in (True, False):
            lua = workshop_runtime()
            lua.execute("""
            u=Unit(63,8); SpawnAPI.add(63,8,21,46)
            properties['LOTM_WORLD_MONSTER_ENGINE:63:8']=99
            properties['LOTM_WORLD_MONSTER:99:LIVE']=1
            properties['LOTM_WORLD_MONSTER:99:OWNER']=63
            properties['LOTM_WORLD_MONSTER:99:UNIT_ID']=8
            turn=7; SpawnAPI.boundary(0)
            assert(kills==0 and properties.LOTM_RESCUE_NATIVE_PENDING_UNITS=='63:8')
            """)
            lua.execute("u.props.LOTM_WORLD_MONSTER_SERIAL=99" if real_monster else "properties['LOTM_WORLD_MONSTER:99:LIVE']=0")
            lua.execute("turn=8; SpawnAPI.boundary(0); assert(properties.LOTM_RESCUE_NATIVE_PENDING_UNITS==nil)")
            self.assertEqual(lua.eval("kills"), 0 if real_monster else 1)

    def test_single_player_ordinary_extra_marker_does_not_bypass_rescue(self):
        for old, expected in ((True, 0), (False, 1)):
            lua = workshop_runtime(old)
            lua.execute("network=false; u=Unit(63,8); u.props.LOTM_PP_WORKSHOP_EXTRA=1; SpawnAPI.add(63,8,21,46)")
            self.assertEqual(lua.eval("kills"), expected)

    def test_single_player_failed_remove_retries_at_synchronized_phase5_boundary(self):
        lua = workshop_runtime()
        lua.execute("""
        network=false; killFails=true; Unit(63,8); SpawnAPI.add(63,8,21,46)
        assert(kills==0 and properties.LOTM_RESCUE_NATIVE_PENDING_UNITS=='63:8')
        LOTM_MP_TurnSync.AddSynchronized=function(fn) phaseTurn=fn end
        LOTM_MP_TurnSync.RunStartup=function() end
        properties.LOTM_RESCUE_BARBARIAN_CLEANUP_VERSION=2
        """)
        lua.execute(source("LOTM_RESCUE_Phase5"))
        lua.execute("""
        local phase=LOTM_RESCUE_Phase5
        phase.IsActive=function() return true end; phase.AnchorMajorID=function() return 0 end
        phase.RefreshState=function() end; phase.TrySupplementCamps=function() end
        phase.WorldTurn=function() return 7 end; phase.MonsterTurnAttempts=function() return 6 end
        phase.DirectSpawnCount=function() return 6 end; phase.ScaleMonsterSpawnCount=function() return 3 end
        phase.MonsterSpawnPercent=function() return 50 end
        killFails=false; turn=7; phaseTurn(1); assert(kills==0)
        phaseTurn(0); assert(kills==1 and properties.LOTM_RESCUE_NATIVE_PENDING_UNITS==nil)
        """)

    def test_normal_mode_keeps_ordinary_ambiguous_generation_cancellation(self):
        lua = workshop_runtime()
        lua.execute("rescue=false; Unit(63,8); SpawnAPI.add(63,8,21,46); SpawnAPI.add(63,8,22,46); turn=7; SpawnAPI.boundary(0); assert(kills==0 and propertyWrites==0)")


class BarbarianSpawnTests(unittest.TestCase):
    def test_old_save_version_one_is_repaired_and_baseline_retains_it(self):
        for old, expected in ((True, 0), (False, 1)):
            lua = runtime(old)
            lua.execute("props.LOTM_RESCUE_BARBARIAN_CLEANUP_VERSION=1; Unit(4,1,{LOTM_PP_WORKSHOP_SOURCE=44}); n=LOTM_WORLD_Barbarians.CleanupRescueUnits()")
            self.assertEqual(lua.globals().n, expected)

    def test_normal_mode_cannot_be_mutated_even_by_direct_call(self):
        lua = runtime()
        lua.execute("rescue=false; Unit(1); assert(LOTM_WORLD_Barbarians.CleanupRescueUnits()==0); assert(live[1] and scanCount==0)")

    def test_all_committed_rescue_roles_survive(self):
        lua = runtime()
        lua.execute("""
        Unit(1,1,{LOTM_WORLD_MONSTER_SERIAL=2})
        Unit(2,1,{LOTM_RESCUE_CENTER_MONSTER=1})
        Unit(3,1,{LOTM_PP_WORKSHOP_SEQUENCE=1})
        Unit(4,1,{LOTM_RESCUE_PHASE10_ROLE='BOSS'})
        for kind=2,6 do Unit(10+kind,kind) end
        assert(LOTM_WORLD_Barbarians.CleanupRescueUnits()==0)
        for _,id in ipairs({1,2,3,4,12,13,14,15,16}) do assert(live[id]) end
        """)

    def test_durable_identity_survives_property_publication_delay(self):
        for old, expected in ((True, 1), (False, 0)):
            lua = runtime(old)
            lua.execute("""
            Unit(1); props['LOTM_WORLD_MONSTER_ENGINE:63:1']=7
            props['LOTM_WORLD_MONSTER:7:LIVE']=1; props['LOTM_WORLD_MONSTER:7:OWNER']=63
            props['LOTM_WORLD_MONSTER:7:UNIT_ID']=1
            n=LOTM_WORLD_Barbarians.CleanupRescueUnits()
            """)
            self.assertEqual(lua.globals().n, expected)

    def test_stale_reused_engine_identity_does_not_protect_native_unit(self):
        lua = runtime()
        lua.execute("""
        Unit(1); props['LOTM_WORLD_MONSTER_ENGINE:63:1']=7
        props['LOTM_WORLD_MONSTER:7:LIVE']=1; props['LOTM_WORLD_MONSTER:7:OWNER']=63
        props['LOTM_WORLD_MONSTER:7:UNIT_ID']=9
        assert(LOTM_WORLD_Barbarians.CleanupRescueUnits()==1)
        """)

    def test_successful_migration_never_enumerates_again(self):
        lua = runtime()
        lua.execute("""
        Unit(1); assert(LOTM_WORLD_Barbarians.CleanupRescueUnits()==1)
        local scans=scanCount
        for i=1,1000 do assert(LOTM_WORLD_Barbarians.CleanupRescueUnits()==0) end
        assert(scanCount==scans and props.LOTM_RESCUE_BARBARIAN_CLEANUP_VERSION==2)
        """)

    def test_unavailable_roster_collection_and_birth_windows_defer(self):
        for gate in ("noRoster", "noCollection", "creating", "phaseCreating"):
            lua = runtime()
            lua.execute(f"Unit(1); {gate}=true; assert(LOTM_WORLD_Barbarians.CleanupRescueUnits()==0); assert(live[1] and props.LOTM_RESCUE_BARBARIAN_CLEANUP_VERSION==nil); {gate}=false; assert(LOTM_WORLD_Barbarians.CleanupRescueUnits()==1)")

    def test_native_kill_error_or_false_does_not_acknowledge_migration(self):
        for gate in ("killError", "killFalse"):
            lua = runtime()
            lua.execute(f"Unit(1); {gate}=true; assert(LOTM_WORLD_Barbarians.CleanupRescueUnits()==0); assert(props.LOTM_RESCUE_BARBARIAN_CLEANUP_VERSION==nil); {gate}=false; assert(LOTM_WORLD_Barbarians.CleanupRescueUnits()==1)")

    def test_missing_unit_property_view_defers_without_aborting_turn(self):
        lua = runtime()
        lua.execute("""
        local unit=Unit(1); local get=unit.GetProperty
        unit.GetProperty=function() error('unit property view not ready') end
        assert(LOTM_WORLD_Barbarians.CleanupRescueUnits()==0)
        assert(live[1] and props.LOTM_RESCUE_BARBARIAN_CLEANUP_VERSION==nil)
        unit.GetProperty=get; assert(LOTM_WORLD_Barbarians.CleanupRescueUnits()==1)
        """)

    def test_network_uses_identical_repair_and_melee_baseline_is_unchanged(self):
        from generate_gameplay_bundle import read_network_source
        current = source("LOTM_WORLD_Barbarians")
        self.assertEqual(read_network_source("LOTM_WORLD_Barbarians"), current)
        begin = "local MELEE_CHAIN="
        end = "function LOTM_WORLD_Barbarians.CleanupRescueUnits()"
        old = source("LOTM_WORLD_Barbarians", True)
        unchanged = old[old.index(begin):old.index(end)].rstrip()
        self.assertIn(unchanged, current)

    def test_deterministic_player_and_unit_order(self):
        lua = runtime()
        lua.execute("""
        Unit(7,1,nil,63); Unit(2,1,nil,63); Unit(8,1,nil,62)
        assert(LOTM_WORLD_Barbarians.CleanupRescueUnits()==3)
        assert(table.concat(killed,',')=='62:8,63:2,63:7')
        """)

    def test_phase5_native_defender_removed_same_synchronized_creation(self):
        for old in (True, False):
            for network in (True, False):
                lua = runtime(old, phase=True)
                lua.globals().network = network
                lua.execute("ok,reason=API.CreateCamp(manager,plots[0]); assert(ok and reason=='NONE' and plots[0].improvement==5); assert(table.concat(nativeCalls,',')=='camp,defender')")
                self.assertEqual(lua.eval("live[100]~=nil"), old)

    def test_local_cleanup_is_fixed_seven_hexes_and_preserves_specials_and_humans(self):
        lua = runtime(phase=True)
        lua.execute("""
        Unit(1).plot=1; Unit(2).plot=7
        Unit(3,1,{LOTM_WORLD_MONSTER_SERIAL=1}).plot=0
        Unit(4,1,{LOTM_RESCUE_CENTER_MONSTER=1}).plot=2
        Unit(5,5).plot=3; Unit(6,6).plot=4; Unit(7,1,nil,0).plot=5
        local ok=API.CreateCamp(manager,plots[0]); assert(ok)
        assert(not live[1] and not live[100] and live[2])
        for id=3,7 do assert(live[id]) end
        assert(lookupCount==7 and scanCount==0)
        """)

    def test_camp_cleanup_native_failure_persists_single_id_for_retry(self):
        lua = runtime(phase=True)
        lua.execute("""
        killFalse=true; assert(API.CreateCamp(manager,plots[0]))
        assert(live[100] and props.LOTM_RESCUE_NATIVE_PENDING_UNITS=='63:100')
        killFalse=false; local handled,removed=LOTM_WORLD_Barbarians.ProcessRescueUnitCandidates({})
        assert(handled and removed==1 and not live[100])
        assert(lookupCount==7 and scanCount==0 and props.LOTM_RESCUE_NATIVE_PENDING_UNITS==nil)
        """)

    def test_phase5_periodic_and_direct_spawn_calls_unchanged_after_repair(self):
        for old in (True, False):
            lua = runtime(old, phase=True)
            lua.execute("""
            local phase=LOTM_RESCUE_Phase5
            phase.IsActive=function() return true end; phase.AnchorMajorID=function() return 0 end
            phase.RefreshState=function() turnCalls[#turnCalls+1]='refresh' end
            phase.TrySupplementCamps=function(id) assert(id==0); turnCalls[#turnCalls+1]='camps' end
            phase.WorldTurn=function() return 6 end
            phase.MonsterTurnAttempts=function() return 6 end; phase.DirectSpawnCount=function() return 6 end
            phase.ScaleMonsterSpawnCount=function(raw,kind,worldTurn) assert(raw==6 and worldTurn==6); return 3 end
            phase.MonsterSpawnPercent=function() return 50 end
            LOTM_WORLD_Monsters.RescueTurnSpawn=function(t,n) assert(t==6 and n==3); turnCalls[#turnCalls+1]='periodic'; return 3 end
            LOTM_RESCUE_DirectMonsters={Spawn=function(t,n) assert(t==6 and n==3); turnCalls[#turnCalls+1]='direct'; return 3 end}
            turnHandler(0)
            assert(table.concat(turnCalls,',')=='refresh,camps,periodic,direct')
            """)


if __name__ == "__main__":
    unittest.main(verbosity=2)
