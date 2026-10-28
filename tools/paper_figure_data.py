"""Generate the data behind the two plotted figures in the paper.

  paper_figures/data/grosjean_th.json  deceleration time histories, Grosjean 2020 (real-day
                                       condition, calibrated angle) for the real barrier, standard
                                       TecPro, the small system and the large system
  paper_figures/data/curves_fine.json  peak deceleration against normal impact energy
                                       (20-2000 kJ, 798 kg car) for the breakpoint figure

Run from anywhere:  python3 tools/paper_figure_data.py
Then draw the figures with:  python3 paper_figures/make_figs.py
Needs results/paper_numbers.json (made by tools/verify_paper_numbers.py) for the calibrated angle.
"""
import os, sys, json, numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
# reuse the case list, set-up and barrier definitions of the verification script
src = open(os.path.join(HERE, 'verify_paper_numbers.py')).read().split('res=[]')[0]
exec(src)
from ext import CARS as CARS_EXT, P as P_EXT, barrier as barrier_ext, barrierD, build as build_ext, sim as sim_ext

OUT = os.path.join(ROOT, 'paper_figures', 'data')
os.makedirs(OUT, exist_ok=True)

# ---------- Grosjean 2020 time histories ----------
R = json.load(open(os.path.join(ROOT, 'results', 'paper_numbers.json')))
c = next(x for x in CASES if x[1] == 'Grosjean 2020')
ang = next(r['angle'] for r in R if r['name'] == 'Grosjean 2020')
W, p, v, car = setup(c, c[9])
vn = v / 3.6 * np.sin(np.radians(ang))
Ca = build(car, barrierX(c[4], W['fs']))
Ct = build(car, barrierX('tecpro', W['fs']))
pl = dict(p); pl['S'] = 2.5; pl['v_pre'] = 6
runs = {'real': ('passive', Ca, p), 'tecpro': ('passive', Ct, p),
        'small': ('smart', Ct, p), 'large': ('smart', Ct, pl)}
th = {}
for k, (mode, C, pp) in runs.items():
    x = sim(mode, vn, car, C, pp)
    A = np.asarray(x['a']); dt = pp['dt']
    n = int(round(0.003 / dt))
    ma = np.convolve(A, np.ones(n) / n, 'same')
    step = int(round(1e-4 / dt))
    th[k] = dict(a=A[::step].tolist(), ma=ma[::step].tolist(), dt=1e-4, clip=float(x['clip']),
                 raw=float(A.max()), dur=len(A) * dt, stop=float(x['stop']))
    print('Grosjean %-7s peak (3 ms clip) %6.2f g' % (k, x['clip']))
json.dump(th, open(os.path.join(OUT, 'grosjean_th.json'), 'w'))

# ---------- breakpoint curves ----------
car = dict(CARS_EXT['2020s']); car['mass'] = 798
Ct = build_ext(car, barrier_ext('tecpro'))
C12 = build_ext(car, barrierD('tecpro_deep', 1, 1.2))
C35 = build_ext(car, barrierD('tecpro_deep', 1, 3.5))
def cfg(name, vn):
    q = dict(P_EXT)
    if name == 'tecpro': return sim_ext('passive', vn, car, Ct, q)
    if name == 'deep12': return sim_ext('passive', vn, car, C12, q)
    if name == 'small':  return sim_ext('smart', vn, car, Ct, q)
    if name == 'deep35': return sim_ext('passive', vn, car, C35, q)
    if name == 'large':  q['S'] = 2.5; q['v_pre'] = 6; return sim_ext('smart', vn, car, Ct, q)
names = ['tecpro', 'deep12', 'small', 'deep35', 'large']
rows = []
for e in np.linspace(20, 2000, 100):
    vn = np.sqrt(2 * e * 1e3 / 798)
    rows.append(dict(kJ=float(e), **{n: float(cfg(n, vn)['clip']) for n in names}))
json.dump(rows, open(os.path.join(OUT, 'curves_fine.json'), 'w'))
print('breakpoint curves:', len(rows), 'energies')
