#!/usr/bin/env python3
"""Exercise actual Thief Lua functions at rule boundaries; no Civ VI claim."""
from __future__ import annotations

import argparse
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(add_help=False)
parser.add_argument("--source-root", type=Path, default=ROOT)
args, remaining = parser.parse_known_args()
SOURCE_ROOT = args.source_root
sys.argv = [sys.argv[0], *remaining]
try:
    from lupa.lua51 import LuaRuntime
except ImportError:
    sys.path.insert(0, str(ROOT.parent / ".tmp" / "refactor-rc340-python"))
    from lupa.lua51 import LuaRuntime

BASE = r'''
function include() end
function print() end
stats={writes=0,attached=0,points=0,digests={},nativeFound=0,created=0}
turn=1; rescue=false
Game={GetCurrentGameTurn=function() return turn end,
 GetProperty=function(k) if k=="LOTM_RESCUE_MODE" then return rescue and 1 or 0 end end}
GameConfiguration={GetValue=function() return rescue end}
LOTM_MP_TurnSync={IsRescueModeConfigured=function() return rescue end}
function Player(id,civ)
 local p={id=id,props={LOTM_RP_PATH="PATH_THIEF",LOTM_RP_SEQUENCE=9},alive=true,human=true,major=true}
 function p:GetID() return self.id end
 function p:GetProperty(k) return self.props[k] end
 function p:SetProperty(k,v) self.props[k]=v; stats.writes=stats.writes+1 end
 function p:IsAlive() return self.alive end
 function p:IsHuman() return self.human end
 function p:IsMajor() return self.major end
 function p:AttachModifierByID(mod) stats.attached=stats.attached+1 end
 return p
end
Players={[0]=Player(0),[1]=Player(1),[2]=Player(2),[3]=Player(3)}
PlayerConfigurations={}
for id=0,3 do local civ="CIV_"..id; PlayerConfigurations[id]={GetCivilizationTypeName=function() return civ end} end
PlayerManager={GetAliveMajors=function() return {Players[0],Players[1],Players[2],Players[3]} end,
 GetWasEverAliveMajors=function() return {Players[3],Players[0],Players[1],Players[2]} end}
LOTM_RP_State={GetSequence=function(id) return Players[id].props.LOTM_RP_SEQUENCE end,
 IsThiefPlayer=function(id) return Players[id]~=nil and Players[id].props.LOTM_RP_PATH=="PATH_THIEF" end,
 TryAddDigestion=function(id,category,key,amount)
  local full=id..":"..Players[id].props.LOTM_RP_SEQUENCE..":"..key
  if stats.digests[full] or stats.points>=6 then return false end
  stats.digests[full]=true; stats.points=math.min(6,stats.points+(amount or 1)); return true
 end}
function ResetStats() stats={writes=0,attached=0,points=0,digests={},nativeFound=0,created=0} end
function EmptyRows() return function() end end
GameInfo={Units=setmetatable({}, {__call=EmptyRows}), Buildings=EmptyRows,
 Districts=EmptyRows, Improvements=EmptyRows, CivilizationTraits=EmptyRows,
 TraitModifiers=EmptyRows, Modifiers={}}
YieldTypes={PRODUCTION=1}
'''


def runtime(module: str, extra_exports: str = ""):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(BASE)
    lua.execute((SOURCE_ROOT / "Scripts/LOTM_Effects.lua").read_text(encoding="utf-8-sig"))
    source = (SOURCE_ROOT / "Scripts" / f"{module}.lua").read_text(encoding="utf-8-sig")
    if module == "LOTM_RESCUE_Thief":
        exports = r'''
        API={recover=RecoverPotionCompletionFromProduction,copy=CopyProduction,
         digest=DigestBorrowedAbilities,process=ProcessThief,select=OnSelectAbility,
         potion=ApplyPotionProjectCompleted,complete=OnCityProjectCompleted,
         copyAbilities=LOTM_RESCUE_Thief.CopyThreeAbilities,found=LOTM_RESCUE_Thief.FoundTimeWormCity}
        function SpyInheritedEffects(keepProduction)
         GrantThiefPerTurn=function() stats.energy=(stats.energy or 0)+1 end
         EnsureSwindlerGold=function() end
         CopyGold=function() stats.gold=(stats.gold or 0)+1; return true end
         TriggerBoost=function() stats.boost=(stats.boost or 0)+1; return true end
         if not keepProduction then CopyProduction=function() stats.production=(stats.production or 0)+1; return true end end
         CopyKnowledge=function() stats.knowledge=(stats.knowledge or 0)+1; return true end
         LOTM_RESCUE_Thief.CopyThreeAbilities=function() end
        end
        function AbilityFixtures()
         CivPortableAbilities=function(civ)
          if civ=="CIV_3" then return {} end
          return {{TraitType="TRAIT_"..civ,Modifiers={"MOD_"..civ}}}
         end
         ApplySelectedSources=function(id,sources)
          stats.appliedSources=sources; stats.attached=stats.attached+#sources
          Players[id]:SetProperty("LOTM_RESCUE_THIEF_S2_ABILITIES","MOD_VALID")
          Players[id]:SetProperty("LOTM_RESCUE_THIEF_S2_TRAITS","TRAIT_VALID")
          return #sources,#sources
         end
        end
        rescue=true
        '''
    else:
        lua.execute("rescue=true")  # Suppress Initialize; tests drive actual callbacks.
        exports = r'''
        API={complete=ApplyCityProjectCompleted}
        CompleteFaithTransfer=function(id,all) stats.faith=(stats.faith or 0)+1; return true end
        ApplyTourismBurst=function(id,modifier,amount) stats.tourism=(stats.tourism or 0)+1; return true end
        rescue=false
        '''
    lua.execute(source + "\n" + exports + "\n" + extra_exports)
    return lua


class ThiefRuleGuards(unittest.TestCase):
    def test_cancel_switch_or_lost_city_never_complete_potion(self):
        lua = runtime("LOTM_RESCUE_Thief")
        lua.execute(r'''
        LOTM_RP_State.AdvanceSequence=function() error("queue disappearance is not a completion") end
        local potionRow={Index=7,ProjectType="PROJECT_LOTM_TP_SWINDLER_POTION"}
        GameInfo.Projects={PROJECT_LOTM_TP_SWINDLER_POTION=potionRow,[7]=potionRow}
        for _,active in ipairs({"","PROJECT_OTHER","PROJECT_LOTM_TP_CRYPTOLOGIST_POTION"}) do
         Players[0].props.LOTM_RESCUE_THIEF_LAST_ACTIVE_POTION="PROJECT_LOTM_TP_SWINDLER_POTION"
         Players[0].props.LOTM_WORLD_ACTIVE_POTION_PROJECTS=active
         API.recover(0)
         assert(Players[0].props.LOTM_RP_SEQUENCE==9)
         assert(Players[0].props.LOTM_RESCUE_THIEF_LAST_ACTIVE_POTION==nil)
         local writes=stats.writes; API.recover(0); assert(stats.writes==writes)
        end
        ''')

    def test_real_potion_completion_still_reaches_authoritative_gate(self):
        lua = runtime("LOTM_RESCUE_Thief")
        lua.execute(r'''
        GameInfo.Projects={[7]={Index=7,ProjectType="PROJECT_LOTM_TP_SWINDLER_POTION"}}
        local calls=0
        LOTM_RP_State.AdvanceSequence=function(id,from,to,allowWithoutChurch)
         calls=calls+1; assert(from==9 and to==8 and allowWithoutChurch==true)
         if stats.points<6 or Players[id].props.LOTM_RP_SEQUENCE~=from then return false end
         Players[id].props.LOTM_RP_SEQUENCE=to; return true
        end
        assert(API.potion(0,4,7,1)==false and calls==1)
        stats.points=6; assert(API.potion(0,4,7,1)==true and calls==2)
        assert(API.potion(0,4,7,1)==false and calls==2)
        Players[0].props.LOTM_RP_PATH="PATH_PERFECT"; assert(API.potion(0,4,7,1)==false)
        ''')

    def test_special_project_rewards_require_sequence_and_final_branch(self):
        lua = runtime("LOTM_TP_Thief")
        lua.execute(r'''
        for _,kind in ipairs({"FAITH","CULTURE"}) do
         for _,tier in ipairs({"","_II"}) do
          local name="PROJECT_LOTM_TP_"..kind.."_TRANSFER"..tier
          GameInfo.Projects={[7]={ProjectType=name}}
          for sequence=9,0,-1 do for _,branch in ipairs({"NONE","TECH_CIVIC","FAITH","CULTURE"}) do
           ResetStats(); Players[0].props.LOTM_RP_SEQUENCE=sequence
           Players[0].props.LOTM_TP_FINAL_BRANCH=branch
           API.complete(0,3,7,1)
           local permitted=tier=="" and sequence<=3 or tier=="_II" and sequence==0 and branch==kind
           local count=(stats.faith or 0)+(stats.tourism or 0)
           assert(count==(permitted and 1 or 0),name..":"..sequence..":"..branch)
          end end
         end
        end
        ''')

    def test_worm_found_command_rejects_wrong_unit_stale_pending_and_cooldown(self):
        lua = runtime("LOTM_RESCUE_Thief")
        lua.execute(r'''
        local worm={dead=false,delayed=false,kind=11}
        function worm:GetType() return self.kind end
        function worm:GetID() return 9 end
        function worm:GetOwner() return 0 end
        function worm:GetX() return 1 end
        function worm:GetY() return 2 end
        function worm:IsDead() return self.dead end
        function worm:IsDelayedDeath() return self.delayed end
        GameInfo.Units[11]={Index=11,UnitType="UNIT_LOTM_RESCUE_TIME_WORM"}
        GameInfo.Units[12]={Index=12,UnitType="UNIT_SCOUT"}
        GameInfo.Units.UNIT_LOTM_RESCUE_TIME_WORM=GameInfo.Units[11]
        Players[0].GetUnits=function() return {FindID=function(_,id) return id==9 and worm or nil end} end
        Map={GetPlot=function() return {GetIndex=function() return 12 end,
         GetX=function() return 1 end, GetY=function() return 2 end, IsCity=function() return false end} end}
        GameInfo.Units.UNIT_LOTM_RESCUE_CAMP_FOUNDER={Index=14}
        UnitOperationTypes={FOUND_CITY=2}
        UnitManager={InitUnit=function() stats.created=stats.created+1; return {GetID=function() return 90 end} end,
         Kill=function() end, CanStartOperation=function() return true end,
         RequestOperation=function() stats.nativeFound=stats.nativeFound+1; return true end}
        Players[0].props.LOTM_RP_SEQUENCE=1
        for _,id in ipairs({-1,0,9.5,"invalid"}) do assert(API.found(0,id,"SELF")==false) end
        assert(API.found(0,nil,"SELF")==false)
        worm.kind=12; assert(API.found(0,9,"SELF")==false); worm.kind=11
        worm.dead=true; assert(API.found(0,9,"SELF")==false); worm.dead=false
        worm.delayed=true; assert(API.found(0,9,"SELF")==false); worm.delayed=false
        Players[0].props.LOTM_RESCUE_TIME_WORM_FOUND_PENDING=1; assert(API.found(0,9,"SELF")==false)
        Players[0].props.LOTM_RESCUE_TIME_WORM_FOUND_PENDING=0
        Players[0].props.LOTM_RESCUE_TIME_WORM_COOLDOWN=turn+1; assert(API.found(0,9,"SELF")==false)
        Players[0].props.LOTM_RESCUE_TIME_WORM_COOLDOWN=turn
        assert(stats.nativeFound==0 and stats.created==0 and stats.writes==0)
        -- Success uses the full Gameplay city fixture in rc347/rc357.
        ''')

    def test_borrow_sources_fully_validate_before_writes(self):
        lua = runtime("LOTM_RESCUE_Thief")
        lua.execute(r'''
        AbilityFixtures(); Players[0].props.LOTM_RP_SEQUENCE=2
        setmetatable(Players,{__index=function(_,id) error("unused native player slot "..tostring(id)) end})
        for _,sources in ipairs({{0},{1,1},{20},{1,20},{1,"invalid"},{1,2,3,1},{1.5},{3}}) do
         assert(API.copyAbilities(0,sources)==false)
         assert(stats.writes==0 and stats.attached==0)
        end
        Players[0].props.LOTM_RP_SEQUENCE=3; assert(API.copyAbilities(0,{1})==false)
        Players[0].props.LOTM_RP_SEQUENCE=2
        Players[2].alive=false -- Existing UI allows a civilization that was previously alive.
        assert(API.copyAbilities(0,{1,2})==true and stats.attached==2)
        local writes=stats.writes; assert(API.copyAbilities(0,{1,2})==false and stats.writes==writes)
        ''')

    def test_s2_selection_and_six_active_turns_share_one_daily_point(self):
        lua = runtime("LOTM_RESCUE_Thief")
        lua.execute(r'''
        AbilityFixtures(); Players[0].props.LOTM_RP_SEQUENCE=2
        assert(API.digest(0)==false and stats.points==0)
        API.select(0,{SourcePlayerID1=1,SourcePlayerID2=2})
        assert(stats.points==1)
        for i=1,6 do
         turn=i; API.digest(0); API.digest(0)
         API.select(0,{SourcePlayerID1=1})
         assert(stats.points==i)
        end
        turn=7; API.digest(0); assert(stats.points==6)
        ResetStats(); Players[0].props.LOTM_RP_SEQUENCE=1
        assert(API.digest(0)==false and stats.points==0)
        Players[0].props.LOTM_RP_SEQUENCE=2
        Players[0].props.LOTM_RESCUE_THIEF_S2_ABILITIES=""
        assert(API.digest(0)==false and stats.points==0)
        ''')

    def test_inherited_effects_do_not_digest_a_different_sequence(self):
        lua = runtime("LOTM_RESCUE_Thief")
        lua.execute(r'''
        SpyInheritedEffects()
        for seq=9,0,-1 do
         ResetStats(); turn=turn+2
         Players[0].props.LOTM_RP_SEQUENCE=seq
         Players[0].props.LOTM_RESCUE_THIEF_S2_DONE=2
         Players[0].props.LOTM_RESCUE_THIEF_S2_ABILITIES="MOD_VALID"
         Players[0].props.LOTM_RESCUE_THIEF_S2_TRAITS="TRAIT_VALID"
         API.process(0)
         local expected=(seq>=5 or seq==2) and 1 or 0
         assert(stats.points==expected,"wrong digestion for Sequence "..seq)
         assert((stats.gold or 0)==(seq<=8 and 1 or 0))
         assert((stats.production or 0)==(seq<=6 and 1 or 0))
         assert((stats.knowledge or 0)==(seq<=5 and 1 or 0))
         local before=stats.points; API.process(0); assert(stats.points==before)
        end
        ''')

    def test_production_requires_active_sources_and_redeems_failed_buffer(self):
        lua = runtime("LOTM_RESCUE_Thief")
        lua.execute(r'''
        local mode="EMPTY"; local progress=0
        local queue={GetCurrentProductionTypeHash=function() return mode=="EMPTY" and 0 or 13 end}
        function queue:AddProgress(n)
         if mode=="ERROR" then error("native refusal") end
         if mode=="FALSE" then return false end
         progress=progress+n
        end
        Players[0].GetCities=function() return {GetCapitalCity=function() return {GetBuildQueue=function() return queue end} end} end
        local producing=true
        local cities={
         {GetYield=function() return 19.9 end,GetBuildQueue=function() return {GetCurrentProductionTypeHash=function() return producing and 7 or 0 end} end},
         {GetYield=function() return 1000 end,GetBuildQueue=function() return {GetCurrentProductionTypeHash=function() return 0 end} end}}
        Players[1].GetCities=function() return {Members=function() return ipairs(cities) end} end
        PlayerManager.GetAliveMajors=function() return {Players[0],Players[1]} end
        for _,failure in ipairs({"EMPTY","ERROR","FALSE"}) do
         mode=failure; local ok,amount=API.copy(0)
         assert(ok==false and amount==1 and progress==0)
        end
        assert(Players[0].props.LOTM_RESCUE_THIEF_PRODUCTION_BUFFER==3)
        producing=false; mode="GOOD"
        local ok,amount=API.copy(0)
        assert(ok==true and amount==0 and progress==3)
        assert(Players[0].props.LOTM_RESCUE_THIEF_PRODUCTION_BUFFER==0)
        assert(API.copy(0)==false and progress==3)
        Players[0].props.LOTM_RP_SEQUENCE=6; SpyInheritedEffects(true)
        producing=true; mode="FALSE"; API.process(0)
        assert(stats.points==0 and Players[0].props.LOTM_RESCUE_THIEF_PRODUCTION_BUFFER==1)
        turn=turn+1; mode="GOOD"; API.process(0)
        assert(stats.points==1 and progress==5 and Players[0].props.LOTM_RESCUE_THIEF_PRODUCTION_BUFFER==0)
        ''')


if __name__ == "__main__":
    unittest.main(verbosity=2)
