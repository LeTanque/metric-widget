#!/usr/bin/env python3
"""Generate Matrix-themed app icon from gauge source image."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(
    "/Users/frank.martinez/.cursor/projects/Users-frank-martinez-git-MetricsWidget/assets/"
    "istockphoto-1144415426-612x612-fe332761-e0cc-44f5-8088-cf58131deb66.jpg"
)
ICONSET = ROOT / "MetricsWidget/Assets.xcassets/AppIcon.appiconset"

# Matches Theme.swift matrix palette (sRGB 0–255)
BG_TOP = (2, 8, 4)
BG_BOTTOM = (0, 0, 0)
ACCENT = (89, 255, 71)  # 0.35, 1.0, 0.28
PRIMARY = (140, 255, 115)  # 0.55, 1.0, 0.45
GLOW = (35, 200, 55)
GRID = (8, 42, 14, 90)


def luminance(rgb: tuple[int, int, int]) -> float:
    r, g, b = rgb
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def extract_gauge_alpha(source: Image.Image) -> Image.Image:
    rgb = source.convert("RGB")
    w, h = rgb.size
    alpha = Image.new("L", (w, h), 0)
    px = rgb.load()
    apx = alpha.load()
    for y in range(h):
        for x in range(w):
            if luminance(px[x, y]) < 210:
                apx[x, y] = 255
    return alpha


def matrix_background(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size))
    draw = ImageDraw.Draw(img)
    for y in range(size):
        t = y / max(size - 1, 1)
        r = int(BG_TOP[0] * (1 - t) + BG_BOTTOM[0] * t)
        g = int(BG_TOP[1] * (1 - t) + BG_BOTTOM[1] * t)
        b = int(BG_TOP[2] * (1 - t) + BG_BOTTOM[2] * t)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

    grid = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(grid)
    step = max(size // 32, 8)
    for x in range(0, size, step):
        gdraw.line([(x, 0), (x, size)], fill=GRID, width=1)
    for y in range(0, size, step):
        gdraw.line([(0, y), (size, y)], fill=GRID, width=1)
    img = Image.alpha_composite(img, grid)

    vignette = Image.new("L", (size, size), 0)
    vdraw = ImageDraw.Draw(vignette)
    margin = size * 0.08
    vdraw.ellipse(
        (margin, margin, size - margin, size - margin),
        fill=255,
    )
    vignette = vignette.filter(ImageFilter.GaussianBlur(radius=size * 0.18))
    dark = Image.new("RGBA", (size, size), (0, 0, 0, 180))
    img = Image.composite(img, dark, ImageChops.invert(vignette))
    return img


def tint_gauge(alpha: Image.Image, size: int) -> Image.Image:
    gauge_w = int(size * 0.62)
    alpha_resized = alpha.resize((gauge_w, gauge_w), Image.Resampling.LANCZOS)

    colored = Image.new("RGBA", (gauge_w, gauge_w), ACCENT + (255,))
    colored.putalpha(alpha_resized)

    glow_layer = Image.new("RGBA", (gauge_w, gauge_w), GLOW + (255,))
    glow_layer.putalpha(alpha_resized.filter(ImageFilter.GaussianBlur(radius=max(2, size // 128))))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=max(3, size // 64)))

    highlight = Image.new("RGBA", (gauge_w, gauge_w), PRIMARY + (255,))
    highlight.putalpha(alpha_resized.filter(ImageFilter.MinFilter(3)))

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx = (size - gauge_w) // 2
    cy = (size - gauge_w) // 2 + int(size * 0.02)

    for layer, opacity in ((glow_layer, 255), (colored, 255), (highlight, 140)):
        if opacity < 255:
            layer = layer.copy()
            r, g, b, a = layer.split()
            a = a.point(lambda p: p * opacity // 255)
            layer = Image.merge("RGBA", (r, g, b, a))
        canvas.alpha_composite(layer, (cx, cy))

    return canvas


def compose_icon(size: int, gauge_alpha: Image.Image) -> Image.Image:
    bg = matrix_background(size)
    fg = tint_gauge(gauge_alpha, size)
    bg.alpha_composite(fg)
    return bg.convert("RGBA")


def main() -> None:
    if not SOURCE.is_file():
        raise SystemExit(f"Source image not found: {SOURCE}")

    source = Image.open(SOURCE)
    gauge_alpha = extract_gauge_alpha(source)

    master_size = 1024
    master = compose_icon(master_size, gauge_alpha)

    exports: list[tuple[str, int, str]] = [
        ("icon_16x16.png", 16, "16x16"),
        ("icon_16x16@2x.png", 32, "16x16"),
        ("icon_32x32.png", 32, "32x32"),
        ("icon_32x32@2x.png", 64, "32x32"),
        ("icon_128x128.png", 128, "128x128"),
        ("icon_128x128@2x.png", 256, "128x128"),
        ("icon_256x256.png", 256, "256x256"),
        ("icon_256x256@2x.png", 512, "256x256"),
        ("icon_512x512.png", 512, "512x512"),
        ("icon_512x512@2x.png", 1024, "512x512"),
    ]

    ICONSET.mkdir(parents=True, exist_ok=True)
    for filename, px, _ in exports:
        out = ICONSET / filename
        icon = master if px == master_size else master.resize((px, px), Image.Resampling.LANCZOS)
        icon.save(out, format="PNG", optimize=True)

    contents = {
        "images": [
            {"filename": "icon_16x16.png", "idiom": "mac", "scale": "1x", "size": "16x16"},
            {"filename": "icon_16x16@2x.png", "idiom": "mac", "scale": "2x", "size": "16x16"},
            {"filename": "icon_32x32.png", "idiom": "mac", "scale": "1x", "size": "32x32"},
            {"filename": "icon_32x32@2x.png", "idiom": "mac", "scale": "2x", "size": "32x32"},
            {"filename": "icon_128x128.png", "idiom": "mac", "scale": "1x", "size": "128x128"},
            {"filename": "icon_128x128@2x.png", "idiom": "mac", "scale": "2x", "size": "128x128"},
            {"filename": "icon_256x256.png", "idiom": "mac", "scale": "1x", "size": "256x256"},
            {"filename": "icon_256x256@2x.png", "idiom": "mac", "scale": "2x", "size": "256x256"},
            {"filename": "icon_512x512.png", "idiom": "mac", "scale": "1x", "size": "512x512"},
            {"filename": "icon_512x512@2x.png", "idiom": "mac", "scale": "2x", "size": "512x512"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (ICONSET / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(exports)} icons to {ICONSET}")


if __name__ == "__main__":
    main()
