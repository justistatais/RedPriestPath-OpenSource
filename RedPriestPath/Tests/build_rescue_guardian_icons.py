#!/usr/bin/env python3
"""Build circular church-colored Phase 3 guardian unit icons.

The existing church artwork intentionally uses a black square presentation for
panels. Unit flags and combat portraits need a different contract: transparent
corners, a circular church-colored field, and an opaque black church seal.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Art"
ICON_SIZES = (22, 30, 32, 38, 50, 70, 80, 95, 200, 256)
CHURCHES = {
    "FOOL": (245, 245, 255),
    "NIGHT": (185, 170, 255),
    "STORM": (55, 235, 225),
}


def extract_seal(source_path: Path) -> Image.Image:
    """Turn the luminous-on-black source seal into a black alpha mask."""
    source = Image.open(source_path).convert("RGB")
    red, green, blue = source.split()
    peak = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    alpha = peak.point(lambda value: max(0, min(255, round((value - 24) * 1.42))))
    alpha = alpha.filter(ImageFilter.UnsharpMask(radius=1.2, percent=145, threshold=3))
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError(f"source has no visible seal: {source_path}")
    alpha = alpha.crop(bounds)
    side = max(alpha.size)
    square = Image.new("L", (side, side), 0)
    square.paste(alpha, ((side - alpha.width) // 2, (side - alpha.height) // 2))
    mark = Image.new("RGBA", (side, side), (8, 10, 14, 255))
    mark.putalpha(square)
    return mark


def render_icon(mark: Image.Image, color: tuple[int, int, int], size: int) -> Image.Image:
    scale = 4
    extent = size * scale
    canvas = Image.new("RGBA", (extent, extent), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    margin = round(extent * 0.045)
    outline = max(scale, round(extent * 0.018))
    draw.ellipse(
        (margin, margin, extent - margin - 1, extent - margin - 1),
        fill=(*color, 255),
        outline=(8, 10, 14, 255),
        width=outline,
    )
    # Keep every outer point of the seal within the colored field and away
    # from Civ VI's own circular portrait rim.
    coverage = 0.78 if size <= 38 else 0.82
    mark_size = max(1, round(extent * coverage))
    resized = mark.resize((mark_size, mark_size), Image.Resampling.LANCZOS)
    inset = (extent - mark_size) // 2
    canvas.alpha_composite(resized, (inset, inset))
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--preview", type=Path)
    args = parser.parse_args()

    preview_tiles: list[Image.Image] = []
    for church, color in CHURCHES.items():
        mark = extract_seal(ART / f"LOTM_Church_{church}_256.dds")
        for size in ICON_SIZES:
            rendered = render_icon(mark, color, size)
            rendered.save(
                ART / f"LOTM_RESCUE_{church}_GuardianGameIcon{size}.dds",
                format="DDS",
                pixel_format="DXT5",
            )
        if args.preview is not None:
            icon = render_icon(mark, color, 256)
            tile = Image.new("RGBA", (300, 300), (205, 205, 205, 255))
            tile.alpha_composite(icon, (22, 8))
            ImageDraw.Draw(tile).text((22, 270), church, fill=(0, 0, 0, 255))
            preview_tiles.append(tile)

    if args.preview is not None:
        preview = Image.new("RGBA", (900, 300), (180, 180, 180, 255))
        for index, tile in enumerate(preview_tiles):
            preview.alpha_composite(tile, (index * 300, 0))
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        preview.save(args.preview)

    print(f"built {len(CHURCHES) * len(ICON_SIZES)} guardian DDS icons")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
