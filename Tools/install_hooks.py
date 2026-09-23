#!/usr/bin/env python3
"""Install the versioned HeartPro Git hooks without overwriting native hooks."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


def run(root: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", *args], cwd=root, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    git_dir_result = run(root, "rev-parse", "--git-common-dir")
    if git_dir_result.returncode:
        print("Not a Git worktree.", file=sys.stderr)
        return 2
    git_dir = Path(git_dir_result.stdout.strip())
    if not git_dir.is_absolute():
        git_dir = root / git_dir
    # Include inherited configuration; do not silently shadow a global hook manager.
    configured = run(root, "config", "--get", "core.hooksPath")
    if configured.returncode not in (0, 1):
        print(configured.stderr.strip() or "Unable to inspect core.hooksPath.", file=sys.stderr)
        return 2
    current = configured.stdout.strip() if configured.returncode == 0 else ""
    if current and Path(current).as_posix().rstrip("/") != ".githooks":
        print(f"Existing core.hooksPath={current}; integrate it before installing .githooks.", file=sys.stderr)
        return 2
    if not current:
        for native in (git_dir / "hooks").glob("*"):
            if native.is_file() and not native.name.endswith(".sample") and os.access(native, os.X_OK):
                print(f"Existing native hook {native} was preserved; integrate it before installing .githooks.", file=sys.stderr)
                return 2
    hooks = root / ".githooks"
    expected = [hooks / name for name in ("pre-commit", "commit-msg")]
    if any(not hook.is_file() for hook in expected):
        print("Missing versioned hooks; restore .githooks before installation.", file=sys.stderr)
        return 2
    for hook in expected:
        hook.chmod(hook.stat().st_mode | 0o111)
    if not current:
        configured = run(root, "config", "--local", "core.hooksPath", ".githooks")
        if configured.returncode:
            print(configured.stderr.strip() or "Unable to configure core.hooksPath.", file=sys.stderr)
            return 2
    print("Installed HeartPro hooks at .githooks (native hooks were not overwritten).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
