"""Exercise the guard through real Git indexes, commits, and installed hooks."""

import importlib.util
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("heartpro_guard", ROOT / "Tools/guard.py")
guard = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(guard)


class MessageTests(unittest.TestCase):
    def test_valid_messages(self):
        messages = [
            "feat(ui): add the usage notice",
            "docs(appstore): 完善六语审核材料",
            "fix: preserve missing measurements\n\nTested with incomplete recordings.\n",
            "fix(core)!: change result schema\n\nBREAKING CHANGE: migrate stored results",
            "feat(core): revise result schema\n\nBREAKING CHANGE: regenerate cached results",
            "feat: " + "a" * 94,
        ]
        for message in messages:
            with self.subTest(message=message):
                self.assertEqual([], guard.validate_message_text(message))

    def test_invalid_messages(self):
        messages = [
            "", "# no title", "Prepare a release", "wip: work", "fixup! fix: work",
            "feat(UI): add notice", "fix(core/): change schema", "fix:  extra space",
            "fix: ", "fix: trim.", "fix: 修正。", "fix: trailing ", "fix: tab\tvalue",
            "fix: title\nbody with no separator", "feat: " + "a" * 95,
            "fix(core)!: change schema", "fix(core)!: change schema\n\nBREAKING CHANGE: ",
            "Merge branch 'main' into feature",
        ]
        for message in messages:
            with self.subTest(message=message):
                self.assertTrue(guard.validate_message_text(message))


class RepositoryTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="heartpro-guard-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
        self.env.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1", GIT_TERMINAL_PROMPT="0")
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "test@example.com")
        self.git("config", "user.name", "HeartPro Test")
        (self.root / "Tools").mkdir()
        for name in ("guard.py", "install_hooks.py"):
            shutil.copy2(ROOT / "Tools" / name, self.root / "Tools" / name)
        shutil.copytree(ROOT / ".githooks", self.root / ".githooks")
        self.write(".gitignore", "__pycache__/\nbuild/\n.env\n.env.*\n!.env.example\n")
        self.git("add", ".")

    def run_command(self, *args, check=True):
        result = subprocess.run(args, cwd=self.root, env=self.env, capture_output=True, text=True)
        if check:
            self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        return result

    def git(self, *args, check=True):
        return self.run_command("git", *args, check=check)

    def guard(self, *args, check=True):
        return self.run_command(sys.executable, "Tools/guard.py", *args, check=check)

    def install(self, check=True):
        return self.run_command(sys.executable, "Tools/install_hooks.py", check=check)

    def write(self, name, text):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return path

    def commit(self, message="chore: initialize fixture"):
        self.git("commit", "-qm", message)
        return self.git("rev-parse", "HEAD").stdout.strip()

    def test_hooks_accept_valid_and_reject_invalid_messages(self):
        self.install()
        self.install()
        self.assertEqual(".githooks", self.git("config", "--local", "--get", "core.hooksPath").stdout.strip())
        failed = self.git("commit", "-qm", "bad title", check=False)
        self.assertNotEqual(0, failed.returncode)
        self.assertNotEqual(0, self.git("rev-parse", "--verify", "HEAD", check=False).returncode)
        self.commit("chore(guard): enable hooks")

    def test_precommit_rejects_force_added_ignored_artifact(self):
        self.install()
        self.write("build/generated output.txt", "temporary\n")
        self.git("add", "-f", "build/generated output.txt")
        result = self.git("commit", "-qm", "build: add output", check=False)
        self.assertNotEqual(0, result.returncode)
        self.assertIn("build/generated output.txt", result.stderr)

    def test_new_ignore_rule_catches_unchanged_tracked_file(self):
        self.write("artifact.bin", "ordinary\n")
        self.git("add", "artifact.bin")
        self.commit()
        with (self.root / ".gitignore").open("a") as output:
            output.write("artifact.bin\n")
        self.git("add", ".gitignore")
        self.assertNotEqual(0, self.guard("staged", check=False).returncode)
        self.git("rm", "--cached", "artifact.bin")
        self.guard("staged")

    def test_unstaged_ignore_rule_cannot_hide_staged_violation(self):
        self.write("build/output", "temporary\n")
        self.git("add", "-f", "build/output")
        self.write(".gitignore", "__pycache__/\n")
        self.assertNotEqual(0, self.guard("staged", check=False).returncode)

    def test_whitespace_failure_is_rejected(self):
        self.write("code.txt", "trailing space \n")
        self.git("add", "code.txt")
        self.assertNotEqual(0, self.guard("staged", check=False).returncode)

    def test_scans_index_not_unstaged_redaction_and_redacts_output(self):
        secret = "github" + "_pat_" + "a" * 40
        self.write("capture.log", secret + " \n")
        self.git("add", "capture.log")
        self.write("capture.log", "redacted\n")
        for mode in ("staged", "tracked"):
            result = self.guard(mode, check=False)
            self.assertNotEqual(0, result.returncode)
            self.assertIn("capture.log", result.stderr)
            self.assertNotIn(secret, result.stdout + result.stderr)

    def test_assets_templates_and_credentials_documentation_are_allowed(self):
        self.write("config/.env.example", "TOKEN=\n")
        self.write("docs/credentials.md", "Use the existing credential store.\n")
        self.write("image with\nnewline.png", "\x00\u00ff")
        self.git("add", ".")
        self.guard("staged")
        self.guard("tracked")

    def test_symlinks_are_checked_without_reading_their_target(self):
        with tempfile.TemporaryDirectory() as external:
            target = Path(external) / "private.txt"
            target.write_text("github" + "_pat_" + "b" * 40)
            (self.root / "reference.txt").symlink_to(target)
            self.git("add", "reference.txt")
            self.guard("tracked")

    def test_merge_titles_only_allowed_for_actual_merges(self):
        self.install()
        self.commit()
        base = self.git("rev-parse", "HEAD").stdout.strip()
        self.git("checkout", "-qb", "feature")
        self.write("feature.txt", "feature\n")
        self.git("add", "feature.txt")
        self.commit("feat: add a feature")
        self.git("checkout", "-q", "main")
        self.git("merge", "--no-ff", "--no-edit", "feature")
        self.guard("commits", "--range", f"{base}..HEAD")
        failed = self.git("commit", "--allow-empty", "-qm", "Merge fake", check=False)
        self.assertNotEqual(0, failed.returncode)

    def test_ci_catches_earlier_invalid_commit_even_when_tip_is_valid(self):
        base = self.commit()
        self.git("commit", "--allow-empty", "-qm", "bad title")
        bad = self.git("rev-parse", "HEAD").stdout.strip()[:12]
        self.git("commit", "--allow-empty", "-qm", "docs: describe behavior")
        for revision in ("HEAD", f"{base}..HEAD"):
            result = self.guard("commits", "--range", revision, check=False)
            self.assertNotEqual(0, result.returncode)
            self.assertIn(bad, result.stderr)
        self.guard("commits", "--range", "HEAD^..HEAD")
        self.assertNotEqual(0, self.guard("commits", "--range", "missing..HEAD", check=False).returncode)

    def test_editor_comments_use_configured_git_character(self):
        self.git("config", "core.commentChar", ";")
        path = self.write("message.txt", "; comment\nfix(ui): show status\n\n; staged list\n")
        self.guard("message", "--file", str(path), "--hook")
        self.assertNotEqual(0, self.guard("message", "--file", "missing.txt", check=False).returncode)

    def test_installer_preserves_local_and_global_custom_hook_paths(self):
        self.git("config", "core.hooksPath", "local-hooks")
        self.assertNotEqual(0, self.install(check=False).returncode)
        self.assertEqual("local-hooks", self.git("config", "core.hooksPath").stdout.strip())
        self.git("config", "--unset", "core.hooksPath")
        config = self.write("global-test-config", "[core]\n\thooksPath = global-hooks\n")
        self.env["GIT_CONFIG_GLOBAL"] = str(config)
        self.assertNotEqual(0, self.install(check=False).returncode)
        self.assertEqual("global-hooks", self.git("config", "core.hooksPath").stdout.strip())

    def test_installer_preserves_other_executable_native_hooks(self):
        hook = self.write(".git/hooks/pre-push", "#!/bin/sh\nexit 0\n")
        hook.chmod(0o755)
        self.assertNotEqual(0, self.install(check=False).returncode)
        self.assertNotEqual(0, self.git("config", "--local", "--get", "core.hooksPath", check=False).returncode)
        self.assertEqual("#!/bin/sh\nexit 0\n", hook.read_text())


if __name__ == "__main__":
    unittest.main()
