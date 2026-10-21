"""Recovery must remove bad packages, not simply claim their hashes are valid."""
from pathlib import Path
import hashlib,json,xml.etree.ElementTree as E
import build_release
ROOT=Path(__file__).resolve().parents[1]
def main():
 mod=E.parse(ROOT/'RedPriestPath.modinfo').getroot();assert mod.get('version')=='407'
 excluded=['Art/LOTMModelsV4/','Art/LOTMHolyCities/'];forbidden_ids={'LOTM_MODELS_V4_ART','LOTM_RESCUE_HOLY_CITY_ART'}
 declared={f.text for f in mod.findall('./Files/File')}
 for parent in ['InGameActions','FrontEndActions']:
  for action in mod.findall('./'+parent+'/*'):
   assert action.get('id') not in forbidden_ids
   for file in action.findall('.//File'):assert not any((file.text or '').startswith(p) for p in excluded)
 assert not any(any(name.startswith(p) for p in excluded) for name in declared)
 release={p.relative_to(ROOT).as_posix() for p in build_release.release_files()}
 assert not any(any(name.startswith(p) for p in excluded) for name in release)
 assert 'Art/LOTMArtMaterialAudit_rc374.json' not in release
 q=json.loads((ROOT/'Art/ExperimentalArtQuarantine.json').read_text('utf-8'))
 assert set(q['disabled_actions'])==forbidden_ids and q['reason']=='resource406_live_render_failure'
 assert not q['recovery_in_game_verified'] and not q['new_models_fixed']
 for rel,digest in q['retained_source_files'].items():assert hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()==digest,rel
 for rel,digest in q['fallback_runtime_files'].items():
  assert rel in release and rel in declared
  assert hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()==digest,rel
 live={a.get('id') for a in mod.findall('./InGameActions/UpdateArt')}
 assert {'LOTM_RP_ART','LOTM_RESCUE_PHASE3_ART','LOTM_RESCUE_PHASE4_ART','LOTM_RESCUE_PHASE10_ART'}<=live
 print('PASS: both failed packages absent from active actions, declared files and release inventory; prior art remains intact. Recovery rendering still requires live confirmation.')
if __name__=='__main__':main()
