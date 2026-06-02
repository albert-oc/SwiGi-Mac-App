#!/usr/bin/env python3
"""Rewrite assets/SwiGi-icon-1024.png as a trimmed 1024×1024 square master."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

from icon_util import prepare_master  # noqa: E402

SRC = ROOT / "assets" / "SwiGi-icon-1024.png"

if __name__ == "__main__":
    if not SRC.exists():
        print(f"error: missing {SRC}", file=sys.stderr)
        sys.exit(1)
    master = prepare_master(str(SRC), 1024)
    master.save(SRC, format="PNG")
    print(f"Normalized {SRC} to {master.size[0]}×{master.size[1]}")
