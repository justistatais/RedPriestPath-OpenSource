"""Native DB coverage and executed migration contracts; not engine acceptance."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET
from test_rc390_normal_balance import difficulty_runtime, native_copy

ROOT=Path(__file__).resolve().parents[1]
TAG='CLASS_LOTM_CDIFF_MILITARY_V2'
PREFIX='LOTM_CDIFF_MILITARY_V2_'

def army_parents(lua,player):
    return [x for x in lua.eval(f'Players[{player}].attachments').values() if x.startswith(PREFIX)]

def active_amount(c,lua,player,slot,home):
    total=0
    for mid in army_parents(lua,player):
        if not mid.startswith(PREFIX+slot+'_'):
            continue
        resource=c.execute('''select a.Value from Modifiers m
          join RequirementSetRequirements r on r.RequirementSetId=m.OwnerRequirementSetId
          join RequirementArguments a on a.RequirementId=r.RequirementId and a.Name='ResourceType'
          where m.ModifierId=?''',(mid,)).fetchone()[0]
        if lua.eval(f'Players[{player}].resources[GameInfo.Resources["{resource}"].Index]')!=1:
            continue
        child=c.execute("select Value from ModifierArguments where ModifierId=? and Name='ModifierId'",(mid,)).fetchone()[0]
        subject=c.execute('select SubjectRequirementSetId from Modifiers where ModifierId=?',(child,)).fetchone()[0]
        if subject=='LOTM_CDIFF_REQSET_OWN' and not home:
            continue
        total+=int(c.execute("select Value from ModifierArguments where ModifierId=? and Name='Amount'",(child,)).fetchone()[0])
    return total

class CultMilitary(unittest.TestCase):
    def test_real_unit_tag_coverage_excludes_civilian_and_support(self):
        c=native_copy()
        expected={x[0] for x in c.execute("select UnitType from Units where (Combat>0 or RangedCombat>0) and FormationClass not in ('FORMATION_CLASS_CIVILIAN','FORMATION_CLASS_SUPPORT')")}
        matched={x[0] for x in c.execute('select Type from TypeTags where Tag=?',(TAG,))}
        self.assertEqual(matched,expected)
        for unit in ('UNIT_WARRIOR','UNIT_ARCHER','UNIT_HORSEMAN','UNIT_CATAPULT','UNIT_GALLEY','UNIT_FIGHTER','UNIT_BOMBER'):
            self.assertIn(unit,matched)
        for unit in ('UNIT_SETTLER','UNIT_BUILDER','UNIT_MISSIONARY','UNIT_BATTERING_RAM','UNIT_MEDIC'):
            self.assertNotIn(unit,matched)
        self.assertEqual(c.execute("select count(*) from Units join TypeTags on UnitType=Type where Tag='CLASS_ALL_COMBAT_UNITS'").fetchone()[0],0)
        self.assertEqual(c.execute('pragma foreign_key_check').fetchall(),[])
        c.close()

    def test_new_parent_gates_and_legacy_parents_inactive(self):
        c=native_copy()
        rows=c.execute("select ModifierId,OwnerRequirementSetId,SubjectRequirementSetId,Permanent,NewOnly from Modifiers where ModifierType='MODIFIER_PLAYER_UNITS_ATTACH_MODIFIER' and ModifierId like 'LOTM_CDIFF_%'").fetchall()
        self.assertEqual(len(rows),24)
        for mid,owner,subject,permanent,new_only in rows:
            if mid.startswith(PREFIX):
                token=mid[len(PREFIX):].split('_ON__')[0]
                self.assertEqual(owner,'LOTM_CDIFF_GATE_'+token)
                self.assertEqual(subject,'LOTM_CDIFF_REQSET_MILITARY_V2')
            else:
                self.assertEqual(owner,'LOTM_CDIFF_GATE_LEGACY_MILITARY_DISABLED')
            self.assertEqual(permanent,0)
            self.assertEqual(new_only,0)
        c.close()

    def test_saved_rc390_receipt_migrates_only_military_once_and_after_reload(self):
        for network in (False,True):
            lua=difficulty_runtime()
            lua.execute('''configured='INSANE';gameprops.LOTM_CULT_DIFFICULTY='INSANE';
              gameprops.LOTM_CULT_STATE_VERSION=4;
              p=Players[1];p.props.LOTM_CDIFF_APPLIED_COMMON='COMMON_INSANE_T1';
              p.props.LOTM_CDIFF_ATTACHED_COMMON_INSANE_T1=1;
              p.props.LOTM_CDIFF_APPLIED_DEMONESS='DEMONESS_INSANE_T1';
              p.props.LOTM_CDIFF_ATTACHED_DEMONESS_INSANE_T1=1;
              p.props.LOTM_CDIFF_APPLIED_CHAINED='NONE';
              p.resources[GameInfo.Resources.RESOURCE_LOTM_CDIFF_COMMON_INSANE_T1.Index]=1;
              p.resources[GameInfo.Resources.RESOURCE_LOTM_CDIFF_DEMONESS_INSANE_T1.Index]=1;''')
            lua.globals().network=network
            lua.execute('LOTM_AI_Cult_Difficulty.Reconcile();LOTM_AI_Cult_Difficulty.Reconcile()')
            self.assertEqual(list(lua.eval('Players[1].attachments').values()),[PREFIX+'COMMON_INSANE_T1_ON__COMBAT'])
            self.assertEqual(lua.eval('Players[1].props.LOTM_CDIFF_MILITARY_V2_ATTACHED_COMMON_INSANE_T1'),1)
            self.assertEqual(lua.eval('scans'),0)
            # Clear local caches/register state as a Lua-context reload does;
            # persistent receipts still prohibit an extra native attachment.
            lua.execute((ROOT/'Scripts/LOTM_AI_Cult_Difficulty.lua').read_text(encoding='utf-8'))
            lua.execute('LOTM_AI_Cult_Difficulty.Reconcile()')
            self.assertEqual(list(lua.eval('Players[1].attachments').values()),[PREFIX+'COMMON_INSANE_T1_ON__COMBAT'])
            self.assertEqual(lua.eval('Players[1].gold'),0)

    def test_stage_strength_replaces_and_chained_home_bonus_adds(self):
        c=native_copy()
        for difficulty,common,home in [('HARD',[2,4,6],[2,3,4]),('INSANE',[4,7,10],[3,5,7])]:
            lua=difficulty_runtime();lua.execute(f"configured='{difficulty}';LOTM_AI_Cult_Difficulty.Initialize()")
            for tier in range(1,4):
                lua.execute(f'tiers={{DEMONESS={tier},HANGED_MAN={tier},CHAINED={tier}}};LOTM_AI_Cult_Difficulty.Reconcile();LOTM_AI_Cult_Difficulty.Reconcile()')
                self.assertEqual(active_amount(c,lua,3,'COMMON',True),common[tier-1])
                self.assertEqual(active_amount(c,lua,3,'CHAINED',True),home[tier-1])
                self.assertEqual(active_amount(c,lua,3,'CHAINED',False),0)
                self.assertEqual(active_amount(c,lua,3,'COMMON',True)+active_amount(c,lua,3,'CHAINED',True),common[tier-1]+home[tier-1])
            self.assertEqual(len(army_parents(lua,3)),6)
            lua.execute("Players[3].props.LOTM_CULT_PATH='DEMONESS';LOTM_AI_Cult_Difficulty.Reconcile()")
            self.assertEqual(active_amount(c,lua,3,'CHAINED',True),0)
            lua.execute('Players[3].human=true;LOTM_AI_Cult_Difficulty.Reconcile()')
            self.assertEqual(active_amount(c,lua,3,'COMMON',True),0)
            self.assertEqual(lua.eval('scans'),0)
        c.close()

    def test_missing_v2_definition_defers_receipt_and_can_retry(self):
        lua=difficulty_runtime();lua.execute('''configured='INSANE';LOTM_AI_Cult_Difficulty.Initialize();
          p=Players[1];p.props.LOTM_CDIFF_APPLIED_COMMON='COMMON_INSANE_T1';
          p.props.LOTM_CDIFF_ATTACHED_COMMON_INSANE_T1=1;
          p.props.LOTM_CDIFF_APPLIED_DEMONESS='DEMONESS_INSANE_T1';
          p.props.LOTM_CDIFF_ATTACHED_DEMONESS_INSANE_T1=1;
          p.props.LOTM_CDIFF_APPLIED_CHAINED='NONE';
          kept={};for row in GameInfo.Modifiers() do
            if row.ModifierId:find('LOTM_CDIFF_MILITARY_V2_',1,true)~=1 then kept[#kept+1]=row end
          end;GameInfo.Modifiers=Rows(kept);LOTM_AI_Cult_Difficulty.Reconcile();''')
        self.assertIsNone(lua.eval('Players[1].props.LOTM_CDIFF_MILITARY_V2_ATTACHED_COMMON_INSANE_T1'))
        self.assertEqual(army_parents(lua,1),[])
        # A next context with native V2 definitions available retries normally.
        c=native_copy();ids=[x[0] for x in c.execute("select ModifierId from Modifiers where ModifierId like 'LOTM_CDIFF_%'")];c.close()
        lua.execute('GameInfo.Modifiers=Rows({'+','.join('{ModifierId="'+x+'"}' for x in ids)+'})')
        lua.execute((ROOT/'Scripts/LOTM_AI_Cult_Difficulty.lua').read_text(encoding='utf-8'))
        lua.execute('LOTM_AI_Cult_Difficulty.Reconcile()')
        self.assertEqual(army_parents(lua,1),[PREFIX+'COMMON_INSANE_T1_ON__COMBAT'])

    def test_rescue_and_easy_do_not_grant_military(self):
        for condition in ('rescue=true','configured="EASY"'):
            lua=difficulty_runtime();lua.execute(condition+';LOTM_AI_Cult_Difficulty.Initialize();LOTM_AI_Cult_Difficulty.Register();LOTM_AI_Cult_Difficulty.Reconcile()')
            self.assertEqual(army_parents(lua,1),[])
            self.assertEqual(lua.eval('scans'),0)
        root=ET.parse(ROOT/'RedPriestPath.modinfo').getroot()
        action=root.find("InGameActions/UpdateDatabase[@id='LOTM_NORMAL_BALANCE_DATABASE']")
        self.assertEqual(action.get('criteria'),'LOTM_RP_NORMAL_MODE')
        self.assertGreaterEqual(int(action.findtext('Properties/LoadOrder')),10000)

if __name__=='__main__':
    unittest.main(verbosity=2)
