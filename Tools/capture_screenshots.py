#!/usr/bin/env python3
"""Capture and export real XCTest screenshots; never resize or fabricate app screens."""
import argparse, datetime, hashlib, json, os, pathlib, plistlib, shutil, signal, struct, subprocess, sys, tempfile
from screenshot_common import app_source_fingerprint
ROOT = pathlib.Path(__file__).resolve().parents[1]
LANGUAGES = sorted(path.stem for path in (ROOT / 'Packages/HeartProCore/Sources/HeartProCore/Resources').glob('*.lproj'))
p = argparse.ArgumentParser()
p.add_argument('--device', required=True, help='Dedicated simulator UDID, not a personal device')
p.add_argument('--group', choices=['iphone-6.9', 'iphone-6.3', 'ipad-13'], required=True)
p.add_argument('--output', type=pathlib.Path, help='Output directory; defaults to ignored TestResults/screenshots')
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
    result = ROOT / f'TestResults/Screenshots-{a.group}-{stamp}.xcresult'
    result.parent.mkdir(parents=True, exist_ok=True)
    source_fingerprint = app_source_fingerprint(ROOT)
    run('xcodebuild', '-project', 'HeartPro.xcodeproj', '-scheme', 'HeartPro',
        '-destination', f'platform=iOS Simulator,id={a.device}', '-derivedDataPath', 'DerivedData',
        '-resultBundlePath', str(result), '-parallel-testing-enabled', 'NO', '-collect-test-diagnostics', 'never',
        '-only-testing:HeartProUITests/ScreenshotUITests', 'CODE_SIGNING_ALLOWED=NO', 'test', timeout=a.timeout)
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
            for language in LANGUAGES:
                for index, screen in enumerate(['history', 'daily', 'trends', 'waveform', 'note', 'privacy-settings'], 1):
                    key = f'{language}-{index:02d}-{screen}'
                    if name.startswith(key): chosen[key] = export / item['exportedFileName']
        expected_count = 6 * len(LANGUAGES)
        if len(chosen) != expected_count: raise ValueError(f'Expected {expected_count} named screenshots, found {len(chosen)}; inspect {result}')
        if app_source_fingerprint(ROOT) != source_fingerprint:
            raise ValueError('App sources changed during capture; keep the previous assets and recapture.')
        accepted = {'iphone-6.9': {(1320,2868),(1290,2796),(1260,2736)}, 'iphone-6.3': {(1206,2622),(1179,2556)}, 'ipad-13': {(2064,2752),(2048,2732)}}[a.group]
        for key, file in chosen.items():
            data = file.read_bytes()
            if data[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack('>II', data[16:24]) not in accepted:
                raise ValueError(f'Wrong screen dimensions for {key}; capture on the correct device, do not resize.')
        destination = a.output.resolve() if a.output else ROOT / 'TestResults/screenshots' / a.group / stamp
        destination.mkdir(parents=True, exist_ok=True)
        info = plistlib.loads((ROOT / 'DerivedData/Build/Products/Debug-iphonesimulator/HeartPro.app/Info.plist').read_bytes())
        assert info['CFBundleIdentifier'] == 'com.alkinum.heartpro'
        items = []
        for key, file in sorted(chosen.items()):
            target = destination / (key + '.png'); shutil.copy2(file, target)
            items.append({'file':target.name,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
                          'dimensions':list(struct.unpack('>II', target.read_bytes()[16:24]))})
        (destination / 'manifest.json').write_text(json.dumps({'bundle_id':info['CFBundleIdentifier'],
            'version':info['CFBundleShortVersionString'],'build':info['CFBundleVersion'],'device':device['name'],
            'captured_at':stamp,'xcresult':str(result.relative_to(ROOT)),'data':'synthetic, labelled in the app',
            'source_fingerprint_sha256':source_fingerprint,
            'visual_review_complete':False,'screenshots':items}, indent=2)+'\n')
        print(f'Exported {expected_count} screenshots to {destination}; visual review is still required.')
except (subprocess.SubprocessError, ValueError, StopIteration, AssertionError, OSError) as error:
    sys.exit(f'Capture failed without promoting incomplete assets: {error}')
