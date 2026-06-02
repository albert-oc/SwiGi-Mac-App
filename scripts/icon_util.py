"""Shared icon processing: remove white matte and trim to colored content."""
from __future__ import annotations

try:
    from PIL import Image
except ImportError:
    Image = None  # type: ignore

# Near-white matte around the artwork (including anti-aliased edges).
WHITE_THRESHOLD = 240


def require_pillow() -> None:
    if Image is None:
        raise SystemExit("error: install Pillow — pip install pillow")


def _is_near_white(r: int, g: int, b: int, a: int) -> bool:
    if a < 16:
        return False
    return r >= WHITE_THRESHOLD and g >= WHITE_THRESHOLD and b >= WHITE_THRESHOLD


def _is_content_pixel(r: int, g: int, b: int, a: int) -> bool:
    if a < 16:
        return False
    if _is_near_white(r, g, b, a):
        return False
    return True


def remove_white_border(img: "Image.Image") -> "Image.Image":
    require_pillow()
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if _is_near_white(r, g, b, a):
                pixels[x, y] = (r, g, b, 0)
    return img


def crop_to_content(img: "Image.Image") -> "Image.Image":
    """Crop to bounding box of non-white, visible pixels."""
    require_pillow()
    pixels = img.load()
    w, h = img.size
    min_x, min_y, max_x, max_y = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if _is_content_pixel(*pixels[x, y]):
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    if max_x < 0:
        bbox = img.getbbox()
        return img if bbox is None else img.crop(bbox)
    return img.crop((min_x, min_y, max_x + 1, max_y + 1))


def trim_transparent(img: "Image.Image") -> "Image.Image":
    require_pillow()
    bbox = img.getbbox()
    if bbox is None:
        return img
    return img.crop(bbox)


def pad_square(img: "Image.Image", size: int) -> "Image.Image":
    require_pillow()
    w, h = img.size
    scale = min(size / w, size / h)
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
    img = crop_to_content(img)
    img = trim_transparent(img)
    return pad_square(img, size)
