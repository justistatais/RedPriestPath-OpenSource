#!/usr/bin/env python3
"""Execute complete Lifecycle in Lua 5.1 against the real project-rule SQL.

Only the final Initialize call is replaced with private-function exports;
State methods, refresh recursion, purchases and advancement run unchanged.
The Civ VI database is copied to memory and never modified on disk. Native
resources/modifiers are deterministic mocks, so these are not in-game results.
"""
from __future__ import annotations

from functools import lru_cache
import hashlib
import os
from pathlib import Path
import re
import sqlite3
import sys
import unittest
import xml.etree.ElementTree as ET
import zipfile
import zlib

ROOT = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
DATABASE = Path(os.environ.get("LOCALAPPDATA", "")) / "Firaxis Games" / "Sid Meier's Civilization VI" / "Cache" / "DebugGameplay.sqlite"
# A shared selected snapshot survives positional-argument consumption by imported fixtures.
if os.environ.get("LOTM_TEST_GAMEPLAY_DATABASE"):
    DATABASE=Path(os.environ["LOTM_TEST_GAMEPLAY_DATABASE"])
BASELINE = ROOT.parent / "dist/RedPriestPath-0.1.0-rc.345.zip"
if len(sys.argv) > 1 and not sys.argv[1].startswith("-"):
    DATABASE = Path(sys.argv.pop(1))
try:
    from lupa.lua51 import LuaRuntime
except ImportError:
    sys.path.insert(0, str(ROOT.parent / ".tmp" / "refactor-rc340-python"))
    from lupa.lua51 import LuaRuntime


@lru_cache(maxsize=2)
def database_rows(rescue: bool):
    assert DATABASE.is_file(), f"Missing game database: {DATABASE}"
    db = sqlite3.connect(":memory:")
    db.row_factory = sqlite3.Row
    with sqlite3.connect(f"file:{DATABASE.as_posix()}?mode=ro", uri=True) as source:
        source.backup(db)
    db.create_function("Make_Hash", 1, lambda value: zlib.crc32(str(value).encode("utf-8")))
    # The captured game may be rescue. Reapply the exact normal prerequisites
    # from the canonical XML and the Black Emperor SQL before choosing mode.
    xml = ET.parse(ROOT / "Gameplay/LOTM_RP_Projects.xml")
    for row in xml.findall("./Projects/Row"):
        if row.get("PrereqTech"):
            db.execute("UPDATE Projects SET PrereqTech=? WHERE ProjectType=?", (row.get("PrereqTech"), row.get("ProjectType")))
    black = (ROOT / "Gameplay/LOTM_BE_BlackEmperor.sql").read_text(encoding="utf-8-sig")
    normal_update = re.search(r"UPDATE Projects\s+SET PrereqTech\s*=\s*'TECH_INDUSTRIALIZATION'.*?;", black, re.S)
    assert normal_update is not None
    db.executescript(normal_update.group())
    if rescue:
        rescue_sql = (ROOT / "Gameplay/LOTM_RESCUE_Phase9.sql").read_text(encoding="utf-8-sig")
        update = re.search(r"UPDATE Projects SET PrereqTech=NULL.*?;", rescue_sql, re.S)
        assert update is not None
        db.executescript(update.group())
    db.executescript((ROOT / "Gameplay/LOTM_PathProjectRules.sql").read_text(encoding="utf-8-sig"))
    rules = [dict(row) for row in db.execute("SELECT * FROM LOTM_PathProjectRules ORDER BY ProjectType")]
    assert len(rules) == 39
    projects = [dict(row) for row in db.execute("SELECT p.* FROM Projects p JOIN LOTM_PathProjectRules r USING(ProjectType)")]
    resources = [dict(row) for row in db.execute("SELECT s.* FROM Resources s JOIN LOTM_PathProjectRules r ON s.ResourceType=r.GateResourceType ORDER BY ResourceType")]
    technologies = [dict(row) for row in db.execute("SELECT * FROM Technologies WHERE TechnologyType IN (SELECT DISTINCT PrereqTech FROM Projects WHERE ProjectType IN (SELECT ProjectType FROM LOTM_PathProjectRules))")]
    db.close()
    return rules, projects, resources, technologies


HARNESS = r'''
function include() end
function print() end
rescue=false; turn=10; hasTech=true
Game={GetProperty=function(key) if key=="LOTM_RESCUE_MODE" then return rescue and 1 or 0 end end,
 GetCurrentGameTurn=function() return turn end}
GameConfiguration={GetValue=function() return rescue end}
LOTM_MP_TurnSync={IsRescueModeConfigured=function() return rescue end}
GameInfo={}
function Rows(rows,key)
 local result={}
 for index,row in ipairs(rows) do row.Index=index; result[row[key]]=row; result[index]=row end
 return setmetatable(result,{__call=function()
  local index=0; return function() index=index+1; return rows[index] end
 end})
end
function ResetPlayer(path,sequence,digestion,church)
 stats={attachments={},resourceReads={},resourceWrites={},propertyWrites={}}
 player={props={LOTM_RP_PATH=path,LOTM_RP_PATH_DECIDED=1,LOTM_RP_SEQUENCE=sequence,
  LOTM_RP_DIGEST_A=digestion,LOTM_RP_DIGEST_B=0,LOTM_RP_TRUE_GOD_CHURCH=church or 0,
  LOTM_RP_STATE_VERSION=36},resources={amounts={}}}
 function player:GetID() return 0 end
 function player:IsAlive() return true end
 function player:IsMajor() return true end
 function player:IsHuman() return true end
 function player:GetProperty(key) if self.props[key]~=nil then return self.props[key] end end
 function player:SetProperty(key,value) self.props[key]=value; stats.propertyWrites[#stats.propertyWrites+1]={key,value} end
 function player:GetResources() return self.resources end
 function player.resources:GetResourceAmount(index)
  stats.resourceReads[index]=(stats.resourceReads[index] or 0)+1
  return self.amounts[index] or 0
 end
 function player.resources:ChangeResourceAmount(index,amount)
  stats.resourceWrites[#stats.resourceWrites+1]={index,amount}
  self.amounts[index]=(self.amounts[index] or 0)+amount
 end
 function player:GetTechs() return {HasTech=function() return hasTech end} end
 function player:AttachModifierByID(id) stats.attachments[#stats.attachments+1]=id end
 Players={[0]=player}
 return player
end
function Count(t) local n=0; for _ in pairs(t) do n=n+1 end; return n end
function ResourceTotal() local total=0; for _,n in pairs(player.resources.amounts) do total=total+n end; return total end
function RuleGate(rule) return player.resources.amounts[GameInfo.Resources[rule.GateResourceType].Index] or 0 end
function AttachmentCount(id) local total=0; for _,value in ipairs(stats.attachments) do if id==value then total=total+1 end end; return total end
'''


def runtime(rescue=False, baseline=False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(HARNESS)
    lua.globals().rescue = rescue
    rules, projects, resources, technologies = database_rows(rescue)
    for table, rows, key in (
        ("LOTM_PathProjectRules", rules, "ProjectType"),
        ("Projects", projects, "ProjectType"),
        ("Resources", resources, "ResourceType"),
        ("Technologies", technologies, "TechnologyType"),
        ("Modifiers", [{"ModifierId": row["ModifierId"]} for row in rules], "ModifierId"),
    ):
        lua.globals().GameInfo[table] = lua.globals().Rows(lua.table_from(rows, recursive=True), key)
    lua.globals().rules = lua.table_from(rules, recursive=True)
    if baseline:
        with zipfile.ZipFile(BASELINE) as archive:
            name = next(name for name in archive.namelist() if name.endswith("/Scripts/LOTM_RP_Lifecycle.lua"))
            original = archive.read(name)
            assert hashlib.sha256(original).hexdigest() == "0a6e75f1e5cad7c256a197e54178e844a92a172948b38080c0f50f5f3e5c029e"
            source = original.decode("utf-8-sig")
    else:
        source = (ROOT / "Scripts/LOTM_RP_Lifecycle.lua").read_text(encoding="utf-8-sig")
    source = re.sub(r"\s*:(?:number|string|boolean|table)\b", "", source)
    source, replaced = re.subn(r"\bInitialize\(\);\s*$", "return {Refresh=RefreshProjectUnlock,Current=CurrentProjectRule,Sync=SyncProjectQualification};", source)
    assert replaced == 1
    lua.globals().API = lua.execute(source)
    return lua


class LifecycleRuleTests(unittest.TestCase):
    def test_all_39_rows_below_six_never_grant_project_or_resource(self):
        for rescue in (False, True):
            lua = runtime(rescue)
            lua.execute(r'''
            for _,rule in ipairs(rules) do for _,digestion in ipairs({0,1,5}) do
             ResetPlayer(rule.PathType,rule.FromSequence,digestion,rule.ChurchRequired==1 and 1 or 0)
             API.Refresh(0)
             assert(#stats.attachments==0,rule.ProjectType.." premature modifier at "..digestion)
             assert(ResourceTotal()==0 and #stats.resourceWrites==0,rule.ProjectType.." premature native prerequisite")
             assert(Count(stats.resourceReads)==39)
             assert((player.props[rule.UnlockFlag] or 0)==0)
            end end
            ''')

    def test_six_points_select_exact_path_sequence_and_church_variant(self):
        for rescue in (False, True):
            lua = runtime(rescue)
            lua.execute(r'''
            for _,rule in ipairs(rules) do
             ResetPlayer(rule.PathType,rule.FromSequence,6,rule.ChurchRequired==1 and 1 or 0)
             assert(API.Current(player).ProjectType==rule.ProjectType)
             assert(API.Refresh(0)==true,rule.ProjectType.." should unlock")
             assert(#stats.attachments==1 and stats.attachments[1]==rule.ModifierId,rule.ProjectType)
             assert(ResourceTotal()==1 and RuleGate(rule)==1)
             for _,other in ipairs(rules) do if other.ProjectType~=rule.ProjectType then assert(RuleGate(other)==0) end end
             local writes=#stats.resourceWrites; API.Refresh(0); API.Refresh(0)
             assert(#stats.attachments==1 and #stats.resourceWrites==writes)
            end
            ''')

    def test_normal_tech_gate_and_effective_rescue_null_prerequisite(self):
        normal = runtime(False)
        normal.execute(r'''
        local count=0
        for _,rule in ipairs(rules) do if GameInfo.Projects[rule.ProjectType].PrereqTech~=nil then
         count=count+1; hasTech=false; ResetPlayer(rule.PathType,rule.FromSequence,6,0)
         assert(API.Refresh(0)==false and ResourceTotal()==0 and #stats.attachments==0)
         assert(LOTM_RP_State.AdvanceSequence(0,rule.FromSequence,rule.ToSequence,true)==false)
         assert(player.props.LOTM_RP_SEQUENCE==rule.FromSequence)
         hasTech=true; assert(API.Refresh(0)==true and RuleGate(rule)==1)
        end end
        assert(count==3)
        ''')
        rescue = runtime(True)
        rescue.execute(r'''
        hasTech=false
        for _,rule in ipairs(rules) do
         assert(GameInfo.Projects[rule.ProjectType].PrereqTech==nil)
         ResetPlayer(rule.PathType,rule.FromSequence,6,rule.ChurchRequired==1 and 1 or 0)
         assert(API.Refresh(0)==true and RuleGate(rule)==1,rule.ProjectType.." rescue should unlock")
        end
        ''')

    def test_old_repair_unlock_flag_cannot_enable_one_point_thief(self):
        for rescue in (False, True):
            lua = runtime(rescue)
            lua.execute(r'''
            local rule=GameInfo.LOTM_PathProjectRules.PROJECT_LOTM_TP_SWINDLER_POTION
            ResetPlayer("PATH_THIEF",9,1,0)
            player.props.LOTM_RP_PROJECT_UNLOCK_REPAIR_VERSION=1
            player.props[rule.UnlockFlag]=1
            player.resources.amounts[GameInfo.Resources[rule.GateResourceType].Index]=1
            assert(API.Refresh(0)==false)
            assert(#stats.attachments==0 and RuleGate(rule)==0 and player.props[rule.UnlockFlag]==0)
            assert(player.props.LOTM_RP_SEQUENCE==9 and player.props.LOTM_RP_DIGEST_A==1)
            ''')

    def test_purchases_are_exact_current_project_and_wait_for_real_digestion(self):
        for rescue in (False, True):
            lua = runtime(rescue)
            lua.execute(r'''
            for _,rule in ipairs(rules) do if rule.FromSequence>=2 then
             ResetPlayer(rule.PathType,rule.FromSequence,1,0)
             player.props[rule.UnlockFlag]=1
             assert(LOTM_RP_State.RegisterPurchasedPotion(0,rule.FromSequence,"PROJECT_WRONG",11)==false)
             assert(player.props.LOTM_WORLD_PURCHASED_POTION_SEQUENCE==nil)
             assert(LOTM_RP_State.RegisterPurchasedPotion(0,rule.FromSequence,rule.ProjectType,11)==true)
             assert(player.props.LOTM_RP_SEQUENCE==rule.FromSequence and player.props.LOTM_RP_DIGEST_A==1)
             assert(player.props.LOTM_WORLD_PURCHASED_POTION_SEQUENCE==rule.FromSequence)
             assert(LOTM_RP_State.RegisterPurchasedPotion(0,rule.FromSequence,rule.ProjectType,12)==false)
             for _,points in ipairs({0,1,5}) do
              player.props.LOTM_RP_DIGEST_A=points
              assert(LOTM_RP_State.TryConsumePurchasedPotion(0)==false)
              assert(player.props.LOTM_WORLD_PURCHASED_POTION_SEQUENCE==rule.FromSequence)
             end
             player.props.LOTM_RP_DIGEST_A=6
             assert(LOTM_RP_State.TryConsumePurchasedPotion(0)==true)
             assert(player.props.LOTM_RP_SEQUENCE==rule.ToSequence and player.props.LOTM_RP_DIGEST_A==0)
             assert(player.props.LOTM_WORLD_PURCHASED_POTION_SEQUENCE==nil and ResourceTotal()==0)
             assert(LOTM_RP_State.TryConsumePurchasedPotion(0)==false)
            end end
            ''')

    def test_purchased_normal_potion_waits_for_technology(self):
        lua = runtime(False)
        lua.execute(r'''
        for _,rule in ipairs(rules) do if GameInfo.Projects[rule.ProjectType].PrereqTech~=nil then
         hasTech=false; ResetPlayer(rule.PathType,rule.FromSequence,6,0)
         assert(LOTM_RP_State.RegisterPurchasedPotion(0,rule.FromSequence,rule.ProjectType,7)==true)
         assert(player.props.LOTM_RP_SEQUENCE==rule.FromSequence,"purchase bypassed technology: "..rule.ProjectType)
         assert(player.props.LOTM_WORLD_PURCHASED_POTION_PROJECT==rule.ProjectType)
         assert(LOTM_RP_State.TryConsumePurchasedPotion(0)==false)
         hasTech=true; assert(LOTM_RP_State.TryConsumePurchasedPotion(0)==true)
         assert(player.props.LOTM_RP_SEQUENCE==rule.ToSequence)
        end end
        ''')

    def test_wrong_entitlement_stage_and_missing_church_cannot_advance(self):
        lua = runtime(False)
        lua.execute(r'''
        for _,rule in ipairs(rules) do
         ResetPlayer(rule.PathType,rule.FromSequence,6,rule.ChurchRequired==1 and 1 or 0)
         assert(LOTM_RP_State.AdvanceSequence(0,rule.FromSequence+1,rule.ToSequence,true)==false)
         assert(LOTM_RP_State.AdvanceSequence(0,rule.FromSequence,rule.ToSequence-1,true)==false)
         player.props.LOTM_WORLD_PURCHASED_POTION_SEQUENCE=rule.FromSequence
         player.props.LOTM_WORLD_PURCHASED_POTION_PROJECT="PROJECT_WRONG"
         assert(LOTM_RP_State.TryConsumePurchasedPotion(0)==false)
         if rule.FromSequence==1 then
          player.props.LOTM_RP_TRUE_GOD_CHURCH=0
          assert(LOTM_RP_State.AdvanceSequence(0,1,0,false)==false)
          assert(LOTM_RP_State.RegisterPurchasedPotion(0,1,rule.ProjectType,1)==false)
         end
         assert(player.props.LOTM_RP_SEQUENCE==rule.FromSequence)
        end
        ResetPlayer("NONE",9,6,0)
        assert(LOTM_RP_State.AdvanceSequence(0,9,8,true)==false)
        ''')

    def test_successful_advancement_clears_previous_gate_and_points(self):
        for rescue in (False, True):
            lua = runtime(rescue)
            lua.execute(r'''
            for _,rule in ipairs(rules) do
             ResetPlayer(rule.PathType,rule.FromSequence,6,rule.ChurchRequired==1 and 1 or 0)
             assert(API.Refresh(0)==true and RuleGate(rule)==1,rule.ProjectType.." before advance should unlock")
             assert(LOTM_RP_State.AdvanceSequence(0,rule.FromSequence,rule.ToSequence,rule.ChurchRequired~=1)==true)
             assert(player.props.LOTM_RP_SEQUENCE==rule.ToSequence)
             assert(player.props.LOTM_RP_DIGEST_A==0 and player.props.LOTM_RP_DIGEST_B==0)
             assert(ResourceTotal()==0 and RuleGate(rule)==0)
             assert(player.props.LOTM_PATH_PROJECT_GATE_ACTIVE=="")
             assert(LOTM_RP_State.AdvanceSequence(0,rule.FromSequence,rule.ToSequence,true)==false)
            end
            ''')

    def test_gate_migration_scans_once_then_only_previous_current_tokens(self):
        lua = runtime(True)
        lua.execute(r'''
        local first=GameInfo.LOTM_PathProjectRules.PROJECT_LOTM_TP_SWINDLER_POTION
        local second=GameInfo.LOTM_PathProjectRules.PROJECT_LOTM_TP_CRYPTOLOGIST_POTION
        ResetPlayer("PATH_THIEF",9,1,0)
        for _,rule in ipairs(rules) do player.resources.amounts[GameInfo.Resources[rule.GateResourceType].Index]=1 end
        API.Refresh(0)
        assert(Count(stats.resourceReads)==39 and #stats.resourceWrites==39 and ResourceTotal()==0)
        assert(player.props.LOTM_PATH_PROJECT_GATE_VERSION==1)
        stats.resourceReads={}; stats.resourceWrites={}
        for i=1,10 do API.Refresh(0) end
        assert(Count(stats.resourceReads)==0 and #stats.resourceWrites==0)
        player.props.LOTM_RP_DIGEST_A=6; API.Refresh(0)
        assert(Count(stats.resourceReads)==1 and #stats.resourceWrites==1 and RuleGate(first)==1)
        stats.resourceReads={}; stats.resourceWrites={}
        for i=1,10 do API.Refresh(0) end
        assert(Count(stats.resourceReads)==1 and #stats.resourceWrites==0)
        player.props.LOTM_RP_SEQUENCE=8; API.Refresh(0)
        assert(Count(stats.resourceReads)==2 and #stats.resourceWrites==2)
        assert(RuleGate(first)==0 and RuleGate(second)==1 and ResourceTotal()==1)
        ''')

    def test_fixed_rc345_positive_control_exhibits_both_original_bugs(self):
        self.assertTrue(BASELINE.is_file())
        lua = runtime(True, baseline=True)
        lua.execute(r'''
        local rule=GameInfo.LOTM_PathProjectRules.PROJECT_LOTM_TP_SWINDLER_POTION
        ResetPlayer("PATH_THIEF",9,1,0)
        player.props.LOTM_RP_PROJECT_UNLOCK_REPAIR_VERSION=1
        API.Refresh(0)
        assert(AttachmentCount(rule.ModifierId)>=1 and player.props[rule.UnlockFlag]==1)
        assert(player.props.LOTM_RP_DIGEST_A==1)
        -- Reproduce the false unlock flag being accepted as digestion proof.
        player.props.LOTM_WORLD_PURCHASED_POTION_SEQUENCE=9
        player.props.LOTM_WORLD_PURCHASED_POTION_PROJECT=rule.ProjectType
        player.props.LOTM_WORLD_PURCHASED_POTION_SERIAL=4
        assert(LOTM_RP_State.TryConsumePurchasedPotion(0)==true)
        assert(player.props.LOTM_RP_SEQUENCE==8 and player.props.LOTM_RP_DIGEST_A==0)
        ''')

    def test_failed_native_token_write_does_not_finish_migration_or_grant(self):
        lua = runtime(True)
        lua.execute(r'''
        local rule=GameInfo.LOTM_PathProjectRules.PROJECT_LOTM_TP_SWINDLER_POTION
        ResetPlayer("PATH_THIEF",9,6,0)
        local original=player.resources.ChangeResourceAmount
        player.resources.ChangeResourceAmount=function() end
        assert(API.Refresh(0)==false)
        assert(player.props.LOTM_PATH_PROJECT_GATE_VERSION==nil and #stats.attachments==0)
        player.resources.ChangeResourceAmount=original
        assert(API.Refresh(0)==true and RuleGate(rule)==1)
        assert(player.props.LOTM_PATH_PROJECT_GATE_VERSION==1 and #stats.attachments==1)
        ''')

    def test_saved_gate_version_survives_context_reload_without_full_rescan(self):
        before = runtime(True)
        before.execute('ResetPlayer("PATH_THIEF",9,6,0); API.Refresh(0)')
        props = dict(before.globals().player.props.items())
        resources = dict(before.globals().player.resources.amounts.items())
        after = runtime(True)
        after.execute('ResetPlayer("PATH_THIEF",9,6,0)')
        after.globals().player.props = after.table_from(props)
        after.globals().player.resources.amounts = after.table_from(resources)
        after.execute(r'''
        API.Refresh(0)
        assert(Count(stats.resourceReads)==1 and #stats.resourceWrites==0)
        assert(#stats.attachments==0 and ResourceTotal()==1)
        ''')


if __name__ == "__main__":
    unittest.main(verbosity=2)
