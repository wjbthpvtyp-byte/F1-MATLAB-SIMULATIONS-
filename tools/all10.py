from eng import *
CASES=[
 (1,'Senna',211,309,'concrete','1994',610,25,None),
 (2,'Ratzenberger',314,314,'concrete','1994',590,60,None),
 (3,'Hubert',216,216,'tyre','2020s',720,40,33.7),
 (4,'Grosjean',192,241,'armco','2020s',846,29,67),
 (5,'Kubica',232,280,'concrete','2000s',655,45,75),
 (6,'Sainz',153,153,'tecpro','2020s',732,80,46),
 (7,'Barrichello',225,225,'tyre','1994',610,45,95),
 (8,'MSchumacher22',270,270,'concrete','2020s',813,15,33),
 (9,'Schumacher99',107,306,'tyre','2000s',670,80,None),
 (10,'Alonso',305,313,'concrete','2020s',772,20,45),
]
def real(c,ang=None):
    i,n,vi,vb,bt,era,m,a,rec=c; ang=a if ang is None else ang
    car=dict(CARS[era]); car['mass']=m; vn=vi/3.6*np.sin(np.radians(ang))
    C=build(car,barrier(bt)); return sim('passive',vn,car,C,dict(P)),vn
if __name__=='__main__':
    for c in CASES:
        r,vn=real(c); print('%2d %-14s vn %5.1f  model %6.1f g   recorded %s'%(c[0],c[1],vn,r['clip'],c[8]))
