"""Shared icon processing: remove white matte and trim transparent edges."""
from __future__ import annotations

try:
    from PIL import Image
except ImportError:
    Image = None  # type: ignore

WHITE_THRESHOLD = 248


def require_pillow() -> None:
    if Image is None:
        raise SystemExit("error: install Pillow — pip install pillow")


def remove_white_border(img: "Image.Image") -> "Image.Image":
    require_pillow()
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


def trim_transparent(img: "Image.Image") -> "Image.Image":
    require_pillow()
    bbox = img.getbbox()
    if bbox is None:
        return img
    return img.crop(bbox)


def pad_square(img: "Image.Image", size: int) -> "Image.Image":
    require_pillow()
    w, h = img.size
    scale = min(size / w, size / h) * 0.92
    nw, nh = max(1, int(w * scale)), max(1, int(h * scale))
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ox = (size - nw) // 2
    oy = (size - nh) // 2
    canvas.paste(resized, (ox, oy), resized)
    return canvas


def prepare_master(src_path: str, size: int = 1024) -> "Image.Image":
    require_pillow()
    img = Image.open(src_path).convert("RGBA")
    img = remove_white_border(img)
    img = trim_transparent(img)
    return pad_square(img, size)
