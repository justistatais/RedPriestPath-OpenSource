"""Exercise the synchronized Justice story state machine with Civ-style Lua objects."""

from pathlib import Path
import unittest

from test_rc346_thief_rule_guards import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = r'''
function print() end
now=0; finishes=0; envoys=0; nativeIncome=0; nativeAttachments={}
Game={GetCurrentGameTurn=function() return now end}
YieldTypes={PRODUCTION=1}
GameInfo={
 Governors={GOVERNOR_LOTM_JUSTICE={Index=1}},
 Buildings={BUILDING_LOTM_JUSTICE_STORY_PAUSE={Index=9},
  [100]={Index=100,Hash=1000},[101]={Index=101,Hash=1001}},
 Projects={}, GreatPersonClasses={}
}
GameInfo.District_GreatPersonPoints=function() return function() return nil end end
GameInfo.Building_GreatPersonPoints=function() return function() return nil end end
LOTM_MP_TurnSync={IsRescueModeConfigured=function() return false end,
 Add=function(fn,key) if key=='JusticeGovernor' then onTurn=fn end end}
GameEvents=setmetatable({},{__index=function(t,k)
 local handlers={}; local event={Add=function(fn) handlers[#handlers+1]=fn end}
 setmetatable(event,{__call=function(_,...) for _,fn in ipairs(handlers) do fn(...) end end})
 rawset(t,k,event); return event
end})
LOTM_RP_State={FindHero=function() return nil end}
LOTM_WORLD_Churches={ChangeEnvoys=function() envoys=envoys+1; return true end}
local queue={}
function queue:CreateBuilding(index) assert(index==9); cities[activeCity].owned[9]=true end
function queue:CanProduce(hash) error('UI-only CanProduce unavailable in Gameplay') end
function queue:CurrentlyBuilding() return currentProduction or 101 end
function queue:FinishProgress() finishes=finishes+1 end
local function makeCity(id)
 local c={id=id,owned={},props={},repairYield=0}
 function c:GetID() return self.id end
 function c:GetOwner() return 0 end
 function c:GetX() return self.id end
 function c:GetY() return 2 end
 function c:GetProperty(k) return self.props[k] end
 function c:SetProperty(k,v) self.props[k]=v end
 function c:AttachModifierByID(id)
  if id=='LOTM_JUSTICE_CACHE_MINUS_1000' then self.repairYield=self.repairYield-1000
  elseif id=='LOTM_JUSTICE_CACHE_PLUS_1000' then self.repairYield=self.repairYield+1000
  elseif id=='LOTM_JUSTICE_CACHE_MINUS_10000' then self.repairYield=self.repairYield-10000
  elseif id=='LOTM_JUSTICE_CACHE_PLUS_10000' then self.repairYield=self.repairYield+10000
  else error('legacy repair modifier must never attach: '..tostring(id)) end
  self.cacheAttachments=(self.cacheAttachments or 0)+1
 end
 function c:GetYield() return 13*(1+self.repairYield/100)+2.5 end
 function c:GetBuildQueue() activeCity=self.id; return queue end
 function c:GetBuildings()
  return {HasBuilding=function(_,index) return self.owned[index]==true end,
   RemoveBuilding=function(_,index) self.owned[index]=nil end}
 end
 function c:GetDistricts() return {} end
 return c
end
cities={[10]=makeCity(10),[11]=makeCity(11)}
Map={GetPlot=function(x,y) if y~=2 or cities[x]==nil then return nil end
 return {GetIndex=function() return x end} end}
Cities={GetCityInPlot=function(index) return cities[index] end}
memberScans=0
local collection={FindID=function(_,id) return cities[id] end,
 Members=function() memberScans=memberScans+1;local ids={10,11};local i=0;return function()
  i=i+1;if ids[i] then return i,cities[ids[i]] end
 end end}
local player={props={}}
function player:GetID() return 0 end
function player:IsAlive() return true end
function player:IsMajor() return true end
function player:GetProperty(k) if self.props[k]==nil then return end; return self.props[k] end
function player:SetProperty(k,v) self.props[k]=v end
function player:AttachModifierByID(id)
 nativeAttachments[#nativeAttachments+1]=id
 if id=='LOTM_JUSTICE_SPONSOR_GOLD_NATIVE_START' then nativeIncome=nativeIncome+15
 elseif id=='LOTM_JUSTICE_SPONSOR_GOLD_NATIVE_STOP' then nativeIncome=nativeIncome-15
 else error('unexpected native modifier '..tostring(id)) end
end
function player:GetCities() return collection end
function player:GetGreatPeoplePoints() return {ChangePointsTotal=function() end} end
Players={[0]=player}; props=player.props
function snapshot(cityID,neutralized,sponsor,tarot,story,counsel,salon,suggestion,auditSerial,auditData)
 GameEvents.LOTM_JUSTICE_UpdateGovernor(0,{CityID=cityID,Established=1,
  Neutralized=neutralized or 0,
  GOVERNOR_PROMOTION_LOTM_JUSTICE_SPONSOR=sponsor==nil and 1 or sponsor,
  GOVERNOR_PROMOTION_LOTM_JUSTICE_COUNSEL=counsel==nil and 1 or counsel,
  GOVERNOR_PROMOTION_LOTM_JUSTICE_SALON=salon==nil and 1 or salon,
  GOVERNOR_PROMOTION_LOTM_JUSTICE_SUGGESTION=suggestion==nil and 1 or suggestion,
  GOVERNOR_PROMOTION_LOTM_JUSTICE_TAROT=tarot==nil and 1 or tarot,
  GOVERNOR_PROMOTION_LOTM_JUSTICE_STORY=story==nil and 1 or story,
  LoadAuditSerial=auditSerial,ProductionAuditData=auditData})
end
function tick(turn)
 now=turn;onTurn(0,true)
end
'''


def runtime():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(FIXTURE)
    lua.execute((ROOT / "Scripts/LOTM_JUSTICE_Governor.lua").read_text(encoding="utf-8-sig"))
    return lua


class JusticeStoryRuntimeTests(unittest.TestCase):
    def test_unpromoted_abilities_never_count_or_arm_and_orphan_pause_is_removed(self):
        lua = runtime()
        lua.execute('''
        cities[10].owned[9]=true
        snapshot(10,0,1,0,0)
        assert(cities[10].owned[9]==nil)
        for t=1,14 do tick(t) end
        assert(envoys==0 and props.JUSTICE_FOOL_ENVOY_COUNTER==nil)
        assert(props.JUSTICE_STORY_COUNTER==nil and cities[10].owned[9]==nil)
        snapshot(10,0,1,1,0)
        for t=15,21 do tick(t) end
        assert(envoys==1 and props.JUSTICE_STORY_COUNTER==nil)
        snapshot(10,0,1,1,1)
        for t=22,27 do tick(t) end
        assert(cities[10].owned[9]==nil and props.JUSTICE_STORY_COUNTER==6)
        snapshot(10,0,1,1,0)
        assert(cities[10].owned[9]==nil)
        tick(28)
        assert(props.JUSTICE_STORY_PENDING==0 and props.JUSTICE_STORY_COUNTER==6)
        ''')

    def test_unowned_story_never_activates_with_other_branches(self):
        lua = runtime()
        lua.execute('''
        snapshot(10,0,1,1,0,1,0,0)
        assert(props.JUSTICE_GOVERNOR_HAS_GOVERNOR_PROMOTION_LOTM_JUSTICE_TAROT==1)
        assert(props.JUSTICE_GOVERNOR_HAS_GOVERNOR_PROMOTION_LOTM_JUSTICE_STORY==0)
        for t=1,8 do tick(t) end
        assert(envoys==1 and cities[10].owned[9]==nil)
        snapshot(10,0,1,1,0,1,1,0)
        assert(props.JUSTICE_GOVERNOR_HAS_GOVERNOR_PROMOTION_LOTM_JUSTICE_TAROT==1)
        assert(props.JUSTICE_GOVERNOR_HAS_GOVERNOR_PROMOTION_LOTM_JUSTICE_STORY==0)
        for t=9,15 do tick(t) end
        assert(envoys==2 and cities[10].owned[9]==nil)
        ''')

    def test_saved_native_owned_story_with_missing_sibling_counts_and_triggers(self):
        lua = runtime()
        lua.execute('''
        -- Exact raw snapshot from the user's turn-63 save:
        -- 65536:1:0:1:1:1:0:1:1 (Story owned, Suggestion not owned).
        snapshot(10,0,1,1,1,1,1,0)
        assert(props.JUSTICE_GOVERNOR_HAS_GOVERNOR_PROMOTION_LOTM_JUSTICE_STORY==1)
        for t=1,6 do tick(t) end
        assert(props.JUSTICE_STORY_COUNTER==6 and props.JUSTICE_STORY_PENDING~=1)
        tick(7)
        assert(props.JUSTICE_STORY_PENDING==1 and props.JUSTICE_STORY_COUNTER==0)
        tick(8)
        assert(props.JUSTICE_STORY_PENDING==0 and cities[10].repairYield==0)
        ''')

    def test_native_sponsor_income_is_exact_once_and_reversible(self):
        lua = runtime()
        lua.execute('''
        -- Unset properties must not cause tonumber() to receive zero arguments.
        tick(1); assert(nativeIncome==0)
        snapshot(10); assert(nativeIncome==15 and #nativeAttachments==1)
        tick(2); tick(3); snapshot(10)
        assert(nativeIncome==15 and #nativeAttachments==1)
        snapshot(10,1); assert(nativeIncome==0 and #nativeAttachments==2)
        tick(4); assert(nativeIncome==0 and #nativeAttachments==2)
        snapshot(10,0); assert(nativeIncome==15 and #nativeAttachments==3)
        snapshot(-1); assert(nativeIncome==0 and #nativeAttachments==4)
        snapshot(11,0,0); assert(nativeIncome==0 and #nativeAttachments==4)
        snapshot(11,0,1); assert(nativeIncome==15 and #nativeAttachments==5)
        ''')

    def test_seven_turn_completion_is_single_use_without_production_freeze(self):
        lua = runtime()
        lua.execute('''snapshot(10)
        for t=1,5 do tick(t) end
        assert(props.JUSTICE_STORY_COUNTER==5 and cities[10].owned[9]==nil)
        tick(6);assert(props.JUSTICE_STORY_COUNTER==6 and cities[10].owned[9]==nil)
        tick(7);assert(props.JUSTICE_STORY_PENDING==1 and props.JUSTICE_STORY_COUNTER==0)
        assert(cities[10].repairYield==0)
        GameEvents.LOTM_JUSTICE_RecordStoryOriginal(0,{CityID=10,Kind='BUILDING',TypeID=100,Progress=20})
        local choice={CityID=11,TargetKind='BUILDING',TargetID=101,TargetHash=1001,
         OriginalQueued=1,OriginalProgress=20}
        GameEvents.LOTM_JUSTICE_CompleteStory(0,choice);assert(finishes==0)
        choice.CityID=10;choice.OriginalQueued=0
        GameEvents.LOTM_JUSTICE_CompleteStory(0,choice)
        assert(finishes==1 and props.JUSTICE_STORY_PENDING==0 and cities[10].owned[9]==nil)
        GameEvents.LOTM_JUSTICE_CompleteStory(0,choice);assert(finishes==1)
        tick(8);assert(cities[10].owned[9]==nil and props.JUSTICE_STORY_COUNTER==1)
        assert(envoys==1)''')

    def test_direct_click_without_original_capture_finishes_immediately(self):
        lua = runtime()
        lua.execute("""
        snapshot(10);for t=1,7 do tick(t) end
        assert(props.JUSTICE_STORY_ORIGINAL_CAPTURED==0)
        local choice={CityID=10,TargetKind='UNIT',TargetID=101,TargetHash=1001}
        GameEvents.LOTM_JUSTICE_CompleteStory(0,choice);assert(finishes==0)
        choice.TargetKind='BUILDING'
        GameEvents.LOTM_JUSTICE_CompleteStory(0,choice)
        assert(finishes==1 and props.JUSTICE_STORY_PENDING==0)
        GameEvents.LOTM_JUSTICE_CompleteStory(0,choice);assert(finishes==1)
        """)

    def test_current_gameplay_target_must_match_and_project_completes_without_canproduce(self):
        lua = runtime()
        lua.execute("""
        GameInfo.Projects[35]={Index=35,Hash=-1406079690}
        GameInfo.Projects.PROJECT_TEST=GameInfo.Projects[35]
        snapshot(10);for t=1,7 do tick(t) end
        local choice={CityID=10,TargetKind='PROJECT',TargetID=35,TargetHash=-1406079690}
        currentProduction=''
        GameEvents.LOTM_JUSTICE_CompleteStory(0,choice);assert(finishes==0)
        currentProduction=100
        GameEvents.LOTM_JUSTICE_CompleteStory(0,choice);assert(finishes==0)
        assert(props.JUSTICE_STORY_PENDING==1)
        currentProduction='PROJECT_TEST'
        GameEvents.LOTM_JUSTICE_CompleteStory(0,choice)
        assert(finishes==1 and props.JUSTICE_STORY_PENDING==0)
        GameEvents.LOTM_JUSTICE_CompleteStory(0,choice);assert(finishes==1)
        """)

    def test_unused_turn_expires_and_reassignment_moves_prearm(self):
        lua = runtime()
        lua.execute('''snapshot(10)
        for t=1,6 do tick(t) end
        assert(cities[10].owned[9]==nil and props.JUSTICE_STORY_ARMED_CITY_ID==10);snapshot(11)
        assert(cities[10].owned[9]==nil and props.JUSTICE_STORY_ARMED_CITY_ID==11)
        tick(7);assert(props.JUSTICE_STORY_PENDING==1 and props.JUSTICE_STORY_CITY_ID==11)
        tick(8);assert(props.JUSTICE_STORY_PENDING==0 and cities[11].owned[9]==nil)
        assert(props.JUSTICE_STORY_COUNTER==1)
        props.JUSTICE_STORY_COUNTER=6;snapshot(11,1)
        assert(cities[11].owned[9]==nil and props.JUSTICE_STORY_COUNTER==6)''')

    def test_saved_resource398_repair_receipt_is_cleared_without_new_modifier(self):
        lua = runtime()
        lua.execute('''
        -- Resource 401's database makes the old saved modifier inert.
        -- Gameplay only clears bookkeeping; no inverse may be attached.
        props.JUSTICE_STORY_PAUSE_SOURCE_VERSION=3
        props.JUSTICE_STORY_COUNTER=5
        props.JUSTICE_STORY_LEGACY_REPAIR_PHASE=2
        props.JUSTICE_STORY_LEGACY_REPAIR_COUNT=1
        props.JUSTICE_STORY_LEGACY_REPAIR_X=10
        props.JUSTICE_STORY_LEGACY_REPAIR_Y=2
        cities[10].owned[9]=true
        cities[10].props.JUSTICE_STORY_LEGACY_REPAIR_APPLIED_0=1
        cities[10].repairYield=0
        snapshot(10)
        assert(cities[10].owned[9]==nil)
        assert(props.JUSTICE_STORY_LEGACY_REPAIR_PHASE==5)
        assert(props.JUSTICE_STORY_LEGACY_REPAIR_COUNT==0)
        assert(props.JUSTICE_STORY_LEGACY_REPAIR_RETIRE_VERSION==2)
        assert(cities[10].props.JUSTICE_STORY_LEGACY_REPAIR_APPLIED_0==0)
        assert(cities[10].repairYield==0)
        snapshot(10)
        assert(cities[10].repairYield==0)
        tick(1)
        tick(2)
        assert(cities[10].repairYield==0)
        ''')

    def test_pre398_save_does_not_receive_a_new_counter(self):
        lua = runtime()
        lua.execute('''
        props.JUSTICE_STORY_PAUSE_SOURCE_VERSION=2
        props.JUSTICE_STORY_COUNTER=5
        cities[10].owned[9]=true
        snapshot(10)
        assert(cities[10].owned[9]==nil)
        assert(cities[10].repairYield==0)
        tick(1)
        assert(cities[10].repairYield==0)
        ''')

    def test_load_audit_clears_expired_story_and_legacy_yield_once(self):
        lua = runtime()
        lua.execute('''
        now=49
        props.JUSTICE_STORY_PAUSE_SOURCE_VERSION=4
        props.JUSTICE_STORY_PENDING=1
        props.JUSTICE_STORY_PENDING_TURN=46
        props.JUSTICE_STORY_CITY_ID=10
        props.JUSTICE_STORY_PAUSE_CLEANUP_ID=10
        props.JUSTICE_STORY_LEGACY_REPAIR_PHASE=2
        props.JUSTICE_STORY_LEGACY_REPAIR_COUNT=1
        cities[10].props.JUSTICE_STORY_LEGACY_REPAIR_APPLIED_0=1
        cities[10].repairYield=0
        cities[10].owned[9]=true
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,1)
        assert(props.JUSTICE_STORY_PENDING==0 and props.JUSTICE_STORY_CITY_ID==-1)
        assert(cities[10].owned[9]==nil and cities[10].repairYield==0)
        assert(props.JUSTICE_STORY_LOAD_AUDIT_SERIAL==1)
        assert(props.JUSTICE_GOVERNOR_SNAPSHOT_DIGEST=='10:1:0:1:1:1:1:1:1')
        local scans=memberScans
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,1)
        assert(memberScans==scans and cities[10].repairYield==0)
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,2)
        assert(props.JUSTICE_STORY_LOAD_AUDIT_SERIAL==2)
        assert(memberScans==scans and cities[10].repairYield==0)
        ''')

    def test_resource400_retired_save_does_not_attach_another_inverse(self):
        lua = runtime()
        lua.execute('''
        props.JUSTICE_STORY_LEGACY_REPAIR_RETIRE_VERSION=1
        props.JUSTICE_STORY_LEGACY_REPAIR_PHASE=4
        props.JUSTICE_STORY_LEGACY_REPAIR_COUNT=0
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,1)
        assert(props.JUSTICE_STORY_LEGACY_REPAIR_RETIRE_VERSION==2)
        assert(cities[10].repairYield==0)
        tick(1)
        assert(cities[10].repairYield==0)
        ''')

    def test_load_audit_preserves_only_current_special_turn(self):
        lua = runtime()
        lua.execute('''
        now=7
        props.JUSTICE_STORY_PENDING=1
        props.JUSTICE_STORY_PENDING_TURN=7
        props.JUSTICE_STORY_CITY_ID=10
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,1)
        assert(props.JUSTICE_STORY_PENDING==1)
        assert(props.JUSTICE_STORY_LOAD_AUDIT_SERIAL==1)
        now=8
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,2)
        assert(props.JUSTICE_STORY_PENDING==0)
        assert(props.JUSTICE_STORY_LOAD_AUDIT_SERIAL==2)
        ''')


class JusticeProductionCacheTests(unittest.TestCase):
    def test_real_ui_gameplay_roundtrip_from_stale_save_to_one_completion(self):
        from generate_startup_trace import strip_trace
        lua = runtime()
        lua.execute('''
        contextHidden=true
        ContextPtr={SetHide=function(_,v) contextHidden=v end,IsHidden=function() return contextHidden end}
        now=69; props.JUSTICE_LAST_SETTLED_TURN=68; props.JUSTICE_STORY_COUNTER=3
        props.JUSTICE_GOVERNOR_HAS_GOVERNOR_PROMOTION_LOTM_JUSTICE_STORY=0
        props.JUSTICE_GOVERNOR_SNAPSHOT_DIGEST='10:1:0:1:1:1:0:1:1'
        Game.GetLocalPlayer=function() return 0 end
        local function Event()
         local handlers={}; return {Add=function(fn) handlers[#handlers+1]=fn end,
          Fire=function() for _,fn in ipairs(handlers) do fn() end end}
        end
        Events=setmetatable({},{__index=function(t,k) local e=Event();rawset(t,k,e);return e end})
        Controls={HintLabel={SetText=function(_,v) hint=v end},StoryPanel={SetHide=function(_,v) panelHidden=v end},
         CompleteButton={RegisterCallback=function(_,_,fn) completeClick=fn end,
          SetDisabled=function(_,v) buttonDisabled=v end},CityLabel={SetText=function() end}}
        Mouse={eLClick=1}; PlayerOperations={EXECUTE_SCRIPT=99}
        CityProductionDirectives={CONSTRUCT=1,PROJECT=2,TRAIN=3,ZONE=4}
        Locale={Lookup=function(s) return s end}
        GameInfo.GovernorPromotions={}
        for i,n in ipairs({'SPONSOR','COUNSEL','SALON','SUGGESTION','TAROT','STORY'}) do
         GameInfo.GovernorPromotions['GOVERNOR_PROMOTION_LOTM_JUSTICE_'..n]={Hash=i}
        end
        local gov={GetType=function() return 1 end,GetAssignedCity=function() return cities[10] end,
         IsEstablished=function() return true end,GetNeutralizedTurns=function() return 0 end,
         HasPromotion=function(_,hash) return hash~=4 end}
        Players[0].IsTurnActive=function() return true end
        Players[0].GetGovernors=function() return {GetGovernorList=function() return 1,{gov} end} end
        cities[10].GetYieldToolTip=function() return nil end -- formerly blocked ALL snapshots
        cities[10].GetName=function() return 'Beijing' end
        local q=cities[10]:GetBuildQueue()
        GameInfo.Buildings.BUILDING_TEST=GameInfo.Buildings[101]
        originalProgress=20
        q.GetAt=function(_,i)
         if selected and i==0 then return {Directive=1,BuildingType='BUILDING_TEST'} end
         if not selected and i==0 then return {Directive=1,BuildingType=100} end
        end
        q.GetSize=function() return 1 end
        q.GetCurrentProductionTypeHash=function() return selected and 1001 or 0 end
        q.GetBuildingProgress=function(_,id) return id==100 and originalProgress or 0 end
        snapshotSubmits=0
        UI={RequestPlayerOperation=function(id,op,params)
         assert(op==99)
         if params.OnStart=='LOTM_JUSTICE_UpdateGovernor' then
          snapshotSubmits=snapshotSubmits+1
          if snapshotSubmits==1 then return false end -- lost first command
         end
         GameEvents[params.OnStart](id,params);return true
        end}
        ''')
        lua.execute(strip_trace((ROOT / 'UI/LOTM_JUSTICE_Story.lua').read_text(encoding='utf-8')))
        lua.execute('''
        for i=1,30 do Events.GameCoreEventPublishComplete.Fire() end
        assert(props.JUSTICE_GOVERNOR_SNAPSHOT_SERIAL==1)
        assert(props.JUSTICE_GOVERNOR_HAS_GOVERNOR_PROMOTION_LOTM_JUSTICE_STORY==1)
        assert(props.JUSTICE_STORY_LOAD_AUDIT_SERIAL==nil) -- unreadable audit not falsely acked
        for t=70,72 do tick(t);Events.PlayerTurnActivated.Fire() end
        assert(props.JUSTICE_STORY_COUNTER==6 and panelHidden)
        tick(73);Events.PlayerTurnActivated.Fire()
        assert(props.JUSTICE_STORY_PENDING==1 and not panelHidden and not buttonDisabled)
        assert(not contextHidden, "InGame loads add-in contexts hidden; a visible child is not visible on screen")
        ''')
        # Reload the UI while a saved current-turn opportunity is already pending.
        lua.execute('contextHidden=true')
        lua.execute(strip_trace((ROOT / 'UI/LOTM_JUSTICE_Story.lua').read_text(encoding='utf-8')))
        lua.execute('''
        Events.LoadGameViewStateDone.Fire()
        assert(not contextHidden and not panelHidden and props.JUSTICE_STORY_PENDING==1)
        originalProgress=22.5 -- legitimate production settled after the initial capture
        selected=true; Events.CityProductionQueueChanged.Fire(); completeClick();completeClick()
        assert(originalProgress==22.5) -- completion never resets the original item
        assert(finishes==1 and props.JUSTICE_STORY_PENDING==0)
        tick(74);Events.PlayerTurnActivated.Fire()
        assert(panelHidden and cities[10].repairYield==0)
        ''')

    def test_serialized_10000_survives_db_zero_but_observed_audit_corrects_once(self):
        lua = runtime()
        lua.execute('''
        cities[10].repairYield=10000
        cities[10].props.JUSTICE_STORY_LEGACY_REPAIR_APPLIED_0=0
        props.JUSTICE_STORY_LEGACY_REPAIR_RETIRE_VERSION=2
        props.JUSTICE_STORY_PAUSE_SOURCE_VERSION=5
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,1,'10,10000,1315.5')
        assert(cities[10]:GetYield()==15.5 and cities[10].cacheAttachments==1)
        assert(props.JUSTICE_PRODUCTION_VERIFY_NEEDED==1)
        -- Duplicate synchronized request and stale UI observation cannot stack.
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,1,'10,10000,1315.5')
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,2,'10,10000,1315.5')
        assert(cities[10].cacheAttachments==1 and props.JUSTICE_STORY_LOAD_AUDIT_SERIAL==1)
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,2,'10,0,15.5')
        assert(props.JUSTICE_PRODUCTION_VERIFY_NEEDED==0)
        assert(cities[10].props.JUSTICE_PRODUCTION_CACHE_PENDING==0)
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,3,'10,0,15.5')
        tick(51)
        assert(cities[10].cacheAttachments==1 and cities[10]:GetYield()==15.5)
        ''')

    def test_negative_residue_preserves_legitimate_bonus_and_requires_city_evidence(self):
        lua = runtime()
        lua.execute('''
        cities[10].repairYield=-19994
        cities[10].props.JUSTICE_STORY_LEGACY_REPAIR_APPLIED_0=0
        local before=cities[10]:GetYield()
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,1,'10,-19994,'..before)
        assert(cities[10].repairYield==6 and cities[10].cacheAttachments==2)
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,2,'10,0,'..cities[10]:GetYield())
        cities[11].repairYield=10000
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,3,'11,10000,'..cities[11]:GetYield())
        assert(cities[11].cacheAttachments==nil and cities[11].repairYield==10000)
        ''')

    def test_pending_effect_waits_for_observation_instead_of_attaching_twice(self):
        lua = runtime()
        lua.execute('''
        cities[10].repairYield=10000
        cities[10].props.JUSTICE_STORY_LEGACY_REPAIR_APPLIED_0=0
        cities[10].AttachModifierByID=function(self,id) self.cacheAttachments=(self.cacheAttachments or 0)+1 end
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,1,'10,10000,1315.5')
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,2,'10,10000,1315.5')
        assert(cities[10].cacheAttachments==1 and props.JUSTICE_STORY_LOAD_AUDIT_SERIAL==1)
        cities[10].repairYield=0
        snapshot(10,nil,nil,nil,nil,nil,nil,nil,2,'10,0,15.5')
        assert(cities[10].cacheAttachments==1 and props.JUSTICE_PRODUCTION_VERIFY_NEEDED==0)
        ''')


if __name__ == "__main__":
    unittest.main(verbosity=2)
