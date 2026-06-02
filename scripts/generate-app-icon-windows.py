#!/usr/bin/env python3
"""Generate app.ico for SwiGi.Win from assets/SwiGi-icon-1024.png."""
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
ICO = ROOT / "SwiGi.Win" / "SwiGi.Win" / "app.ico"
SIZES = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]

if not SRC.exists():
    print(f"error: missing {SRC}", file=sys.stderr)
    sys.exit(1)

master = prepare_master(str(SRC), 256)
master.save(ICO, format="ICO", sizes=SIZES)
print(f"Generated {ICO} ({ICO.stat().st_size} bytes)")
