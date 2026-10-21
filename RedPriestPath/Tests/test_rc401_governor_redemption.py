"""Rescue migration, combat attribution and source-owned visibility regressions.

Native rendering, event publication timing and native count serialization remain
manual tests. These objects exercise the real Lua handlers, not a replacement rule.
"""
from pathlib import Path
import sqlite3
import re
import sys
import unittest
import xml.etree.ElementTree as ET
import zlib
from unittest.mock import patch

from luaparser import ast
from test_rc346_thief_rule_guards import LuaRuntime
from test_magician_star_runtime import FIXTURE
import test_justice_story_runtime as justice

ROOT=Path(__file__).resolve().parents[1]
DB=Path(sys.argv.pop(1)) if len(sys.argv)>1 and not sys.argv[1].startswith('-') else None

EXTRA=r'''
rescue=true; science=0; culture=0; gameprops={LOTM_RESCUE_MODE=1}; ticks={}; vischanges=0
Game.GetProperty=function(k) return gameprops[k] end
Game.SetProperty=function(k,v) gameprops[k]=v end
LOTM_MP_TurnSync.IsRescueModeConfigured=function() return rescue end
LOTM_MP_TurnSync.Add=function(f,k) ticks[k]=f end
LOTM_MP_TurnSync.AddSynchronized=function(f,k) ticks[k]=f end
rngs=0;choice=0
LOTM_MP_TurnSync.Random=function(n,label) rngs=rngs+1;return choice end
GameInfo.GovernorPromotions={GOVERNOR_PROMOTION_LOTM_STAR_HIDDEN_WORLD={Hash=1}}
GameInfo.Resources.RESOURCE_LOTM_RESCUE_STAR_PATROL_ACTIVE={Index=90}
GameInfo.Units={
 [1]={Index=1,UnitType='UNIT_SCOUT',PromotionClass='PROMOTION_CLASS_RECON',Combat=10,FormationClass='FORMATION_CLASS_LAND_COMBAT'},
 [2]={Index=2,UnitType='UNIT_WARRIOR',PromotionClass='PROMOTION_CLASS_MELEE',Combat=20,FormationClass='FORMATION_CLASS_LAND_COMBAT'},
 [3]={Index=3,UnitType='UNIT_SETTLER',PromotionClass='PROMOTION_CLASS_CIVILIAN',Combat=0,FormationClass='FORMATION_CLASS_CIVILIAN'},
 [4]={Index=4,UnitType='UNIT_LOTM_PATH_HOLDER',PromotionClass='PROMOTION_CLASS_RECON',Combat=40,FormationClass='FORMATION_CLASS_LAND_COMBAT'},
 [5]={Index=5,UnitType='UNIT_CARAVEL',PromotionClass='PROMOTION_CLASS_NAVAL_MELEE',Combat=50,FormationClass='FORMATION_CLASS_NAVAL'},
 [6]={Index=6,UnitType='UNIT_RANGER',PromotionClass='PROMOTION_CLASS_RECON',Combat=60,FormationClass='FORMATION_CLASS_LAND_COMBAT'},
 [7]={Index=7,UnitType='UNIT_LOTM_RESCUE_MONSTER',PromotionClass='PROMOTION_CLASS_MELEE',Combat=80,FormationClass='FORMATION_CLASS_LAND_COMBAT'}}
local plots={};local width,height=48,28
for y=0,height-1 do for x=0,width-1 do
 local i=y*width+x; local p={i=i,x=x,y=y,owner=0}
 function p:GetIndex() return self.i end
 function p:GetX() return self.x end
 function p:GetY() return self.y end
 function p:GetOwner() return self.owner end
 plots[i]=p
end end
Map.GetPlotCount=function() return width*height end
Map.GetPlotByIndex=function(i) return plots[i] end
Map.GetPlot=function(x,y) if x<0 or y<0 or x>=width or y>=height then return nil end;return plots[y*width+x] end
Map.GetPlotXYWithRangeCheck=function(x,y,dx,dy,r)
 if math.max(math.abs(dx),math.abs(dy),math.abs(dx+dy))>r then return nil end
 return Map.GetPlot(x+dx,y+dy)
end
Cities.GetCityInPlot=function(i) if i==490 then return cities[10] elseif i==510 then return cities[11] end end
units={};owners={0,1,2};resources={};attached={};wars={[1]=true,[2]=true}
function MakeUnit(owner,id,t,x,y)
 local u={owner=owner,id=id,t=t,x=x,y=y,props={},dead=false,remaining=1}
 function u:GetOwner() return self.owner end
 function u:GetID() return self.id end
 function u:GetType() return self.t end
 function u:GetX() return self.x end
 function u:GetY() return self.y end
 function u:GetProperty(k) return self.props[k] end
 function u:SetProperty(k,v) self.props[k]=v end
 function u:IsDead() return self.dead end
 function u:IsDelayedDeath() return self.dead end
 function u:ChangeMovesRemaining() error('Forbidden: replenishing moves') end
 units[owner..':'..id]=u;return u
end
UnitManager={GetUnit=function(o,i) return units[o..':'..i] end}
function UnitCollection(owner)
 return {Members=function()
  local ids={};for _,u in pairs(units) do if u.owner==owner then ids[#ids+1]=u.id end end;table.sort(ids)
  local j=0;return function() j=j+1;local id=ids[j];if id then return id,units[owner..':'..id] end end
 end}
end
player.GetUnits=function() return UnitCollection(0) end
player.GetResources=function() return {GetResourceAmount=function(_,i) return resources[i] or 0 end,
 ChangeResourceAmount=function(_,i,n) resources[i]=(resources[i] or 0)+n end} end
player.AttachModifierByID=function(_,m) attached[m]=(attached[m] or 0)+1 end
player.GetTechs=function() return {ChangeCurrentResearchProgress=function(_,n) science=science+n end} end
player.GetCulture=function() return {ChangeCurrentCulturalProgress=function(_,n) culture=culture+n end} end
player.GetDiplomacy=function() return {IsAtWarWith=function(_,id) return wars[id]==true end} end
player.GetDistricts=function() return {FindID=function(_,i) if i==40 then return {GetOwner=function() return 0 end} end end} end
for _,id in ipairs({1,2}) do
 Players[id]={GetUnits=function() return UnitCollection(id) end,
  IsAlive=function() return true end,IsMajor=function() return false end}
end
PlayerManager={GetAliveIDs=function() return {0,1,2} end}
PlayersVisibility[0].ChangeVisibilityCount=function(_,i,n) sight[i]=(sight[i] or 0)+n;assert(sight[i]>=0);vischanges=vischanges+1 end
MakeUnit(0,10,1,10,10);MakeUnit(0,11,2,11,10)
function Governor(case,gloves,world,neutral,city)
 GameEvents.LOTM_MS_UpdateGovernor(0,{STAR_CityID=city or 10,STAR_Established=1,STAR_Neutralized=neutral or 0,
  GOVERNOR_PROMOTION_LOTM_STAR_WATCHER=1,GOVERNOR_PROMOTION_LOTM_STAR_PATROL=1,GOVERNOR_PROMOTION_LOTM_STAR_INVESTIGATION=1,
  GOVERNOR_PROMOTION_LOTM_STAR_CASE_FILES=case or 0,GOVERNOR_PROMOTION_LOTM_STAR_RED_GLOVES=gloves or 0,
  GOVERNOR_PROMOTION_LOTM_STAR_HIDDEN_WORLD=world or 0})
end
function Move(id,x,y)
 local u=units['0:'..id];u.x=x;u.y=y;GameEvents.OnUnitMoved(0,id)
end
function Stop(id)
 local u=units['0:'..id]
 GameEvents.LOTM_RESCUE_StarMoveComplete(0,{UnitID=id,Identity=u.props.LOTM_RESCUE_STAR_IDENTITY,
  MoveSerial=u.props.LOTM_RESCUE_STAR_MOVE_SERIAL,Turn=turn,PlotIndex=Map.GetPlot(u.x,u.y):GetIndex()})
end
function Kill(victimID,t,x,y,land,attackerID,owner)
 owner=owner or 1;local v=MakeUnit(owner,victimID,t,x,y);Map.GetPlot(x,y).owner=land
 GameEvents.LOTM_RESCUE_StarUnitLifecycle(0,{OwnerID=owner,UnitID=victimID})
 v.dead=true
 GameEvents.UnitKilledInCombat(owner,victimID,0,attackerID or 11)
 GameEvents.OnCombatOccurred(0,attackerID or 11,owner,victimID)
 return v
end
'''

def runtime(normal=False):
    l=LuaRuntime(unpack_returned_tuples=True); l.execute(FIXTURE); l.execute(EXTRA)
    if normal:l.execute('rescue=false;gameprops.LOTM_RESCUE_MODE=0')
    l.execute((ROOT/'Scripts/LOTM_MS_Governors.lua').read_text(encoding='utf-8'))
    l.execute((ROOT/'Scripts/LOTM_RESCUE_StarGovernor.lua').read_text(encoding='utf-8'))
    return l

class RescueStarTests(unittest.TestCase):
    def test_modes_are_isolated_and_normal_captures_never_pay_in_rescue(self):
        l=runtime();l.execute('''Governor(1,1,1);assert(player.props.LOTM_MS_STAR_HAS_GOVERNOR_PROMOTION_LOTM_STAR_CONTACT==0)
        GameEvents.LOTM_MS_Interrogation(0,{Captured=1,AttackerID=1,MissionID=1});assert(science==0 and culture==0)
        assert(attached.LOTM_MS_CONTACT_PLAYER419==nil and attached.LOTM_MS_GUARDIAN_PLAYER417==nil)''')
        l=runtime(True);l.execute('Governor(1,1,1);assert(gameprops.LOTM_RESCUE_STAR_UNIT_LEDGER_VERSION==nil);assert(ticks.RescueStarGovernor==nil)')

    def test_owned_territory_kills_random_one_yield_no_cap_and_dedup_across_events(self):
        l=runtime();l.execute('''Governor(1,0,0)
        Kill(20,2,12,10,0);assert(science==300 and culture==0 and rngs==1)
        choice=1;Kill(21,5,13,10,0);assert(science==300 and culture==300 and rngs==2)
        choice=0;Kill(22,7,14,10,0);assert(science==600 and culture==300 and rngs==3)
        GameEvents.UnitKilledInCombat(1,20,0,11);GameEvents.OnCombatOccurred(0,11,1,20)
        assert(science==600 and culture==300 and rngs==3)''')

    def test_foreign_unowned_allied_and_civilian_victims_never_pay(self):
        l=runtime();l.execute('''Governor(1,0,0)
        for i,land in ipairs({-1,1,2}) do Kill(30+i,2,12+i,10,land) end
        Kill(40,3,20,10,0);wars[2]=false;Kill(41,2,21,10,0,11,2)
        assert(science==0 and culture==0 and rngs==0)''')

    def test_script_removal_conversion_and_unverified_attackers_never_pay(self):
        l=runtime();l.execute('''Governor(1,0,0)
        local v=MakeUnit(1,42,2,20,10);GameEvents.LOTM_RESCUE_StarUnitLifecycle(0,{OwnerID=1,UnitID=42})
        units['1:42']=nil;GameEvents.LOTM_RESCUE_StarUnitLifecycle(0,{OwnerID=1,UnitID=42})
        GameEvents.OnCombatOccurred(0,11,1,42)
        assert(science==0)
        v=MakeUnit(1,43,2,21,10);GameEvents.UnitKilledInCombat(1,43,0,11);assert(science==0)
        Kill(44,2,22,10,0,999);assert(science==0 and rngs==0)
        MakeUnit(2,11,2,23,10);MakeUnit(1,45,2,23,11).dead=true
        GameEvents.OnCombatOccurred(2,11,1,45);assert(science==0)''')

    def test_defensive_kill_and_verified_city_attack(self):
        l=runtime();l.execute('''Governor(1,0,0)
        MakeUnit(1,50,2,12,10).dead=true;GameEvents.OnCombatOccurred(1,50,0,11)
        assert(science==300)
        MakeUnit(1,51,2,13,10).dead=true;GameEvents.OnCombatOccurred(0,-1,1,51,40,-1)
        assert(science==600)
        MakeUnit(1,52,2,14,10).dead=true;GameEvents.OnCombatOccurred(0,-1,1,52,999,-1)
        assert(science==600)''')

    def test_dead_victim_cache_current_plot_owner_and_reused_unit_id(self):
        l=runtime();l.execute('''Governor(1,0,0)
        local v=MakeUnit(1,60,2,12,10);GameEvents.OnUnitMoved(1,60)
        Map.GetPlot(12,10).owner=1;GameEvents.UnitKilledInCombat(1,60,0,11)
        units['1:60']=nil;Map.GetPlot(12,10).owner=0;GameEvents.OnCombatOccurred(0,11,1,60);assert(science==0)
        Kill(60,2,13,10,0);assert(science==300 and rngs==1)
        local v=MakeUnit(1,61,2,14,10);GameEvents.UnitKilledInCombat(1,61,0,11)
        units['1:61']=nil;GameEvents.OnCombatOccurred(0,11,1,61);assert(science==600 and rngs==2)''')

    def test_patrol_only_completed_moves_refresh_source_and_next_own_turn_clear(self):
        l=runtime();l.execute('''Governor(0,1,0)
        local before=sight[Map.GetPlot(11,10):GetIndex()] or 0
        Move(10,11,10);assert((sight[Map.GetPlot(11,10):GetIndex()] or 0)==before)
        Stop(10);local n=vischanges;Stop(10);assert(vischanges==n)
        assert(sight[Map.GetPlot(11,10):GetIndex()]==before+1)
        Move(10,12,10);Stop(10);assert(sight[Map.GetPlot(10,10):GetIndex()]==1)
        local n=vischanges;ticks.RescueStarGovernor(1,true);assert(vischanges==n)
        turn=6;ticks.RescueStarGovernor(0,true);assert(player.props.LOTM_RESCUE_STAR_PATROL_REFERENCES['10']==nil)
        local n=vischanges;ticks.RescueStarGovernor(0,true);assert(vischanges==n)''')

    def test_patrol_multiple_units_and_ineligible_units(self):
        l=runtime();l.execute('''Governor(0,1,0)
        MakeUnit(0,12,6,12,10);Move(10,11,10);Stop(10);Move(12,11,10);Stop(12)
        assert(sight[Map.GetPlot(11,10):GetIndex()]==3)
        Move(11,11,10);Stop(11);assert(player.props.LOTM_RESCUE_STAR_PATROL_REFERENCES['11']==nil)
        MakeUnit(0,13,4,10,10);Move(13,11,10);Stop(13);assert(player.props.LOTM_RESCUE_STAR_PATROL_REFERENCES['13']==nil)
        units['0:10']=nil;GameEvents.LOTM_RESCUE_StarUnitLifecycle(0,{OwnerID=0,UnitID=10})
        assert(sight[Map.GetPlot(11,10):GetIndex()]==2)
        units['0:12'].t=1;GameEvents.LOTM_RESCUE_StarUnitLifecycle(0,{OwnerID=0,UnitID=12})
        assert(sight[Map.GetPlot(11,10):GetIndex()]==1)''')

    def test_patrol_stale_commands_transfer_and_neutralization(self):
        l=runtime();l.execute('''Governor(0,1,0);Move(10,11,10);Stop(10)
        local u=units['0:10'];local n=vischanges
        GameEvents.LOTM_RESCUE_StarMoveComplete(0,{UnitID=10,Identity=u.props.LOTM_RESCUE_STAR_IDENTITY,
         MoveSerial=u.props.LOTM_RESCUE_STAR_MOVE_SERIAL-1,Turn=turn,PlotIndex=490});assert(vischanges==n)
        units['0:10']=nil;u.owner=2;units['2:10']=u
        GameEvents.LOTM_RESCUE_StarUnitLifecycle(0,{OwnerID=0,UnitID=10});assert(next(player.props.LOTM_RESCUE_STAR_PATROL_REFERENCES)==nil)
        Governor(0,1,0,1);assert(resources[90]==0)
        Governor(0,1,0,0);Governor(0,1,0,1);Governor(0,1,0,0)
        assert(resources[90]==1 and attached.LOTM_RESCUE_STAR_PATROL_MOVEMENT==1 and u.remaining==1)''')

    def test_old_move_completion_cannot_reappear_after_reassignment(self):
        l=runtime();l.execute('''Governor(0,1,0);Move(10,11,10)
        Governor(0,1,0,1);Governor(0,1,0,0);Stop(10)
        assert(next(player.props.LOTM_RESCUE_STAR_PATROL_REFERENCES)==nil)
        Move(10,12,10);Stop(10);assert(player.props.LOTM_RESCUE_STAR_PATROL_REFERENCES['10']~=nil)''')

    def test_native_ui_and_guard_requires_both_without_changing_other_promotions(self):
        s=(ROOT/'UI/LOTM_RESCUE_GovernorDetailsPanel.lua').read_text(encoding='utf-8')
        helper=s.split('-- BEGIN LOTM RESCUE STAR AND PREREQUISITES\n',1)[1].split('-- END LOTM RESCUE STAR AND PREREQUISITES',1)[0]
        l=LuaRuntime(unpack_returned_tuples=True)
        l.execute('''GameInfo={GovernorPromotions={
         GOVERNOR_PROMOTION_LOTM_STAR_CASE_FILES={Hash=1},GOVERNOR_PROMOTION_LOTM_STAR_RED_GLOVES={Hash=2}}}
         owned={};governor={HasPromotion=function(_,h) return owned[h]==true end}''')
        l.execute(helper+'\nCheck=LOTM_StarBranchesOwned')
        l.execute('''local world={GovernorPromotionType='GOVERNOR_PROMOTION_LOTM_STAR_HIDDEN_WORLD'}
         assert(not Check(governor,world));owned[1]=true;assert(not Check(governor,world))
         owned[2]=true;assert(Check(governor,world));owned[1]=false;assert(not Check(governor,world))
         assert(Check(nil,{GovernorPromotionType='NATIVE_OTHER_PROMOTION'}))''')
        self.assertIn('canEarnPromotion = canEarnPromotion and LOTM_StarBranchesOwned',s)
        self.assertIn('if not LOTM_StarBranchesOwned(governor,promotion) then m_SelectedPromotion=-1',s)
        ast.parse(re.sub(r'\s*:\s*(?:boolean|number|string|table)\b','',s))

    def test_full_map_both_branches_only_and_native_sources_survive_retraction(self):
        l=runtime();l.execute('''local far=Map.GetPlot(47,27):GetIndex();sight[far]=2
        Governor(1,0,1);assert(player.props.LOTM_RESCUE_STAR_FULL_VISION_ACTIVE==nil)
        Governor(1,1,1);assert(sight[far]==3)
        for i=0,Map.GetPlotCount()-1 do assert((sight[i] or 0)>0) end
        local n=vischanges;for i=1,5 do LOTM_RESCUE_StarGovernor.Refresh(0) end;assert(vischanges==n)
        Governor(1,1,1,1);assert(sight[far]==2 and sight[490]==0)
        Governor(1,1,1);Governor(1,1,0);assert(sight[far]==2 and sight[490]==1)
        Governor(1,1,1);cities[10]=nil;LOTM_RESCUE_StarGovernor.Refresh(0);assert(sight[far]==2)
        ''')

    def test_reload_preserved_counts_and_rewards_do_not_duplicate(self):
        l=runtime();l.execute('Governor(1,1,1);Move(10,11,10);Stop(10);Kill(70,2,15,10,0);before=vischanges')
        l.execute((ROOT/'Scripts/LOTM_RESCUE_StarGovernor.lua').read_text(encoding='utf-8'))
        l.execute('''LOTM_RESCUE_StarGovernor.Refresh(0);assert(vischanges==before)
        GameEvents.OnCombatOccurred(0,11,1,70);assert(science==300 and rngs==1)
        Governor(1,1,0);assert(sight[490]==2);turn=6;ticks.RescueStarGovernor(0,true);assert(sight[490]==1)''')

    def test_reload_missing_native_counts_restores_minimum_owned_references_once(self):
        l=runtime();l.execute('Governor(1,1,1);sight={}')
        l.execute((ROOT/'Scripts/LOTM_RESCUE_StarGovernor.lua').read_text(encoding='utf-8'))
        l.execute('''LOTM_RESCUE_StarGovernor.Refresh(0);assert(sight[490]==2 and sight[Map.GetPlot(47,27):GetIndex()]==1)
        local n=vischanges;LOTM_RESCUE_StarGovernor.Refresh(0);assert(vischanges==n)
        Governor(1,1,0);assert(sight[490]==1 and sight[Map.GetPlot(47,27):GetIndex()]==0)''')

    def test_magician_history_unchanged_in_rescue_and_migration_runs_once(self):
        l=runtime();l.execute('''Governor(0,0,0)
        GameEvents.LOTM_MS_UpdateGovernor(0,{MAGICIAN_CityID=10,MAGICIAN_Established=1,MAGICIAN_Neutralized=0,
         GOVERNOR_PROMOTION_LOTM_MAGICIAN_RECORD=1})
        assert(player.props.LOTM_MS_RECORD_B_BUILDING_LIBRARY==1 and player.props.LOTM_MS_RECORD_D_DISTRICT_CAMPUS==1)
        local identity=gameprops.LOTM_RESCUE_STAR_NEXT_IDENTITY
        for i=1,5 do LOTM_RESCUE_StarGovernor.Refresh(0) end
        assert(gameprops.LOTM_RESCUE_STAR_NEXT_IDENTITY==identity)
        cities[10].ownedBuildings[2]=true;GameEvents.BuildingConstructed(0,10,2,490,true)
        assert(player.props.LOTM_MS_RECORD_B_BUILDING_MARKET==1)''')

    def test_real_ui_submits_only_final_endpoint_retries_and_handles_lifecycle(self):
        l=runtime();l.execute(r'''
        Events=setmetatable({},{__index=function(t,k)
         local fs={};local e={Add=function(f) fs[#fs+1]=f end}
         setmetatable(e,{__call=function(_,...) for _,f in ipairs(fs) do f(...) end end});rawset(t,k,e);return e
        end});LuaEvents={};GameConfiguration={GetValue=function() return 1 end}
        Game.GetLocalPlayer=function() return 0 end
        player.IsTurnActive=function() return true end
        GameInfo.GovernorPromotions=setmetatable({},{__index=function(_,k) return {Hash=k} end})
        player.GetGovernors=function() return {GetGovernorList=function() return 1,{{
          GetType=function() return 2 end,GetAssignedCity=function() return cities[10] end,
          IsEstablished=function() return true end,GetNeutralizedTurns=function() return 0 end,
          HasPromotion=function(_,hash) return hash=='GOVERNOR_PROMOTION_LOTM_STAR_RED_GLOVES' or hash=='GOVERNOR_PROMOTION_LOTM_STAR_WATCHER' end
        }} end} end
        requests=0;drop=false;PlayerOperations={EXECUTE_SCRIPT=1}
        UI={RequestPlayerOperation=function(id,op,data)
         requests=requests+1;if not drop then GameEvents[data.OnStart](id,data) end;return true
        end}
        ''')
        l.execute((ROOT/'UI/LOTM_MS_Governors.lua').read_text(encoding='utf-8'))
        l.execute('''Move(10,11,10);Events.UnitMoveComplete(0,10,11,10)
        assert(player.props.LOTM_RESCUE_STAR_PATROL_REFERENCES['10']==nil)
        Move(10,12,10);Events.UnitMoveComplete(0,10,12,10);drop=true
        Events.GameCoreEventPublishComplete();assert(player.props.LOTM_RESCUE_STAR_PATROL_REFERENCES['10']==nil)
        drop=false;for i=1,20 do Events.GameCoreEventPublishComplete() end
        assert(player.props.LOTM_RESCUE_STAR_PATROL_REFERENCES['10'].MoveSerial==2)
        local n=requests;for i=1,40 do Events.GameCoreEventPublishComplete() end;assert(requests==n)
        units['0:10']=nil;Events.UnitRemovedFromMap(0,10);Events.GameCoreEventPublishComplete()
        assert(next(player.props.LOTM_RESCUE_STAR_PATROL_REFERENCES)==nil)''')

class RescueJusticeTests(justice.JusticeStoryRuntimeTests):
    """Repeat the same Justice rules with rescue configured before loading Lua."""
    def setUp(self):
        base=justice.runtime
        def rescue_runtime(*args,**kwargs):
            l=base(*args,**kwargs)
            l.execute('LOTM_MP_TurnSync.IsRescueModeConfigured=function() return true end')
            return l
        self.patcher=patch.object(justice,'runtime',rescue_runtime);self.patcher.start()
        self.addCleanup(self.patcher.stop)

class DatabaseIsolationTests(unittest.TestCase):
    @unittest.skipIf(DB is None,'Pass a native DebugGameplay.sqlite snapshot')
    def test_mode_trees_shared_skills_modifiers_and_text_routing(self):
        source=sqlite3.connect(DB.resolve().as_uri()+'?mode=ro',uri=True)
        normal=sqlite3.connect(':memory:');source.backup(normal)
        normal.create_function('Make_Hash',1,lambda v:zlib.crc32(v.encode()) if v else 0)
        for name in ('LOTM_JUSTICE_Governor.sql','LOTM_MS_Governors.sql'):
            normal.executescript((ROOT/'Gameplay'/name).read_text(encoding='utf-8'))
        rescue=sqlite3.connect(':memory:');normal.backup(rescue)
        rescue.create_function('Make_Hash',1,lambda v:zlib.crc32(v.encode()) if v else 0)
        rescue.execute('PRAGMA foreign_keys=ON')
        rescue.executescript((ROOT/'Gameplay/LOTM_RESCUE_Governors.sql').read_text(encoding='utf-8'))
        self.assertEqual(list(rescue.execute('PRAGMA foreign_key_check')),[])
        def tree(db,g):return {r[0] for r in db.execute('SELECT GovernorPromotion FROM GovernorPromotionSets WHERE GovernorType=?',(g,))}
        for g in ('GOVERNOR_LOTM_JUSTICE','GOVERNOR_LOTM_MAGICIAN'):
            self.assertEqual(tree(normal,g),tree(rescue,g))
            q='SELECT m.* FROM GovernorPromotionModifiers m JOIN GovernorPromotionSets s ON m.GovernorPromotionType=s.GovernorPromotion WHERE s.GovernorType=? ORDER BY m.GovernorPromotionType,m.ModifierId'
            self.assertEqual(list(normal.execute(q,(g,))),list(rescue.execute(q,(g,))))
        n=tree(normal,'GOVERNOR_LOTM_STAR');r=tree(rescue,'GOVERNOR_LOTM_STAR')
        self.assertEqual(len(n),6);self.assertEqual(len(r),6)
        self.assertEqual(n-r,{'GOVERNOR_PROMOTION_LOTM_STAR_'+x for x in ('INTERROGATION','CONTACT','GUARDIAN')})
        self.assertEqual(r-n,{'GOVERNOR_PROMOTION_LOTM_STAR_'+x for x in ('CASE_FILES','RED_GLOVES','HIDDEN_WORLD')})
        self.assertEqual(normal.execute("SELECT count(*) FROM GovernorPromotions WHERE GovernorPromotionType LIKE '%HIDDEN_WORLD'").fetchone()[0],0)
        self.assertEqual(rescue.execute("SELECT count(*) FROM GovernorPromotionModifiers WHERE GovernorPromotionType IN ('GOVERNOR_PROMOTION_LOTM_STAR_CONTACT','GOVERNOR_PROMOTION_LOTM_STAR_GUARDIAN','GOVERNOR_PROMOTION_LOTM_STAR_INTERROGATION')").fetchone()[0],0)
        self.assertEqual({x[0] for x in rescue.execute("SELECT PrereqGovernorPromotion FROM GovernorPromotionPrereqs WHERE GovernorPromotionType='GOVERNOR_PROMOTION_LOTM_STAR_HIDDEN_WORLD'")},{'GOVERNOR_PROMOTION_LOTM_STAR_CASE_FILES','GOVERNOR_PROMOTION_LOTM_STAR_RED_GLOVES'})
        self.assertEqual(rescue.execute("SELECT Value FROM ModifierArguments WHERE ModifierId='LOTM_RESCUE_STAR_PATROL_MOVEMENT' AND Name='Amount'").fetchone()[0],'1')
        self.assertEqual(rescue.execute("SELECT Value FROM RequirementArguments WHERE RequirementId='LOTM_RESCUE_STAR_RECON_REQ' AND Name='UnitPromotionClass'").fetchone()[0],'PROMOTION_CLASS_RECON')
        self.assertEqual(rescue.execute("SELECT SubjectRequirementSetId FROM Modifiers WHERE ModifierId='LOTM_MS_STAR_LOCAL_SPY'").fetchone()[0],None)
        for language in ('zh_Hans_CN','en_US'):
            source=ET.parse(ROOT/'Text'/language/'LOTM_RESCUE_Governors.xml').getroot().find('./LocalizedText')
            selected=ET.parse(ROOT/'Text/Selected'/f'LOTM_RESCUE_Governors_{language}.xml').getroot().find('./BaseGameText')
            self.assertEqual({r.get('Tag'):r.findtext('Text') for r in source},{r.get('Tag'):r.findtext('Text') for r in selected})
            self.assertTrue(all(r.tag=='Replace' and r.get('Language') is None for r in selected))
        mod=ET.parse(ROOT/'RedPriestPath.modinfo')
        for node in mod.findall('.//InGameActions/*'):
            if node.get('id','').startswith('LOTM_RESCUE_GOVERNORS_'):
                criteria=mod.find(f".//ActionCriteria/Criteria[@id='{node.get('criteria')}']")
                self.assertIsNotNone(criteria)
                self.assertTrue(any(c.findtext('ConfigurationId')=='GAMEMODE_LOTM_RESCUE' and c.findtext('Value')=='1' for c in criteria.findall('ConfigurationValueMatches')))
        for name in ('Scripts/LOTM_RESCUE_StarGovernor.lua','Scripts/LOTM_MS_Governors.lua','UI/LOTM_MS_Governors.lua'):
            ast.parse((ROOT/name).read_text(encoding='utf-8'))

if __name__=='__main__':unittest.main(verbosity=2)
