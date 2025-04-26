import matplotlib.pyplot as plt

phases = ['Phase I', 'Phase II', 'Phase III']
start  = [0,  2,  4]        # months offset
dur    = [2,  2,  2]        # months duration
labels = ['Battery & comm-loss', 'ROS 2 port', 'Field pilot']

fig, ax = plt.subplots(figsize=(6, 1.5))
ax.barh(phases, dur, left=start, color='#0072BD')
for s, p, l in zip(start, phases, labels):
    ax.text(s + 0.1, p, l, va='center', ha='left', color='white', fontsize=8)
ax.set_xlabel('Month')
ax.set_xlim(0, 6)
ax.invert_yaxis()
plt.tight_layout()
plt.savefig('figures/roadmap.png', dpi=300)