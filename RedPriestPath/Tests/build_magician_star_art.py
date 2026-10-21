"""Derive DDS governor portraits and circular CityBanner icons from project PNGs."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageOps


ART = Path(__file__).resolve().parents[1] / "Art"


def circle_mask(size: int) -> Image.Image:
    scale = 4
    mask = Image.new("L", (size * scale, size * scale), 0)
    ImageDraw.Draw(mask).ellipse((1, 1, size * scale - 2, size * scale - 2), fill=255)
    return mask.resize((size, size), Image.Resampling.LANCZOS)


def build_one(name: str) -> None:
    source = Image.open(ART / f"LOTM_MS_{name}Portrait.png").convert("RGBA")
    width, height = source.size
    side = min(width, height)
    source = source.crop(((width - side) // 2, (height - side) // 2,
                          (width + side) // 2, (height + side) // 2))
    for size in (24, 32, 64, 256):
        image = source.resize((size, size), Image.Resampling.LANCZOS)
        image.save(ART / f"LOTM_MS_{name}{size}.dds")
    for size in (22, 32):
        fill = source.resize((size, size), Image.Resampling.LANCZOS)
        fill.putalpha(circle_mask(size))
        gray = ImageOps.grayscale(fill)
        slot = ImageOps.colorize(gray, black="#24283a", white="#a3a5b9").convert("RGBA")
        slot.putalpha(fill.getchannel("A"))
        slot = ImageEnhance.Brightness(slot).enhance(0.65)
        for kind, image in (("Fill", fill), ("Slot", slot)):
            path = ART / f"LOTM_MS_{name}Banner{kind}{size}.dds"
            image.save(path)
            checked = Image.open(path).convert("RGBA")
            assert checked.size == (size, size)
            assert checked.getpixel((0, 0))[3] == 0
            assert checked.getpixel((size // 2, size // 2))[3] > 200
            print(f"{path.name}: {path.stat().st_size} bytes")


if __name__ == "__main__":
    for governor in ("Fors", "Leonard"):
        build_one(governor)
