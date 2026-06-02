#!/usr/bin/env python3
"""Generate app.ico for SwiGi.Win from assets/SwiGi-icon-1024.png."""
from __future__ import annotations

import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("error: install Pillow — pip install pillow", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "SwiGi-icon-1024.png"
ICO = ROOT / "SwiGi.Win" / "SwiGi.Win" / "app.ico"
SIZES = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]

# Pixels brighter than this become fully transparent (removes white matte/borders).
WHITE_THRESHOLD = 248


def remove_white_border(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            if r >= WHITE_THRESHOLD and g >= WHITE_THRESHOLD and b >= WHITE_THRESHOLD:
                pixels[x, y] = (r, g, b, 0)
    return img


def trim_transparent(img: Image.Image) -> Image.Image:
    bbox = img.getbbox()
    if bbox is None:
        return img
    return img.crop(bbox)


def pad_square(img: Image.Image, size: int) -> Image.Image:
    w, h = img.size
    scale = min(size / w, size / h) * 0.92
    nw, nh = max(1, int(w * scale)), max(1, int(h * scale))
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ox = (size - nw) // 2
    oy = (size - nh) // 2
    canvas.paste(resized, (ox, oy), resized)
    return canvas


if not SRC.exists():
    print(f"error: missing {SRC}", file=sys.stderr)
    sys.exit(1)

img = Image.open(SRC).convert("RGBA")
img = remove_white_border(img)
img = trim_transparent(img)

# Master square asset for ICO (largest size).
master = pad_square(img, 256)
master.save(ICO, format="ICO", sizes=SIZES)
print(f"Generated {ICO} ({ICO.stat().st_size} bytes)")
