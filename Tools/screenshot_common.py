"""Shared provenance for captures of the native app."""
from pathlib import Path
import hashlib


def app_source_fingerprint(root: Path) -> str:
    paths = [root / 'project.yml']
    for directory in ['HeartPro', 'Packages/HeartProCore/Sources']:
        paths.extend(path for path in (root / directory).rglob('*') if path.is_file())
    digest = hashlib.sha256()
    for path in sorted(paths):
        digest.update(path.relative_to(root).as_posix().encode('utf-8') + b'\0')
        digest.update(path.read_bytes())
        digest.update(b'\0')
    return digest.hexdigest()
