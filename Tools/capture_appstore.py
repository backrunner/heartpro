#!/usr/bin/env python3
"""Capture and export real XCTest screenshots; never resize or fabricate app screens."""
import argparse, datetime, hashlib, json, os, pathlib, plistlib, shutil, signal, struct, subprocess, sys, tempfile
ROOT = pathlib.Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('--device', required=True, help='Dedicated simulator UDID, not a personal device')
p.add_argument('--group', choices=['iphone-6.9', 'ipad-13'], required=True)
p.add_argument('--timeout', type=int, default=600)
a = p.parse_args()
def run(*args, timeout=60, capture=False):
    process = subprocess.Popen(['rtk', 'proxy', *args], cwd=ROOT, text=True, start_new_session=True,
                               stdout=subprocess.PIPE if capture else None,
                               stderr=subprocess.PIPE if capture else None)
    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGTERM)
        try: process.communicate(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL); process.communicate()
        raise
    if process.returncode: raise subprocess.CalledProcessError(process.returncode, args, stdout, stderr)
    return subprocess.CompletedProcess(args, process.returncode, stdout, stderr)
try:
    devices = json.loads(run('xcrun', 'simctl', 'list', 'devices', 'available', '-j', capture=True).stdout)
    device = next(d for ds in devices['devices'].values() for d in ds if d['udid'] == a.device)
    if device['state'] != 'Booted':
        run('xcrun', 'simctl', 'boot', a.device)
        run('xcrun', 'simctl', 'bootstatus', a.device, '-b', timeout=180)
    run('xcrun', 'simctl', 'status_bar', a.device, 'override', '--time', '9:41', '--dataNetwork', 'wifi',
        '--wifiMode', 'active', '--wifiBars', '3', '--batteryState', 'discharging', '--batteryLevel', '100')
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    result = ROOT / f'TestResults/AppStore-{a.group}-{stamp}.xcresult'
    run('xcodegen', 'generate')
    run('xcodebuild', '-project', 'HeartPro.xcodeproj', '-scheme', 'HeartPro',
        '-destination', f'platform=iOS Simulator,id={a.device}', '-derivedDataPath', 'DerivedData',
        '-resultBundlePath', str(result), '-parallel-testing-enabled', 'NO', '-collect-test-diagnostics', 'never',
        '-only-testing:HeartProUITests/AppStoreScreenshotTests', 'CODE_SIGNING_ALLOWED=NO', 'test', timeout=a.timeout)
    with tempfile.TemporaryDirectory(prefix='heartpro-screenshots-') as tmp:
        export = pathlib.Path(tmp)
        run('xcrun', 'xcresulttool', 'export', 'attachments', '--path', str(result), '--output-path', tmp)
        manifest = json.loads((export / 'manifest.json').read_text())
        attachments = []
        def walk(value):
            if isinstance(value, dict):
                if 'exportedFileName' in value: attachments.append(value)
                for child in value.values(): walk(child)
            elif isinstance(value, list):
                for child in value: walk(child)
        walk(manifest)
        chosen = {}
        for item in attachments:
            name = item.get('suggestedHumanReadableName', '')
            for language in ['en', 'zh-Hans']:
                for index, screen in enumerate(['history', 'daily', 'trends', 'waveform', 'note', 'privacy-settings'], 1):
                    key = f'{language}-{index:02d}-{screen}'
                    if name.startswith(key): chosen[key] = export / item['exportedFileName']
        if len(chosen) != 12: raise ValueError(f'Expected 12 named screenshots, found {len(chosen)}; inspect {result}')
        accepted = {'iphone-6.9': {(1320,2868),(1290,2796),(1260,2736)}, 'ipad-13': {(2064,2752),(2048,2732)}}[a.group]
        for key, file in chosen.items():
            data = file.read_bytes()
            if data[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack('>II', data[16:24]) not in accepted:
                raise ValueError(f'Wrong screen dimensions for {key}; capture on the correct device, do not resize.')
        destination = ROOT / 'AppStore/screenshots' / a.group
        destination.mkdir(parents=True, exist_ok=True)
        info = plistlib.loads((ROOT / 'DerivedData/Build/Products/Debug-iphonesimulator/HeartPro.app/Info.plist').read_bytes())
        assert info['CFBundleIdentifier'] == 'com.alkinum.heartpro'
        items = []
        for key, file in sorted(chosen.items()):
            target = destination / (key + '.png'); shutil.copy2(file, target)
            items.append({'file':target.name,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
                          'dimensions':list(struct.unpack('>II', target.read_bytes()[16:24]))})
        (destination / 'manifest.json').write_text(json.dumps({'bundle_id':info['CFBundleIdentifier'],
            'version':info['CFBundleShortVersionString'],'build':info['CFBundleVersion'],'device':device,
            'captured_at':stamp,'xcresult':str(result.relative_to(ROOT)),'data':'synthetic, labelled in the app',
            'visual_review_complete':False,'screenshots':items}, indent=2)+'\n')
        print(f'Exported 12 screenshots to {destination}; visual review is still required.')
except (subprocess.SubprocessError, ValueError, StopIteration, AssertionError, OSError) as error:
    sys.exit(f'Capture failed without promoting incomplete assets: {error}')
