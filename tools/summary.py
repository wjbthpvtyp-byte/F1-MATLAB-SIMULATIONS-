from all10 import *
from runcase import best
DAY={4:'night',8:'night'}
VB={1:309,2:314,3:216,4:241,5:280,6:153,7:225,8:270,9:306,10:313}
def calib(c,p):
    lo,hi=0.5,90.0
    if real(c,hi)[0]['clip']<c[8]: return hi
    for _ in range(25):
        mid=(lo+hi)/2
        if real(c,mid)[0]['clip']<c[8]: lo=mid
        else: hi=mid
    return (lo+hi)/2
if __name__=="__main__":
  print('%-3s %-14s %6s %6s | %6s %6s %6s %6s | %6s %6s | reb T  S  L'%('#','crash','rec','ang','real','tec','small','large','bestS','bestL'))
  for c in CASES:
      i,n,vi,vb,bt,era,m,a,rec=c
      ang=calib(c,P) if rec else a
      w=weather(DAY.get(i,'dry')); p=dict(P); p.update(tau=w['tau'],cameraOK=w['cam'],v_err=w['verr'])
      car=dict(CARS[era]); car['mass']=m; vn=vi/3.6*np.sin(np.radians(ang))
      Ca=build(car,barrier(bt,w['fs'])); Ct=build(car,barrier('tecpro',w['fs']))
      pl=dict(p); pl['S']=2.5; pl['v_pre']=6
      rs=[sim('passive',vn,car,Ca,p),sim('passive',vn,car,Ct,p),sim('smart',vn,car,Ct,p),sim('smart',vn,car,Ct,pl)]
      KE=0.5*m*vn**2
      print('%-3d %-14s %6s %6.1f | %6.1f %6.1f %6.1f %6.1f | %6.1f %6.1f | %4.1f %4.1f %4.1f'%(i,n,rec,ang,*[r['clip'] for r in rs],best(KE,0.2,Ct)/m/9.81,best(KE,2.5,Ct)/m/9.81,rs[1]['reb'],rs[2]['reb'],rs[3]['reb']))
