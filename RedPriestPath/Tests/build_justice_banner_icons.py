"""Build the small circular Justice city-banner meters from the source PNG."""

from pathlib import Path

from PIL import Image, ImageEnhance, ImageOps


ART = Path(__file__).resolve().parents[1] / "Art"
SOURCE = ART / "LOTM_JUSTICE_AudreyBannerCircle.png"


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    for size in (22, 32):
        fill = source.resize((size, size), Image.Resampling.LANCZOS)
        # Preserve the same outline for both halves of the vanilla progress
        # meter while making its unfilled segment visibly dimmer.
        gray = ImageOps.grayscale(fill)
        slot = ImageOps.colorize(gray, black="#30291f", white="#b9ab8d").convert("RGBA")
        slot.putalpha(fill.getchannel("A"))
        slot = ImageEnhance.Brightness(slot).enhance(0.64)
        for kind, image in (("Fill", fill), ("Slot", slot)):
            path = ART / f"LOTM_JUSTICE_Banner{kind}{size}.dds"
            image.save(path)
            check = Image.open(path).convert("RGBA")
            assert check.size == (size, size)
            assert check.getpixel((0, 0))[3] == 0
            assert check.getpixel((size // 2, size // 2))[3] > 200
            print(f"{path.name}: {path.stat().st_size} bytes")


if __name__ == "__main__":
    main()
