"""Exercise Magician history and Star visibility state with Civ-like Lua objects."""

from pathlib import Path
import unittest

from test_rc346_thief_rule_guards import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = r'''
function print() end
turn=5; attachments={}; sight={}
Game={GetCurrentGameTurn=function() return turn end}
local buildings={
 {Index=1,BuildingType='BUILDING_LIBRARY',Cost=80,InternalOnly=0},
 {Index=2,BuildingType='BUILDING_MARKET',Cost=100,InternalOnly=0},
 {Index=3,BuildingType='BUILDING_HIDDEN',Cost=1,InternalOnly=1}}
local districts={
 {Index=4,DistrictType='DISTRICT_CAMPUS',Cost=60},
 {Index=5,DistrictType='DISTRICT_CITY_CENTER',Cost=60}}
local function info(rows,byIndex)
 local t=byIndex or {}
 for _,row in ipairs(rows) do t[row.Index]=row; end
 return setmetatable(t,{__call=function() local i=0; return function() i=i+1; return rows[i] end end})
end
GameInfo={Resources={},Governors={GOVERNOR_LOTM_MAGICIAN={Index=1},GOVERNOR_LOTM_STAR={Index=2}},
 Buildings=info(buildings),Districts=info(districts)}
LOTM_MP_TurnSync={IsRescueModeConfigured=function() return false end,
 Add=function(fn,key) if key=='MagicianStarGovernors' then tick=fn end end}
GameEvents=setmetatable({},{__index=function(t,k)
 local handlers={}; local event={Add=function(fn) handlers[#handlers+1]=fn end};
 setmetatable(event,{__call=function(_,...) for _,fn in ipairs(handlers) do fn(...) end end});
 rawset(t,k,event);return event
end})
local allplots={}
local function plot(x,y)
 local id=x*1000+y
 if not allplots[id] then
  allplots[id]={GetIndex=function() return id end}
 end
 return allplots[id]
end
Map={GetPlot=function(x,y) if x==nil or y==nil then return nil end;return plot(x,y) end,
 GetPlotByIndex=function(i) return allplots[i] end,
 GetPlotXYWithRangeCheck=function(x,y,dx,dy,r)
  if math.max(math.abs(dx),math.abs(dy),math.abs(dx+dy))>r then return nil end
  return plot(x+dx,y+dy)
 end}
local function city(id,x)
 local c={id=id,x=x,props={},ownedBuildings={},ownedDistricts={}}
 function c:GetID() return self.id end
 function c:GetOwner() return 0 end
 function c:GetX() return self.x end
 function c:GetY() return 10 end
 function c:GetProperty(k) return self.props[k] end
 function c:SetProperty(k,v) self.props[k]=v end
 function c:AttachModifierByID(modifier)
  attachments[#attachments+1]={self.id,modifier};return true
 end
 function c:GetBuildings()
  return {HasBuilding=function(_,index) return self.ownedBuildings[index]==true end}
 end
 function c:GetDistricts()
  return {HasDistrict=function(_,index) return self.ownedDistricts[index]==true end}
 end
 return c
end
cities={[10]=city(10,10),[11]=city(11,30)}
cities[10].ownedBuildings[1]=true;cities[10].ownedDistricts[4]=true
Cities={GetCityInPlot=function(index)
 if index==10010 then return cities[10] end
 if index==30010 then return cities[11] end
 return nil
end}
local cityCollection={FindID=function(_,id) return cities[id] end,
 Members=function() local ids={10,11}; local i=0; return function()
  i=i+1; if ids[i] then return i,cities[ids[i]] end
 end end}
player={props={}}
function player:GetID() return 0 end
function player:IsAlive() return true end
function player:IsMajor() return true end
function player:GetProperty(k) return self.props[k] end
function player:SetProperty(k,v) self.props[k]=v end
function player:GetCities() return cityCollection end
Players={[0]=player}
PlayersVisibility={[0]={GetVisibilityCount=function(_,i) return sight[i] or 0 end,
 IsVisible=function(_,i) return (sight[i] or 0)>0 end,
 ChangeVisibilityCount=function(_,i,delta)
  sight[i]=(sight[i] or 0)+delta;assert(sight[i]>=0)
 end}}
function snapshot(magCity,starCity,record,watch)
 GameEvents.LOTM_MS_UpdateGovernor(0,{
  MAGICIAN_CityID=magCity,MAGICIAN_Established=magCity>=0 and 1 or 0,
  MAGICIAN_Neutralized=0,GOVERNOR_PROMOTION_LOTM_MAGICIAN_RECORD=record or 0,
  GOVERNOR_PROMOTION_LOTM_MAGICIAN_GATE=1,
  GOVERNOR_PROMOTION_LOTM_MAGICIAN_SERIAL=1,
  GOVERNOR_PROMOTION_LOTM_MAGICIAN_SUPPLY=1,
  STAR_CityID=starCity,STAR_Established=starCity>=0 and 1 or 0,
  STAR_Neutralized=0,GOVERNOR_PROMOTION_LOTM_STAR_WATCHER=watch or 0})
end
'''


def runtime():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(FIXTURE)
    lua.execute((ROOT / "Scripts/LOTM_MS_Governors.lua").read_text(encoding="utf-8"))
    return lua


class MagicianStarRuntimeTests(unittest.TestCase):
    def test_ui_retries_lost_snapshot_and_capture_then_stops_on_receipt(self):
        lua=runtime()
        lua.execute(r'''
        Events=setmetatable({},{__index=function(t,k)
          local handlers={};local event={Add=function(fn) handlers[#handlers+1]=fn end}
          setmetatable(event,{__call=function(_,...) for _,fn in ipairs(handlers) do fn(...) end end})
          rawset(t,k,event);return event
        end})
        LuaEvents={}; Game.GetLocalPlayer=function() return 0 end
        active=true; player.IsTurnActive=function() return active end
        owned=true
        GameInfo.GovernorPromotions=setmetatable({},{__index=function(_,k) return {Hash=k} end})
        player.GetGovernors=function() return {GetGovernorList=function() return 1,{{
          GetType=function() return 2 end,GetAssignedCity=function() return cities[10] end,
          IsEstablished=function() return true end,GetNeutralizedTurns=function() return 0 end,
          HasPromotion=function(_,hash) return owned and hash=='GOVERNOR_PROMOTION_LOTM_STAR_INTERROGATION' end
        }} end} end
        science=0;player.GetTechs=function() return {ChangeCurrentResearchProgress=function(_,n) science=science+n end} end
        LOTM_MP_TurnSync.Random=function() return 0 end
        mission={InitialResult=1,EscapeResult=0,PlotIndex=10010,CompletionTurn=5}
        Players[1]={IsAlive=function() return true end,IsMajor=function() return true end,
          GetDiplomacy=function() return {GetMission=function() return mission end} end}
        Map.GetPlot(10,10);Cities.GetPlotPurchaseCity=function() return cities[10] end
        EspionageResultTypes={CAPTURED=1};PlayerOperations={EXECUTE_SCRIPT=1}
        requests={}; drop=true
        UI={RequestPlayerOperation=function(id,op,data)
          requests[#requests+1]=data.OnStart
          if not drop then GameEvents[data.OnStart](id,data) end
          return true
        end}
        ''')
        lua.execute((ROOT / 'UI/LOTM_MS_Governors.lua').read_text(encoding='utf-8'))
        lua.execute(r'''
        assert(#requests==1 and player.props.LOTM_MS_SNAPSHOT_DIGEST==nil)
        -- Loading can consume all attempts while native EXECUTE_SCRIPT accepts
        -- requests without dispatching them. Closing the loading screen must
        -- recover in the SAME turn, without requiring Next Turn.
        for i=1,260 do Events.GameCoreEventPublishComplete() end
        assert(#requests==12 and player.props.LOTM_MS_SNAPSHOT_DIGEST==nil)
        drop=false
        Events.LoadScreenClose()
        assert(#requests==13 and player.props.LOTM_MS_SNAPSHOT_DIGEST~=nil)
        for i=1,25 do Events.GameCoreEventPublishComplete() end
        assert(#requests==13)
        active=false;Events.SpyMissionCompleted(1,9);assert(science==0)
        active=true;drop=true;Events.PlayerTurnActivated(0,true);assert(science==0)
        drop=false;for i=1,20 do Events.GameCoreEventPublishComplete() end
        assert(science==300)
        Events.SpyMissionCompleted(1,9);assert(science==300)
        mission.InitialResult=2;Events.SpyMissionCompleted(1,10);assert(science==300)
        mission.InitialResult=1;owned=false;Events.SpyMissionCompleted(1,11);assert(science==300)
        ''')

    def test_owned_record_is_not_revoked_by_purchase_prerequisites(self):
        lua = runtime()
        lua.execute(r'''
        tick(0,true)
        GameEvents.LOTM_MS_UpdateGovernor(0,{
         MAGICIAN_CityID=10,MAGICIAN_Established=1,MAGICIAN_Neutralized=0,
         GOVERNOR_PROMOTION_LOTM_MAGICIAN_RECORD=1,
         STAR_CityID=-1,STAR_Established=0,STAR_Neutralized=0})
        assert(player.props.LOTM_MS_MAGICIAN_HAS_GOVERNOR_PROMOTION_LOTM_MAGICIAN_RECORD==1)
        assert(#attachments==2)
        ''')

    def test_player_leases_toggle_without_stacking_and_owned_guardian_needs_no_sibling(self):
        lua=runtime()
        lua.execute(r"""
        GameInfo.Resources.RESOURCE_LOTM_MS_CONTACT_NATIVE419_ACTIVE={Index=80}
        GameInfo.Resources.RESOURCE_LOTM_MS_CONTACT_ACTIVE={Index=82}
        GameInfo.Resources.RESOURCE_LOTM_MS_GUARDIAN_ACTIVE={Index=81}
        local resources={[82]=1};local attached={}
        player.GetResources=function() return {
         GetResourceAmount=function(_,id) return resources[id] or 0 end,
         ChangeResourceAmount=function(_,id,n) resources[id]=(resources[id] or 0)+n end} end
        player.AttachModifierByID=function(_,id) attached[id]=(attached[id] or 0)+1 end
        local state={STAR_CityID=10,STAR_Established=1,STAR_Neutralized=0,
          GOVERNOR_PROMOTION_LOTM_STAR_CONTACT=1,GOVERNOR_PROMOTION_LOTM_STAR_GUARDIAN=1}
        GameEvents.LOTM_MS_UpdateGovernor(0,state)
        assert(resources[80]==1 and resources[81]==1)
        assert(resources[82]==0 and attached.LOTM_MS_CONTACT_PLAYER417==nil)
        assert(attached.LOTM_MS_CONTACT_PLAYER419==1)
        for i=1,3 do tick(0,true);GameEvents.LOTM_MS_UpdateGovernor(0,state) end
        for _,n in pairs(attached) do assert(n==1) end
        state.STAR_Neutralized=1;GameEvents.LOTM_MS_UpdateGovernor(0,state)
        assert(resources[80]==0 and resources[81]==0)
        state.STAR_Neutralized=0;state.STAR_Established=0
        GameEvents.LOTM_MS_UpdateGovernor(0,state);assert(resources[80]==0)
        state.STAR_Established=1;state.GOVERNOR_PROMOTION_LOTM_STAR_CONTACT=0
        GameEvents.LOTM_MS_UpdateGovernor(0,state)
        assert(resources[80]==0 and resources[81]==1)
        state.STAR_CityID=-1;GameEvents.LOTM_MS_UpdateGovernor(0,state)
        assert(resources[81]==0)
        """)

    def test_captured_case_awards_one_random_yield_once_and_respects_ownership(self):
        lua=runtime()
        lua.execute(r"""
        local science,culture=0,0
        player.GetTechs=function() return {ChangeCurrentResearchProgress=function(_,n) science=science+n end} end
        player.GetCulture=function() return {ChangeCurrentCulturalProgress=function(_,n) culture=culture+n end} end
        LOTM_MP_TurnSync.Random=function() return 0 end
        Players[1]={IsAlive=function() return true end,IsMajor=function() return true end}
        Cities.GetPlotPurchaseCity=function(plot) return cities[10] end
        Map.GetPlot(10,10)
        local state={STAR_CityID=10,STAR_Established=1,STAR_Neutralized=0,
          GOVERNOR_PROMOTION_LOTM_STAR_INTERROGATION=0}
        GameEvents.LOTM_MS_UpdateGovernor(0,state)
        local case={Captured=1,AttackerID=1,MissionID=5,CompletionTurn=5,PlotIndex=10010,CityID=10}
        GameEvents.LOTM_MS_Interrogation(0,case);assert(science==0)
        state.GOVERNOR_PROMOTION_LOTM_STAR_INTERROGATION=1
        GameEvents.LOTM_MS_UpdateGovernor(0,state)
        case.Captured=0;GameEvents.LOTM_MS_Interrogation(0,case);assert(science==0)
        case.Captured=1;GameEvents.LOTM_MS_Interrogation(0,case)
        GameEvents.LOTM_MS_Interrogation(0,case);assert(science==300 and culture==0)
        LOTM_MP_TurnSync.Random=function() return 1 end
        case.MissionID=6;GameEvents.LOTM_MS_Interrogation(0,case)
        assert(science==300 and culture==300)
        case.MissionID=7;case.CompletionTurn=2;GameEvents.LOTM_MS_Interrogation(0,case)
        assert(culture==300)
        """)

    def test_unpromoted_record_and_watcher_do_not_apply(self):
        lua = runtime()
        lua.execute(r'''
        tick(0,true)
        snapshot(10,11,0,0)
        assert(#attachments==0 and next(sight)==nil)
        cities[10].ownedBuildings[2]=true
        GameEvents.BuildingConstructed(0,10,2,10010,true)
        assert(player.props.LOTM_MS_RECORD_B_BUILDING_MARKET==1)
        assert(#attachments==0)
        snapshot(10,11,1,0)
        assert(#attachments==3 and next(sight)==nil)
        snapshot(10,11,1,1)
        assert(sight[30010]==1)
        snapshot(10,11,0,0)
        assert((sight[30010] or 0)==0)
        assert(cities[10].props.LOTM_MS_RECORD_APPLIED_0_B_BUILDING_LIBRARY==0)
        ''')

    def test_old_save_history_is_once_and_record_modifier_reverses(self):
        lua = runtime()
        lua.execute(r'''
        tick(0,true)
        assert(player.props.LOTM_MS_RECORD_VERSION==1)
        assert(player.props.LOTM_MS_RECORD_MIGRATED_BUILDINGS==1)
        assert(player.props.LOTM_MS_RECORD_MIGRATED_DISTRICTS==1)
        snapshot(10,-1,1,0)
        local n=#attachments;assert(n==2)
        snapshot(10,-1,1,0);tick(0,true);assert(#attachments==n)
        cities[10].ownedBuildings[2]=true
        GameEvents.BuildingConstructed(0,10,2,10010,true)
        assert(#attachments==n+1)
        assert(player.props.LOTM_MS_RECORD_B_BUILDING_MARKET==1)
        snapshot(11,-1,1,0)
        assert(#attachments==n+7)
        assert(cities[10].props.LOTM_MS_RECORD_APPLIED_0_B_BUILDING_LIBRARY==0)
        assert(cities[11].props.LOTM_MS_RECORD_APPLIED_0_B_BUILDING_LIBRARY==1)
        snapshot(-1,-1,0,0)
        assert(#attachments==n+10)
        ''')

    def test_star_sight_is_hexagonal_and_reversible(self):
        lua = runtime()
        lua.execute(r'''
        tick(0,true)
        snapshot(-1,10,0,1)
        assert(sight[10010]==1)
        assert(sight[16010]==1 and sight[17010]==nil)
        assert(sight[16016]==nil)
        snapshot(-1,10,0,1);assert(sight[10010]==1)
        -- Simulate a loaded save whose plot ledger persisted but visibility
        -- counts were rebuilt by the engine.
        sight[10010]=0
        tick(0,true)
        assert(sight[10010]==1)
        tick(0,true)
        assert(sight[10010]==1)
        snapshot(-1,11,0,1)
        assert((sight[10010] or 0)==0 and sight[30010]==1)
        snapshot(-1,-1,0,0)
        assert((sight[30010] or 0)==0)
        ''')


if __name__ == "__main__":
    unittest.main()
