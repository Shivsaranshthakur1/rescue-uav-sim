#!/usr/bin/env python3
"""
make_rrt_schematic.py
Creates a small PNG comparing RRT vs. RRT* for your Chapter-2 figure.

Output → figures/RRT_vs_RRTStar_schematic.png
"""

import pathlib
import numpy as np
import matplotlib.pyplot as plt

# ------------------------------------------------------------
def random_tree(n_pts=35, goal=np.array([0.9, 0.9]), rewire=False):
    """Return node coords and parent indices; if rewire=True emulate RRT*."""
    rng = np.random.default_rng(3)
    pts = rng.random((n_pts, 2)) * 0.8 + 0.1      # scatter inside [0.1,0.9]
    pts[0]  = np.array([0.1, 0.1])                # start
    pts[-1] = goal                                # goal
    parents = np.zeros(n_pts, dtype=int)

    for i in range(1, n_pts):
        dists = np.linalg.norm(pts[:i] - pts[i], axis=1)
        parents[i] = np.argmin(dists)

    if rewire:                                    # very simple “rewiring”
        for i in range(1, n_pts):
            better = [j for j in range(i)
                      if np.linalg.norm(pts[j] - goal) <
                         np.linalg.norm(pts[parents[i]] - goal)]
            if better:
                parents[i] = min(better,
                                 key=lambda j: np.linalg.norm(pts[j]-pts[i]))
    return pts, parents

# ------------------------------------------------------------
# Generate the two trees
pts_rrt,      par_rrt      = random_tree(rewire=False)
pts_rrt_star, par_rrt_star = random_tree(rewire=True)

# ------------------------------------------------------------
# Plotting
fig, axes = plt.subplots(1, 2, figsize=(6, 3), dpi=300)

for ax, (pts, par), title in zip(
        axes,
        [(pts_rrt, par_rrt), (pts_rrt_star, par_rrt_star)],
        ["RRT (first feasible path)",
         "RRT* (rewired – shorter path)"]):

    # draw all edges
    for i in range(1, len(pts)):
        ax.plot([pts[i, 0], pts[par[i], 0]],
                [pts[i, 1], pts[par[i], 1]],
                color="steelblue", linewidth=0.8)

    # highlight final start→goal path in red
    idx = len(pts) - 1
    while idx != 0:
        parent = par[idx]
        ax.plot([pts[idx, 0], pts[parent, 0]],
                [pts[idx, 1], pts[parent, 1]],
                color="crimson", linewidth=1.5)
        idx = parent

    # start / goal markers
    ax.scatter(*pts[0],  s=22, c="green", zorder=3)
    ax.scatter(*pts[-1], s=22, c="red",   zorder=3)

    ax.set_title(title, fontsize=8)
    ax.set_xticks([]), ax.set_yticks([])
    ax.set_xlim(0, 1),  ax.set_ylim(0, 1)
    ax.set_aspect("equal")

fig.tight_layout()

# ------------------------------------------------------------
# Save to figures/
out_dir = pathlib.Path("figures")
out_dir.mkdir(exist_ok=True)
out_file = out_dir / "RRT_vs_RRTStar_schematic.png"
fig.savefig(out_file, bbox_inches="tight", transparent=True)
print(f"✓  Saved schematic → {out_file}")