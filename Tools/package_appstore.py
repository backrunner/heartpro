#!/usr/bin/env python3
"""Generate Connect copy/paste data and a local preparation ZIP. Never uploads."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
STORE = ROOT / 'AppStore'
LIMITS = {'name': 30, 'subtitle': 30, 'description': 4000, 'keywords': 100,
          'promotional_text': 170, 'whats_new': 4000}


def generated_files():
    config = json.loads((STORE / 'localizations.json').read_text())
    state = json.loads((STORE / 'readiness.json').read_text())
    connect_evidence = STORE / 'evidence/connect-2026-10-10/status.json'
    saved = json.loads(connect_evidence.read_text()) if connect_evidence.exists() else {}
    project = (ROOT / 'project.yml').read_text()
    version = re.search(r"MARKETING_VERSION:\s*'([^']+)'", project).group(1)
    build = re.search(r"CURRENT_PROJECT_VERSION:\s*'([^']+)'", project).group(1)
    payload = {
        'purpose': 'Local preparation data; not an App Store Connect API request',
        'submission_ready': state['submission_ready'],
        'external_testflight_ready': state['external_testflight_ready'],
        'bundle_id': state['bundle_id'], 'version': version, 'build': build,
        'primary_locale': config['primary_locale'],
        'primary_category': state['store_category']['primary'],
        'secondary_category': state['store_category']['secondary'],
        'operator': state['operator'],
        'copyright': f"2026 {state['operator'].get('display_name') or 'Alkinum'}",
        'sign_in_required': False,
        'review_notes': (STORE / 'review-notes.txt').read_text().strip(),
        'account_fields_deferred': (
            (['review_contact_name', 'review_contact_email', 'review_contact_phone'] if not saved.get('review_contact_saved') else [])
            + (['price'] if not saved.get('price_base_amount') else [])
            + (['territories'] if not saved.get('territories_saved') else [])
            + (['regulated_medical_device_declaration'] if not saved.get('regulated_medical_device_declaration_saved') else [])
            + (['privacy_publish_confirmation'] if not saved.get('privacy_labels_published') else [])
        ),
        'review_contact_saved_in_connect': saved.get('review_contact_saved', False),
        'price_base': {'currency': saved.get('price_base_currency'), 'amount': saved.get('price_base_amount')},
        'urls_verified_public': state['gates']['public_policies_and_support_https']['complete'],
        'localizations': {},
    }
    lengths = {}
    for entry in config['localizations']:
        locale, language = entry['locale'], entry['language']
        metadata = {field: (STORE / 'metadata' / locale / (field + '.txt')).read_text().strip()
                    for field in LIMITS}
        lengths[locale] = {
            field: {'characters': len(value), 'utf8_bytes': len(value.encode('utf-8')),
                    'limit': LIMITS[field], 'limit_unit': 'UTF-8 bytes' if field == 'keywords' else 'characters'}
            for field, value in metadata.items()
        }
        prefix = 'https://heartpro.alkinum.com/' + ('zh/' if language == 'zh-Hans' else '')
        screenshots = {}
        for group in ['iphone-6.3', 'iphone-6.9', 'ipad-13']:
            folder = STORE / 'screenshots' / group
            capture = json.loads((folder / 'manifest.json').read_text())
            known = {item['file']: item for item in capture['screenshots']}
            screenshots[group] = []
            for scene in config['screenshot_order']:
                filename = f'{language}-{scene}.png'
                item = known[filename]
                screenshots[group].append({
                    'file': f'AppStore/screenshots/{group}/{filename}',
                    'sha256': item['sha256'], 'dimensions': item['dimensions'],
                })
        payload['localizations'][locale] = {
            **metadata,
            'whats_new_usage': 'Reserve for an update; first-version form may not expose this field',
            'marketing_url': prefix,
            'support_url': prefix + 'support/',
            'privacy_policy_url': prefix + 'privacy/',
            'website_language': 'zh-Hans' if language == 'zh-Hans' else 'en',
            'beta_description': (STORE / 'testflight' / f'beta-description.{locale}.txt').read_text().strip(),
            'what_to_test': (STORE / 'testflight' / f'what-to-test.{locale}.txt').read_text().strip(),
            'screenshots_in_upload_order': screenshots,
        }
    return {
        STORE / 'metadata/lengths.json': lengths,
        STORE / 'submission/connect-payload.json': payload,
    }, version, build


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--check', action='store_true')
    mode.add_argument('--zip', action='store_true')
    args = parser.parse_args()
    files, version, build = generated_files()
    for path, data in files.items():
        content = json.dumps(data, ensure_ascii=False, indent=2) + '\n'
        if args.check:
            if not path.is_file() or path.read_text() != content:
                raise SystemExit(f'Stale generated file: {path.relative_to(ROOT)}')
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
    if not args.zip:
        print('Connect preparation data ' + ('verified.' if args.check else 'generated.'))
        return
    subprocess.run(['rtk', 'proxy', 'python3', str(ROOT / 'Tools/check_appstore.py')], cwd=ROOT, check=True)
    selected = set()
    for name in ['metadata', 'testflight', 'icons', 'submission', 'validation']:
        selected.update(path for path in (STORE / name).rglob('*') if path.is_file())
    for group in ['iphone-6.3', 'iphone-6.9', 'ipad-13']:
        selected.update(path for path in (STORE / 'screenshots' / group).iterdir() if path.is_file())
    selected.update((STORE / 'screenshots').glob('*contact-sheet.jpg'))
    for name in ['README.md', 'localizations.json', 'readiness.json', 'connect-settings.md',
                 'review-notes.txt', 'testflight-guide.zh-CN.md', 'compliance-audit.md', 'screenshots/README.md']:
        selected.add(STORE / name)
    # Keep the delivery focused: current summaries, notice previews and synthetic report examples.
    for name in ['validation/device-checklist.md', 'validation/watch-accuracy-protocol.md',
                 'validation/compliance-2026-09-22.md',
                 'validation/health-fitness-2026-10-09.md',
                 'evidence/submission-materials-2026-09-22/online-checks.json',
                 'evidence/submission-materials-2026-09-22/iphone-tests-summary.json',
                 'evidence/submission-materials-2026-09-22/ipad-tests-summary.json',
                 'evidence/usage-notice-design-2026-09-22/zh-usage-notice.png',
                 'evidence/usage-notice-design-2026-09-22/zh-iphone-dark.png',
                 'evidence/usage-notice-design-2026-09-22/zh-ipad-light.png',
                 'evidence/usage-notice-design-2026-09-22/language-contact-sheet.jpg']:
        selected.add(STORE / name)
    selected.update(path for path in (STORE / 'evidence/health-fitness-2026-10-09').rglob('*') if path.is_file())
    selected.update(path for path in (STORE / 'evidence/wave-labels-2026-10-10').rglob('*') if path.is_file())
    selected.update(path for path in (STORE / 'evidence/connect-2026-10-10').rglob('*') if path.is_file())
    selected.update((STORE / 'evidence/testflight-2026-09-22').glob('report-*.pdf'))
    selected.update((STORE / 'evidence/submission-materials-2026-09-22').glob('*.txt'))
    for language in ['en', 'zh']:
        for page in ['privacy', 'terms', 'support']:
            selected.add(ROOT / 'website/content/pages' / language / (page + '.md'))
        selected.add(ROOT / 'website/content/docs' / language / 'methods.md')
    archive = ROOT / f'HeartPro-AppStore-{version}-{build}-preparation.zip'
    inventory = [{'path': str(path.relative_to(ROOT)), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
                 for path in sorted(selected)]
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as output:
        for path in sorted(selected):
            output.write(path, path.relative_to(ROOT))
        output.writestr('CONTENTS-SHA256.json', json.dumps(inventory, indent=2) + '\n')
    with zipfile.ZipFile(archive) as output:
        if output.testzip() is not None:
            raise SystemExit('ZIP integrity check failed')
    print(f'Prepared {len(selected)} files: {archive.name} ({archive.stat().st_size / 1048576:.1f} MiB)')


if __name__ == '__main__':
    main()
