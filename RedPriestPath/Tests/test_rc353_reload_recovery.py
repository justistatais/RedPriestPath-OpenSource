"""Exercise the real turn dispatcher and the saved-READY UI race in Lua 5.1."""
import unittest
from test_rc352_potion_receipt import receipt_runtime,ROOT
from test_rc349_runtime_events import UI_FIXTURE,LuaRuntime
from generate_startup_trace import strip_trace

TURN_EXPORTS=r'''
API.turn=OnTurn
GrantEnergyForPurification=function() end
MigrateLegacyS2Selection=function() end
ProcessThief=function() end
EnsureWorm=function() end
AutoErrorClear=function() end
RefreshEffects=function() end
LOTM_MP_TurnSync.IsNetworkGame=function() return network end
LOTM_MP_TurnSync.GetStableAnchorPlayerID=function() return 0 end
LOTM_MP_TurnSync.IsStableAnchorPlayer=function(id) return id==0 end
for id=1,3 do Players[id].human=false end
'''

def turn_runtime():
    lua=receipt_runtime(TURN_EXPORTS)
    lua.execute('network=true; turn=19; completedAmount=1')
    return lua

def ui_runtime(network=True):
    lua=LuaRuntime(unpack_returned_tuples=True); lua.execute(UI_FIXTURE)
    lua.execute('''
    properties.LOTM_MP241_MAIN_LOAD_SERIAL=7
    properties.LOTM_MP241_MAIN_LOAD_STATE="LOADED"
    GameInfo={Projects={[7]={ProjectType="POTION"}},LOTM_RESCUE_PotionCompletions={POTION={}}}
    '''+('GameConfiguration={IsAnyMultiplayer=function() return true end}' if network else ''))
    lua.execute(strip_trace((ROOT/'UI/LOTM_RESCUE_RuntimeEvents.lua').read_text(encoding='utf-8')))
    return lua

class ReloadRecovery(unittest.TestCase):
    def test_network_startup_and_later_turn_recover_without_local_completion_event(self):
        lua=turn_runtime()
        lua.execute('API.turn(0,true); assert(advances==1); assert(Players[0].props.LOTM_RP_SEQUENCE==7); turn=20; API.turn(0,true); assert(advances==1)')

    def test_non_anchor_and_non_first_turn_do_not_mutate(self):
        lua=turn_runtime(); lua.execute('API.turn(1,true); API.turn(0,false); assert(advances==0); assert(attachCount==0)')

    def test_delayed_native_receipt_is_rechecked_without_reattaching(self):
        lua=turn_runtime()
        lua.execute('completedAmount=0; API.turn(0,true); assert(advances==0); assert(attachCount==0); completedAmount=1; turn=20; API.turn(0,true); assert(advances==1); assert(attachCount==0)')

    def test_single_player_turn_still_recovers(self):
        lua=turn_runtime(); lua.execute('network=false; API.turn(0,true); assert(advances==1)')

    def test_cancelled_or_unqualified_network_save_never_advances(self):
        for guard in ('completedAmount=0','stats.points=5','rescue=false','Players[0].props.LOTM_RP_PATH="PATH_PERFECT"'):
            lua=turn_runtime(); lua.execute(guard+'; API.turn(0,true); assert(advances==0)')

    def test_saved_ready_waits_for_fresh_loaded_ack_and_preserves_all_queues(self):
        lua=ui_runtime()
        lua.execute('''
        events.LoadGameViewStateDone(); events.UnitAddedToMap(63,9); events.ImprovementRemovedFromMap(1,1)
        for i=1,100 do events.GameCoreEventPublishComplete() end
        assert(#commands==0)
        properties.LOTM_MP241_MAIN_LOAD_SERIAL=8; properties.LOTM_MP241_MAIN_LOAD_STATE="LOADING"
        events.GameCoreEventPublishComplete(); assert(#commands==0)
        properties.LOTM_MP241_MAIN_LOAD_STATE="LOADED"
        events.GameCoreEventPublishComplete(); assert(#commands==3)
        assert(commands[1].OnStart=="LOTM_RESCUE_Command_NativeCleanup")
        assert(commands[2].OnStart=="LOTM_RESCUE_Command_CampRemoved")
        assert(commands[3].OnStart=="LOTM_RESCUE_Command_PotionCompleted")
        events.GameCoreEventPublishComplete(); assert(#commands==3)
        events.CityProjectCompleted(0,1,7); events.GameCoreEventPublishComplete(); assert(#commands==4)
        ''')

    def test_failed_load_or_old_serial_never_uses_saved_ready(self):
        lua=ui_runtime()
        lua.execute('''
        events.LoadGameViewStateDone(); assert(#commands==0)
        properties.LOTM_MP241_MAIN_LOAD_SERIAL=8; properties.LOTM_MP241_MAIN_LOAD_STATE="FAILED"
        events.GameCoreEventPublishComplete(); assert(#commands==0)
        properties.LOTM_MP241_MAIN_LOAD_STATE="LOADED"; properties.LOTM_RESCUE_RUNTIME_EVENTS_READY=0
        events.GameCoreEventPublishComplete(); assert(#commands==0)
        properties.LOTM_RESCUE_RUNTIME_EVENTS_READY=1; events.GameCoreEventPublishComplete(); assert(#commands==1)
        ''')

    def test_single_player_does_not_require_network_serial(self):
        lua=ui_runtime(False); lua.execute('events.LoadGameViewStateDone(); assert(#commands==1)')

if __name__=='__main__': unittest.main(verbosity=2)
