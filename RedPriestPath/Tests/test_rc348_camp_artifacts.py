#!/usr/bin/env python3
"""Exercise actual workshop reward queues with Lua 5.1, not the game engine."""
from __future__ import annotations

import hashlib
from pathlib import Path
import re
import sys
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
try:
    from lupa.lua51 import LuaRuntime
except ImportError:
    sys.path.insert(0, str(ROOT.parent / ".tmp/refactor-rc340-python"))
    from lupa.lua51 import LuaRuntime

BASELINE = ROOT.parent / "dist/RedPriestPath-0.1.0-rc.347.zip"
BASELINE_SHA = "514c60418877091ce3935798aab3707cba4764792d4c9ab632e7d17d908dc468"
RELATIVE = "Scripts/LOTM_PP_Workshops.lua"

HARNESS = r'''
turn=6; network=true; rescue=true; grants={}; notifications=0; logs={};
properties={}; propertyWrites=0; grantResult=true; grantType="ARTIFACT_TEST";
function print(s) logs[#logs+1]=tostring(s) end
function include() end
function Object(properties)
 local o={props=properties or {}};
 function o:GetProperty(k) return self.props[k] end
 function o:SetProperty(k,v) propertyWrites=propertyWrites+1; self.props[k]=v end
 return o
end
function Player(id,human,major)
 local p=Object(); p.id=id; p.human=human; p.major=major;
 function p:GetID() return self.id end
 function p:IsAlive() return true end
 function p:IsMajor() return self.major end
 function p:IsHuman() return self.human end
 return p
end
Players={[0]=Player(0,true,true),[1]=Player(1,true,true),[2]=Player(2,false,true),
 [20]=Player(20,false,false),[63]=Player(63,false,false)};
PlayerConfigurations={[20]={GetCivilizationLevelTypeName=function() return "CIVILIZATION_LEVEL_CITY_STATE" end}};
PlayerManager={GetAliveBarbarians=function() return {Players[63]} end};
plot=Object({LOTM_PP_WORKSHOP_CLASSIFIED=1,LOTM_PP_WORKSHOP_IS_WORKSHOP=1,
 LOTM_PP_WORKSHOP_LEVEL=2,LOTM_PP_WORKSHOP_PATH="PP",
 LOTM_PP_WORKSHOP_CAMP_EPOCH=1,LOTM_RESCUE_WORKSHOP_CLASSIFIED_TURN=0});
plot.improvement=-1;
function plot:GetIndex() return 3885 end
function plot:GetX() return 21 end
function plot:GetY() return 46 end
function plot:GetOwner() return 63 end
function plot:GetImprovementType() return self.improvement end
units={}; occupancy={};
function Unit(owner,id)
 local u={owner=owner,id=id,x=21,y=46};
 function u:GetOwner() return self.owner end
 function u:GetID() return self.id end
 function u:GetX() return self.x end
 function u:GetY() return self.y end
 function u:IsDead() return false end
 function u:IsDelayedDeath() return false end
 units[owner..":"..id]=u; return u;
end
UnitManager={GetUnit=function(owner,id) return units[owner..":"..id] end};
Units={GetUnitsInPlot=function(p) assert(p==plot); return occupancy end};
Map={GetPlotByIndex=function(i) return i==3885 and plot or nil end,
 GetPlot=function(x,y) return x==21 and y==46 and plot or nil end};
GameInfo={Improvements={IMPROVEMENT_BARBARIAN_CAMP={Index=7}},
 Units={UNIT_LOTM_PP_PATH_HOLDER={Index=10}},GreatWorks={ARTIFACT_TEST={Name="Artifact"}}};
Game={GetCurrentGameTurn=function() return turn end,
 GetProperty=function(k) return properties[k] end,
 SetProperty=function(k,v) propertyWrites=propertyWrites+1; properties[k]=v end,
 AddWorldViewText=function(...) notifications=notifications+1 end};
GameConfiguration={GetValue=function() return nil end};
Locale={Lookup=function(key,...) return key end};
LOTM_MP_TurnSync={IsNetworkGame=function() return network end,
 IsStableAnchorPlayer=function(id) return id==0 end,
 IsRescueModeConfigured=function() return rescue end};
LOTM_WORLD_Churches={OnWorkshopResolved=function() end};
LOTM_RESCUE_Phase4={OnWorkshopCleared=function() end};
function LOTM_PP_GrantWorkshopReward(owner,level,path,eventKey)
 if grantResult then grants[#grants+1]={owner=owner,level=level,path=path,eventKey=eventKey} end
 return grantResult,grantType
end
'''

EXPORT = r'''
API={removed=OnRemoved,move=OnUnitMoved,removals=ProcessNetworkImprovementRemovals,
 settle=ProcessNetworkWorkshopSettlements,loadRegistry=LoadWorkshopRegistry};
function Boundary(id) API.removals(id or 0); API.settle(id or 0) end
function Remove() API.removed(21,46,63) end
function Receipt(owner,id)
 local u=Unit(owner,id); plot.improvement=7; API.move(owner,id);
 plot.improvement=-1; occupancy={u};
end
'''


def source(baseline=False):
    if baseline:
        with zipfile.ZipFile(BASELINE) as archive:
            entry = next(n for n in archive.namelist() if n.endswith("/" + RELATIVE))
            data = archive.read(entry)
        assert hashlib.sha256(data).hexdigest() == BASELINE_SHA
        text = data.decode("utf-8-sig")
    else:
        text = (ROOT / RELATIVE).read_text(encoding="utf-8-sig")
    text = re.sub(r"\s*:\s*(?:number|boolean|string|table)\b", "", text)
    assert text.rstrip().endswith("Initialize();")
    return text.rstrip()[:-len("Initialize();")] + EXPORT


def runtime(baseline=False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(HARNESS)
    lua.execute(source(baseline))
    return lua


class CampRewardTests(unittest.TestCase):
    def test_departed_unrecorded_clearer_remains_unresolved(self):
        for old in (True, False):
            lua = runtime(old)
            lua.execute("occupancy={Unit(0,100)}; Remove(); occupancy={}; turn=7; Boundary(); turn=8; Boundary()")
            self.assertEqual(lua.eval("#grants"), 0)

    def test_no_receipt_different_local_occupancy_cannot_diverge_peers(self):
        for stays in (False, True):
            results = []
            for visible in (False, True):
                lua = runtime()
                lua.execute("u=Unit(0,100); occupancy=" + ("{u}" if visible else "{}") + "; Remove()")
                lua.execute("occupancy=" + ("{u}" if stays else "{}") + "; turn=7; Boundary(); turn=8; Boundary()")
                results.append((lua.eval("#grants"), lua.eval("plot.props.LOTM_PP_WORKSHOP_MP_PENDING_CLEARER")))
            expected = (1, 0) if stays else (0, None)
            self.assertEqual(results, [expected, expected])

    def test_legacy_boundary_fallback_reward_coverage_is_preserved(self):
        # A unique unit still at the later boundary may be the clearer or a
        # passer-by. The game state cannot distinguish these without a receipt.
        # Preserve rc347 compatibility until native attribution is proven.
        for old, expected in ((True, 1), (False, 1)):
            lua = runtime(old)
            lua.execute("occupancy={Unit(0,100)}; Remove(); turn=7; Boundary(); turn=8; Boundary()")
            self.assertEqual(lua.eval("#grants"), expected)

    def test_legacy_boundary_passerby_inference_risk_is_unchanged(self):
        for old, expected in ((True, 1), (False, 1)):
            lua = runtime(old)
            lua.execute("Remove(); occupancy={Unit(1,101)}; turn=7; Boundary(); turn=8; Boundary()")
            self.assertEqual(lua.eval("#grants"), expected)

    def test_clearer_is_not_replaced_by_later_human(self):
        lua = runtime()
        lua.execute("Receipt(1,100); Remove(); occupancy={Unit(0,101)}; turn=7; Boundary(); turn=8; Boundary()")
        self.assertEqual(lua.eval("grants[1].owner"), 1)

    def test_two_sync_edges_and_non_anchor_are_preserved(self):
        lua = runtime()
        lua.execute("Receipt(0,100); Remove(); Boundary(); turn=7; Boundary(1)")
        self.assertEqual(lua.eval("#grants"), 0)
        lua.execute("Boundary(); Boundary(); turn=8; Boundary(1)")
        self.assertEqual(lua.eval("#grants"), 0)
        lua.execute("Boundary(); Boundary()")
        self.assertEqual(lua.eval("#grants"), 1)

    def test_local_publication_makes_no_authoritative_writes(self):
        lua = runtime()
        lua.execute("occupancy={Unit(0,100)}; Remove()")
        self.assertEqual(lua.eval("propertyWrites"), 0)

    def test_synchronized_movement_receipt_survives_departure(self):
        for old in (False, True):
            lua = runtime(old)
            lua.execute("u=Unit(0,100); plot.improvement=7; API.move(0,100); plot.improvement=-1; occupancy={}; Remove(); turn=7; Boundary(); turn=8; Boundary()")
            self.assertEqual(lua.eval("#grants"), 1)

    def test_synchronized_receipt_resolves_both_peer_publication_orders(self):
        results = []
        # Local publication can precede or follow the shared movement event.
        # Both peers see the same synchronized receipt before consuming it.
        for order in ("REMOVE_FIRST", "MOVE_FIRST"):
            lua = runtime()
            lua.execute("u=Unit(0,100); plot.improvement=7")
            if order == "REMOVE_FIRST":
                lua.execute("occupancy={}; Remove(); API.move(0,100)")
            else:
                lua.execute("API.move(0,100); occupancy={u}; Remove()")
            lua.execute("plot.improvement=-1; occupancy={}; turn=7; Boundary(); turn=8; Boundary()")
            results.append((lua.eval("#grants"), lua.eval("grants[1].owner")))
        self.assertEqual(results, [(1, 0), (1, 0)])

    def test_synchronized_receipt_overrides_different_local_occupant(self):
        lua = runtime()
        lua.execute("occupancy={Unit(1,101)}; Remove(); u=Unit(0,100); plot.improvement=7; API.move(0,100); plot.improvement=-1; occupancy={}; turn=7; Boundary(); turn=8; Boundary()")
        self.assertEqual(lua.eval("grants[1].owner"), 0)

    def test_absent_movement_and_occupant_is_not_invented(self):
        lua = runtime()
        lua.execute("Remove(); occupancy={}; turn=7; Boundary(); turn=8; Boundary()")
        self.assertEqual(lua.eval("#grants"), 0)

    def test_older_camp_generation_cannot_reward(self):
        lua = runtime()
        lua.execute("Receipt(0,100); Remove(); plot.props.LOTM_PP_WORKSHOP_CAMP_EPOCH=2; turn=7; Boundary(); turn=8; Boundary()")
        self.assertEqual(lua.eval("#grants"), 0)

    def test_ai_city_state_and_barbarian_do_not_reward_humans(self):
        for owner in (2, 20, 63):
            lua = runtime()
            lua.execute(f"Receipt({owner},100); Remove(); turn=7; Boundary(); turn=8; Boundary()")
            self.assertEqual(lua.eval("#grants"), 0)

    def test_duplicate_remove_and_reloaded_settlement_are_once_only(self):
        lua = runtime()
        lua.execute("Receipt(0,100); Remove(); Remove(); turn=7; Boundary()")
        lua.execute(source())  # new Lua-local queues, same saved properties
        lua.execute("turn=8; Boundary(); turn=9; Boundary()")
        self.assertEqual(lua.eval("#grants"), 1)

    def test_legacy_reload_registry_fallback_unchanged(self):
        for old, expected in ((True, 1), (False, 1)):
            lua = runtime(old)
            lua.execute("properties.LOTM_PP_WORKSHOP_REGISTRY_PLOTS='3885'; occupancy={Unit(1,101)}; API.loadRegistry(); turn=7; Boundary()")
            self.assertEqual(lua.eval("#grants"), expected)

    def test_failed_grant_retries_and_complete_pool_commits(self):
        lua = runtime()
        lua.execute("Receipt(0,100); Remove(); turn=7; Boundary(); grantResult=false; turn=8; Boundary()")
        self.assertEqual(lua.eval("plot.props.LOTM_PP_WORKSHOP_MP_PENDING"), 1)
        lua.execute("grantResult=true; turn=9; Boundary(); turn=10; Boundary()")
        self.assertEqual(lua.eval("#grants"), 1)
        lua = runtime()
        lua.execute("Receipt(0,100); Remove(); turn=7; Boundary(); grantResult=false; grantType='COMPLETE'; turn=8; Boundary()")
        self.assertEqual(lua.eval("plot.props.LOTM_PP_WORKSHOP_REWARD_SETTLED"), 1)

    def test_single_player_existing_immediate_reward_unchanged(self):
        lua = runtime()
        lua.execute("network=false; occupancy={Unit(0,100)}; Remove()")
        self.assertEqual(lua.eval("#grants"), 1)


if __name__ == "__main__":
    unittest.main(verbosity=2)
