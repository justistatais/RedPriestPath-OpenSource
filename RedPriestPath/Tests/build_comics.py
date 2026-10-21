"""Preserve the original comic PNGs and build native-size runtime DDS files.

Civ VI's in-game Image control showed imported PNG files as blank in the
resource-308 runtime test.  The Sequence 0 ceremony proves the supported UI
path: imported DDS textures.  Keep each PNG byte-for-byte for source evidence,
then create one DXT5 DDS companion at exactly the same pixel dimensions.  No
resize, crop, thumbnail, atlas packing, or visual optimizer is applied.
"""
from pathlib import Path
from shutil import copy2

from PIL import Image

SOURCE = Path(r"C:\Users\20594\Downloads")
ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "Art" / "Comics"
OUTPUT.mkdir(parents=True, exist_ok=True)

files = sorted(
    p for p in SOURCE.glob("[123]-*.png")
    if p.stem[:1] in {"1", "2", "3"} and p.stem[1:2] == "-"
)
if not files:
    raise SystemExit(f"no comic PNG files found in {SOURCE}")

for source in files:
    png_target = OUTPUT / f"LOTM_Comic_{source.stem}.png"
    dds_target = OUTPUT / f"LOTM_Comic_{source.stem}.dds"
    copy2(source, png_target)
    with Image.open(source) as image:
        dimensions = image.size
        image.convert("RGBA").save(
            dds_target,
            format="DDS",
            pixel_format="DXT5",
        )
    print(
        f"{source.name}: PNG copied byte-for-byte; "
        f"runtime DDS={dds_target.name} size={dimensions[0]}x{dimensions[1]}"
    )

# Resource 308's direct-PNG-only runtime path is intentionally preserved as a
# rejected reference.  Civ VI displayed a blank Image control even though the
# file was packaged and imported correctly:
# Controls.ComicImage:SetTexture("LOTM_Comic_" .. key .. ".png")

print(f"preserved {len(files)} PNGs and built {len(files)} native-size DDS files")
