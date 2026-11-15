"""Assemble build/demo_frames and build/style_frames into doc/demo.gif and doc/style.gif (Pillow)."""
import glob
import os

from PIL import Image

os.makedirs("doc", exist_ok=True)
for src, dst in (("demo_frames", "demo.gif"), ("style_frames", "style.gif")):
    files = sorted(glob.glob(f"build/{src}/f*.png"))
    frames = [
        Image.open(f).convert("RGB").quantize(colors=64, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
        for f in files
    ]
    frames[0].save(f"doc/{dst}", save_all=True, append_images=frames[1:], duration=50, loop=0, optimize=True)
    print(dst, len(frames), "frames", os.path.getsize(f"doc/{dst}") // 1024, "KB")
