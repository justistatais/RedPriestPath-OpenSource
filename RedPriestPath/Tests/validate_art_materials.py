"""Bind the decoded-pixel audit to shipped BLP bytes; prevent missing PBR slots."""
from pathlib import Path
import hashlib,json,xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1]
def main():
 report=json.loads((ROOT/'Art/LOTMArtMaterialAudit_rc378.json').read_text('utf-8'))
 assert not report['in_game_fixed'] and not report['multiplayer_fixed']
 expected={'LOTMModelsV4':['LOTM4_Saint_Body','LOTM4_Angel_Body','LOTM4_Angel_FX'],'LOTMHolyCities':['LHC_Fool','LHC_Night','LHC_Storm']}
 assert len(report['package_hashes'])==4
 for rel,digest in report['package_hashes'].items():assert hashlib.sha256((ROOT/'Art'/rel).read_bytes()).hexdigest()==digest,rel
 expected_checks={(pkg,platform,stem+'_'+ch) for pkg,stems in expected.items() for stem in stems for ch in ['BaseColor','Emissive'] for platform in ['Windows','MacOS']}
 checks=report['cooked_color_checks'];assert len(checks)==24
 assert {(c['package'],c['platform'],c['texture']) for c in checks}==expected_checks
 assert all(max(c['mean_abs_error'])<2 for c in checks)
 for c in checks:assert hashlib.sha256((ROOT/c['shipped_file']).read_bytes()).hexdigest()==c['cooked_sha256']
 materials={m['name']:m['maps'] for m in report['complete_materials']};assert len(materials)==6
 for package,stems in expected.items():
  for stem in stems:
   maps=materials[stem if package=='LOTMModelsV4' else stem+'_Atlas']
   assert all(maps[k] for k in ['BaseColor','Normal','AO','Metalness','Gloss','Emissive','TintMask'])
   for platform in ['Windows','MacOS']:
    blob=(ROOT/f'Art/{package}/Platforms/{platform}/BLPs/{package}.blp').read_bytes()
    for channel in ['Normal','AO','Metalness','Gloss']:assert ('TEXTURE_'+maps[channel]).encode() in blob,(stem,channel)
 for key,slugs,minimum in [('non_emitting_body_checks',['Saint','Angel'],23),('non_emitting_city_checks',['Fool','Night','Storm'],10)]:
  rows=report[key];assert {(r['slug'],r['platform']) for r in rows}=={(s,p) for s in slugs for p in ['Windows','MacOS']}
  assert all(r['non_emitting_cells_confirmed_black']>=minimum for r in rows)
 assert len(report['geometry_unchanged'])==9 and report['static_geometry_rebuilt']==27
 declared={f.text for f in E.parse(ROOT/'RedPriestPath.modinfo').getroot().findall('./Files/File')}
 assert 'Art/LOTMArtMaterialAudit_rc378.json' in declared
 print('PASS: 4 BLP hashes bind 24 cooked color checks, 6 complete materials and non-emitting character/city cells. In-game visuals remain pending.')
if __name__=='__main__':main()
