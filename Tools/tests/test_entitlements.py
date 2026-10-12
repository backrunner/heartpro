"""Reject accidental capabilities and development signing in release artifacts."""

import plistlib
import shutil
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Tools"))
from check_entitlements import HEALTHKIT, SOURCE_PATH, check_source, validate_entitlements, validate_info


class EntitlementTests(unittest.TestCase):
    def distribution(self):
        return {
            HEALTHKIT: True,
            "application-identifier": "PB8H83VL3Z.com.alkinum.heartpro",
            "com.apple.developer.team-identifier": "PB8H83VL3Z",
            "get-task-allow": False,
            "beta-reports-active": True,
        }

    def test_minimal_source_and_distribution_are_valid(self):
        self.assertEqual([], validate_entitlements({HEALTHKIT: True}))
        self.assertEqual([], validate_entitlements(self.distribution(), signed=True))

    def test_unused_capabilities_fail_even_when_empty_or_false(self):
        for key, value in {
            "com.apple.developer.healthkit.access": [],
            "com.apple.developer.healthkit.background-delivery": False,
            "com.apple.developer.icloud-services": ["CloudKit"],
            "aps-environment": "production",
            "com.apple.security.application-groups": [],
            "com.apple.developer.associated-domains": [],
            "unrecognized.future.entitlement": True,
        }.items():
            for signed in (False, True):
                with self.subTest(key=key, signed=signed):
                    values = self.distribution() if signed else {HEALTHKIT: True}
                    values[key] = value
                    self.assertTrue(validate_entitlements(values, signed=signed))

    def test_development_archive_never_passes_distribution_rules(self):
        values = self.distribution()
        values["get-task-allow"] = True
        del values["beta-reports-active"]
        self.assertTrue(validate_entitlements(values, signed=True))
        self.assertEqual([], validate_entitlements(values, signed=True, development=True))

    def test_healthkit_cannot_be_removed_or_use_non_boolean(self):
        for values in ({}, {HEALTHKIT: False}, {HEALTHKIT: 1}):
            self.assertTrue(validate_entitlements(values))

    def test_identity_and_default_keychain_group(self):
        values = self.distribution()
        values["keychain-access-groups"] = [values["application-identifier"]]
        self.assertEqual([], validate_entitlements(values, signed=True))
        values["keychain-access-groups"].append("PB8H83VL3Z.other-app")
        self.assertTrue(validate_entitlements(values, signed=True))
        values = self.distribution()
        values["application-identifier"] = "PB8H83VL3Z.other-app"
        self.assertTrue(validate_entitlements(values, signed=True))

    def test_signing_values_and_required_testflight_entitlement(self):
        for key, value in (("get-task-allow", 0), ("beta-reports-active", False),
                           ("com.apple.developer.team-identifier", "")):
            values = self.distribution()
            values[key] = value
            self.assertTrue(validate_entitlements(values, signed=True))
        values = self.distribution()
        del values["beta-reports-active"]
        self.assertTrue(validate_entitlements(values, signed=True))

    def test_generated_info_permissions_and_background_modes(self):
        info = {"CFBundleIdentifier": "com.alkinum.heartpro",
                "NSHealthShareUsageDescription": "Read ECGs, heart rate and HRV",
                "NSHealthUpdateUsageDescription": "Save selected symptoms"}
        self.assertEqual([], validate_info(info))
        for key, value in (("NSHealthClinicalHealthRecordsShareUsageDescription", "Read records"),
                           ("NSCameraUsageDescription", "Take photos"),
                           ("UIBackgroundModes", ["fetch"]),
                           ("BGTaskSchedulerPermittedIdentifiers", ["app.refresh"]),
                           ("NSHealthUpdateUsageDescription", "")):
            self.assertTrue(validate_info(dict(info, **{key: value})))


class SourceTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="heartpro-entitlements-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        for name in (SOURCE_PATH, "project.yml", "HeartPro.xcodeproj/project.pbxproj"):
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / name, target)

    def test_actual_configuration(self):
        self.assertEqual([], check_source(self.root))

    def test_real_source_injection_is_rejected(self):
        path = self.root / SOURCE_PATH
        values = plistlib.loads(path.read_bytes())
        values["com.apple.developer.healthkit.access"] = ["health-records"]
        path.write_bytes(plistlib.dumps(values))
        self.assertTrue(check_source(self.root))

    def test_generated_or_persistent_configuration_cannot_switch_entitlement_file(self):
        for name in ("project.yml", "HeartPro.xcodeproj/project.pbxproj"):
            with self.subTest(name=name):
                path = self.root / name
                original = path.read_text()
                path.write_text(original.replace(SOURCE_PATH, "HeartPro/Other.entitlements"))
                self.assertTrue(check_source(self.root))
                path.write_text(original)

    def test_new_entitlement_file_requires_audit(self):
        (self.root / "HeartPro/Other.entitlements").write_bytes(plistlib.dumps({HEALTHKIT: True}))
        self.assertTrue(check_source(self.root))

    def test_conditional_override_cannot_bypass_default_path(self):
        path = self.root / "HeartPro.xcodeproj/project.pbxproj"
        with path.open("a") as output:
            output.write('\n"CODE_SIGN_ENTITLEMENTS[sdk=iphoneos*]" = "HeartPro/Other.entitlements";\n')
        self.assertTrue(check_source(self.root))


if __name__ == "__main__":
    unittest.main()
