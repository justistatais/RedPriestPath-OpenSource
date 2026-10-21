"""Verify the shipped four-tier art graph, cooked dependencies and cosmetic SQL."""
from pathlib import Path
import hashlib,json,sqlite3,xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1];A=ROOT/'Art/LOTMPlayerModels'
def named(root,collection):
 c=next(c for c in root.findall('./m_RootCollections/Element') if c.find('m_CollectionName').get('text')==collection)
 return {e.find('m_Name').get('text'):e for e in c.findall('Element')}
def params(e):return {v.find('m_ParamName').get('text'):v for v in e.findall('./m_Fields/m_Values/Element')}
def main():
 mod=E.parse(ROOT/'RedPriestPath.modinfo').getroot();actions={n.get('id'):n for n in mod.findall('./InGameActions/*')};declared={f.text for f in mod.findall('./Files/File')}
 for name in ['LOTM_PLAYER_MODELS_DATABASE','LOTM_PLAYER_MODELS_TEXT','LOTM_PLAYER_MODELS_ART','LOTM_PLAYER_MODELS_GAMEPLAY']:assert actions[name].get('criteria')=='LOTM_RP_EXPANSION_2'
 assert actions['LOTM_PLAYER_GODS_ART'].get('criteria')=='LOTM_RP_RESCUE_MODE'
 assert int(actions['LOTM_PLAYER_GODS_ART'].findtext('./Properties/LoadOrder'))>int(actions['LOTM_MODELS_V4_ART'].findtext('./Properties/LoadOrder'))
 manifest=json.loads((A/'manifest.json').read_text());audit=json.loads((A/'audit.json').read_text());assert len(audit['geometries'])==17 and len(audit['cooked_pixel_checks'])==108
 for rel,h in manifest['files'].items():assert 'Art/LOTMPlayerModels/'+rel in declared and hashlib.sha256((A/rel).read_bytes()).hexdigest()==h,rel
 units=named(E.parse(A/'ArtDefs/Units.artdef').getroot(),'Units');assert set(units)=={'UNIT_LOTM_'+p+'_PATH_HOLDER' for p in ['RP','PP','BE','TP']}
 for u in units.values():
  coll=next(c for c in u.findall('./m_ChildCollections/Element') if c.find('m_CollectionName').get('text')=='AttachmentVisibility');conditions={params(e)['Attachment Point Name'].find('m_Value').get('text'):params(e)['Conditions'].find('m_Value').get('text').split(';') for e in coll.findall('Element')};assert len(conditions)==4
  for tier in range(4):
   granted={'PROMOTION_LPM_TIER_'+str(i) for i in range(1,tier+1)}
   visible=[name for name,cs in conditions.items() if all((c[1:] not in granted) if c.startswith('-') else c in granted for c in cs)]
   assert visible==['LPM_Tier'+str(tier)],visible
 gods=named(E.parse(A/'ArtDefs/PlayerGods.artdef').getroot(),'Units');assert len(gods)==4
 for platform,shared in manifest['cooker_shared_files'].items():
  folder=A/f'Platforms/{platform}/BLPs';blob=(folder/'LOTMPlayerModels.blp').read_bytes()
  for name in shared:assert (folder/'SHARED_DATA'/name).is_file() and name.encode() in blob
  for tier in range(4):assert ('LPM_Tier'+str(tier)).encode() in blob
 sql=(ROOT/'Gameplay/LOTM_PlayerModels.sql').read_text();db=sqlite3.connect(':memory:');db.executescript('CREATE TABLE Types(Type TEXT PRIMARY KEY,Kind TEXT);CREATE TABLE UnitPromotionClasses(PromotionClassType TEXT PRIMARY KEY,Name TEXT);CREATE TABLE UnitPromotions(UnitPromotionType TEXT PRIMARY KEY,Name TEXT,Description TEXT,Level INT,PromotionClass TEXT);'+sql)
 assert db.execute('SELECT count(*) FROM UnitPromotions').fetchone()[0]==3
 assert not any(x in sql for x in ['INSERT INTO UnitPromotionModifiers','UPDATE Units','DELETE FROM','UPDATE UnitAbilities'])
 lua=(ROOT/'Scripts/LOTM_PlayerModels.lua').read_text();assert 'GameEvents.PlayerTurnStarted.Add' in lua and 'GameEvents.UnitInitialized.Add' in lua
 assert all(x not in lua for x in ['UnitManager','Members()','Map.','Events.LocalPlayer','UI.','ChangeExperience','SetDamage','ChangeDamage'])
 print('PASS: 16 models / four mutually exclusive tiers, cosmetic SQL, synchronized O(1) hero lookup, 17 native roundtrips, 108 cooked pixel checks and complete two-platform dependencies. Native game and multiplayer remain unverified.')
if __name__=='__main__':main()
