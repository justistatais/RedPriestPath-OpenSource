"""Verify the actual release includes every cooked external texture/animation."""
from pathlib import Path
import hashlib,json,xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1]
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 declared={x.text for x in E.parse(ROOT/'RedPriestPath.modinfo').getroot().findall('./Files/File')};total=0
 for package in ['LOTMModelsV4','LOTMHolyCities']:
  art=ROOT/'Art'/package;manifest=json.loads((art/'manifest.json').read_text('utf-8'));files=manifest['files'];assert manifest['release_includes_all_cooker_outputs']
  for rel,sha in files.items():assert 'Art/'+package+'/'+rel in declared and digest(art/rel)==sha,(package,rel)
  for platform in ['Windows','MacOS']:
   prefix=f'Platforms/{platform}/BLPs/SHARED_DATA/';shared={rel for rel in files if rel.startswith(prefix)};assert len(shared)>=22
   expected=set(manifest['cooker_shared_files'][platform]);assert {r.removeprefix(prefix) for r in shared}==expected
   blob=(art/f'Platforms/{platform}/BLPs/{package}.blp').read_bytes()
   for rel in shared:
    p=art/rel;assert p.read_bytes()[:6]==b'CIVBIG';assert p.name.encode('ascii') in blob,p.name
   total+=len(shared)
 audit=json.loads((ROOT/'Art/LOTMGeometryAudit_rc378.json').read_text('utf-8'));assert len(audit['geometries'])==27
 assert audit['native_static_stride']==84 and audit['failed_city_stride']==76
 for g in audit['geometries']:
  l=g['layout'];r=g['roundtrip'];names={f['name'] for f in l['layout']};assert l['stride']==84
  assert not names&{'BoneWeights','BoneIndices'} and {'TextureCoordinates0','TextureCoordinates1','TextureCoordinates2'}<=names
  assert l['vertices']<=12000 and r['triangles']<=6000 and r['position_max_error']<.0002 and r['uv_max_error']<.00001
 for key,value in audit['package_hashes'].items():assert digest(ROOT/'Art'/key)==value
 print(f'PASS: {total} external cooked files included/declared/hashed; 27 bounded static three-UV geometry resources; final BLP hashes match audits.')
 print('Boundary: no in-game rendering or multiplayer verdict from this offline check.')
if __name__=='__main__':main()
