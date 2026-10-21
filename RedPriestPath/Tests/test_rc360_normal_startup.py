"""Regression for normal startup publish spam with real Thief Initialize."""
import hashlib,json,re,unittest,zipfile
import xml.etree.ElementTree as ET
from pathlib import Path
from test_rc346_thief_rule_guards import BASE,LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
FIXTURE=r'''
network=false; rescue=false; scans=0;cleans=0;refreshes=0;probes=0;logs=0
function print(s) if string.find(s,'startup refresh complete') then logs=logs+1 end end
function Event()
 local fs={};return setmetatable({Add=function(f) fs[#fs+1]=f end},
 {__call=function(_,...) for _,f in ipairs(fs) do f(...) end end})
end
function EventTable() return setmetatable({},{__index=function(t,k) local e=Event();rawset(t,k,e);return e end}) end
Events=EventTable();GameEvents=EventTable(); turns={};synchronized={};startups={}
LOTM_MP_TurnSync.Add=function(f,k) turns[k]=f end
LOTM_MP_TurnSync.AddSynchronized=function(f,k) synchronized[k]=f end
LOTM_MP_TurnSync.RunStartup=function(f,k) startups[k]=f end
LOTM_MP_TurnSync.IsNetworkGame=function() return network end
PlayerManager.GetAliveMajorIDs=function() scans=scans+1;return ids end
ids={0,1};Players[0].props.LOTM_RP_PATH='NONE';Players[1].props.LOTM_RP_PATH='NONE'
LOTM_RP_State.RefreshSequenceState=function(id) refreshes=refreshes+1 end
'''
def runtime(old=False):
 lua=LuaRuntime(unpack_returned_tuples=True);lua.execute(BASE);lua.execute(FIXTURE)
 if old:
  z=ROOT.parent/'dist/RedPriestPath-0.1.0-rc.359.zip'
  assert hashlib.sha256(z.read_bytes()).hexdigest()=='cb9ab1d3ffd4758e4646c708568ed6e3f3a7c2fb51b2f081bf7e9d0f222a30f4'
  with zipfile.ZipFile(z) as a:s=a.read('RedPriestPath/Scripts/LOTM_TP_Thief.lua').decode('utf-8-sig')
 else:s=(ROOT/'Scripts/LOTM_TP_Thief.lua').read_text(encoding='utf-8-sig')
 # Preserve real Initialize and its closures; isolate unrelated gameplay APIs.
 s=re.sub(r'Initialize\(\);\s*$',r'''ClearLegacyTradeCarrier=function(id) cleans=cleans+1 end
 ProbePlayer=function(id) probes=probes+1 end
 API={initialize=Initialize}
 ''',s)
 lua.execute(s);return lua
class NormalStartupTests(unittest.TestCase):
 def test_old_release_reproduces_all_5315_publish_retries(self):
  l=runtime(True);l.execute('API.initialize();for i=1,5315 do Events.GameCoreEventPublishComplete() end;assert(logs==5315 and scans==5315 and cleans==10630)')
 def test_new_game_without_thief_completes_once_not_on_publish(self):
  l=runtime();l.execute('''API.initialize();for i=1,5315 do Events.GameCoreEventPublishComplete() end
   assert(scans==0 and cleans==0 and logs==0)
   synchronized.ThiefLoad(0,true);local n=scans
   for i=1,30 do synchronized.ThiefLoad(0,true);Events.GameCoreEventPublishComplete() end
   assert(scans==n and cleans==2 and logs==1 and refreshes==0)''')
 def test_restored_thief_refreshes_once_and_reentrant_turn_does_not_repeat(self):
  l=runtime();l.execute('''API.initialize();Players[0].props.LOTM_RP_PATH='PATH_THIEF'
   LOTM_RP_State.RefreshSequenceState=function() refreshes=refreshes+1;synchronized.ThiefLoad(0,true) end
   synchronized.ThiefLoad(0,true);assert(logs==1 and probes==1 and refreshes==1 and cleans==2)''')
 def test_empty_or_incomplete_registry_waits_without_mutation(self):
  l=runtime();l.execute('''API.initialize();ids={};synchronized.ThiefLoad(0,true);assert(cleans==0)
   ids={0,8};synchronized.ThiefLoad(0,true);assert(cleans==0)
   ids={0,1};synchronized.ThiefLoad(0,false);assert(cleans==0)
   synchronized.ThiefLoad(0,true);assert(cleans==2 and logs==1)''')
 def test_network_branch_unchanged_and_rescue_registers_nothing(self):
  for old in (False,True):
   l=runtime(old);l.execute('network=true;API.initialize();assert(startups.Thief~=nil and synchronized.ThiefLoad==nil);Events.GameCoreEventPublishComplete();assert(scans==0);startups.Thief();assert(cleans==2)')
  l=runtime();l.execute('rescue=true;API.initialize();assert(next(turns)==nil and next(startups)==nil and next(synchronized)==nil)')
 def test_rescue_frozen_files_unchanged_except_release_marker(self):
  baseline=ROOT.parent/'frozen-baselines/rescue-rc359-resource391'
  files=json.loads((baseline/'protected-files.json').read_text(encoding='utf-8'))
  with zipfile.ZipFile(baseline/'RedPriestPath-0.1.0-rc.359.zip') as a:
   for name,digest in files.items():
    now=(ROOT/name).read_bytes();old=a.read('RedPriestPath/'+name)
    self.assertEqual(hashlib.sha256(old).hexdigest(),digest)
    if name=='Scripts/LOTM_RESCUE_Phase10.lua':
     # User's 2026-10-07 storm instruction authorizes this exact appended API.
     # Every original Phase-10 byte and all other frozen files stay protected.
     approved=(baseline/'authorized-deltas/20261007-rescue-storm-damage.lua').read_bytes()
     self.assertEqual(now.count(approved),1)
     now=now.replace(approved,b'',1)
    if name.startswith('UI/'):
     resource=ET.parse(ROOT/'RedPriestPath.modinfo').getroot().get('version').encode('ascii')
     for prefix in (b'resource ',b'Resource=',b'r='):
      now=now.replace(prefix+resource,prefix+b'391')
     if name=='UI/LOTM_RESCUE_CityBootstrap.lua':now=now.replace(b'resource='+resource,b'resource=391')
    self.assertEqual(now,old,name)
if __name__=='__main__':unittest.main(verbosity=2)
