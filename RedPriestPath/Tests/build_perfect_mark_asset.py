#!/usr/bin/env python3
"""Build the centered DXT5 Perfect Path LaunchBar mark from the user PNG."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

CEREMONY_SIZES = (384, 512, 640, 768)


def make_transparent_source(source_path: Path, threshold: int) -> Image.Image:
    source = Image.open(source_path).convert("RGB")
    red, green, blue = source.split()
    alpha = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    alpha = alpha.filter(ImageFilter.UnsharpMask(radius=2, percent=180, threshold=4))
    alpha = alpha.point(
        lambda value: max(0, min(255, (value - threshold) * 10))
    )
    # At 40 px, DXT5 color blocks can turn mixed white/orange edge pixels into
    # colored speckles. Preserve the supplied glyph and glow in alpha while
    # normalizing all visible pixels to its dominant golden hue.
    rgba = Image.new("RGBA", source.size, (255, 184, 0, 255))
    rgba.putalpha(alpha)
    return rgba


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--threshold", type=int, default=205)
    parser.add_argument("--content-size", type=int, default=31)
    parser.add_argument("--preview", type=Path)
    parser.add_argument(
        "--output",
        type=Path,
        default=(
            Path(__file__).resolve().parents[1]
            / "Art"
            / "LOTM_PP_PerfectMarkCentered40.dds"
        ),
    )
    args = parser.parse_args()

    source = make_transparent_source(args.source, args.threshold)
    content_size = args.content_size
    resized = source.resize((content_size, content_size), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
    inset = (40 - content_size) // 2
    canvas.alpha_composite(resized, (inset, inset))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(args.output, format="DDS", pixel_format="DXT5")
    if args.preview is not None:
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        preview = Image.new("RGBA", (400, 400), (0, 0, 0, 255))
        preview.alpha_composite(
            canvas.resize((400, 400), Image.Resampling.NEAREST)
        )
        preview.convert("RGB").save(args.preview)
    for size in CEREMONY_SIZES:
        ceremony_content_size = round(size * 0.94)
        ceremony = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        resized_ceremony = source.resize(
            (ceremony_content_size, ceremony_content_size),
            Image.Resampling.LANCZOS,
        )
        ceremony_inset = (size - ceremony_content_size) // 2
        ceremony.alpha_composite(
            resized_ceremony,
            (ceremony_inset, ceremony_inset),
        )
        ceremony.save(
            args.output.parent / f"LOTM_PP_PerfectMarkCentered{size}.dds",
            format="DDS",
            pixel_format="DXT5",
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
