"""Print every summary statistic quoted in the paper (Tables 1-4, medians, ranges, rebound,
fail-safe check, design load) from results/paper_numbers.json.
Run:  python3 tools/verify_paper_numbers.py   (writes results/paper_numbers.json, ~1 min)
then: python3 tools/paper_stats.py
Cases 2 (Ratzenberger) and 13 (Cevert) are excluded from the medians, as in the paper.
"""
import json, os, numpy as np
R=json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','results','paper_numbers.json')))
print('TABLE 1 (real day)')
for r in R:
    d=r['realday']
    print('%2d %-20s ang %5.2f vn %5.1f KE %6.0f | real %6.1f tec %6.1f small %6.1f bestS %5.1f large %6.1f bestL %5.1f | d1.2 %6.1f d3.5 %6.1f | reb tec %5.2f small %5.2f large %5.2f | fs %6.1f'%(
      r['id'],r['name'],r['angle'],d['vn'],d['KE'],d['real'],d['tecpro'],d['small'],d['bestS'],d['large'],d['bestL'],d['deepS'],d['deepL'],d['tecpro_reb'],d['small_reb'],d['large_reb'],d['failsafe']))
ok=[r for r in R if r['id'] not in (2,13)]
f=lambda key: [r['realday'][key] for r in ok]
rs=[100*(1-r['realday']['small']/r['realday']['tecpro']) for r in ok]
rl=[100*(1-r['realday']['large']/r['realday']['tecpro']) for r in ok]
print('\nreal-day small vs tec: median %.1f min %.1f max %.1f'%(np.median(rs),min(rs),max(rs)))
print('real-day large vs tec: median %.1f min %.1f max %.1f'%(np.median(rl),min(rl),max(rl)))
gs=[r['realday']['small']-r['realday']['bestS'] for r in ok]; gl=[r['realday']['large']-r['realday']['bestL'] for r in ok]
print('gap small-best median %.2f min %.2f max %.2f; large median %.2f min %.2f max %.2f'%(np.median(gs),min(gs),max(gs),np.median(gl),min(gl),max(gl)))
rb=[100*(1-r['realday']['small_reb']/r['realday']['tecpro_reb']) for r in ok]
print('rebound reduction small vs tec median %.1f min %.1f max %.1f'%(np.median(rb),min(rb),max(rb)))
for r in ok: print('   reb %-20s %.2f -> %.2f (%.0f%%)'%(r['name'],r['realday']['tecpro_reb'],r['realday']['small_reb'],100*(1-r['realday']['small_reb']/r['realday']['tecpro_reb'])))
# fail-safe across all runs (all cases x conditions + realday)
fsok=all(abs(r['conds'][w]['failsafe']-r['conds'][w]['tecpro'])<0.1 for r in R for w in r['conds'])
print('failsafe all conds ok',fsok, 'count',sum(1 for r in R for w in r['conds']))
# TABLE 2 per condition
print('\nTABLE 2')
for w in R[0]['conds']:
    s=[100*(1-r['conds'][w]['small']/r['conds'][w]['tecpro']) for r in ok]
    l=[100*(1-r['conds'][w]['large']/r['conds'][w]['tecpro']) for r in ok]
    dl=[100*(1-r['conds'][w]['large']/r['conds'][w]['deepL']) for r in ok]
    ds=[100*(1-r['conds'][w]['small']/r['conds'][w]['deepS']) for r in ok]
    print('%-11s small med %5.1f (min %5.1f) | large med %5.1f (min %5.1f) | large vs d3.5 med %5.1f (min %5.1f) | small vs d1.2 med %5.1f (min %5.1f)'%(w,np.median(s),min(s),np.median(l),min(l),np.median(dl),min(dl),np.median(ds),min(ds)))
# TABLE 3 all conditions pooled excl 2,13
def pool(fn): v=[fn(r['conds'][w]) for r in ok for w in r['conds']]; return np.median(v),min(v),max(v),len(v)
print('\nTABLE 3')
print('d1.2 vs tec  %.1f %.1f %.1f n=%d'%pool(lambda x:100*(1-x['deepS']/x['tecpro'])))
print('small vs d1.2 %.1f %.1f %.1f n=%d'%pool(lambda x:100*(1-x['small']/x['deepS'])))
print('d3.5 vs tec  %.1f %.1f %.1f n=%d'%pool(lambda x:100*(1-x['deepL']/x['tecpro'])))
print('large vs d3.5 %.1f %.1f %.1f n=%d'%pool(lambda x:100*(1-x['large']/x['deepL'])))
allp=[(r['name'],w,r['conds'][w]) for r in R for w in r['conds']]
print('small<deepS %d/%d ; large<deepL %d/%d'%(sum(x['small']<x['deepS'] for _,_,x in allp),len(allp),sum(x['large']<x['deepL'] for _,_,x in allp),len(allp)))
for n,w,x in allp:
    if x['small']>=x['deepS'] or x['large']>=x['deepL']: print('  EXC',n,w,'small %.2f deepS %.2f large %.2f deepL %.2f'%(x['small'],x['deepS'],x['large'],x['deepL']))
print('median rebound pooled tec %.2f deepL %.2f small %.2f large %.2f'%tuple(np.median([x[k] for r in ok for w in r['conds'] for x in [r['conds'][w]]]) for k in ['tecpro_reb','deepL_reb','small_reb','large_reb']))
# blind camera large vs deepL
for w in ['heavy_rain','worst']:
    v=[100*(1-r['conds'][w]['large']/r['conds'][w]['deepL']) for r in ok]; print(w,'large vs d3.5 median %.1f range %.1f..%.1f'%(np.median(v),min(v),max(v)))
v=[100*(1-r['conds'][w]['large']/r['conds'][w]['deepL']) for r in ok for w in ['dry','light_rain','cold','hot','sun_glare','night']]; print('camera available large vs d3.5 median %.1f'%np.median(v))
# FEA design load: max 3ms force Case3 within capacity (<=600) across all conds
F=[(r['name'],w,r['conds'][w]['small_F3_kN']) for r in R for w in r['conds']]
over=[x for x in F if x[2]>600]; within=[x for x in F if x[2]<=600]
print('\nCase3 runs %d, over 600kN %d: %s'%(len(F),len(over),sorted(set((o[0],o[1]) for o in over))))
print('max within', max(within,key=lambda x:x[2]))
# fatal
print('\nFATAL'); 
for r in R:
    if r['id'] in (1,2,3,11,12,13,14,15): d=r['realday']; print(r['name'],'real %.1f tec %.1f small %.1f large %.1f KE %.0f'%(d['real'],d['tecpro'],d['small'],d['large'],d['KE']))
