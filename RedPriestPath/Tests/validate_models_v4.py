"""Gate the final V4 override, not just the retained V3 fallback package."""
from pathlib import Path
import hashlib,json,xml.etree.ElementTree as ET
from validate_god_models import named_elements
ROOT=Path(__file__).resolve().parents[1];ART=ROOT/'Art/LOTMModelsV4'
EXPECTED={
 'UNIT_LOTM_RESCUE_GOD_FOOL':'Fool','UNIT_LOTM_RESCUE_GOD_NIGHT':'Night',
 'UNIT_LOTM_RESCUE_GOD_STORM':'Storm','UNIT_LOTM_RESCUE_GOD_RED_PRIEST':'RedPriest',
 'UNIT_LOTM_RESCUE_GOD_BLACK_EMPEROR':'BlackEmperor','UNIT_LOTM_RESCUE_GOD_PERFECT':'Perfect',
 'UNIT_LOTM_RESCUE_GOD_THIEF':'Perfect','UNIT_LOTM_RESCUE_OUTER_GOD_AVATAR':'OuterGod',
 'UNIT_LOTM_RESCUE_OUTER_GOD_MINION':'OuterGod',
 **{f'UNIT_LOTM_RESCUE_{c}_{level.upper()}':level for c in ('FOOL','NIGHT','STORM') for level in ('Saint','Angel')}}
def params(element):
 return {e.find('m_ParamName').get('text'):e for e in element.findall('./m_Fields/m_Values/Element') if e.find('m_ParamName') is not None}
def main():
 mod=ET.parse(ROOT/'RedPriestPath.modinfo').getroot();actions=mod.findall('./InGameActions/UpdateArt')
 action=next(a for a in actions if a.get('id')=='LOTM_MODELS_V4_ART')
 assert action.get('criteria')=='LOTM_RP_RESCUE_MODE'
 assert action.findtext('File')=='Art/LOTMModelsV4/LOTMModelsV4.dep'
 order=int(action.findtext('./Properties/LoadOrder'))
 assert all(order>int(a.findtext('./Properties/LoadOrder') or '0') for a in actions if a.get('id') in ('LOTM_RESCUE_PHASE3_ART','LOTM_RESCUE_PHASE10_ART'))
 declared={f.text for f in mod.findall('./Files/File')};required=['LOTMModelsV4.dep','ArtDefs/Units.artdef','ArtDefs/Unit_Bins.artdef','Platforms/Windows/BLPs/LOTMModelsV4.blp','Platforms/MacOS/BLPs/LOTMModelsV4.blp']
 manifest=json.loads((ART/'manifest.json').read_text('utf-8'))
 for rel in required:
  assert 'Art/LOTMModelsV4/'+rel in declared
  assert hashlib.sha256((ART/rel).read_bytes()).hexdigest()==manifest['files'][rel]
 root=ET.parse(ART/'ArtDefs/Units.artdef').getroot();units=named_elements(root,'Units');members=named_elements(root,'UnitMemberTypes')
 assert set(units)==set(EXPECTED)
 unitcol=next(c for c in root.findall('./m_RootCollections/Element') if c.find('m_CollectionName').get('text')=='Units')
 assert unitcol.findtext('m_ReplaceMergedCollectionElements')=='false'
 for name,slug in EXPECTED.items():
  unit=units[name];assert params(unit)['ProxyUnit'].find('m_ElementName').get('text')==''
  col=next(c for c in unit.findall('./m_ChildCollections/Element') if c.find('m_CollectionName').get('text')=='Members')
  assert col.findtext('m_ReplaceMergedCollectionElements')=='true'
  entries=col.findall('Element');assert len(entries)==1
  p=params(entries[0]);assert p['Type'].find('m_ElementName').get('text')=='LOTM4_'+slug
  assert p['Count'].findtext('m_nValue')=='1'
  assert 'LOTM4_'+slug in members
 for platform in ('Windows','MacOS'):
  blob=(ART/f'Platforms/{platform}/BLPs/LOTMModelsV4.blp').read_bytes();assert len(blob)>3000000
  for slug in set(EXPECTED.values()):
   assert f'TEXTURE_DiffuseTint_LOTM4_{slug}_Body_BaseColor_LOTM4_NoTint'.encode() in blob
  assert b'TEXTURE_LOTM4_Angel_FX_Emissive' in blob
  assert b'TEXTURE_DiffuseTint_LOTM4_Angel_FX_BaseColor_LOTM4_NoTint' in blob
 assert len(manifest['roundtrip'])==9
 for model in manifest['roundtrip']:
  assert model['bone_hierarchy_equal']
  for mesh in model['meshes']:assert mesh['max_influences']<=4 and mesh['position_max_error']<.0002 and mesh['vertices']<65536
 print('PASS: V4 models: 15 unit overrides, rescue criterion, later load order, cleared proxies, one member per unit, 9 FGX roundtrips, both cooked bundles and no owner tint.')
 print('Boundary: static/Cooker checks; in-game movement, combat, FX and multiplayer remain unverified.')
if __name__=='__main__':main()
