#!/usr/bin/env python3
"""Exercise path project callbacks and inherited relic grants in actual Lua 5.1.

The shared state helper is deliberately generic, as it is in the game: the
project handlers must enforce their own path. Native engine calls are mocked;
these checks are not evidence of an in-game or multiplayer acceptance run.
"""
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
try:
    from lupa.lua51 import LuaRuntime
except ImportError:
    sys.path.insert(0, str(ROOT.parent / ".tmp" / "refactor-rc340-python"))
    from lupa.lua51 import LuaRuntime

from generate_gameplay_bundle import read_network_source

PROJECTS = [
    ("PROVOKER_POTION", 9), ("PYROMANIAC_POTION", 8),
    ("CONSPIRATOR_POTION", 7), ("REAPER_POTION", 6),
    ("IRONBLOOD_KNIGHT_POTION", 5), ("WAR_BISHOP_POTION", 4),
    ("WEATHER_WARLOCK_POTION", 3), ("CONQUEROR_POTION", 2),
    ("WAR_FESTIVAL", 1), ("WAR_FESTIVAL_UNCONSECRATED", 1),
]

HARNESS = r'''
turn=10; network=false; rescue=false; path='PATH_RED_PRIEST'; sequence=9;
digestion=6; tech=true; church=true; advanceCalls={}; advances=0;
relics=0; digestCalls={}; digestLedger={}; turnGain={}; props={}; turns={};
function print(...) end
function Event()
 local e={callbacks={}};
 e.Add=function(f) e.callbacks[#e.callbacks+1]=f; end;
 e.Fire=function(...) for _,f in ipairs(e.callbacks) do f(...); end; end;
 return e;
end
function EventBus()
 return setmetatable({}, {__index=function(t,k) local e=Event(); rawset(t,k,e); return e; end});
end
Events=EventBus(); GameEvents=EventBus();
function EmptyRows() return function() return nil; end; end
GameInfo={Projects={},Units={},Beliefs={},Features={},Technologies=EmptyRows,
 Civics=EmptyRows,Districts=EmptyRows,Yields=EmptyRows,GreatWork_YieldChanges=EmptyRows,
 GreatPersonClasses={GREAT_PERSON_CLASS_SCIENTIST={Index=1}}};
Game={GetCurrentGameTurn=function() return turn; end,
 GetProperty=function(k) if k=='LOTM_RESCUE_MODE' then return rescue and 1 or 0; end; end};
GameConfiguration={GetValue=function() return rescue; end};
PlayerManager={GetAliveMajorIDs=function() return {}; end};
local player={};
player.GetProperty=function(_,k)
 if k=='LOTM_RP_CAN_ADVANCE_SEQUENCE_0' then return church and 1 or 0; end;
 return props[k];
end;
player.SetProperty=function(_,k,v) props[k]=v; end;
player.GetCities=function() return {Members=EmptyRows}; end;
player.GetTechs=function() return {HasTech=function() return tech; end}; end;
player.GetCulture=function() return {}; end;
player.GetGreatPeoplePoints=function() return {ChangePointsTotal=function() end}; end;
player.AttachModifierByID=function() end;
Players={[0]=player};
LOTM_UnitAddedPerf={Wrap=function(_,f) return f; end};
LOTM_MP_TurnSync={
 IsNetworkGame=function() return network; end,
 IsStableAnchorPlayer=function(id) return id==63; end,
 IsRescueModeConfigured=function() return rescue; end,
 Add=function(f,name) turns[name]=f; end,
 RunStartup=function() end
};
LOTM_RP_State={
 IsEnabledPlayer=function(id) return id==0 and path=='PATH_RED_PRIEST'; end,
 IsAnyPathPlayer=function(id) return id==0 and path~='NONE'; end,
 IsPerfectPlayer=function(id) return id==0 and path=='PATH_PERFECT'; end,
 GetPath=function() return path; end,
 GetSequence=function() return sequence; end,
 FindHero=function() return nil; end,
 RefreshSequenceState=function() end,
 AdvanceSequence=function(id,from,to,withoutChurch)
  advanceCalls[#advanceCalls+1]={id=id,from=from,to=to};
  if id~=0 or path=='NONE' or sequence~=from or digestion<6
   or (to==0 and not church and not withoutChurch) then return false; end;
  sequence=to; digestion=0; advances=advances+1; return true;
 end,
 TryAddDigestion=function(id,category,key)
  local ledger=tostring(sequence)..':'..category..':'..key;
  if digestLedger[ledger] or (turnGain[turn] or 0)>=2 then return false; end;
  digestLedger[ledger]=true; turnGain[turn]=(turnGain[turn] or 0)+1;
  digestCalls[#digestCalls+1]={sequence=sequence,category=category,key=key};
  return true;
 end,
 AttachModifierOnce=function(id,modifier,flag)
  if props[flag]==1 then return false; end;
  props[flag]=1;
  if string.find(modifier,'LOTM_PP_MOD_GRANT_RELIC_V3_',1,true)==1 then
   relics=relics+1;
   -- Firaxis may publish creation as a consequence of the relic modifier.
   Events.GreatWorkCreated.Fire(0,-1,3,4,5,relics);
  end;
  return true;
 end
};
function FlushProjects()
 turn=turn+1;
 for _,name in ipairs({'Progression','Advanced'}) do
  if turns[name] then turns[name](63,true); end;
 end;
end
function CountDigest(prefix)
 local n=0;
 for _,entry in ipairs(digestCalls) do
  if string.find(entry.key,prefix,1,true)==1 then n=n+1; end;
 end;
 return n;
end
'''


def standard_lua(source):
    return re.sub(r"\s*:\s*(?:boolean|number|string|table)\b", "", source)


def make_lua(perfect=False, sources=None):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(HARNESS)
    for index, (suffix, _) in enumerate(PROJECTS, 1):
        name = "PROJECT_LOTM_RP_" + suffix
        row = lua.table_from({"ProjectType": name, "Index": index})
        lua.globals().GameInfo.Projects[name] = row
        lua.globals().GameInfo.Projects[index] = row
    # Advanced checks the native technology table by key, while Perfect also
    # iterates it. Support both without inventing available technologies.
    lua.execute("GameInfo.Technologies=setmetatable({TECH_INDUSTRIALIZATION={Index=1}},"
                "{__call=function() return function() return nil; end; end});")
    names = ["LOTM_PP_Perfect.lua"] if perfect else [
        "LOTM_RP_Progression.lua", "LOTM_RP_Advanced.lua"]
    for name in names:
        source = (sources[name] if sources else
                  (ROOT / "Scripts" / name).read_text(encoding="utf-8-sig"))
        lua.execute(standard_lua(source), name=name)
    return lua


class PathProjectRulesTests(unittest.TestCase):
    def test_wrong_paths_cannot_consume_red_priest_projects(self):
        for network in (False, True):
            for rescue in (False, True):
                for path in ("PATH_PERFECT", "PATH_BLACK_EMPEROR", "PATH_THIEF", "NONE"):
                    for index, (suffix, sequence) in enumerate(PROJECTS, 1):
                        with self.subTest(network=network, rescue=rescue, path=path, project=suffix):
                            lua = make_lua()
                            g = lua.globals()
                            g.network, g.rescue, g.path, g.sequence = network, rescue, path, sequence
                            g.Events.CityProjectCompleted.Fire(0, 100, index)
                            if network:
                                g.FlushProjects()
                            self.assertEqual(lua.eval("#advanceCalls"), 0)
                            self.assertEqual(g.sequence, sequence)
                            self.assertEqual(g.digestion, 6)

    def test_red_priest_projects_still_advance_once(self):
        for network in (False, True):
            for rescue in (False, True):
                for index, (suffix, sequence) in enumerate(PROJECTS, 1):
                    with self.subTest(network=network, rescue=rescue, project=suffix):
                        lua = make_lua()
                        g = lua.globals()
                        g.network, g.rescue, g.sequence = network, rescue, sequence
                        g.Events.CityProjectCompleted.Fire(0, 100, index)
                        g.Events.CityProjectCompleted.Fire(0, 100, index)
                        if network:
                            self.assertEqual(g.advances, 0)
                            g.FlushProjects()
                        self.assertEqual(g.advances, 1)
                        self.assertEqual(g.sequence, sequence - 1)
                        self.assertEqual(g.digestion, 0)

    def test_existing_digestion_technology_and_church_guards_remain(self):
        for network in (False, True):
            for sequence, index, key in ((9, 1, "digestion"), (5, 5, "tech"), (1, 9, "church")):
                with self.subTest(network=network, guard=key):
                    lua = make_lua()
                    g = lua.globals()
                    g.network, g.sequence = network, sequence
                    setattr(g, key, 5 if key == "digestion" else False)
                    g.Events.CityProjectCompleted.Fire(0, 100, index)
                    if network:
                        g.FlushProjects()
                    self.assertEqual(g.advances, 0)
                    self.assertEqual(g.sequence, sequence)

    def test_queued_project_rechecks_path_before_applying(self):
        for index in (1, 5):
            lua = make_lua()
            g = lua.globals()
            g.network, g.sequence = True, PROJECTS[index - 1][1]
            g.Events.CityProjectCompleted.Fire(0, 100, index)
            g.path = "PATH_PERFECT"
            g.FlushProjects()
            self.assertEqual(lua.eval("#advanceCalls"), 0)


class InheritedRelicRulesTests(unittest.TestCase):
    def start(self, network=False):
        lua = make_lua(perfect=True)
        g = lua.globals()
        g.path, g.sequence, g.network = "PATH_PERFECT", 8, network
        g.LOTM_PP_OnPathSelected(0)
        self.assertEqual(g.relics, 1)
        self.assertEqual(g.CountDigest("PERFECT_RELIC:"), 1)
        return lua

    def test_five_inherited_relics_do_not_digest_later_sequences(self):
        for network in (False, True):
            for sequence in (6, 5, 4, 3, 2, 1, 0):
                with self.subTest(network=network, sequence=sequence):
                    lua = self.start(network)
                    g = lua.globals()
                    g.sequence = sequence
                    for turn in (15, 20, 25, 30, 35):
                        g.turn = turn
                        g.turns.Perfect(0, True)
                    self.assertEqual(g.relics, 5)
                    self.assertEqual(g.CountDigest("PERFECT_RELIC:"), 1)
                    self.assertEqual(lua.eval("#digestCalls"), 1)

    def test_sequence_eight_still_digests_all_five_relics(self):
        lua = self.start()
        g = lua.globals()
        for turn in (15, 20, 25, 30, 35):
            g.turn = turn
            g.turns.Perfect(0, True)
            g.turns.Perfect(0, True)
        self.assertEqual(g.relics, 5)
        self.assertEqual(g.CountDigest("PERFECT_RELIC:"), 5)

    def test_sequence_seven_uses_only_its_great_work_tasks(self):
        for network in (False, True):
            with self.subTest(network=network):
                lua = self.start(network)
                g = lua.globals()
                g.sequence, g.turn = 7, 15
                g.turns.Perfect(0, True)
                # Duplicate publication of the same work must retain its
                # stable acquired/placed keys rather than add a relic task.
                g.Events.GreatWorkCreated.Fire(0, -1, 3, 4, 5, 2)
                if network:
                    g.turn = 16
                    g.turns.Perfect(63, True)
                self.assertEqual(g.relics, 2)
                self.assertEqual(g.CountDigest("PERFECT_RELIC:"), 1)
                self.assertEqual(g.CountDigest("GREAT_WORK_ACQUIRED:"), 1)
                self.assertEqual(g.CountDigest("GREAT_WORK_PLACED:"), 1)


class PublishedNetworkRuleTests(unittest.TestCase):
    """Run the actual rc.241-derived production source, not today's dead branch."""

    @classmethod
    def setUpClass(cls):
        cls.sources = {name + ".lua": read_network_source(name) for name in (
            "LOTM_RP_Progression", "LOTM_RP_Advanced", "LOTM_PP_Perfect")}

    def test_network_project_handlers_reject_other_paths(self):
        for rescue in (False, True):
            for path in ("PATH_PERFECT", "PATH_BLACK_EMPEROR", "PATH_THIEF", "NONE"):
                for index, (suffix, sequence) in enumerate(PROJECTS, 1):
                    with self.subTest(rescue=rescue, path=path, project=suffix):
                        lua = make_lua(sources=self.sources)
                        g = lua.globals()
                        g.network, g.rescue, g.path, g.sequence = True, rescue, path, sequence
                        g.Events.CityProjectCompleted.Fire(0, 100, index)
                        self.assertEqual(lua.eval("#advanceCalls"), 0)
                        self.assertEqual(g.sequence, sequence)
                        self.assertEqual(g.digestion, 6)

    def test_network_keeps_original_direct_project_timing(self):
        for rescue in (False, True):
            for index, (suffix, sequence) in enumerate(PROJECTS, 1):
                with self.subTest(rescue=rescue, project=suffix):
                    lua = make_lua(sources=self.sources)
                    g = lua.globals()
                    g.network, g.rescue, g.sequence = True, rescue, sequence
                    g.Events.CityProjectCompleted.Fire(0, 100, index)
                    self.assertEqual(g.advances, 1)
                    self.assertEqual(g.sequence, sequence - 1)
                    g.Events.CityProjectCompleted.Fire(0, 100, index)
                    self.assertEqual(g.advances, 1)
                    self.assertIsNone(g.turns.Progression)
                    self.assertIsNone(g.turns.Advanced)

    def test_network_inherits_relics_without_archaeologist_digestion(self):
        for sequence in range(9):
            with self.subTest(sequence=sequence):
                lua = make_lua(perfect=True, sources=self.sources)
                g = lua.globals()
                g.path, g.sequence, g.network = "PATH_PERFECT", 8, True
                g.LOTM_PP_OnPathSelected(0)
                self.assertEqual(g.relics, 1)
                g.sequence = sequence
                for turn in (15, 20, 25, 30, 35):
                    g.turn = turn
                    g.Events.PlayerTurnActivated.Fire(0, True)
                self.assertEqual(g.relics, 5)
                self.assertEqual(g.CountDigest("PERFECT_RELIC:"), 5 if sequence == 8 else 1)
                if sequence == 7:
                    self.assertEqual(g.CountDigest("GREAT_WORK_ACQUIRED:"), 4)
                    self.assertEqual(g.CountDigest("GREAT_WORK_PLACED:"), 4)
                else:
                    self.assertEqual(lua.eval("#digestCalls"), 5 if sequence == 8 else 1)

    def test_only_reviewed_function_spans_change_in_rc241(self):
        from validate_gameplay_bundle import validate_network_rule_sources
        validate_network_rule_sources()


if __name__ == "__main__":
    unittest.main(verbosity=2)
