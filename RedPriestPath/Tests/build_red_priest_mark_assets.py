#!/usr/bin/env python3
"""Build centered DXT5 Red Priest mark textures from the user-provided PNG."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops


CEREMONY_SIZES = (384, 512, 640, 768)


def make_transparent_source(source_path: Path) -> Image.Image:
    source = Image.open(source_path).convert("RGB")
    red, green, blue = source.split()
    alpha = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    rgba = source.convert("RGBA")
    rgba.putalpha(alpha)
    return rgba


def centered_texture(source: Image.Image, size: int, coverage: float) -> Image.Image:
    content_size = round(size * coverage)
    resized = source.resize((content_size, content_size), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inset = (size - content_size) // 2
    canvas.alpha_composite(resized, (inset, inset))
    return canvas


def save_dxt5(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="DDS", pixel_format="DXT5")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument(
        "--art-dir",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "Art",
    )
    args = parser.parse_args()

    source = make_transparent_source(args.source)
    # The LaunchBar control remains 40 px so the engine never crops the atlas.
    # The mark itself occupies 80%, producing the requested smaller inner glyph.
    save_dxt5(
        centered_texture(source, 40, 0.80),
        args.art_dir / "LOTM_RP_RedPriestMarkCentered40.dds",
    )
    # Ceremony controls always match one of these atlas sizes exactly.  A small,
    # symmetric margin keeps the glow and every outer ring inside the texture.
    for size in CEREMONY_SIZES:
        save_dxt5(
            centered_texture(source, size, 0.94),
            args.art_dir / f"LOTM_RP_RedPriestMarkCentered{size}.dds",
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
