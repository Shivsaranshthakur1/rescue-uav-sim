#!/usr/bin/env python3
"""
csv2png.py  – run from inside the analysis/ folder.

• Converts every CSV in this folder into a PNG table.
• PNGs are written to analysis/Analysis1/ (created if absent).
• PNG file names mirror the CSV base-names (just ".png").
• Prints only the PNG name (not the path) after each save.
"""

import os
import pathlib
import math
import pandas as pd
import matplotlib.pyplot as plt

HERE      = pathlib.Path(__file__).resolve().parent         # .../analysis
PNG_DIR   = HERE / "Analysis1"
PNG_DIR.mkdir(exist_ok=True)

# ------------------------------------------------------------------
# Helper – Format floats so they do not overflow the table cells
# ------------------------------------------------------------------
def prettify_dataframe(df, float_fmt="{:.2f}"):
    """Return a *string* DataFrame with nicer float formatting."""
    df_fmt = df.copy()
    for col in df_fmt.columns:
        if pd.api.types.is_numeric_dtype(df_fmt[col]):
            df_fmt[col] = df_fmt[col].map(lambda x: float_fmt.format(x))
    return df_fmt.astype(str)

# ------------------------------------------------------------------
# Helper – Render a single CSV to PNG
# ------------------------------------------------------------------
def csv_to_png(csv_path: pathlib.Path,
               png_path: pathlib.Path,
               dpi=200,
               cell_fs=8,
               header_fs=9):
    df_raw = pd.read_csv(csv_path)
    df = prettify_dataframe(df_raw)

    rows, cols = df.shape

    # --- Estimate figure size based on maximum text width in each column ---
    char_per_inch = 6              # heuristic; tweak if needed
    max_chars = df.applymap(len).max()  # per-column max string length
    col_inches = [max(1.2, c / char_per_inch) for c in max_chars]
    fig_w = sum(col_inches) + 0.6          # extra margin
    fig_h = 0.6 + 0.3 * rows               # 0.3 in per row

    fig, ax = plt.subplots(figsize=(fig_w, fig_h), dpi=dpi)
    ax.axis("off")

    tbl = ax.table(cellText=df.values,
                   colLabels=df.columns,
                   loc="center",
                   cellLoc="center")

    tbl.auto_set_font_size(False)

    for (r, c), cell in tbl.get_celld().items():
        # Header row
        if r == 0:
            cell.set_text_props(weight="bold", fontsize=header_fs)
            cell.set_facecolor("#d9d9d9")
        else:
            cell.set_fontsize(cell_fs)

        # Prevent text clipping
        cell.set_clip_on(True)

    tbl.scale(1, 1.25)      # adjust vertical spacing
    fig.tight_layout()
    fig.savefig(png_path, bbox_inches="tight")
    plt.close(fig)

# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------
def main():
    csv_files = sorted(HERE.glob("*.csv"))
    if not csv_files:
        print("No CSV files found; nothing to convert.")
        return

    for csv_f in csv_files:
        png_f = PNG_DIR / f"{csv_f.stem}.png"
        try:
            csv_to_png(csv_f, png_f)
            print(png_f.name)      # just the file name
        except Exception as exc:
            print(f"[!] Failed on {csv_f.name}: {exc}")

if __name__ == "__main__":
    main()