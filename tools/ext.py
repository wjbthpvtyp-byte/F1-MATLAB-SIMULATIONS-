from all10 import *
import numpy as np
CARS['cart1990s']=dict(mass=800,d=[0,0.10,0.45],F=[0,280e3,380e3],k=1e7)
CARS['1973']=dict(mass=650,d=[0,0.05,0.25],F=[0,150e3,220e3],k=1e7)
CARS['stockcar']=dict(mass=1600,d=[0,0.15,0.60],F=[0,350e3,550e3],k=1e7)
def barrierD(t,s=1,L=1.0):
    if t=='tecpro_deep': return dict(d=np.array([0,0.02*L,L]),F=np.array([0,60e3,360e3])*s,k=5e8)
    return barrier(t,s)
NEW=[ # id,name,vi,vb,bt,era,m,nominal ang,rec
 (11,'Moore1999',350,350,'concrete','cart1990s',800,90,154),
 (12,'Brayton1996',370,370,'concrete','cart1990s',780,20,None),
 (13,'Cevert1973',241,241,'armco','1973',650,80,None),
 (14,'Rodriguez1999',250,250,'tyre','cart1990s',780,60,150),
 (15,'Earnhardt2001',256,256,'concrete','stockcar',1600,13.6,58),
]
def realC(c,ang):
    i,n,vi,vb,bt,era,m,a,rec=c
    car=dict(CARS[era]); car['mass']=m; vn=vi/3.6*np.sin(np.radians(ang))
    return sim('passive',vn,car,build(car,barrier(bt)),dict(P)),vn
def calibC(c):
    lo,hi=0.5,90.0
    if realC(c,hi)[0]['clip']<c[8]: return hi
    for _ in range(25):
        mid=(lo+hi)/2
        if realC(c,mid)[0]['clip']<c[8]: lo=mid
        else: hi=mid
    return (lo+hi)/2
def runall(c,w='dry',ang=None):
    i,n,vi,vb,bt,era,m,a,rec=c
    if ang is None: ang=calibC(c) if rec else a
    W=weather(w); p=dict(P); p.update(tau=W['tau'],cameraOK=W['cam'],v_err=W['verr'])
    v=np.sqrt(max(vb**2-W['grip']*(vb**2-vi**2),0)); vn=v/3.6*np.sin(np.radians(ang))
    car=dict(CARS[era]); car['mass']=m
    Ca=build(car,barrier(bt,W['fs'])); Ct=build(car,barrier('tecpro',W['fs']))
    C12=build(car,barrierD('tecpro_deep',W['fs'],1.2)); C35=build(car,barrierD('tecpro_deep',W['fs'],3.5))
    pl=dict(p); pl['S']=2.5; pl['v_pre']=6
    r=dict(real=sim('passive',vn,car,Ca,p),tecpro=sim('passive',vn,car,Ct,p),deep12=sim('passive',vn,car,C12,p),
           small=sim('smart',vn,car,Ct,p),deep35=sim('passive',vn,car,C35,p),large=sim('smart',vn,car,Ct,pl))
    return ang,vn,r
if __name__=='__main__':
    print('%-14s %5s %5s | %7s %7s %7s %7s %7s %7s'%('crash','ang','vn','real','tecpro','deep1.2','small','deep3.5','large'))
    for c in NEW:
        ang,vn,r=runall(c)
        print('%-14s %5.1f %5.1f | '%(c[1],ang,vn)+' '.join('%7.1f'%r[k]['clip'] for k in ['real','tecpro','deep12','small','deep35','large']))
