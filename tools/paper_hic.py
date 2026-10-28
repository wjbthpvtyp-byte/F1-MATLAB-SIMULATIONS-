import json, numpy as np
exec(open(__import__('os').path.join(__import__('os').path.dirname(__file__),'verify_paper_numbers.py')).read().split('res=[]')[0])
def hic15(a,dt=1e-5):
    t=np.arange(len(a))*dt; tc=np.arange(0,t[-1],1e-4); ac=np.maximum(np.interp(tc,t,a),0)
    I=np.concatenate([[0],np.cumsum(ac)*1e-4]); H=0
    for w in range(1,min(150,len(I)-1)+1):
        T=w*1e-4; avg=(I[w:]-I[:-w])/T; H=max(H,(T*avg**2.5).max())
    return H
R=json.load(open(__import__('os').path.join(__import__('os').path.dirname(__file__),'..','results','paper_numbers.json'))); out={}
for c,r in zip(CASES,R):
    W,p,v,car=setup(c,c[9]); vn=v/3.6*np.sin(np.radians(r['angle']))
    Ca=build(car,barrierX(c[4],W['fs'])); Ct=build(car,barrierX('tecpro',W['fs'])); pl=dict(p); pl['S']=2.5; pl['v_pre']=6
    h={k:hic15(sim(mo,vn,car,C,pp)['a']) for k,(mo,C,pp) in {'real':('passive',Ca,p),'tecpro':('passive',Ct,p),'small':('smart',Ct,p),'large':('smart',Ct,pl)}.items()}
    out[c[1]]=h; print('%-20s real %8.0f tec %7.0f small %7.0f large %6.0f'%(c[1],h['real'],h['tecpro'],h['small'],h['large']))
json.dump(out,open(__import__('os').path.join(__import__('os').path.dirname(__file__),'..','results','hic_realday.json'),'w'))
