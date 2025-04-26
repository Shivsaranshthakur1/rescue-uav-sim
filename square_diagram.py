#!/usr/bin/env python3
"""
square_diagram.py
-----------------
Post-process the Graphviz architecture diagram:

1.  Optionally down-scales if the longest side exceeds MAX_SIDE.
2.  Adds uniform padding.
3.  Centers it on a square white canvas (great for LaTeX / slides).
4.  Saves the prettified PNG to figures/architecture_sq.png

Run this script from the project root (or from the folder that already
contains architecture.png).  Requires Pillow:  pip install pillow
"""

from PIL import Image
import pathlib
import sys

# --------------------------------------------------
# parameters you may tweak
# --------------------------------------------------
MAX_SIDE = 1600   # px –– max width / height after optional resize
PAD_PX   = 40     # uniform white padding
BG_COLOR = (255, 255, 255)

# --------------------------------------------------
# locate original diagram
# --------------------------------------------------
CWD = pathlib.Path.cwd()
cand = [
    CWD / "architecture.png",
    CWD / "figures" / "architecture.png"
]
ORIG_PATH = next((p for p in cand if p.exists()), None)

if ORIG_PATH is None:
    sys.exit("✗  Couldn’t find architecture.png. "
             "Run make_architecture_diagram.py first (or move the PNG here).")

# output folder / name
OUT_DIR  = ORIG_PATH.parent / "figures"   # save alongside, inside figures/
OUT_DIR.mkdir(exist_ok=True)
OUT_PATH = OUT_DIR / "architecture_sq.png"

# --------------------------------------------------
# process
# --------------------------------------------------
im = Image.open(ORIG_PATH)
w, h = im.size

# 1) optional down-scale
scale = MAX_SIDE / max(w, h) if max(w, h) > MAX_SIDE else 1.0
if scale < 1.0:
    im = im.resize((int(w*scale), int(h*scale)), Image.LANCZOS)
    w, h = im.size

# 2) square canvas with padding
side = max(w, h) + 2*PAD_PX
canvas = Image.new("RGB", (side, side), BG_COLOR)
offset = ((side - w)//2, (side - h)//2)
canvas.paste(im, offset)

# 3) save @ 300 dpi
canvas.save(OUT_PATH, dpi=(300, 300))
print(f"✓  Saved prettified diagram → {OUT_PATH.relative_to(CWD)}")