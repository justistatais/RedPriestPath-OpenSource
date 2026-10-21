#!/usr/bin/env python3
"""Build one-cell DXT5 project/unit/portrait atlases for both pathways."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter


ICON_SIZES = (22, 30, 32, 38, 50, 64, 70, 80, 95, 200, 256)


def transparent_mark(
    source_path: Path,
    color: tuple[int, int, int] | None,
    threshold: int = 0,
) -> Image.Image:
    source = Image.open(source_path).convert("RGB")
    red, green, blue = source.split()
    alpha = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    alpha = alpha.filter(ImageFilter.UnsharpMask(radius=2, percent=180, threshold=4))
    if threshold > 0:
        alpha = alpha.point(
            lambda value: max(0, min(255, (value - threshold) * 10))
        )
    else:
        alpha = alpha.point(lambda value: 0 if value < 10 else value)
    if color is None:
        rgba = source.convert("RGBA")
    else:
        rgba = Image.new("RGBA", source.size, (*color, 255))
    rgba.putalpha(alpha)

    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError(f"source contains no visible mark: {source_path}")
    cropped = rgba.crop(bounds)
    side = max(cropped.width, cropped.height)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.alpha_composite(
        cropped,
        ((side - cropped.width) // 2, (side - cropped.height) // 2),
    )
    return square


def render_icon(mark: Image.Image, size: int) -> Image.Image:
    # Retain an even margin so Civ VI's circular portrait masks and city-banner
    # frames do not clip the outer ring or glow.
    coverage = 0.88 if size <= 38 else 0.92
    content_size = max(1, round(size * coverage))
    resized = mark.resize((content_size, content_size), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inset = (size - content_size) // 2
    canvas.alpha_composite(resized, (inset, inset))
    return canvas


def build_set(mark: Image.Image, art_dir: Path, prefix: str) -> None:
    for size in ICON_SIZES:
        render_icon(mark, size).save(
            art_dir / f"{prefix}GameIcon{size}.dds",
            format="DDS",
            pixel_format="DXT5",
        )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--red-source", type=Path, required=True)
    parser.add_argument("--perfect-source", type=Path, required=True)
    parser.add_argument(
        "--art-dir",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "Art",
    )
    args = parser.parse_args()
    args.art_dir.mkdir(parents=True, exist_ok=True)

    red = transparent_mark(args.red_source, None)
    perfect = transparent_mark(args.perfect_source, (255, 184, 0), threshold=205)
    build_set(red, args.art_dir, "LOTM_RP_RedPriest")
    build_set(perfect, args.art_dir, "LOTM_PP_Perfect")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
