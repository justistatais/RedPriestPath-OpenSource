"""Cosmetic native-call contract tests; not a Civ VI rendering verdict."""
from pathlib import Path
import unittest
from test_rc346_thief_rule_guards import LuaRuntime
ROOT=Path(__file__).resolve().parents[1];SOURCE=(ROOT/'Scripts/LOTM_PlayerModels.lua').read_text()
FIXTURE='''
function print() end
stats={writes=0,promotions=0,lookups=0}; owned={[999]=true}; up={}; pp={LOTM_RP_UNIT_ID=4,LOTM_RP_SEQUENCE=9}; kind='UNIT_LOTM_RP_PATH_HOLDER'; ignored=false
xp={HasPromotion=function(_,id) return owned[id]==true end,SetPromotion=function(_,id,value) stats.promotions=stats.promotions+1;if not ignored then owned[id]=value end end}
unit={GetOwner=function() return 0 end,GetID=function() return 4 end,GetType=function() return 20 end,GetExperience=function() return xp end,GetProperty=function(_,key) return up[key] end,SetProperty=function(_,key,value) stats.writes=stats.writes+1;up[key]=value end}
player={GetProperty=function(_,key) return pp[key] end,GetUnits=function() return {FindID=function(_,id) stats.lookups=stats.lookups+1;if id==4 then return unit end end} end}
Players={[0]=player};GameInfo={Units={[20]={UnitType=kind}},UnitPromotions={}}
for i=1,3 do GameInfo.UnitPromotions['PROMOTION_LPM_TIER_'..i]={Index=100+i} end
GameEvents={PlayerTurnStarted={Add=function(f) turn=f end},UnitInitialized={Add=function(f) initialized=f end}}
'''
def runtime(extra=''):
 l=LuaRuntime(unpack_returned_tuples=True);l.execute(FIXTURE+extra);l.execute(SOURCE);return l
class PlayerModels(unittest.TestCase):
 def test_load_is_readonly(self):runtime().execute('assert(stats.writes==0 and stats.promotions==0 and stats.lookups==0)')
 def test_ten_sequence_boundaries(self):
  for seq,tier in [(9,0),(8,0),(7,0),(6,0),(5,0),(4,1),(3,1),(2,2),(1,2),(0,3)]:
   runtime(f'pp.LOTM_RP_SEQUENCE={seq}').execute(f'turn(0);assert(up.LOTM_PLAYER_MODEL_TIER_V1=={tier});assert(stats.promotions=={tier});assert(owned[999])')
 def test_four_paths(self):
  for path in ['RP','PP','BE','TP']:runtime(f"GameInfo.Units[20].UnitType='UNIT_LOTM_{path}_PATH_HOLDER';pp.LOTM_RP_SEQUENCE=2").execute('turn(0);assert(up.LOTM_PLAYER_MODEL_TIER_V1==2)')
 def test_repeated_turn_does_not_write(self):runtime('pp.LOTM_RP_SEQUENCE=2').execute('turn(0);for i=1,20 do turn(0) end;assert(stats.promotions==2 and stats.writes==1 and stats.lookups==21)')
 def test_ascent_keeps_other_promotions(self):runtime().execute('turn(0);pp.LOTM_RP_SEQUENCE=4;turn(0);pp.LOTM_RP_SEQUENCE=2;turn(0);pp.LOTM_RP_SEQUENCE=0;turn(0);assert(stats.promotions==3 and owned[999] and unit:GetID()==4)')
 def test_reset_removes_only_visual_promotions(self):runtime('pp.LOTM_RP_SEQUENCE=0').execute('turn(0);pp.LOTM_RP_SEQUENCE=9;turn(0);assert(up.LOTM_PLAYER_MODEL_TIER_V1==0 and owned[999] and not owned[101] and not owned[102] and not owned[103])')
 def test_foreign_units_untouched(self):runtime("GameInfo.Units[20].UnitType='UNIT_WARRIOR'").execute('turn(0);initialized(0,4);assert(stats.writes==0 and stats.promotions==0)')
 def test_rescue_gods_not_modified(self):runtime("GameInfo.Units[20].UnitType='UNIT_LOTM_RESCUE_GOD_THIEF'").execute('turn(0);assert(stats.writes==0 and stats.promotions==0)')
 def test_missing_identity_no_scan(self):runtime('pp.LOTM_RP_UNIT_ID=nil').execute('turn(0);assert(stats.lookups==0 and stats.writes==0)')
 def test_new_unit_initialized(self):runtime('pp.LOTM_RP_SEQUENCE=3').execute('initialized(0,4);assert(up.LOTM_PLAYER_MODEL_TIER_V1==1)')
 def test_invalid_sequence_no_write(self):
  for s in ['nil','-1','10','1.5',"'bad'"]:runtime(f'pp.LOTM_RP_SEQUENCE={s}').execute('turn(0);assert(stats.writes==0 and stats.promotions==0)')
 def test_native_rejection_does_not_record_success(self):runtime('ignored=true;pp.LOTM_RP_SEQUENCE=0').execute('turn(0);assert(up.LOTM_PLAYER_MODEL_TIER_V1==nil);ignored=false;turn(0);assert(up.LOTM_PLAYER_MODEL_TIER_V1==3)')
 def test_reload_does_not_regrant(self):
  l=runtime('pp.LOTM_RP_SEQUENCE=1');l.execute('turn(0)');l.execute(SOURCE);l.execute('turn(0);assert(stats.promotions==2 and stats.writes==1)')
 def test_identical_peer_event_stream(self):
  a,b=runtime(),runtime()
  for l in [a,b]:l.execute('initialized(0,4);pp.LOTM_RP_SEQUENCE=2;turn(0)')
  self.assertEqual(a.eval('up.LOTM_PLAYER_MODEL_TIER_V1'),b.eval('up.LOTM_PLAYER_MODEL_TIER_V1'))
if __name__=='__main__':unittest.main()
