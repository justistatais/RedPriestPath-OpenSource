#!/usr/bin/env python3
"""Execute shared effects and real caller functions in Lua with native API mocks.

Requires lupa (Lua 5.4+). --baseline-root can point at the pre-refactor source
backup to additionally compare native writes, returns, balances and Properties.
These checks do not establish Civ VI or multiplayer runtime stability.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
try:
    from lupa import LuaRuntime
except ImportError:
    # The release workspace keeps its optional test runtime outside the mod.
    # Portable checkouts can install lupa normally; no runtime is bundled.
    sys.path.insert(0, str(ROOT.parent / ".tmp" / "refactor-rc340-python"))
    from lupa import LuaRuntime

CALLERS = (
    "LOTM_RP_Lifecycle", "LOTM_PP_Workshops", "LOTM_WORLD_Monsters",
    "LOTM_RESCUE_Phase10", "LOTM_RESCUE_DirectMonsters",
    "LOTM_RESCUE_Thief", "LOTM_TP_Thief",
)

MOCKS = r'''
local snapshots = {}
function Copy(value)
 local result = {}; for k,v in pairs(value or {}) do result[k] = v; end; return result;
end
function Snapshot(value)
 if type(value) ~= "table" then return tostring(value); end
 local keys = {}; for k in pairs(value) do keys[#keys+1] = k; end
 table.sort(keys, function(a,b) return tostring(a) < tostring(b); end)
 local result = {}; for _,k in ipairs(keys) do result[#result+1] = tostring(k).."="..Snapshot(value[k]); end
 return "{"..table.concat(result, ",").."}";
end
function Record(value) snapshots[#snapshots+1] = Snapshot(value); end
function Results() return table.concat(snapshots, "\n"), #snapshots; end
function MakeAbility(seed, refuse)
 local a = {counts=Copy(seed), writes={}};
 function a:GetAbilityCount(id) return self.counts[id]; end
 function a:ChangeAbilityCount(id, delta)
  self.writes[#self.writes+1] = {id, delta};
  if not refuse then self.counts[id] = (self.counts[id] or 0) + delta; end
 end
 return a;
end
function MakeUnit(ability, properties)
 local u = {ability=ability, properties=Copy(properties)};
 function u:GetAbility() return self.ability; end
 function u:GetProperty(key) return self.properties[key]; end
 function u:SetProperty(key,value) self.properties[key] = value; end
 function u:GetID() return 9; end
 function u:GetType() return 11; end
 function u:GetOwner() return 0; end
 return u;
end
function MakeTreasury(yield, balance, refusal)
 local t = {yield=yield, balance=balance, writes={}};
 function t:GetGoldYield() return self.yield; end
 function t:GetGoldBalance() return self.balance; end
 function t:ChangeGoldBalance(amount)
  self.writes[#self.writes+1] = amount;
  if refusal == "throw" then error("refused"); end
  if refusal ~= "silent" then self.balance = self.balance + amount; end
 end
 return t;
end
function Log(message) end
function Trace(message) end
function NumberValue(value) return tonumber(value); end
function N(value, default) return tonumber(value) or default; end
'''


def text(root: Path, module: str) -> str:
    return (root / "Scripts" / f"{module}.lua").read_text(encoding="utf-8-sig")


def clean(source: str) -> str:
    return re.sub(r"\s*:(?:boolean|number|string|table)\b", "", source)


def section(source: str, start: str, stop: str) -> str:
    return source[source.index(start):source.index(stop, source.index(start))]


def runtime() -> LuaRuntime:
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(text(ROOT, "LOTM_Effects"))
    lua.execute(MOCKS)
    return lua


def run_case(root: Path, module: str, start: str, stop: str,
             returned: str, setup: str, cases: str, constants: str = "") -> tuple[str, int]:
    lua = runtime()
    lua.execute(setup)
    source = text(root, module)
    function = lua.execute(clean(constants + "\n" + section(source, start, stop)
                                 + "\nreturn " + returned))
    lua.globals().Subject = function
    lua.execute(cases)
    return lua.eval("Results()")


def unit_ability_case(root: Path, module: str, name: str, stop: str,
                      missing_is_zero: bool) -> tuple[str, int]:
    return run_case(root, module, "local function " + name, stop, name,
        "GameInfo={UnitAbilities={KNOWN={}}};",
        f'''
        for _, initial in ipairs({{0,1,3,9}}) do
         for _, desired in ipairs({{0,1,4}}) do
          for _, refuse in ipairs({{false,true}}) do
           local a=MakeAbility({{KNOWN=initial}},refuse); local u=MakeUnit(a);
           local result=Subject(u,"KNOWN",desired);
           assert(result == (refuse and initial==desired or not refuse));
           local writes=#a.writes; assert(writes == (initial==desired and 0 or 1));
           if not refuse then Subject(u,"KNOWN",desired); assert(#a.writes==writes); end
           Record({{result,a.counts,a.writes}});
          end
         end
        end
        assert(Subject(nil,"KNOWN",1)==false);
        assert(Subject(MakeUnit(nil),"KNOWN",1)==false);
        local a=MakeAbility({{}}); local u=MakeUnit(a);
        assert(Subject(u,"MISSING",0)=={str(missing_is_zero).lower()});
        assert(Subject(u,"MISSING",1)==false); assert(#a.writes==0);
        Record({{a.counts,a.writes}});
        ''')


def caller_cases(root: Path) -> dict[str, tuple[str, int]]:
    results = {}
    for module in ("LOTM_WORLD_Monsters", "LOTM_RESCUE_DirectMonsters"):
        results[module] = unit_ability_case(root, module, "ApplyAbilityCount",
                                            "local function ApplyMonsterAbilities", True)
    results["LOTM_RESCUE_Phase10"] = unit_ability_case(root, "LOTM_RESCUE_Phase10",
        "SetAbilityCount", "local function BitAbility", False)

    results["normal_gold"] = run_case(root, "LOTM_TP_Thief", "local function TransferGold",
        "local function ApplyProgressBuffer", "TransferGold", "Game={};", r'''
        for _, network in ipairs({false,true}) do
         LOTM_MP_TurnSync={IsNetworkGame=function() return network; end};
         for _, sample in ipairs({{-4,9,0},{0,9,0},{1.99,9,0},{2,9,1},
            {3.99,9,1},{101,99,50},{101,2.75,2.75},{101,-4,0}}) do
          local source=MakeTreasury(sample[1],sample[2]); local recipient=MakeTreasury(0,10);
          local target={GetTreasury=function() return source; end};
          Players={[0]={GetTreasury=function() return recipient; end, GetCities=function() return nil; end}};
          assert(Subject(0,1,target)==sample[3]);
          assert(source.balance==sample[2]-sample[3]); assert(recipient.balance==10+sample[3]);
          Record({network,source.balance,source.writes,recipient.balance,recipient.writes});
         end
        end
        LOTM_MP_TurnSync={IsNetworkGame=function() return false; end};
        for _, refusal in ipairs({"throw","silent"}) do
         local source=MakeTreasury(100,200); local recipient=MakeTreasury(0,10,refusal);
         Players={[0]={GetTreasury=function() return recipient; end}};
         assert(Subject(0,1,{GetTreasury=function() return source; end})==0);
         assert(source.balance==200 and recipient.balance==10);
         Record({source.balance,recipient.balance,source.writes,recipient.writes});
        end
        assert(Subject(0,1,{GetTreasury=function() return nil; end})==0);
        ''')

    # Rescue copies the positive aggregate, including fractional source yields.
    results["rescue_gold"] = run_case(root, "LOTM_RESCUE_Thief", "local function CopyGold",
        "local function CopyProduction", "CopyGold", "", r'''
        for _, sample in ipairs({{{1,1},1},{{1.9,1.9},1},{{-100,5},2},{{0,0},0},{{11,20},15}}) do
         local recipient=MakeTreasury(0,10); local sources={};
         Players={[0]={GetTreasury=function() return recipient; end}};
         for _,yield in ipairs(sample[1]) do
          local t=MakeTreasury(yield,100); sources[#sources+1]={GetTreasury=function() return t; end};
         end
         GetOtherMajors=function() return sources; end;
         local ok,amount=Subject(0); assert(amount==sample[2] and ok==(amount>0));
         assert(recipient.balance==10+amount);
         for _,source in ipairs(sources) do assert(source:GetTreasury().balance==100); end
         Record({ok,amount,recipient.balance,recipient.writes});
        end
        ''')

    results["rescue_knowledge"] = rescue_knowledge_case(root)
    results["rescue_production"] = run_case(root, "LOTM_RESCUE_Thief",
        "local function CopyProduction", "-- Keep rescue knowledge", "CopyProduction",
        'P={ProductionBuffer="BUFFER"}; YieldTypes={PRODUCTION=1};', r'''
        for _,sample in ipairs({{{5,5},1},{{9.9,9.9},1},{{-99,20},2},{{0,0},0}}) do
         for _,mode in ipairs({"QUEUE","MISSING","REFUSED"}) do
          local queue={progress=0};
          function queue:GetCurrentProductionTypeHash() return 17; end
          function queue:AddProgress(amount) if mode=="REFUSED" then error("refused"); end; self.progress=self.progress+amount; end
          local cities={GetCapitalCity=function() if mode=="MISSING" then return nil; end; return {GetBuildQueue=function() return queue; end}; end};
          local player={properties={},GetCities=function() return cities; end};
          function player:GetProperty(key) return self.properties[key]; end
          function player:SetProperty(key,value) self.properties[key]=value; end
          Players={[0]=player}; local sourceCities={};
          for _,yield in ipairs(sample[1]) do sourceCities[#sourceCities+1]={GetYield=function() return yield; end,GetBuildQueue=function() return queue; end}; end
          GetOtherMajors=function() return {{GetCities=function() return {Members=function() return ipairs(sourceCities); end}; end}}; end;
          local ok,amount=Subject(0); assert(amount==sample[2] and ok==(amount>0 and mode=="QUEUE"));
          assert(queue.progress==(mode=="QUEUE" and amount or 0));
          assert((player.properties.BUFFER or 0)==(mode~="QUEUE" and amount or 0));
          Record({ok,amount,queue.progress,player.properties});
         end
        end
        ''')
    results["normal_knowledge"] = normal_knowledge_case(root)
    results["rescue_madness"] = run_case(root, "LOTM_RESCUE_Thief",
        "function LOTM_RESCUE_Thief.ApplyMadnessToUnit", "local function RefreshMadness",
        "LOTM_RESCUE_Thief.ApplyMadnessToUnit", r'''
        LOTM_RESCUE_Thief={}; P={Level="LEVEL_"}; GameInfo={UnitAbilities={}};
        Active=function() return true; end;
        IsOuterGod=function(u) return u:GetProperty("GOD")==1; end;
        ''', r'''
        for level=0,10 do
         Global=function() return level; end; local seed={};
         for i=1,10 do local id="LOTM_RESCUE_PURIFICATION_MADNESS_"..i*5; seed[id]=4; GameInfo.UnitAbilities[id]={}; end
         local a=MakeAbility(seed); local u=MakeUnit(a); assert(Subject(u)==true);
         for i=1,10 do assert(a.counts["LOTM_RESCUE_PURIFICATION_MADNESS_"..i*5]==(i==level and 1 or 0)); end
         local writes=#a.writes; Subject(u); assert(#a.writes==writes); Record({a.counts,a.writes});
        end
        local a=MakeAbility({}); assert(Subject(MakeUnit(a,{GOD=1}))==false); assert(#a.writes==0);
        Active=function() return false; end; assert(Subject(MakeUnit(a))==false); assert(#a.writes==0);
        Record(a.writes);
        ''')
    results["workshop_strength"] = workshop_case(root)
    results["war_aura"] = run_case(root, "LOTM_RP_Lifecycle", "local function RefreshWarAuraSource",
        "function LOTM_RP_State.EnsureHero", "RefreshWarAuraSource",
        'GameInfo={UnitPromotions={PROMOTION_LOTM_RP_COMBAT_3={Index=3}}}; IsHeroUnit=function(u) return u~=nil; end;',
        r'''
        for _, initial in ipairs({0,1,5}) do for _, promoted in ipairs({false,true}) do
         local a=MakeAbility({ABILITY_LOTM_RP_WAR_AURA_SOURCE_V2=initial}); local u=MakeUnit(a);
         u.GetExperience=function() return {HasPromotion=function() return promoted; end}; end;
         Subject(0,u); local writes=#a.writes; local props=Snapshot(u.properties);
         assert(a.counts.ABILITY_LOTM_RP_WAR_AURA_SOURCE_V2==(promoted and 1 or 0));
         Subject(0,u); assert(#a.writes==writes and Snapshot(u.properties)==props);
         Record({a.counts,a.writes,u.properties});
        end end
        ''')
    return results


def rescue_knowledge_case(root: Path) -> tuple[str, int]:
    setup = r'''
    P={KnowledgeBonusScience="SCI",KnowledgeBonusCulture="CUL",KnowledgeBonusFaith="FAI"};
    function SetKnowledgeYieldBonus(id,player,category,desired) player.bonuses[category]=desired; return true,0; end
    Game={GetCurrentGameTurn=function() return 1; end};
    '''
    return run_case(root, "LOTM_RESCUE_Thief", "local function CopyKnowledge", "local function TriggerBoost",
        "CopyKnowledge", setup, r'''
        for _,sample in ipairs({{{9,9},0},{{10,19},2},{{-100,25},2},{{100.9,109.9},20}}) do
         local player={bonuses={},properties={}};
         player.GetProperty=function(self,key) return self.properties[key]; end;
         player.SetProperty=function(self,key,value) self.properties[key]=value; end;
         Players={[0]=player}; local sources={};
         for _,yield in ipairs(sample[1]) do
          local object={GetScienceYield=function() return yield; end,GetCultureYield=function() return yield; end,GetFaithYield=function() return yield; end};
          sources[#sources+1]={GetTechs=function() return object; end,GetCulture=function() return object; end,GetReligion=function() return object; end};
         end
         GetOtherMajors=function() return sources; end;
         Subject(0);
         for _,category in ipairs({"SCIENCE","CULTURE","FAITH"}) do assert(player.bonuses[category]==sample[2]); end
         Record({player.bonuses,player.properties});
        end
        ''')


def normal_knowledge_case(root: Path) -> tuple[str, int]:
    return run_case(root, "LOTM_TP_Thief", "local function TransferKnowledgeAndFaith",
        "local function TriggerRandomBoost", "TransferKnowledgeAndFaith", r'''
        Game={GetCurrentGameTurn=function() return 4; end};
        P={LastKnowledgeSource="SOURCE",LastKnowledgeTurn="TURN",LastKnowledgeScience="SCI",
          LastKnowledgeCulture="CUL",LastKnowledgeFaith="FAI"};
        function ApplyProgressBuffer(player,kind) end
        function SetKnowledgeYieldBonus(id,player,category,desired)
         local old=player.bonuses[category] or 0; player.bonuses[category]=desired; return true,old;
        end
        function RestoreKnowledgeYieldBonus(id,player,category,old) player.bonuses[category]=old; end
        ''', r'''
        for _,sample in ipairs({{-10,100,0,0,0},{4.99,100,0,0,0},{5,100,1,1,1},
            {99,100,19,19,19},{101,2.75,2,20,2},{100,-3,0,20,0}}) do
         for _,refuse in ipairs({false,true}) do
          local player={properties={},bonuses={}};
          player.SetProperty=function(self,key,value) self.properties[key]=value; end;
          Players={[0]=player};
          local source={science=sample[2],culture=sample[2],faith=sample[2],writes={}};
          source.GetScienceYield=function() return sample[1]; end;
          source.GetCultureYield=source.GetScienceYield; source.GetFaithYield=source.GetScienceYield;
          source.GetResearchingTech=function() return 1; end; source.GetProgressingCivic=source.GetResearchingTech;
          source.GetResearchProgress=function(self) return self.science; end;
          source.GetFaithBalance=function(self) return self.faith; end;
          source.ChangeCurrentResearchProgress=function(self,delta)
           if refuse then error("refused"); end; self.science=self.science+delta; self.writes[#self.writes+1]={"SCI",delta};
          end;
          source.ChangeCurrentCulturalProgress=function(self,delta)
           if refuse then error("refused"); end; self.culture=self.culture+delta; self.writes[#self.writes+1]={"CUL",delta};
          end;
          source.ChangeFaithBalance=function(self,delta)
           if refuse then error("refused"); end; self.faith=self.faith+delta; self.writes[#self.writes+1]={"FAI",delta};
          end;
          local target={GetTechs=function() return source; end,GetCulture=function() return source; end,GetReligion=function() return source; end};
          local moved=Subject(0,1,target);
          assert(moved==(refuse and 0 or sample[3]+sample[4]+sample[5]));
          assert(source.science==sample[2]-(refuse and 0 or sample[3]));
          assert(source.culture==sample[2]-(refuse and 0 or sample[4]));
          assert(source.faith==sample[2]-(refuse and 0 or sample[5]));
          Record({moved,source.science,source.culture,source.faith,source.writes,player.properties,player.bonuses});
         end
        end
        ''')


def workshop_case(root: Path) -> tuple[str, int]:
    source = text(root, "LOTM_PP_Workshops")
    constants = section(source, 'local SEQUENCE_STRENGTH_ABILITY=', 'local SEQUENCE_NAMES=')
    constants += '\nlocal LEVEL="LOTM_PP_WORKSHOP_LEVEL"; local RESCUE_BONUS={[2]=15,[1]=25,[0]=35};\n'
    return run_case(root, "LOTM_PP_Workshops", "local function EnsureSequenceStrength",
        "local function ApplySequenceName", "EnsureSequenceStrength", r'''
        GameInfo={Units={[11]={Combat=20}},UnitAbilities={}};
        LOTM_WORLD_Barbarians={ResolveMeleeBaseline=function() return {Combat=20}; end};
        LOTM_RESCUE_Artifacts={ApplyMonsterWeather=function(unit) unit.weather=(unit.weather or 0)+1; end};
        ''', r'''
        local ids={"ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_STRENGTH","ABILITY_LOTM_WORLD_DYNAMIC_STRENGTH",
          "ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2","ABILITY_LOTM_WORLD_MONSTER_TIER_MID_STRENGTH",
          "ABILITY_LOTM_WORLD_MONSTER_TIER_HIGH_STRENGTH"};
        for _,value in ipairs({20,30,25,35,45,55,65,75,85,95}) do ids[#ids+1]="ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_"..value; end
        for _,value in ipairs({10,20,30,40}) do ids[#ids+1]="ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_"..value; end
        for _,rescue in ipairs({false,true}) do for _,level in ipairs({0,1,2}) do
         for _,baseline in ipairs({20,35,80}) do for _,period in ipairs({0,10,20,30,40}) do
          IsRescueMode=function() return rescue; end;
          local seed={}; for _,id in ipairs(ids) do seed[id]=3; GameInfo.UnitAbilities[id]={}; end
          local a=MakeAbility(seed); local unit=MakeUnit(a,{LOTM_PP_WORKSHOP_LEVEL=level,LOTM_RESCUE_PHASE5_BIRTH_BONUS=period});
          Subject(unit,baseline); local writes=#a.writes;
          assert(a.counts.ABILITY_LOTM_WORLD_DYNAMIC_STRENGTH==0);
          assert(a.counts.ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2==(rescue and 1 or 0));
          assert(a.counts.ABILITY_LOTM_WORLD_MONSTER_TIER_HIGH_STRENGTH==(rescue and level==0 and 1 or 0));
          assert(a.counts.ABILITY_LOTM_WORLD_MONSTER_TIER_MID_STRENGTH==(rescue and level==1 and 1 or 0));
          for _,value in ipairs({10,20,30,40}) do assert(a.counts["ABILITY_LOTM_RESCUE_PERIOD_STRENGTH_"..value]==(rescue and value==period and 1 or 0)); end
          Subject(unit,baseline); assert(#a.writes==writes);
          Record({a.counts,a.writes,unit.properties,unit.weather});
         end end
        end end
        IsRescueMode=function() return true; end; GameInfo.UnitAbilities={};
        local a=MakeAbility({ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2=4}); local u=MakeUnit(a);
        Subject(u,nil); assert(a.counts.ABILITY_LOTM_WORLD_MONSTER_FRENZY_STRENGTH_V2==4);
        Record({a.counts,a.writes,u.properties});
        local missing=MakeUnit(nil); Subject(missing,nil); assert(next(missing.properties)==nil);
        ''', constants)


def helper_cases() -> int:
    lua = runtime()
    return lua.execute(r'''
    local checks=0;
    for _,percent in ipairs({10,20,50}) do
     for n=-40,4000 do
      local base=n/7;
      assert(LOTM_Effects.PercentFloor(base,percent)==math.floor(math.max(0,base)*(percent/100)));
      checks=checks+1;
     end
    end
    assert(LOTM_Effects.PercentFloor(nil,50)==0);
    assert(LOTM_Effects.PercentFloor("11.9",50)==5);
    assert(LOTM_Effects.CappedPercentFloor(100,50,2.75)==2.75);
    assert(LOTM_Effects.CappedPercentFloor(100,50,-3)==0);
    local tiers={{0,"HIGH"},{1,"MID"},{2,"LOW"}};
    local a=MakeAbility({HIGH=5,MID=0,LOW=1,MISSING=7});
    local selected,count=LOTM_Effects.SyncAbilityTiers(a,tiers,0);
    assert(selected=="HIGH" and count==2 and a.counts.HIGH==1 and a.counts.LOW==0);
    local writes=#a.writes; selected,count=LOTM_Effects.SyncAbilityTiers(a,tiers,0);
    assert(selected=="HIGH" and count==0 and #a.writes==writes);
    selected,count=LOTM_Effects.SyncAbilityTiers(a,tiers,nil);
    assert(selected==nil and count==1 and a.counts.HIGH==0);
    a=MakeAbility({HIGH=4,MID=3,LOW=2});
    LOTM_Effects.SyncAbilityTiers(a,tiers,1,{HIGH={},MID={}});
    assert(a.counts.HIGH==0 and a.counts.MID==1 and a.counts.LOW==2);
    assert(a.writes[1][1]=="HIGH" and a.writes[2][1]=="MID");
    assert(LOTM_Effects.SetAbilityCount(nil,"HIGH",1)==false);
    return checks+10;
    ''')


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline-root", type=Path)
    args = parser.parse_args()
    syntax_lua = runtime()
    for module in (*CALLERS, "LOTM_Effects"):
        source = text(ROOT, module)
        syntax_lua.compile(clean(source))
        if module in CALLERS:
            assert 'include("LOTM_Effects")' in source, module
    checks = helper_cases()
    results = caller_cases(ROOT)
    if args.baseline_root:
        baseline = caller_cases(args.baseline_root)
        for name, outcome in results.items():
            assert outcome == baseline[name], f"behavior changed from baseline: {name}"
    scenarios = sum(count for _, count in results.values())
    print(f"PASS shared effects: {checks} arithmetic/helper checks, {scenarios} real-caller scenarios, "
          f"8 Lua files compiled; baseline equivalence={bool(args.baseline_root)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
