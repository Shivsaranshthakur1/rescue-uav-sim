#!/usr/bin/env python3
"""
square_diagram.py
Resize & square-pad the Graphviz 'architecture.png' so it
fits nicely in LaTeX or slides.

Run from the folder that contains architecture.png
"""

from PIL import Image
import pathlib

# --------------------------------------------------
# Paths – tweak if your filenames / folders differ
# --------------------------------------------------
ORIG_PATH = pathlib.Path("architecture.png")      # original Graphviz output
OUT_DIR   = pathlib.Path("figures")               # where to save the prettified version
OUT_DIR.mkdir(exist_ok=True, exist_ok=True)
OUT_PATH  = OUT_DIR / "architecture_sq.png"

# --------------------------------------------------
# Tweakable parameters
# --------------------------------------------------
MAX_SIDE = 1600   # px – longest side after possible down-scale
PAD_PX   = 40     # uniform white border
BG_COLOR = (255, 255, 255)

# --------------------------------------------------
# Main
# --------------------------------------------------
def main():
    if not ORIG_PATH.exists():
        raise FileNotFoundError(f"{ORIG_PATH} not found. Run make_architecture_diagram.py first.")
    
    im = Image.open(ORIG_PATH)
    w, h = im.size

    # 1) optional down-scale
    scale = MAX_SIDE / max(w, h) if max(w, h) > MAX_SIDE else 1.0
    if scale < 1.0:
        new_size = (int(w * scale), int(h * scale))
        im = im.resize(new_size, Image.LANCZOS)
        w, h = im.size

    # 2) square canvas with padding
    side   = max(w, h) + 2 * PAD_PX
    canvas = Image.new("RGB", (side, side), BG_COLOR)
    offset = ((side - w) // 2, (side - h) // 2)
    canvas.paste(im, offset)

    # 3) save
    canvas.save(OUT_PATH, dpi=(300, 300))
    print(f"[✓] Saved prettified diagram → {OUT_PATH.name}")

if __name__ == "__main__":
    main()