# Python mirror of the MATLAB engine in src/, used to cross-check results.
# Not needed to run the MATLAB cases. Requires numpy.
import numpy as np
P=dict(g=9.81,dt=1e-5,tend=0.5,kun=2e7,cdamp=1e5,Fram_max=300e3,ram_stroke=0.95,tau=0.002,S=0.2,ms=100,cs=5e3,kstop=1e8,
 Fmin=80e3,Fmax=600e3,sf=1.0,t_sense=0.015,t_upd=1e-3,vlock=1.5,v_pre=0.0,a_pre=10*9.81,v_err=0.0,cameraOK=True,online=True)
CARS={'2020s':dict(mass=798,d=[0,0.01,0.46],F=[0,360e3,420e3],k=1e7),'1994':dict(mass=610,d=[0,0.01,0.36],F=[0,250e3,300e3],k=1e7)}
def barrier(t,s=1):
    B={'concrete':([0,0.001],[0,0.5e6]),'armco':([0,0.05,0.6],[0,150e3,350e3]),'tyre':([0,0.02,0.7],[0,40e3,300e3]),'tecpro':([0,0.02,1.0],[0,60e3,360e3])}
    d,F=B[t]; F=np.array(F)*(s if t!='concrete' else 1); return dict(d=np.array(d),F=F,k=5e8)
def edepth(F,e):
    F=np.asarray(F,float); d=np.where(F<=e['F'][-1], np.interp(F,e['F'],e['d']), e['d'][-1]+(F-e['F'][-1])/e['k']); return d
def build(car,b):
    Fq=np.linspace(0,3e6,6001); dq=edepth(Fq,b)+edepth(Fq,car)
    return dict(Fq=Fq,dq=dq,k=1/(1/b['k']+1/car['k']))
def crush(d,C):
    if d<=C['dq'][-1]: return float(np.interp(d,C['dq'],C['Fq']))
    return C['Fq'][-1]+C['k']*(d-C['dq'][-1])
def depthAt(F,C):
    if F<=0: return 0.0
    if F>=C['Fq'][-1]: return C['dq'][-1]+(F-C['Fq'][-1])/C['k']
    return float(np.interp(F,C['Fq'],C['dq']))
def absorbed(F,d,rem,R,S,C,p):
    dF=max(depthAt(F,C),d)
    if R:
        rs=p['ram_stroke']; E=F*max(0,min(dF,rs)-d)
        a=max(d,rs)
        if dF>a:
            x=np.linspace(a,dF,25); E+=np.trapezoid([crush(q,C) for q in x],x)
    else:
        x=np.linspace(d,dF,25); E=np.trapezoid([crush(a,C) for a in x],x)
    return E+F*rem*S
def target(KE,d,rem,R,S,C,p):
    lo,hi=p['Fmin'],p['Fmax']
    if absorbed(hi,d,rem,R,S,C,p)<KE: return hi
    for _ in range(30):
        m=(lo+hi)/2
        if absorbed(m,d,rem,R,S,C,p)<KE: lo=m
        else: hi=m
    return hi*p['sf']
def sim(mode,v0,car,C,p):
    dt=p['dt'];mc=car['mass'];ms=p['ms']
    R=mode in('rams','smart');S=mode in('sled','smart')
    if not p['online']: R=S=False
    act=R or S
    t=0;xc=0;vc=v0;xb=0;vb=0;dmax=0;Fr=0;Ft=np.inf
    if act and p['cameraOK']: Ft=target(0.5*mc*(v0*(1+p['v_err']))**2,0,p['S']*S,R,S,C,p)
    tn=p['t_sense'];A=[];X=[];V=[]
    pre = S and act and p['cameraOK'] and p.get('v_pre',0)>0
    if pre:
        tr=p['v_pre']/p['a_pre']; t=-tr-0.005; xc=v0*t   # camera triggers retraction before contact
        while t<0:
            if t>=-tr and vb<p['v_pre']: vb=min(p['v_pre'],vb+p['a_pre']*dt)
            xb+=vb*dt; xc+=vc*dt; t+=dt
    while t<p['tend']:
        d=xc-xb
        if d>0:
            if d>=dmax: dmax=d;Ff=crush(d,C)
            else:
                Ff=max(0,crush(dmax,C)-p['kun']*(dmax-d))
                if Ff>0: Ff=max(0,Ff+p['cdamp']*(vc-vb))
        else: Ff=0
        if act and t>=tn:
            tn+=p['t_upd']
            if vc>0.5: Ft=target(0.5*mc*vc**2,max(d,0),max(p['S']-xb,0)*S,R,S,C,p)
        if R:
            cmd=0
            if np.isfinite(Ft) and d>0 and vc>0 and d<p['ram_stroke']: cmd=min(max(Ft-Ff,0),p['Fram_max'])
            Fr+=(cmd-Fr)*dt/p['tau']
        F=Ff+Fr
        if S:
            Fs=Ft*(mc+ms)/mc
            if vb>0 and vb<vc-p['vlock']: Fs=0.0   # let sled catch up with car
            Fst=p['kstop']*(xb-p['S']) if xb>p['S'] else 0
            if pre and d<=0 and vb>0: xb+=vb*dt          # actuator holds retraction speed until contact
            elif vb<=0 and F<=Fs and Fst==0: vb=0
            else:
                vb+=(F-Fs-p['cs']*(vb-vc)-Fst)/ms*dt
                if vb<0: vb=0
                xb+=vb*dt
        ac=-F/mc; vc+=ac*dt; xc+=vc*dt; t+=dt
        A.append(-ac/p['g']); X.append(xc); V.append(vc)
        if vc<=0 and F<1: break
    A=np.array(A); n=300
    clip=np.convolve(A,np.ones(n)/n,'valid').max() if len(A)>n else A.max()
    return dict(clip=clip,stop=max(X),reb=max(0,-min(V))*3.6,a=A)
def weather(key):
    c=dict(grip=1,T=20,cam=True,verr=0)
    c.update({'dry':{},'light_rain':dict(grip=0.75,T=15,verr=0.1),'heavy_rain':dict(grip=0.55,T=12,cam=False),
      'cold':dict(T=5),'hot':dict(T=40),'sun_glare':dict(verr=0.2),'worst':dict(grip=0.55,T=5,cam=False)}[key])
    c['fs']=1-0.006*(c['T']-20); c['tau']=0.002*(1+0.04*max(0,20-c['T'])); return c
def four(crash,carkey,wkey,ang):
    c=weather(wkey); p=dict(P); p.update(tau=c['tau'],cameraOK=c['cam'],v_err=c['verr'])
    vb,vr,rg=crash['vb'],crash['vr'],crash['rg']
    vi=np.sqrt(max(vb**2-(c['grip']/rg)*(vb**2-vr**2),0)); vn=vi/3.6*np.sin(np.radians(ang))
    car=CARS[carkey]; Ca=build(car,barrier(crash['bt'],c['fs'])); Ct=build(car,barrier('tecpro',c['fs']))
    po=dict(p); po['online']=False
    return vi,vn,{'actual':sim('passive',vn,car,Ca,p),'tecpro':sim('passive',vn,car,Ct,p),'smart':sim('smart',vn,car,Ct,p),'failed':sim('smart',vn,car,Ct,po)}
