import json, numpy as np
exec(open(__import__('os').path.join(__import__('os').path.dirname(__file__),'verify_paper_numbers.py')).read().split('res=[]')[0])
R=json.load(open(__import__('os').path.join(__import__('os').path.dirname(__file__),'..','results','paper_numbers.json')))
res={}
for ms in (100,250,400):
    rs=[];rl=[];reb=[];cmpS=[];cmpL=[]
    for c,r in zip(CASES,R):
        if c[0] in (2,13): continue
        W,p,v,car=setup(c,c[9]); vn=v/3.6*np.sin(np.radians(r['angle'])); Ct=build(car,barrierX('tecpro',W['fs']))
        q=dict(p); q['ms']=ms; x=sim('smart',vn,car,Ct,q); ql=dict(q); ql['S']=2.5; ql['v_pre']=6; y=sim('smart',vn,car,Ct,ql)
        d=r['realday']
        rs.append(100*(1-x['clip']/d['tecpro'])); rl.append(100*(1-y['clip']/d['tecpro']))
        reb.append(100*(1-x['reb']/d['tecpro_reb'])); cmpS.append(x['clip']<d['deepS']); cmpL.append(y['clip']<d['deepL'])
    print('ms %d: small median %.1f (%.1f-%.1f) | large median %.1f (%.1f-%.1f) | rebound median %.0f%% | small<deep1.2 %d/13 large<deep3.5 %d/13'%(ms,np.median(rs),min(rs),max(rs),np.median(rl),min(rl),max(rl),np.median(reb),sum(cmpS),sum(cmpL)))
