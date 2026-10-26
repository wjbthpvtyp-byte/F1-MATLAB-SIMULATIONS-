"""Authoritative re-computation of every number in the paper, mirroring the MATLAB pipeline
(runCaseStudy -> calibrateAngle under the real-day condition -> runScenarios)."""
import sys, json, numpy as np
import os
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from python_reference_engine import P, CARS, barrier, build, sim, weather, target
CARS['cart1990s']=dict(mass=800,d=[0,0.10,0.45],F=[0,280e3,380e3],k=1e7)
CARS['1973']=dict(mass=650,d=[0,0.05,0.25],F=[0,150e3,220e3],k=1e7)
CARS['stockcar']=dict(mass=1600,d=[0,0.15,0.60],F=[0,350e3,550e3],k=1e7)
def barrierX(t,fs=1,L=1.0):
    if t=='tecpro': return dict(d=np.array([0,0.02,1.0])*L,F=np.array([0,60e3,360e3])*fs,k=5e8)
    return barrier(t,fs)
# id, name, vImpact, vBrake, barrier, era, mass, nominal angle, recordedG, dayCond
CASES=[(1,'Senna 1994',211,309,'concrete','1994',610,25,None,'dry'),
 (2,'Ratzenberger 1994',314,314,'concrete','1994',590,60,None,'dry'),
 (3,'Hubert 2019',216,262,'tyre','2020s',720,40,33.7,'dry'),
 (4,'Grosjean 2020',192,241,'armco','2020s',846,29,67,'night'),
 (5,'Kubica 2007',232,280,'concrete','2000s',655,45,75,'dry'),
 (6,'Sainz 2015',153,204,'tecpro','2020s',732,80,42,'dry'),
 (7,'Barrichello 1994',225,225,'tyre','1994',610,45,95,'dry'),
 (8,'M. Schumacher 2022',270,270,'concrete','2020s',813,15,33,'night'),
 (9,'Schumacher 1999',107,306,'tyre','2000s',670,80,None,'dry'),
 (10,'Alonso 2016',305,313,'concrete','2020s',772,20,45,'dry'),
 (11,'Moore 1999',350,350,'concrete','cart1990s',800,30,154,'dry'),
 (12,'Brayton 1996',370,370,'concrete','cart1990s',780,20,None,'dry'),
 (13,'Cevert 1973',241,241,'armco','1973',650,80,None,'dry'),
 (14,'Rodriguez 1999',250,250,'tyre','cart1990s',780,60,150,'dry'),
 (15,'Earnhardt 2001',256,256,'concrete','stockcar',1600,13.6,58,'dry')]
CONDS=['dry','light_rain','heavy_rain','cold','hot','sun_glare','night','worst']
def setup(c,w):
    i,n,vi,vb,bt,era,m,a,rec,day=c
    W=weather(w); p=dict(P); p.update(tau=W['tau'],cameraOK=W['cam'],v_err=W['verr'])
    v=np.sqrt(max(vb**2-W['grip']*(vb**2-vi**2),0))
    car=dict(CARS[era]); car['mass']=m
    return W,p,v,car
def calib(c):
    i,n,vi,vb,bt,era,m,a,rec,day=c
    W,p,v,car=setup(c,day); C=build(car,barrierX(bt,W['fs']))
    g=lambda ang: sim('passive',v/3.6*np.sin(np.radians(ang)),car,C,p)['clip']
    lo,hi=0.5,90.0
    if g(hi)<rec: return hi
    for _ in range(25):
        mid=(lo+hi)/2
        if g(mid)<rec: lo=mid
        else: hi=mid
    return (lo+hi)/2
def best(KE,S,C):
    q=dict(P); q.update(Fmax=2e7,Fmin=1,sf=1,ram_stroke=np.inf)
    return target(KE,0,S,True,S>0,C,q)
def scen(c,w,ang):
    W,p,v,car=setup(c,w); m=car['mass']; vn=v/3.6*np.sin(np.radians(ang))
    Ca=build(car,barrierX(c[4],W['fs'])); Ct=build(car,barrierX('tecpro',W['fs']))
    Cs=build(car,barrierX('tecpro',W['fs'],1.2)); Cl=build(car,barrierX('tecpro',W['fs'],3.5))
    pl=dict(p); pl['S']=2.5; pl['v_pre']=6; po=dict(p); po['online']=False
    r=dict(real=sim('passive',vn,car,Ca,p),tecpro=sim('passive',vn,car,Ct,p),small=sim('smart',vn,car,Ct,p),
           large=sim('smart',vn,car,Ct,pl),failsafe=sim('smart',vn,car,Ct,po),
           deepS=sim('passive',vn,car,Cs,p),deepL=sim('passive',vn,car,Cl,p))
    KE=0.5*m*vn**2
    out=dict(v=v,vn=vn,KE=KE/1e3,bestS=best(KE,0.2,Ct)/m/9.81,bestL=best(KE,2.5,Ct)/m/9.81)
    for k,x in r.items():
        out[k]=float(x['clip']); out[k+'_reb']=float(x['reb']); out[k+'_stop']=float(x['stop'])
        out[k+'_Fmax_kN']=float(x['a'].max()*m*9.81/1e3); out[k+'_F3_kN']=float(x['clip']*m*9.81/1e3)
    return out
res=[]
for c in CASES:
    ang=calib(c) if c[8] else c[7]
    row=dict(id=c[0],name=c[1],angle=ang,day=c[9],rec=c[8])
    row['conds']={w:scen(c,w,ang) for w in CONDS}
    row['realday']=scen(c,c[9],ang)
    res.append(row); print(c[1],'angle %.2f'%ang, flush=True)
json.dump(res,open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','results','paper_numbers.json'),'w'),indent=1)
