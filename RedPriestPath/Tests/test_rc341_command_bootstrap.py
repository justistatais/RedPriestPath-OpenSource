#!/usr/bin/env python3
"""Exercise the actual network city script and UI in Lua, with native API stubs.

The request queue deliberately stays separate from UI callbacks.  The test
proves when the Lua code requests and creates cities; it cannot prove that
Civ VI's native city/event processing survives in an actual hosted room.
"""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
try:
    from lupa import LuaRuntime
except ImportError:
    sys.path.insert(0, str(ROOT.parent / ".tmp" / "refactor-rc340-python"))
    from lupa import LuaRuntime


HARNESS = r'''
network=true; active=false; turn=1; props={}; requests={}; logs={};
stats={cities=0, walls=0, core=0, damage=0, loyalty=0, tech=0, civic=0};
function Event()
    local e={listeners={}};
    e.Add=function(fn) e.listeners[#e.listeners+1]=fn; end;
    e.Fire=function(...) local count=#e.listeners; for i=1,count do e.listeners[i](...); end; end;
    return e;
end
function EventsTable()
    return setmetatable({}, {__index=function(t,k) local e=Event(); rawset(t,k,e); return e; end});
end
Events=EventsTable(); GameEvents=EventsTable();
print=function(value) logs[#logs+1]=tostring(value); end;
Game={
    GetProperty=function(k) return props[k]; end,
    SetProperty=function(k,v) props[k]=v; end,
    GetCurrentGameTurn=function() return turn; end,
    GetLocalPlayer=function() return 0; end
};
GameConfiguration={
    IsAnyMultiplayer=function() return network; end,
    GetValue=function(k)
        if k=='GAMEMODE_LOTM_RESCUE' then return true; end
        if k=='CITY_STATE_COUNT' then return 12; end
        if k=='LOTM_RP_TEXT_LANGUAGE' then return 'en_US'; end
    end
};
GameInfo={
    Resources={RESOURCE_LOTM_RESCUE_ALLY_BANNER={Index=0}},
    Technologies={TECH_CASTLES={Index=10}},
    Civics={CIVIC_MEDIEVAL_FAIRES={Index=20}},
    Buildings={BUILDING_LOTM_RESCUE_SEAL_CORE={Index=100},
        BUILDING_WALLS={Index=101}, BUILDING_CASTLE={Index=102}, BUILDING_STAR_FORT={Index=103}}
};
DefenseTypes={DISTRICT_OUTER=0,DISTRICT_GARRISON=1};
plots={}; citiesByPlot={}; citiesByID={};
for i=0,75 do
    local p={index=i,owner=62};
    p.GetIndex=function(self) return self.index; end;
    p.GetX=function(self) return self.index; end;
    p.GetY=function(self) return 0; end;
    p.GetOwner=function(self) return self.owner; end;
    p.SetOwner=function(self,owner) self.owner=owner; end;
    p.GetDistrictType=function(self) return citiesByPlot[self.index]~=nil and 0 or -1; end;
    plots[i]=p;
end
Map={GetPlotByIndex=function(i) return plots[i]; end};
local cityCollection={};
cityCollection.Create=function(self,x,y)
    assert(citiesByPlot[x]==nil,'a city was created twice');
    stats.cities=stats.cities+1;
    local city={id=stats.cities*65536,plot=x,owner=62,population=1,buildings={},properties={}};
    city.GetID=function(self) return self.id; end;
    city.GetOwner=function(self) return self.owner; end;
    city.GetX=function(self) return self.plot; end;
    city.GetY=function(self) return 0; end;
    city.SetName=function(self,name) self.name=name; end;
    city.GetPopulation=function(self) return self.population; end;
    city.ChangePopulation=function(self,n) self.population=self.population+n; end;
    city.SetProperty=function(self,k,v) self.properties[k]=v; end;
    city.ChangeLoyalty=function(self,n) stats.loyalty=stats.loyalty+1; end;
    city.GetBuildings=function(self)
        return {HasBuilding=function(_,index) return self.buildings[index]==true; end};
    end;
    city.GetBuildQueue=function(self)
        return {CreateBuilding=function(_,index)
            assert(not self.buildings[index],'a building was created twice');
            self.buildings[index]=true;
            if index==100 then stats.core=stats.core+1; else stats.walls=stats.walls+1; end;
        end};
    end;
    citiesByPlot[x]=city; citiesByID[city.id]=city;
    return city;
end;
cityCollection.FindID=function(self,id) return citiesByID[id]; end;
CityManager={
    GetCityAt=function(x,y) return citiesByPlot[x]; end,
    GetDistrictAt=function(x,y)
        if citiesByPlot[x]==nil then return nil; end;
        return {SetDamage=function(_,kind,value) assert(value==0); stats.damage=stats.damage+1; end};
    end
};
function Player(id,human,major)
    return {
        GetID=function() return id; end,
        IsAlive=function() return true; end,
        IsMajor=function() return major; end,
        IsHuman=function() return human; end,
        IsBarbarian=function() return false; end,
        IsTurnActive=function() return active; end,
        GetCities=function() return cityCollection; end,
        GetEra=function() return 0; end,
        GetTechs=function() return {
            HasTech=function() return stats.tech>0; end,
            GetResearchCost=function() return 100; end,
            SetResearchProgress=function(_,index,progress) assert(index==10 and progress==100); stats.tech=stats.tech+1; end
        }; end,
        GetCulture=function() return {
            HasCivic=function() return stats.civic>0; end,
            GetCultureCost=function() return 100; end,
            SetCulturalProgress=function(_,index,progress) assert(index==20 and progress==100); stats.civic=stats.civic+1; end
        }; end
    };
end
Players={[0]=Player(0,true,true),[1]=Player(1,false,true),[62]=Player(62,false,false)};
local minors={}; for i=1,12 do minors[i]={}; end;
PlayerManager={
    GetAliveMajors=function() return {Players[1],Players[0]}; end,
    GetAliveMinors=function() return minors; end,
    GetFreeCitiesPlayerID=function() return 62; end
};
props.LOTM_RESCUE_PHASE1_STATE='READY';
for zoneNumber,zone in ipairs({'CENTER','FOOL','NIGHT','STORM'}) do
    local first=(zoneNumber-1)*19; local indices={};
    for i=first,first+18 do indices[#indices+1]=tostring(i); end;
    props['LOTM_RESCUE_'..zone..'_PLOT']=first;
    props['LOTM_RESCUE_'..zone..'_TERRITORY']=table.concat(indices,',');
end
PlayerOperations={EXECUTE_SCRIPT=55};
UI={RequestPlayerOperation=function(id,operation,args)
    assert(id==0 and operation==PlayerOperations.EXECUTE_SCRIPT);
    requests[#requests+1]={id=id,args=args};
    return true;
end};
function CountRequests(command)
    local count=0; for _,request in ipairs(requests) do if request.args.OnStart==command then count=count+1; end; end;
    return count;
end
function DispatchRequest(index)
    local request=requests[index];
    GameEvents[request.args.OnStart].Fire(request.id,request.args);
end
function AssertFullCityResult()
    assert(stats.cities==4 and stats.walls==12 and stats.core==4);
    assert(stats.tech==1 and stats.civic==1);
    assert(props.LOTM_RESCUE_PHASE2A_STATE=='READY');
    assert(props.LOTM_RESCUE_PHASE2A_VERSION==11);
    assert(props.LOTM_RESCUE_PHASE2A_FAILURE=='NONE');
    local owned=0; for i=0,75 do if plots[i]:GetOwner()==62 then owned=owned+1; end; end;
    assert(owned==76);
    for _,zone in ipairs({'CENTER','FOOL','NIGHT','STORM'}) do
        local id=props['LOTM_RESCUE_'..zone..'_CITY_ID'];
        assert(citiesByID[id]~=nil and citiesByID[id]:GetPopulation()==1);
    end;
end
'''


class CommandBootstrapTests(unittest.TestCase):
    def runtime(self, setup=""):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(HARNESS)
        lua.execute(setup)
        return lua

    def load(self, lua, relative):
        lua.execute((ROOT / relative).read_text(encoding="utf-8-sig"))

    def test_solo_host_waits_for_queued_ui_command_and_creates_once(self):
        lua = self.runtime()
        self.load(lua, "Scripts/LOTM_MP241_Phase2.lua")
        self.load(lua, "UI/LOTM_RESCUE_CityBootstrap.lua")
        lua.execute(r'''
            assert(stats.cities==0 and #requests==0);
            Events.LoadScreenClose.Fire();
            assert(stats.cities==0 and #requests==0);
            GameEvents.PlayerTurnStarted.Fire(0);
            assert(stats.cities==0 and #requests==0);
            active=true;
            Events.LocalPlayerTurnBegin.Fire();
            Events.GameCoreEventPublishComplete.Fire();
            Events.PlayerTurnActivated.Fire(0,true);
            Events.GameCoreEventPublishComplete.Fire();
            assert(#requests==1 and stats.cities==0);
            assert(requests[1].args.OnStart=='LOTM_RESCUE_Command_BootstrapCity');
            DispatchRequest(1);
            AssertFullCityResult();
            local previousDamage=stats.damage;
            local previousLoyalty=stats.loyalty;
            GameEvents.LOTM_RESCUE_Command_BootstrapCity.Fire(0,{Trigger='DUPLICATE'});
            AssertFullCityResult();
            assert(stats.damage==previousDamage and stats.loyalty==previousLoyalty);
            Events.GameCoreEventPublishComplete.Fire();
            Events.GameCoreEventPublishComplete.Fire();
            assert(CountRequests('LOTM_RESCUE_Command_BootstrapCity')==1);
            assert(CountRequests('LOTM_MP241_Command_LoadMain')==1);
        ''')

    def test_turn_start_never_creates_even_after_player_becomes_active(self):
        lua = self.runtime("active=true;")
        self.load(lua, "Scripts/LOTM_MP241_Phase2.lua")
        lua.execute(r'''
            for nextTurn=1,4 do
                turn=nextTurn;
                GameEvents.PlayerTurnStarted.Fire(0);
                GameEvents.PlayerTurnStarted.Fire(1);
                GameEvents.PlayerTurnStarted.Fire(62);
            end;
            assert(stats.cities==0 and stats.walls==0 and stats.tech==0 and stats.civic==0);
            assert(props.LOTM_RESCUE_PHASE2A_STATE==nil);
        ''')

    def test_ready_save_only_requests_main_recovery_without_creating_cities(self):
        lua = self.runtime(r'''
            props.LOTM_RESCUE_PHASE2A_STATE='READY';
            props.LOTM_RESCUE_PHASE2A_VERSION=11;
            props.LOTM_MP241_MAIN_LOAD_STATE='LOADED';
            active=true;
        ''')
        self.load(lua, "Scripts/LOTM_MP241_Phase2.lua")
        self.load(lua, "UI/LOTM_RESCUE_CityBootstrap.lua")
        lua.execute(r'''
            GameEvents.PlayerTurnStarted.Fire(0);
            Events.LoadScreenClose.Fire();
            Events.LocalPlayerTurnBegin.Fire();
            Events.GameCoreEventPublishComplete.Fire();
            assert(CountRequests('LOTM_RESCUE_Command_BootstrapCity')==0);
            assert(CountRequests('LOTM_MP241_Command_LoadMain')==1);
            GameEvents.LOTM_RESCUE_Command_BootstrapCity.Fire(0,{Trigger='OLD_SAVE_DUPLICATE'});
            assert(stats.cities==0 and stats.walls==0 and stats.core==0);
        ''')

    def test_nonhuman_request_rejected_before_any_native_mutation(self):
        lua = self.runtime()
        self.load(lua, "Scripts/LOTM_MP241_Phase2.lua")
        lua.execute(r'''
            GameEvents.LOTM_RESCUE_Command_BootstrapCity.Fire(1,{});
            GameEvents.LOTM_RESCUE_Command_BootstrapCity.Fire(62,{});
            assert(stats.cities==0 and stats.tech==0 and stats.civic==0);
        ''')

    def test_network_phase2_has_no_singleplayer_registration_or_writes(self):
        lua = self.runtime("network=false;")
        self.load(lua, "Scripts/LOTM_MP241_Phase2.lua")
        lua.execute(r'''
            assert(next(Events)==nil and next(GameEvents)==nil);
            assert(stats.cities==0 and stats.walls==0 and stats.tech==0);
            assert(props.LOTM_RESCUE_PHASE2A_STATE==nil);
            for _,line in ipairs(logs) do assert(string.find(line,'[LOTM_DIAG]',1,true)~=nil); end;
        ''')


if __name__ == "__main__":
    unittest.main(verbosity=2)
