"""Real Lua 5.1 event/command regression tests; not an in-game acceptance."""
from pathlib import Path
import os
import zlib
import re
import sqlite3
import sys
import unittest
import xml.etree.ElementTree as ET
import zipfile

from test_rc348_camp_artifacts import runtime as camp_runtime
from test_rc348_barbarian_spawn import runtime as barbarian_runtime, LuaRuntime
from generate_startup_trace import strip_trace

ROOT=Path(__file__).resolve().parents[1]
DATABASE=Path(sys.argv.pop(1)) if len(sys.argv)>1 and not sys.argv[1].startswith('-') else Path(os.environ['LOCALAPPDATA'])/'Firaxis Games/Sid Meier\'s Civilization VI/Cache/DebugGameplay.sqlite'
# A shared selected snapshot survives positional-argument consumption by imported fixtures.
if os.environ.get("LOTM_TEST_GAMEPLAY_DATABASE"):
    DATABASE=Path(os.environ["LOTM_TEST_GAMEPLAY_DATABASE"])
SOURCE=(ROOT/'Scripts/LOTM_RESCUE_RuntimeEvents.lua').read_text(encoding='utf-8')
SEAL='ABILITY_LOTM_RESCUE_EARLY_SEAL'
SETUP=r'''
function include() end
handlers={}; startups={}; synchronized={}
GameEvents=setmetatable({}, {__index=function(t,k) local event={Add=function(fn) handlers[k]=fn end}; rawset(t,k,event); return event end})
LOTM_MP_TurnSync.AddSynchronized=function(fn) synchronized[#synchronized+1]=fn end
LOTM_MP_TurnSync.RunStartup=function(fn) startups[#startups+1]=fn end
LOTM_MP_TurnSync.IsStableAnchorPlayer=function(id) return id==0 end
'''

def cleanup_runtime():
    lua=barbarian_runtime()
    lua.execute(SETUP+r'''
    GameConfiguration={GetStartTurn=function() return startTurn or 1 end}
    props.LOTM_RESCUE_MODE=1
    GameInfo.UnitAbilities={ABILITY_LOTM_RESCUE_EARLY_SEAL={}}
    PlayerManager.GetAliveMajors=function() return {Players[0]} end
    Players[0].IsHuman=function() return true end
    ''')
    lua.execute((ROOT/'Scripts/LOTM_Effects.lua').read_text(encoding='utf-8'))
    lua.execute(SOURCE)
    lua.execute(r'''
    function Monster(id)
     local u=Unit(id,1,{LOTM_WORLD_MONSTER_SERIAL=id,V=7})
     u.abilities={WEATHER=1,MADNESS=3}; u.writes=0
     function u:GetAbility()
      local a={}
      function a:GetAbilityCount(k) return u.abilities[k] or 0 end
      function a:ChangeAbilityCount(k,v) u.writes=u.writes+1; u.abilities[k]=(u.abilities[k] or 0)+v end
      return a
     end
     function u:SetProperty(k,v) self.props[k]=v end
     return u
    end
    function Cleanup(csv,id) handlers.LOTM_RESCUE_Command_NativeCleanup(id or 0,{Units=csv}) end
    function Seal(u) return LOTM_RESCUE_RuntimeEvents.ApplyEarlySeal(u) end
    function SealTurn() for _,fn in ipairs(synchronized) do fn(0) end end
    ''')
    return lua

def reward_runtime():
    lua=camp_runtime()
    lua.execute(SETUP)
    lua.execute(SOURCE)
    lua.execute(r'''
    properties.LOTM_RESCUE_MODE=1
    PlayerManager.GetAliveMajors=function() return {Players[0],Players[1],Players[2]} end
    function Resolve(index,epoch,id) handlers.LOTM_RESCUE_Command_CampRemoved(id or 0,{PlotIndex=index or 3885,CampEpoch=epoch or 1}) end
    ''')
    return lua

class RewardCommands(unittest.TestCase):
    def test_five_different_camps_each_reward_and_late_local_queue_is_noop(self):
        lua=reward_runtime()
        lua.execute(r'''
        saved={}; local template=plot
        Map.GetPlotByIndex=function(index) return saved[index] end
        for i=1,5 do
         local p={}; for k,v in pairs(template) do p[k]=v end
         p.number=1000+i; p.GetIndex=function(self) return self.number end
         p.props={LOTM_PP_WORKSHOP_CLASSIFIED=1,LOTM_PP_WORKSHOP_IS_WORKSHOP=1,
          LOTM_PP_WORKSHOP_CAMP_EPOCH=1,LOTM_RESCUE_WORKSHOP_CLASSIFIED_TURN=turn}
         plot=p; saved[p.number]=p
         Receipt(0,100); Remove(); Resolve(p.number,1); Resolve(p.number,1)
        end
        turn=8; Boundary()
        ''')
        self.assertEqual(lua.eval('#grants'),5)

    def test_same_turn_settlement_and_legacy_queue_no_double_grant(self):
        lua=reward_runtime()
        lua.execute('Receipt(0,100); Remove(); Resolve(); turn=7; Boundary(); turn=8; Boundary()')
        self.assertEqual(lua.eval('#grants'),1)
        self.assertEqual(lua.eval('grants[1].owner'),0)

    def test_multiple_camps_and_new_generation_every_time(self):
        lua=reward_runtime()
        lua.execute(r'''
        for epoch=1,5 do
         plot.props={LOTM_PP_WORKSHOP_CLASSIFIED=1,LOTM_PP_WORKSHOP_IS_WORKSHOP=1,
          LOTM_PP_WORKSHOP_CAMP_EPOCH=epoch,LOTM_RESCUE_WORKSHOP_CLASSIFIED_TURN=turn}
         Receipt(0,100); Remove(); Resolve(3885,epoch); Resolve(3885,epoch)
         turn=turn+1; Boundary()
        end
        ''')
        self.assertEqual(lua.eval('#grants'),5)

    def test_native_movement_after_improvement_disappears_keeps_clearer(self):
        lua=reward_runtime()
        lua.execute('u=Unit(0,100); plot.improvement=-1; API.move(0,100); occupancy={}; Remove(); Resolve()')
        self.assertEqual(lua.eval('#grants'),1)

    def test_commands_validate_mode_sender_camp_and_generation(self):
        for setup,call in [('properties.LOTM_RESCUE_MODE=0','Resolve()'),('','Resolve(3885,2)'),('plot.improvement=7','Resolve()'),('','Resolve(3885,1,2)')]:
            lua=reward_runtime(); lua.execute('; '.join(s for s in ('Receipt(0,100)',setup,call) if s))
            self.assertEqual(lua.eval('#grants'),0)

    def test_unknown_clearer_is_not_invented(self):
        lua=reward_runtime(); lua.execute('occupancy={}; Remove(); Resolve()')
        self.assertEqual(lua.eval('#grants'),0)

    def test_failure_keeps_retry_and_repeated_command_does_not_duplicate(self):
        lua=reward_runtime(); lua.execute('Receipt(0,100); Remove(); grantResult=false; Resolve()')
        self.assertEqual(lua.eval('plot.props.LOTM_PP_WORKSHOP_MP_PENDING'),1)
        lua.execute('grantResult=true; Resolve(); Resolve(); turn=8; Boundary()')
        self.assertEqual(lua.eval('#grants'),1)

    def test_peer_local_occupancy_is_not_command_authority(self):
        results=[]
        for local_visible in (False,True):
            lua=reward_runtime()
            lua.execute('u=Unit(0,100); occupancy='+('{u}' if local_visible else '{}')+'; Remove(); occupancy={u}; Resolve()')
            results.append((lua.eval('#grants'),lua.eval('grants[1].owner')))
        self.assertEqual(results,[(1,0),(1,0)])

class NativeCommands(unittest.TestCase):
    def test_every_birth_processed_same_turn_without_turn_advance(self):
        lua=cleanup_runtime()
        lua.execute("for id=1,5 do Unit(id); Cleanup('63:'..id); assert(live[id]==nil) end")
        self.assertEqual(lua.eval('#killed'),5)
        self.assertEqual(lua.eval('scanCount'),0)

    def test_current_monster_and_god_identity_protected(self):
        lua=cleanup_runtime()
        lua.execute("Monster(1); Unit(2,5); Unit(3,6); Cleanup('63:1,63:2,63:3'); assert(live[1] and live[2] and live[3])")
        self.assertEqual(lua.eval('#killed'),0)

    def test_failure_duplicate_and_reused_id_revalidate(self):
        lua=cleanup_runtime()
        lua.execute("Unit(1); killFalse=true; Cleanup('63:1'); assert(live[1]); killFalse=false; Cleanup('63:1'); Cleanup('63:1'); Monster(1); Cleanup('63:1'); assert(live[1])")
        self.assertEqual(lua.eval('#killed'),1)

    def test_nonbarbarian_mode_and_sender_cannot_kill(self):
        for setup,call in [("Unit(1,1,nil,0)","Cleanup('0:1')"),("Unit(1); props.LOTM_RESCUE_MODE=0","Cleanup('63:1')"),("Unit(1)","Cleanup('63:1',99)")]:
            lua=cleanup_runtime(); lua.execute(setup+'; '+call)
            self.assertEqual(lua.eval('#killed'),0)

class EarlySeal(unittest.TestCase):
    def test_turns_1_20_inclusive_then_remove_21_and_late_birth(self):
        lua=cleanup_runtime()
        lua.execute("u=Monster(1); for _,t in ipairs({1,19,20}) do turn=t; Seal(u); assert(u.abilities['"+SEAL+"']==1) end; turn=21; Seal(u); assert(u.abilities['"+SEAL+"']==0); v=Monster(2); Seal(v); assert((v.abilities['"+SEAL+"'] or 0)==0)")

    def test_no_stacking_and_other_modifiers_preserved(self):
        lua=cleanup_runtime(); lua.execute('u=Monster(1); for i=1,50 do Seal(u) end')
        self.assertEqual(lua.eval('u.writes'),1)
        self.assertEqual(lua.eval('u.abilities.WEATHER'),1)
        self.assertEqual(lua.eval('u.abilities.MADNESS'),3)

    def test_world_turn_uses_start_turn_and_isolates_ordinary_mode(self):
        lua=cleanup_runtime(); lua.execute('startTurn=200; turn=219; u=Monster(1); Seal(u)')
        self.assertEqual(lua.eval('u.abilities["'+SEAL+'"]'),1)
        lua.execute('turn=220; Seal(u)')
        self.assertEqual(lua.eval('u.abilities["'+SEAL+'"]'),0)
        lua.execute('props.LOTM_RESCUE_MODE=0; turn=200; Seal(u)')
        self.assertEqual(lua.eval('u.abilities["'+SEAL+'"]'),0)

    def test_gods_and_unmarked_units_excluded(self):
        lua=cleanup_runtime(); lua.execute('u=Monster(1); u.kind=5; Seal(u); v=Monster(2); v.props.LOTM_RESCUE_PHASE10_ROLE="MINION"; Seal(v); w=Monster(3); w.props.LOTM_WORLD_MONSTER_SERIAL=nil; Seal(w)')
        self.assertEqual(lua.eval('u.writes+v.writes+w.writes'),0)

    def test_migration_once_then_threshold_uses_active_index(self):
        lua=cleanup_runtime()
        lua.execute('u=Monster(1); turn=20; SealTurn(); before=scanCount; for i=1,50 do SealTurn() end; assert(scanCount==before); props.LOTM_WORLD_MONSTER_ACTIVE_SERIALS="1"; props["LOTM_WORLD_MONSTER:1:LIVE"]=1; props["LOTM_WORLD_MONSTER:1:OWNER"]=63; props["LOTM_WORLD_MONSTER:1:UNIT_ID"]=1; turn=21; SealTurn(); assert(scanCount==before)')
        self.assertEqual(lua.eval('u.abilities["'+SEAL+'"]'),0)

    def test_both_spawn_callers_only_add_seal_hook_against_fixed_rc348(self):
        with zipfile.ZipFile(ROOT.parent/'dist/RedPriestPath-0.1.0-rc.348.zip') as z:
            for module in ('LOTM_WORLD_Monsters','LOTM_RESCUE_DirectMonsters'):
                name='Scripts/'+module+'.lua'
                old=z.read('RedPriestPath/'+name).decode('utf-8').replace('\r\n','\n')
                current=(ROOT/name).read_text(encoding='utf-8')
                restored=re.sub(r'^\s*if LOTM_RESCUE_RuntimeEvents~=nil then LOTM_RESCUE_RuntimeEvents.ApplyEarlySeal\(unit\); end\n','',current,flags=re.M)
                self.assertEqual(restored,old)

class DatabaseAndRegistration(unittest.TestCase):
    def test_sql_reversible_ability_combat_minus10_and_rescue_criteria(self):
        db=sqlite3.connect(':memory:')
        db.create_function('Make_Hash',1,lambda text:zlib.crc32(str(text).encode('utf-8')))
        with sqlite3.connect(f'file:{DATABASE.as_posix()}?mode=ro',uri=True) as original: original.backup(db)
        sql=(ROOT/'Gameplay/LOTM_RESCUE_Phase5.sql').read_text(encoding='utf-8')
        db.executescript(sql); db.executescript(sql)
        self.assertEqual(db.execute("select Value from ModifierArguments where ModifierId='LOTM_RESCUE_EARLY_SEAL_COMBAT' and Name='Amount'").fetchone()[0],'-10')
        self.assertEqual(db.execute('select Inactive from UnitAbilities where UnitAbilityType=?',(SEAL,)).fetchone()[0],1)
        self.assertEqual(db.execute("select Text from ModifierStrings where ModifierId='LOTM_RESCUE_EARLY_SEAL_COMBAT'").fetchone()[0],'LOC_LOTM_RESCUE_EARLY_SEAL_PREVIEW')
        self.assertEqual(db.execute('pragma foreign_key_check').fetchall(),[])
        mod=ET.parse(ROOT/'RedPriestPath.modinfo').getroot()
        for suffix in ('RUNTIME_EVENTS_UI_FILES','RUNTIME_EVENTS_UI_ADDIN'):
            action=mod.find(f".//*[@id='LOTM_RESCUE_{suffix}']")
            self.assertEqual(action.get('criteria'),'LOTM_RP_RESCUE_MODE')

UI_FIXTURE=r'''
properties={LOTM_RESCUE_MODE=1,LOTM_RESCUE_RUNTIME_EVENTS_READY=1}; active=true; localID=0; commands={}; requests=0
turn=6
Game={GetProperty=function(k) return properties[k] end,GetLocalPlayer=function() return localID end,GetCurrentGameTurn=function() return turn end}
local player={GetID=function() return 0 end,IsHuman=function() return true end,IsTurnActive=function() return active end}
PlayerManager={GetAliveMajors=function() return {player} end}
ContextPtr={SetRefreshHandler=function(_,fn) refresh=fn end,RequestRefresh=function() requests=requests+1 end}
events={}; Events=setmetatable({}, {__index=function(t,k) local event={Add=function(fn) events[k]=fn end}; rawset(t,k,event); return event end})
PlayerOperations={EXECUTE_SCRIPT=1}; UI={RequestPlayerOperation=function(id,op,params) commands[#commands+1]=params; return accepted end}
plot={GetIndex=function() return 88 end,GetProperty=function(_,k) if k=='LOTM_PP_WORKSHOP_CAMP_EPOCH' then return epoch or 1 elseif k=='LOTM_PP_WORKSHOP_CLASSIFIED' then return 1 end end}
Map={GetPlot=function() return plot end,GetPlotByIndex=function() return plot end}
function print() end
'''

class UICommands(unittest.TestCase):
    def runtime(self):
        lua=LuaRuntime(unpack_returned_tuples=True); lua.execute(UI_FIXTURE)
        lua.execute(strip_trace((ROOT/'UI/LOTM_RESCUE_RuntimeEvents.lua').read_text(encoding='utf-8')))
        return lua

    def test_each_new_batch_and_camp_sends_without_game_turn_delay(self):
        lua=self.runtime(); lua.execute('for i=1,5 do events.UnitAddedToMap(63,i); events.GameCoreEventPublishComplete(); events.ImprovementRemovedFromMap(1,2); events.GameCoreEventPublishComplete() end')
        self.assertEqual(lua.eval('#commands'),10)

    def test_batches_64_dedup_and_no_empty_publication_polling(self):
        lua=self.runtime(); lua.execute('for i=1,130 do events.UnitAddedToMap(63,i); events.UnitAddedToMap(63,i) end; events.GameCoreEventPublishComplete(); n=requests; for i=1,1000 do events.GameCoreEventPublishComplete() end; assert(requests==n)')
        self.assertEqual(lua.eval('#commands'),3)

    def test_not_ready_or_not_active_defers_until_allowed_event(self):
        lua=self.runtime(); lua.execute('active=false; events.UnitAddedToMap(63,1); events.GameCoreEventPublishComplete(); assert(#commands==0); active=true; properties.LOTM_RESCUE_RUNTIME_EVENTS_READY=0; events.GameCoreEventPublishComplete(); assert(#commands==0); properties.LOTM_RESCUE_RUNTIME_EVENTS_READY=1; events.PlayerTurnActivated()')
        self.assertEqual(lua.eval('#commands'),1)

    def test_rejected_request_retries_and_ordinary_mode_sends_nothing(self):
        lua=self.runtime(); lua.execute('accepted=false; events.UnitAddedToMap(63,1); events.GameCoreEventPublishComplete(); accepted=true; for i=1,1000 do events.GameCoreEventPublishComplete() end; assert(#commands==1); turn=7; events.GameCoreEventPublishComplete(); n=#commands; properties.LOTM_RESCUE_MODE=0; events.UnitAddedToMap(63,2); events.GameCoreEventPublishComplete(); assert(#commands==n)')
        self.assertEqual(lua.eval('#commands'),2)

if __name__=='__main__': unittest.main(verbosity=2)
