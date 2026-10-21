"""Run real Phase 10 spawn/advance/kill logic with bounded engine doubles."""
from pathlib import Path
import hashlib
import sqlite3
import unittest
import zipfile
import zlib
import xml.etree.ElementTree as ET
from test_rc346_thief_rule_guards import LuaRuntime
from test_rc346_lifecycle_rules import runtime as lifecycle_runtime, DATABASE

ROOT = Path(__file__).resolve().parents[1]
HARNESS = r'''
function include() end
function print() end
turn=84; kills=0; creates=0; props={LOTM_RESCUE_MODE=1,LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED=1}
Game={GetProperty=function(k) return props[k] end,SetProperty=function(k,v) props[k]=v end}
GameConfiguration={IsAnyMultiplayer=function() return network end}
LOTM_RESCUE_Phase5={WorldTurn=function() return turn end}
LOTM_RESCUE_Phase10A={RefreshAll=function() end}
LOTM_MP_TurnSync={Add=function() end,RunStartup=function() end}
local event={Add=function() end}
Events={UnitRemovedFromMap=event,UnitMoveComplete=event,UnitDamageChanged=event}
GameEvents={OnCombatOccurred=event}
units={}
function Unit(role,birth)
 local u={props={LOTM_RESCUE_PHASE10_IS_GOD=1,LOTM_RESCUE_PHASE10_ROLE=role,LOTM_RESCUE_PHASE10_SPAWN_TURN=birth},damage=0,id=creates+10}
 function u:GetProperty(k) return self.props[k] end
 function u:SetProperty(k,v) self.props[k]=v end
 function u:GetOwner() return 0 end
 function u:GetID() return self.id end
 function u:GetType() return 1 end
 function u:IsDead() return self.dead or false end
 function u:IsDelayedDeath() return false end
 function u:GetDamage() return self.damage end
 function u:GetMaxDamage() return 100 end
 function u:ChangeDamage(v) self.damage=self.damage+v end
 function u:GetCombat() return 550 end
 function u:GetExperience() return nil end
 units[u.id]=u; return u
end
UnitManager={Kill=function(u) kills=kills+1; u.dead=true; units[u.id]=nil end,
 GetUnit=function(p,id) return units[id] end,
 InitUnit=function(p,t,x,y) creates=creates+1; return Unit(nil,nil) end}
player={props={LOTM_RP_PATH='PATH_THIEF',LOTM_RP_SEQUENCE=0},human=true}
function player:GetID() return 0 end
function player:IsHuman() return self.human end
function player:GetProperty(k) return self.props[k] end
function player:SetProperty(k,v) self.props[k]=v end
Players={[0]=player}
GameInfo={Units={UNIT_LOTM_RESCUE_GOD_THIEF={Index=1}}}
'''
EXPORTS = r'''
API={attack=OuterGodUnitAttack,network=CorrectNetworkGodCombatDamage,native=CorrectNativeGodCombatDamage,
 ensure=EnsurePlayerGod,spawn=Spawn,paths=PATH_GODS,events=m_nativeDamageEvents,combats=m_bossCombatEvents}
-- Stub placement and effect APIs, retaining real Spawn and EnsurePlayerGod.
plot={GetX=function() return 1 end,GetY=function() return 1 end,GetIndex=function() return 1 end}
CandidatePlots=function() return noPlot and {} or {{Plot=plot,Distance=1}} end
PlacedUnit=function(u) if u and not u.dead then return u,plot,'OK' end end
PlacementAllowed=function() return true,1,'OK' end
SetAbilityCount=function() return true end
ExactStrength=function() return true end
EffectiveCombatStrength=function(u,f) return f end
CombatStrengthDamage=function() return 100 end
'''


def runtime(old=False):
    lua=LuaRuntime(unpack_returned_tuples=True);lua.execute(HARNESS)
    if old:
        archive=ROOT.parent/'dist/RedPriestPath-0.1.0-rc.357.zip'
        assert hashlib.sha256(archive.read_bytes()).hexdigest()=='4f3c39729b531776a2227129eb425679f38bcfef691b792f6c1a2795919e6d2a'
        with zipfile.ZipFile(archive) as z: source=z.read('RedPriestPath/Scripts/LOTM_RESCUE_Phase10.lua').decode('utf-8-sig')
    else: source=(ROOT/'Scripts/LOTM_RESCUE_Phase10.lua').read_text(encoding='utf-8-sig')
    lua.execute(source+EXPORTS);return lua


class DescentTests(unittest.TestCase):
    def test_immutable_previous_release_misses_thief_and_kills_new_church_god(self):
        lua=runtime(True)
        lua.execute("assert(API.ensure(player)==nil and creates==0); target=Unit('STORM',turn); assert(API.attack(Unit('BOSS',turn),target)); assert(target.dead and kills==1)")

    def test_thief_immediate_spawn_is_real_and_idempotent(self):
        lua=runtime();lua.execute('''
        assert(LOTM_RESCUE_Phase10.OnSequenceZeroAdvanced(0)); assert(creates==1)
        assert(LOTM_RESCUE_Phase10.OnSequenceZeroAdvanced(0)); assert(creates==1)
        local u=API.ensure(player); assert(u:GetProperty('LOTM_RESCUE_PHASE10_ROLE')=='PLAYER_GOD_0')
        assert(u:GetProperty('LOTM_RESCUE_PHASE10_SPAWN_TURN')==84)
        assert(LOTM_RESCUE_Phase10.IsDescentProtected(u))
        turn=85; API.ensure(player); assert(not LOTM_RESCUE_Phase10.IsDescentProtected(u) and creates==1)
        ''')

    def test_spawn_waits_for_world_descent_and_rescue_and_sequence_and_placement(self):
        for setup in ("props.LOTM_RESCUE_MODE=0", "props.LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED=0", "props.LOTM_RESCUE_PHASE10_VICTORY=1", "player.props.LOTM_RP_SEQUENCE=1", "player.human=false", "noPlot=true"):
            lua=runtime();lua.execute(setup+"; assert(not LOTM_RESCUE_Phase10.OnSequenceZeroAdvanced(0)); assert(creates==0)")

    def test_protection_all_friend_roles_but_not_boss_minion_or_ordinary(self):
        lua=runtime();lua.execute('''
        for _,r in ipairs({'FOOL','NIGHT','STORM','PLAYER_GOD_0','PLAYER_GOD_7'}) do
         local t=Unit(r,turn); local ok,reason=API.attack(Unit('BOSS',turn),t)
         assert(not ok and reason=='DESCENT_PROTECTED' and not t.dead and t.damage==0)
        end
        assert(kills==0)
        for _,r in ipairs({'BOSS','MINION','','PLAYER_GOD_BAD'}) do
         assert(not LOTM_RESCUE_Phase10.IsDescentProtected(Unit(r,turn)))
        end
        local t=Unit('FOOL',turn); t.props.LOTM_RESCUE_PHASE10_IS_GOD=0
        assert(not LOTM_RESCUE_Phase10.IsDescentProtected(t))
        ''')

    def test_protection_expires_and_does_not_need_local_cache_after_reload(self):
        lua=runtime();lua.execute("target=Unit('NIGHT',83); assert(API.attack(Unit('BOSS',turn),target)); assert(target.dead)")
        lua=runtime();lua.execute("target=Unit('NIGHT',84); assert(not API.attack(Unit('BOSS',turn),target)); assert(not target.dead)")

    def test_native_and_network_script_correction_skip_birth_turn(self):
        for network in (False,True):
            lua=runtime();lua.globals().network=network
            lua.execute('''target=Unit('STORM',turn); target.damage=10
            API.events.k={Old=0,New=10}; API.combats.k={Player=0,Unit=target.id,Role='STORM',Desired=100,IsBoss=false,Attack=999,Defense=550}
            API.native('k'); API.network(target,'STORM',999,550,false)
            assert(kills==0 and target.damage==10)
            turn=85; API.network(target,'STORM',999,550,false); assert(kills==1)''')

    def test_shared_script_kill_has_no_killer_reward_on_protected_attempt(self):
        lua=runtime();lua.execute((ROOT/'Scripts/LOTM_RESCUE_SyncActions.lua').read_text(encoding='utf-8-sig'))
        lua.execute('''marks=0; LOTM_RESCUE_SyncActions.MarkScriptedKiller=function() marks=marks+1 end
        target=Unit('PLAYER_GOD_0',turn); boss=Unit('BOSS',turn)
        assert(not LOTM_RESCUE_SyncActions.ScriptedKill(target,boss)); assert(kills==0 and marks==0)
        turn=85; assert(LOTM_RESCUE_SyncActions.ScriptedKill(target,boss)); assert(kills==1 and marks==1)''')

    def test_respawn_new_birth_turn_without_extra_respawn_allowance(self):
        lua=runtime();lua.execute('''
        props.LOTM_RESCUE_PHASE10_PLAYER_GOD_0_STATE='RESPAWN_PENDING'
        props.LOTM_RESCUE_PHASE10_PLAYER_GOD_0_RESPAWN_TURN=84
        local u=API.ensure(player); assert(u and LOTM_RESCUE_Phase10.IsDescentProtected(u))
        assert(props.LOTM_RESCUE_PHASE10_PLAYER_GOD_0_RESPAWN_USED==1)
        turn=85; UnitManager.Kill(u); player.GetUnits=function() return {FindID=function() end} end
        assert(API.ensure(player)==nil and creates==1)
        assert(props.LOTM_RESCUE_PHASE10_PLAYER_GOD_0_STATE=='DEAD')''')

    def test_real_lifecycle_calls_descent_after_sequence_committed_once(self):
        lua=lifecycle_runtime(True);lua.execute('''
        ResetPlayer('PATH_THIEF',1,6,0); callbacks=0
        LOTM_RESCUE_Phase10={OnSequenceZeroAdvanced=function(id)
         assert(id==0 and player.props.LOTM_RP_SEQUENCE==0); callbacks=callbacks+1
        end}
        assert(LOTM_RP_State.AdvanceSequence(0,1,0,true)); assert(callbacks==1)
        assert(not LOTM_RP_State.AdvanceSequence(0,1,0,true)); assert(callbacks==1)''')

    def test_database_art_and_localization_are_complete_and_rescue_gated(self):
        db=sqlite3.connect(':memory:')
        db.create_function('Make_Hash',1,lambda s:zlib.crc32(s.encode('utf-8')))
        with sqlite3.connect(f'file:{DATABASE.as_posix()}?mode=ro',uri=True) as src: src.backup(db)
        db.executescript((ROOT/'Gameplay/LOTM_RESCUE_Phase10.sql').read_text(encoding='utf-8-sig'))
        name='UNIT_LOTM_RESCUE_GOD_THIEF'
        self.assertEqual(db.execute('SELECT Combat,CanTrain,Name FROM Units WHERE UnitType=?',(name,)).fetchone(),(550,0,'LOC_'+name+'_NAME'))
        self.assertIsNotNone(db.execute('SELECT 1 FROM TypeTags WHERE Type=? AND Tag=?',(name,'CLASS_LOTM_RESCUE_GOD')).fetchone())
        for lang in ('zh_Hans_CN','en_US'):
            rows=ET.parse(ROOT/f'Text/{lang}/LOTM_RP_GameplayText.xml').findall(f'.//Row[@Tag="LOC_{name}_NAME"]')
            self.assertEqual(len(rows),1);self.assertTrue(rows[0].findtext('Text'))
        actions=ET.parse(ROOT/'RedPriestPath.modinfo').findall('./InGameActions/UpdateDatabase')
        self.assertTrue(any(a.get('criteria')=='LOTM_RP_RESCUE_MODE' and any(n.text=='Gameplay/LOTM_RESCUE_Phase10.sql' for n in a.findall('.//File')) for a in actions))
        from validate_god_models import main
        self.assertEqual(main(),0)


if __name__=='__main__': unittest.main(verbosity=2)
