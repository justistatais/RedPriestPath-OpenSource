"""Execute Thief -> synchronized command -> real Lifecycle project gates.

The native project effect is simulated from the actual SQL rows, not invented
resource amounts. This proves the contract, not Civ VI engine execution.
"""
import sqlite3,unittest,zlib
from functools import lru_cache
from test_rc346_lifecycle_rules import runtime,ROOT,DATABASE
from test_rc349_runtime_events import SETUP,SOURCE

@lru_cache(maxsize=1)
def completion_rows():
    db=sqlite3.connect(':memory:'); db.row_factory=sqlite3.Row
    db.create_function('Make_Hash',1,lambda v:zlib.crc32(str(v).encode()))
    with sqlite3.connect(f'file:{DATABASE.as_posix()}?mode=ro',uri=True) as src: src.backup(db)
    db.executescript((ROOT/'Gameplay/LOTM_RESCUE_Thief.sql').read_text(encoding='utf-8'))
    rows=[dict(r) for r in db.execute('''SELECT c.*, m.ModifierType,m.RunOnce,m.Permanent,
      a.Value AS MarkerKey,b.Value AS MarkerAmount FROM LOTM_RESCUE_PotionCompletions c
      JOIN ProjectCompletionModifiers p ON p.ProjectType=c.ProjectType AND p.ModifierId=c.ModifierId
      JOIN Modifiers m ON m.ModifierId=p.ModifierId
      JOIN ModifierArguments a ON a.ModifierId=m.ModifierId AND a.Name='Key'
      JOIN ModifierArguments b ON b.ModifierId=m.ModifierId AND b.Name='Amount'
      ORDER BY c.ProjectType''')]
    db.close(); assert len(rows)==9
    return rows

def combined_runtime():
    lua=runtime(True)
    lua.execute('ResetPlayer("PATH_THIEF",8,6,0); PlayerManager={GetAliveMajors=function() return {player} end}')
    lua.globals().GameInfo.LOTM_RESCUE_PotionCompletions=lua.globals().Rows(lua.table_from(completion_rows(),recursive=True),'ProjectType')
    source=(ROOT/'Scripts/LOTM_RESCUE_Thief.lua').read_text(encoding='utf-8')
    source,registration=source.rsplit('\nif Active() then',1)
    assert 'LOTM_MP_TurnSync.RunStartup' in registration
    lua.execute(source)  # Only module event registration is skipped.
    # Inherited income/unit effects require unrelated engine APIs. Keep actual
    # Lifecycle sequence/digestion/project-gate refresh and stub only that hook.
    lua.execute('LOTM_RESCUE_Thief.RefreshSequenceState=function() end')
    lua.execute(SETUP); lua.execute(SOURCE)
    lua.execute('''
    function NativeComplete(project)
      local row=GameInfo.LOTM_RESCUE_PotionCompletions[project]
      assert(row.ModifierType=="MODIFIER_PLAYER_ADJUST_PROPERTY" and row.RunOnce==1 and row.Permanent==1)
      assert(row.MarkerKey==row.PropertyKey)
      -- Simulate the engine effect read from ProjectCompletionModifiers.
      player.props[row.MarkerKey]=(player.props[row.MarkerKey] or 0)+tonumber(row.MarkerAmount)
    end
    function SyncCompletion() handlers.LOTM_RESCUE_Command_PotionCompleted(0,{TargetPlayerID=0}) end
    ''')
    return lua

class ProjectCompletionTests(unittest.TestCase):
    def test_new_game_seq8_complete_advances_now_and_next_project_waits_for_new_digestion(self):
        lua=combined_runtime()
        lua.execute('''
        turn=25; local rule=API.Current(player); assert(rule.ToSequence==7)
        assert(API.Refresh(0)); assert(RuleGate(rule)==1)
        SyncCompletion(); assert(player.props.LOTM_RP_SEQUENCE==8)
        NativeComplete(rule.ProjectType); SyncCompletion()
        assert(turn==25 and player.props.LOTM_RP_SEQUENCE==7)
        assert(player.props.LOTM_RP_DIGEST_A==0 and ResourceTotal()==0)
        local nextRule=API.Current(player); assert(nextRule.FromSequence==7)
        SyncCompletion(); assert(player.props.LOTM_RP_SEQUENCE==7)
        assert(RuleGate(nextRule)==0)
        player.props.LOTM_RP_DIGEST_A=6; assert(API.Refresh(0)); assert(RuleGate(nextRule)==1)
        ''')

    def test_all_nine_projects_advance_once_through_real_lifecycle(self):
        lua=combined_runtime()
        lua.execute('''
        for _,rule in ipairs(rules) do if rule.PathType=="PATH_THIEF" then
          ResetPlayer("PATH_THIEF",rule.FromSequence,6,0); API.Refresh(0)
          NativeComplete(rule.ProjectType); SyncCompletion()
          assert(player.props.LOTM_RP_SEQUENCE==rule.ToSequence,rule.ProjectType)
          assert(player.props.LOTM_RP_DIGEST_A==0 and ResourceTotal()==0)
          SyncCompletion(); assert(player.props.LOTM_RP_SEQUENCE==rule.ToSequence)
        end end
        ''')

    def test_cancel_or_unqualified_or_wrong_project_never_advances(self):
        for setup in (
            '',
            'NativeComplete("PROJECT_LOTM_TP_SWINDLER_POTION")',
            'NativeComplete("PROJECT_LOTM_TP_CRYPTOLOGIST_POTION"); player.props.LOTM_RP_DIGEST_A=5',
            'NativeComplete("PROJECT_LOTM_TP_CRYPTOLOGIST_POTION"); player.props.LOTM_RP_PATH="PATH_PERFECT"',
            'NativeComplete("PROJECT_LOTM_TP_CRYPTOLOGIST_POTION"); rescue=false',
        ):
            lua=combined_runtime(); lua.execute(setup+'\nSyncCompletion(); assert(player.props.LOTM_RP_SEQUENCE==8)')

    def test_completion_marker_is_never_attached_by_gameplay(self):
        lua=combined_runtime()
        lua.execute('''
        API.Refresh(0); local before=#stats.attachments
        for i=1,20 do SyncCompletion() end
        assert(#stats.attachments==before)
        for _,row in pairs(GameInfo.LOTM_RESCUE_PotionCompletions) do
          assert(player:GetProperty(row.PropertyKey)==nil)
        end
        ''')

if __name__=='__main__': unittest.main(verbosity=2)
