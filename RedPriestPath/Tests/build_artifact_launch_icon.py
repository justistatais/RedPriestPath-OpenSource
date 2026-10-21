#!/usr/bin/env python3
"""Build deterministic one-cell DDS atlases for the artifact launch button."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


ICON_SIZES = (40, 64, 256)


def render(source: Image.Image, size: int) -> Image.Image:
    # Firaxis LaunchBar buttons provide the outer 49px frame. Keep a visible
    # margin inside the 40px icon control and remove the source's square corners.
    content_size = max(1, round(size * 0.90))
    resized = source.resize((content_size, content_size), Image.Resampling.LANCZOS)
    scale = 4
    mask_large = Image.new("L", (content_size * scale, content_size * scale), 0)
    draw = ImageDraw.Draw(mask_large)
    draw.ellipse(
        (1 * scale, 1 * scale, content_size * scale - 1, content_size * scale - 1),
        fill=255,
    )
    mask = mask_large.resize((content_size, content_size), Image.Resampling.LANCZOS)
    resized.putalpha(mask)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(
        resized,
        ((size - content_size) // 2, (size - content_size) // 2),
    )
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

    source = Image.open(args.source).convert("RGBA")
    side = min(source.size)
    left = (source.width - side) // 2
    top = (source.height - side) // 2
    square = source.crop((left, top, left + side, top + side))
    for size in ICON_SIZES:
        render(square, size).save(
            args.art_dir / f"LOTM_ArtifactLaunchIcon{size}.dds",
            format="DDS",
            pixel_format="DXT5",
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
