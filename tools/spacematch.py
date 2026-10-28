from ext import *
from summary import DAY
ALL=[(c[0],c[1],c[2],{1:309,2:314,3:216,4:241,5:280,6:153,7:225,8:270,9:306,10:313}[c[0]],*c[4:]) for c in CASES]+NEW
conds=['dry','light_rain','heavy_rain','cold','hot','sun_glare','night','worst']
rows=[]
for c in ALL:
    ang=calibC(c) if c[8] else c[7]
    for w in conds:
        _,vn,r=runall(c,w,ang)
        rows.append((c[0],c[1],w,ang,vn,*[r[k]['clip'] for k in ['real','tecpro','deep12','small','deep35','large']],r['tecpro']['reb'],r['deep35']['reb'],r['small']['reb'],r['large']['reb']))
import json; json.dump(rows,open(__import__('os').path.join(__import__('os').path.dirname(__import__('os').path.abspath(__file__)),'..','results','spacematch.json'),'w'))
day={1:'dry',4:'night',8:'night'}
print('REAL DAY')
for r in rows:
    if r[2]==day.get(r[0],'dry'):
        print('%2d %-14s ang %5.1f | real %6.1f tec %6.1f d1.2 %6.1f small %6.1f | d3.5 %6.1f large %6.1f | reb tec %.1f d3.5 %.1f small %.1f large %.1f'%(r[0],r[1],r[3],*r[5:11],*r[11:]))
s=[r for r in rows]
print('small < deep1.2 in %d/%d runs'%(sum(r[8]<r[7] for r in s),len(s)))
print('large < deep3.5 in %d/%d runs'%(sum(r[10]<r[9] for r in s),len(s)))
for r in s:
    if r[10]>=r[9] or r[8]>=r[7]: print('EXCEPTION',r[1],r[2],'small %.1f d1.2 %.1f large %.1f d3.5 %.1f'%(r[8],r[7],r[10],r[9]))
