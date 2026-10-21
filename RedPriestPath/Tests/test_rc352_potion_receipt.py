"""Native completion marker plus real Lua reconciliation/command tests.

rc354 replaces the ineffective resource receipt with ProjectCompletionModifiers.
The prior cancellation, validation and duplicate-completion boundaries remain.
"""
from pathlib import Path
import os,sqlite3,sys,unittest,zlib
from test_rc346_thief_rule_guards import runtime
from test_rc349_runtime_events import UI_FIXTURE,LuaRuntime,SETUP,SOURCE
from generate_startup_trace import strip_trace

ROOT=Path(__file__).resolve().parents[1]
DB=Path(sys.argv.pop(1)) if len(sys.argv)>1 and not sys.argv[1].startswith('-') else Path(os.environ['LOCALAPPDATA'])/"Firaxis Games/Sid Meier's Civilization VI/Cache/DebugGameplay.sqlite"
PROJECT='PROJECT_LOTM_TP_CRYPTOLOGIST_POTION'

def receipt_runtime(extra_exports=""):
    lua=runtime('LOTM_RESCUE_Thief',extra_exports)
    lua.execute('''
    completedAmount=0; advances=0; stats.points=6; attachCount=0
    Players[0].props.LOTM_RP_SEQUENCE=8
    local row={Index=7,ProjectType="PROJECT_LOTM_TP_CRYPTOLOGIST_POTION"}
    GameInfo.Projects={[7]=row,PROJECT_LOTM_TP_CRYPTOLOGIST_POTION=row}
    GameInfo.LOTM_RESCUE_PotionCompletions={PROJECT_LOTM_TP_CRYPTOLOGIST_POTION={PropertyKey="NATIVE_COMPLETION",ModifierId="NATIVE_MOD"}}
    local original=Players[0].GetProperty
    Players[0].GetProperty=function(self,key) if key=="NATIVE_COMPLETION" then return completedAmount end return original(self,key) end
    Players[0].AttachModifierByID=function() attachCount=attachCount+1; error("Gameplay must not grant native completion") end
    LOTM_RP_State.AdvanceSequence=function(id,old,new)
      if Players[id].props.LOTM_RP_SEQUENCE~=old or stats.points<6 then return false end
      Players[id].props.LOTM_RP_SEQUENCE=new; stats.points=0; advances=advances+1; return true
    end
    function Reconcile() return LOTM_RESCUE_Thief.ReconcileCompletedPotion(0) end
    ''')
    return lua

class ReceiptTests(unittest.TestCase):
    def test_cancel_or_empty_queue_never_advances_without_native_receipt(self):
        lua=receipt_runtime(); lua.execute('for i=1,100 do assert(Reconcile()==false) end')
        self.assertEqual(lua.eval('advances'),0); self.assertEqual(lua.eval('attachCount'),0)

    def test_native_completion_advances_same_turn_exactly_once(self):
        lua=receipt_runtime(); lua.execute('Reconcile(); completedAmount=1; turn=18; assert(Reconcile()); assert(turn==18); Reconcile()')
        self.assertEqual(lua.eval('advances'),1); self.assertEqual(lua.eval('Players[0].props.LOTM_RP_SEQUENCE'),7)

    def test_native_marker_works_without_local_event_queue(self):
        lua=receipt_runtime(); lua.execute('completedAmount=1; assert(Reconcile())')
        self.assertEqual(lua.eval('advances'),1)

    def test_receipt_cannot_bypass_digestion_path_or_mode(self):
        for guard in ('stats.points=5','Players[0].props.LOTM_RP_PATH="PATH_PERFECT"','rescue=false'):
            lua=receipt_runtime(); lua.execute('completedAmount=1; '+guard+'; assert(Reconcile()==false)')
            self.assertEqual(lua.eval('advances'),0)

    def test_late_legacy_completion_event_cannot_advance_twice(self):
        lua=receipt_runtime(); lua.execute('completedAmount=1; assert(Reconcile()); assert(API.potion(0,1,7,18)==false)')
        self.assertEqual(lua.eval('advances'),1)

    def test_synchronized_command_validates_requester_and_native_receipt(self):
        lua=receipt_runtime(); lua.execute(SETUP); lua.execute(SOURCE)
        lua.execute('''
        local command=handlers.LOTM_RESCUE_Command_PotionCompleted
        command(0,{TargetPlayerID=0}); assert(advances==0)
        completedAmount=1; command(99,{TargetPlayerID=0}); assert(advances==0)
        command(0,{TargetPlayerID=99}); assert(advances==0)
        command(0,{TargetPlayerID=0}); assert(advances==1)
        command(0,{TargetPlayerID=0}); assert(advances==1)
        ''')

    def test_ui_publishes_completion_and_load_recheck_without_visual_refresh(self):
        lua=LuaRuntime(unpack_returned_tuples=True); lua.execute(UI_FIXTURE)
        lua.execute('''
        GameInfo={Projects={[7]={ProjectType="PROJECT_LOTM_TP_CRYPTOLOGIST_POTION"}},
          LOTM_RESCUE_PotionCompletions={PROJECT_LOTM_TP_CRYPTOLOGIST_POTION={}}}
        ''')
        lua.execute(strip_trace((ROOT/'UI/LOTM_RESCUE_RuntimeEvents.lua').read_text(encoding='utf-8')))
        lua.execute('''
        events.CityProjectCompleted(0,1,7); assert(#commands==0)
        events.GameCoreEventPublishComplete(); assert(#commands==1)
        assert(commands[1].OnStart=="LOTM_RESCUE_Command_PotionCompleted" and commands[1].TargetPlayerID==0)
        events.GameCoreEventPublishComplete(); assert(#commands==1)
        events.LoadGameViewStateDone(); assert(#commands==2)
        ''')

    def test_native_sql_requires_specific_completed_project_for_each_receipt(self):
        db=sqlite3.connect(':memory:'); db.create_function('Make_Hash',1,lambda v:zlib.crc32(str(v).encode()))
        with sqlite3.connect(f'file:{DB.as_posix()}?mode=ro',uri=True) as src: src.backup(db)
        sql=(ROOT/'Gameplay/LOTM_RESCUE_Thief.sql').read_text(encoding='utf-8')
        db.executescript(sql); db.executescript(sql)
        rows=db.execute('SELECT ProjectType,PropertyKey,ModifierId FROM LOTM_RESCUE_PotionCompletions').fetchall()
        self.assertEqual(len(rows),9)
        for project,key,modifier in rows:
            self.assertEqual(db.execute('SELECT ModifierId FROM ProjectCompletionModifiers WHERE ProjectType=? AND ModifierId=?',(project,modifier)).fetchone(),(modifier,))
            self.assertEqual(db.execute('SELECT ModifierType,RunOnce,Permanent,SubjectRequirementSetId FROM Modifiers WHERE ModifierId=?',(modifier,)).fetchone(),('MODIFIER_PLAYER_ADJUST_PROPERTY',1,1,None))
            self.assertEqual(dict(db.execute('SELECT Name,Value FROM ModifierArguments WHERE ModifierId=?',(modifier,))),{'Key':key,'Amount':'1'})
        self.assertEqual(db.execute('PRAGMA foreign_key_check').fetchall(),[])

if __name__=='__main__': unittest.main(verbosity=2)
