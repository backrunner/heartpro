#!/usr/bin/env python3
"""Enforce HeartPro's capability budget; optionally inspect an actual signed app."""

import argparse
import fnmatch
import plistlib
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BUNDLE_ID = "com.alkinum.heartpro"
HEALTHKIT = "com.apple.developer.healthkit"
SOURCE_PATH = "HeartPro/HeartPro.entitlements"
SIGNING_KEYS = {
    "application-identifier", "com.apple.developer.team-identifier",
    "get-task-allow", "beta-reports-active", "keychain-access-groups",
}
USAGE_KEYS = {"NSHealthShareUsageDescription", "NSHealthUpdateUsageDescription"}


def validate_entitlements(values, *, signed=False, development=False):
    errors = []
    if not isinstance(values, dict):
        return ["Entitlements must be a dictionary"]
    allowed = {HEALTHKIT} | (SIGNING_KEYS if signed else set())
    extra = set(values) - allowed
    if extra:
        errors.append("Unexpected entitlements: " + ", ".join(sorted(extra)))
    if values.get(HEALTHKIT) is not True:
        errors.append("HealthKit must remain enabled for the existing health features")
    if signed:
        team = values.get("com.apple.developer.team-identifier")
        app_id = values.get("application-identifier")
        if not isinstance(team, str) or not re.fullmatch(r"[A-Z0-9]{10}", team):
            errors.append("Missing or invalid signing team identifier")
        if app_id != f"{team}.{BUNDLE_ID}":
            errors.append("Signed application identifier does not match HeartPro and its team")
        if values.get("get-task-allow") is not development:
            errors.append("get-task-allow must be " + str(development).lower())
        if not development and values.get("beta-reports-active") is not True:
            errors.append("App Store/TestFlight signing must include beta-reports-active=true")
        if "beta-reports-active" in values and values["beta-reports-active"] is not True:
            errors.append("Invalid beta-reports-active value")
        # Xcode may add the app's default group; sharing with other apps is unused.
        if "keychain-access-groups" in values and values["keychain-access-groups"] != [app_id]:
            errors.append("Unexpected shared Keychain access group")
    return errors


def validate_info(info):
    errors = []
    if info.get("CFBundleIdentifier") != BUNDLE_ID:
        errors.append("Wrong app bundle identifier")
    for key in USAGE_KEYS:
        if not isinstance(info.get(key), str) or not info[key].strip():
            errors.append(f"Missing health purpose string: {key}")
    for key in info:
        if "UsageDescription" in key and key not in USAGE_KEYS:
            errors.append(f"Unused permission purpose string: {key}")
    for key in ("UIBackgroundModes", "BGTaskSchedulerPermittedIdentifiers"):
        if info.get(key):
            errors.append(f"Unused background capability: {key}")
    return errors


def check_source(root=ROOT):
    errors = validate_entitlements(plistlib.loads((root / SOURCE_PATH).read_bytes()))
    files = {p.relative_to(root).as_posix() for p in (root / "HeartPro").rglob("*.entitlements")}
    if files != {SOURCE_PATH}:
        errors.append("Unexpected app entitlement files")
    # Check both the persistent XcodeGen source and the generated project.
    for name in ("project.yml", "HeartPro.xcodeproj/project.pbxproj"):
        text = (root / name).read_text()
        paths = re.findall(r'''CODE_SIGN_ENTITLEMENTS(?:\[[^\]]+\])*["']?\s*[:=]\s*["']?([^\s"';]+)''', text)
        if not paths or any(path != SOURCE_PATH for path in paths):
            errors.append(f"{name}: unexpected CODE_SIGN_ENTITLEMENTS path")
        for key in re.findall(r"INFOPLIST_KEY_(\w*UsageDescription)\b", text):
            if key not in USAGE_KEYS:
                errors.append(f"{name}: unused permission purpose string {key}")
        for key in ("UIBackgroundModes", "BGTaskSchedulerPermittedIdentifiers"):
            if f"INFOPLIST_KEY_{key}" in text:
                errors.append(f"{name}: unused background setting {key}")
    return errors


def command(*args):
    result = subprocess.run(args, capture_output=True, check=False)
    if result.returncode:
        raise ValueError(f"{args[0]} failed: {result.stderr.decode(errors='replace').strip()}")
    return result.stdout


def check_app(app, *, development=False):
    if app.suffix != ".app" or not app.is_dir():
        raise ValueError("--app must point to an existing signed .app bundle")
    command("codesign", "--verify", "--deep", "--strict", str(app))
    values = plistlib.loads(command("codesign", "-d", "--entitlements", ":-", str(app)))
    info = plistlib.loads((app / "Info.plist").read_bytes())
    errors = validate_entitlements(values, signed=True, development=development) + validate_info(info)
    nested = [p for p in app.rglob("*") if p.is_dir() and p.suffix in (".app", ".appex", ".xpc")]
    if nested:
        errors.append("New embedded executable bundles require a separate entitlement audit")
    profile = plistlib.loads(command("security", "cms", "-D", "-i", str(app / "embedded.mobileprovision")))
    permitted = profile.get("Entitlements", {})
    for key, value in values.items():
        expected = permitted.get(key)
        if isinstance(value, str) and isinstance(expected, str):
            matches = fnmatch.fnmatchcase(value, expected)
        elif isinstance(value, list) and isinstance(expected, list):
            matches = all(isinstance(item, str) and any(
                isinstance(pattern, str) and fnmatch.fnmatchcase(item, pattern) for pattern in expected
            ) for item in value)
        else:
            matches = type(value) is type(expected) and value == expected
        if not matches:
            errors.append(f"Provisioning profile does not authorize signed entitlement: {key}")
    # The profile may authorize more capabilities than the binary actually claims.
    # Its full dictionary is not treated as the app's effective entitlements.
    return errors, values, info


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=Path, help="Inspect a signed .app; defaults to App Store/TestFlight rules")
    parser.add_argument("--development", action="store_true", help="Explicitly allow a development-signed archive/app")
    args = parser.parse_args()
    if args.development and not args.app:
        parser.error("--development requires --app")
    try:
        errors = check_source()
        if args.app:
            app_errors, values, info = check_app(args.app, development=args.development)
            errors.extend(app_errors)
            print(f"Inspected {info.get('CFBundleIdentifier')} {info.get('CFBundleShortVersionString')} ({info.get('CFBundleVersion')})")
            print("Signed entitlement keys: " + ", ".join(sorted(values)))
    except (OSError, ValueError, plistlib.InvalidFileException) as error:
        errors = [str(error)]
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print("Entitlement audit passed (" + ("development app" if args.development else "App Store/TestFlight app" if args.app else "source only") + ").")
    return 0


if __name__ == "__main__":
    sys.exit(main())
