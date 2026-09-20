#!/usr/bin/env python3
"""Download specified public MIT-BIH records and audit 30 s single-channel windows.

Requires only Python standard library and the ECGAudit Swift executable. This is a
development audit, not Apple Watch validation. Keep records outside the repository.
Source: https://physionet.org/content/mitdb/1.0.0/ (Open Data Commons Attribution).
"""
import argparse, json, pathlib, subprocess, urllib.request

p = argparse.ArgumentParser()
p.add_argument('--directory', required=True)
p.add_argument('--executable', required=True)
p.add_argument('--records', nargs='+', default=['100', '101', '103', '106', '119'])
args = p.parse_args()
root = pathlib.Path(args.directory); root.mkdir(parents=True, exist_ok=True)

def annotations(data):
    result, time, i = [], 0, 0
    while i + 1 < len(data):
        delta, code = data[i] + ((data[i+1] & 3) << 8), data[i+1] >> 2
        i += 2
        if code == 0 and delta == 0: break
        if code == 59:
            value = data[i+2] + (data[i+3] << 8) + (data[i] << 16) + (data[i+1] << 24)
            time += value if value < 2**31 else value - 2**32
            i += 4
        elif code == 63: i += delta + (delta % 2)
        elif code not in (60, 61, 62):
            time += delta
            if code in set(range(1, 14)) | {34, 35, 38}: result.append((time, code))
    return result

summary = []
for record in args.records:
    for extension in ['hea', 'dat', 'atr']:
        path = root / f'{record}.{extension}'
        if not path.exists():
            with urllib.request.urlopen(f'https://physionet.org/files/mitdb/1.0.0/{record}.{extension}', timeout=60) as response:
                path.write_bytes(response.read())
    header = (root / f'{record}.hea').read_text().splitlines()
    fs = float(header[0].split()[2])
    fields = header[1].split()
    assert fields[1] == '212' and int(header[0].split()[1]) == 2
    gain = float(fields[2].split('(')[0].split('/')[0]); baseline = int(fields[4])
    raw = (root / f'{record}.dat').read_bytes()
    values = []
    for i in range(0, len(raw) - 2, 3):
        value = raw[i] + ((raw[i+1] & 15) << 8)
        if value >= 2048: value -= 4096
        values.append((value - baseline) / gain)
    truth = [(sample / fs, code) for sample, code in annotations((root / f'{record}.atr').read_bytes())]
    fixture, result = root / f'{record}.json', root / f'{record}-result.json'
    fixture.write_text(json.dumps({'samplingFrequency': fs, 'values': values}, separators=(',', ':')))
    subprocess.run([args.executable, str(fixture), str(result)], check=True)
    windows = json.loads(result.read_text())
    tp = fp = fn = unassessed = truth_count = evaluated_count = 0
    for window in windows:
        start = window['start']
        beats = window.get('assessment', {}).get('beats', [])
        relevant = [(t, c) for t, c in truth if start + 0.5 <= t < start + 29.5]
        candidates = [b for b in beats if b.get('candidate') and start + 0.5 <= start+b['time'] < start+29.5]
        matched = set()
        for beat in candidates:
            matches = [(abs(t - start - beat['time']), i, c) for i, (t, c) in enumerate(relevant) if i not in matched and abs(t - start - beat['time']) <= 0.15]
            if matches:
                _, i, code = min(matches); matched.add(i)
                if code in (4, 5, 7, 8, 9): tp += 1
                else: fp += 1
            else: fp += 1
        for i, (t, code) in enumerate(relevant):
            assessed = any(not b.get('exclusion') and abs(t - start - b['time']) <= 0.15 for b in beats)
            evaluated_count += assessed
            if code in (4, 5, 7, 8, 9):
                truth_count += 1
                if i not in matched: fn += 1
                if not assessed: unassessed += 1
    item = {'record': record, 'lead': fields[-1], 'windows': len(windows), 'annotated_beats': len(truth), 'assessed_beats': evaluated_count,
            'true_premature': truth_count, 'TP': tp, 'FP': fp, 'FN': fn, 'unassessed_true_premature': unassessed,
            'sensitivity': tp / max(1, tp+fn), 'precision': tp / max(1, tp+fp)}
    summary.append(item); print(json.dumps(item), flush=True)
(root / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
