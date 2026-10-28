"""Draw Figure 2 (Grosjean 2020 deceleration time histories) and Figure 3 (breakpoint curves).
Data come from paper_figures/data/, made by tools/paper_figure_data.py.
Run from anywhere:  python3 paper_figures/make_figs.py
"""
import os
HERE=os.path.dirname(os.path.abspath(__file__))
DATA=os.path.join(HERE,'data')
import json, numpy as np, matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':10,'axes.spines.top':False,'axes.spines.right':False,
                     'axes.edgecolor':'#555','axes.labelcolor':'#222','xtick.color':'#444','ytick.color':'#444'})
INK='#222'; MUTED='#666'; GRID='#e4e4e0'
GRAY='#4d4d4d'; ORANGE='#eb6834'; BLUE='#2a78d6'; RED='#e34948'

# ---------- Figure: deceleration time histories, Grosjean 2020 ----------
d=json.load(open(os.path.join(DATA,'grosjean_th.json')))
fig,ax=plt.subplots(figsize=(6.5,3.6),dpi=300)
spec=[('real','Real barrier (triple guardrail)',RED,'-'),('tecpro','Standard TecPro',GRAY,'-'),
      ('small','Small system (+0.20 m)',ORANGE,'-'),('large','Large system (+2.5 m)',BLUE,'-')]
for k,lab,col,ls in spec:
    a=np.array(d[k]['a']); t=np.arange(len(a))*d[k]['dt']*1e3
    ax.plot(t,a,ls,color=col,lw=1.8,label=lab,solid_capstyle='round')
    i=int(np.argmax(a))
    ax.annotate('%.1f g'%d[k]['clip'],(t[i],a[i]),xytext=(4,4),textcoords='offset points',fontsize=8.5,color=INK)
ax.set_xlabel('Time after first contact (ms)'); ax.set_ylabel('Car deceleration (g)')
ax.set_xlim(0,220); ax.set_ylim(0,75)
ax.grid(axis='y',color=GRID,lw=0.8); ax.set_axisbelow(True)
ax.legend(frameon=False,fontsize=8.5,loc='upper right')
fig.tight_layout(); fig.savefig(os.path.join(HERE,'Figure_deceleration_Grosjean2020.png')); plt.close(fig)

# ---------- Figure: breakpoint curves ----------
rows=json.load(open(os.path.join(DATA,'curves_fine.json')))
E=np.array([r['kJ'] for r in rows])
cfg=[('tecpro','Standard TecPro, 1.0 m',GRAY,'-'),('deep12','Passive TecPro, 1.2 m',ORANGE,(0,(4,2))),
     ('small','Small system, 1.2 m',ORANGE,'-'),('deep35','Passive TecPro, 3.5 m',BLUE,(0,(4,2))),
     ('large','Large system, 3.5 m',BLUE,'-')]
fig,ax=plt.subplots(figsize=(6.5,4.0),dpi=300)
for k,lab,col,ls in cfg:
    ax.plot(E,[r[k] for r in rows],linestyle=ls,color=col,lw=1.8,label=lab)
for g in (40,67):
    ax.axhline(g,color=MUTED,lw=0.9,ls=':')
    ax.text(1995,g*1.06,'%d g'%g,ha='right',va='bottom',fontsize=8.5,color=MUTED)
ax.set_yscale('log'); ax.set_ylim(5,1500); ax.set_xlim(0,2000)
ax.set_yticks([5,10,20,40,67,100,200,500,1000]); ax.set_yticklabels(['5','10','20','40','67','100','200','500','1000'])
ax.set_xlabel('Normal impact energy (kJ), 798 kg car'); ax.set_ylabel('Peak deceleration, 3 ms clip (g)')
ax.grid(axis='y',color=GRID,lw=0.8,which='major'); ax.set_axisbelow(True)
ax.legend(frameon=False,fontsize=8.5,loc='lower right',ncol=1)
fig.tight_layout(); fig.savefig(os.path.join(HERE,'Figure_breakpoint_curves.png')); plt.close(fig)
print('ok')
