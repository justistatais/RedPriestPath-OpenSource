"""Regress actual rc356 API refusal; model only the available Gameplay APIs."""
import hashlib
import unittest
import zipfile
from test_rc347_found_city_gate import ROOT, runtime, source_file
from test_rc356_advanced_cities import fixture


class GameplayCityAPITests(unittest.TestCase):
    def test_immutable_rc356_reproduces_missing_ui_api_refusal(self):
        path=ROOT.parent/'dist/RedPriestPath-0.1.0-rc.356.zip'
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),'269a1da2c307d63a8978fe7a1a79348848f33001568a44ad2d780abf1e079790')
        with zipfile.ZipFile(path) as z: old=z.read('RedPriestPath/Scripts/LOTM_RESCUE_Thief.lua').decode('utf-8')
        lua=runtime();lua.execute('rescue=false')
        lua.execute(old+'\nAPI.convert=LOTM_RESCUE_Thief.ConvertBarbarianCamp; rescue=true')
        lua.execute('''Players[0].props.LOTM_RP_SEQUENCE=4
        assert(UnitManager.CanStartOperation==nil and UnitManager.RequestOperation==nil and UnitOperationTypes==nil)
        assert(not API.convert(0,12,"SELF")); assert(stats.nativeFound==0 and not hero.dead)''')

    def test_current_found_both_units_with_no_ui_operation_api(self):
        for command in ('API.convert(0,12,"SELF")','API.found(0,8,"SELF")'):
            lua=fixture();lua.execute('''Players[0].props.LOTM_RP_SEQUENCE=1
            UnitManager.InitUnit=nil; UnitManager.RequestCommand=nil; UnitCommandTypes=nil
            assert(UnitManager.RequestOperation==nil and UnitManager.CanStartOperation==nil)
            ''')
            lua.execute('assert('+command+'); assert(stats.nativeFound==1 and stats.created==0 and stats.population==4 and stats.walls==1)')

    def test_local_legality_checks_and_visible_failure_reason(self):
        for setup,reason in (
            ('plot.water=true','TERRAIN'),('plot.impassable=true','TERRAIN'),
            ('plot.district=3','OCCUPIED'),('plot.wonder=2','OCCUPIED'),
            ('plot.owner=1','FOREIGN'),
            ('plot.feature=2; GameInfo.Features[2]={Settlement=false}','TERRAIN'),
            ('plot.feature=2; GameInfo.Features[2]={Settlement=0}','TERRAIN'),
            ('plot.feature=2; GameInfo.Features[2]={NaturalWonder=true}','TERRAIN'),
            ('neighbor=setmetatable({city=true},{__index=plot})','CITY_DISTANCE'),
        ):
            with self.subTest(setup=setup):
                lua=fixture();lua.execute(setup)
                lua.execute('assert(not API.convert(0,12,"SELF")); assert(stats.nativeFound==0 and not hero.dead and stats.effects==0); assert(string.find(stats.message,"REASON_'+reason+'"))')

    def test_city_distance_database_boundary_and_distinct_landmasses(self):
        for distance,area,allowed in ((3,1,False),(3,2,True),(2,2,False)):
            lua=fixture();lua.execute(f'neighbor=setmetatable({{city=true,area={area}}},{{__index=plot}}); neighborDistance={distance}')
            self.assertEqual(lua.eval('API.convert(0,12,"SELF")'),allowed)
            self.assertLessEqual(lua.eval('stats.neighbors'),49)
        lua=fixture();lua.execute('''GameInfo.GlobalParameters.CITY_MIN_RANGE.Value=2
        neighbor=setmetatable({city=true},{__index=plot}); neighborDistance=2
        assert(not API.convert(0,12,"SELF")); assert(stats.neighbors<=25)''')

    def test_no_map_unit_or_city_enumeration_for_ability(self):
        lua=fixture();lua.execute('''
        Map.GetPlotCount=function() error("map scan") end
        local old=Players[0].GetCities
        Players[0].GetCities=function() local c=old(); c.Members=function() error("city scan") end; return c end
        local unitsAPI=Players[0]:GetUnits(); unitsAPI.Members=function() error("unit scan") end
        Players[0].GetUnits=function() return unitsAPI end
        assert(API.convert(0,12,"SELF")); assert(stats.effects==2)
        ''')

    def test_missing_city_create_api_fails_visibly_and_rolls_back(self):
        lua=fixture();lua.execute('''
        local old=Players[0].GetCities
        Players[0].GetCities=function() local c=old(); c.Create=nil; return c end
        assert(not API.convert(0,12,"SELF")); assert(not hero.dead and stats.effects==0)
        assert(Players[0].props.LOTM_RESCUE_CAMP_CONVERT_PENDING==0)
        assert(Players[0].props.LOTM_RESCUE_CAMP_CONVERT_TURN==nil)
        assert(string.find(stats.message,"REASON_API"))
        ''')

    def test_optional_plot_helpers_absent_cannot_break_click(self):
        lua=fixture();lua.execute('plot.GetWonderType=nil; plot.GetArea=nil; assert(API.convert(0,12,"SELF")); assert(stats.effects==2)')

    def test_confirmed_city_receipt_survives_reload_without_regrant(self):
        lua=fixture();lua.execute('assert(API.convert(0,12,"SELF")); rescue=false')
        lua.execute(source_file('Scripts/LOTM_RESCUE_Thief.lua')+'\nAPI.city=OnCityBuilt; rescue=true')
        lua.execute('API.city(0,5); assert(stats.effects==2 and stats.heroKilled==1 and stats.respawn==1)')


if __name__=='__main__': unittest.main(verbosity=2)
