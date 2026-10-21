#!/usr/bin/env python3
"""Build church and Astral Descent emblems as deterministic DDS icon files."""
from pathlib import Path
from PIL import Image, ImageEnhance

ROOT=Path(__file__).resolve().parents[1]
SOURCES={
 "CENTER":Path(r"C:\Users\20594\Downloads\ChatGPT Image 2026年8月15日 14_52_21.png"),
 "FOOL":Path(r"C:\Users\20594\Downloads\ChatGPT Image 2026年8月10日 23_25_50 (2).png"),
 "NIGHT":Path(r"C:\Users\20594\Downloads\ChatGPT Image 2026年8月10日 23_25_50 (1).png"),
 "STORM":Path(r"C:\Users\20594\Downloads\ChatGPT Image 2026年8月10日 23_28_22.png"),
}

def remove_dark_background(image, threshold=50):
 """Recover a translucent luminous seal from artwork rendered on black."""
 source=image.convert("RGB")
 pixels=[]
 for red,green,blue in source.getdata():
  peak=max(red,green,blue)
  if peak<=threshold:
   pixels.append((0,0,0,0))
   continue
  alpha=round(255*(peak-threshold)/(255-threshold))
  pixels.append((round(red*255/peak),round(green*255/peak),round(blue*255/peak),alpha))
 transparent=Image.new("RGBA",source.size,(0,0,0,0))
 transparent.putdata(pixels)
 return transparent

for church,source in SOURCES.items():
 image=Image.open(source).convert("RGBA")
 side=min(image.size); left=(image.width-side)//2; top=(image.height-side)//2; image=image.crop((left,top,left+side,top+side))
 if church=="CENTER":
  # The full astronomical seal is too dense at the banner's native 22px.
  # Frame its defining central eye so the supplied artwork remains legible.
  inset=round(image.width*0.40)
  image=image.crop((inset,inset,image.width-inset,image.height-inset))
 image=ImageEnhance.Contrast(image).enhance(1.08)
 manual_image=remove_dark_background(image)
 sizes=(22,) if church=="CENTER" else (22,26,32,36,40,56,64,128,200,256)
 for size in sizes:
  if size==22:
   # City banner slots already provide their own circular backing. Remove the
   # source artwork's black square so only the luminous seal is composited.
   rendered=manual_image.resize((size,size),Image.Resampling.LANCZOS)
  elif size==40:
   # Firaxis' notification control supplies its own 40px circular rim.  Keep
   # the complete church seal inside that rim instead of touching its edge.
   rendered=Image.new("RGBA",(40,40),(0,0,0,0)); inset=image.resize((30,30),Image.Resampling.LANCZOS); rendered.alpha_composite(inset,(5,5))
  elif size==200:
   # The manual lays these seals directly over its illustrated panel, like
   # the three pathway marks, so its dedicated size must not retain a square.
   rendered=manual_image.resize((size,size),Image.Resampling.LANCZOS)
  else:
   rendered=image.resize((size,size),Image.Resampling.LANCZOS)
  filename=(f"LOTM_RESCUE_AstralDescent_{size}.dds" if church=="CENTER"
            else f"LOTM_Church_{church}_{size}.dds")
  rendered.save(ROOT/"Art"/filename,format="DDS",pixel_format="DXT5")
print("built",sum(1 if key=="CENTER" else 10 for key in SOURCES),"seal DDS icons")
