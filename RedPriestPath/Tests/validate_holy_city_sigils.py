"""Release-bound checks for large native scrolling seals and the astral gate."""
from pathlib import Path
import json,hashlib,xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 report=json.loads((ROOT/'Art/LOTMHolyCitySigilsAudit_rc378.json').read_text());assert report['resource']==410
 assert not report['in_game_verified'] and not report['in_game_animation_verified'] and not report['multiplayer_verified']
 assert len(report['cooker'])==4 and all(x['returncode']==0 for x in report['cooker'])
 for file,digest in report['package_hashes'].items():assert sha(ROOT/'Art'/file)==digest
 mats=report['materials'];assert len(mats)==9
 assert {(m['city'],m['part']) for m in mats}=={(s,p) for s in ['Fool','Night','Storm','Star'] for p in ['Main','Outer']}|{('Star','Portal')}
 for m in mats:
  assert m['shader']=='Landmark' and m['polar_uv'] and set(m['maps'])=={'BaseColor','Emissive','Opacity'} and all(m['maps'].values())
  expected={'Main':36,'Outer':-54,'Portal':64}[m['part']];assert m['seconds_per_turn']==expected and abs(m['scroll_u']-1/expected)<1e-10
  if m['part']!='Portal':assert m['radius']>report['footprint_radius']*3
 textures=report['decoded_texture_checks'];assert len(textures)==54
 for t in textures:
  assert sha(ROOT/'Art/LOTMHolyCities'/t['file'])==t['sha256'] and max(t['mean_abs_error'])<3 and (t['width'],t['height'])==(2048,1024)
  if t['channel']=='Opacity' and 'Portal' not in t['texture']:assert t['transparent_fraction']>.4 and t['visible_fraction']>.003
 geo=report['new_geometry'];assert len(geo)==27
 for g in geo:
  l=g['layout'];assert l['stride']==84 and l['vertices']==g['vertices'] and g['max_index']<g['vertices']<=12000 and g['triangles']<=6000
  assert g['position_error']<.0002 and g['uv_error']<1e-5
  assert not {f['name'] for f in l['layout']}&{'BoneWeights','BoneIndices'}
 assert len(report['preserved_original_city_geometries'])==27
 assert {b['slug'] for b in report['bindings']}=={'Fool','Night','Storm','Star'}
 for b in report['bindings']:
  assert b['footprint']=='LHC_CityFootprint' and not b['auto_footprint'] and len([x for x in b['models'] if 'Sigil' in x])==3
  if b['slug']=='Star':assert len([x for x in b['models'] if 'Gate' in x])==12 and len([x for x in b['models'] if 'Portal' in x])==2
  else:assert len([x for x in b['models'] if 'Sigil' not in x])==9
 declared={x.text for x in E.parse(ROOT/'RedPriestPath.modinfo').getroot().findall('./Files/File')};assert 'Art/LOTMHolyCitySigilsAudit_rc378.json' in declared
 print('PASS: release hashes bind four city designs, nine scrolling materials, 54 decoded texture checks and 27 new bounded static geometries; in-game motion remains unverified.')
if __name__=='__main__':main()
