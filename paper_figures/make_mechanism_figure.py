"""Draw Figure 1, the schematic of the adaptive barrier (plan view and parts).
Run from anywhere:  python3 paper_figures/make_mechanism_figure.py
"""
import os
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, FancyBboxPatch, Circle, FancyArrowPatch, Polygon
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':8.5})
INK='#222'; MUT='#666'; ORANGE='#eb6834'; BLUE='#2a78d6'; GRAY='#8a8a86'; FOAM='#f3d9a4'; STEEL='#b9c2cc'
fig=plt.figure(figsize=(7.2,3.5),dpi=300)
ax=fig.add_axes([0.0,0.02,0.64,0.96]); ax.set_xlim(-2.35,2.55); ax.set_ylim(-0.55,2.25); ax.axis('off'); ax.set_aspect('equal')
ax.add_patch(Rectangle((-2.35,-0.55),4.9,0.35,color='#ecebe6',lw=0)); ax.plot([-2.35,2.55],[-0.2,-0.2],color=MUT,lw=0.8)
# car
car=Polygon([[-2.0,-0.2],[-2.0,0.10],[-1.55,0.14],[-1.32,0.30],[-0.98,0.30],[-0.84,0.16],[-0.45,0.12],[-0.45,-0.2]],closed=True,fc='#d8d8d4',ec=INK,lw=0.9)
ax.add_patch(car); ax.add_patch(Circle((-1.75,-0.12),0.1,fc=INK)); ax.add_patch(Circle((-0.65,-0.12),0.1,fc=INK))
ax.add_patch(FancyArrowPatch((-1.4,0.52),(-0.55,0.52),arrowstyle='-|>',mutation_scale=10,color=INK,lw=1.2))
ax.text(-0.97,0.59,'$v_n$',ha='center',fontsize=9)
# camera
ax.plot([-2.2,-2.2],[-0.2,1.62],color=GRAY,lw=1.5); ax.add_patch(Rectangle((-2.3,1.62),0.28,0.15,fc=INK))
ax.plot([-2.02,-1.62],[1.66,0.36],ls=(0,(3,2)),color=MUT,lw=0.8)
# controller
ax.add_patch(FancyBboxPatch((-1.25,1.72),1.6,0.32,boxstyle='round,pad=0.03',fc='white',ec=INK,lw=0.9))
ax.text(-0.45,1.88,'Controller',ha='center',va='center',fontsize=8)
ax.plot([-2.02,-1.28],[1.72,1.85],ls=(0,(3,2)),color=MUT,lw=0.8)
# face panel, TecPro
ax.add_patch(Rectangle((0.0,-0.18),0.05,1.18,fc=INK))
ax.add_patch(Rectangle((0.05,0.0),1.0,1.0,fc=FOAM,ec=INK,lw=0.9,hatch='////'))
# ram (dashed = between stacks)
ax.add_patch(Rectangle((0.32,0.36),0.73,0.2,fc='white',ec=ORANGE,lw=1.3,ls='--'))
ax.plot([0.05,0.32],[0.46,0.46],color=ORANGE,lw=2.2)
# sled deck, rails, cylinder, beam
ax.add_patch(Rectangle((0.0,-0.13),1.18,0.11,fc=STEEL,ec=INK,lw=0.9))
for x in (0.2,0.95): ax.add_patch(Circle((x,-0.165),0.035,fc=INK))
ax.add_patch(Rectangle((1.18,-0.11),0.06,0.07,fc=INK)); ax.add_patch(Rectangle((1.24,-0.12),0.42,0.09,fc=BLUE,ec=INK,lw=0.8))
ax.add_patch(Rectangle((1.66,-0.2),0.16,1.05,fc='#55555a',ec=INK,lw=0.8))
ax.annotate('',xy=(1.66,1.12),xytext=(1.18,1.12),arrowprops=dict(arrowstyle='<->',color=INK,lw=0.9))
ax.plot([1.18,1.18],[-0.02,1.18],color=INK,lw=0.5,ls=':')
ax.text(1.42,1.17,'+0.20 m',ha='center',va='bottom',fontsize=8,fontweight='bold')
# guardrail
ax.plot([2.25,2.25],[-0.2,0.85],color=GRAY,lw=2); ax.add_patch(Rectangle((2.2,0.5),0.1,0.28,fc=GRAY))
# control lines
ax.add_patch(FancyArrowPatch((0.2,1.72),(0.68,0.58),arrowstyle='-|>',mutation_scale=8,color=ORANGE,lw=0.9,ls='--'))
ax.add_patch(FancyArrowPatch((0.33,1.80),(1.45,-0.01),arrowstyle='-|>',mutation_scale=8,color=BLUE,lw=0.9,ls='--',connectionstyle='arc3,rad=-0.25'))
# numbered callouts
def call(n,x,y):
    ax.add_patch(Circle((x,y),0.1,fc='white',ec=INK,lw=0.8,zorder=5)); ax.text(x,y,str(n),ha='center',va='center',fontsize=7.5,zorder=6,fontweight='bold')
call(1,-2.16,1.98); call(2,-1.42,1.88); call(3,0.25,0.8); call(4,0.86,0.46)
call(5,0.6,-0.36); call(6,1.45,-0.36); call(7,1.74,1.0); call(8,2.25,1.0)
ax.plot([0.6,0.6],[-0.26,-0.13],color=INK,lw=0.6); ax.plot([1.45,1.45],[-0.26,-0.12],color=INK,lw=0.6)
# legend
items=[('1','Trackside camera + ML model: speed estimate before contact'),
       ('2','Controller: lowest constant force that stops the car; on-board sensors take over at 15 ms'),
       ('3','Standard TecPro stack, unchanged (1.0 m deep)'),
       ('4','Parallel hydraulic rams between stacks: 300 kN, 0.95 m stroke, compression only'),
       ('5','Sled deck on rails (20 mm S355 steel)'),
       ('6','Sled cylinders with relief valves: cap the force; 0.18 m stroke + 0.02 m rebound reserve'),
       ('7','Reaction beam anchored to the foundation'),
       ('8','Existing guardrail, kept as secondary containment')]
y=0.93
for n,t in items:
    fig.text(0.655,y,n,fontsize=7.5,fontweight='bold',va='top'); 
    import textwrap
    w=textwrap.fill(t,40); fig.text(0.675,y,w,fontsize=7.0,va='top',linespacing=1.15)
    y-=0.035*(w.count('\n')+1)+0.035
fig.text(0.655,y-0.01,'Fail-safe: rams fail open and the sled\nlocks, leaving standard TecPro.',fontsize=7.2,va='top',style='italic',color=MUT)
fig.savefig(os.path.join(os.path.dirname(os.path.abspath(__file__)),'Figure_mechanism.png')); print('ok')
