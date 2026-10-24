#!/usr/bin/env python3
"""Create web previews from captured app PNGs (requires Pillow).

Native originals remain untouched. The provenance file records both hashes.
"""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source', required=True, type=Path, help='Native capture directory containing manifest.json')
parser.add_argument('--output', type=Path, default=ROOT / 'website/static/screenshots')
args = parser.parse_args()
from PIL import Image

source = args.source.resolve()
destination = args.output.resolve()
manifest = json.loads((source / "manifest.json").read_text())
assert manifest["bundle_id"] == "com.alkinum.heartpro"
known = {item["file"]: item for item in manifest["screenshots"]}
selected = [(lang, scene, f"{lang}-{index:02d}-{scene}.png")
            for lang in ("en", "zh-Hans")
            for index, scene in ((1, "history"), (3, "trends"), (4, "waveform"))]
for _, _, name in selected:
    assert hashlib.sha256((source / name).read_bytes()).hexdigest() == known[name]["sha256"], name

destination.mkdir(parents=True, exist_ok=True)
items = []
for lang, scene, name in selected:
    target = destination / f"{lang}-{scene}.webp"
    with Image.open(source / name) as image:
        image.thumbnail((880, 1920), Image.Resampling.LANCZOS)
        image.convert("RGB").save(target, "WEBP", quality=90, method=6)
        dimensions = list(image.size)
    items.append({"file": target.name, "dimensions": dimensions,
                  "sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
                  "source_file": name,
                  "source_sha256": known[name]["sha256"]})
(destination / "provenance.json").write_text(json.dumps({
    "bundle_id": manifest["bundle_id"], "version": manifest["version"],
    "build": manifest["build"],
    "data": manifest["data"], "images": items
}, indent=2) + "\n")
print(f"Prepared {len(items)} website previews from {manifest['version']} ({manifest['build']}).")
