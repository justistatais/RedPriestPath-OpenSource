"""UI-only ending routing and hidden sacrifice entry; native rendering remains manual."""
import hashlib
import re
import unittest
import zipfile
from pathlib import Path
from test_rc346_thief_rule_guards import LuaRuntime
from generate_startup_trace import strip_trace

ROOT=Path(__file__).resolve().parents[1]
BASE=r'''
function print() end
function include() end
function Event()
 local callbacks={};return setmetatable({Add=function(f) callbacks[#callbacks+1]=f end},
 {__call=function(_,...) for _,f in ipairs(callbacks) do f(...) end end})
end
function EventsTable() return setmetatable({},{__index=function(t,k) local e=Event();rawset(t,k,e);return e end}) end
Events=EventsTable();GameEvents=EventsTable();LuaEvents=EventsTable()
function Control()
 local c={hidden=false,w=1120,h=940,callbacks={}}
 function c:SetHide(v) self.hidden=v end
 function c:SetSizeX(v) self.w=v end
 function c:SetSizeY(v) self.h=v end
 function c:SetSizeVal(w,h) self.w=w;self.h=h end
 function c:GetSizeX() return self.w end
 function c:GetSizeY() return self.h end
 function c:SetText(v) self.text=v end
 function c:SetTexture(v) self.texture=v end
 function c:SetScrollValue(v) end
 function c:SetDisabled(v) self.disabled=v end
 function c:RegisterCallback(k,f) self.callbacks[k]=f end
 function c:CalculateSize() end
 function c:ReprocessAnchoring() end
 return c
end
Controls=setmetatable({},{__index=function(t,k) local c=Control();rawset(t,k,c);return c end})
ContextPtr={SetHide=function(_,v) contextHidden=v end,SetInputHandler=function(_,f) input=f end,
 BuildInstanceForControl=function(_,name,instance,parent)
  assert(name=='PopupButtonInstance' and parent==Controls.ButtonStack)
  builds=builds+1;instance.Button=Control();endingButton=instance.Button
 end}
Mouse={eLClick=1};Locale={Lookup=function(k,...) return k end}
KeyEvents={KeyUp=1};Keys={VK_ESCAPE=27}
PopupPriority={Current=0,EndGameMenu=100}
UIManager={GetScreenSizeVal=function() return 1920,1080 end,
 QueuePopup=function(_,c,p) priority=p;queued=queued+1 end,
 DequeuePopup=function() dequeued=dequeued+1 end}
builds=0;queued=0;dequeued=0;returned=0;nativeViews=0;rescue=1;win=true;localID=0
LuaEvents.LOTM_Comic_ReturnToSequence.Add(function() returned=returned+1 end)
player={props={LOTM_RP_PATH='PATH_THIEF'}}
function player:GetProperty(k) return self.props[k] end
function player:GetTeam() return 0 end
Players={[0]=player}
Game={GetLocalPlayer=function() return localID end,GetProperty=function(k) if k=='LOTM_RESCUE_MODE' then return rescue end end,
 SetProperty=function() error('UI authoritative write') end,GetWinningTeam=function() return -1 end}
GameConfiguration={GetValue=function() return 1 end,GetStartTurn=function() return 0 end}
MapConfiguration={GetValue=function() return 1 end}
Options={GetUserOption=function() return 1 end,SetUserOption=function() error('manual review must not change acknowledgement') end,SaveOptions=function() end}
function TeamVictoryData() return {IsWinnerLocalPlayer=win,RibbonIcon='NATIVE_RIBBON',VictoryTypeIcon='NATIVE_VICTORY'} end
function View(data) nativeViews=nativeViews+1 end
'''

def source(name):
    s=strip_trace((ROOT/'UI'/name).read_text(encoding='utf-8-sig'))
    return re.sub(r'\s*:(?:number|string|boolean|table)\b','',s)

def runtime(comic=True):
    lua=LuaRuntime(unpack_returned_tuples=True);lua.execute(BASE)
    lua.execute(source('EndGameMenu_LOTM_Redemption.lua'))
    if comic: lua.execute(source('LOTM_RP_ComicViewer.lua'))
    return lua

class EndingUITests(unittest.TestCase):
    def test_normal_mode_blocks_all_comics_without_marking_them_read(self):
        lua=runtime();lua.execute('''rescue=0
        Options.GetUserOption=function() error('normal mode must not access comic acknowledgements') end
        LuaEvents.LOTM_Comic_ShowStart();LuaEvents.LOTM_Comic_ShowReview()
        LuaEvents.LOTM_Comic_ShowEnding('VICTORY');LuaEvents.LOTM_Comic_ShowEnding('DEFEAT')
        Events.TeamVictory(0);Events.TeamVictory(1)
        assert(queued==0 and Controls.ComicImage.texture==nil)
        ''')

    def test_four_paths_both_icons_and_unknown_no_red_fallback(self):
        lua=runtime(False);lua.execute('''
        for path,prefix in pairs({PATH_RED_PRIEST='RP',PATH_PERFECT='PP',PATH_BLACK_EMPEROR='BE',PATH_THIEF='TP'}) do
         player.props.LOTM_RP_PATH=path;local d=TeamVictoryData(0,'VICTORY_CONQUEST')
         assert(d.RibbonIcon=='ICON_UNIT_LOTM_'..prefix..'_PATH_HOLDER' and d.VictoryTypeIcon==d.RibbonIcon)
        end
        player.props.LOTM_RP_PATH='NONE';local d=TeamVictoryData(0,'VICTORY_CONQUEST')
        assert(d.RibbonIcon=='NATIVE_RIBBON' and d.VictoryTypeIcon=='NATIVE_VICTORY')
        player.props.LOTM_RP_PATH='PATH_THIEF';rescue=0;d=TeamVictoryData(0,'VICTORY_CONQUEST')
        assert(d.RibbonIcon=='NATIVE_RIBBON' and d.VictoryTypeIcon=='NATIVE_VICTORY')
        ''')

    def test_button_once_and_repeatable_victory_comic_above_end_game(self):
        lua=runtime();lua.execute('''
        View(TeamVictoryData(0,'VICTORY_CONQUEST'));View(TeamVictoryData(0,'VICTORY_CONQUEST'))
        assert(builds==1 and nativeViews==2 and not endingButton.hidden)
        endingButton.callbacks[1]();assert(Controls.ComicImage.texture=='LOTM_Comic_2-1.dds')
        assert(priority>PopupPriority.EndGameMenu)
        for i=1,8 do Controls.Next.callbacks[1]() end
        assert(dequeued==1 and returned==0)
        endingButton.callbacks[1]();assert(queued==2 and Controls.ComicImage.texture=='LOTM_Comic_2-1.dds')
        Controls.Close.callbacks[1]();assert(dequeued==2 and returned==0)
        ''')

    def test_defeat_routes_two_pages_and_invalid_category_is_ignored(self):
        lua=runtime();lua.execute('''
        win=false;View(TeamVictoryData(1,'VICTORY_CONQUEST'));endingButton.callbacks[1]()
        assert(Controls.ComicImage.texture=='LOTM_Comic_3-1.dds')
        Controls.Next.callbacks[1]();assert(Controls.ComicImage.texture=='LOTM_Comic_3-2.dds')
        Controls.Next.callbacks[1]();assert(returned==0 and dequeued==1)
        LuaEvents.LOTM_Comic_ShowEnding('START');assert(queued==1)
        ''')

    def test_non_rescue_or_no_path_hides_button_and_prologue_still_returns(self):
        lua=runtime();lua.execute('''
        rescue=0;View(TeamVictoryData(0,'VICTORY_CONQUEST'));assert(endingButton.hidden)
        rescue=1;player.props.LOTM_RP_PATH='NONE';View(TeamVictoryData(0,'VICTORY_CONQUEST'));assert(endingButton.hidden)
        LuaEvents.LOTM_Comic_ShowEnding('VICTORY');assert(queued==0)
        player.props.LOTM_RP_PATH='PATH_THIEF';LuaEvents.LOTM_Comic_ShowReview()
        assert(Controls.ComicImage.texture=='LOTM_Comic_1-1.dds' and priority==PopupPriority.Current)
        for i=1,3 do Controls.Next.callbacks[1]() end
        assert(returned==1)
        ''')

    def test_sacrifice_entry_never_registers_or_unhides(self):
        lua=LuaRuntime(unpack_returned_tuples=True);lua.execute(BASE)
        lua.execute(source('LOTM_RESCUE_Sacrifice.lua'))
        lua.execute('''assert(contextHidden and Controls.SacrificeButton.hidden and Controls.SacrificeButton.callbacks[1]==nil)
        Events.UnitSelectionChanged();Events.LocalPlayerTurnBegin();Events.GameCoreEventPublishComplete()
        assert(contextHidden and Controls.SacrificeButton.hidden)''')

    def test_existing_bonus_gameplay_bytes_preserved(self):
        archive=ROOT.parent/'dist/RedPriestPath-0.1.0-rc.358.zip'
        self.assertEqual(hashlib.sha256(archive.read_bytes()).hexdigest(),'0892d8b9d52e5d21dd4add2caee2dd743b84d148f13444e3eb55508618d42f4b')
        with zipfile.ZipFile(archive) as z:
            for name in ('Scripts/LOTM_RESCUE_Phase10.lua','Scripts/LOTM_RESCUE_Phase10A.lua','Gameplay/LOTM_RESCUE_Phase10.sql'):
                self.assertEqual((ROOT/name).read_bytes(),z.read('RedPriestPath/'+name),name)

if __name__=='__main__':unittest.main(verbosity=2)
