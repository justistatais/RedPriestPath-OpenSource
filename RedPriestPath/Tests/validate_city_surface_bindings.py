"""Catch intact textures with wrong runtime UVs, the cause of resource409 failure."""
from pathlib import Path
import json,hashlib,xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 r=json.loads((ROOT/'Art/LOTMHolyCitySurfaceAudit_rc378.json').read_text('utf-8'));assert r['resource']==410 and r['modified_geometries']==26
 assert not r['in_game_verified'] and not r['multiplayer_verified'] and r['user_requested_manual_game_test']
 for f,h in r['package_hashes'].items():assert sha(ROOT/'Art'/f)==h
 assert len(r['body_pixel_checks'])==8 and len(r['body_palette_samples'])==2
 for p in r['body_pixel_checks']:assert sha(ROOT/'Art/LOTMHolyCities'/p['file'])==p['sha256'] and max(p['mean_abs_error'])<3
 for p in r['body_palette_samples']:
  assert p['before_all_cells_black'] and p['before_all_ao_zero'] and p['after_ao_min']>250 and p['after_colored_cells']==p['used_cells']==7 and p['emitting_cells']==2
  assert all(max(c['color'])>30 and c['native_uv'][1] in [.625,.875] for c in p['cells'])
 assert len(r['outer_band_samples'])==8 and {(p['city'],p['platform']) for p in r['outer_band_samples']}=={(s,p) for s in ['Fool','Night','Storm','Star'] for p in ['Windows','MacOS']}
 for p in r['outer_band_samples']:
  assert sha(ROOT/'Art/LOTMHolyCities'/p['texture_file'])==p['texture_sha256'];assert p['before_visible_fraction']==0 and p['after_visible_fraction']>.05 and p['after_angular_coverage']==1
 assert len(r['polar_uv_checks'])==14
 for p in r['polar_uv_checks']:
  assert p['max_native_radial_uv_error']<1e-6 and p['max_native_angular_uv_error']<2e-5
  if p['ground_z'] is not None:assert p['ground_z']==(28 if 'Outer' in p['geometry'] else 24)
 assert r['minimum_cull_radius_world']==100 and r['obstruction_radius_source']==249
 assert len(r['geometry_audit'])==27
 for p in r['geometry_audit']:
  assert p['layout']['stride']==84 and p['max_index']<p['vertices']<=12000 and p['triangles']<=6000
  if p['geometry']!='LHC_CityFootprint':assert p['zero_area_triangles']==0 and p['normal_error']<1e-5 and p['normal_tangent_dot']<1e-5
 declared={p.text for p in E.parse(ROOT/'RedPriestPath.modinfo').getroot().findall('./Files/File')};assert 'Art/LOTMHolyCitySurfaceAudit_rc378.json' in declared
 print('PASS: final geometry UVs reach 7 colored gate cells with valid AO and 4 complete outer-ring textures on both platforms; release hashes bind the evidence. Actual terrain/rotation remains user-tested.')
if __name__=='__main__':main()
