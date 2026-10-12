#!/usr/bin/env python3
"""Local material checks; release modes require their own evidence gates."""
from pathlib import Path
import argparse,hashlib,json,plistlib,re,struct,sys
from appstore_common import app_source_fingerprint
from check_entitlements import check_source
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
mode=p.add_mutually_exclusive_group()
mode.add_argument('--submission',action='store_true')
mode.add_argument('--external-testflight',action='store_true')
args=p.parse_args()
errors=[]
errors.extend(check_source(root))
def check(ok, message):
 if not ok:errors.append(message)
yaml=(root/'project.yml').read_text();check('PRODUCT_BUNDLE_IDENTIFIER: com.alkinum.heartpro' in yaml,'Wrong bundle ID')
manifest=plistlib.loads((root/'HeartPro/Resources/PrivacyInfo.xcprivacy').read_bytes())
check(manifest.get('NSPrivacyTracking') is False,'Unexpected tracking')
reasons={x['NSPrivacyAccessedAPIType']:x['NSPrivacyAccessedAPITypeReasons'] for x in manifest['NSPrivacyAccessedAPITypes']}
check('CA92.1' in reasons.get('NSPrivacyAccessedAPICategoryUserDefaults',[]),'Missing AppStorage reason')
check('C617.1' in reasons.get('NSPrivacyAccessedAPICategoryFileTimestamp',[]),'Missing file timestamp reason')
limits={'name':30,'subtitle':30,'description':4000,'keywords':100,'promotional_text':170,'whats_new':4000}
configuration=json.loads((root/'AppStore/localizations.json').read_text())
localizations=configuration['localizations']
expected_locales={entry['locale'] for entry in localizations}
check({p.name for p in (root/'AppStore/metadata').iterdir() if p.is_dir()}==expected_locales,'Unexpected or missing metadata locale')
lengths={}
for entry in localizations:
 lang=entry['locale'];lengths[lang]={}
 for name,limit in limits.items():
  value=(root/f'AppStore/metadata/{lang}/{name}.txt').read_text().strip()
  count=len(value.encode('utf-8')) if name=='keywords' else len(value)
  unit='UTF-8 bytes' if name=='keywords' else 'characters'
  check(0<count<=limit,f'{lang}/{name}: {count} {unit}, limit {limit}')
  lengths[lang][name]={'characters':len(value),'utf8_bytes':len(value.encode('utf-8')),'limit':limit,'limit_unit':unit}
 for field in ['beta-description','what-to-test']:
  value=(root/f'AppStore/testflight/{field}.{lang}.txt').read_text().strip()
  check(0<len(value)<=4000,f'{lang}/{field}: empty or exceeds 4000 characters')
check(json.loads((root/'AppStore/metadata/lengths.json').read_text())==lengths,'Stale metadata lengths; run Tools/package_appstore.py')
check(0<len((root/'AppStore/review-notes.txt').read_text().strip().encode('utf-8'))<=4000,'Review notes: empty or exceeds 4000 UTF-8 bytes')
for f in (root/'AppStore/icons').glob('*.png'):
 b=f.read_bytes();check(struct.unpack('>II',b[16:24])==(1024,1024),f'{f.name}: wrong icon size');check(b[25]==2,f'{f.name}: expected RGB without alpha')
state=json.loads((root/'AppStore/readiness.json').read_text())
check(state.get('store_category',{}).get('primary')=='Health & Fitness','Expected Health & Fitness primary category')
check('INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.healthcare-fitness' in yaml,'Wrong native category')
source_fingerprint=app_source_fingerprint(root)
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
 expected={f'{entry["language"]}-{i:02d}-{scene}.png' for entry in localizations for i,scene in enumerate(['history','daily','trends','waveform','note','privacy-settings'],1)}
 check({f.name for f in folder.glob('*.png')}==expected,f'{group}: missing or unexpected upload PNGs')
 items=data.get('screenshots',[])
 check({item['file'] for item in items}==expected and len(items)==len(expected),f'{group}: incomplete capture set')
 for item in items:
  f=folder/item['file']
  if not f.is_file():
   check(False,f'{group}/{f.name}: missing image');continue
  b=f.read_bytes()
  check(hashlib.sha256(b).hexdigest()==item['sha256'],f'{group}/{f.name}: image differs from capture')
  check(b[:8]==b'\x89PNG\r\n\x1a\n' and struct.unpack('>II',b[16:24]) in allowed,f'{group}/{f.name}: incorrect PNG dimensions')
  check(b[25]==2,f'{group}/{f.name}: expected RGB screenshot without alpha')
 if args.submission or state['gates']['current_iphone_and_ipad_screenshots']['complete']:
  check(data.get('visual_review_complete') is True,f'{group}: visual review missing')
  check(data.get('source_fingerprint_sha256')==source_fingerprint,f'{group}: capture does not match current app sources; recapture')
if args.submission:
 for gate,v in state['gates'].items():
  check(v['complete'] and v['evidence'] and (root/'AppStore'/v['evidence']).is_file(),f'BLOCKED: {gate}')
 check(state['submission_ready'],'Submission has not been approved as ready')
if args.external_testflight:
 for gate in state['external_testflight_gates']:
  v=state['gates'][gate]
  check(v['complete'] and v['evidence'] and (root/'AppStore'/v['evidence']).is_file(),f'BLOCKED: {gate}')
 check(state.get('external_testflight_ready') is True,'External TestFlight has not been verified as ready')
if errors:print('\n'.join(errors));sys.exit(1)
if not state['gates']['current_iphone_and_ipad_screenshots']['complete']:
 print('NOTICE: screenshot readiness is not complete; do not treat existing captures as current.')
print('Local materials verified; this is not approval to distribute.' if not (args.submission or args.external_testflight) else 'Evidence gates verified; Apple still determines review outcome.')
