#!/usr/bin/env python3
"""Creates clay-tile placeholder PNGs for every word image in words.json.

Usage (from the repo root, needs Pillow):
    python3 tool/generate_placeholders.py            # only fills MISSING files
    python3 tool/generate_placeholders.py --force    # overwrite placeholders too

Real artwork is never overwritten: a file is only replaced when it is missing,
or when --force is given AND the file is itself a placeholder.

Each placeholder carries a PNG text chunk `unscramble-placeholder=1`. The app
detects that marker and draws the word's emoji on top of the clay tile, so the
game is playable before final art lands. Drop real art in with the same
filename and the marker disappears automatically.
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFilter
from PIL.PngImagePlugin import PngInfo

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORDS = os.path.join(ROOT, "assets", "words", "words.json")
MARKER_KEY = "unscramble-placeholder"
SIZE = 256

CATEGORY_COLORS = {
    "Animals": (255, 196, 163),    # peach
    "Food": (255, 214, 107),       # yellow
    "Nature": (125, 226, 197),     # mint
    "Home": (255, 138, 122),       # coral
    "Colors": (201, 182, 255),     # lilac
    "Body": (255, 176, 190),       # pink clay
    "Toys": (126, 200, 255),       # sky
    "Transport": (150, 214, 240),  # light sky
    "Weather": (180, 222, 255),    # pale blue
    "School": (190, 236, 150),     # lime clay
}


def is_placeholder(path):
    try:
        with Image.open(path) as im:
            return im.info.get(MARKER_KEY) == "1"
    except Exception:
        return False


def shade(rgb, f):
    return tuple(max(0, min(255, int(c * f))) for c in rgb)


def make_tile(color):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    pad, radius = 14, 56

    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (pad + 6, pad + 10, SIZE - pad + 4, SIZE - pad + 8), radius,
        fill=shade(color, 0.55) + (150,))
    img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(8)))

    body = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle(
        (pad, pad, SIZE - pad, SIZE - pad), radius, fill=color + (255,))
    img = Image.alpha_composite(img, body)

    # Soft top-left highlight and bottom-right inner shade = clay look.
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    g.ellipse((pad + 10, pad + 6, SIZE * 0.62, SIZE * 0.42), fill=(255, 255, 255, 90))
    g.ellipse((SIZE * 0.45, SIZE * 0.62, SIZE - pad - 6, SIZE - pad - 4),
              fill=shade(color, 0.8) + (110,))
    glow = glow.filter(ImageFilter.GaussianBlur(18))
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((pad, pad, SIZE - pad, SIZE - pad), radius, fill=255)
    img.paste(Image.alpha_composite(img, glow), (0, 0), mask)

    # Inner "picture well" where the app paints the emoji.
    well = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(well).ellipse((58, 58, SIZE - 58, SIZE - 58), fill=(255, 255, 255, 120))
    return Image.alpha_composite(img, well.filter(ImageFilter.GaussianBlur(2)))


def main():
    force = "--force" in sys.argv
    with open(WORDS, encoding="utf-8") as f:
        words = json.load(f)["words"]

    tiles = {}
    created = skipped = 0
    for w in words:
        path = os.path.join(ROOT, w["image"])
        exists = os.path.exists(path)
        if exists and not (force and is_placeholder(path)):
            skipped += 1
            continue
        os.makedirs(os.path.dirname(path), exist_ok=True)
        cat = w["category"]
        if cat not in tiles:
            tiles[cat] = make_tile(CATEGORY_COLORS.get(cat, (220, 220, 220)))
        meta = PngInfo()
        meta.add_text(MARKER_KEY, "1")
        tiles[cat].quantize(64, method=Image.Quantize.FASTOCTREE).save(
            path, pnginfo=meta, optimize=True)
        created += 1
    print(f"placeholders written: {created}, kept existing: {skipped}")


if __name__ == "__main__":
    main()
