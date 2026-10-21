#!/usr/bin/env python3
"""Generate exact 200px DXT5 AI-cult atlases for the opening manual."""

from __future__ import annotations

import struct
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Art"
ICONS = (
    "LOTM_AI_Cult_Demoness",
    "LOTM_AI_Cult_HangedMan",
    "LOTM_AI_Cult_Chained",
)


def main() -> None:
    for stem in ICONS:
        source = ART / f"{stem}_256.dds"
        target = ART / f"{stem}_200.dds"
        with Image.open(source) as image:
            resized = image.convert("RGBA").resize((200, 200), Image.Resampling.LANCZOS)
            resized.save(target, format="DDS", pixel_format="DXT5")

        header = target.read_bytes()[:128]
        height, width = struct.unpack_from("<II", header, 12)
        fourcc = header[84:88]
        if header[:4] != b"DDS " or (width, height) != (200, 200) or fourcc != b"DXT5":
            raise RuntimeError(f"invalid generated DDS: {target}")
        print(f"wrote {target.relative_to(ROOT)} (200x200 DXT5)")


if __name__ == "__main__":
    main()
