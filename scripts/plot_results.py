"""Render README figures from saved Julia results; run from any directory.

Requires matplotlib 3.11.2. No simulations are generated or selected here.
"""
from pathlib import Path
import csv
import math
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import PercentFormatter
from matplotlib.lines import Line2D

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'results' / 'full'
OUT = ROOT / 'figures'
OUT.mkdir(exist_ok=True)
BLUE = '#1763A6'
GOLD = '#B47714'
INK = '#243247'
GRAY = '#E4E9EF'
plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 12,
    'axes.labelcolor': INK, 'text.color': INK, 'xtick.color': INK,
    'ytick.color': INK, 'axes.edgecolor': '#93A0AE',
    'axes.spines.top': False, 'axes.spines.right': False,
    'axes.titleweight': 'bold', 'figure.facecolor': 'white',
    'savefig.facecolor': 'white', 'svg.fonttype': 'none'})


def read(name):
    with (DATA / name).open() as f:
        return [{k: float(v) for k, v in r.items()} for r in csv.DictReader(f)]


def exact(N, s, i=1):
    if s == 0:
        return i / N
    return math.expm1(-i * math.log1p(s)) / math.expm1(-N * math.log1p(s))


def save(fig, filename):
    fig.savefig(OUT / filename, dpi=180, bbox_inches='tight', pad_inches=.25)
    plt.close(fig)


rows = read('fixation.csv')
assert len(rows) == 28
for r in rows:
    assert r['estimate'] == r['fixations'] / r['repetitions']
    assert r['lower'] <= r['estimate'] <= r['upper']
    assert math.isclose(r['exact'], exact(int(r['N']), r['s']), rel_tol=1e-12)

# Every saved path is shown, in its original order: no selection of outcomes.
fig, axes = plt.subplots(1, 2, figsize=(11.5, 5.3), sharex=True, sharey=True)
fig.suptitle('The same starting population can have different futures',
             x=.08, ha='left', y=.99, fontsize=19, fontweight='bold')
fig.text(.08, .91, '100 individuals; 10 initially carry allele A. All eight saved runs per condition are shown.', fontsize=11)
for ax, s, filename, label in zip(axes, [0., .1],
        ['trajectory_N100_i10_s0p0.csv', 'trajectory_N100_i10_s0p1.csv'],
        ['No selective advantage (s = 0)', '10% reproductive advantage (s = 0.1)']):
    rr = read(filename)
    t = [r['generation'] for r in rr]
    for i in range(1, 9):
        ax.plot(t, [r[f'path_{i}'] for r in rr], color=BLUE, alpha=.58, lw=1.35)
    ax.plot(t, [r['deterministic'] for r in rr], color=GOLD, ls='--', lw=2.4)
    ax.set(title=label, xlabel='Time (reproduction events / population size)', xlim=(0, 300), ylim=(-.025, 1.025))
    ax.set_xticks([0, 100, 200, 300])
    ax.yaxis.set_major_formatter(PercentFormatter(1))
    ax.grid(axis='y', alpha=.16)
axes[0].set_ylabel('Share of the population carrying allele A')
fig.legend(handles=[Line2D([0],[0],color=BLUE,lw=2,label='Individual stochastic runs'),
    Line2D([0],[0],color=GOLD,ls='--',lw=2.4,label='Deterministic mean-field approximation')],
    loc='lower center',bbox_to_anchor=(.5,.035),ncol=2,frameon=False,fontsize=11)
fig.text(.08, -.015, '0% = allele lost; 100% = allele fixed. The dashed curve is not the exact average of stochastic runs.',fontsize=10)
fig.subplots_adjust(top=.79,bottom=.24,left=.08,right=.99,wspace=.14)
save(fig, 'allele-trajectories.png')

# Analytical probabilities make the small absolute chance of fixation visible.
fig, ax = plt.subplots(figsize=(11.5, 4.8))
fig.suptitle('An advantageous allele can still be lost',x=.08,ha='left',y=.99,fontsize=20,fontweight='bold')
fig.text(.08,.89,'Exact model probabilities: one initial copy of allele A in a population of 100.',fontsize=12)
ss = [0., .01, .1]
ys = [2, 1, 0]
for y, s in zip(ys, ss):
    p = exact(100, s)
    ax.barh(y, p, color=BLUE,height=.35)
    ax.barh(y, 1-p,left=p,color=GRAY,height=.35)
    ax.text(0,y+.26,f'{s:.0%} advantage',fontweight='bold',fontsize=12)
    ax.text(.23,y+.26,f'Fixation: {p:.2%}',color=BLUE,fontweight='bold',fontsize=12)
    ax.text(.64,y+.26,f'Loss: {1-p:.2%}',fontsize=12)
ax.set(xlim=(0,1),ylim=(-.45,2.65),xlabel='Probability of the eventual outcome')
ax.set_yticks([])
ax.xaxis.set_major_formatter(PercentFormatter(1))
ax.spines['left'].set_visible(False)
fig.text(.08,.015,'Fixation means allele A eventually occupies the whole population. Loss means no copies remain.\nCalculated from the exact fixation formula; these bars are not simulation estimates.',fontsize=10,linespacing=1.5)
fig.subplots_adjust(left=.08,right=.99,top=.78,bottom=.22)
save(fig,'fixation-and-loss.png')

# Full parameter grid, with a common scale and the supplied asymmetric intervals.
fig, axes = plt.subplots(2,2,figsize=(11.5,7),sharex=True,sharey=True)
fig.suptitle('Simulations follow the exact fixation prediction',x=.08,ha='left',y=.99,fontsize=20,fontweight='bold')
fig.text(.08,.925,'One initial copy; 20,000 independent runs per point. Bars show 95% Wilson confidence intervals.',fontsize=11)
for ax,N in zip(axes.flat,[20,50,100,200]):
    rr = sorted([r for r in rows if r['N']==N],key=lambda r:r['s'])
    xs = np.linspace(0,.1,300)
    ax.plot(xs,[exact(N,float(s)) for s in xs],color=INK,lw=1.7)
    ax.errorbar([r['s'] for r in rr],[r['estimate'] for r in rr],
        yerr=[[r['estimate']-r['lower'] for r in rr],[r['upper']-r['estimate'] for r in rr]],
        fmt='o',color=BLUE,mec='white',mew=.6,ms=6,capsize=3,lw=1.3)
    ax.set(title=f'Population size N = {N}',xlim=(-.003,.103),ylim=(0,.12))
    ax.set_xticks([0,.02,.05,.1])
    ax.set_yticks([0,.03,.06,.09,.12])
    ax.xaxis.set_major_formatter(PercentFormatter(1,decimals=0))
    ax.yaxis.set_major_formatter(PercentFormatter(1,decimals=0))
    ax.grid(axis='y',alpha=.16)
for ax in axes[1]: ax.set_xlabel('Reproductive advantage (s)')
for ax in axes[:,0]: ax.set_ylabel('Probability of fixation')
fig.legend(handles=[Line2D([0],[0],color=INK,lw=1.7,label='Exact model prediction'),
    Line2D([0],[0],marker='o',color=BLUE,lw=0,label='Simulation estimate (95% interval)')],
    loc='lower center',bbox_to_anchor=(.5,.025),ncol=2,frameon=False,fontsize=11)
fig.text(.08,-.005,'All 28 conditions are retained. One of the 28 nominal 95% intervals misses the exact probability.',fontsize=10)
fig.subplots_adjust(top=.84,bottom=.16,left=.08,right=.99,hspace=.35,wspace=.16)
save(fig,'simulation-vs-exact.png')
print('Rendered three figures from results/full/; validated all 28 estimates and exact probabilities.')
