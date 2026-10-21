"""Task-sheet contracts in Lua 5.1 and a disposable native database copy.

No native game, save/reload, or dual-client acceptance is claimed here.
"""
from pathlib import Path
import os
import re
import sqlite3
import sys
import unittest
import zlib
import xml.etree.ElementTree as ET

from test_rc346_thief_rule_guards import LuaRuntime
from generate_gameplay_bundle import read_network_source
from generate_startup_trace import strip_trace

ROOT=Path(__file__).resolve().parents[1]
# Match the other database validators: --database on build_release supplies a
# preserved successful-load database when a native load failure has rolled the
# current cache back to core-only rows. Never restore/overwrite the game cache.
DB=(Path(sys.argv.pop(1)) if len(sys.argv)>1 and not sys.argv[1].startswith('-')
    else Path(os.environ['LOCALAPPDATA'])/"Firaxis Games/Sid Meier's Civilization VI/Cache/DebugGameplay.sqlite")

FIXTURE=r'''
function print() end
turn=10; network=false; rescue=false; configured='HARD'; gameprops={}; scans=0
Game={GetCurrentGameTurn=function() return turn end,
 GetProperty=function(k) if k=='LOTM_RESCUE_MODE' then return rescue and 1 or 0 end;return gameprops[k] end,
 SetProperty=function(k,v) gameprops[k]=v end}
GameConfiguration={GetValue=function() return configured end}
function EventBus() return setmetatable({}, {__index=function(t,k)
 local e={callbacks={}};e.Add=function(fn)e.callbacks[#e.callbacks+1]=fn end;
 e.Fire=function(...)for _,fn in ipairs(e.callbacks)do fn(...)end end;rawset(t,k,e);return e end})end
Events=EventBus();GameEvents=EventBus();turns={};startups={}
LOTM_MP_TurnSync={IsNetworkGame=function()return network end,
 IsRescueModeConfigured=function()return rescue end,
 IsStableAnchorPlayer=function(id)return id==0 end,
 Add=function(fn,key)turns[key]=fn end,
 RunStartup=function(fn,key)startups[key]=fn end}
function Rows(rows)
 local t={};for _,row in ipairs(rows)do if row.Index then t[row.Index]=row end;if row.UnitType then t[row.UnitType]=row end end
 return setmetatable(t,{__call=function()local i=0;return function()i=i+1;return rows[i]end end})
end
GameInfo={Modifiers=Rows({}),Units=Rows({
 {Index=10,UnitType='UNIT_WARRIOR',Combat=20,PromotionClass='PROMOTION_CLASS_MELEE'},
 {Index=11,UnitType='UNIT_MAN_AT_ARMS',Combat=45,PromotionClass='PROMOTION_CLASS_MELEE'},
 {Index=12,UnitType='UNIT_ARCHER',Combat=15,RangedCombat=25,PromotionClass='PROMOTION_CLASS_RANGED'},
 {Index=13,UnitType='UNIT_UNIQUE',Combat=50,PromotionClass='PROMOTION_CLASS_MELEE'},
 {Index=14,UnitType='UNIT_BUILDER',Combat=0}}),
 UnitReplaces=Rows({{CivUniqueUnitType='UNIT_UNIQUE',ReplacesUnitType='UNIT_MAN_AT_ARMS'}})}
function Player(id,human,path)
 local p={id=id,human=human,major=true,alive=true,props={LOTM_CULT_PATH=path},units={},gold=0,maintenance=80,attachments={},resources={}}
 function p:GetID()return self.id end
 function p:IsHuman()return self.human end
 function p:IsAlive()return self.alive end
 function p:IsMajor()return self.major end
 function p:GetProperty(k)return self.props[k]end
 function p:SetProperty(k,v)self.props[k]=v end
 function p:GetUnits()return {Members=function()
  scans=scans+1;local i=0;return function()i=i+1;if self.units[i]then return i,self.units[i]end end end}end
 function p:GetResources()return {GetResourceAmount=function(_,id)return self.resources[id]or 0 end,
  ChangeResourceAmount=function(_,id,v)self.resources[id]=(self.resources[id]or 0)+v end}end
 function p:AttachModifierByID(id)self.attachments[#self.attachments+1]=id end
 function p:GetTreasury()return {GetUnitMaintenance=function()return self.maintenance end,
  ChangeGoldBalance=function(_,v)self.gold=self.gold+v end}end
 return p
end
Players={[0]=Player(0,true,'DEMONESS'),[1]=Player(1,false,'DEMONESS'),
 [2]=Player(2,false,'HANGED_MAN'),[3]=Player(3,false,'CHAINED'),[4]=Player(4,false,'NONE')}
PlayerManager={GetAliveMajors=function()return {Players[3],Players[1],Players[0],Players[2],Players[4]}end}
tiers={DEMONESS=1,HANGED_MAN=1,CHAINED=1}
LOTM_AI_Cults={GetTier=function(c)return tiers[c]end,
 GetPlayerCult=function(id)return Players[id].props.LOTM_CULT_PATH end,
 GetTargetTier=function()return 2 end,GetMultiplier=function()return 1 end}
LOTM_WORLD_Barbarians={ResolveMeleeBaseline=function()return {Index=11,UnitType='UNIT_MAN_AT_ARMS',Combat=45}end}
LOTM_RP_State={IsAnyPathPlayer=function(id)return id==0 end}
Locale={Lookup=function(tag)return tag end}
function Unit(owner,id,typ,damage)
 local u={owner=owner,id=id,typ=typ,damage=damage or 20,dead=false,delayed=false,props={},abilities={},moves=2,attacks=1}
 function u:GetID()return self.id end
 function u:GetType()return self.typ end
 function u:GetProperty(k)return self.props[k]end
 function u:SetProperty(k,v)self.props[k]=v end
 function u:IsDead()return self.dead end
 function u:IsDelayedDeath()return self.delayed end
 function u:GetDamage()return self.damage end
 function u:ChangeDamage(v)self.damage=math.max(0,self.damage+v)end
 function u:GetAbility()return {GetAbilityCount=function(_,k)return self.abilities[k] or 0 end,
 ChangeAbilityCount=function(_,k,v)self.abilities[k]=(self.abilities[k]or 0)+v end}end
 function u:GetExperience()return {SetVeteranName=function(_,v)self.name=v end}end
 Players[owner].units[#Players[owner].units+1]=u;return u
end
UnitManager={GetUnit=function(owner,id)for _,u in ipairs(Players[owner].units)do if u.id==id then return u end end end}
function DropUnit(owner,id)local a={};for _,u in ipairs(Players[owner].units)do if u.id~=id then a[#a+1]=u end end;Players[owner].units=a end
'''

def runtime(module):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute(FIXTURE)
    lua.execute(strip_trace((ROOT/'Scripts'/f'{module}.lua').read_text(encoding='utf-8')))
    return lua

def native_copy():
    source=sqlite3.connect(DB.as_uri()+'?mode=ro',uri=True)
    c=sqlite3.connect(':memory:');source.backup(c);source.close()
    c.create_function('Make_Hash',1,lambda v:zlib.crc32(str(v).encode('utf-8')))
    c.executescript((ROOT/'Gameplay/LOTM_AI_Cult_Difficulty.sql').read_text(encoding='utf-8'))
    return c

def difficulty_runtime():
    lua=runtime('LOTM_AI_Cult_Difficulty')
    c=native_copy();ids=[r[0] for r in c.execute("select ModifierId from Modifiers where ModifierId like 'LOTM_CDIFF_%' order by ModifierId")]
    resources=[r[0] for r in c.execute("select ResourceType from Resources where ResourceType like 'RESOURCE_LOTM_CDIFF_%' order by ResourceType")]
    c.close()
    lua.execute('GameInfo.Modifiers=Rows({'+','.join('{ModifierId="'+i+'"}' for i in ids)+'})')
    lua.execute('GameInfo.Resources={'+','.join('["'+i+'"]={Index='+str(index)+'}' for index,i in enumerate(resources,1))+'}')
    return lua

class Balance(unittest.TestCase):
    def test_planned_war_1000_once_and_native_100_income(self):
        for network in [False,True]:
            lua=LuaRuntime(unpack_returned_tuples=True);lua.execute(FIXTURE)
            lua.execute("network="+str(network).lower()+r''';atwar=false;seq=6;
            LOTM_RP_State.IsEnabledPlayer=function(id)return id==0 end;
            LOTM_RP_State.GetSequence=function()return seq end;
            LOTM_RP_State.TryAddDigestion=function()end;
            PlayerManager.GetAliveMajorIDs=function()return {} end;
            Players[0].GetDiplomacy=function()return {IsAtWarWith=function()return atwar end}end;
            Players[0].props.LOTM_RP_PLAN_TARGET_ID=1;
            Players[0].props.LOTM_RP_PLAN_WAS_AT_WAR=0;
            ''')
            source=read_network_source('LOTM_RP_Advanced') if network else (ROOT/'Scripts/LOTM_RP_Advanced.lua').read_text(encoding='utf-8')
            source=re.sub(r'\s*:\s*(?:number|string|boolean|table)\b','',strip_trace(source))
            lua.execute(source+'\nwarProcess=ProcessPlannedWarEconomy')
            lua.execute('atwar=true;warProcess(0);warProcess(0)')
            self.assertEqual(lua.eval('Players[0].gold'),1000)
            self.assertEqual(lua.eval('Players[0].props.LOTM_RP_PLAN_GOLD_ACTIVE'),1)
            lua.execute('atwar=false;warProcess(0);atwar=true;warProcess(0)')
            self.assertEqual(lua.eval('Players[0].gold'),1000)
            lua.execute('atwar=false;warProcess(0)')
            self.assertEqual(lua.eval('Players[0].props.LOTM_RP_PLAN_GOLD_ACTIVE'),0)
            self.assertEqual(list(lua.eval('Players[0].attachments').values()),['LOTM_RP_MOD_PLAN_GOLD_PER_TURN_START','LOTM_RP_MOD_PLAN_GOLD_PER_TURN_STOP','LOTM_RP_MOD_PLAN_GOLD_PER_TURN_START','LOTM_RP_MOD_PLAN_GOLD_PER_TURN_STOP'])
        root=ET.parse(ROOT/'Gameplay/LOTM_RP_Modifiers.xml').getroot()
        values={r.get('ModifierId'):r.get('Value') for r in root.find('ModifierArguments') if r.get('Name')=='Amount'}
        self.assertEqual(values['LOTM_RP_MOD_PLAN_GOLD_PER_TURN_START'],'100')
        self.assertEqual(values['LOTM_RP_MOD_PLAN_GOLD_PER_TURN_STOP'],'-100')

    def test_provoker_original_full_heal_and_fortification_toggle(self):
        lua=LuaRuntime(unpack_returned_tuples=True);lua.execute(FIXTURE)
        lua.execute(r'''
        hero=Unit(0,1,10,60);fortify=1;
        function hero:GetOwner()return 0 end
        function hero:GetFortifyTurns()return fortify end
        GameInfo.Units.UNIT_LOTM_RP_PATH_HOLDER={Index=10};
        LOTM_RP_State.IsEnabledPlayer=function()return true end;
        LOTM_RP_State.GetSequence=function()return 8 end;
        LOTM_RP_State.FindHero=function()return hero end;
        ''')
        source=strip_trace((ROOT/'Scripts/LOTM_RP_Advanced.lua').read_text(encoding='utf-8'))
        source=re.sub(r'\s*:\s*(?:number|string|boolean|table)\b','',source)
        lua.execute(source+'\nprovokerProcess=ProcessProvokerGarrison')
        lua.execute('provokerProcess(0)')
        self.assertEqual(lua.eval('hero.damage'),0)
        self.assertEqual(lua.eval('hero.abilities.ABILITY_LOTM_RP_PROVOKER_GARRISONED'),1)
        lua.execute('fortify=0;hero.damage=50;provokerProcess(0)')
        self.assertEqual(lua.eval('hero.damage'),50)
        self.assertEqual(lua.eval('hero.abilities.ABILITY_LOTM_RP_PROVOKER_GARRISONED'),0)

    def test_normal_three_arguments_only(self):
        c=native_copy()
        # The native cache may already include rc390's normal override after
        # the user's game run. Establish its three original inputs explicitly;
        # the shared XML assertions below still pin the rescue baseline.
        original={'LOTM_RP_MOD_HUNTER_COMBAT':30,'LOTM_RP_MOD_PROVOKER_GARRISON_STRENGTH':40,'LOTM_RP_MOD_IRONBLOOD_FRIENDLY_STRENGTH_EFFECT_V2':30}
        c.executemany("update ModifierArguments set Value=? where ModifierId=? and Name='Amount'",[(str(value),mid) for mid,value in original.items()])
        before=c.execute('select ModifierId,Name,Value from ModifierArguments order by 1,2').fetchall()
        c.executescript((ROOT/'Gameplay/LOTM_NormalBalance.sql').read_text(encoding='utf-8'))
        after=c.execute('select ModifierId,Name,Value from ModifierArguments order by 1,2').fetchall()
        diff=[(a,b) for a,b in zip(before,after) if a!=b]
        self.assertEqual(len(diff),3)
        self.assertEqual({b[0]:int(b[2]) for a,b in diff},{'LOTM_RP_MOD_HUNTER_COMBAT':15,'LOTM_RP_MOD_PROVOKER_GARRISON_STRENGTH':20,'LOTM_RP_MOD_IRONBLOOD_FRIENDLY_STRENGTH_EFFECT_V2':20})
        # The shared rescue XML still contains its original numerical values.
        root=ET.parse(ROOT/'Gameplay/LOTM_RP_Abilities.xml').getroot()
        values={r.get('ModifierId'):r.get('Value') for r in root.find('ModifierArguments') if r.get('Name')=='Amount'}
        self.assertEqual(values['LOTM_RP_MOD_HUNTER_COMBAT'],'30')
        self.assertEqual(values['LOTM_RP_MOD_HUNTER_MOVEMENT'],'2')
        self.assertEqual(values['LOTM_RP_MOD_HUNTER_SIGHT'],'5')
        self.assertEqual(values['LOTM_RP_MOD_IRONBLOOD_FRIENDLY_MOVEMENT_EFFECT_V2'],'3')
        self.assertEqual(values['LOTM_RP_MOD_PROVOKER_GARRISON_STRENGTH'],'40')
        self.assertEqual(c.execute('pragma foreign_key_check').fetchall(),[]);c.close()

    def test_all_six_stage_packages(self):
        expected={'HARD':[(20,30,2,10,10,1,3,2),(40,60,4,20,20,2,5,3),(60,90,6,30,30,3,8,4)],
                  'INSANE':[(40,60,4,20,20,2,5,3),(80,120,7,35,40,3,8,5),(120,180,10,50,60,4,12,7)]}
        c=native_copy()
        def amount(mid):return int(c.execute("select Value from ModifierArguments where ModifierId=? and Name='Amount'",(mid,)).fetchone()[0])
        for difficulty,stages in expected.items():
            for tier,(s,e,combat,maint,food,amenity,heal,home) in enumerate(stages,1):
                lua=difficulty_runtime();lua.execute(f"configured='{difficulty}';tiers={{DEMONESS={tier},HANGED_MAN={tier},CHAINED={tier}}};LOTM_AI_Cult_Difficulty.Initialize();LOTM_AI_Cult_Difficulty.Register();LOTM_AI_Cult_Difficulty.Reconcile()")
                for y in ['SCIENCE','CULTURE','FAITH','PRODUCTION','GOLD']:
                    self.assertEqual(amount(f'LOTM_CDIFF_COMMON_{difficulty}_T{tier}_ON__{y}'),s if y in ['SCIENCE','CULTURE','FAITH'] else e)
                self.assertEqual(amount(f'LOTM_CDIFF_UNIT_COMMON_{difficulty}_T{tier}_ON'),combat)
                self.assertEqual(amount(f'LOTM_CDIFF_DEMONESS_{difficulty}_T{tier}_ON__FOOD'),food)
                self.assertEqual(amount(f'LOTM_CDIFF_DEMONESS_{difficulty}_T{tier}_ON__AMENITIES'),amenity)
                self.assertEqual(amount(f'LOTM_CDIFF_UNIT_CHAINED_{difficulty}_T{tier}_ON'),home)
                lua.execute('u=Unit(2,1,11,50);turns.AICultDifficulty(2,true)')
                self.assertEqual(lua.eval('u.damage'),50-heal)
                self.assertAlmostEqual(lua.eval('Players[2].gold'),80*maint/100)
                for id in [0,4]: self.assertEqual(lua.eval(f'#Players[{id}].attachments'),0)
        c.close()

    def test_lock_legacy_and_host_config(self):
        lua=difficulty_runtime();lua.execute('LOTM_AI_Cult_Difficulty.Initialize();configured="INSANE";LOTM_AI_Cult_Difficulty.Initialize()')
        self.assertEqual(lua.eval('gameprops.LOTM_CULT_DIFFICULTY'),'HARD')
        for marker in ['LOTM_CULT_STATE_VERSION','LOTM_CULT_ASSIGNMENTS_INITIALIZED']:
            lua=difficulty_runtime();lua.execute(f'configured="INSANE";gameprops.{marker}=4;LOTM_AI_Cult_Difficulty.Initialize();LOTM_AI_Cult_Difficulty.Reconcile()')
            self.assertEqual(lua.eval('gameprops.LOTM_CULT_DIFFICULTY'),'EASY')
            self.assertEqual(lua.eval('#Players[1].attachments'),0)
            self.assertEqual(lua.eval('Players[1].props.LOTM_CULT_PATH'),'DEMONESS')

    def test_stage_replacement_is_numerically_exclusive(self):
        lua=difficulty_runtime();lua.execute('configured="INSANE";LOTM_AI_Cult_Difficulty.Initialize();LOTM_AI_Cult_Difficulty.Reconcile();tiers={DEMONESS=2,HANGED_MAN=2,CHAINED=2};LOTM_AI_Cult_Difficulty.Reconcile();tiers={DEMONESS=3,HANGED_MAN=3,CHAINED=3};LOTM_AI_Cult_Difficulty.Reconcile();LOTM_AI_Cult_Difficulty.Reconcile()')
        c=native_copy()
        for id,cult in [(1,'DEMONESS'),(2,'HANGED_MAN'),(3,'CHAINED')]:
            counts={}
            for mid in lua.eval(f'Players[{id}].attachments').values():counts[mid]=counts.get(mid,0)+1
            for yield_name,expected in [('SCIENCE',120),('CULTURE',120),('FAITH',120),('PRODUCTION',180),('GOLD',180)]:
                total=0
                for mid,count in counts.items():
                    args=dict(c.execute('select Name,Value from ModifierArguments where ModifierId=?',(mid,)).fetchall())
                    resource=c.execute('select a.Value from Modifiers m join RequirementSetRequirements r on r.RequirementSetId=m.OwnerRequirementSetId join RequirementArguments a on a.RequirementId=r.RequirementId and a.Name="ResourceType" where m.ModifierId=?',(mid,)).fetchone()
                    active=resource and lua.eval(f'Players[{id}].resources[GameInfo.Resources["{resource[0]}"].Index]')==1
                    if active and args.get('YieldType')=='YIELD_'+yield_name:total+=int(args['Amount'])*count
                self.assertEqual(total,expected)
            self.assertEqual(lua.eval(f'Players[{id}].props.LOTM_CDIFF_APPLIED_COMMON'),'COMMON_INSANE_T3')
        c.close()

    def test_unique_cult_and_invalid_targets(self):
        lua=difficulty_runtime();lua.execute('LOTM_AI_Cult_Difficulty.Initialize();LOTM_AI_Cult_Difficulty.Reconcile();Players[1].props.LOTM_CULT_PATH="CHAINED";LOTM_AI_Cult_Difficulty.Reconcile()')
        self.assertEqual(lua.eval('Players[1].props.LOTM_CDIFF_APPLIED_DEMONESS'),'NONE')
        self.assertEqual(lua.eval('Players[1].props.LOTM_CDIFF_APPLIED_CHAINED'),'CHAINED_HARD_T1')
        for condition in ['Players[1].human=true','Players[1].major=false','Players[1].alive=false']:
            lua=difficulty_runtime();lua.execute(condition+';LOTM_AI_Cult_Difficulty.Initialize();LOTM_AI_Cult_Difficulty.Reconcile()')
            self.assertEqual(lua.eval('#Players[1].attachments'),0)

    def test_heal_once_health_cap_civilians_dead_and_maintenance(self):
        lua=difficulty_runtime();lua.execute('configured="INSANE";LOTM_AI_Cult_Difficulty.Initialize();LOTM_AI_Cult_Difficulty.Register();tiers.HANGED_MAN=3;u=Unit(2,1,11,5);b=Unit(2,2,14,20);d=Unit(2,3,11,100);d.dead=true;z=Unit(2,4,11,50);z.delayed=true;turns.AICultDifficulty(2,true);u.damage=20;turns.AICultDifficulty(2,true)')
        self.assertEqual(lua.eval('u.damage'),20)
        self.assertEqual(lua.eval('b.damage'),20)
        self.assertEqual(lua.eval('d.damage'),100)
        self.assertEqual(lua.eval('z.damage'),50)
        self.assertEqual(lua.eval('Players[2].gold'),40)
        self.assertEqual(lua.eval('u.moves'),2);self.assertEqual(lua.eval('u.attacks'),1)
        lua.execute('turn=11;Players[2].maintenance=-5;turns.AICultDifficulty(2,true)')
        self.assertEqual(lua.eval('Players[2].gold'),40)
        self.assertEqual(lua.eval('u.damage'),8)

    def test_rescue_never_locks_or_adds_bonus(self):
        lua=difficulty_runtime();lua.execute('rescue=true;LOTM_AI_Cult_Difficulty.Initialize();LOTM_AI_Cult_Difficulty.Register();LOTM_AI_Cult_Difficulty.Reconcile()')
        self.assertIsNone(lua.eval('gameprops.LOTM_CULT_DIFFICULTY'))
        self.assertEqual(lua.eval('#Players[1].attachments'),0)
        self.assertIsNone(lua.eval('turns.AICultDifficulty'))

    def test_current_plot_owner_requirement_and_military_filter(self):
        c=native_copy()
        self.assertEqual(c.execute("select RequirementType from Requirements where RequirementId='LOTM_CDIFF_REQ_OWN'").fetchone()[0],'REQUIREMENT_UNIT_IN_OWNER_TERRITORY')
        self.assertEqual(c.execute("select Value from RequirementArguments where RequirementId='LOTM_CDIFF_REQ_MILITARY_V2' and Name='Tag'").fetchone()[0],'CLASS_LOTM_CDIFF_MILITARY_V2')
        self.assertGreater(c.execute("select count(*) from TypeTags join Units on UnitType=Type where Tag='CLASS_LOTM_CDIFF_MILITARY_V2'").fetchone()[0],0)
        self.assertEqual(c.execute("select SubjectRequirementSetId from Modifiers where ModifierId='LOTM_CDIFF_UNIT_V2_CHAINED_INSANE_T3_ON'").fetchone()[0],'LOTM_CDIFF_REQSET_OWN')
        c.close()

class Puppets(unittest.TestCase):
    def test_before_object_exists_then_map_fallback(self):
        lua=runtime('LOTM_AI_Cult_Hanged');lua.execute('tiers.HANGED_MAN=2;GameEvents.UnitInitialized.Fire(2,1);u=Unit(2,1,11);Events.UnitAddedToMap.Fire(2,1)')
        self.assertIsNone(lua.eval('u.props.LOTM_CULT_SOURCE_CULT'))
        lua.execute('turns.AICultHanged(2,true)')
        self.assertEqual(lua.eval('u.props.LOTM_CULT_SOURCE_CULT'),'HANGED_MAN')
        self.assertEqual(lua.eval('u.abilities.ABILITY_LOTM_CULT_FLESH_PUPPET_10'),1)

    def test_migration_once_and_tier_replaces_without_scan(self):
        lua=runtime('LOTM_AI_Cult_Hanged');lua.execute('tiers.HANGED_MAN=2;u=Unit(2,1,11);r=Unit(2,2,12);LOTM_AI_Cult_Hanged.ReconcileAll();initialScans=scans;LOTM_AI_Cult_Hanged.ReconcileAll();tiers.HANGED_MAN=3;LOTM_AI_Cult_Hanged.ReconcileAll()')
        self.assertEqual(lua.eval('scans'),lua.eval('initialScans'))
        self.assertEqual(lua.eval('u.abilities.ABILITY_LOTM_CULT_FLESH_PUPPET_10'),0)
        self.assertEqual(lua.eval('u.abilities.ABILITY_LOTM_CULT_FLESH_PUPPET_20'),1)
        self.assertIsNone(lua.eval('r.props.LOTM_CULT_SOURCE_CULT'))

    def test_tier_one_existing_units_not_mass_converted_on_tier_two(self):
        lua=runtime('LOTM_AI_Cult_Hanged');lua.execute('u=Unit(2,1,11);LOTM_AI_Cult_Hanged.ReconcileAll();tiers.HANGED_MAN=2;LOTM_AI_Cult_Hanged.ReconcileAll()')
        self.assertIsNone(lua.eval('u.props.LOTM_CULT_SOURCE_CULT'))

    def test_unique_replacement_duplicate_and_other_unit_types(self):
        lua=runtime('LOTM_AI_Cult_Hanged');lua.execute('tiers.HANGED_MAN=2;u=Unit(2,1,13);h=Unit(0,1,11);old=Unit(2,2,10);r=Unit(2,3,12);GameEvents.UnitInitialized.Fire(2,1);GameEvents.UnitInitialized.Fire(2,1);GameEvents.UnitInitialized.Fire(0,1);GameEvents.UnitInitialized.Fire(2,2);GameEvents.UnitInitialized.Fire(2,3)')
        self.assertEqual(lua.eval('u.abilities.ABILITY_LOTM_CULT_FLESH_PUPPET_10'),1)
        for name in ['h','old','r']:self.assertIsNone(lua.eval(name+'.props.LOTM_CULT_SOURCE_CULT'))

    def test_network_stable_turn_and_removed_candidate(self):
        lua=runtime('LOTM_AI_Cult_Hanged');lua.execute('network=true;tiers.HANGED_MAN=2;u=Unit(2,1,11);GameEvents.UnitInitialized.Fire(2,1);turns.AICultHanged(0,true);turn=11;turns.AICultHanged(2,true)')
        self.assertIsNone(lua.eval('u.props.LOTM_CULT_SOURCE_CULT'))
        lua.execute('turns.AICultHanged(0,true)')
        self.assertEqual(lua.eval('u.props.LOTM_CULT_SOURCE_CULT'),'HANGED_MAN')
        lua.execute('v=Unit(2,2,11);GameEvents.UnitInitialized.Fire(2,2);Events.UnitRemovedFromMap.Fire(2,2);DropUnit(2,2);turn=12;turns.AICultHanged(0,true)')
        self.assertIsNone(lua.eval('v.props.LOTM_CULT_SOURCE_CULT'))

    def test_same_turn_reload_maintenance_heal_receipts_and_puppet_index(self):
        lua=difficulty_runtime();lua.execute('LOTM_AI_Cult_Difficulty.Initialize();LOTM_AI_Cult_Difficulty.Register();u=Unit(2,1,11,40);turns.AICultDifficulty(2,true)')
        source=(ROOT/'Scripts/LOTM_AI_Cult_Difficulty.lua').read_text(encoding='utf-8')
        lua.execute(source);lua.execute('LOTM_AI_Cult_Difficulty.Register();turns.AICultDifficulty(2,true)')
        self.assertEqual(lua.eval('Players[2].gold'),8)
        self.assertEqual(lua.eval('u.damage'),37)
        lua.execute(strip_trace((ROOT/'Scripts/LOTM_AI_Cult_Hanged.lua').read_text(encoding='utf-8')))
        lua.execute('tiers.HANGED_MAN=2;LOTM_AI_Cult_Hanged.ReconcileAll();initialScans=scans')
        lua.execute(strip_trace((ROOT/'Scripts/LOTM_AI_Cult_Hanged.lua').read_text(encoding='utf-8')))
        lua.execute('LOTM_AI_Cult_Hanged.ReconcileAll()')
        self.assertEqual(lua.eval('scans'),lua.eval('initialScans'))

class Packaging(unittest.TestCase):
    def test_normal_criteria_language_lock_and_shared_rescue(self):
        m=ET.parse(ROOT/'RedPriestPath.modinfo').getroot()
        self.assertEqual(m.find("InGameActions/UpdateDatabase[@id='LOTM_NORMAL_BALANCE_DATABASE']").get('criteria'),'LOTM_RP_NORMAL_MODE')
        c=ET.parse(ROOT/'Config/LOTM_RP_PathSelection.xml').getroot()
        row=c.find("Parameters/Row[@ParameterId='LOTM_CULT_DIFFICULTY']")
        self.assertEqual(row.get('DefaultValue'),'EASY');self.assertEqual(row.get('ConfigurationGroup'),'Game');self.assertEqual(row.get('ChangeableAfterGameStart'),'0')
        texts=[]
        for lang in ['zh_Hans_CN','en_US']:
            rows={r.get('Tag'):r.findtext('Text') for r in ET.parse(ROOT/'Text/Selected'/f'LOTM_NormalBalance_{lang}.xml').getroot().iter('Replace')}
            self.assertFalse(any('ARTIFACT' in t or 'RESCUE' in t for t in rows))
            self.assertNotIn('2000',rows['LOC_LOTM_RP_DETAILS_EFFECTS_S6'])
            self.assertIn('+15',rows['LOC_LOTM_RP_DETAILS_EFFECTS_S9'])
            self.assertIn('+20',rows['LOC_LOTM_RP_DETAILS_EFFECTS_S4'])
            self.assertIn('+3',rows['LOC_LOTM_RP_DETAILS_EFFECTS_S4'])
            texts.append(set(rows))
        self.assertEqual(*texts)
        hanged=read_network_source('LOTM_AI_Cult_Hanged')
        self.assertIn('if not LOTM_MP_TurnSync.IsRescueModeConfigured() then',hanged)
        self.assertIn('and 2000 or 1000',read_network_source('LOTM_RP_Advanced'))

if __name__=='__main__':unittest.main(verbosity=2)
