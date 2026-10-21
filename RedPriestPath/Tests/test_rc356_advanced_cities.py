"""Actual Lua 5.1 founding callbacks and native SQL contracts; not an engine test."""
import sqlite3
import unittest
import zlib
from test_rc347_found_city_gate import runtime, ui_runtime, source_file, DATABASE


def fixture():
    lua = runtime()
    lua.execute(r'''
    API.found=LOTM_RESCUE_Thief.FoundTimeWormCity
    Players[0].props.LOTM_RP_SEQUENCE=4
    plot.improvement=-1
    worm=setmetatable({id=8,kind=13,owner=0,dead=false,delayed=false,x=1,y=2},{__index=hero})
    units[8]=worm
    Players[0].props.LOTM_RESCUE_TIME_WORM_ID=8
    UnitManager.FinishMoves=function(unit) assert(unit==worm); stats.finished=(stats.finished or 0)+1 end
    UnitManager.RequestCommand=function() error("wrong founding API") end
    stats.population=1; stats.walls=0; stats.effects=0
    function DeliverCity(owner,cityID,x,y)
     city={owner=owner or 0,id=cityID or 5,x=x or plot.x,y=y or plot.y}
     function city:GetID() return self.id end
     function city:GetOwner() return self.owner end
     function city:GetX() return self.x end
     function city:GetY() return self.y end
     function city:AttachModifierByID(modifier)
      assert(not creating,"effects must wait for native city initialization")
      stats.effects=stats.effects+1
      if modifier=="LOTM_RESCUE_ADVANCED_CITY_POPULATION" then stats.population=stats.population+3
      elseif modifier=="LOTM_RESCUE_ADVANCED_CITY_WALLS" then stats.walls=stats.walls+1
      else error(modifier) end
      API.city(self.owner,self.id) -- Modifier publication may reenter CityBuilt.
     end
     plot.city=true
     API.city(city.owner,city.id)
    end
    ''')
    return lua


class AdvancedCityTests(unittest.TestCase):
    def test_parasite_legal_land_without_camp_and_reentrant_native_callbacks(self):
        for delivery in ('ASYNC', 'SYNC', 'SYNC_BEFORE_CONSUME', 'REENTRANT'):
            for seq in range(5):
                with self.subTest(delivery=delivery, seq=seq):
                    lua=fixture(); lua.globals().delivery=delivery
                    lua.globals().Players[0].props.LOTM_RP_SEQUENCE=seq
                    lua.execute('assert(API.convert(0,12,"SELF")); if city==nil then DeliverCity() end')
                    lua.execute('''
                    assert(stats.population==4 and stats.walls==1 and stats.effects==2)
                    assert(stats.heroKilled==1 and stats.respawn==1)
                    assert(Players[0].props.LOTM_RP_RESPAWN_AT==turn+5)
                    turn=turn+1; API.city(0,5)
                    assert(stats.population==4 and stats.walls==1 and stats.heroKilled==1)
                    assert((stats.temporaryKilled or 0)==0)
                    ''')

    def test_worm_original_survives_and_cooldown_commits_only_on_matching_city(self):
        lua=fixture(); lua.execute('''
        Players[0].props.LOTM_RP_SEQUENCE=1
        assert(API.found(0,8,"SELF")); assert(Players[0].props.LOTM_RESCUE_TIME_WORM_COOLDOWN==turn+3)
        DeliverCity(1,5); DeliverCity(0,6,99,99)
        assert(stats.effects==2 and Players[0].props.LOTM_RESCUE_TIME_WORM_FOUND_PENDING==0)
        DeliverCity(0,5)
        assert(stats.population==4 and stats.walls==1 and units[8]==worm and not worm.dead and not hero.dead)
        assert(stats.finished==1 and Players[0].props.LOTM_RESCUE_TIME_WORM_COOLDOWN==turn+3)
        plot.city=false
        for i=0,2 do assert(not API.found(0,8,"SELF")); turn=turn+1 end
        API.city(0,5); assert(stats.effects==2 and stats.finished==1)
        createID=9; assert(API.found(0,8,"SELF"))
        assert(stats.effects==4 and stats.population==7 and stats.walls==2)
        ''')

    def test_worm_success_before_actor_consumption_and_late_native_error(self):
        for result in (True, 'FALSE_AFTER_COMMIT', 'ERROR_AFTER_COMMIT'):
            lua=fixture(); lua.globals().nativeResult=result
            lua.execute('''
            Players[0].props.LOTM_RP_SEQUENCE=1; delivery="SYNC_BEFORE_CONSUME"
            assert(API.found(0,8,"SELF")); API.city(0,5)
            assert(stats.effects==2 and stats.population==4 and stats.walls==1)
            assert(units[8]==worm and not worm.dead and (stats.temporaryKilled or 0)==0)
            ''')

    def test_failure_rolls_back_only_temporary_actor_no_rewards_or_costs(self):
        for command in ('API.convert(0,12,"SELF")','API.found(0,8,"SELF")'):
            for setup in ('plot.water=true','plot.owner=1','failCreate=true','nativeResult=false','nativeResult="ERROR"'):
                with self.subTest(command=command,setup=setup):
                    lua=fixture();lua.execute('Players[0].props.LOTM_RP_SEQUENCE=1;'+setup)
                    lua.execute('assert(not '+command+''')
                    assert(not hero.dead and not worm.dead and stats.effects==0)
                    assert((stats.respawn or 0)==0 and Players[0].props.LOTM_RESCUE_TIME_WORM_COOLDOWN==nil)
                    assert((Players[0].props.LOTM_RESCUE_CAMP_CONVERT_PENDING or 0)==0)
                    assert((Players[0].props.LOTM_RESCUE_TIME_WORM_FOUND_PENDING or 0)==0)
                    assert(stats.created==(stats.temporaryKilled or 0))
                    ''')

    def test_ordinary_city_at_remembered_worm_location_gets_no_bonus(self):
        lua=fixture(); lua.execute('''
        Players[0].props.LOTM_RP_SEQUENCE=1
        Players[0].props.LOTM_RESCUE_TIME_WORM_LAST_PLOT=12
        DeliverCity(); assert(stats.effects==0 and stats.population==1 and stats.walls==0)
        assert(Players[0].props.LOTM_RESCUE_TIME_WORM_COOLDOWN==nil)
        ''')

    def test_ui_legal_land_worm_gate_and_submission(self):
        lua=ui_runtime();lua.execute('''
        plot.improvement=-1; Players[0].props.LOTM_RP_SEQUENCE=4
        UIAPI.refresh(); assert(not Controls.ActionButton.hidden)
        hero.kind=13; Players[0].props.LOTM_RP_SEQUENCE=2
        UIAPI.refresh(); assert(Controls.ActionButton.hidden)
        Players[0].props.LOTM_RP_SEQUENCE=1
        UIAPI.refresh(); assert(not Controls.ActionButton.hidden)
        UI.RequestPlayerOperation=function(id,kind,params)
         assert(id==0 and params.OnStart=="LOTM_RESCUE_Command_FoundTimeWormCity" and params.UnitID==7)
         stats.submitted=(stats.submitted or 0)+1
        end
        UIAPI.submit(); assert(stats.submitted==1)
        Players[0].props.LOTM_RESCUE_TIME_WORM_COOLDOWN=turn+3
        UIAPI.submit(); assert(stats.submitted==1)
        plot.IsWater=function() return true end
        hero.kind=11; UIAPI.refresh(); assert(Controls.ActionButton.hidden)
        ''')

    def test_native_effects_single_city_one_shot_and_no_global_bonus(self):
        src=sqlite3.connect(DATABASE.as_uri()+'?mode=ro',uri=True)
        db=sqlite3.connect(':memory:');src.backup(db);src.close()
        db.create_function('Make_Hash',1,lambda value:zlib.crc32(str(value).encode('utf-8')))
        try:
            db.executescript(source_file('Gameplay/LOTM_RESCUE_Thief.sql'))
            rows=db.execute('''SELECT m.ModifierId,d.CollectionType,d.EffectType,m.RunOnce,m.Permanent
            FROM Modifiers m JOIN DynamicModifiers d ON d.ModifierType=m.ModifierType
            WHERE m.ModifierId LIKE 'LOTM_RESCUE_ADVANCED_CITY_%' ORDER BY m.ModifierId''').fetchall()
            self.assertEqual(rows,[('LOTM_RESCUE_ADVANCED_CITY_POPULATION','COLLECTION_OWNER','EFFECT_ADJUST_CITY_POPULATION',1,1),('LOTM_RESCUE_ADVANCED_CITY_WALLS','COLLECTION_OWNER','EFFECT_GRANT_BUILDING_IN_CITY_IGNORE',1,1)])
            args=dict(db.execute("SELECT ModifierId,Value FROM ModifierArguments WHERE ModifierId LIKE 'LOTM_RESCUE_ADVANCED_CITY_%'"))
            self.assertEqual(args,{'LOTM_RESCUE_ADVANCED_CITY_POPULATION':'3','LOTM_RESCUE_ADVANCED_CITY_WALLS':'BUILDING_WALLS'})
            self.assertFalse(list(db.execute('PRAGMA foreign_key_check')))
        finally: db.close()


if __name__=='__main__': unittest.main(verbosity=2)
