#!/usr/bin/env python3
"""Run the real read-only HUD against layout/event stubs; not in-game visual QA."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
try:
    from lupa.lua51 import LuaRuntime
except ImportError:
    sys.path.insert(0, str(ROOT.parent / ".tmp/refactor-rc340-python"))
    from lupa.lua51 import LuaRuntime
from generate_startup_trace import strip_trace

HARNESS = r'''
screenX=1920; screenY=1080; boundsReads=0; lookups=0; rescue=true;
props={}; logs={}; controlsByPath={};
function Event()
    local e={handlers={}};
    e.Add=function(fn) e.handlers[#e.handlers+1]=fn; end;
    e.Fire=function(...) for _,fn in ipairs(e.handlers) do fn(...); end; end;
    return e;
end
Events=setmetatable({}, {__index=function(t,k) local e=Event(); rawset(t,k,e); return e; end});
LuaEvents=setmetatable({}, {__index=function(t,k) local e=Event(); rawset(t,k,e); return e; end});
SystemUpdateUI={ScreenResize=9}; InterfaceModeTypes={VIEW_MODAL_LENS=14};
function Control()
    local c={hidden=false,x=0,y=0,width=500,height=79};
    function c:SetSizeX(v) self.width=v; end
    function c:ReprocessAnchoring() self.anchors=(self.anchors or 0)+1; end
    function c:SetOffsetX(v) self.x=v; end
    function c:SetOffsetY(v) self.y=v; end
    function c:SetHide(v) self.hidden=v; end
    function c:IsHidden() return self.hidden; end
    function c:IsVisible() return not self.hidden; end
    function c:SetText(v) self.text=v; end
    function c:SetToolTipString(v) self.tooltip=v; end
    function c:GetScreenOffset() boundsReads=boundsReads+1; return self.x,self.y; end
    function c:GetSizeVal() return self.width,self.height; end
    return c;
end
Controls=setmetatable({}, {__index=function(t,k) local c=Control(); rawset(t,k,c); return c; end});
ContextPtr=Control(); refreshRequests=0;
function ContextPtr:SetRefreshHandler(fn) self.refreshHandler=fn; end
function ContextPtr:RequestRefresh() self.refreshPending=true; refreshRequests=refreshRequests+1; end
function ContextPtr:ClearRequestRefresh() self.refreshPending=false; end
function FlushRefresh() if ContextPtr.refreshPending then ContextPtr.refreshHandler(); end; end
function ContextPtr:LookUpControl(path) lookups=lookups+1; return controlsByPath[path]; end
function SetBar(x,y,w,h)
    local stack=Control(); stack.x=x; stack.y=y; stack.width=w; stack.height=h;
    controlsByPath['/InGame/LaunchBar/ButtonStack']=stack;
    local back=Control(); back.x=x-63; back.y=y-32; back.width=w+116; back.height=77;
    controlsByPath['/InGame/LaunchBar/LaunchBacking']=back;
end
SetBar(0,28,436,51);
UIManager={GetScreenSizeVal=function() return screenX,screenY; end};
GameInfo={Resources={}};
GameConfiguration={GetValue=function() return rescue; end};
Game={GetProperty=function(k) return props[k]; end, GetLocalPlayer=function() return 0; end,
      SetProperty=function() error('read-only HUD wrote game state'); end};
PlayerConfigurations={};
Locale={Lookup=function(k,...) return k; end};
print=function(line) logs[#logs+1]=line; end;
'''

class PurificationLayoutTests(unittest.TestCase):
    def runtime(self, setup=""):
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.execute(HARNESS)
        lua.execute(setup)
        lua.execute(strip_trace((ROOT / 'UI/LOTM_RESCUE_Purification.lua').read_text(encoding='utf-8-sig')))
        return lua

    def test_user_screenshot_restores_top_center(self):
        lua=self.runtime()
        self.assertEqual(500,lua.eval('Controls.Root.width'))
        self.assertEqual(710,lua.eval('Controls.Root.x'))
        self.assertEqual(1,lua.eval('Controls.Root.anchors'))
        self.assertEqual(31,lua.eval('Controls.Root.y'))
        self.assertIn('Anchor="L,T" Offset="0,31"', (ROOT/'UI/LOTM_RESCUE_Purification.xml').read_text())

    def test_resize_and_added_buttons_keep_viewport_top_center(self):
        lua=self.runtime()
        lua.execute('SetBar(0,28,730,51); LuaEvents.LaunchBar_Resize.Fire(730)')
        self.assertEqual(31,lua.eval('Controls.Root.y'))
        lua.execute('SetBar(0,28,436,51); LuaEvents.LaunchBar_Resize.Fire(436)')
        self.assertEqual(31,lua.eval('Controls.Root.y'))
        lua.execute('screenX=1280; screenY=720; Events.SystemUpdateUI.Fire(9); FlushRefresh()')
        self.assertEqual(400,lua.eval('Controls.Root.width'))
        self.assertEqual(440,lua.eval('Controls.Root.x'))
        self.assertEqual(31,lua.eval('Controls.Root.y'))
        lua.execute('screenX=2560; screenY=1440; Events.SystemUpdateUI.Fire(9); FlushRefresh()')
        self.assertEqual(31,lua.eval('Controls.Root.y'))

    def test_publish_and_unchanged_launch_width_do_not_query_bounds(self):
        lua=self.runtime()
        lua.execute('LuaEvents.LaunchBar_Resize.Fire(436); before=boundsReads; oldLookups=lookups')
        lua.execute('for i=1,1000 do Events.GameCoreEventPublishComplete.Fire(); LuaEvents.LaunchBar_Resize.Fire(436); Events.SystemUpdateUI.Fire(1); end')
        self.assertEqual(lua.eval('before'),lua.eval('boundsReads'))
        self.assertEqual(lua.eval('oldLookups'),lua.eval('lookups'))

    def test_missing_launchbar_cannot_move_hud_down(self):
        for width,height,expected in [(1920,1080,31),(1280,720,31)]:
            lua=self.runtime(f'controlsByPath={{}}; screenX={width}; screenY={height}')
            self.assertEqual(expected,lua.eval('Controls.Root.y'))
            lua.execute('SetBar(0,28,260,51); Events.LoadGameViewStateDone.Fire()')
            self.assertEqual(31,lua.eval('Controls.Root.y'))

    def test_hidden_controls_do_not_force_unneeded_downward_offset(self):
        lua=self.runtime("SetBar(0,28,800,51); for _,c in pairs(controlsByPath) do c.hidden=true; end")
        self.assertEqual(31,lua.eval('Controls.Root.y'))
        self.assertEqual(0,lua.eval('boundsReads'))

    def test_low_resolution_panels_cannot_move_hud_down(self):
        panels=[('CivicsTree_OpenCivicsTree','CivicsTree_CloseCivicsTree'),
                ('Government_OpenGovernment','Government_CloseGovernment'),
                ('GovernorPanel_Opened','GovernorPanel_Closed'),
                ('GreatPeople_OpenGreatPeople','GreatPeople_CloseGreatPeople'),
                ('GreatWorks_OpenGreatWorks','GreatWorks_CloseGreatWorks'),
                ('HistoricMoments_Opened','HistoricMoments_Closed'),
                ('Religion_OpenReligion','Religion_CloseReligion'),
                ('PantheonChooser_OpenReligion','PantheonChooser_CloseReligion'),
                ('TechTree_OpenTechTree','TechTree_CloseTechTree'),
                ('ClimateScreen_Opened','ClimateScreen_Closed')]
        for opened,closed in panels:
            with self.subTest(panel=opened):
                lua=self.runtime('screenX=1280; screenY=720')
                self.assertEqual(31,lua.eval('Controls.Root.y'))
                # Deliberately invoke the HUD's subscriber before the native
                # one moves LaunchContainer; the deferred handler must see it.
                lua.execute(f'LuaEvents.{opened}.Fire(); SetBar(0,-2,436,51); FlushRefresh()')
                self.assertEqual(31,lua.eval('Controls.Root.y'))
                lua.execute('Events.SystemUpdateUI.Fire(9); FlushRefresh(); LuaEvents.LaunchBar_Resize.Fire(436)')
                self.assertEqual(31,lua.eval('Controls.Root.y'))
                lua.execute(f'LuaEvents.{closed}.Fire(); SetBar(0,28,436,51); FlushRefresh()')
                self.assertEqual(31,lua.eval('Controls.Root.y'))
                self.assertFalse(lua.eval('ContextPtr.refreshPending'))

    def test_modal_lens_visibility_preserves_top_position(self):
        lua=self.runtime('screenX=1280; screenY=720')
        lua.execute('Events.InterfaceModeChanged.Fire(1,14); for _,c in pairs(controlsByPath) do c.hidden=true; end; FlushRefresh()')
        self.assertEqual(31,lua.eval('Controls.Root.y'))
        lua.execute('Events.SystemUpdateUI.Fire(9); FlushRefresh()')
        lua.execute('Events.InterfaceModeChanged.Fire(14,1); for _,c in pairs(controlsByPath) do c.hidden=false; end; FlushRefresh()')
        self.assertEqual(31,lua.eval('Controls.Root.y'))
        lua.execute('before=boundsReads; Events.InterfaceModeChanged.Fire(1,2); FlushRefresh()')
        self.assertEqual(lua.eval('before'),lua.eval('boundsReads'))

    def test_layout_events_coalesce_without_continuous_refresh(self):
        lua=self.runtime('screenX=1280; screenY=720')
        lua.execute('before=boundsReads; for i=1,1000 do LuaEvents.TechTree_OpenTechTree.Fire(); LuaEvents.TechTree_CloseTechTree.Fire(); end')
        self.assertEqual(1,lua.eval('refreshRequests'))
        self.assertEqual(lua.eval('before'),lua.eval('boundsReads'))
        lua.execute('FlushRefresh(); after=boundsReads; for i=1,1000 do FlushRefresh(); end')
        self.assertEqual(lua.eval('after'),lua.eval('boundsReads'))
        self.assertFalse(lua.eval('ContextPtr.refreshPending'))

    def test_mode_and_descent_gates_remain_read_only(self):
        for setup in ['rescue=false', 'props.LOTM_RESCUE_PHASE10_DESCENT_TRIGGERED=true']:
            lua=self.runtime(setup)
            self.assertTrue(lua.eval('ContextPtr.hidden and Controls.Root.hidden'))
            self.assertEqual(0,lua.eval('boundsReads'))
            lua.execute('Events.GameCoreEventPublishComplete.Fire(); Events.SystemUpdateUI.Fire(9); FlushRefresh()')
            self.assertTrue(lua.eval('ContextPtr.hidden and Controls.Root.hidden'))
        for value in ['true','1','"1"']:
            lua=self.runtime('rescue='+value)
            self.assertFalse(lua.eval('Controls.Root.hidden'))
        lua=self.runtime('rescue=false; GameInfo.Resources.RESOURCE_LOTM_RESCUE_ALLY_BANNER={}')
        self.assertFalse(lua.eval('Controls.Root.hidden'))

    def test_layout_events_keep_values_and_markers_consistent(self):
        lua=self.runtime('props.GLOBAL_PURIFICATION=1500')
        self.assertEqual(236,lua.eval('Controls.ProgressFill.width'))
        lua.execute('screenX=1280; Events.SystemUpdateUI.Fire(9); FlushRefresh()')
        self.assertEqual(186,lua.eval('Controls.ProgressFill.width'))
        self.assertEqual(199,lua.eval('Controls.Mark1500.x'))
        self.assertEqual('1500',lua.eval('Controls.Mark1500Label.text'))
        lua.execute('props.GLOBAL_PURIFICATION=0; Events.GameCoreEventPublishComplete.Fire()')
        self.assertTrue(lua.eval('Controls.ProgressFill.hidden'))

if __name__ == '__main__':
    unittest.main(verbosity=2)
