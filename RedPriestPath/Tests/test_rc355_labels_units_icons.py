"""Database/native-configuration contracts for reported HUD and combat issues."""
from pathlib import Path
import os,sqlite3,sys,struct,unittest,xml.etree.ElementTree as ET,zlib
ROOT=Path(__file__).resolve().parents[1]
DB=Path(sys.argv.pop(1)) if len(sys.argv)>1 and not sys.argv[1].startswith('-') else Path(os.environ['LOCALAPPDATA'])/"Firaxis Games/Sid Meier's Civilization VI/Cache/DebugGameplay.sqlite"

def database():
    db=sqlite3.connect(':memory:'); db.create_function('Make_Hash',1,lambda v:zlib.crc32(str(v).encode()))
    with sqlite3.connect(f'file:{DB.as_posix()}?mode=ro',uri=True) as src: src.backup(db)
    for name in ('LOTM_RESCUE_Phase5.sql','LOTM_RESCUE_Thief.sql'):
        sql=(ROOT/'Gameplay'/name).read_text(encoding='utf-8'); db.executescript(sql); db.executescript(sql)
    return db

def texts(lang):
    root=ET.parse(ROOT/'Text'/lang/'LOTM_RP_GameplayText.xml').getroot()
    rows=list(root.iter('Row'))
    result={row.get('Tag'):row.findtext('Text') for row in rows}
    assert len(result)==len(rows),'Duplicate source-language rows'
    return result

class LabelsUnitsIcons(unittest.TestCase):
    def test_seal_and_all_ten_suppression_levels_have_numeric_native_previews(self):
        db=database()
        expected=[('LOTM_RESCUE_EARLY_SEAL_COMBAT',-10)]+[(f'LOTM_RESCUE_PURIFICATION_MADNESS_{n}_MOD',-n) for n in range(5,51,5)]
        for lang in ('zh_Hans_CN','en_US'):
            loc=texts(lang)
            selected={r.get('Tag'):r.findtext('Text') for r in ET.parse(ROOT/'Text/Selected'/f'LOTM_RP_Selected_{lang}.xml').getroot().find('BaseGameText') if r.get('Tag')}
            for mod,amount in expected:
                tag=db.execute("SELECT Text FROM ModifierStrings WHERE ModifierId=? AND Context='Preview'",(mod,)).fetchone()[0]
                self.assertIn('{1_Amount}',loc[tag]); self.assertEqual(selected[tag],loc[tag])
                self.assertIn(str(amount),loc[tag].replace('{1_Amount}',str(amount)))
                self.assertEqual(db.execute("SELECT Value FROM ModifierArguments WHERE ModifierId=? AND Name='Amount'",(mod,)).fetchone()[0],str(amount))
            for n in range(5,51,5):
                name,desc=db.execute('SELECT Name,Description FROM UnitAbilities WHERE UnitAbilityType=?',(f'LOTM_RESCUE_PURIFICATION_MADNESS_{n}',)).fetchone()
                self.assertIn(str(n),loc[name]); self.assertIn(str(n),loc[desc]); self.assertEqual(selected[name],loc[name])
            self.assertIn('10',loc['LOC_LOTM_RESCUE_EARLY_SEAL_NAME'])
        self.assertEqual(db.execute('PRAGMA foreign_key_check').fetchall(),[])

    def test_army_requires_positive_combat_tag_for_all_levels(self):
        db=database()
        expected=[f'LOTM_RESCUE_PURIF_ARMY_LEVEL_{n}' for n in range(1,11)]+['LOTM_RESCUE_PURIF_ARMY_PLUS','LOTM_RESCUE_PURIF_ARMY_MINUS']
        for modifier in expected:
            rows=db.execute('''SELECT r.RequirementType,r.Inverse,a.Name,a.Value FROM Modifiers m
              JOIN RequirementSetRequirements s ON s.RequirementSetId=m.SubjectRequirementSetId
              JOIN Requirements r ON r.RequirementId=s.RequirementId
              JOIN RequirementArguments a ON a.RequirementId=r.RequirementId WHERE m.ModifierId=?''',(modifier,)).fetchall()
            self.assertEqual(rows,[('REQUIREMENT_UNIT_TAG_MATCHES',0,'Tag','CLASS_LOTM_RESCUE_COMBAT_UNIT')])
        tag='CLASS_LOTM_RESCUE_COMBAT_UNIT'
        for name in ('UNIT_BUILDER','UNIT_SETTLER','UNIT_TRADER','UNIT_BATTERING_RAM','UNIT_MISSIONARY','UNIT_GREAT_GENERAL'):
            self.assertEqual(db.execute('SELECT COUNT(*) FROM TypeTags WHERE Type=? AND Tag=?',(name,tag)).fetchone()[0],0,name)
        for name in ('UNIT_WARRIOR','UNIT_ARCHER','UNIT_SCOUT','UNIT_GALLEY','UNIT_CATAPULT'):
            self.assertEqual(db.execute('SELECT COUNT(*) FROM TypeTags WHERE Type=? AND Tag=?',(name,tag)).fetchone()[0],1,name)
        invalid=db.execute('''SELECT u.UnitType FROM Units u JOIN TypeTags t ON t.Type=u.UnitType
          WHERE t.Tag=? AND ((u.Combat<=0 AND u.RangedCombat<=0) OR u.FormationClass IN ('FORMATION_CLASS_CIVILIAN','FORMATION_CLASS_SUPPORT'))''',(tag,)).fetchall()
        self.assertEqual(invalid,[])

    def test_every_potion_icon_resolves_production_queue_and_detail_sizes(self):
        db=database(); projects=[r[0] for r in db.execute('SELECT ProjectType FROM LOTM_RESCUE_PotionCompletions')]
        self.assertEqual(len(projects),9)
        for file in ('LOTM_RESCUE_TP_Icons.xml','LOTM_TP_Icons.xml'):
            root=ET.parse(ROOT/'Art'/file).getroot()
            definitions={r.get('Name'):r.get('Atlas') for r in root.findall('./IconDefinitions/Row')}
            textures={(r.get('Name'),int(r.get('IconSize'))):r.get('Filename') for r in root.findall('./IconTextureAtlases/Row')}
            for project in projects:
                atlas=definitions['ICON_'+project]
                for size in (22,30,32,38,40,50,64,70,80,95,200,256):
                    p=ROOT/'Art'/textures[(atlas,size)]; data=p.read_bytes()[:20]
                    self.assertEqual(data[:4],b'DDS ')
                    self.assertEqual(struct.unpack('<II',data[12:20]),(size,size),(file,project,size))

if __name__=='__main__': unittest.main(verbosity=2)
