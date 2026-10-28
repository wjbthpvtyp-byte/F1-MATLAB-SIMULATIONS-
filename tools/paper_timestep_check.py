"""Time-step convergence check: re-runs every case's TecPro, small-system and large-system
impacts at 20, 10 (the step used in the paper) and 5 microseconds and reports how much the
3 ms peak deceleration changes.
Run:  python3 tools/paper_timestep_check.py   (needs results/paper_numbers.json)
"""
import json, os, numpy as np
HERE=os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE,'verify_paper_numbers.py')).read().split('res=[]')[0])
R=json.load(open(os.path.join(HERE,'..','results','paper_numbers.json')))
def clip(A,dt):
    n=int(round(0.003/dt)); return np.convolve(A,np.ones(n)/n,'valid').max()
worst=0; rows=[]
for c,r in zip(CASES,R):
    W,p,v,car=setup(c,c[9]); m=car['mass']; vn=v/3.6*np.sin(np.radians(r['angle']))
    Ct=build(car,barrierX('tecpro',W['fs']))
    pl=dict(p); pl['S']=2.5; pl['v_pre']=6
    for name,mode,pp in [('tecpro','passive',p),('small','smart',p),('large','smart',pl)]:
        g={}
        for dt in [2e-5,1e-5,5e-6]:
            q=dict(pp); q['dt']=dt; x=sim(mode,vn,car,Ct,q); g[dt]=clip(x['a'],dt)
        d1=abs(g[5e-6]-g[1e-5])/g[1e-5]*100; d2=abs(g[2e-5]-g[1e-5])/g[1e-5]*100
        rows.append((c[1],name,g[2e-5],g[1e-5],g[5e-6],d2,d1)); worst=max(worst,d1)
for x in rows: print('%-20s %-6s 20us %8.3f 10us %8.3f 5us %8.3f | d20 %.3f%% d5 %.3f%%'%x)
print('max change 10->5 us: %.4f%%'%worst, ' max 10->20: %.4f%%'%max(x[5] for x in rows))
