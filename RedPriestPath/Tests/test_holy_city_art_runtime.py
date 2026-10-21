"""Exercise cosmetic selector installation without claiming native game behavior."""
from pathlib import Path
import unittest
from test_rc346_thief_rule_guards import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
SOURCE=(ROOT/'Scripts/LOTM_RESCUE_HolyCityArt.lua').read_text(encoding='utf-8-sig')
FIXTURE=r'''
function print() end
props={LOTM_RESCUE_MODE=1,LOTM_RESCUE_PHASE2A_STATE='READY',LOTM_RESCUE_TEST_PLAYER_ID=62}
stats={created={},lookups=0,writes=0};failure=nil
Game={GetProperty=function(k) return props[k] end,SetProperty=function(k,v) props[k]=v;stats.writes=stats.writes+1 end}
PlayerManager={GetFreeCitiesPlayerID=function() return 62 end}
GameInfo={Buildings={}};cities={};zones={'FOOL','NIGHT','STORM','CENTER'}
for i,z in ipairs(zones) do
 GameInfo.Buildings['BUILDING_LOTM_RESCUE_HOLY_CITY_'..z]={Index=100+i}
 props['LOTM_RESCUE_'..z..'_CITY_ID']=i
 props['LOTM_RESCUE_'..z..'_CITY_PLOT']=1000+i
 local c={id=i,owner=62,owned={}}
 function c:GetOwner() return self.owner end
 function c:GetID() return self.id end
 function c:GetBuildings() return {HasBuilding=function(_,n) return self.owned[n]==true end} end
 function c:GetBuildQueue()
  return {CreateBuilding=function(_,n)
   stats.created[#stats.created+1]=n
   if failure=='error' and n==102 then error('native unavailable') end
   if failure~=n then self.owned[n]=true end
  end}
 end
 cities[1000+i]=c
end
Map={GetPlotByIndex=function(p) return {GetX=function() return p end,GetY=function() return 0 end} end}
CityManager={GetCityAt=function(x,y) stats.lookups=stats.lookups+1;return cities[x] end}
GameEvents={PlayerTurnStarted={Add=function(fn) onTurn=fn end},LOTM_RESCUE_Command_BootstrapCity={Add=function(fn) onBootstrap=fn end}}
'''
def runtime(prefix=''):
 lua=LuaRuntime(unpack_returned_tuples=True);lua.execute(FIXTURE+prefix);lua.execute(SOURCE);return lua
class HolyCityArt(unittest.TestCase):
 def test_load_does_not_write(self):
  runtime().execute('assert(#stats.created==0 and stats.writes==0 and stats.lookups==0)')
 def test_new_game_install_four_in_stable_order(self):
  runtime().execute("onBootstrap();assert(table.concat(stats.created,',')=='101,102,103,104');assert(props.LOTM_RESCUE_HOLY_CITY_ART_IDENTITY_V2)")
 def test_only_ready_rescue(self):
  for change in ["props.LOTM_RESCUE_MODE=0", "props.LOTM_RESCUE_PHASE2A_STATE='PENDING'", "GameInfo.Buildings={}"]:
   runtime(change).execute('onTurn(0);onBootstrap();assert(#stats.created==0 and stats.writes==0 and stats.lookups==0)')
 def test_repeated_event_never_rescans_native_cities(self):
  runtime().execute('onTurn(0);local n=stats.lookups;for i=1,20 do onTurn(i);onBootstrap() end;assert(#stats.created==4 and stats.lookups==n and stats.writes==1)')
 def test_old_save_already_has_one_marker(self):
  runtime('cities[1001].owned[101]=true').execute("onTurn(0);assert(table.concat(stats.created,',')=='102,103,104')")
 def test_partial_failure_only_pending_city_retried(self):
  runtime('failure=102').execute("onTurn(0);assert(not props.LOTM_RESCUE_HOLY_CITY_ART_IDENTITY_V2);failure=nil;onTurn(1);assert(table.concat(stats.created,',')=='101,102,103,104,102');assert(stats.writes==1)")
 def test_native_exception_does_not_claim_success(self):
  runtime("failure='error'").execute("onTurn(0);assert(not props.LOTM_RESCUE_HOLY_CITY_ART_IDENTITY_V2 and cities[1003].owned[103]);failure=nil;onTurn(0);assert(stats.writes==1)")
 def test_missing_city_retry(self):
  runtime('saved=cities[1002];cities[1002]=nil').execute('onTurn(0);assert(not props.LOTM_RESCUE_HOLY_CITY_ART_IDENTITY_V2);cities[1002]=saved;onTurn(0);assert(#stats.created==4 and stats.writes==1)')
 def test_foreign_city_not_modified(self):
  runtime('cities[1002].owner=0').execute('onTurn(0);assert(not cities[1002].owned[102] and #stats.created==3 and stats.writes==0)')
 def test_wrong_city_id_not_modified(self):
  runtime('cities[1002].id=8').execute('onTurn(0);assert(not cities[1002].owned[102] and stats.writes==0)')
 def test_no_native_reads_for_incomplete_identity(self):
  runtime('props.LOTM_RESCUE_NIGHT_CITY_ID=nil').execute('onTurn(0);assert(stats.lookups==0 and stats.writes==0)')
 def test_reload_preserves_idempotence(self):
  lua=runtime();lua.execute('onTurn(0)');lua.execute(SOURCE);lua.execute('onTurn(0);assert(#stats.created==4 and stats.lookups==4 and stats.writes==1)')
 def test_identity_change_reconciles_new_city(self):
  runtime().execute('onTurn(0);props.LOTM_RESCUE_NIGHT_CITY_ID=12; cities[1002].id=12;cities[1002].owned={};onTurn(0);assert(#stats.created==5 and stats.writes==2)')
 def test_identical_peer_sequences(self):
  a,b=runtime(),runtime()
  for lua in [a,b]:lua.execute('onTurn(0);onBootstrap();onTurn(1)')
  self.assertEqual(a.eval('props.LOTM_RESCUE_HOLY_CITY_ART_IDENTITY_V2'),b.eval('props.LOTM_RESCUE_HOLY_CITY_ART_IDENTITY_V2'))
 def test_v1_save_migrates_only_star_and_retains_old_receipt(self):
  runtime("props.LOTM_RESCUE_HOLY_CITY_ART_IDENTITY_V1='old';for i=1,3 do cities[1000+i].owned[100+i]=true end").execute("onTurn(0);assert(table.concat(stats.created,',')=='104');assert(props.LOTM_RESCUE_HOLY_CITY_ART_IDENTITY_V1=='old');local n=stats.lookups;onBootstrap();assert(stats.lookups==n and stats.writes==1)")
 def test_missing_star_identity_does_not_write(self):
  runtime('props.LOTM_RESCUE_CENTER_CITY_PLOT=nil').execute('onTurn(0);assert(stats.lookups==0 and stats.writes==0 and #stats.created==0)')
 def test_star_foreign_owner_is_not_changed(self):
  runtime('cities[1004].owner=0').execute('onTurn(0);assert(not cities[1004].owned[104] and #stats.created==3 and stats.writes==0)')
 def test_star_creation_failure_is_retried(self):
  runtime('failure=104').execute("onTurn(0);assert(not props.LOTM_RESCUE_HOLY_CITY_ART_IDENTITY_V2);failure=nil;onTurn(0);assert(table.concat(stats.created,',')=='101,102,103,104,104' and stats.writes==1)")
if __name__=='__main__':unittest.main(verbosity=2)
