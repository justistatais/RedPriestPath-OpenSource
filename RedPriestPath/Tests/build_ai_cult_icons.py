#!/usr/bin/env python3
"""Build user-supplied AI cult emblems and the civilization-tinted puppet mark."""
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
CULT_SOURCES={
 "Demoness":Path(r"C:\Users\20594\Downloads\ChatGPT Image 2026年8月11日 21_03_22 (1).png"),
 "HangedMan":Path(r"C:\Users\20594\Downloads\ChatGPT Image 2026年8月11日 21_03_23 (2).png"),
 "Chained":Path(r"C:\Users\20594\Downloads\ChatGPT Image 2026年8月11日 21_03_24 (3).png"),
}
PUPPET_SOURCE=Path(r"C:\Users\20594\Downloads\ChatGPT Image 2026年8月11日 21_48_40.png")

def square(image):
 side=min(image.size); left=(image.width-side)//2; top=(image.height-side)//2
 return image.crop((left,top,left+side,top+side))

def remove_dark(image,threshold=45):
 source=image.convert("RGB"); out=[]
 for red,green,blue in source.getdata():
  peak=max(red,green,blue)
  if peak<=threshold: out.append((0,0,0,0))
  else: out.append((round(red*255/peak),round(green*255/peak),round(blue*255/peak),round(255*(peak-threshold)/(255-threshold))))
 result=Image.new("RGBA",source.size); result.putdata(out); return result

for name,path in CULT_SOURCES.items():
 image=remove_dark(square(Image.open(path)))
 for size in (22,32,40,50,64,80,128,256): image.resize((size,size),Image.Resampling.LANCZOS).save(ROOT/"Art"/f"LOTM_AI_Cult_{name}_{size}.dds",format="DDS",pixel_format="DXT5")

# The new puppet source intentionally carries its shape in alpha and near-black
# RGB. Convert only the shape to a white mask so Firaxis' existing civilization
# foreground color tints it. The flag base color is never overridden.
source=Image.open(PUPPET_SOURCE).convert("RGBA"); alpha=source.getchannel("A"); bbox=alpha.point(lambda value: 255 if value>=8 else 0).getbbox()
if bbox is None: raise RuntimeError("flesh puppet source has no visible alpha")
cropped=alpha.crop(bbox); side=round(max(cropped.size)*1.16); padded=Image.new("L",(side,side),0); padded.paste(cropped,((side-cropped.width)//2,(side-cropped.height)//2))
mark=Image.new("RGBA",padded.size,(255,255,255,0)); mark.putalpha(padded)
for size in (40,64,256): mark.resize((size,size),Image.Resampling.LANCZOS).save(ROOT/"Art"/f"LOTM_AI_Cult_FleshPuppetMark_{size}.dds",format="DDS",pixel_format="DXT5")
print("built",len(CULT_SOURCES)*8+3,"AI cult DDS icons")
