"""Publication-to-command integration; mocks do not prove native acceptance."""
from pathlib import Path
import unittest
import zipfile
import xml.etree.ElementTree as ET

from test_rc349_runtime_events import UI_FIXTURE, LuaRuntime, reward_runtime
from generate_startup_trace import strip_trace

ROOT=Path(__file__).resolve().parents[1]
UI_SOURCE=strip_trace((ROOT/'UI/LOTM_RESCUE_RuntimeEvents.lua').read_text(encoding='utf-8'))

class Dispatch(unittest.TestCase):
    def test_old_rc350_waits_for_visual_refresh_new_publishes_without_one(self):
        with zipfile.ZipFile(ROOT.parent/'dist/RedPriestPath-0.1.0-rc.350.zip') as z:
            old=strip_trace(z.read('RedPriestPath/UI/LOTM_RESCUE_RuntimeEvents.lua').decode('utf-8'))
        for source,expected in ((old,0),(UI_SOURCE,1)):
            lua=LuaRuntime(unpack_returned_tuples=True); lua.execute(UI_FIXTURE); lua.execute(source)
            # No synthetic refresh() call: an empty visual context may not render.
            lua.execute('events.ImprovementRemovedFromMap(1,2); for i=1,10 do events.GameCoreEventPublishComplete() end')
            self.assertEqual(lua.eval('#commands'),expected)

    def test_ui_native_publish_command_and_real_reward_in_same_turn(self):
        lua=reward_runtime()
        lua.execute('''
        properties.LOTM_RESCUE_RUNTIME_EVENTS_READY=1
        Game.GetLocalPlayer=function() return 0 end
        Players[0].IsTurnActive=function() return true end
        Players[1].IsTurnActive=function() return false end
        events={}; Events=setmetatable({}, {__index=function(t,k)
          local e={Add=function(fn) events[k]=fn end}; rawset(t,k,e); return e end})
        ContextPtr=setmetatable({}, {__index=function() error('no visual refresh required') end})
        PlayerOperations={EXECUTE_SCRIPT=1}; sent=0
        UI={RequestPlayerOperation=function(id,op,parameters)
          sent=sent+1; handlers[parameters.OnStart](id,parameters)
          -- Engine publication must not recursively submit the same work.
          events.GameCoreEventPublishComplete()
        end}
        ''')
        lua.execute(UI_SOURCE)
        lua.execute('''
        for epoch=1,5 do
          plot.props={LOTM_PP_WORKSHOP_CLASSIFIED=1,LOTM_PP_WORKSHOP_IS_WORKSHOP=1,
            LOTM_PP_WORKSHOP_CAMP_EPOCH=epoch,LOTM_RESCUE_WORKSHOP_CLASSIFIED_TURN=epoch}
          Receipt(0,100); Remove(); local before=propertyWrites
          events.ImprovementRemovedFromMap(21,46)
          assert(propertyWrites==before) -- UI observation writes no authority
          assert(#grants==epoch-1)
          events.GameCoreEventPublishComplete()
          assert(#grants==epoch and turn==6)
          assert(plot.props.LOTM_PP_WORKSHOP_REWARD_SETTLED==1)
          events.ImprovementRemovedFromMap(21,46); events.GameCoreEventPublishComplete()
          assert(#grants==epoch)
        end
        turn=7; Boundary(); turn=8; Boundary(); assert(#grants==5)
        ''')
        self.assertEqual(lua.eval('sent'),5)

    def test_inactive_sender_waits_then_birth_batch_sends_once(self):
        lua=LuaRuntime(unpack_returned_tuples=True); lua.execute(UI_FIXTURE); lua.execute(UI_SOURCE)
        lua.execute('''
        active=false; for i=1,100 do events.UnitAddedToMap(63,i) end
        for i=1,1000 do events.GameCoreEventPublishComplete() end
        assert(#commands==0); active=true; events.PlayerTurnActivated()
        assert(#commands==2)
        for i=1,1000 do events.GameCoreEventPublishComplete() end
        assert(#commands==2 and requests==0)
        ''')

    def test_rejection_throttled_and_error_does_not_poison_future_flush(self):
        lua=LuaRuntime(unpack_returned_tuples=True); lua.execute(UI_FIXTURE); lua.execute(UI_SOURCE)
        lua.execute('''
        local submit=UI.RequestPlayerOperation; tries=0
        UI.RequestPlayerOperation=function() tries=tries+1; error('temporary refusal') end
        events.ImprovementRemovedFromMap(1,2)
        for i=1,1000 do events.GameCoreEventPublishComplete() end
        assert(tries==1)
        turn=turn+1; UI.RequestPlayerOperation=submit; events.GameCoreEventPublishComplete()
        assert(#commands==1)
        ''')

    def test_old_save_raw_names_have_both_selected_language_translations(self):
        for lang in ('zh_Hans_CN','en_US'):
            source=ET.parse(ROOT/f'Text/{lang}/LOTM_RP_GameplayText.xml')
            rows={r.get('Tag'):r.findtext('Text') for r in source.getroot().iter('Row')}
            selected=ET.parse(ROOT/f'Text/Selected/LOTM_RP_Selected_{lang}.xml')
            packed={r.get('Tag'):r.findtext('Text') for r in selected.getroot().iter() if r.get('Tag')}
            for tier,name in ((2,'LOW'),(1,'MID'),(0,'HIGH')):
                raw=f'LOTM_WORLD_MONSTER_{tier}'
                self.assertEqual(rows[raw],rows[f'LOC_LOTM_WORLD_MONSTER_{name}_NAME'])
                self.assertEqual(packed[raw],rows[raw])

if __name__=='__main__': unittest.main(verbosity=2)
