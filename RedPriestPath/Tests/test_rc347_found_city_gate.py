#!/usr/bin/env python3
"""Run actual rescue Thief founding gates in Lua 5.1; no in-game claim."""
from __future__ import annotations

import hashlib
import os
from pathlib import Path
import sqlite3
import sys
import unittest
import xml.etree.ElementTree as ET
import zipfile
import zlib

from test_rc346_thief_rule_guards import BASE, LuaRuntime
from generate_startup_trace import strip_trace

ROOT = Path(__file__).resolve().parents[1]
BASELINE = ROOT.parent / "dist/RedPriestPath-0.1.0-rc.346.zip"
DATABASE = Path(os.environ.get("LOCALAPPDATA", "")) / "Firaxis Games" / "Sid Meier's Civilization VI" / "Cache" / "DebugGameplay.sqlite"
# A shared selected snapshot survives positional-argument consumption by imported fixtures.
if os.environ.get("LOTM_TEST_GAMEPLAY_DATABASE"):
    DATABASE=Path(os.environ["LOTM_TEST_GAMEPLAY_DATABASE"])
if len(sys.argv) > 1 and Path(sys.argv[1]).suffix.lower() in {".sqlite", ".sqlite3", ".db"}:
    DATABASE = Path(sys.argv.pop(1))
BASELINE_HASHES = {
    "Scripts/LOTM_RESCUE_Thief.lua": "6b96f5f3b5896916bbc7ef97d1066e1cc69f87def8f88e17f3a35b4b92454263",
    "Gameplay/LOTM_RESCUE_Thief.sql": "4af8e59137dbe2766d1019c1bf0c2f47a4fca9df80550b812829b40003f5184b",
}


def source_file(relative: str, baseline=False):
    if not baseline:
        return (ROOT / relative).read_text(encoding="utf-8-sig")
    with zipfile.ZipFile(BASELINE) as archive:
        name = next(name for name in archive.namelist() if name.endswith("/" + relative))
        data = archive.read(name)
        assert hashlib.sha256(data).hexdigest() == BASELINE_HASHES[relative]
        return data.decode("utf-8-sig")


FIXTURE = r'''
rescue=true
for id=1,3 do Players[id].human=false end
hero={id=7,x=1,y=2,kind=11,owner=0,dead=false,delayed=false}
function hero:GetID() return self.id end
function hero:GetX() return self.x end
function hero:GetY() return self.y end
function hero:GetType() return self.kind end
function hero:GetOwner() return self.owner end
function hero:IsDead() return self.dead end
function hero:IsDelayedDeath() return self.delayed end
function hero:GetMovesRemaining() return 2 end
plot={index=12,x=1,y=2,improvement=3,city=false}
function plot:GetIndex() return self.index end
function plot:GetX() return self.x end
function plot:GetY() return self.y end
function plot:GetImprovementType() return self.improvement end
function plot:IsCity() return self.city end
Map={GetPlotByIndex=function(index) return index==12 and plot or nil end,
 GetPlot=function(x,y) return x==plot.x and y==plot.y and plot or nil end}
GameInfo.Improvements={IMPROVEMENT_BARBARIAN_CAMP={Index=3}}
GameInfo.Units={[11]={Index=11,UnitType="UNIT_LOTM_TP_PATH_HOLDER"},
 [12]={Index=12,UnitType="UNIT_SCOUT"},[13]={Index=13,UnitType="UNIT_LOTM_RESCUE_TIME_WORM"},
 [14]={Index=14,UnitType="UNIT_LOTM_RESCUE_CAMP_FOUNDER"}}
GameInfo.Units.UNIT_LOTM_TP_PATH_HOLDER=GameInfo.Units[11]
GameInfo.Units.UNIT_LOTM_RESCUE_TIME_WORM=GameInfo.Units[13]
GameInfo.Units.UNIT_LOTM_RESCUE_CAMP_FOUNDER=GameInfo.Units[14]
units={[7]=hero}
Players[0].props.LOTM_RP_UNIT_ID=hero.id
Players[0].GetUnits=function() return {FindID=function(_,id) return units[id] end,
 Members=function() return pairs(units) end} end
LOTM_RP_State.FindHero=function(id) return id==hero.owner and not hero.dead and hero or nil end
LOTM_RP_State.SnapshotHero=function(id,unit) assert(id==0 and unit==hero); stats.snapshots=(stats.snapshots or 0)+1 end
LOTM_RP_State.ScheduleRespawn=function(id)
 assert(id==0); stats.respawn=(stats.respawn or 0)+1
 Players[id].props.LOTM_RP_RESPAWN_AT=turn+5
 Players[id].props.LOTM_RP_UNIT_ID=-1
end
UnitCommandTypes={FOUND_CITY=1}
UnitOperationTypes={FOUND_CITY=2}
nativeResult=true; operationAllowed=true; delivery="ASYNC"; failCreate=false
city=nil
function DeliverCity(owner,cityID,x,y)
 city={owner=owner or 0,id=cityID or 5,x=x or plot.x,y=y or plot.y}
 function city:GetID() return self.id end
 function city:GetOwner() return self.owner end
 function city:GetX() return self.x end
 function city:GetY() return self.y end
 plot.improvement=-1; plot.city=true
 API.city(city.owner,city.id)
end
CityManager={GetCity=function(owner,id) return city~=nil and city.owner==owner and city.id==id and city or nil end}
Players[0].GetCities=function() return {FindID=function(_,id) return CityManager.GetCity(0,id) end,
 Members=function() return ipairs(city and {city} or {}) end} end
UnitManager={RequestCommand=function(unit,command,params)
 assert(unit==hero and command==UnitCommandTypes.FOUND_CITY)
 stats.nativeFound=stats.nativeFound+1
 if nativeResult=="ERROR" then error("native refusal") end
 return nativeResult
end,GetUnit=function(owner,id) return owner==0 and units[id] or nil end,
 InitUnit=function(owner,kind,x,y)
  if failCreate then return nil end
  local made=setmetatable({id=90+(stats.created or 0),x=x,y=y,kind=kind,owner=owner,dead=false,delayed=false},{__index=hero})
  stats.created=stats.created+1; units[made.id]=made
  stats.lastCreatedType=kind
  return made
 end,
 Kill=function(unit)
  assert(not unit.dead,"double native Kill")
  unit.dead=true; units[unit.id]=nil
  if unit==hero then stats.heroKilled=(stats.heroKilled or 0)+1 else stats.temporaryKilled=(stats.temporaryKilled or 0)+1 end
  if delivery=="REENTRANT" and city~=nil then API.city(city.owner,city.id) end
 end,
 CanStartOperation=function(unit,operation,_,params)
  assert(unit.kind==14 and operation==UnitOperationTypes.FOUND_CITY)
  stats.permissionChecks=(stats.permissionChecks or 0)+1
  if operationAllowed=="ERROR" then error("native permission refused") end
  return operationAllowed
 end,
 RequestOperation=function(unit,operation,params)
  assert(unit.kind==14 and unit~=hero and operation==UnitOperationTypes.FOUND_CITY)
  stats.nativeFound=stats.nativeFound+1
  if nativeResult=="ERROR" then error("native refusal") end
  if nativeResult==false then return false end
  if delivery=="SYNC_BEFORE_CONSUME" then DeliverCity() end
  unit.dead=true; units[unit.id]=nil
  if delivery=="SYNC" or delivery=="REENTRANT" then DeliverCity() end
  if nativeResult=="FALSE_AFTER_COMMIT" then return false end
  if nativeResult=="ERROR_AFTER_COMMIT" then error("native result after committed city") end
  return nativeResult
 end}
API={convert=LOTM_RESCUE_Thief.ConvertBarbarianCamp,command=OnConvert,
 city=OnCityBuilt}
'''


# Gameplay has no UI UnitManager operation APIs. Model city creation directly.
CITY_FIXTURE = r'''
UnitManager.CanStartOperation=nil; UnitManager.RequestOperation=nil; UnitOperationTypes=nil
function plot:IsWater() return self.water or false end
function plot:IsImpassable() return self.impassable or false end
function plot:GetDistrictType() return self.district or -1 end
function plot:GetWonderType() return self.wonder or -1 end
function plot:GetFeatureType() return self.feature or -1 end
function plot:GetOwner() return self.owner or -1 end
function plot:GetArea() return self.area or 1 end
GameInfo.Features={};GameInfo.GlobalParameters={CITY_MIN_RANGE={Value=3}}
Map.GetPlotXYWithRangeCheck=function(x,y,dx,dy,radius)
 stats.neighbors=(stats.neighbors or 0)+1
 if dx==0 and dy==0 then return plot end
 if dx==1 and dy==0 then return neighbor end
end
Map.GetPlotDistance=function() return neighborDistance or 3 end
CityManager.GetCityAt=function(x,y) return city and city.x==x and city.y==y and city or nil end
local oldGetCities=Players[0].GetCities
Players[0].GetCities=function()
 local cities=oldGetCities()
 cities.Create=function(_,x,y)
  stats.nativeFound=stats.nativeFound+1
  if failCreate or nativeResult==false then return nil end
  if nativeResult=="ERROR" then error("native city refusal") end
  creating=true
  DeliverCity(createOwner,createID,createX or x,createY or y)
  creating=false
  if nativeResult=="ERROR_AFTER_COMMIT" then error("native error after creation") end
  if nativeResult=="FALSE_AFTER_COMMIT" then return false end
  if nativeResult=="NIL_AFTER_COMMIT" then return nil end
  return city
 end
 return cities
end
Locale={Lookup=function(key,reason) return key..(reason and ":"..reason or "") end}
Game.AddWorldViewText=function(_,message) stats.message=message end
'''


def runtime(baseline=False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(BASE)
    lua.execute(source_file("Scripts/LOTM_Effects.lua"))
    lua.execute(source_file("Scripts/LOTM_RESCUE_Thief.lua", baseline) + "\n" + FIXTURE)
    if not baseline:
        lua.execute(CITY_FIXTURE)
    return lua


def ui_runtime():
    lua = runtime()
    lua.execute(r'''
    Locale={Lookup=function(key) return key end}
    Locale={Lookup=function(key) return key end}
    Game.GetLocalPlayer=function() return 0 end
    selected=hero
    UI={GetHeadSelectedUnit=function() return selected end,
     RequestPlayerOperation=function(id,kind,params)
      assert(id==0 and kind==1 and params.OnStart=="LOTM_RESCUE_Command_ConvertBarbarianCamp")
      assert(params.PlotIndex==12 and params.Mode=="SELF")
      stats.submitted=(stats.submitted or 0)+1
     end}
    PlayerOperations={EXECUTE_SCRIPT=1}
    function Control()
     local control={hidden=true}
     function control:SetHide(hidden) self.hidden=hidden end
     function control:SetToolTipString(text) self.tooltip=text end
     function control:SetDisabled(disabled) self.disabled=disabled end
     function control:ChangeParent(parent) self.parent=parent end
     function control:RegisterCallback(_,callback) self.callback=callback end
     function control:CalculateSize() end
     function control:ReprocessAnchoring() end
     return control
    end
    Controls={ActionButton=Control(),ModePopup=Control()}
    Events=setmetatable({},{__index=function(t,key)
     local event={callbacks={}}
     event.Add=function(callback) event.callbacks[#event.callbacks+1]=callback end
     t[key]=event; return event
    end})
    ContextPtr={SetHide=function() end,LookUpControl=function() return Control() end,
     SetRefreshHandler=function(self,handler) self.handler=handler end,
     RequestRefresh=function(self) if self.handler~=nil then self.handler() end end}
    Mouse={eLClick=1}
    ''')
    lua.execute(strip_trace(source_file("UI/LOTM_RESCUE_CampAction.lua")) + "\nUIAPI={refresh=Refresh,submit=Submit,setup=Setup}")
    lua.execute('UIAPI.setup()')
    return lua


class FoundCityGateTests(unittest.TestCase):
    def test_sequence_matrix(self):
        for sequence in range(10):
            lua=runtime();lua.globals().Players[0].props.LOTM_RP_SEQUENCE=sequence
            lua.execute("local allowed=Players[0].props.LOTM_RP_SEQUENCE<=4; assert(API.convert(0,12,'SELF')==allowed); assert(stats.nativeFound==(allowed and 1 or 0))")

    def test_authority_and_actor_guards(self):
        for setup in ('rescue=false','Players[0].props.LOTM_RP_PATH="PATH_PERFECT"','Players[0].alive=false','Players[0].human=false','Players[0].major=false','hero.dead=true','hero.delayed=true','hero.kind=12','hero.x=2','plot.city=true','LOTM_RP_State.FindHero=function() return nil end'):
            lua=runtime();lua.execute('Players[0].props.LOTM_RP_SEQUENCE=4;'+setup)
            lua.execute('assert(not API.convert(0,12,"SELF")); assert(stats.nativeFound==0 and stats.writes==0)')

    def test_invalid_plot_and_pending_do_not_mutate(self):
        lua=runtime();lua.execute('''Players[0].props.LOTM_RP_SEQUENCE=4
        for _,index in ipairs({-1,0,12.5,"bad",999}) do assert(not API.convert(0,index,"SELF")) end
        Players[0].props.LOTM_RESCUE_CAMP_CONVERT_PENDING=1; assert(not API.convert(0,12,"SELF"))
        assert(stats.nativeFound==0 and stats.writes==0)''')

    def test_failure_no_death_no_pending_or_turn_consumption(self):
        for result in (False,'ERROR'):
            lua=runtime();lua.globals().nativeResult=result
            lua.execute('''Players[0].props.LOTM_RP_SEQUENCE=4; assert(not API.convert(0,12,"SELF"))
            assert(not hero.dead and stats.nativeFound==1 and stats.created==0)
            assert(Players[0].props.LOTM_RESCUE_CAMP_CONVERT_PENDING==0 and Players[0].props.LOTM_RESCUE_CAMP_CONVERT_TURN==nil)
            assert(string.find(stats.message,"REASON_CREATE"))''')

    def test_city_confirmation_death_respawn_and_duplicate_event(self):
        for sequence in range(5):
            for delivery in ('SYNC','REENTRANT'):
                lua=runtime();lua.globals().Players[0].props.LOTM_RP_SEQUENCE=sequence;lua.globals().delivery=delivery
                lua.execute('''assert(API.convert(0,12,"SELF")); assert(hero.dead and stats.heroKilled==1 and stats.respawn==1)
                assert(Players[0].props.LOTM_RP_RESPAWN_AT==turn+5 and stats.created==0)
                assert(stats.points==(Players[0].props.LOTM_RP_SEQUENCE==4 and 1 or 0))
                API.city(0,5); API.city(0,5); assert(stats.heroKilled==1 and stats.respawn==1)''')

    def test_native_result_not_trusted_without_resolving_city(self):
        for result in ('FALSE_AFTER_COMMIT','ERROR_AFTER_COMMIT','NIL_AFTER_COMMIT'):
            lua=runtime();lua.globals().nativeResult=result
            lua.execute('Players[0].props.LOTM_RP_SEQUENCE=4; assert(API.convert(0,12,"SELF")); assert(stats.heroKilled==1)')
        for setup in ('createOwner=1','createX=99'):
            lua=runtime();lua.execute('Players[0].props.LOTM_RP_SEQUENCE=4;'+setup)
            lua.execute('assert(not API.convert(0,12,"SELF")); assert(not hero.dead and stats.points==0)')

    def test_hero_conversion_does_not_claim_existing_worm_or_its_cooldown(self):
        lua=runtime();lua.execute('''Players[0].props.LOTM_RP_SEQUENCE=1
        local worm=setmetatable({id=8,kind=13,dead=false},{__index=hero}); units[8]=worm
        Players[0].props.LOTM_RESCUE_TIME_WORM_ID=8; Players[0].props.LOTM_RESCUE_TIME_WORM_COOLDOWN=77
        assert(API.convert(0,12,"SELF")); assert(not worm.dead and units[8]==worm)
        assert(Players[0].props.LOTM_RESCUE_TIME_WORM_COOLDOWN==77)''')

    def test_fixed_rc346_positive_controls_reproduce_mode_and_pending_holes(self):
        for setup in ('rescue=false','Players[0].props.LOTM_RESCUE_CAMP_CONVERT_PENDING=1; Players[0].props.LOTM_RESCUE_CAMP_CONVERT_TURN=turn'):
            lua=runtime(baseline=True);lua.execute('Players[0].props.LOTM_RP_SEQUENCE=4;'+setup)
            lua.execute('assert(API.convert(0,12,"SELF")==true and stats.nativeFound==1)')


class FoundCityDatabaseTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(DATABASE.is_file())
        self.db = sqlite3.connect(":memory:")
        self.db.row_factory = sqlite3.Row
        with sqlite3.connect(f"file:{DATABASE.as_posix()}?mode=ro", uri=True) as original:
            original.backup(self.db)
        self.db.create_function("Make_Hash", 1, lambda value: zlib.crc32(str(value).encode("utf-8")))

    def tearDown(self):
        self.db.close()

    def test_native_holder_found_permission_removed_and_dedicated_actor_not_trainable(self):
        self.db.executescript(source_file("Gameplay/LOTM_RESCUE_Thief.sql"))
        units = {row["UnitType"]: row for row in self.db.execute(
            "SELECT * FROM Units WHERE UnitType IN ('UNIT_LOTM_TP_PATH_HOLDER','UNIT_LOTM_RESCUE_CAMP_FOUNDER','UNIT_LOTM_RESCUE_TIME_WORM')")}
        self.assertEqual(set(units), {"UNIT_LOTM_TP_PATH_HOLDER", "UNIT_LOTM_RESCUE_CAMP_FOUNDER", "UNIT_LOTM_RESCUE_TIME_WORM"})
        self.assertEqual(units["UNIT_LOTM_TP_PATH_HOLDER"]["FoundCity"], 0)
        self.assertEqual(units["UNIT_LOTM_RESCUE_TIME_WORM"]["FoundCity"], 0)
        helper = units["UNIT_LOTM_RESCUE_CAMP_FOUNDER"]
        self.assertEqual(helper["FoundCity"], 1)
        self.assertEqual(helper["CanTrain"], 0)
        self.assertEqual(helper["Cost"], -1)
        self.assertFalse(list(self.db.execute("PRAGMA foreign_key_check")))

    def test_fixed_rc346_database_exposed_native_action_to_every_holder(self):
        self.db.executescript(source_file("Gameplay/LOTM_RESCUE_Thief.sql", baseline=True))
        self.assertEqual(self.db.execute("SELECT FoundCity FROM Units WHERE UnitType='UNIT_LOTM_TP_PATH_HOLDER'").fetchone()[0], 1)

    def test_new_founder_database_is_rescue_criteria_only(self):
        modinfo = ET.parse(ROOT / "RedPriestPath.modinfo")
        database_actions = [node for node in modinfo.findall(".//UpdateDatabase")
                            if any((file.text or "").strip() == "Gameplay/LOTM_RESCUE_Thief.sql" for file in node.findall("File"))]
        self.assertEqual(len(database_actions), 1)
        self.assertEqual(database_actions[0].get("criteria"), "LOTM_RP_RESCUE_MODE")
        self.assertNotIn("UNIT_LOTM_RESCUE_CAMP_FOUNDER", source_file("Gameplay/LOTM_TP_Thief.sql"))

    def test_custom_city_action_is_registered_for_rescue_mode(self):
        modinfo = ET.parse(ROOT / "RedPriestPath.modinfo")
        actions = [node for node in modinfo.findall(".//AddUserInterfaces")
                   if any((file.text or "").strip() == "UI/LOTM_RESCUE_CampAction.xml" for file in node.findall("File"))]
        self.assertEqual(len(actions), 1)
        self.assertEqual(actions[0].get("criteria"), "LOTM_RP_RESCUE_MODE")


class FoundCityUITests(unittest.TestCase):
    def test_real_ui_shows_only_unlocked_sequence_on_current_hero_camp(self):
        for sequence in range(10):
            with self.subTest(sequence=sequence):
                lua = ui_runtime()
                lua.globals().Players[0].props.LOTM_RP_SEQUENCE = sequence
                lua.execute('UIAPI.refresh(); assert(Controls.ActionButton.hidden==(Players[0].props.LOTM_RP_SEQUENCE>4))')
        for setup in ('rescue=false', 'Players[0].props.LOTM_RP_PATH="PATH_PERFECT"',
                      'hero.kind=12', 'hero.owner=1', 'hero.dead=true',
                      'hero.delayed=true', 'selected=nil', 'plot.city=true',
                      'Players[0].props.LOTM_RESCUE_CAMP_CONVERT_PENDING=1',
                      'Players[0].props.LOTM_RESCUE_CAMP_CONVERT_TURN=turn'):
            with self.subTest(setup=setup):
                lua = ui_runtime()
                lua.execute('Players[0].props.LOTM_RP_SEQUENCE=4; ' + setup)
                lua.execute('UIAPI.refresh(); assert(Controls.ActionButton.hidden==true)')

    def test_ui_click_revalidates_changed_selection_before_sending(self):
        for setup in ('Players[0].props.LOTM_RP_SEQUENCE=9', 'rescue=false',
                      'plot.city=true', 'selected=nil', 'hero.x=9',
                      'Players[0].props.LOTM_RESCUE_CAMP_CONVERT_PENDING=1'):
            with self.subTest(setup=setup):
                lua = ui_runtime()
                lua.execute('Players[0].props.LOTM_RP_SEQUENCE=4; UIAPI.refresh(); assert(Controls.ActionButton.hidden==false)')
                lua.execute(setup + '; UIAPI.submit(); assert((stats.submitted or 0)==0)')
        lua = ui_runtime()
        lua.execute('Players[0].props.LOTM_RP_SEQUENCE=4; UIAPI.submit(); assert(stats.submitted==1)')


if __name__ == "__main__":
    unittest.main(verbosity=2)
