"""Real Lua callbacks and generated startup: not a native-engine test."""
from pathlib import Path
import re
import unittest
import zipfile

from test_rc348_camp_artifacts import HARNESS, EXPORT, LuaRuntime, runtime
from test_rc349_runtime_events import cleanup_runtime
from generate_gameplay_bundle import generate_rc241_network

ROOT = Path(__file__).resolve().parents[1]


def old_text(relative):
    with zipfile.ZipFile(ROOT.parent / 'dist/RedPriestPath-0.1.0-rc.349.zip') as z:
        return z.read('RedPriestPath/' + relative).decode('utf-8-sig').replace('\r\n', '\n')


class TurnSafety(unittest.TestCase):
    def test_rc349_reproduces_deleting_native_actor_during_move(self):
        old = re.sub(r'\s*:\s*(?:number|boolean|string|table)\b', '', old_text('Scripts/LOTM_PP_Workshops.lua'))
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(HARNESS)
        lua.execute(old.rstrip()[:-len('Initialize();')] + EXPORT)
        lua.execute('''
        nativeActorDeleted=false
        LOTM_WORLD_Barbarians={ProcessRescueUnitCandidates=function(ids)
          nativeActorDeleted=true; return true,1
        end}
        API.move(63,100)
        ''')
        self.assertTrue(lua.eval('nativeActorDeleted'))

    def test_moving_native_actor_is_never_deleted_in_callback(self):
        for network in (True, False):
            lua = runtime()
            lua.execute('network=' + str(network).lower())
            lua.execute('''
            LOTM_WORLD_Barbarians={ProcessRescueUnitCandidates=function()
              error('native moving actor must remain alive until operation returns')
            end}
            UnitManager.Kill=function() error('native movement reentrancy') end
            u=Unit(63,100)
            for i=1,100 do API.move(63,100) end
            assert(UnitManager.GetUnit(63,100)==u)
            assert(propertyWrites==0)
            ''')

    def test_cleanup_still_runs_after_movement_at_command_boundary(self):
        lua = cleanup_runtime()
        lua.execute('u=Unit(100,1,{}); Cleanup("63:100"); assert(UnitManager.GetUnit(63,100)==nil)')

    def test_generated_network_startup_actually_invokes_runtime_module(self):
        # Execute the generated top-level boot sequence, not just look for a
        # loader definition. rc349 embedded the module but never called it.
        marker = 'LOTM_MP241_LoadBundledModule("LOTM_MP241_Compat");\n'
        for old in (True, False):
            text = old_text('Scripts/LOTM_MP241_MainBundle.lua') if old else generate_rc241_network()
            boot = text[text.rindex(marker):]
            boot = boot[:boot.index('LOTM_MP241_MAIN_READY = true;') + len('LOTM_MP241_MAIN_READY = true;')]
            for rescue in (True, False):
                lua = LuaRuntime(unpack_returned_tuples=True)
                lua.execute('''
                loaded={}; LOTM_MP241_BUNDLE_LOADED={}
                function print() end
                LOTM_MP_TurnSync={IsRescueModeConfigured=function() return rescue end}
                function LOTM_MP241_LoadBundledModule(name)
                  loaded[#loaded+1]=name; LOTM_MP241_BUNDLE_LOADED[name]=true
                end
                ''')
                lua.globals().rescue = rescue
                lua.execute(boot)
                names = list(lua.globals().loaded.values())
                self.assertEqual(names.count('LOTM_RESCUE_RuntimeEvents'), int(rescue and not old))
                if rescue and not old:
                    self.assertGreater(names.index('LOTM_RESCUE_RuntimeEvents'), names.index('LOTM_RP_Gameplay'))
                self.assertTrue(lua.eval('LOTM_MP241_MAIN_READY'))


if __name__ == '__main__':
    unittest.main(verbosity=2)
