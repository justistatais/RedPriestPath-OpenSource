"""Real storm/Phase-10 Lua bodies under finite substitutes, not native Civ VI."""
from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET

import test_rc392_god_blessings as god
from generate_gameplay_bundle import lua_function_span
from generate_startup_trace import strip_trace

ROOT=Path(__file__).resolve().parents[1]

def phase_api(lua):
    source=(ROOT/'Scripts/LOTM_RESCUE_Phase10.lua').read_text(encoding='utf-8')
    names=('PublishNetworkConfirmedDamage','IsGod','UnitKey','KillBossAtTerminalDamage','OnUnitDamageChanged')
    bodies=[]
    for name in names:
        start,end=lua_function_span(source,name)
        bodies.append(source[start:end])
    block=re.search(r'-- BEGIN USER AUTHORIZED RESCUE STORM DAMAGE \(resource434\)[\s\S]*?-- END USER AUTHORIZED RESCUE STORM DAMAGE \(resource434\)',source).group(0)
    lua.execute('''
      network=false;phases=0;bossKills=0;corrected=0;
      GameConfiguration.IsAnyMultiplayer=function() return network end;
      gameprops.LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED=1;
      GameInfo.Units[501]={UnitType='UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR',Index=501};
      GameInfo.Units[502]={UnitType='UNIT_LOTM_RESCUE_OUTER_GOD_MINION',Index=502};
      GameInfo.Units[503]={UnitType='UNIT_WARRIOR',Index=503};
      UnitManager.GetUnit=function(owner,id)
       local u=units[id];return u~=nil and u:GetOwner()==owner and u or nil;
      end;
      LOTM_RESCUE_Phase10={};
      local BOSS_TYPE='UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR';
      local GOD_PROPERTY='LOTM_RESCUE_PHASE10_IS_GOD';
      local CONFIRMED_DAMAGE_PROPERTY='LOTM_RESCUE_PHASE10_LAST_CONFIRMED_DAMAGE';
      local m_bossIntentionalDefeat={};local m_nativeDamageEvents={};
      local m_nativeDamageCorrections={};local m_bossCombatEvents={};
      local function Number(v,d) return tonumber(v) or d end;
      local function Active() return rescue end;
      local function IsNetworkMultiplayer() return network end;
      local function Log(s) end;
      local function ResolveBossDefeat(...) phases=phases+1 end;
      local function CorrectNativeGodCombatDamage(key)
       if m_bossCombatEvents[key]~=nil then corrected=corrected+1;error('stale combat amplification') end;
      end;
    '''+'\n'.join(bodies)+'\n'+block+'''
      function CreateBoss(damage,x,epoch)
       local u=UnitManager.InitUnit(1,501,x or 11,10);
       u.damage=damage or 0;
       u.props.LOTM_RESCUE_PHASE10_ROLE='BOSS';u.props.LOTM_RESCUE_PHASE10_IS_GOD=1;
       u.props.LOTM_RESCUE_PHASE10_BOSS_EPOCH=epoch or 1;
       u.props.LOTM_RESCUE_PHASE10_LAST_CONFIRMED_DAMAGE=u.damage;
       gameprops.LOTM_RESCUE_PHASE10_BOSS_OWNER=1;gameprops.LOTM_RESCUE_PHASE10_BOSS_UNIT=u:GetID();
       local change=u.ChangeDamage;
       u.ChangeDamage=function(self,delta)
        if failBefore then error('before native change') end;
        local old=self.damage;change(self,delta);
        OnUnitDamageChanged(self:GetOwner(),self:GetID(),self.damage,old);
        if failAfter then error('after native change') end;
       end;
       return u;
      end;
      local kill=UnitManager.Kill;
      UnitManager.Kill=function(u)
       if u:GetType()==501 then bossKills=bossKills+1 end;return kill(u);
      end;
      function SeedStaleCombat(u) m_bossCombatEvents[UnitKey(u:GetOwner(),u:GetID())]={Desired=1000} end;
      function fireBoss() fire('LOTM_Storm_Prepare',{ExpectedSerial=N(p,'LOTM_STORM_CAST_SERIAL',0)});
       fire('LOTM_Storm_Fire',{CastSerial=N(p,'LOTM_STORM_CAST_SERIAL',0),PlotIndex=6});end;
    ''')
    return lua

def runtime(debug=True):
    return phase_api(god.runtime(rescue=True,debug=debug))

class RescueStorm(unittest.TestCase):
    def test_full_health_boss_prejudged_before_resistance_or_nuclear_kill(self):
        lua=runtime();lua.execute('boss=CreateBoss();boss.GetAbility=function() error("no nuclear resistance read for Boss") end;fireBoss()')
        self.assertEqual(lua.eval('boss:GetDamage()'),0)
        lua.execute('impact(97)');self.assertEqual(lua.eval('boss:GetDamage()'),0)
        lua.execute('impact(98)')
        self.assertEqual(lua.eval('boss:GetDamage()'),20)
        self.assertEqual(lua.eval('bossKills'),0)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'FIRED')
        self.assertEqual(lua.eval('''(function()
          local found=0;
          for i=1,p.props.LOTM_STORM_PLAN_COUNT do
            local key='LOTM_STORM_PLAN_'..i..'_';
            if p.props[key..'Kind']=='OUTER_GOD' and p.props[key..'Owner']==1
               and p.props[key..'ID']==boss:GetID() then found=found+1 end;
          end;
          return found;
        end)()'''),1)
        self.assertEqual(lua.eval('stats.created'),1)
        self.assertEqual(lua.eval('stats.improvementChanges+stats.weaponChanges'),0)

    def test_wounded_and_repeated_casts_each_deal_twenty_without_full_health_kill(self):
        lua=runtime();lua.execute('boss=CreateBoss(30);fireBoss();impact();fireBoss();impact();impact()')
        self.assertEqual(lua.eval('boss:GetDamage()'),70)
        self.assertEqual(lua.eval('bossKills'),0)
        self.assertEqual(lua.eval('stats.damageChanges'),2)

    def test_minions_and_other_targets_keep_existing_nuclear_profile(self):
        lua=runtime();lua.execute('boss=CreateBoss();minion=UnitManager.InitUnit(1,502,11,10);ordinary=UnitManager.InitUnit(1,503,11,10);fireBoss();impact()')
        self.assertEqual(lua.eval('boss:GetDamage()'),20)
        self.assertIsNone(lua.eval('units[minion:GetID()]'))
        self.assertIsNone(lua.eval('units[ordinary:GetID()]'))
        self.assertEqual(lua.eval('bossKills'),0)

    def test_legacy_saved_nuclear_step_is_converted_before_apply(self):
        lua=runtime();lua.execute('''boss=CreateBoss(10);fire('LOTM_Storm_Prepare',{ExpectedSerial=0});
         p.props.LOTM_STORM_APPLYING=1;p.props.LOTM_STORM_PLAN_COUNT=1;p.props.LOTM_STORM_PLAN_DONE=0;
         p.props.LOTM_STORM_PLAN_1_Kind='UNIT';p.props.LOTM_STORM_PLAN_1_Owner=1;p.props.LOTM_STORM_PLAN_1_ID=boss:GetID();
         p.props.LOTM_STORM_PLAN_1_Value=100;p.props.LOTM_STORM_PLAN_1_Extra=100;turns.GodBlessings(0);turns.GodBlessings(0);''')
        self.assertEqual(lua.eval('boss:GetDamage()'),30)
        self.assertEqual(lua.eval('bossKills'),0)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_PLAN_1_Kind'),'OUTER_GOD')

    def test_native_exception_before_change_can_retry_after_source_reload(self):
        lua=runtime();lua.execute('boss=CreateBoss(10);failBefore=true;fireBoss();impact()')
        self.assertEqual(lua.eval('boss:GetDamage()'),10)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'IMPACT_FAILED')
        lua.execute(god.blessing_source())
        lua.execute('failBefore=false;turns.GodBlessings(0);turns.GodBlessings(0)')
        self.assertEqual(lua.eval('boss:GetDamage()'),30)
        self.assertEqual(lua.eval('stats.damageChanges'),1)

    def test_after_change_exception_and_healing_do_not_repeat_twenty(self):
        lua=runtime();lua.execute('''boss=CreateBoss(40);failAfter=true;fireBoss();impact();
         boss.damage=40;
         ok=LOTM_RESCUE_Phase10.ApplyStormDamage(boss,40,60,1,0,1);''')
        self.assertTrue(lua.eval('ok'))
        self.assertEqual(lua.eval('boss:GetDamage()'),40)
        self.assertEqual(lua.eval('stats.damageChanges'),1)
        self.assertEqual(lua.eval('bossKills'),0)

    def test_stale_native_combat_cannot_amplify_the_fixed_hit(self):
        lua=runtime();lua.execute('boss=CreateBoss();SeedStaleCombat(boss);fireBoss();impact()')
        self.assertEqual(lua.eval('boss:GetDamage()'),20)
        self.assertEqual(lua.eval('corrected'),0)

    def test_network_checkpoint_and_lethal_phase_use_existing_terminal_path(self):
        lua=runtime();lua.execute('network=true;boss=CreateBoss();fireBoss();impact()')
        self.assertEqual(lua.eval('boss.props.LOTM_RESCUE_PHASE10_LAST_CONFIRMED_DAMAGE'),20)
        self.assertEqual(lua.eval('phases'),0)
        lua.execute('boss.damage=85;boss.props.LOTM_RESCUE_PHASE10_LAST_CONFIRMED_DAMAGE=85;fireBoss();impact()')
        self.assertEqual(lua.eval('bossKills'),1)
        self.assertEqual(lua.eval('phases'),1)

    def test_old_phase_identity_never_hits_newly_respawned_boss(self):
        lua=runtime();lua.execute('''boss=CreateBoss(10);failBefore=true;fireBoss();impact();
         boss.props.LOTM_RESCUE_PHASE10_BOSS_EPOCH=2;boss.damage=0;failBefore=false;turns.GodBlessings(0)''')
        self.assertEqual(lua.eval('boss:GetDamage()'),0)
        self.assertEqual(lua.eval('bossKills'),0)

    def test_rescue_rewards_use_ten_fifteen_only_and_preserve_legacy_six_buff(self):
        lua=runtime(debug=False);lua.execute('''p.props.LOTM_CHURCH_STORM_QUEST_6_REWARD_APPLIED=1;
         p.props.LOTM_CHURCH_STORM_QUEST_6_REWARD_KIND='HALF_BLESSING';
         p.props.LOTM_CHURCH_STORM_QUEST_10_REWARD_APPLIED=1;p.props.LOTM_CHURCH_STORM_QUEST_10_REWARD_KIND='ARTIFACT';
         p.props.LOTM_CHURCH_STORM_QUEST_15_REWARD_APPLIED=1;p.props.LOTM_CHURCH_STORM_QUEST_15_REWARD_KIND='HALF_BLESSING';
         p.props.LOTM_CHURCH_STORM_BLESSING_TIER=6;turns.GodBlessings(0);turns.GodBlessings(0)''')
        self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),1)
        self.assertEqual(lua.eval('p.props.LOTM_CHURCH_STORM_BLESSING_TIER'),6)
        self.assertEqual(lua.eval('#p.attachments'),0)

    def test_actual_rescue_world_input_and_fx_request_bound_impact(self):
        lua=god.ui_runtime();lua.execute('rescue=true');phase_api(lua)
        lua.execute('boss=CreateBoss();inputHandler(input(2));confirmation();fire(requests[1].args.OnStart,requests[1].args)')
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'CASTING')
        god.attach_fx(lua);lua.execute('update(4.084)')
        self.assertEqual(lua.eval('#fxRequests'),1)
        self.assertEqual(lua.eval('fxRequests[1].args.OnStart'),'LOTM_Storm_Impact')
        lua.execute('fire(fxRequests[1].args.OnStart,fxRequests[1].args)')
        self.assertEqual(lua.eval('boss:GetDamage()'),20)
        self.assertEqual(lua.eval('instances[1].Frames.file'),'LOTM_GOD_FX_STORM_V4_06.dds')

    def test_mode_mismatch_and_capital_fx_remain_isolated(self):
        lua=runtime();lua.execute('''LOTM_GodBlessings.RecordCapitalFX(p,'FOOL',6);
         LOTM_GodBlessings.RecordCapitalFX(p,'NIGHT',6);
         LOTM_MP_TurnSync.IsRescueModeConfigured=function() return false end;
         fire('LOTM_Storm_Prepare',{ExpectedSerial=0})''')
        self.assertIsNone(lua.eval('p.props.LOTM_GOD_FX_SERIAL'))
        self.assertEqual(lua.eval('p.props.LOTM_STORM_PENDING'),0)

    def test_shared_manifest_bilingual_hint_and_unchanged_phase_body(self):
        root=ET.parse(ROOT/'RedPriestPath.modinfo').getroot()
        actions=[a for a in root.find('InGameActions') if a.attrib['id'].startswith(('LOTM_GOD_BLESS','LOTM_STORM_'))]
        self.assertEqual(len(actions),9)
        self.assertTrue(all(a.get('criteria') in ('LOTM_RP_EXPANSION_2','LOTM_RP_LANGUAGE_EN') for a in actions))
        for language in ('zh_Hans_CN','en_US'):
            text=ET.parse(ROOT/f'Text/Selected/LOTM_GodBlessings_{language}.xml').find(".//*[@Tag='LOC_LOTM_STORM_RESCUE_OUTER_HINT']/Text").text
            self.assertIn('20',text)
        baseline=ROOT.parent/'frozen-baselines/rescue-rc359-resource391'
        block=(baseline/'authorized-deltas/20261007-rescue-storm-damage.lua').read_bytes()
        now=(ROOT/'Scripts/LOTM_RESCUE_Phase10.lua').read_bytes()
        before=(ROOT.parent/'Reports/rc402-rescue-storm-20261007/before/Scripts/LOTM_RESCUE_Phase10.lua').read_bytes()
        self.assertEqual(now.count(block),1)
        self.assertEqual(now.replace(block,b'',1),before)

if __name__=='__main__':unittest.main(verbosity=2)
