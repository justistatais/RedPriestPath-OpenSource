#!/usr/bin/env python3
"""Exercise the real Justice UI load request when the first submit is lost."""

from pathlib import Path
import unittest

from test_rc346_thief_rule_guards import LuaRuntime
from generate_startup_trace import strip_trace


ROOT = Path(__file__).resolve().parents[1]
SOURCE = strip_trace((ROOT / "UI/LOTM_JUSTICE_Story.lua").read_text(encoding="utf-8"))

HARNESS = r'''
contextHidden=true
ContextPtr={SetHide=function(_,v) contextHidden=v end,IsHidden=function() return contextHidden end}
requests=0; auditRequests=0; active=false; props={}; now=49; deny=false
tip='+20% (+2.5) from Amenities'; currentYield=15.5; fullScans=0
YieldTypes={PRODUCTION=1}
local function Event()
 local handlers={}
 return {Add=function(fn) handlers[#handlers+1]=fn end,
  Fire=function() for _,fn in ipairs(handlers) do fn() end end}
end
Events={PlayerTurnActivated=Event(),CityProductionQueueChanged=Event(),
 GovernorChanged=Event(),GovernorAssigned=Event(),GovernorPromoted=Event(),
 GovernorEstablished=Event(),GameCoreEventPublishComplete=Event(),
 LoadGameViewStateDone=Event(),LoadScreenClose=Event()}
Controls={StoryPanel={SetHide=function() end},
 CompleteButton={RegisterCallback=function() end,SetDisabled=function() end},
 CityLabel={SetText=function() end}}
Mouse={eLClick=1}; PlayerOperations={EXECUTE_SCRIPT=99}
Game={GetLocalPlayer=function() return 0 end,GetCurrentGameTurn=function() return now end}
local names={'SPONSOR','COUNSEL','SALON','SUGGESTION','TAROT','STORY'}
GameInfo={Governors={GOVERNOR_LOTM_JUSTICE={Index=7}},GovernorPromotions={}}
for i,name in ipairs(names) do
 GameInfo.GovernorPromotions['GOVERNOR_PROMOTION_LOTM_JUSTICE_'..name]={Hash=i}
end
local city={GetID=function() return 10 end,GetOwner=function() return 0 end,
 GetYieldToolTip=function() return tip end,GetYield=function() return currentYield end}
local governor={GetType=function() return 7 end,GetAssignedCity=function() return city end,
 IsEstablished=function() return true end,GetNeutralizedTurns=function() return 0 end,
 HasPromotion=function() return true end}
local p={GetProperty=function(_,k) if props[k]==nil then return end; return props[k] end,
 IsTurnActive=function() return active end,
 GetCities=function() return {FindID=function(_,id) if id==10 then return city end end,
 Members=function() fullScans=fullScans+1; local done=false; return function()
  if not done then done=true;return 10,city end end end} end,
 GetGovernors=function() return {GetGovernorList=function() return 1,{governor} end} end}
Players={[0]=p}
UI={RequestPlayerOperation=function(id,op,state)
 assert(id==0 and op==99)
 if state.OnStart=='LOTM_JUSTICE_UpdateGovernor' then
  requests=requests+1
  assert(state.ProductionAuditData==nil and state.LoadAuditSerial==nil)
  if requests==1 or deny then return false end
  props.JUSTICE_GOVERNOR_SNAPSHOT_SERIAL=state.SnapshotSerial
  props.JUSTICE_GOVERNOR_SNAPSHOT_DIGEST='10:1:0:1:1:1:1:1:1'
 else
  assert(state.OnStart=='LOTM_JUSTICE_AuditProduction')
  assert(state.GovernorSnapshotSerial==props.JUSTICE_GOVERNOR_SNAPSHOT_SERIAL)
  auditRequests=auditRequests+1
  lastAuditData=state.ProductionAuditData
  props.JUSTICE_PRODUCTION_AUDIT_VERSION=1
  if onAudit then onAudit(state) end
  props.JUSTICE_STORY_LOAD_AUDIT_SERIAL=state.LoadAuditSerial
 end
 return true
end}
'''


class JusticeUIRetryTests(unittest.TestCase):
    def test_actual_percentage_is_submitted_and_rechecked_without_repeating_full_scan(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(HARNESS)
        lua.execute('''
        props.JUSTICE_STORY_PAUSE_SOURCE_VERSION=5
        tip='+20% (+2.5) from Amenities[NEWLINE]+10000% (+1300) from Modifiers'
        currentYield=1315.5
        function onAudit(state)
         if state.LoadAuditSerial==1 then
          assert(state.ProductionAuditData=='10,10000,1315.5')
          props.JUSTICE_PRODUCTION_VERIFY_NEEDED=1
          props.JUSTICE_PRODUCTION_AUDIT_CITIES='10'
          tip='+20% (+2.5) from Amenities';currentYield=15.5
         else
          assert(state.LoadAuditSerial==2 and state.ProductionAuditData=='10,0,15.5')
          props.JUSTICE_PRODUCTION_VERIFY_NEEDED=0
         end
        end
        ''')
        lua.execute(SOURCE)
        lua.execute('''
        active=true; Events.LoadGameViewStateDone.Fire()
        for i=1,100 do Events.GameCoreEventPublishComplete.Fire() end
        assert(requests==2 and auditRequests==2 and props.JUSTICE_STORY_LOAD_AUDIT_SERIAL==2)
        assert(fullScans==1 and lastAuditData=='10,0,15.5')
        ''')

    def test_missing_production_tooltip_does_not_block_fresh_ownership_receipt(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(HARNESS)
        lua.execute("tip=nil; props.JUSTICE_GOVERNOR_SNAPSHOT_SERIAL=5; props.JUSTICE_GOVERNOR_SNAPSHOT_DIGEST='10:1:0:1:1:1:1:1:1'")
        lua.execute(SOURCE)
        lua.execute('''
        active=true; Events.LoadGameViewStateDone.Fire()
        for i=1,100 do Events.GameCoreEventPublishComplete.Fire() end
        assert(requests==2 and props.JUSTICE_GOVERNOR_SNAPSHOT_SERIAL==6)
        assert(auditRequests==0 and props.JUSTICE_STORY_LOAD_AUDIT_SERIAL==nil)
        tip='+20% (+2.5) from Amenities'
        for i=1,100 do Events.GameCoreEventPublishComplete.Fire() end
        assert(requests==2 and auditRequests==1 and props.JUSTICE_STORY_LOAD_AUDIT_SERIAL==1)
        ''')

    def test_exhausted_requests_rearm_next_turn_and_ambiguous_audit_is_independent(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(HARNESS)
        lua.execute("deny=true; tip='+10000% A[NEWLINE]-10000% B'")
        lua.execute(SOURCE)
        lua.execute('''
        active=true; Events.LoadGameViewStateDone.Fire()
        for i=1,300 do Events.GameCoreEventPublishComplete.Fire() end
        assert(requests==12 and auditRequests==0)
        now=50; deny=false; Events.PlayerTurnActivated.Fire()
        for i=1,60 do Events.GameCoreEventPublishComplete.Fire() end
        assert(requests==13 and props.JUSTICE_GOVERNOR_SNAPSHOT_SERIAL==1)
        assert(auditRequests==0)
        ''')

    def test_load_waits_for_active_turn_retries_lost_request_and_stops_on_ack(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(HARNESS)
        lua.execute(SOURCE)
        lua.execute('''
        assert(requests==0)
        active=true
        Events.LoadGameViewStateDone.Fire()
        assert(requests==1)
        for i=1,21 do Events.GameCoreEventPublishComplete.Fire() end
        assert(requests==2 and props.JUSTICE_STORY_LOAD_AUDIT_SERIAL==1)
        for i=1,100 do Events.GameCoreEventPublishComplete.Fire() end
        Events.PlayerTurnActivated.Fire()
        assert(requests==2)
        ''')


if __name__ == "__main__":
    unittest.main(verbosity=2)
