from eng import *
import sys
def best(KE,S,C):
    q=dict(P); q.update(Fmax=2e7,Fmin=1,sf=1,ram_stroke=np.inf); return target(KE,0,S,True,S>0,C,q)
def run(cr,w,ang):
    c=weather(w); p=dict(P); p.update(tau=c['tau'],cameraOK=c['cam'],v_err=c['verr'])
    vi=np.sqrt(max(cr['vb']**2-(c['grip']/1.0)*(cr['vb']**2-cr['vr']**2),0)); vn=vi/3.6*np.sin(np.radians(ang))
    car=dict(CARS['1994']); car['mass']=cr['m']
    Ca=build(car,barrier('concrete')); Ct=build(car,barrier('tecpro',c['fs']))
    pl=dict(p); pl['S']=2.5; pl['v_pre']=6; po=dict(p); po['online']=False
    r={'real':sim('passive',vn,car,Ca,p),'tecpro':sim('passive',vn,car,Ct,p),'small':sim('smart',vn,car,Ct,p),'large':sim('smart',vn,car,Ct,pl),'fs':sim('smart',vn,car,Ct,po)}
    KE=0.5*cr['m']*vn**2
    return vi,KE,r,best(KE,0.2,Ct)/cr['m']/9.81,best(KE,2.5,Ct)/cr['m']/9.81
if __name__=="__main__":
  for cr,ang in [(dict(vb=309,vr=211,m=610),25),(dict(vb=314,vr=314,m=590),60)]:
      print('=== case',cr,ang)
      for w in ['dry','light_rain','heavy_rain','cold','hot','sun_glare','worst']:
          vi,KE,r,bs,bl=run(cr,w,ang)
          print('%-11s v%3.0f KE%5.0f'%(w,vi,KE/1e3),' '.join('%s %.1fg/%.2fm/rb%.1f'%(k,v['clip'],v['stop'],v['reb']) for k,v in r.items()),'best %.1f %.1f'%(bs,bl))
