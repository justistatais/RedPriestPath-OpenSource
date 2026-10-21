"""Direct-impact lifecycle, damage endpoints and actual UI source contracts.

Lua substitutes exercise the protocol only; they do not certify Civ VI damage,
fallout, rendering, saving or multiplayer synchronization.
"""
from pathlib import Path
import os, re, sqlite3, sys, unittest, xml.etree.ElementTree as ET
from PIL import Image
from generate_startup_trace import strip_trace
from test_rc346_thief_rule_guards import LuaRuntime
from validate_ui_compatibility import user_interface_context_failures
ROOT=Path(__file__).resolve().parents[1]
CACHE=(Path(sys.argv.pop(1)) if len(sys.argv)>1 and not sys.argv[1].startswith('-')
       else Path.home()/"AppData/Local/Firaxis Games/Sid Meier's Civilization VI/Cache/DebugGameplay.sqlite")
BASE=r'''
function print() end
function include() end
turn=10; rescue=false; failInit=false; failChange=false; failOrigin=false; active=true;
stats={created=0,killed=0,weaponChanges=0,improvementChanges=0}; units={}; handlers={}; turns={};
function UIEvent()
 local callbacks={};return setmetatable({Add=function(f) callbacks[#callbacks+1]=f end},
 {__call=function(_,...) for _,f in ipairs(callbacks) do f(...) end end});
end;
function UIEventTable(entries) return setmetatable(entries or {},{__index=function(t,k) local e=UIEvent();rawset(t,k,e);return e end});end;
LuaEvents=UIEventTable();
LOTM_WORLD_Churches={};
gameprops={};Game={GetCurrentGameTurn=function() return turn end,GetProperty=function(k) if k=='LOTM_RESCUE_MODE' then return rescue and 1 or 0 end;return gameprops[k] end,SetProperty=function(k,v) gameprops[k]=v end};
GameInfo={WMDs={WMD_LOTM_LIGHTNING_STORM={Index=2}},Units={UNIT_LOTM_STORM_MANIFESTATION={Index=99}},Improvements={IMPROVEMENT_MISSILE_SILO={Index=101}}};
GameConfiguration={GetValue=function() return rescue and 1 or 0 end};
GameEvents=setmetatable({}, {__index=function(t,k)
 local e={Add=function(f) handlers[k]=f end};rawset(t,k,e);return e end});
LOTM_MP_TurnSync={IsRescueModeConfigured=function() return rescue end,
 Add=function(f,k) turns[k]=f end,AddSynchronized=function(f,k) turns[k]=f end,RunStartup=function(f,k) f() end};
PlayerManager={GetAliveMajorIDs=function() return {0} end};
function makeplot(index,x,y,owner,isCity)
 local o={index=index,x=x,y=y,owner=owner,improvement=-1,feature=-1,resource=-1};
 function o:GetIndex() return self.index end;function o:GetX() return self.x end;function o:GetY() return self.y end;
 function o:GetOwner() return self.owner end;function o:IsCity() return isCity end;
 function o:IsWater() return false end;function o:IsImpassable() return false end;
 function o:GetDistrictType() return isCity and 0 or -1 end;
 function o:GetImprovementType() return self.improvement end;function o:IsImprovementPillaged() return false end;
 function o:GetFeatureType() return self.feature end;function o:GetResourceType() return self.resource end;
 return o;
end;
plot=makeplot(5,10,10,0,true);target=makeplot(6,11,10,-1,false);site=makeplot(7,10,11,0,false);
plots={[5]=plot,[6]=target,[7]=site};
Map={GetPlot=function(x,y) for _,v in pairs(plots) do if v.x==x and v.y==y then return v end end end,
 GetPlotByIndex=function(i) return plots[i] end,
 GetPlotDistance=function(x0,y0,x1,y1) return math.max(math.abs(x0-x1),math.abs(y0-y1)) end};
ImprovementBuilder={SetImprovementType=function(o,kind,owner)
 stats.improvementChanges=stats.improvementChanges+1;if not failOrigin then o.improvement=kind end end};
Cities={GetPlotPurchaseCity=function(o) return o.owner==0 and capital or nil end};
PlayersVisibility={[0]={IsRevealed=function(self,x,y) return x<=11 end}};
capital={GetX=function() return 10 end,GetY=function() return 10 end,GetID=function() return 42 end,GetOwner=function() return 0 end};
weapons={stock=0}; function weapons:GetWeaponCount(index) assert(index==2);return self.stock end;
function weapons:ChangeWeaponCount(index,amount) assert(index==2);stats.weaponChanges=stats.weaponChanges+1;if not failChange then self.stock=self.stock+amount end end;
p={id=0,props={},attachments={},human=true};
function p:GetID() return self.id end;function p:IsAlive() return true end;function p:IsMajor() return true end;
function p:IsHuman() return self.human end;function p:IsTurnActive() return active end;
function p:GetProperty(k) return self.props[k] end;function p:SetProperty(k,v) self.props[k]=v end;
function p:GetWMDs() return weapons end;function p:GetCities() return {GetCapitalCity=function() return capital end,
 FindID=function(self,id) return id==42 and capital or nil end} end;
Players={[0]=p};
UnitManager={};
function UnitManager.GetUnit(owner,id) return owner==0 and units[id] or nil end;
function UnitManager.InitUnit(owner,kind,x,y)
 stats.created=stats.created+1;if failInit then return nil end;
 local u={id=stats.created,owner=owner,kind=kind,x=x,y=y,props={}};units[u.id]=u;
 function u:GetID() return self.id end;function u:GetOwner() return self.owner end;function u:GetType() return self.kind end;
 function u:GetX() return self.x end;function u:GetY() return self.y end;
 function u:GetProperty(k) return self.props[k] end;function u:SetProperty(k,v) self.props[k]=v end;
 return u;
end;
function UnitManager.Kill(u) assert(units[u.id]==u);units[u.id]=nil;stats.killed=stats.killed+1 end;
function fire(k,args) assert(handlers[k],k);args=args or {};
 if k=='LOTM_Storm_Target' and args.OriginRevision==nil then args.OriginRevision=0 end;
 handlers[k](0,args) end;
function N(o,k,d) local v=o:GetProperty(k);return v~=nil and tonumber(v) or d end;
function K(ch,s) return 'LOTM_CHURCH_'..ch..'_'..s end;
function QK(ch,t,s) return K(ch,'QUEST_'..t..'_'..s) end;
function RescueActive() return rescue end;
function CurrentPlayerTurn(p) return N(p,'LOTM_WORLD_PLAYER_TURN',0) end;
function Attach(p,id) p.attachments[#p.attachments+1]=id;return true end;
function Log() end;
function RewardKey(t,s) return 'LOTM_CHURCH_STORM_QUEST_'..t..'_'..s end;
'''
EXT=r'''
function rows(list) return setmetatable(list or {},{__call=function(self) local i=0;return function() i=i+1;return self[i] end end}) end;
GameInfo.UnitAbilityModifiers=rows({{UnitAbilityType='ABILITY_UNIT_WMD_RESISTANCE',ModifierId='GDR_WMD_RESISTANCE'}});
GameInfo.Modifiers={GDR_WMD_RESISTANCE={ModifierType='PROTECTION'}};
GameInfo.DynamicModifiers={PROTECTION={EffectType='EFFECT_ADJUST_UNIT_WMD_PROTECTION'}};
GameInfo.ModifierArguments=rows({{ModifierId='GDR_WMD_RESISTANCE',Name='Blast',Value='50'}});
GameInfo.Districts={[0]={DistrictType='DISTRICT_CITY_CENTER'},[1]={DistrictType='DISTRICT_CAMPUS'}};
GameInfo.DistrictReplaces=rows({{CivUniqueDistrictType='DISTRICT_SEOWON',ReplacesDistrictType='DISTRICT_CAMPUS'}});
GameInfo.Buildings=rows({{Index=0,PrereqDistrict='DISTRICT_CITY_CENTER',IsWonder=false},{Index=1,PrereqDistrict='DISTRICT_CAMPUS',IsWonder=false},{Index=2,PrereqDistrict='DISTRICT_CAMPUS',IsWonder=true}});
DefenseTypes={DISTRICT_GARRISON=0,DISTRICT_OUTER=1}; Units={};
Map.GetPlotXYWithRangeCheck=function(x,y,dx,dy,radius)
 if (dx==1 and dy==1) or (dx==-1 and dy==-1) then return nil end;
 return Map.GetPlot(x+dx,y+dy);
end;
local oldMake=makeplot;
function makeplot(index,x,y,owner,isCity)
 local o=oldMake(index,x,y,owner,isCity);o.workers=0;o.route=-1;o.pillaged=false;o.routePillaged=false;
 function o:GetWorkerCount() return self.workers end;function o:GetAirUnits() return self.air or {} end;
 function o:GetRouteType() return self.route end;function o:IsRoutePillaged() return self.routePillaged end;
 function o:IsImprovementPillaged() return self.pillaged end;
 return o;
end;
plot=makeplot(5,10,10,0,true); target=makeplot(6,11,10,-1,false);site=makeplot(7,10,11,0,false);
plots={[5]=plot,[6]=target,[7]=site};
local init=UnitManager.InitUnit;
function UnitManager.InitUnit(owner,kind,x,y)
 local u=init(owner,kind,x,y); if not u then return nil end;u.damage=0;u.maximum=100;u.resistant=false;
 function u:GetDamage() return self.damage end;function u:GetMaxDamage() return self.maximum end;
 function u:IsDead() return false end;function u:IsDelayedDeath() return false end;
 function u:GetAbility() return {GetAbilityCount=function(_,kind) return self.resistant and 1 or 0 end} end;
 function u:ChangeDamage(v) self.damage=self.damage+v;stats.damageChanges=(stats.damageChanges or 0)+1 end;
 return u;
end;
Units.GetUnitsInPlot=function(o) local list={};for _,u in pairs(units) do if u.x==o.x and u.y==o.y then list[#list+1]=u end end;return list end;
ImprovementBuilder.SetImprovementPillaged=function(o,v) o.pillaged=v;stats.pillages=(stats.pillages or 0)+1 end;
RouteBuilder={SetRoutePillaged=function(o,v) o.routePillaged=v end};
capital.pop=10;capital.buildings={have={[0]=true,[1]=true,[2]=true},pillaged={}};
function capital:GetPopulation() return self.pop end;
function capital:ChangePopulation(v) self.pop=self.pop+v;stats.populationChanges=(stats.populationChanges or 0)+1 end;
function capital:GetBuildings() return self.buildings end;
function capital.buildings:HasBuilding(id) return self.have[id]==true end;
function capital.buildings:IsPillaged(id) return self.pillaged[id]==true end;
function capital.buildings:SetPillaged(id,v) if failBuilding then error('injected building failure') end;self.pillaged[id]=v end;
districts={};
function makedistrict(id,plotIndex,kind)
 local d={id=id,plotIndex=plotIndex,kind=kind,damage={[0]=20,[1]=15},maximum={[0]=200,[1]=100},pillaged=false};districts[id]=d;
 function d:GetID() return self.id end;function d:GetOwner() return 0 end;function d:GetType() return self.kind end;
 function d:GetDamage(t) return self.damage[t] end;function d:GetMaxDamage(t) return self.maximum[t] end;
 function d:ChangeDamage(t,v) assert(t==0 or t==1);self.damage[t]=self.damage[t]+v end;
 function d:IsPillaged() return self.pillaged end;function d:SetPillaged(v) self.pillaged=v end;
 return d;
end;
center=makedistrict(42,5,0);
function capital:GetDistricts() return {GetDistrictAtLocation=function(_,index) for _,d in pairs(districts) do if d.plotIndex==index then return d end end end} end;
function p:GetDistricts() return {FindID=function(_,id) return districts[id] end} end;
Cities.GetPlotWorkingCity=function(index) return plots[index] and plots[index].owner==0 and capital or nil end;
wars={[1]=true};
WarTypes={SURPRISE_WAR=1};
function p:GetDiplomacy() return {IsAtWarWith=function(_,id) return wars[id]==true end,
 HasAllied=function() return allied==true end,HasDeclaredFriendship=function() return friend==true end,
 CanDeclareWarOn=function() return not blockedWar end,
 DeclareWarOn=function(_,id,kind,flag) assert(kind==1 and flag==true);stats.warDeclarations=(stats.warDeclarations or 0)+1;if not failWar then wars[id]=true end end} end;
function impact(frame)
 fire('LOTM_Storm_Impact',{CastSerial=N(p,'LOTM_STORM_CAST_SERIAL',0),FXSerial=N(p,'LOTM_STORM_START_FX_SERIAL',0),
  PlotIndex=N(p,'LOTM_STORM_TARGET_PLOT',-1),PresentedFrame=frame or 98});
end;
function cast(index)
 fire('LOTM_Storm_Prepare',{ExpectedSerial=N(p,'LOTM_STORM_CAST_SERIAL',0)});
 fire('LOTM_Storm_Fire',{CastSerial=N(p,'LOTM_STORM_CAST_SERIAL',0),PlotIndex=index or 6});
 impact();
end;
'''

def blessing_source(debug=True):
    source=(ROOT/'Scripts/LOTM_GodBlessings.lua').read_text(encoding='utf-8')
    assert source.count('local STORM_DEBUG_UNLIMITED=false;')==1
    if debug:
        # Simulate the archived debug build only inside this finite fixture.
        source=source.replace('local STORM_DEBUG_UNLIMITED=false;','local STORM_DEBUG_UNLIMITED=true;',1)
    return source

def runtime(rescue=False,debug=False):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute(BASE)
    lua.execute(EXT)
    lua.globals().rescue=rescue
    lua.execute(blessing_source(debug))
    return lua
def church_function(lua,name,next_name):
    source=strip_trace((ROOT/'Scripts/LOTM_WORLD_Churches.lua').read_text(encoding='utf-8'))
    start=source.index('local function '+name+'(')
    end=source.index('local function '+next_name+'(',start)
    return lua.execute(source[start:end]+'\nreturn '+name)


def ui_runtime():
    lua=runtime(debug=True)
    lua.execute(r"""requests={};events={};mode=3;cursor=6;nativeCalls=0;opened=0;preview={};
      Game.GetLocalPlayer=function() return 0 end;
      InterfaceModeTypes={SELECTION=1,WMD_STRIKE=2,VIEW_MODAL_LENS=3,ICBM_STRIKE=4};
      MouseEvents={LButtonDown=1,LButtonUp=2,RButtonUp=3,PointerDown=4,PointerUp=5,MouseMove=6};
      KeyEvents={KeyUp=7};Keys={VK_ESCAPE=27};CursorTypes={NORMAL=0,RANGE_ATTACK=1};
      PlayerOperations={EXECUTE_SCRIPT=55,DIPLOMACY_DECLARE_WAR=56,PARAM_PLAYER_ONE='one',PARAM_PLAYER_TWO='two'};
      WarTypes={SURPRISE_WAR=1};
      UI={GetCursorPlotID=function() return cursor end,GetInterfaceMode=function() return mode end,
       SetInterfaceMode=function(v) mode=v end,SelectCity=function() error('No city selection') end,
       RequestPlayerOperation=function(id,op,args) requests[#requests+1]={op=op,args=args} end};
      UIManager={SetUICursor=function(self,v) shownCursor=v end};
      UILens={CreateLensLayerHash=function(s) return 9 end,ClearLayerHexes=function() preview={} end,
       ToggleLayerOn=function() end,ToggleLayerOff=function() end,
       SetLayerHexesArea=function(layer,owner,list) assert(layer==9 and owner==0);preview=list end};
      ContextPtr={SetInputHandler=function(self,f) inputHandler=f end,LookUpControl=function() return nil end};
      function OnInputHandler(input) nativeCalls=nativeCalls+1;return 'native' end;
      function input(message,key) return {GetMessageType=function() return message end,GetKey=function() return key or 0 end} end;
      Events=setmetatable({}, {__index=function(t,k) local e={Add=function(f) events[k]=f end};rawset(t,k,e);return e end});
      LuaEvents=UIEventTable({WorldInput_ConfirmWarDialog=function(id,list,war,fn) warList=list;warConfirmation=fn end});
      Locale={Lookup=function(k) return k end};PopupDialogInGame={};
      function PopupDialogInGame:new(name) return {AddText=function() end,AddCancelButton=function() end,
       AddConfirmButton=function(self,label,f) confirmation=f end,Open=function() opened=opened+1 end} end;
      fire('LOTM_Storm_Prepare',{ExpectedSerial=0});
      """)
    lua.execute(strip_trace((ROOT/'UI/LOTM_StormWorldInput.lua').read_text(encoding='utf-8')))
    return lua

def attach_fx(lua,local_id=0):
    lua.globals().fxLocalID=local_id
    lua.execute('''starts=0;released=0;events={};instances={};fxRequests={};Controls={Effects={}};
      Game.GetLocalPlayer=function() return fxLocalID end;
      PlayerManager.GetWasEverAliveMajors=function() return {p} end;
      PlayersVisibility[1]={IsVisible=function() return true end};
      PlayerOperations={EXECUTE_SCRIPT=55};
      UI={GridToWorld=function() return 200,400 end,
       RequestPlayerOperation=function(id,op,args)
        assert(id==fxLocalID and op==55);fxRequests[#fxRequests+1]={id=id,args=args,texture=instances[starts].Frames.file};end};
      ContextPtr={SetHide=function() end,SetUpdate=function(self,f) update=f end};
      Events=setmetatable({}, {__index=function(t,k) local e={Add=function(f) events[k]=f end};rawset(t,k,e);return e end});
      InstanceManager={};function InstanceManager:new() return {
       GetInstance=function() starts=starts+1;local instance={
        Anchor={SetWorldPositionVal=function() end},Frames={SetSizeVal=function() end,SetOffsetY=function() end,
        SetTexture=function(self,x,y,file) self.x=x;self.y=y;self.file=file end,SetAlpha=function() end}};
        instances[starts]=instance;return instance end,
       ReleaseInstance=function() released=released+1 end,ResetInstances=function() end};end;''')
    lua.execute(strip_trace((ROOT/'UI/LOTM_GodBlessingFX.lua').read_text(encoding='utf-8')))
    return lua

class GodBlessings(unittest.TestCase):
    def test_storm_waits_for_bound_mass_strike_cue_and_settles_once(self):
        lua=runtime()
        lua.execute("LOTM_GodBlessings.GrantStorm(p,6,'FULL');u=UnitManager.InitUnit(0,1,11,10);fire('LOTM_Storm_Prepare',{ExpectedSerial=0});fire('LOTM_Storm_Fire',{CastSerial=1,PlotIndex=6})")
        self.assertEqual(lua.eval('stats.killed'),0)
        self.assertEqual(lua.eval('center.damage[0]'),20)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),1)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'CASTING')
        lua.execute("impact(97);fire('LOTM_Storm_Impact',{CastSerial=1,FXSerial=99,PlotIndex=6,PresentedFrame=98});fire('LOTM_Storm_Impact',{CastSerial=1,FXSerial=1,PlotIndex=7,PresentedFrame=98});fire('LOTM_Storm_Fire',{CastSerial=1,PlotIndex=6});fire('LOTM_Storm_Cancel',{CastSerial=1})")
        self.assertEqual(lua.eval('stats.killed'),0)
        self.assertEqual(lua.eval('p.props.LOTM_GOD_FX_SERIAL'),1)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_WINDUP'),1)
        lua.execute('impact();impact();turns.GodBlessings(0)')
        self.assertEqual(lua.eval('stats.killed'),1)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),0)
        self.assertEqual(lua.eval('p.props.LOTM_GOD_FX_SERIAL'),1)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'FIRED')

    def test_actual_fx_draws_mass_strike_before_requesting_damage(self):
        lua=runtime(debug=True);attach_fx(lua)
        lua.execute("u=UnitManager.InitUnit(0,1,11,10);fire('LOTM_Storm_Prepare',{ExpectedSerial=0});fire('LOTM_Storm_Fire',{CastSerial=1,PlotIndex=6});events.GameCoreEventPublishComplete();update(0);update(97/24)")
        self.assertEqual(lua.eval('#fxRequests'),0)
        self.assertEqual(lua.eval('stats.killed'),0)
        lua.execute('update(1.01/24)')
        self.assertEqual(lua.eval('#fxRequests'),1)
        self.assertEqual(lua.eval('fxRequests[1].args.PresentedFrame'),98)
        self.assertEqual(lua.eval('fxRequests[1].texture'),'LOTM_GOD_FX_STORM_V4_06.dds')
        self.assertEqual(lua.eval('instances[1].Frames.x'),1536)
        self.assertEqual(lua.eval('stats.killed'),0) # UI itself is read-only.
        lua.execute('fire(fxRequests[1].args.OnStart,fxRequests[1].args);update(1);events.GameCoreEventPublishComplete()')
        self.assertEqual(lua.eval('stats.killed'),1)
        self.assertEqual(lua.eval('#fxRequests'),1)
        self.assertEqual(lua.eval('starts'),1)

    def test_windup_load_and_turn_change_replay_only_unsettled_storm(self):
        lua=runtime(debug=True)
        lua.execute("u=UnitManager.InitUnit(0,1,11,10);fire('LOTM_Storm_Prepare',{ExpectedSerial=0});fire('LOTM_Storm_Fire',{CastSerial=1,PlotIndex=6});turn=11;active=false;turns.GodBlessings(0)")
        lua.execute(blessing_source(True))
        self.assertEqual(lua.eval('stats.killed'),0)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_WINDUP'),1)
        attach_fx(lua)
        self.assertEqual(lua.eval('starts'),1)
        lua.execute('events.GameCoreEventPublishComplete();update(98/24);fire(fxRequests[1].args.OnStart,fxRequests[1].args)')
        self.assertEqual(lua.eval('starts'),1)
        self.assertEqual(lua.eval('stats.killed'),1)
        lua.execute(blessing_source(True));attach_fx(lua)
        self.assertEqual(lua.eval('starts'),0) # Completed receipt stays historical.
        self.assertEqual(lua.eval('stats.killed'),1)

    def test_observer_renders_but_only_owner_can_submit_cue(self):
        lua=runtime(debug=True)
        lua.execute("fire('LOTM_Storm_Prepare',{ExpectedSerial=0});fire('LOTM_Storm_Fire',{CastSerial=1,PlotIndex=6})")
        attach_fx(lua,local_id=1)
        lua.execute('update(5);update(1)')
        self.assertEqual(lua.eval('starts'),1)
        self.assertEqual(lua.eval('#fxRequests'),0)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_WINDUP'),1)

    def test_frame_skip_and_delayed_ack_keep_one_bound_impact(self):
        lua=runtime(debug=True)
        lua.execute("u=UnitManager.InitUnit(0,1,11,10);fire('LOTM_Storm_Prepare',{ExpectedSerial=0});fire('LOTM_Storm_Fire',{CastSerial=1,PlotIndex=6})")
        attach_fx(lua);lua.execute('update(12)')
        self.assertEqual(lua.eval('released'),0)
        self.assertEqual(lua.eval('fxRequests[1].args.PresentedFrame'),98)
        lua.execute('update(0.8)')
        self.assertEqual(lua.eval('#fxRequests'),2)
        lua.execute('for _,request in ipairs(fxRequests) do fire(request.args.OnStart,request.args) end;update(6)')
        self.assertEqual(lua.eval('stats.killed'),1)
        self.assertEqual(lua.eval('released'),1)

    def test_impact_uses_current_radius_objects_and_rechecks_new_war_owner(self):
        lua=runtime(debug=True)
        lua.execute("outside=UnitManager.InitUnit(0,1,11,10);fire('LOTM_Storm_Prepare',{ExpectedSerial=0});fire('LOTM_Storm_Fire',{CastSerial=1,PlotIndex=6});outside.x=13;incoming=UnitManager.InitUnit(0,1,11,10);impact()")
        self.assertEqual(lua.eval('stats.killed'),1)
        self.assertIsNotNone(lua.eval('units[outside.id]'))
        lua=runtime()
        lua.execute("LOTM_GodBlessings.GrantStorm(p,6,'FULL');fire('LOTM_Storm_Prepare',{ExpectedSerial=0});fire('LOTM_Storm_Fire',{CastSerial=1,PlotIndex=6});Players[1]={};target.owner=1;wars[1]=false;impact()")
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'WAR_REQUIRED')
        self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),1)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_PENDING'),0)
        self.assertEqual(lua.eval('center.damage[0]'),20)
    def test_each_reward_grants_once_and_charges_survive_lua_reload(self):
        lua=runtime()
        lua.execute("LOTM_GodBlessings.GrantStorm(p,6,'FULL');LOTM_GodBlessings.GrantStorm(p,6,'HALF');LOTM_GodBlessings.GrantStorm(p,10,'HALF');LOTM_GodBlessings.GrantStorm(p,15,'FULL')")
        self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),3)
        lua.execute(blessing_source(False))
        lua.execute("LOTM_GodBlessings.GrantStorm(p,10,'FULL')")
        self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),3)
        self.assertEqual(lua.eval('stats.created'),0)
    def test_production_button_ignores_saved_debug_flag_and_needs_earned_charge(self):
        for debug in (False,True):
            with self.subTest(debug=debug):
                lua=runtime(debug=debug)
                lua.execute('''requests={};events={};
                  Game.GetLocalPlayer=function() return 0 end;
                  function control() return {
                    SetHide=function(self,v) self.hidden=v end,
                    SetText=function(self,v) self.text=v end,
                    SetDisabled=function(self,v) self.disabled=v end,
                    SetAlpha=function(self,v) self.alpha=v end,
                    SetOffsetX=function(self,v) self.x=v end,
                    SetOffsetY=function(self,v) self.y=v end,
                    ReprocessAnchoring=function(self) self.anchored=true end,
                    SetToolTipString=function(self,v) self.tooltip=v end,
                    RegisterCallback=function(self,k,f) self.click=f end} end;
                  Controls={Root=control(),Count=control(),StormButton=control(),StormIcon=control(),TargetHint=control(),HintText=control(),Cancel=control()};
                  -- Firaxis creates AddUserInterfaces with isHidden=true.
                  ContextPtr={hidden=true,SetHide=function(self,v) self.hidden=v end,LookUpControl=function() return nil end};
                  screenX=1920;screenY=1080;
                  UIManager={GetScreenSizeVal=function() return screenX,screenY end};
                  SystemUpdateUI={ScreenResize=44};
                  Locale={Lookup=function(k,...) return k end};Mouse={eLClick=1};
                  InterfaceModeTypes={SELECTION=1,WMD_STRIKE=2,VIEW_MODAL_LENS=3};PlayerOperations={EXECUTE_SCRIPT=55};
                  UI={GetInterfaceMode=function() return 1 end,SetInterfaceMode=function() end,
                    RequestPlayerOperation=function(id,op,args) assert(id==0 and op==55);requests[#requests+1]=args end};
                  UILens={SetActive=function() end};
                  Events=setmetatable({}, {__index=function(t,k) local e={Add=function(f) events[k]=f end};rawset(t,k,e);return e end});''')
                lua.execute(strip_trace((ROOT/'UI/LOTM_StormBlessing.lua').read_text(encoding='utf-8')))
                self.assertEqual(lua.eval('Controls.Root.hidden'),False)
                self.assertEqual(lua.eval('ContextPtr.hidden'),False)
                self.assertEqual((lua.eval('Controls.Root.x+36'),lua.eval('Controls.Root.y+38')),(1820,752))
                self.assertEqual(lua.eval('Controls.TargetHint.x'),816)
                self.assertEqual(lua.eval('Controls.Count.text'),'0')
                self.assertEqual(lua.eval('Controls.StormButton.disabled'),True)
                self.assertEqual(lua.eval('Controls.StormIcon.alpha'),0.45)
                self.assertEqual(lua.eval('Controls.StormButton.tooltip'),'LOC_LOTM_STORM_TOOLTIP')
                lua.execute('Controls.StormButton.click()')
                self.assertEqual(lua.eval('#requests'),0)
                lua.execute('screenX=1366;screenY=768;events.SystemUpdateUI(44)')
                self.assertEqual((lua.eval('Controls.Root.x+36'),lua.eval('Controls.Root.y+38')),(1266,440))
                self.assertEqual(lua.eval('Controls.Root.anchored'),True)
                self.assertEqual(lua.eval('Controls.TargetHint.hidden'),True)
                lua.execute('p.props.LOTM_STORM_RESULT_SERIAL=1;active=false;events.GameCoreEventPublishComplete();Controls.StormButton.click()')
                self.assertEqual(lua.eval('Controls.StormButton.disabled'),True)
                self.assertEqual(lua.eval('#requests'),0)
                lua.execute('rescue=true;GameConfiguration.GetValue=function() return 0 end;events.GameCoreEventPublishComplete()')
                self.assertEqual(lua.eval('ContextPtr.hidden'),True)
                self.assertEqual(lua.eval('Controls.Root.hidden'),True)
    def test_capital_effect_receipts_and_historical_suppression(self):
        lua=runtime();lua.execute("p.props.LOTM_CHURCH_FOOL_QUEST_6_REWARD_APPLIED=1;LOTM_GodBlessings.BaselineCapitalFX(p);LOTM_GodBlessings.RecordCapitalFX(p,'FOOL',6);LOTM_GodBlessings.RecordCapitalFX(p,'NIGHT',10);LOTM_GodBlessings.RecordCapitalFX(p,'NIGHT',10);LOTM_GodBlessings.RecordCapitalFX(p,'FOOL',15)")
        self.assertEqual(lua.eval('p.props.LOTM_GOD_FX_SERIAL'),2)
        self.assertEqual(lua.eval('p.props.LOTM_GOD_FX_1_KIND'),'NIGHT')
        self.assertEqual(lua.eval('p.props.LOTM_GOD_FX_2_KIND'),'FOOL')
        self.assertEqual(lua.eval('p.props.LOTM_GOD_FX_2_PLOT'),5)
    def test_active_legacy_storm_migrates_once_but_expired_does_not(self):
        for until,expected in ((15,1),(3,0)):
            lua=runtime();record=church_function(lua,'RecordReward','MigrateNormalGodBlessings')
            lua.globals().RecordReward=record
            migrate=church_function(lua,'MigrateNormalGodBlessings','RunBlessingExtras')
            lua.execute(f"p.props.LOTM_WORLD_PLAYER_TURN=5;p.props.LOTM_CHURCH_STORM_BLESSING_TIER=10;p.props.LOTM_CHURCH_STORM_BLESSING_STRENGTH='HALF';p.props.LOTM_CHURCH_STORM_BLESSING_UNTIL={until}")
            migrate(lua.globals().p);migrate(lua.globals().p)
            self.assertEqual(lua.eval('N(p,"LOTM_STORM_CHARGES",0)'),expected)
            self.assertEqual(list(lua.eval('p.attachments').values()),['LOTM_CHURCH_STORM_BLESS_10_HALF_OFF'])
            self.assertEqual(lua.eval('p.props.LOTM_CHURCH_STORM_BLESSING_TIER'),0)
    def test_rescue_storm_enabled_and_original_blessing_branch_remains(self):
        lua=runtime(rescue=True,debug=True)
        lua.execute("LOTM_GodBlessings.GrantStorm(p,6,'FULL');LOTM_GodBlessings.RecordCapitalFX(p,'FOOL',6)")
        self.assertIsNone(lua.eval('p.props.LOTM_STORM_CHARGES'))
        self.assertIsNotNone(lua.eval('handlers.LOTM_Storm_Prepare'))
        self.assertEqual(lua.eval('gameprops.LOTM_STORM_DEBUG_UNLIMITED'),1)
        self.assertIsNone(lua.eval('p.props.LOTM_GOD_FX_SERIAL'))
        self.assertFalse(lua.eval('LOTM_GodBlessings.IsEnabled()'))
        apply=church_function(lua,'ApplyBlessing','ArtifactName')
        lua.execute("DURATION={[6]=10,[10]=12,[15]=15};function BlessingRank(t,s) return t*10+(s=='FULL' and 2 or 1) end;p.props.LOTM_WORLD_PLAYER_TURN=5;p.props.LOTM_WORLD_PLAYER_TURN_SETTLED_GAME_TURN=10")
        self.assertTrue(apply(lua.globals().p,'STORM',6,'FULL'))
        self.assertEqual(list(lua.eval('p.attachments').values()),['LOTM_CHURCH_STORM_BLESS_6_FULL_ON'])
        self.assertEqual(lua.eval('p.props.LOTM_CHURCH_STORM_BLESSING_UNTIL'),15)
    def test_normal_storm_skips_buff_and_night_fool_keep_original_duration(self):
        lua=runtime();apply=church_function(lua,'ApplyBlessing','ArtifactName')
        lua.execute("DURATION={[6]=10,[10]=12,[15]=15};function BlessingRank(t,s) return t*10+(s=='FULL' and 2 or 1) end;p.props.LOTM_WORLD_PLAYER_TURN=5;p.props.LOTM_WORLD_PLAYER_TURN_SETTLED_GAME_TURN=10")
        self.assertTrue(apply(lua.globals().p,'STORM',6,'FULL'))
        self.assertEqual(len(list(lua.eval('p.attachments').values())),0)
        for church in ('NIGHT','FOOL'):
            self.assertTrue(apply(lua.globals().p,church,10,'FULL'))
            self.assertEqual(lua.eval(f'p.props.LOTM_CHURCH_{church}_BLESSING_UNTIL'),17)
    def test_database_native_damage_flags_radius_and_zero_fallout(self):
        original=sqlite3.connect(CACHE.as_uri()+'?mode=ro',uri=True);db=sqlite3.connect(':memory:');original.backup(db);original.close()
        db.execute('pragma foreign_keys=on')
        import zlib
        db.create_function('Make_Hash',1,lambda v:zlib.crc32(str(v).encode('utf-8')))
        sql=(ROOT/'Gameplay/LOTM_GodBlessings.sql').read_text(encoding='utf-8');db.executescript(sql);db.executescript(sql)
        fields='BlastRadius,AffectPopulation,AffectImprovements,AffectBuildings,AffectUnits,AffectResources,AffectRoutes'
        self.assertEqual(db.execute('select '+fields+' from WMDs where WeaponType=?',('WMD_NUCLEAR_DEVICE',)).fetchone(),db.execute('select '+fields+' from WMDs where WeaponType=?',('WMD_LOTM_LIGHTNING_STORM',)).fetchone())
        self.assertEqual(db.execute("select BlastRadius,FalloutDuration,Maintenance from WMDs where WeaponType='WMD_LOTM_LIGHTNING_STORM'").fetchone(),(1,0,0))
        self.assertEqual(db.execute("select ICBMStrikeRange from WMDs where WeaponType='WMD_LOTM_LIGHTNING_STORM'").fetchone(),(999,))
        self.assertEqual(db.execute("select CanTrain,Maintenance,BaseSightRange,WMDCapable from Units where UnitType='UNIT_LOTM_STORM_MANIFESTATION'").fetchone(),(0,0,0,1))
        self.assertEqual(db.execute('pragma foreign_key_check').fetchall(),[])
        db.close()
    def test_fx_ui_tracks_plot_frames_and_does_not_replay_old_receipts(self):
        lua=runtime()
        lua.execute('''starts=0;released=0;events={};instances={};Controls={Effects={}};
          Game.GetLocalPlayer=function() return 0 end;
          PlayerManager.GetWasEverAliveMajors=function() return {p} end;
          UI={GridToWorld=function(index) return 200,400 end};
          PlayerOperations={EXECUTE_SCRIPT=55};
          UI.RequestPlayerOperation=function(id,op,args) assert(id==0 and op==55);fire(args.OnStart,args) end;
          ContextPtr={hidden=true,SetHide=function(self,v) self.hidden=v end,SetUpdate=function(self,f) update=f end};
          Events=setmetatable({}, {__index=function(t,k) local e={Add=function(f) events[k]=f end};rawset(t,k,e);return e end});
          InstanceManager={};function InstanceManager:new(name,root,parent)
           return {GetInstance=function()
            starts=starts+1;local i={Anchor={SetWorldPositionVal=function(self,x,y,z) self.x=x;self.y=y;self.z=z end},
             Frames={SetTexture=function(self,x,y,file) self.x=x;self.y=y;self.file=file end,
              SetSizeVal=function(self,w,h) self.width=w;self.height=h end,
              SetOffsetY=function(self,y) self.offsetY=y end,SetAlpha=function(self,a) self.alpha=a end}};
            instances[starts]=i;return i end,
            ReleaseInstance=function(self,i) released=released+1 end,ResetInstances=function() end} end;
          p.props.LOTM_GOD_FX_SERIAL=1;p.props.LOTM_GOD_FX_1_KIND='FOOL';p.props.LOTM_GOD_FX_1_PLOT=5;''')
        lua.execute(strip_trace((ROOT/'UI/LOTM_GodBlessingFX.lua').read_text(encoding='utf-8')))
        self.assertEqual(lua.eval('ContextPtr.hidden'),False)
        self.assertEqual(lua.eval('starts'),0)
        lua.execute("LOTM_GodBlessings.RecordCapitalFX(p,'NIGHT',6);events.GameCoreEventPublishComplete();events.GameCoreEventPublishComplete();update(0)")
        self.assertEqual(lua.eval('starts'),1)
        self.assertEqual(lua.eval('instances[1].Anchor.x'),200)
        self.assertEqual(lua.eval('instances[1].Frames.file'),'LOTM_GOD_FX_NIGHT_00.dds')
        lua.execute('update(0.043)')
        self.assertEqual(lua.eval('instances[1].Frames.x'),256)
        lua.execute('update(10)')
        self.assertEqual(lua.eval('released'),1)
        lua.execute("fire('LOTM_Storm_Prepare',{ExpectedSerial=0});fire('LOTM_Storm_Fire',{CastSerial=1,PlotIndex=6});events.GameCoreEventPublishComplete();update(0)")
        self.assertEqual(lua.eval('starts'),1)  # The fixture has no earned charge.
        lua.execute("LOTM_GodBlessings.GrantStorm(p,6,'FULL');fire('LOTM_Storm_Prepare',{ExpectedSerial=0});fire('LOTM_Storm_Fire',{CastSerial=1,PlotIndex=6});events.GameCoreEventPublishComplete();update(0)")
        self.assertEqual(lua.eval('starts'),2)
        self.assertEqual(lua.eval('instances[2].Frames.file'),'LOTM_GOD_FX_STORM_V4_00.dds')
        self.assertEqual((lua.eval('instances[2].Frames.width'),lua.eval('instances[2].Frames.height')),(768,512))
        self.assertEqual((lua.eval('instances[2].Anchor.z'),lua.eval('instances[2].Frames.offsetY')),(0,-147))
        lua.execute('update(4.09);update(4.91)')
        self.assertEqual(lua.eval('instances[2].Frames.file'),'LOTM_GOD_FX_STORM_V4_13.dds')
        self.assertEqual(lua.eval('released'),1)
        lua.execute('update(0.02)')
        self.assertEqual(lua.eval('released'),2)
    def test_ui_native_delegation_normal_criteria_and_complete_animation_assets(self):
        wrapper=strip_trace((ROOT/'UI/LOTM_StormWorldInput.lua').read_text(encoding='utf-8'))
        self.assertIn('include("WorldInput_Expansion2")',wrapper)
        self.assertNotIn('BASE_ICBMStrike',wrapper);self.assertNotIn('RequestCommand(',wrapper);self.assertIn('LOTM_Storm_Fire',wrapper)
        for name in ('LOTM_StormWorldInput','LOTM_StormBlessing','LOTM_GodBlessingFX'):
            source=strip_trace((ROOT/f'UI/{name}.lua').read_text(encoding='utf-8'))
            self.assertNotIn(':SetProperty(',source);self.assertNotIn('ChangeWeaponCount(',source);self.assertNotIn('UnitManager.RequestOperation(',source)
        root=ET.parse(ROOT/'RedPriestPath.modinfo').getroot()
        actions=[x for x in root.find('InGameActions') if x.attrib['id'].startswith(('LOTM_GOD_BLESS','LOTM_STORM_'))]
        self.assertEqual(len(actions),9)
        self.assertTrue(all(x.get('criteria') in ('LOTM_RP_EXPANSION_2','LOTM_RP_LANGUAGE_EN') for x in actions))
        registered={x.text for x in root.findall('./Files/File')}
        for kind,count in [('STORM',204),('NIGHT',168),('FOOL',192)]:
            for i in range((count+15)//16):
                relative=f'Art/LOTM_GOD_FX_{kind}_{i:02d}.dds'
                self.assertIn(relative,registered)
                p=ROOT/relative;data=p.read_bytes();self.assertEqual(data[84:88],b'DXT5')
                with Image.open(p) as im: self.assertEqual(im.size,(1024,1024))
        for i in range(14):
            relative=f'Art/LOTM_GOD_FX_STORM_V4_{i:02d}.dds'
            self.assertIn(relative,registered)
            p=ROOT/relative
            self.assertEqual(p.read_bytes()[84:88],b'DXT5')
            with Image.open(p) as im:self.assertEqual(im.size,(4096,2048))
        source_icon=Path(r'D:\Downloads\风暴漩涡雷霆徽章.png')
        if source_icon.exists(): self.assertEqual(source_icon.read_bytes(),(ROOT/'Art/LOTM_StormBlessingSource.png').read_bytes())
    def test_ui_loader_context_gate_rejects_the_actual_resource425_manifest_fault(self):
        root=ET.parse(ROOT/'RedPriestPath.modinfo').getroot()
        self.assertEqual(user_interface_context_failures(root),[])
        ids={'LOTM_STORM_BLESSING_UI','LOTM_GOD_BLESSING_FX_UI'}
        addins=[x for x in root.find('InGameActions') if x.get('id') in ids]
        self.assertEqual(len(addins),2)
        for addin in addins:
            self.assertEqual(addin.findtext('./Properties/Context'),'InGame')
            properties=addin.find('Properties')
            properties.remove(properties.find('Context'))
        # Reproduce the two missing fields reported by the actual native log;
        # a release must reject the bad manifest before it reaches installation.
        errors=user_interface_context_failures(root)
        self.assertEqual(len(errors),2)
        self.assertEqual({message.split(':',1)[0] for message in errors},ids)
        for addin in addins:
            ET.SubElement(addin.find('Properties'),'Context').text='  '
        self.assertEqual(len(user_interface_context_failures(root)),2)

    def test_prepare_cancel_without_unit_source_or_inventory(self):
        lua=runtime(debug=True)
        lua.execute("capital=nil;fire('LOTM_Storm_Prepare',{ExpectedSerial=0});fire('LOTM_Storm_Prepare',{ExpectedSerial=0});fire('LOTM_Storm_Cancel',{CastSerial=1})")
        self.assertEqual(lua.eval('stats.created+stats.improvementChanges+stats.weaponChanges'),0)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'CANCELLED')
        self.assertIsNone(lua.eval('p.props.LOTM_GOD_FX_SERIAL'))

    def test_direct_impact_kills_only_units_in_radius_once(self):
        lua=runtime(debug=True)
        lua.execute('u=UnitManager.InitUnit(0,1,11,10);outside=UnitManager.InitUnit(0,1,13,10);cast();fire("LOTM_Storm_Fire",{CastSerial=1,PlotIndex=6})')
        self.assertEqual(lua.eval('stats.killed'),1)
        self.assertEqual(lua.eval('outside:GetDamage()'),0)
        self.assertEqual(lua.eval('p.props.LOTM_GOD_FX_SERIAL'),1)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'FIRED')
        self.assertEqual(lua.eval('stats.weaponChanges+stats.improvementChanges'),0)

    def test_resistance_uses_database_amount_and_current_health(self):
        lua=runtime(debug=True)
        lua.execute('u=UnitManager.InitUnit(0,1,11,10);u.resistant=true;cast()')
        self.assertEqual(lua.eval('u:GetDamage()'),50)
        lua.execute('cast()')
        self.assertEqual(lua.eval('stats.killed'),1)
        lua=runtime(debug=True)
        lua.execute("GameInfo.ModifierArguments[1].Value='100';u=UnitManager.InitUnit(0,1,11,10);u.resistant=true;cast()")
        self.assertEqual(lua.eval('u:GetDamage()'),0)
        self.assertEqual(lua.eval('stats.killed'),0)

    def test_population_snapshot_facilities_defenses_and_wonder(self):
        lua=runtime(debug=True)
        lua.execute('campus=makedistrict(43,6,1);target.owner=0;target.workers=3;plot.workers=2;target.improvement=3;target.route=0;target.resource=4;cast()')
        self.assertEqual(lua.eval('capital.pop'),5)
        self.assertEqual(lua.eval('center.damage[0]'),200)
        self.assertEqual(lua.eval('center.damage[1]'),100)
        self.assertEqual(lua.eval('campus.damage[0]'),200)
        self.assertTrue(lua.eval('campus.pillaged and target.pillaged and target.routePillaged'))
        self.assertTrue(lua.eval('capital.buildings:IsPillaged(0) and capital.buildings:IsPillaged(1)'))
        self.assertFalse(lua.eval('capital.buildings:IsPillaged(2)'))
        self.assertEqual(lua.eval('target.resource'),4)
        lua.execute('target.workers=20;cast()')
        self.assertEqual(lua.eval('capital.pop'),1)

    def test_charge_consumption_and_infinite_debug_repeated_casts(self):
        for debug in (False,True):
            lua=runtime(debug=debug)
            lua.execute("LOTM_GodBlessings.GrantStorm(p,6,'FULL');cast();cast()")
            self.assertEqual(lua.eval('N(p,"LOTM_STORM_CHARGES",0)'),1 if debug else 0)
            self.assertEqual(lua.eval('N(p,"LOTM_GOD_FX_SERIAL",0)'),2 if debug else 1)
            self.assertEqual(lua.eval('stats.created+stats.weaponChanges+stats.improvementChanges'),0)

    def test_debug_disable_keeps_saved_cast_earned_charge(self):
        lua=runtime(debug=True)
        lua.execute("LOTM_GodBlessings.GrantStorm(p,6,'FULL');fire('LOTM_Storm_Prepare',{ExpectedSerial=0})")
        lua.execute(blessing_source(False))
        lua.execute("fire('LOTM_Storm_Fire',{CastSerial=1,PlotIndex=6});impact();cast()")
        self.assertEqual(lua.eval('N(p,"LOTM_STORM_CHARGES",0)'),0)
        self.assertEqual(lua.eval('p.props.LOTM_GOD_FX_SERIAL'),1)
        self.assertEqual(lua.eval('gameprops.LOTM_STORM_DEBUG_UNLIMITED'),0)

    def test_invalid_hidden_stale_inactive_turn_targets_keep_charge(self):
        for setup,args in [('active=false','CastSerial=1,PlotIndex=6'),('','CastSerial=9,PlotIndex=6'),('target.x=12','CastSerial=1,PlotIndex=6'),('','CastSerial=1,PlotIndex=999'),('turn=11','CastSerial=1,PlotIndex=6')]:
            lua=runtime();lua.execute("LOTM_GodBlessings.GrantStorm(p,6,'FULL');fire('LOTM_Storm_Prepare',{ExpectedSerial=0})")
            lua.execute(setup);lua.execute("fire('LOTM_Storm_Fire',{"+args+"})")
            self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),1)
            self.assertIsNone(lua.eval('p.props.LOTM_GOD_FX_SERIAL'))

    def test_war_must_actually_exist_before_damage(self):
        lua=runtime(debug=True)
        lua.execute("Players[1]={};target.owner=1;wars[1]=false;cast()")
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'WAR_REQUIRED')
        self.assertIsNone(lua.eval('p.props.LOTM_GOD_FX_SERIAL'))
        lua.execute("wars[1]=true;fire('LOTM_Storm_Fire',{CastSerial=1,PlotIndex=6});impact()")
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'FIRED')

    def test_missing_api_preflight_applies_nothing(self):
        lua=runtime()
        lua.execute("LOTM_GodBlessings.GrantStorm(p,6,'FULL');u=UnitManager.InitUnit(0,1,11,10);target.improvement=3;ImprovementBuilder.SetImprovementPillaged=nil;cast()")
        self.assertEqual(lua.eval('stats.killed'),0)
        self.assertEqual(lua.eval('center.damage[0]'),20)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),1)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'NATIVE_UNAVAILABLE')

    def test_partial_failure_retry_reload_is_idempotent_and_not_cancelled(self):
        lua=runtime()
        lua.execute("LOTM_GodBlessings.GrantStorm(p,6,'FULL');u=UnitManager.InitUnit(0,1,10,10);u.resistant=true;failBuilding=true;cast();fire('LOTM_Storm_Cancel',{CastSerial=1})")
        self.assertEqual(lua.eval('u.damage'),50)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),1)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_APPLYING'),1)
        self.assertEqual(lua.eval('p.props.LOTM_GOD_FX_SERIAL'),1)
        lua.execute('failBuilding=false');lua.execute(blessing_source(False))
        lua.execute("fire('LOTM_Storm_Fire',{CastSerial=1,PlotIndex=6})")
        self.assertEqual(lua.eval('u.damage'),50)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),0)
        self.assertEqual(lua.eval('p.props.LOTM_GOD_FX_SERIAL'),1)

    def test_legacy_cleanup_removes_only_marked_entities_once(self):
        lua=runtime(debug=True)
        lua.execute("u=UnitManager.InitUnit(0,99,10,10);u.props.LOTM_STORM_CAST_SERIAL=2;p.props.LOTM_STORM_CAST_SERIAL=2;p.props.LOTM_STORM_CARRIER_ID=u:GetID();p.props.LOTM_STORM_SOURCE_PLOT=7;p.props.LOTM_STORM_SOURCE_TEMPORARY=1;gameprops.LOTM_STORM_ORIGIN_7_OWNER=0;gameprops.LOTM_STORM_ORIGIN_7_SERIAL=2;site.improvement=101;weapons.stock=1;p.props.LOTM_STORM_DELIVERY_MIGRATED=2;p.props.LOTM_STORM_PENDING=1;turns.GodBlessings(0);turns.GodBlessings(0)")
        self.assertEqual(lua.eval('stats.killed'),1)
        self.assertEqual(lua.eval('site.improvement'),-1)
        self.assertEqual(lua.eval('weapons.stock'),0)
        self.assertEqual(lua.eval('stats.improvementChanges'),1)

    def test_reused_carrier_or_existing_silo_is_preserved(self):
        lua=runtime(debug=True)
        lua.execute("u=UnitManager.InitUnit(0,99,10,10);u.props.LOTM_STORM_CAST_SERIAL=99;p.props.LOTM_STORM_CAST_SERIAL=2;p.props.LOTM_STORM_CARRIER_ID=u:GetID();site.improvement=101;p.props.LOTM_STORM_SOURCE_PLOT=7;p.props.LOTM_STORM_SOURCE_TEMPORARY=0;p.props.LOTM_STORM_DELIVERY_MIGRATED=2;turns.GodBlessings(0)")
        self.assertEqual(lua.eval('stats.killed'),0)
        self.assertEqual(lua.eval('site.improvement'),101)

    def test_aiming_expires_without_damage_or_charge(self):
        lua=runtime()
        lua.execute("LOTM_GodBlessings.GrantStorm(p,6,'FULL');fire('LOTM_Storm_Prepare',{ExpectedSerial=0});turn=11;turns.GodBlessings(0)")
        self.assertEqual(lua.eval('p.props.LOTM_STORM_CHARGES'),1)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_PENDING'),0)
        self.assertIsNone(lua.eval('p.props.LOTM_GOD_FX_SERIAL'))

    def test_direct_source_has_no_native_launch_or_new_entity(self):
        source=strip_trace((ROOT/'Scripts/LOTM_GodBlessings.lua').read_text(encoding='utf-8'))
        for forbidden in ['UnitManager.InitUnit','RequestOperation(', 'RequestCommand(', 'SetFallout(', 'LOTM_Storm_ResolveOrigin']:
            self.assertNotIn(forbidden,source)
        self.assertEqual(source.count('ImprovementBuilder.SetImprovementType('),1)
        self.assertIn('ImprovementBuilder.SetImprovementType(plot,-1,-1)',source)
        self.assertNotIn('ChangeWeaponCount(GameInfo',source)

    def test_map_click_own_preview_confirm_dispatches_only_direct_impact(self):
        lua=ui_runtime()
        lua.execute('inputHandler(input(6));inputHandler(input(1));inputHandler(input(2))')
        self.assertEqual(lua.eval('opened'),1)
        self.assertEqual(lua.eval('#requests'),0)
        self.assertEqual(lua.eval('#preview'),3)
        lua.execute('confirmation()')
        self.assertEqual(lua.eval('#requests'),1)
        self.assertEqual(lua.eval('requests[1].op'),55)
        self.assertEqual(lua.eval('requests[1].args.OnStart'),'LOTM_Storm_Fire')
        self.assertEqual(lua.eval('requests[1].args.PlotIndex'),6)
        self.assertEqual(lua.eval('mode'),1)
        lua.execute('fire(requests[1].args.OnStart,requests[1].args);impact()')
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'FIRED')
        self.assertEqual(lua.eval('stats.created+stats.improvementChanges+stats.weaponChanges'),0)

    def test_cancel_stale_popup_hidden_target_and_base_input(self):
        lua=ui_runtime();lua.execute('inputHandler(input(2));oldConfirm=confirmation;inputHandler(input(3));fire("LOTM_Storm_Cancel",requests[1].args);fire("LOTM_Storm_Prepare",{ExpectedSerial=1});mode=3;oldConfirm()')
        self.assertEqual(lua.eval('#requests'),1)
        lua.execute('cursor=999;inputHandler(input(2))')
        self.assertEqual(lua.eval('opened'),1)
        lua.execute('mode=4;result=inputHandler(input(2))')
        self.assertEqual(lua.eval('result'),'native')
        self.assertEqual(lua.eval('nativeCalls'),1)
        lua.execute('mode=3;rescue=true;GameConfiguration.GetValue=function() return 0 end;result=inputHandler(input(2))')
        self.assertEqual(lua.eval('result'),'native')

    def test_ui_only_requests_script_and_gameplay_declares_confirmed_war(self):
        lua=ui_runtime();lua.execute('Players[1]={};target.owner=1;wars[1]=false;inputHandler(input(2))')
        self.assertEqual(lua.eval('warList[1]'),1)
        self.assertEqual(lua.eval('#requests'),0)
        lua.execute('warConfirmation()')
        self.assertEqual(lua.eval('#requests'),1)
        self.assertEqual(lua.eval('requests[1].op'),55)
        self.assertEqual(lua.eval('requests[1].args.OnStart'),'LOTM_Storm_Fire')
        self.assertEqual(lua.eval('requests[1].args.ConfirmedWarOwners'),'1')
        lua.execute('fire(requests[1].args.OnStart,requests[1].args);impact()')
        self.assertEqual(lua.eval('stats.warDeclarations'),1)
        self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'FIRED')

    def test_wrong_unconfirmed_friend_or_failed_declaration_never_impacts(self):
        for setup,allowed in [('','2'),('allied=true','1'),('friend=true','1'),('blockedWar=true','1'),('failWar=true','1')]:
            lua=runtime(debug=True)
            lua.execute("Players[1]={};target.owner=1;wars[1]=false;fire('LOTM_Storm_Prepare',{ExpectedSerial=0});"+setup)
            lua.execute("fire('LOTM_Storm_Fire',{CastSerial=1,PlotIndex=6,ConfirmedWarOwners='"+allowed+"'})")
            self.assertEqual(lua.eval('p.props.LOTM_STORM_RESULT'),'WAR_REQUIRED')
            self.assertIsNone(lua.eval('p.props.LOTM_GOD_FX_SERIAL'))
            self.assertEqual(lua.eval('center.damage[0]'),20)

    def test_actual_firaxis_nuclear_functions_remain_untouched(self):
        native_root=Path(os.environ.get('LOTM_CIV6_ROOT',r"D:\app\steam\steamapps\common\Sid Meier's Civilization VI"))
        original=(native_root/'Base/Assets/UI/WorldInput.lua').read_text(encoding='utf-8-sig')
        start=original.index('function ICBMStrike(');end=original.index('function OnInterfaceModeChange_ICBM_Strike(',start)
        function=re.sub(r'\s*:\s*(?:number|string|boolean|table)\b','',original[start:end])
        lua=ui_runtime();lua.execute(r"""
          CityCommandTypes={WMD_STRIKE=60,PARAM_X0='x0',PARAM_Y0='y0',PARAM_X1='x1',PARAM_Y1='y1',PARAM_WMD_TYPE='wmd'};
          nativeLaunches=0;CityManager={CanStartCommand=function() return true end,
           RequestCommand=function(city,command,args) assert(command==60 and args.wmd==0);nativeLaunches=nativeLaunches+1 end};
          """)
        lua.execute(function);lua.execute('ICBMStrike(capital,10,10,target,0)')
        self.assertEqual(lua.eval('nativeLaunches'),1)
        self.assertEqual(lua.eval('#requests'),0)
        wrapper=strip_trace((ROOT/'UI/LOTM_StormWorldInput.lua').read_text(encoding='utf-8'))
        self.assertNotIn('function ICBMStrike(',wrapper)
        self.assertNotIn('function WMDStrike(',wrapper)

    def test_unique_district_buildings_and_wonder_plot(self):
        lua=runtime(debug=True)
        lua.execute("GameInfo.Districts[2]={DistrictType='DISTRICT_SEOWON'};campus=makedistrict(43,6,2);target.owner=0;cast()")
        self.assertTrue(lua.eval('capital.buildings:IsPillaged(1)'))
        lua=runtime(debug=True)
        lua.execute("GameInfo.Districts[2]={DistrictType='DISTRICT_WONDER'};wonder=makedistrict(43,6,2);target.owner=0;cast()")
        self.assertFalse(lua.eval('wonder.pillaged'))
        self.assertEqual(lua.eval('wonder.damage[0]'),20)

    def test_seven_hexes_bounded_queries_and_wrapped_plot_dedup(self):
        lua=runtime(debug=True)
        lua.execute('''plots={};districts={};PlayersVisibility[0].IsRevealed=function() return true end;
         for dy=-1,1 do for dx=-1,1 do
          if not ((dx==1 and dy==1) or (dx==-1 and dy==-1)) then
           local index=(dy+1)*3+dx+2;plots[index]=makeplot(index,20+dx,20+dy,-1,false);
           UnitManager.InitUnit(0,1,20+dx,20+dy);
          end
         end end;
         local native=Map.GetPlotXYWithRangeCheck;queries=0;
         Map.GetPlotXYWithRangeCheck=function(...) queries=queries+1;return native(...) end;
         cast(5);''')
        self.assertEqual(lua.eval('stats.killed'),7)
        self.assertEqual(lua.eval('queries'),18) # One bounded preflight and one impact snapshot.
        lua=runtime(debug=True)
        lua.execute('''districts={};target.improvement=3;target.owner=-1;
         Map.GetPlotXYWithRangeCheck=function() return target end;cast()''')
        self.assertEqual(lua.eval('stats.pillages'),1)

    def test_failed_impact_button_submits_retry_instead_of_reaiming(self):
        lua=ui_runtime()
        lua.execute('''function control() return {SetHide=function() end,SetText=function() end,
         SetDisabled=function() end,SetAlpha=function() end,SetOffsetX=function() end,SetOffsetY=function() end,
         ReprocessAnchoring=function() end,SetToolTipString=function() end,
         RegisterCallback=function(self,event,fn) self.click=fn end} end;
         Controls={Root=control(),Count=control(),StormButton=control(),StormIcon=control(),TargetHint=control(),HintText=control(),Cancel=control()};
         ContextPtr.SetHide=function() end;UIManager.GetScreenSizeVal=function() return 1920,1080 end;
         UILens.SetActive=function() end;Mouse={eLClick=1};SystemUpdateUI={ScreenResize=44};
         p.props.LOTM_STORM_APPLYING=1;p.props.LOTM_STORM_TARGET_PLOT=6;''')
        lua.execute(strip_trace((ROOT/'UI/LOTM_StormBlessing.lua').read_text(encoding='utf-8')))
        lua.execute('Controls.StormButton.click()')
        self.assertEqual(lua.eval('#requests'),1)
        self.assertEqual(lua.eval('requests[1].args.OnStart'),'LOTM_Storm_Fire')
        self.assertEqual(lua.eval('requests[1].args.PlotIndex'),6)
        self.assertEqual(lua.eval('requests[1].args.CastSerial'),1)


if __name__=="__main__":
    unittest.main()
