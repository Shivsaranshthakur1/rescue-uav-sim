#!/usr/bin/env python3
"""
make_module_table.py
Re-renders figures/module_table.png with fixed column widths & word-wrapping.
"""

import textwrap, pathlib
import pandas as pd
import matplotlib.pyplot as plt

# ------------------------------------------------------------------
# 1  table data  (edit LoC or wording here)
# ------------------------------------------------------------------
data = [
    ("BaseUAV.m",        77, "moveStep, planPath (abstract)",      "—",                "1",   "Shared kinematics / logging"),
    ("AerialDrone.m",    56, "planPath (3-D)",                     "BaseUAV",          "1,2", "SE3 flight, 3-D validator"),
    ("GroundVehicle.m",  56, "planPath (2-D)",                     "BaseUAV",          "1,2", "SE2 motion, road-level grid"),
    ("Survivor.m",       32, "constructor, markRescued",           "—",                "3",   "Explicit state tracking"),
    ("createEnvironment.m", 99,"env = createEnvironment(cfg)",     "cfg",              "2",   "Builds both occupancy grids"),
    ("runRescueMission.m",306,"main loop, pickSurvivor",           "env, cfg",         "1-3", "Orchestrates vehicles / driver"),
    ("compareApproaches.m",48,"batch loop",                        "runRescueMission", "—",   "96-run experimental driver"),
    ("demoAllScenarios.m",87,"interactive demo",                   "runRescueMission", "—",   "Quick demo for supervisor"),
    ("config.m",         38, "returns cfg struct",                 "—",                "—",   "Central parameter store"),
]

cols = ["File / Class", "LoC", "Key Public Methods",
        "Depends On", "REQ", "Design Rationale"]

# ------------------------------------------------------------------
# 2  wrap long strings so they fit the column width
# ------------------------------------------------------------------
def wrap(txt, width=30):
    return "\n".join(textwrap.wrap(str(txt), width=width, break_long_words=False))

wrapped = [[wrap(c) for c in row] for row in data]
df = pd.DataFrame(wrapped, columns=cols)

# ------------------------------------------------------------------
# 3  render -- fixed colWidths keep table straight
# ------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(9.5, 3.2), dpi=220)
ax.axis("off")

col_widths = [0.9, 0.45, 2.6, 1.2, 0.4, 2.6]   # inches
tbl = ax.table(cellText=df.values,
               colLabels=df.columns,
               loc="center",
               cellLoc="left",
               colWidths=[w/9.5 for w in col_widths])

tbl.auto_set_font_size(False)
tbl.set_fontsize(7.5)
tbl.scale(1, 1.14)

# bold header row
for (r, c), cell in tbl.get_celld().items():
    if r == 0:
        cell.set_text_props(weight="bold")

fig.tight_layout()

out_dir = pathlib.Path("figures")
out_dir.mkdir(exist_ok=True)
out_path = out_dir / "module_table.png"
fig.savefig(out_path, bbox_inches="tight")
plt.close(fig)

print(f"[✓]  Saved  {out_path}")