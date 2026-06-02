#!/usr/bin/env python3
"""Generate macOS AppIcon.appiconset with transparent edges (no white border)."""
from __future__ import annotations

import sys
from pathlib import Path

from icon_util import prepare_master

try:
    from PIL import Image
except ImportError:
    print("error: install Pillow — pip install pillow", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "SwiGi-icon-1024.png"
ICONSET = ROOT / "SwiGi" / "SwiGi" / "Assets.xcassets" / "AppIcon.appiconset"

SIZES = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

if not SRC.exists():
    print(f"error: missing {SRC}", file=sys.stderr)
    sys.exit(1)

ICONSET.mkdir(parents=True, exist_ok=True)
master = prepare_master(str(SRC), 1024)

for name, size in SIZES:
    out = ICONSET / name
    frame = master.resize((size, size), Image.Resampling.LANCZOS)
    frame.save(out, format="PNG")

print(f"Generated AppIcon set in {ICONSET}")
