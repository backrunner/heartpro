#!/usr/bin/env python3
"""Local release-material checks. --submission fails until evidence gates are complete."""
from pathlib import Path
import argparse,hashlib,json,plistlib,re,struct,sys
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--submission',action='store_true');args=p.parse_args()
errors=[]
def check(ok, message):
 if not ok:errors.append(message)
yaml=(root/'project.yml').read_text();check('PRODUCT_BUNDLE_IDENTIFIER: com.alkinum.heartpro' in yaml,'Wrong bundle ID')
manifest=plistlib.loads((root/'HeartPro/Resources/PrivacyInfo.xcprivacy').read_bytes())
check(manifest.get('NSPrivacyTracking') is False,'Unexpected tracking')
reasons={x['NSPrivacyAccessedAPIType']:x['NSPrivacyAccessedAPITypeReasons'] for x in manifest['NSPrivacyAccessedAPITypes']}
check('CA92.1' in reasons.get('NSPrivacyAccessedAPICategoryUserDefaults',[]),'Missing AppStorage reason')
check('C617.1' in reasons.get('NSPrivacyAccessedAPICategoryFileTimestamp',[]),'Missing file timestamp reason')
limits={'name':30,'subtitle':30,'description':4000,'keywords':100,'promotional_text':170,'whats_new':4000}
for lang in ['en-US','zh-Hans']:
 for name,limit in limits.items():
  value=(root/f'AppStore/metadata/{lang}/{name}.txt').read_text().strip()
  check(0<len(value)<=limit,f'{lang}/{name}: {len(value)} exceeds {limit}')
for f in (root/'AppStore/icons').glob('*.png'):
 b=f.read_bytes();check(struct.unpack('>II',b[16:24])==(1024,1024),f'{f.name}: wrong icon size');check(b[25]==2,f'{f.name}: expected RGB without alpha')
state=json.loads((root/'AppStore/readiness.json').read_text())
version=re.search(r"MARKETING_VERSION:\s*'([^']+)'",yaml).group(1)
build=re.search(r"CURRENT_PROJECT_VERSION:\s*'([^']+)'",yaml).group(1)
for group,allowed in [('iphone-6.9',{(1320,2868),(1290,2796),(1260,2736)}),('ipad-13',{(2064,2752),(2048,2732)})]:
 folder=root/'AppStore/screenshots'/group
 capture=folder/'manifest.json'
 if not capture.is_file():
  check(not args.submission,f'{group}: screenshot manifest missing')
  continue
 data=json.loads(capture.read_text())
 check(data.get('bundle_id')==state['bundle_id'],f'{group}: wrong capture bundle ID')
 check(data.get('version')==version and data.get('build')==build,f'{group}: stale capture version/build')
 expected={f'{lang}-{i:02d}-{scene}.png' for lang in ['en','zh-Hans'] for i,scene in enumerate(['history','daily','trends','waveform','note','privacy-settings'],1)}
 check({f.name for f in folder.glob('*.png')}==expected,f'{group}: missing or unexpected upload PNGs')
 items=data.get('screenshots',[])
 check({item['file'] for item in items}==expected and len(items)==12,f'{group}: incomplete capture set')
 for item in items:
  f=folder/item['file']
  if not f.is_file():
   check(False,f'{group}/{f.name}: missing image');continue
  b=f.read_bytes()
  check(hashlib.sha256(b).hexdigest()==item['sha256'],f'{group}/{f.name}: image differs from capture')
  check(b[:8]==b'\x89PNG\r\n\x1a\n' and struct.unpack('>II',b[16:24]) in allowed,f'{group}/{f.name}: incorrect PNG dimensions')
 if args.submission or state['gates']['current_iphone_and_ipad_screenshots']['complete']:
  check(data.get('visual_review_complete') is True,f'{group}: visual review missing')
if args.submission:
 for gate,v in state['gates'].items():
  check(v['complete'] and v['evidence'] and (root/'AppStore'/v['evidence']).is_file(),f'BLOCKED: {gate}')
 check(state['submission_ready'],'Submission has not been approved as ready')
if errors:print('\n'.join(errors));sys.exit(1)
print('Local materials verified.' if not args.submission else 'Submission evidence gates verified; Apple still determines review outcome.')
