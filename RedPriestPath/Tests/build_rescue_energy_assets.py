#!/usr/bin/env python3
"""Build Civ VI DDS icon atlases for Redemption Purification Energy."""

from __future__ import annotations

from pathlib import Path

from PIL import Image


SIZES = (22, 30, 32, 38, 50, 64, 80, 128, 256)


def normalized(path: Path) -> Image.Image:
    source = Image.open(path).convert("RGBA")
    bounds = source.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError(f"no visible pixels in {path}")
    crop = source.crop(bounds)
    side = max(crop.size)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.alpha_composite(crop, ((side - crop.width) // 2, (side - crop.height) // 2))
    return square


def save_icon(image: Image.Image, size: int, destination: Path) -> None:
    content = max(1, round(size * 0.90))
    resized = image.resize((content, content), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((size - content) // 2, (size - content) // 2))
    canvas.save(destination, format="DDS", pixel_format="DXT5")


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    image = normalized(root / "Art" / "LOTM_RESCUE_PurificationEnergy.png")
    for size in SIZES:
        save_icon(image, size, root / "Art" / f"LOTM_RESCUE_PurificationEnergy{size}.dds")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
