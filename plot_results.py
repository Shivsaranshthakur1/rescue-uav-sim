#!/usr/bin/env python3
"""
plot_results.py  –  regenerate all Chapter-5 figures from experiment_results.csv

* Figures 1–4 (core plots)          ->  figures/
* Extended analysis (heat-map etc.) ->  analysis/

PNG names match those already referenced in the .tex file, so Overleaf will
simply pick up the new versions and you won’t accumulate duplicates.
"""

import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# ------------------------------------------------------------------ #
#  Folders & CSV
# ------------------------------------------------------------------ #
CSV_FILE  = "experiment_results.csv"
FIG_DIR   = "figures"
ANA_DIR   = "analysis"

for d in (FIG_DIR, ANA_DIR):
    os.makedirs(d, exist_ok=True)

# ------------------------------------------------------------------ #
#  Helper : grouped bar with 95 % CI
# ------------------------------------------------------------------ #
def bar_with_ci(gb_obj, title, ylabel, fname):
    """
    gb_obj is a pandas GroupBy of a single numeric column:
        df.groupby([...])["metric"]

    Saves <fname> to FIG_DIR.
    """
    means = gb_obj.mean().unstack()
    sems  = gb_obj.sem().unstack() * 1.96       # 95 % CI

    fig, ax = plt.subplots(figsize=(8, 4))
    means.plot(kind="bar", yerr=sems, ax=ax,
               capsize=4, legend=True, rot=0)
    ax.set_title(title)
    ax.set_ylabel(ylabel)
    ax.set_xlabel("")
    plt.tight_layout()
    out = os.path.join(FIG_DIR, fname)
    plt.savefig(out, dpi=300)
    plt.close(fig)
    print(f"✓  {out}")

# ------------------------------------------------------------------ #
#  Main
# ------------------------------------------------------------------ #
def main():

    if not os.path.isfile(CSV_FILE):
        raise FileNotFoundError(f"Cannot see {CSV_FILE} – run runExperiments.m first.")

    df = pd.read_csv(CSV_FILE)

    # Convenience columns ---------------------------------------------------
    df["Scenario"] = df.apply(
        lambda r: f"M{r.MapWidth}_B{r.NumBuildings}_S{r.NumSurvivors}", axis=1)

    df["TotalRescued"]     = df[["UAV1resc","UAV2resc","UAV3resc","UAV4resc"]].sum(axis=1)
    df["FractionRescued"]  = df.TotalRescued / df.NumSurvivors
    df["Planner"]          = df.useRRTStar.map({0:"RRT", 1:"RRT*"})

    # ---------------- Figure 1 : Mean TimeTaken (95 % CI) ------------------
    bar_with_ci(df.groupby(["Planner","Approach"])["TimeTaken"],
                "Average TimeTaken by Planner × Approach (95 % CI)",
                "TimeTaken (s)",
                "avg_time_taken.png")

    # ---------------- Figure 2 : Fraction rescued --------------------------
    bar_with_ci(df.groupby(["Planner","Approach"])["FractionRescued"],
                "Fraction of Survivors Rescued (mean ± 95 % CI)",
                "Fraction rescued",
                "fraction_rescued.png")

    # ---------------- Figure 3 : Aerial distance boxplot -------------------
    aerial_rows = []
    for _, r in df.iterrows():
        aerial_rows += [
            {"Method":f"{r.Planner}_{r.Approach}", "UAV":"UAV3", "Dist":r.UAV3dist},
            {"Method":f"{r.Planner}_{r.Approach}", "UAV":"UAV4", "Dist":r.UAV4dist},
        ]
    a_df = pd.DataFrame(aerial_rows)
    a_df["Label"] = a_df.Method + "_" + a_df.UAV

    fig, ax = plt.subplots(figsize=(10,4))
    labels  = sorted(a_df.Label.unique())
    data    = [a_df.loc[a_df.Label==lab,"Dist"] for lab in labels]
    ax.boxplot(data, labels=labels, showfliers=True)
    ax.set_title("Aerial-drone distances")
    ax.set_ylabel("Distance (m)")
    plt.xticks(rotation=45, ha="right")
    plt.tight_layout()
    out = os.path.join(FIG_DIR, "aerial_distance_box.png")
    plt.savefig(out, dpi=300)
    plt.close(fig)
    print(f"✓  {out}")

    # ---------------- Figure 4 : Ground distance boxplot -------------------
    ground_rows = []
    for _, r in df.iterrows():
        ground_rows += [
            {"Method":f"{r.Planner}_{r.Approach}", "UAV":"UAV1", "Dist":r.UAV1dist},
            {"Method":f"{r.Planner}_{r.Approach}", "UAV":"UAV2", "Dist":r.UAV2dist},
        ]
    g_df = pd.DataFrame(ground_rows)
    g_df["Label"] = g_df.Method + "_" + g_df.UAV

    fig, ax = plt.subplots(figsize=(10,4))
    labels  = sorted(g_df.Label.unique())
    data    = [g_df.loc[g_df.Label==lab,"Dist"] for lab in labels]
    ax.boxplot(data, labels=labels, showfliers=True)
    ax.set_title("Ground-vehicle distances")
    ax.set_ylabel("Distance (m)")
    plt.xticks(rotation=45, ha="right")
    plt.tight_layout()
    out = os.path.join(FIG_DIR, "ground_distance_box.png")
    plt.savefig(out, dpi=300)
    plt.close(fig)
    print(f"✓  {out}")

    # --------------- Extra analysis : Pareto & workload heat-map -----------

    # Pareto plot: time vs fraction rescued
    fig, ax = plt.subplots(figsize=(6,4))
    ax.scatter(df.TimeTaken, df.FractionRescued, alpha=0.6)
    ax.set_xlabel("TimeTaken (s)")
    ax.set_ylabel("Fraction rescued")
    ax.set_title("Pareto front – time vs rescued")
    ax.grid(True, ls=":")
    out = os.path.join(ANA_DIR, "pareto_time_vs_rescued.png")
    plt.tight_layout()
    plt.savefig(out, dpi=300)
    plt.close(fig)
    print(f"✓  {out}")

    # Workload heat-map (total distance / UAV / scenario)
    dist_cols = ["UAV1dist","UAV2dist","UAV3dist","UAV4dist"]
    heat_df   = df.groupby("Scenario")[dist_cols].mean()
    fig, ax   = plt.subplots(figsize=(6,6))
    im = ax.imshow(heat_df.values, cmap="viridis", aspect="auto")
    ax.set_yticks(range(len(heat_df.index)))
    ax.set_yticklabels(heat_df.index)
    ax.set_xticks(range(len(dist_cols)))
    ax.set_xticklabels(dist_cols, rotation=45, ha="right")
    ax.set_title("Average distance per UAV (heat-map)")
    fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
    plt.tight_layout()
    out = os.path.join(ANA_DIR, "workload_heatmap.png")
    plt.savefig(out, dpi=300)
    plt.close(fig)
    print(f"✓  {out}")

    print("\nAll figures regenerated – upload any updated PNGs to Overleaf.")

if __name__ == "__main__":
    main()