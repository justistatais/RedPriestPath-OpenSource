"""Normal-mode removal and counseling rules; does not simulate Civ serialization."""
from pathlib import Path
import os, re, sqlite3, sys, unittest, zlib
from test_rc346_thief_rule_guards import runtime as thief_runtime
from test_justice_story_runtime import runtime as justice_runtime
from test_magician_star_runtime import runtime as ms_runtime

ROOT=Path(__file__).resolve().parents[1]
DB=(Path(sys.argv.pop(1)) if len(sys.argv)>1 and not sys.argv[1].startswith('-')
    else Path(os.environ['LOCALAPPDATA'])/"Firaxis Games/Sid Meier's Civilization VI/Cache/DebugGameplay.sqlite")

class RemovalTests(unittest.TestCase):
    def fixture(self):
        lua=thief_runtime('LOTM_TP_Thief', 'API.remove=OnRemoveAbility;API.all=ApplyAllAbilities')
        lua.execute(r'''
        Players[0].props.LOTM_RP_SEQUENCE=1
        Players[0].props.LOTM_TP_ALL_ABILITIES_AUDIT_VERSION=1
        local function rows(t)
         return setmetatable(t,{__call=function() local i=0;return function() i=i+1;return t[i] end end})
        end
        GameInfo.CivilizationTraits=rows({{CivilizationType='CIV_0',TraitType='N'},
         {CivilizationType='CIV_1',TraitType='A'},{CivilizationType='CIV_2',TraitType='B'}})
        GameInfo.Traits={N={Description='native'},A={Description='foreign'},B={Description='shared'}}
        GameInfo.TraitModifiers=rows({{TraitType='N',ModifierId='N'},
         {TraitType='A',ModifierId='A'},{TraitType='A',ModifierId='B'},{TraitType='B',ModifierId='B'}})
        GameInfo.Modifiers={N={},A={},B={}}
        GameInfo.Resources={RA={Index=1},RB={Index=2},RN={Index=3}}
        GameInfo.LOTM_TP_RemovableModifiers={
         A={ModifierId='A',ResourceType='RA',GateRequirement='GA'},
         B={ModifierId='B',ResourceType='RB',GateRequirement='GB'},
         N={ModifierId='N',ResourceType='RN',GateRequirement='GN'}}
        amounts={};scans=0;legacy=false
        Players[0].GetResources=function() return {
         GetResourceAmount=function(_,id) return amounts[id] or 0 end,
         ChangeResourceAmount=function(_,id,n) amounts[id]=(amounts[id] or 0)+n end} end
        local names={[1]='A',[2]='B',[3]='N'}
        GameEffects={GetModifiers=function() scans=scans+1;return {1,2,3} end,
         GetModifierDefinition=function(id) return {Id=names[id]} end,
         GetModifierOwner=function() return 0 end,GetObjectsPlayerId=function() return 0 end,
         GetModifierOwnerRequirementSet=function(id) return id end,
         GetRequirementSetInnerRequirements=function(id) return {id} end,
         GetRequirementDefinition=function(id) return {ID=legacy and 'OLD' or 'G'..names[id]} end,
         GetModifierActive=function(id) return (amounts[id] or 0)==0 end}
        ''')
        return lua

    def test_irreversible_removal_shared_roots_native_roots_and_retry(self):
        lua=self.fixture();lua.execute(r'''
        API.remove(0,{SourcePlayerID=1})
        local p=Players[0].props
        assert(p.LOTM_TP_REMOVAL_RESULT=='REMOVED' and p.LOTM_TP_REMOVED_CIV_CIV_1==1)
        assert(amounts[1]==1 and amounts[2]==nil and amounts[3]==nil)
        API.remove(0,{SourcePlayerID=1});assert(scans==1 and amounts[1]==1)
        p.LOTM_TP_ALL_ABILITIES_RETRY='A';p.LOTM_TP_ALL_ABILITIES_TOTAL=3
        API.all(0);assert(stats.attached==0 and p.LOTM_TP_ALL_ABILITIES_RETRY=='')
        API.remove(0,{SourcePlayerID=2});assert(amounts[2]==1 and amounts[3]==nil and scans==1)
        ''')

    def test_legacy_without_real_gate_cannot_claim_success(self):
        lua=self.fixture();lua.execute(r'''
        legacy=true;API.remove(0,{SourcePlayerID=1})
        assert(Players[0].props.LOTM_TP_REMOVAL_RESULT=='UNVERIFIED')
        assert(Players[0].props.LOTM_TP_REMOVED_CIV_CIV_1==nil and next(amounts)==nil)
        ''')

    def test_native_leader_shared_modifier_is_preserved(self):
        lua=self.fixture();lua.execute(r'''
        PlayerConfigurations[0].GetLeaderTypeName=function() return 'LEADER_TEST' end
        GameInfo.LeaderTraits=setmetatable({},{__call=function()
         local done=false;return function() if not done then done=true;return {LeaderType='LEADER_TEST',TraitType='A'} end end end})
        API.remove(0,{SourcePlayerID=1})
        assert(next(amounts)==nil and Players[0].props.LOTM_TP_REMOVAL_RESULT=='REMOVED')
        ''')

    def test_mode_sequence_native_and_nonexistent_source_are_rejected(self):
        lua=self.fixture();lua.execute(r'''
        rescue=true;API.remove(0,{SourcePlayerID=1});rescue=false
        Players[0].props.LOTM_RP_SEQUENCE=2;API.remove(0,{SourcePlayerID=1})
        Players[0].props.LOTM_RP_SEQUENCE=1;API.remove(0,{SourcePlayerID=0})
        API.remove(0,{SourcePlayerID=80})
        assert(scans==0 and next(amounts)==nil)
        ''')

    def test_actual_panel_confirmation_receipt_and_rescue_isolation(self):
        lua=self.fixture();lua.execute(r'''
        requests=0;LOTM_TP_PATH='PATH_THIEF'
        function Control()
         local c={hidden=true,text=''}
         function c:SetHide(v) self.hidden=v end
         function c:IsHidden() return self.hidden end
         function c:SetText(v) self.text=v end
         function c:SetDisabled(v) self.disabled=v end
         function c:SetSizeY(v) self.height=v end
         function c:GetSizeY() return 50 end
         function c:RegisterCallback(_,f) self.click=f end
         function c:SetColor() end;function c:SetSelected() end
         function c:CalculateSize() end;function c:ReprocessAnchoring() end
         function c:CalculateInternalSize() end
         return c
        end
        Controls=setmetatable({},{__index=function(t,k) local c=Control();rawset(t,k,c);return c end})
        m_borrowIM={ResetInstances=function() end,GetInstance=function()
         local e={};for _,k in ipairs({'Name','Info','Top','Button','SelectorBrace','Remove'}) do e[k]=Control() end;return e end}
        function GetLocalPlayer() return 0,Players[0] end
        function GetProperty(o,k,d)
         if o==Game then return rescue and 1 or 0 end
         local v=o:GetProperty(k);if v==nil then return d end;return v
        end
        function CalculateSizeIfSupported() end
        Players[0].IsTurnActive=function() return true end
        GameInfo.Civilizations={CIV_1={Name='One'},CIV_2={Name='Two'}}
        Locale={Lookup=function(s) return s end};Mouse={eLClick=1};PlayerOperations={EXECUTE_SCRIPT=9}
        UIManager={GetScreenSizeVal=function() return 1920,1080 end}
        UI={GetColorValue=function() return 0 end,PlaySound=function() end,
         RequestPlayerOperation=function(id,_,data) requests=requests+1;API.remove(id,data) end}
        Events={GameCoreEventPublishComplete={Add=function(fn) receiptUpdate=fn end}}
        ''')
        source=(ROOT/'UI/LOTM_RP_HUD.lua').read_text(encoding='utf-8')
        block=source[source.index('local function GetCivilizationName'):source.index('local function ConfirmBorrowAbility')]
        block=re.sub(r'\s*:\s*(number|string|table|boolean)\b','',block)
        lua.execute(block+'\nPanelOpen=OpenBorrowAbilityPopup')
        lua.execute(r'''
        PanelOpen(true);assert(#m_borrowInstances==2)
        local first=m_borrowInstances[1]
        assert(not first.Remove.hidden and first.Top.height==158)
        first.Remove.click();assert(requests==0 and first.Remove.text=='LOC_LOTM_TP_REMOVE_CONFIRM')
        first.Remove.click();assert(requests==1 and amounts[1]==1)
        receiptUpdate();assert(#m_borrowInstances==1 and m_borrowInstances[1].SourcePlayerID==2)
        rescue=true;Players[0].props.LOTM_RESCUE_THIEF_S2_ABILITIES='A'
        PanelOpen(true);assert(m_borrowInstances[1].Remove.hidden)
        m_borrowInstances[1].Button.click();assert(requests==1)
        ''')

    def test_database_preserves_original_requirements_and_is_idempotent(self):
        p=DB
        original=sqlite3.connect(f'file:{p}?mode=ro',uri=True);db=sqlite3.connect(':memory:');original.backup(db)
        original.close()
        # A loaded normal-game cache already contains these owner wrappers.
        # Reconstruct their recorded inputs only in this disposable copy, so
        # the test checks first application and then repeat application.
        if db.execute("SELECT 1 FROM sqlite_master WHERE name='LOTM_TP_RemovableModifiers'").fetchone():
            for mid,gate,old in db.execute('SELECT ModifierId,GateSet,OriginalOwnerSet FROM LOTM_TP_RemovableModifiers').fetchall():
                self.assertEqual(db.execute('SELECT OwnerRequirementSetId FROM Modifiers WHERE ModifierId=?',(mid,)).fetchone()[0],gate)
                db.execute('UPDATE Modifiers SET OwnerRequirementSetId=? WHERE ModifierId=?',(old,mid))
            db.execute('DROP TABLE LOTM_TP_RemovableModifiers')
        before=dict(db.execute('SELECT ModifierId,OwnerRequirementSetId FROM Modifiers'))
        db.create_function('Make_Hash',1,lambda s:zlib.crc32(s.encode()) if s else 0)
        sql=(ROOT/'Gameplay/LOTM_TP_AbilityRemoval.sql').read_text(encoding='utf-8')
        db.executescript(sql);db.executescript(sql)
        catalog=db.execute('SELECT * FROM LOTM_TP_RemovableModifiers').fetchall();self.assertGreater(len(catalog),100)
        for mid,resource,req,rset,old in catalog:
            self.assertEqual(old,before[mid])
            self.assertEqual(db.execute('SELECT OwnerRequirementSetId FROM Modifiers WHERE ModifierId=?',(mid,)).fetchone()[0],rset)
            self.assertEqual(db.execute('SELECT Inverse FROM Requirements WHERE RequirementId=?',(req,)).fetchone()[0],1)
            if old:
                self.assertEqual(db.execute("SELECT Value FROM RequirementArguments WHERE RequirementId=? AND Name='RequirementSetId'",(req+'_ORIGINAL',)).fetchone()[0],old)
        self.assertEqual(db.execute('PRAGMA foreign_key_check').fetchall(),[])

class GovernorTests(unittest.TestCase):
    def test_magician_star_each_owned_promotion_and_unowned_are_independent(self):
        lua=ms_runtime();lua.execute(r'''
        local groups={MAGICIAN={'GATE','SERIAL','SUPPLY','RECORD','REPLAY','BESTSELLER'},
         STAR={'WATCHER','PATROL','INVESTIGATION','CONTACT','INTERROGATION','GUARDIAN'}}
        for group,names in pairs(groups) do
         for _,owned in ipairs(names) do
          local data={MAGICIAN_CityID=10,MAGICIAN_Established=1,MAGICIAN_Neutralized=0,
           STAR_CityID=11,STAR_Established=1,STAR_Neutralized=0}
          data['GOVERNOR_PROMOTION_LOTM_'..group..'_'..owned]=1
          GameEvents.LOTM_MS_UpdateGovernor(0,data)
          for other,list in pairs(groups) do
           for _,name in ipairs(list) do
            assert(player.props['LOTM_MS_'..other..'_HAS_GOVERNOR_PROMOTION_LOTM_'..other..'_'..name]
             ==(other==group and name==owned and 1 or 0))
           end
          end
         end
        end
        ''')

    def test_salon_oracle_pillage_half_points_and_unowned(self):
        lua=justice_runtime();lua.execute(r'''
        local function rows(t) return setmetatable(t,{__call=function()
         local i=0;return function() i=i+1;return t[i] end end}) end
        local class='GREAT_PERSON_CLASS_WRITER'
        GameInfo.District_GreatPersonPoints=rows({{DistrictType='DISTRICT_THEATER',GreatPersonClassType=class,PointsPerTurn=1}})
        GameInfo.Building_GreatPersonPoints=rows({{BuildingType='BUILDING_AMPHI',GreatPersonClassType=class,PointsPerTurn=1}})
        GameInfo.Districts={DISTRICT_THEATER={Index=20}}
        GameInfo.Buildings.BUILDING_AMPHI={Index=21};GameInfo.Buildings.BUILDING_ORACLE={Index=22}
        GameInfo.ModifierArguments=rows({{ModifierId='ORACLE_GREATWRITERPOINTS',Name='Amount',Value='2'}})
        GameInfo.GreatPersonClasses[class]={Index=0}
        pillage=false;amphi=true;oracle=true;gp=0
        local district={GetType=function() return 20 end,IsComplete=function() return true end,
         IsPillaged=function() return pillage end}
        cities[10].GetDistricts=function() return {GetDistrictByType=function(_,id)
         assert(id==20);return district end} end
        cities[10].GetBuildings=function() return {HasBuilding=function(_,id)
         return (id==21 and amphi) or (id==22 and oracle) end,IsPillaged=function(_,id) return id==21 and pillage end} end
        Players[0].GetGreatPeoplePoints=function() return {ChangePointsTotal=function(_,id,n)
         assert(id==0);gp=gp+n end} end
        snapshot(10,0,0,0,0,0,1,0);tick(1);assert(gp==2)
        pillage=true;tick(2);assert(gp==2)
        pillage=false;oracle=false;amphi=false;tick(3);assert(gp==2)
        tick(4);assert(gp==3)
        snapshot(10,0,0,0,0,0,0,0);tick(5);assert(gp==3)
        snapshot(10,1,0,0,0,0,1,0);tick(6);assert(gp==3)
        ''')

    def test_each_owned_promotion_is_independent_and_unowned_is_off(self):
        lua=justice_runtime();lua.execute(r'''
        local names={'SPONSOR','COUNSEL','SALON','SUGGESTION','TAROT','STORY'}
        for _,owned in ipairs(names) do
         local data={CityID=10,Established=1,Neutralized=0}
         data['GOVERNOR_PROMOTION_LOTM_JUSTICE_'..owned]=1
         GameEvents.LOTM_JUSTICE_UpdateGovernor(0,data)
         for _,name in ipairs(names) do
          assert(props['JUSTICE_GOVERNOR_HAS_GOVERNOR_PROMOTION_LOTM_JUSTICE_'..name]==(name==owned and 1 or 0))
         end
        end
        ''')

    def test_counsel_preserves_positive_duration_and_positive_event_draws(self):
        lua=justice_runtime();lua.execute(r'''
        counts={ABILITY_LOTM_WORLD_HOLDER_GOOD=1,ABILITY_LOTM_WORLD_HOLDER_UNSTABLE=1}
        local hero={GetAbility=function() return {
          GetAbilityCount=function(_,id) return counts[id] or 0 end,
          ChangeAbilityCount=function(_,id,n) counts[id]=(counts[id] or 0)+n end} end}
        LOTM_RP_State.FindHero=function() return hero end
        LOTM_MP_TurnSync.IsNetworkGame=function() return false end
        LOTM_WORLD_State={NumberProperty=function(p,k,d) local v=p:GetProperty(k);if v==nil then return d end;return v end,
          Random=function() return 0 end}
        NotificationTypes={USER_DEFINED_6=6,USER_DEFINED_7=7,USER_DEFINED_8=8,USER_DEFINED_9=9}
        ParameterTypes={MESSAGE=1,SUMMARY=2};NotificationManager={SendNotification=function() end}
        Locale={Lookup=function(s) return s end}
        props.LOTM_WORLD_PLAYER_TURN=10;props.LOTM_HOLDER_GOOD_STATE_UNTIL=15
        props.LOTM_RP_PATH='PATH_RED_PRIEST'
        props.LOTM_HOLDER_UNSTABLE_STATE_UNTIL=15
        snapshot(10,0,1,0,0,1,0,0)
        assert(counts.ABILITY_LOTM_WORLD_HOLDER_UNSTABLE==0)
        assert(counts.ABILITY_LOTM_WORLD_HOLDER_GOOD==1 and props.LOTM_HOLDER_GOOD_STATE_UNTIL==15)
        ''')
        source=(ROOT/'Scripts/LOTM_WORLD_Events.lua').read_text(encoding='utf-8')
        source=re.sub(r'\s*:\s*(number|string|table|boolean)\b','',source)
        lua.execute(source+'\nWorldAPI={trigger=Trigger,refresh=RefreshHolder};Draw=function() return nature end')
        lua.execute(r'''
        nature='B';WorldAPI.trigger(Players[0],10);WorldAPI.refresh(Players[0],10)
        assert(props.LOTM_WORLD_EVENT_KIND=='HOLDER_COUNSELED')
        assert(props.LOTM_HOLDER_GOOD_STATE_UNTIL==15 and counts.ABILITY_LOTM_WORLD_HOLDER_GOOD==1)
        nature='G';WorldAPI.trigger(Players[0],11);WorldAPI.refresh(Players[0],11)
        assert(props.LOTM_WORLD_EVENT_KIND=='HOLDER_GOOD' and props.LOTM_HOLDER_GOOD_STATE_UNTIL==16)
        snapshot(10,0,1,0,0,0,0,0)
        nature='B';WorldAPI.trigger(Players[0],12);WorldAPI.refresh(Players[0],12)
        assert(props.LOTM_WORLD_EVENT_KIND=='HOLDER_UNSTABLE' and counts.ABILITY_LOTM_WORLD_HOLDER_UNSTABLE==1)
        assert(counts.ABILITY_LOTM_WORLD_HOLDER_GOOD==1)
        ''')

if __name__=='__main__':unittest.main(verbosity=2)
