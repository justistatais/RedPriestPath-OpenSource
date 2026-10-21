"""Check the cooked city binding and internal selectors, without claiming game QA."""
from pathlib import Path
import hashlib,json,os,sqlite3,sys,xml.etree.ElementTree as ET,zlib
ROOT=Path(__file__).resolve().parents[1];ART=ROOT/'Art/LOTMHolyCities'
SLUGS=['Fool','Night','Storm','Star'];ZONES={s:('CENTER' if s=='Star' else s.upper()) for s in SLUGS};BUILDINGS={'BUILDING_LOTM_RESCUE_HOLY_CITY_'+ZONES[s] for s in SLUGS}
def col(parent,name):return next(e for e in parent if e.find('m_CollectionName') is not None and e.find('m_CollectionName').get('text')==name)
def named(c):return {e.find('m_Name').get('text'):e for e in c.findall('Element')}
def params(e):return {p.find('m_ParamName').get('text'):p for p in e.findall('./m_Fields/m_Values/Element')}
def field_values(e):return {k:{v.tag:v.get('text',v.text or '') for v in p if v.tag!='m_ParamName'} for k,p in params(e).items()}
def main():
 mod=ET.parse(ROOT/'RedPriestPath.modinfo').getroot();declared={f.text for f in mod.findall('./Files/File')}
 expected={
  'LOTM_RESCUE_HOLY_CITY_ART_DATABASE':('UpdateDatabase','Gameplay/LOTM_RESCUE_HolyCityArt.sql',205),
  'LOTM_RESCUE_HOLY_CITY_ART_TEXT':('UpdateText','Text/LOTM_RESCUE_HolyCityArt.xml',205),
  'LOTM_RESCUE_HOLY_CITY_ART':('UpdateArt','Art/LOTMHolyCities/LOTMHolyCities.dep',206),
  'LOTM_RESCUE_HOLY_CITY_ART_GAMEPLAY':('AddGameplayScripts','Scripts/LOTM_RESCUE_HolyCityArt.lua',209)}
 for key,(tag,file,order) in expected.items():
  actions=[a for a in mod.findall('./InGameActions/'+tag) if a.get('id')==key];assert len(actions)==1
  a=actions[0];assert a.get('criteria')=='LOTM_RP_RESCUE_MODE';assert a.findtext('File')==file
  assert int(a.findtext('./Properties/LoadOrder'))==order and file in declared
 manifest=json.loads((ART/'manifest.json').read_text(encoding='utf-8'))
 assert not manifest['game_verified'] and not manifest['multiplayer_verified']
 assert len(manifest['cooker'])==4 and all(r['returncode']==0 for r in manifest['cooker'])
 for rel,digest in manifest['files'].items():
  assert 'Art/LOTMHolyCities/'+rel in declared
  assert hashlib.sha256((ART/rel).read_bytes()).hexdigest()==digest,rel
 assert len(manifest['roundtrip'])==3
 for model in manifest['roundtrip']:
  assert model['bones']==1 and model['bone_hierarchy_equal'] and len(model['meshes'])==9
  for mesh in model['meshes']:
   assert mesh['static_no_vertex_weights'] and mesh['position_max_error']<.0002 and mesh['uv_max_error']<.00001
   assert mesh['vertices']<=12000 and mesh['triangles']<=6000
 for platform in ['Windows','MacOS']:
  data=(ART/f'Platforms/{platform}/BLPs/LOTMHolyCities.blp').read_bytes();assert len(data)>1_000_000
  for slug in SLUGS:
   stem='LHC_Star_Body' if slug=='Star' else 'LHC_'+slug
   for token in [f'LHC_{slug}',f'TEXTURE_DiffuseTint_{stem}_BaseColor_{stem}_TintMask',f'TEXTURE_{stem}_Emissive']:assert token.encode() in data,(platform,token)
 br=ET.parse(ART/'ArtDefs/Buildings.artdef').getroot();buildings=named(col(br.find('m_RootCollections'),'Building'));assert set(buildings)==BUILDINGS
 for b in buildings.values():
  p=params(b);assert p['AffectsDistrictBuildingSet'].findtext('m_bValue')=='false'
  assert p['AttachmentPointName'].find('m_Value').get('text')==''
 lr=ET.parse(ART/'ArtDefs/Landmarks.artdef').getroot();districts=named(col(lr.find('m_RootCollections'),'Districts'));assert set(districts)=={'DISTRICT_CITY_CENTER'}
 city=districts['DISTRICT_CITY_CENTER'];actual=field_values(city)
 # Omitted fields are filled by Cooker; an empty generator would damage all cities.
 assert actual==manifest['shared_city_fields'],(actual,manifest['shared_city_fields'])
 assert actual['DistrictGenerator']['m_ElementName']=='Gen_CityCenter'
 for r in [br,lr]:
  assert all(e.text=='false' for e in r.iter('m_ReplaceMergedCollectionElements'))
 children=city.find('m_ChildCollections');variants=named(col(children,'BuildingVariants'))
 assert set(variants)=={'LOTM_HOLY_CITY_'+s.upper()+'_BUILDING' for s in SLUGS}
 for c in children:
  if c.find('m_CollectionName').get('text') in ['BuildingSets','BaseVariants']:assert not c.findall('Element')
 for slug in SLUGS:
  p=params(variants['LOTM_HOLY_CITY_'+slug.upper()+'_BUILDING'])
  assert p['Tag_HeroBuilding'].find('m_ElementName').get('text')=='BUILDING_LOTM_RESCUE_HOLY_CITY_'+ZONES[slug]
  assert p['Tag_Era'].find('m_ElementName').get('text')=='DEFAULT' and p['Tag_Culture'].find('m_ElementName').get('text')=='DEFAULT'
  assert p['Priority'].findtext('m_nValue')=='100' and p['Asset'].find('m_EntryName').get('text')=='LHC_'+slug
  assert p['Asset'].find('m_BLPPackage').get('text')=='LOTMHolyCities'
 dep=ET.parse(ART/'LOTMHolyCities.dep').getroot();systems={e.find('ConsumerName').get('text'):e for e in dep.findall('./SystemDependencies/Element')}
 assert set(systems)=={'Landmarks','WorldView_Translate','StrategicView_Translate'}
 assert systems['Landmarks'].findtext('LoadsLibraries')=='true'
 assert systems['Landmarks'].find('./LibraryDependencies/Element').get('text')=='TileBase'
 assert {e.get('text') for e in systems['Landmarks'].findall('./ArtDefDependencyPaths/Element')}=={'Buildings.artdef','Landmarks.artdef'}
 assert dep.find('./LibraryDependencies/Element/PackageDependencies/Element').get('text')=='LOTMHolyCities.blp'
 db=Path(sys.argv[1]) if len(sys.argv)>1 else Path(os.environ['LOCALAPPDATA'])/"Firaxis Games/Sid Meier's Civilization VI/Cache/DebugGameplay.sqlite"
 with sqlite3.connect(db.resolve().as_uri()+'?mode=ro',uri=True) as source,sqlite3.connect(':memory:') as con:
  source.backup(con);con.row_factory=sqlite3.Row;con.execute('PRAGMA foreign_keys=ON')
  # DebugGameplay's Types trigger calls a native hash helper; same local stub
  # as the existing database validators. This does not test the game's hash API.
  con.create_function('Make_Hash',1,lambda value:zlib.crc32(str(value).encode('utf-8')))
  # Permit future reruns against a cache already containing this release;
  # remove only these four selectors from this disposable in-memory copy.
  for name in sorted(BUILDINGS):
   con.execute('DELETE FROM Buildings WHERE BuildingType=?',(name,));con.execute('DELETE FROM Types WHERE Type=?',(name,))
  before=con.total_changes
  con.executescript((ROOT/'Gameplay/LOTM_RESCUE_HolyCityArt.sql').read_text());assert con.total_changes-before==12
  assert not con.execute('PRAGMA foreign_key_check').fetchall()
  rows=con.execute("SELECT * FROM Buildings WHERE BuildingType LIKE 'BUILDING_LOTM_RESCUE_HOLY_CITY_%'").fetchall();assert {r['BuildingType'] for r in rows}==BUILDINGS
  for r in rows:
   assert r['InternalOnly']==1 and r['PrereqDistrict']=='DISTRICT_CITY_CENTER'
   for key in ['Maintenance','OuterDefenseHitPoints','OuterDefenseStrength','Housing','Entertainment']:
    if key in r.keys():assert not r[key],(key,r[key])
  tags={r['Name'] for r in rows}
  text=ET.parse(ROOT/'Text/LOTM_RESCUE_HolyCityArt.xml').getroot()
  for lang in ['zh_Hans_CN','en_US']:assert {r.get('Tag') for r in text.findall('./LocalizedText/Row') if r.get('Language')==lang}==tags
 print('PASS: 4 internal cosmetic buildings, rescue-only actions, unchanged city generator, 4 direct BuildingVariants, 27 bounded static FGX roundtrips, both cooked packages and hashes.')
 print('Boundary: SQLite/static/Cooker checks only; actual city rendering, reload and multiplayer remain unverified.')
if __name__=='__main__':main()
