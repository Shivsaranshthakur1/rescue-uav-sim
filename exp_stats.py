#!/usr/bin/env python3
"""
analysis_script.py  – enhanced: all outputs go to ./Analysis/
"""

import pandas as pd
import numpy as np
from pathlib import Path
from scipy import stats
import statsmodels.api as sm
from statsmodels.formula.api import ols

# ------------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------------
CSV_IN   = Path("experiment_results.csv")
OUT_DIR  = Path("Analysis")          # <-- all results will live here
OUT_DIR.mkdir(parents=True, exist_ok=True)

# ------------------------------------------------------------------
# 0) Read Data
# ------------------------------------------------------------------
def read_data(csv_file=CSV_IN):
    df = pd.read_csv(csv_file)
    df["useRRTStar"] = df["useRRTStar"].astype(bool)
    df["Seed"]       = df["Seed"].astype(int)
    return df

# ------------------------------------------------------------------
# 1) One-Way Descriptive Stats
# ------------------------------------------------------------------
def one_way_descriptive(df, factor_list, value_col="TimeTaken"):
    results = {}
    for factor in factor_list:
        g      = df.groupby(factor)[value_col]
        n      = g.count()
        mean   = g.mean()
        std    = g.std(ddof=1)
        var    = g.var(ddof=1)
        ci95   = 1.96 * std / np.sqrt(n)
        tbl = pd.DataFrame({
            factor       : n.index,
            "N"          : n.values,
            "Mean"       : mean.values,
            "StdDev"     : std.values,
            "Variance"   : var.values,
            "CI95_Lower" : (mean - ci95).values,
            "CI95_Upper" : (mean + ci95).values,
        })
        results[factor] = tbl.reset_index(drop=True)
    return results

# ------------------------------------------------------------------
# 2) Two-Way Planner × Assignment Table
# ------------------------------------------------------------------
def two_way_table(df, planner_col="useRRTStar",
                  assign_col="Approach", value_col="TimeTaken"):
    """
    Returns a 2 × 2 (or however many) table whose cells contain
    “mean ± std dev” for each Planner × Assignment combination.
    """
    g      = df.groupby([planner_col, assign_col])[value_col]
    means  = g.mean()
    stds   = g.std(ddof=1)

    # String like “123.4 ± 5.6”
    combined = means.round(2).astype(str) + " ± " + stds.round(2).astype(str)

    # Pretty labels: True→RRT*, False→RRT
    def label(b: bool) -> str:
        return "RRT*" if b else "RRT"

    new_index = [(label(idx[0]), idx[1]) for idx in combined.index]

    # critical fix: ensure a real MultiIndex
    combined.index = pd.MultiIndex.from_tuples(
        new_index, names=[planner_col, assign_col]
    )

    pivot_df = combined.unstack(level=1)          # columns = Approach
    pivot_df = pivot_df.reset_index().rename_axis(None, axis=1)
    return pivot_df

# ------------------------------------------------------------------
# 3) Factorial ANOVA
# ------------------------------------------------------------------
def run_anova(df):
    df["MapWidth"]     = df["MapWidth"].astype(str)
    df["NumBuildings"] = df["NumBuildings"].astype(str)
    df["NumSurvivors"] = df["NumSurvivors"].astype(str)
    df["useRRTStar"]   = df["useRRTStar"].astype(str)

    formula = ("TimeTaken ~ C(MapWidth) + C(NumBuildings) + C(NumSurvivors)"
               " + C(useRRTStar) + C(Approach)"
               " + C(MapWidth):C(NumBuildings)"
               " + C(useRRTStar):C(Approach)")
    m  = ols(formula, data=df).fit()
    an = sm.stats.anova_lm(m, typ=2).round(3)
    return an.reset_index().rename(columns={"index": "Factor"})

# ------------------------------------------------------------------
# 4) CV for UAV Distances
# ------------------------------------------------------------------
def cv_table(df, cols=("UAV1dist","UAV2dist","UAV3dist","UAV4dist")):
    rows = []
    for c in cols:
        mu  = df[c].mean()
        sd  = df[c].std(ddof=1)
        cv  = sd / mu if mu else np.nan
        rows.append({"UAV": c.replace("dist",""),
                     "MeanDist": mu, "StdDist": sd, "CV": cv})
    return pd.DataFrame(rows)

# ------------------------------------------------------------------
# 5) Representative Runs
# ------------------------------------------------------------------
def representative_runs(df, value_col="TimeTaken"):
    srt = df.sort_values(value_col).reset_index(drop=True)
    return pd.DataFrame([srt.iloc[0],               # min
                         srt.iloc[len(srt)//2],     # median
                         srt.iloc[-1]])             # max

# ------------------------------------------------------------------
# MAIN
# ------------------------------------------------------------------
def save(df, stem):
    path = OUT_DIR / f"{stem}.csv"
    df.to_csv(path, index=False)
    print(f"[✓] {path}")

def main():
    df = read_data()

    # 1) One-way stats
    factors = ["MapWidth","NumBuildings","NumSurvivors","useRRTStar","Approach"]
    for f, tbl in one_way_descriptive(df, factors).items():
        save(tbl, f"{f}_time_stats")

    # 2) Planner × Assignment
    save(two_way_table(df), "planner_x_approach")

    # 3) ANOVA
    save(run_anova(df.copy()), "anova_results")

    # 4) CV table
    save(cv_table(df), "uav_cv_table")

    # 5) Representative runs
    save(representative_runs(df), "representative_runs")

if __name__ == "__main__":
    main()