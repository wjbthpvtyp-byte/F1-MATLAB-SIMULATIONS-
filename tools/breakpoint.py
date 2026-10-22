from ext import *
import numpy as np, json
car=dict(CARS['2020s']); car['mass']=798
Ct=build(car,barrier('tecpro')); C12=build(car,barrierD('tecpro_deep',1,1.2)); C35=build(car,barrierD('tecpro_deep',1,3.5))
def cfg(name,vn):
    p=dict(P)
    if name=='tecpro': return sim('passive',vn,car,Ct,p)
    if name=='deep12': return sim('passive',vn,car,C12,p)
    if name=='small': return sim('smart',vn,car,Ct,p)
    if name=='deep35': return sim('passive',vn,car,C35,p)
    if name=='large': p['S']=2.5; p['v_pre']=6; return sim('smart',vn,car,Ct,p)
names=['tecpro','deep12','small','deep35','large']
if __name__=="__main__":
    grid=[]
    k=0
    for v in [150,200,250,300,350]:
        for a in [20,45,90]:
            k+=1; vn=v/3.6*np.sin(np.radians(a))
            r={n:cfg(n,vn) for n in names}
            grid.append(dict(id=k,v=v,a=a,vn=vn,KE=0.5*798*vn**2/1e3,**{n:r[n]['clip'] for n in names},**{n+'_stop':r[n]['stop'] for n in names}))
            print('H%02d %3d km/h %2d deg vn %5.1f KE %6.0f kJ | '%(k,v,a,vn,0.5*798*vn**2/1e3)+' '.join('%s %6.1f'%(n,r[n]['clip']) for n in names))
    def bp(name,G):
        lo,hi=1.0,120.0
        if cfg(name,hi)['clip']<G: return hi
        for _ in range(22):
            m=(lo+hi)/2
            if cfg(name,m)['clip']<G: lo=m
            else: hi=m
        return (lo+hi)/2
    res={}
    for G in [40,67]:
        for n in names:
            vn=bp(n,G); res[(n,G)]=vn
            print('breakpoint %2d g %-7s vn %5.1f m/s  KE %6.0f kJ'%(G,n,vn,0.5*798*vn**2/1e3))
    json.dump(dict(grid=grid,bp={f'{n}_{G}':v for (n,G),v in res.items()}),open('breakpoint.json','w'))
