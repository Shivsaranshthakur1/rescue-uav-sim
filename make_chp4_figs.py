
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from pathlib import Path

OUT = Path('figures')
OUT.mkdir(exist_ok=True)

# 1. Pipeline ----------------------------------------------------------------
stages = ['initialise maps', 'place buildings', 'extrude 3-D cells', 'spawn survivors']
fig, ax = plt.subplots(figsize=(6,1.7), dpi=150)
ax.axis('off')
for i, txt in enumerate(stages):
    ax.add_patch(patches.FancyBboxPatch(
        (i, 0), 1, 1, boxstyle="round,pad=0.02", fc='#ecf2fc', ec='k', lw=1.2))
    ax.text(i+0.5, 0.55, txt, ha='center', va='center', fontsize=8)
    if i < len(stages)-1:
        ax.annotate('', (i+0.98,0.5), (i+1.02,0.5),
                    arrowprops=dict(arrowstyle='-|>', lw=1.2))
plt.xlim(-0.1, len(stages)+0.1)
plt.ylim(-0.1, 1.1)
fig.savefig(OUT/'env_pipeline.png', bbox_inches='tight')
plt.close(fig)

# 2. Sequence diagram --------------------------------------------------------
actors = ['Controller', 'UAV', 'Planner', 'Env', 'Collision\nCheck']
x = range(len(actors))
fig, ax = plt.subplots(figsize=(14,4), dpi=150)
ax.axis('off')
for xi, name in zip(x, actors):
    ax.plot([xi, xi], [0.1, 0.9], 'k:', lw=0.8)
    ax.text(xi, 0.92, name, ha='center', va='bottom', fontsize=10, fontweight='bold')
def arrow(x0,y0,x1,y1,label):
    ax.annotate('', (x1,y1), (x0,y0), arrowprops=dict(arrowstyle='-|>',lw=1.3))
    ax.text((x0+x1)/2, y0+0.02, label, ha='center', va='bottom', fontsize=8)

arrow(0,0.8,1,0.8,'planPath()')
arrow(1,0.7,2,0.7,'computeRoute()')
arrow(2,0.6,3,0.6,'queryEnv()')
arrow(3,0.5,4,0.5,'isFree()')
arrow(2,0.4,1,0.4,'path',)   # return (drawn reversed)
fig.savefig(OUT/'seq_planPath.png', bbox_inches='tight')
plt.close(fig)

print('✓  Python: figures written to', OUT)