#!/usr/bin/env python3
"""Build transparent DXT5 Black Emperor mark and game icon atlases."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

MARK_SIZES = (40, 384, 512, 640, 768)
ICON_SIZES = (22, 30, 32, 38, 50, 64, 70, 80, 95, 200, 256)


def transparent_source(path: Path) -> Image.Image:
    source = Image.open(path).convert("RGB")
    red, green, blue = source.split()
    alpha = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    alpha = alpha.filter(ImageFilter.UnsharpMask(radius=2, percent=160, threshold=3))
    alpha = alpha.point(lambda value: 0 if value < 8 else min(255, value * 2))
    rgba = source.convert("RGBA")
    rgba.putalpha(alpha)
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError("Black Emperor source contains no visible mark")
    cropped = rgba.crop(bounds)
    side = max(cropped.width, cropped.height)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.alpha_composite(
        cropped, ((side - cropped.width) // 2, (side - cropped.height) // 2)
    )
    return square


def render(mark: Image.Image, size: int, coverage: float) -> Image.Image:
    content = max(1, round(size * coverage))
    resized = mark.resize((content, content), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inset = (size - content) // 2
    canvas.alpha_composite(resized, (inset, inset))
    return canvas


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument(
        "--art-dir",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "Art",
    )
    args = parser.parse_args()
    args.art_dir.mkdir(parents=True, exist_ok=True)
    mark = transparent_source(args.source)
    for size in MARK_SIZES:
        coverage = 0.78 if size == 40 else 0.94
        render(mark, size, coverage).save(
            args.art_dir / f"LOTM_BE_BlackEmperorMarkCentered{size}.dds",
            format="DDS",
            pixel_format="DXT5",
        )
    for size in ICON_SIZES:
        coverage = 0.86 if size <= 38 else 0.92
        render(mark, size, coverage).save(
            args.art_dir / f"LOTM_BE_BlackEmperorGameIcon{size}.dds",
            format="DDS",
            pixel_format="DXT5",
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
