import json, numpy as np
exec(open(__import__('os').path.join(__import__('os').path.dirname(__file__),'verify_paper_numbers.py')).read().split('res=[]')[0])
sw={1:(10,45,2.5),2:(20,90,5),3:(5,60,5),4:(10,60,5),5:(5,60,5),6:(10,90,5),7:(5,60,5),8:(2,30,2),9:(30,90,5),10:(2,30,2),11:(5,60,5),12:(5,40,2.5),13:(30,90,5),14:(5,60,5),15:(4,30,2)}
out={}
for c in CASES:
    a0,a1,st=sw[c[0]]; rows=[]
    for ang in np.arange(a0,a1+1e-9,st):
        o=scen(c,c[9],float(ang)); rows.append(dict(ang=float(ang),**{k:o[k] for k in ('KE','tecpro','small','large','deepS','deepL','bestS')}))
    out[c[1]]=rows
    r=rows; print(c[1], 'small<tec all:',all(x['small']<x['tecpro'] for x in r),'small<deepS all:',all(x['small']<x['deepS'] for x in r),'large<deepL all:',all(x['large']<x['deepL'] for x in r), 'min red %.1f'%min(100*(1-x['small']/x['tecpro']) for x in r), flush=True)
json.dump(out,open(__import__('os').path.join(__import__('os').path.dirname(__file__),'..','results','angle_sweeps.json'),'w'))
