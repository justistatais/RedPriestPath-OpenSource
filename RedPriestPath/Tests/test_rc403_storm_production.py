"""Finite Lua protocol/upgrade checks. No native performance or multiplayer claim."""
from pathlib import Path
import unittest
import sqlite3
import xml.etree.ElementTree as ET

import test_rc392_god_blessings as god
from generate_startup_trace import strip_trace
from generate_gameplay_bundle import lua_function_span

ROOT=Path(__file__).resolve().parents[1]

def legacy_bundle_api(lua):
    source=strip_trace((ROOT/'Scripts/LOTM_WORLD_Churches.lua').read_text(encoding='utf-8'))
    start,end=lua_function_span(source,'LOTM_WORLD_Churches.RemoveLegacyStormBlessing')
    lua.execute('LOTM_WORLD_Churches={};'+source[start:end])
    return lua

def ui(rescue=False):
    lua=god.runtime(rescue=rescue,debug=False)
    lua.execute(r'''
      function control() return {SetHide=function(s,v) s.hidden=v end,SetText=function(s,v) s.text=v end,
       SetDisabled=function(s,v) s.disabled=v end,SetAlpha=function() end,SetOffsetX=function(s,v) s.x=v end,
       SetOffsetY=function(s,v) s.y=v end,ReprocessAnchoring=function() end,SetToolTipString=function(s,v) s.tooltip=v end,
       RegisterCallback=function(s,e,f) s.click=f end} end;
      Controls={Root=control(),Count=control(),StormButton=control(),StormIcon=control(),TargetHint=control(),Cancel=control()};
      mode=1;cursor=6;requests={};preview={};nativeCalls=0;opened=0;screenX=1920;screenY=1080;
      Game.GetLocalPlayer=function() return 0 end;
      ContextPtr={SetHide=function(s,v) s.hidden=v end,LookUpControl=function() return nil end,
       SetInputHandler=function(s,f) inputHandler=f end};
      UIManager={GetScreenSizeVal=function() return screenX,screenY end,SetUICursor=function() end};
      InterfaceModeTypes={SELECTION=1,WMD_STRIKE=2,VIEW_MODAL_LENS=3};
      PlayerOperations={EXECUTE_SCRIPT=55};Mouse={eLClick=1};SystemUpdateUI={ScreenResize=44};
      MouseEvents={LButtonDown=1,LButtonUp=2,RButtonUp=3,PointerDown=4,PointerUp=5,MouseMove=6};
      KeyEvents={KeyUp=7};Keys={VK_ESCAPE=27};CursorTypes={NORMAL=0,RANGE_ATTACK=1};WarTypes={SURPRISE_WAR=1};
      UI={GetInterfaceMode=function() return mode end,SetInterfaceMode=function(v)
        local old=mode;mode=v;if old~=v then Events.InterfaceModeChanged(old,v) end end,
       GetCursorPlotID=function() return cursor end,RequestPlayerOperation=function(id,op,args)
        assert(op==55);requests[#requests+1]={id=id,args=args} end};
      UILens={SetActive=function() end,CreateLensLayerHash=function() return 9 end,
       ToggleLayerOff=function() end,ClearLayerHexes=function() preview={} end,ToggleLayerOn=function() end,
       SetLayerHexesArea=function(layer,owner,list) preview=list end};
      Events=UIEventTable();LuaEvents=UIEventTable({WorldInput_ConfirmWarDialog=function(id,list,war,fn) confirmation=fn end});
      Locale={Lookup=function(k) return k end};PopupDialogInGame={};
      function PopupDialogInGame:new() return {AddText=function() end,AddCancelButton=function() end,
       AddConfirmButton=function(s,label,f) confirmation=f end,Open=function() opened=opened+1 end} end;
      function OnInputHandler() nativeCalls=nativeCalls+1;return 'native' end;
      function input(message) return {GetMessageType=function() return message end,GetKey=function() return 27 end} end;
      function dispatch(index) local r=requests[index];fire(r.args.OnStart,r.args);Events.GameCoreEventPublishComplete() end;
    ''')
    lua.execute(strip_trace((ROOT/'UI/LOTM_StormWorldInput.lua').read_text(encoding='utf-8')))
    lua.execute(strip_trace((ROOT/'UI/LOTM_StormBlessing.lua').read_text(encoding='utf-8')))
    return lua

class StormProduction(unittest.TestCase):
    def test_release_has_no_unlimited_casts_or_debug_descriptions(self):
        lua=god.runtime(rescue=True,debug=False)
        lua.execute("fire('LOTM_Storm_Fire',{ExpectedSerial=0,CastSerial=1,PlotIndex=6})")
        self.assertEqual(lua.eval('gameprops.LOTM_STORM_DEBUG_UNLIMITED'),0)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'NO_CHARGE')
        self.assertIsNone(lua.eval('p.props.LOTM_GOD_FX_SERIAL'))
        for language in ('zh_Hans_CN','en_US'):
            source=(ROOT/f'Text/Selected/LOTM_GodBlessings_{language}.xml').read_text(encoding='utf-8')
            self.assertNotIn('DEBUG_',source)
            self.assertNotIn('无限',source)
            self.assertNotIn('unlimited',source.lower())

    def test_rescue_full_half_ten_fifteen_each_grants_one_without_buff(self):
        for tier in (10,15):
            for strength in ('FULL','HALF'):
                lua=god.runtime(rescue=True)
                apply=god.church_function(lua,'ApplyBlessing','ArtifactName')
                self.assertTrue(apply(lua.globals().p,'STORM',tier,strength))
                self.assertTrue(apply(lua.globals().p,'STORM',tier,strength))
                self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),1)
                self.assertEqual(lua.eval('#p.attachments'),0)
                self.assertIsNone(lua.eval('p.props.LOTM_CHURCH_STORM_BLESSING_UNTIL'))
                lua.execute('turn=100;turns.GodBlessings(0)')
                self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),1)

    def test_no_repeat_grant_after_spend_reload_and_reward_reconcile(self):
        lua=god.runtime(rescue=True)
        lua.execute("p.props.LOTM_CHURCH_STORM_QUEST_10_REWARD_KIND='FULL_BLESSING';p.props.LOTM_CHURCH_STORM_QUEST_10_REWARD_APPLIED=1;turns.GodBlessings(0)")
        lua.execute("fire('LOTM_Storm_Fire',{ExpectedSerial=0,CastSerial=1,PlotIndex=6});impact()")
        self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),0)
        lua.execute(god.blessing_source(False));lua.execute('turns.GodBlessings(0)')
        self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),0)

    def test_active_legacy_buff_off_once_and_existing_charge_not_reissued(self):
        for granted,spent,expected in ((False,False,1),(True,False,1),(True,True,0)):
            lua=legacy_bundle_api(god.runtime(rescue=True))
            lua.execute("p.props.LOTM_RESCUE_STORM_SKILL_VERSION=nil;p.props.LOTM_CHURCH_STORM_BLESSING_TIER=10;p.props.LOTM_CHURCH_STORM_BLESSING_STRENGTH='FULL';p.props.LOTM_CHURCH_STORM_BLESSING_UNTIL=15;p.props.LOTM_WORLD_PLAYER_TURN=5")
            if granted:lua.execute("LOTM_GodBlessings.GrantStorm(p,10,'FULL')")
            if spent:lua.execute('p.props.LOTM_STORM_CHARGES=0')
            lua.execute('turns.GodBlessings(0);turns.GodBlessings(0)')
            lua.execute(god.blessing_source(False))
            self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),expected)
            self.assertEqual(list(lua.eval('p.attachments').values()),['LOTM_CHURCH_STORM_BLESS_10_FULL_OFF'])
            self.assertEqual(lua.eval('p.props.LOTM_CHURCH_STORM_BLESSING_TIER'),0)

    def test_expired_unrecorded_buff_removed_without_free_charge(self):
        lua=legacy_bundle_api(god.runtime(rescue=True))
        lua.execute("p.props.LOTM_RESCUE_STORM_SKILL_VERSION=nil;p.props.LOTM_CHURCH_STORM_BLESSING_TIER=15;p.props.LOTM_CHURCH_STORM_BLESSING_STRENGTH='HALF';p.props.LOTM_CHURCH_STORM_BLESSING_UNTIL=4;p.props.LOTM_WORLD_PLAYER_TURN=5;turns.GodBlessings(0)")
        self.assertIsNone(lua.eval('p.props.LOTM_STORM_CHARGES'))
        self.assertEqual(lua.eval('#p.attachments'),1)

    def test_real_off_bundle_expands_database_members_and_migration_waits_for_it(self):
        with sqlite3.connect(f'file:{god.CACHE.as_posix()}?mode=ro',uri=True) as db:
            names=[r[0] for r in db.execute("SELECT ModifierId FROM Modifiers WHERE ModifierId LIKE 'LOTM_CHURCH_STORM_BLESS_10_FULL_OFF__%' ORDER BY ModifierId")]
        self.assertGreater(len(names),1)
        lua=legacy_bundle_api(god.runtime(rescue=True))
        rows=lua.table_from([lua.table_from({'ModifierId':name}) for name in names])
        lua.globals().modifierRows=rows
        lua.execute('''GameInfo.Modifiers=setmetatable({}, {__call=function()
          local i=0;return function() i=i+1;return modifierRows[i] end end});
          function p:AttachModifierByID(id) self.attachments[#self.attachments+1]=id end;
          p.props.LOTM_RESCUE_STORM_SKILL_VERSION=nil;p.props.LOTM_CHURCH_STORM_BLESSING_TIER=10;
          p.props.LOTM_CHURCH_STORM_BLESSING_STRENGTH='FULL';p.props.LOTM_CHURCH_STORM_BLESSING_UNTIL=20;
        ''')
        source=strip_trace((ROOT/'Scripts/LOTM_WORLD_Churches.lua').read_text(encoding='utf-8'))
        start,end=lua_function_span(source,'Attach')
        lua.globals().Attach=lua.execute(source[start:end]+'\nreturn Attach')
        lua.execute('turns.GodBlessings(0);turns.GodBlessings(0)')
        self.assertEqual(list(lua.eval('p.attachments').values()),names)
        lua=god.runtime(rescue=True)
        lua.execute("p.props.LOTM_RESCUE_STORM_SKILL_VERSION=nil;p.props.LOTM_CHURCH_STORM_BLESSING_TIER=10;p.props.LOTM_CHURCH_STORM_BLESSING_STRENGTH='FULL';turns.GodBlessings(0)")
        self.assertIsNone(lua.eval('p.props.LOTM_RESCUE_STORM_SKILL_VERSION'))
        self.assertEqual(lua.eval('p.props.LOTM_CHURCH_STORM_BLESSING_TIER'),10)

    def test_large_history_aim_and_cancel_need_no_operation_or_scan(self):
        for rescue in (False,True):
            lua=ui(rescue)
            lua.execute("LOTM_GodBlessings.GrantStorm(p,10,'FULL');for i=1,20000 do p.props['OLD_RECORD_'..i]=i end;Events.GameCoreEventPublishComplete();p.GetCities=function() error('no city scan') end;p.GetUnits=function() error('no unit scan') end;Map.GetPlotCount=function() error('no map scan') end;Controls.StormButton.click();inputHandler(input(6))")
            self.assertEqual(lua.eval('mode'),3)
            self.assertFalse(lua.eval('Controls.TargetHint.hidden'))
            self.assertEqual(lua.eval('#requests'),0)
            self.assertEqual(lua.eval('N(p,"LOTM_STORM_PENDING",0)'),0)
            self.assertEqual(lua.eval('#preview'),3)
            lua.execute('Controls.Cancel.click()')
            self.assertEqual(lua.eval('mode'),1)
            self.assertEqual(lua.eval('#requests'),0)
            self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),1)

    def test_confirm_is_one_operation_deduplicated_and_spends_at_impact(self):
        for rescue in (False,True):
            lua=ui(rescue)
            lua.execute("LOTM_GodBlessings.GrantStorm(p,10,'FULL');Events.GameCoreEventPublishComplete();Controls.StormButton.click();inputHandler(input(2));confirmation();confirmation();Controls.StormButton.click()")
            self.assertEqual(lua.eval('#requests'),1)
            self.assertEqual(lua.eval('requests[1].args.ExpectedSerial'),0)
            self.assertEqual(lua.eval('requests[1].args.CastSerial'),1)
            self.assertTrue(lua.eval('Controls.StormButton.disabled'))
            lua.execute('dispatch(1);dispatch(1)')
            self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'CASTING')
            self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),1)
            self.assertEqual(lua.eval('p.props.LOTM_GOD_FX_SERIAL'),1)
            lua.execute('impact();impact();dispatch(1)')
            self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),0)
            self.assertEqual(lua.eval('p.props.LOTM_GOD_FX_SERIAL'),1)
            self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'FIRED')

    def test_old_popup_cancel_reaim_turn_end_or_ownership_change_cannot_fire(self):
        for action in ('Controls.Cancel.click();Controls.StormButton.click()',
                       'active=false', 'turn=11', 'Events.LocalPlayerChanged()'):
            lua=ui(True)
            lua.execute("LOTM_GodBlessings.GrantStorm(p,10,'FULL');Events.GameCoreEventPublishComplete();Controls.StormButton.click();inputHandler(input(2));old=confirmation;"+action+';old()')
            self.assertEqual(lua.eval('#requests'),0)
            self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),1)

    def test_queued_confirmation_revalidates_charge_turn_visibility_and_serial(self):
        for setup,result in (('p.props.LOTM_STORM_CHARGES=0','NO_CHARGE'),('active=false','NOT_YOUR_TURN'),
                             ('target.x=12','NO_TARGETS'),('p.props.LOTM_STORM_CAST_SERIAL=1','STALE_REQUEST'),('turn=11','STALE_REQUEST')):
            lua=ui(True)
            lua.execute("LOTM_GodBlessings.GrantStorm(p,10,'FULL');Events.GameCoreEventPublishComplete();Controls.StormButton.click();inputHandler(input(2));confirmation();"+setup+';dispatch(1)')
            self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),result)
            self.assertIsNone(lua.eval('p.props.LOTM_GOD_FX_SERIAL'))

    def test_legacy_test_aim_cancelled_but_accepted_windup_can_finish(self):
        lua=god.runtime(rescue=True,debug=True)
        lua.execute("fire('LOTM_Storm_Prepare',{ExpectedSerial=0})")
        lua.execute(god.blessing_source(False))
        self.assertEqual(lua.eval('p.props.LOTM_STORM_PENDING'),0)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'CANCELLED')
        lua=god.runtime(rescue=True,debug=True)
        lua.execute('cast()')
        lua.execute("fire('LOTM_Storm_Prepare',{ExpectedSerial=1});fire('LOTM_Storm_Fire',{CastSerial=2,PlotIndex=6})")
        lua.execute(god.blessing_source(False));lua.execute('impact();impact()')
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'FIRED')
        self.assertEqual(lua.eval('p.props.LOTM_STORM_SETTLED_SERIAL'),2)
        lua.execute("fire('LOTM_Storm_Fire',{ExpectedSerial=2,CastSerial=3,PlotIndex=6})")
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'NO_CHARGE')

    def test_cancel_layout_and_production_charge_panel(self):
        root=ET.parse(ROOT/'UI/LOTM_StormBlessing.xml').getroot()
        self.assertIsNone(root.find(".//*[@ID='HintText']"))
        button=root.find(".//*[@ID='Cancel']")
        self.assertEqual(button.get('Size'),'280,56')
        self.assertEqual(button.find('Label').get('Style'),'FontNormal24')
        panel=strip_trace((ROOT/'UI/LOTM_WORLD_ChurchPanel.lua').read_text(encoding='utf-8'))
        start=panel.index('if current=="STORM"')
        self.assertNotIn('LOTM_RESCUE_MODE',panel[start:panel.index('\n end',start)])

if __name__=='__main__':unittest.main(verbosity=2)
