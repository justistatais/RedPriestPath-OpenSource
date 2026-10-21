#!/usr/bin/env python3
"""Build transparent one-cell DDS atlases for the Thief pathway."""

from __future__ import annotations

import argparse
from pathlib import Path
from PIL import Image

GAME_SIZES = (22, 30, 32, 38, 50, 64, 70, 80, 95, 200, 256)
MARK_SIZES = (40, 384, 512, 640, 768)
COIN_SIZES = (22, 30, 32, 38, 50, 64, 80, 128, 256)


def normalized(path: Path, remove_checker: bool = False) -> Image.Image:
    source = Image.open(path)
    image = source.convert("RGBA")
    if remove_checker and "A" not in source.getbands():
        pixels = source.convert("RGB").getdata()
        alpha = Image.new("L", source.size)
        alpha.putdata([
            0 if max(rgb) - min(rgb) <= 10 and 180 <= sum(rgb) // 3 <= 250 else 255
            for rgb in pixels
        ])
        image.putalpha(alpha)
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError(f"no visible pixels in {path}")
    crop = image.crop(bounds)
    side = max(crop.size)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.alpha_composite(crop, ((side - crop.width) // 2, (side - crop.height) // 2))
    return square


def save(image: Image.Image, size: int, path: Path, coverage: float) -> None:
    content = max(1, round(size * coverage))
    resized = image.resize((content, content), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((size - content) // 2, (size - content) // 2))
    canvas.save(path, format="DDS", pixel_format="DXT5")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--path-source", type=Path, required=True)
    parser.add_argument("--coin-source", type=Path, required=True)
    parser.add_argument("--art-dir", type=Path, required=True)
    parser.add_argument("--clean-coin-output", type=Path)
    args = parser.parse_args()
    args.art_dir.mkdir(parents=True, exist_ok=True)
    mark, coin = normalized(args.path_source), normalized(args.coin_source, True)
    if args.clean_coin_output is not None:
        args.clean_coin_output.parent.mkdir(parents=True, exist_ok=True)
        coin.save(args.clean_coin_output)
    for size in GAME_SIZES:
        save(mark, size, args.art_dir / f"LOTM_TP_ThiefGameIcon{size}.dds", 0.91)
    for size in MARK_SIZES:
        save(mark, size, args.art_dir / f"LOTM_TP_ThiefMarkCentered{size}.dds", 0.92)
    for size in COIN_SIZES:
        save(coin, size, args.art_dir / f"LOTM_TP_FakeGoldIcon{size}.dds", 0.90)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
