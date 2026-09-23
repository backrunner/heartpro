#!/usr/bin/env python3
"""Repository guard for HeartPro staged files and Conventional Commits."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


COMMIT_TYPES = {
    "feat",
    "fix",
    "docs",
    "style",
    "refactor",
    "perf",
    "test",
    "build",
    "ci",
    "chore",
    "revert",
}
HEADER = re.compile(
    r"^(?P<type>[a-z]+)(?:\((?P<scope>[a-z0-9](?:[a-z0-9./-]*[a-z0-9])?)\))?"
    r"(?P<breaking>!)?: (?P<description>\S.*)$"
)
# Exempt only the history that predates adoption, including on new branches.
LEGACY_BASELINE = "534d6831feb8c63ab6b5f213675d455747bc622b"
SENSITIVE_NAME = re.compile(
    r"(?:^|/)(?:\.env(?:\..*)?|.*\.(?:p8|p12|pfx|mobileprovision|provisionprofile)|"
    r"id_(?:rsa|ed25519))$",
    re.IGNORECASE,
)
SECRET_CONTENT = [
    re.compile(r"-----BEGIN (?:[A-Z0-9]+ )?PRIVATE KEY-----"),
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(r"\b(?:gh[pousr]|github_pat)_[A-Za-z0-9_]{20,}\b"),
    re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{20,}\b"),
    re.compile(
        r"(?i)\b(?:api[_-]?key|client[_-]?secret|access[_-]?token|refresh[_-]?token|"
        r"private[_-]?key|password)\b[\"']?\s*[:=]\s*[\"']?[A-Za-z0-9_./+=-]{20,}"
    ),
]


def git(root: Path, *args: str, input_text: str | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=root,
        input=input_text,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )


def staged_paths(root: Path) -> list[str]:
    result = git(root, "diff", "--cached", "--name-only", "--diff-filter=ACMRTUXB", "-z")
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "git diff --cached failed")
    return [path for path in result.stdout.split("\0") if path]


def tracked_paths(root: Path) -> list[str]:
    result = git(root, "ls-files", "-z")
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "git ls-files failed")
    return [path for path in result.stdout.split("\0") if path]


def staged_content(root: Path, path: str) -> bytes:
    result = subprocess.run(
        ["git", "show", f":{path}"],
        cwd=root,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode:
        raise RuntimeError(result.stderr.decode(errors="replace").strip() or f"cannot read staged file: {path}")
    return result.stdout


def ignored_paths(root: Path, paths: list[str]) -> list[str]:
    if not paths:
        return []
    result = git(root, "check-ignore", "--no-index", "-z", "--stdin", input_text="\0".join(paths) + "\0")
    if result.returncode not in (0, 1):
        raise RuntimeError(result.stderr.strip() or "git check-ignore failed")
    return [path for path in result.stdout.split("\0") if path]


def check_ignore_rules(root: Path) -> list[str]:
    """Git reads worktree ignore rules, so reject rules that differ from the index."""
    errors = []
    for args in (
        ("diff", "--name-only", "-z", "--", ".gitignore", "**/.gitignore"),
        ("ls-files", "--others", "--exclude-standard", "-z", "--", ".gitignore", "**/.gitignore"),
    ):
        result = git(root, *args)
        if result.returncode:
            raise RuntimeError(result.stderr.strip() or "cannot inspect ignore rules")
        errors.extend(f"stage the intended ignore rules before checking: {path}" for path in result.stdout.split("\0") if path)
    return errors


def content_errors(path: str, data: bytes) -> list[str]:
    errors: list[str] = []
    if SENSITIVE_NAME.search(path) and Path(path).name != ".env.example":
        errors.append(f"local configuration or signing material must not be tracked: {path}")
    if b"\x00" in data or not data:
        return errors
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        return errors
    for pattern in SECRET_CONTENT:
        if pattern.search(text):
            errors.append(f"possible credential material in indexed file: {path}")
            break
    return errors


def check_staged(root: Path) -> list[str]:
    errors = check_ignore_rules(root)
    paths = staged_paths(root)
    diff_check = git(root, "diff", "--cached", "--check")
    if diff_check.returncode:
        # Git includes offending lines; they may contain a secret we also reject.
        errors.append("staged whitespace check failed; inspect git diff --cached --check locally")
    # A new ignore rule may accidentally hide an already tracked, unchanged file.
    errors.extend(f"indexed path is ignored by active Git rules: {path}" for path in ignored_paths(root, tracked_paths(root)))
    for path in paths:
        try:
            errors.extend(content_errors(path, staged_content(root, path)))
        except RuntimeError as error:
            errors.append(str(error))
    return errors


def check_tracked(root: Path) -> list[str]:
    errors = check_ignore_rules(root)
    paths = tracked_paths(root)
    errors.extend(f"indexed path is ignored by active Git rules: {path}" for path in ignored_paths(root, paths))
    for path in paths:
        # Inspect the index, including symlink text, never a symlink's external target.
        errors.extend(content_errors(path, staged_content(root, path)))
    return errors


def validate_message_text(message: str, *, allow_merge: bool = False) -> list[str]:
    lines = message.strip("\r\n").splitlines()
    if not lines or not lines[0].strip():
        return ["commit message is empty"]
    title = lines[0]
    if allow_merge and title.startswith("Merge "):
        return []
    match = HEADER.fullmatch(title)
    if not match:
        return ["commit title must use Conventional Commits: type(scope): description"]
    if match.group("type") not in COMMIT_TYPES:
        return [f"unsupported commit type: {match.group('type')}"]
    if len(title) > 100:
        return [f"commit title is {len(title)} characters; maximum is 100"]
    description = match.group("description")
    if description.endswith((".", "。")):
        return ["commit title description must not end with a period"]
    if title != title.rstrip() or any(ord(char) < 32 for char in title):
        return ["commit title must not contain control characters or trailing whitespace"]
    if len(lines) > 1 and lines[1].strip():
        return ["separate the commit title and body with a blank line"]
    footers = [line for line in lines[2:] if line.startswith("BREAKING CHANGE:")]
    if match.group("breaking") and not footers:
        return ["a breaking title (!) requires a BREAKING CHANGE: explanation"]
    if any(not line.removeprefix("BREAKING CHANGE:").strip() for line in footers):
        return ["BREAKING CHANGE: must explain the impact and migration"]
    return []


def check_message(root: Path, path: Path, *, hook: bool = False) -> list[str]:
    message = path.read_text(encoding="utf-8")
    allow_merge = False
    if hook:
        # Honor Git's configured comment character for editor-generated templates.
        cleaned = git(root, "stripspace", "--strip-comments", input_text=message)
        if cleaned.returncode:
            raise RuntimeError(cleaned.stderr.strip() or "cannot clean commit message")
        message = cleaned.stdout
        allow_merge = git(root, "rev-parse", "--verify", "-q", "MERGE_HEAD").returncode == 0
    return validate_message_text(message, allow_merge=allow_merge)


def check_commit_range(root: Path, revision_range: str) -> list[str]:
    exclusions = []
    if git(root, "cat-file", "-e", f"{LEGACY_BASELINE}^{{commit}}").returncode == 0:
        exclusions.append(f"^{LEGACY_BASELINE}")
    result = git(root, "rev-list", "--reverse", "--end-of-options", revision_range, *exclusions)
    if result.returncode:
        return [result.stderr.strip() or f"invalid revision range: {revision_range}"]
    errors: list[str] = []
    for sha in [item for item in result.stdout.splitlines() if item]:
        parents = git(root, "rev-list", "--parents", "-n", "1", sha)
        message = git(root, "show", "-s", "--format=%B", sha)
        if parents.returncode or message.returncode:
            raise RuntimeError(f"cannot inspect commit {sha}")
        for error in validate_message_text(message.stdout, allow_merge=len(parents.stdout.split()) > 2):
            errors.append(f"{sha[:12]}: {error}")
    return errors


def emit(errors: list[str]) -> int:
    if errors:
        print("HeartPro guard failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("HeartPro guard passed.")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("staged", help="check staged paths and whitespace")
    subparsers.add_parser("tracked", help="check all tracked paths")
    message = subparsers.add_parser("message", help="check one commit message")
    message.add_argument("--file", required=True, type=Path)
    message.add_argument("--hook", action="store_true", help="clean Git comments and detect an active merge")
    commits = subparsers.add_parser("commits", help="check messages in a revision range")
    commits.add_argument("--range", required=True, dest="revision_range")
    args = parser.parse_args(argv)
    root = Path(__file__).resolve().parents[1]
    try:
        if args.command == "staged":
            return emit(check_staged(root))
        if args.command == "tracked":
            return emit(check_tracked(root))
        if args.command == "message":
            return emit(check_message(root, args.file, hook=args.hook))
        return emit(check_commit_range(root, args.revision_range))
    except (RuntimeError, OSError, UnicodeError) as error:
        return emit([str(error)])


if __name__ == "__main__":
    raise SystemExit(main())
