# F1 Smart Barrier — Crash Simulation Study

MATLAB simulations of a camera-controlled hydraulic barrier for Formula 1
circuits, tested against 15 documented crashes (8 of them fatal) and 15
hypothetical breakpoint impacts.

## Design principles
1. **The standard TecPro barrier is not changed.** Same blocks, same depth.
2. **Very little extra space.** The whole system adds only 20 cm of depth.

## The system
| Part | What it does | Extra depth |
|------|--------------|-------------|
| **Parallel hydraulic rams** | Sit between the TecPro stacks, flush with the face. Add force while the foam is still soft, so the push on the car is flat instead of rising. | 0 cm |
| **Force-limiting sled** | The barrier module sits on a sled that stays locked until the force reaches the target, then slides back (20 cm in Case 3, 2.5 m in Case 4). Stops the force rising at the end. | 20 cm / 2.5 m |
| **Pre-retraction** (Case 4 only) | When there is room, the camera's prediction starts moving the sled back before contact, so the car meets a barrier already moving away. | — |
| **Camera + ML prediction** | Predicts impact speed before contact, so the controller can set the lowest flat force that still stops the car. On-board sensors correct it every 1 ms after contact. | — |
| **Rebound lock** | When the car stops, the rams release and the sled gives way into a 2 cm reserve, so the springing-back foam pushes the sled instead of the car back onto the track. | (2 cm of the sled stroke) |
| **Fail-safe** | If offline: ram valves open (no force), sled locked → behaves exactly like TecPro. | — |

## Repository layout
```
src/        Shared simulation engine (used by every case)
cases/      One script per real crash (Case01 ... Case15)
breakpoint/ BreakpointStudy.m - 15 hypothetical impacts and breakpoints
fea/        Finite element analysis of the sled deck
data/       crash_database.csv - the 15 crashes with source IDs
docs/       design concept, FEA notes, external factors, NHSJS references
standalone/ Single-file versions for MATLAB Online
tools/      Python reference implementation of the same model, plus the
            scripts that compute every number in the paper
paper_figures/  The paper's three figures, the scripts that draw them and
            their data (paper_figures/data/)
legacy/     Earlier concept scripts (v1 long-stroke, v2 smart barrier)
results/    JSON outputs of the Python scripts (paper_numbers, hic_realday,
            angle_sweeps, breakpoint, spacematch);
            the MATLAB case scripts write their figures and CSVs here too
REFERENCES.md  All sources (S1, S2, ...) for the paper
```

## How to run
Open MATLAB (R2020a or newer), go to the repository folder and run a case:
```matlab
run('cases/Case01_Senna_Imola1994.m')
```
Each case adds `src/` to the path itself and saves figures and CSV tables
to `results/caseXX/`.

**MATLAB Online / single file:** every case also exists as one self-contained
file in `standalone/` (case + whole engine). Regenerate them after changing
`src/` with `python3 tools/build_standalone.py`.

## Reproducing the paper (Python)
The numbers, tables and figures in the paper were computed with the Python
reference implementation in `tools/`, which follows the MATLAB pipeline step
by step (calibrate the impact angle under the real-day condition, then run
every scenario). It needs Python 3 with NumPy and Matplotlib. Run from the
repository folder:

| Step | Command | What it produces | Time |
|------|---------|------------------|------|
| 1 | `python3 tools/verify_paper_numbers.py` | `results/paper_numbers.json`: all 15 crashes × 8 conditions + real day | ~30 s |
| 2 | `python3 tools/paper_stats.py` | Prints Tables 1–4, medians, ranges, rebound and fail-safe checks | seconds |
| 3 | `python3 tools/paper_hic.py` | `results/hic_realday.json`: HIC15 for every crash | seconds |
| 4 | `python3 tools/paper_sweep.py` | `results/angle_sweeps.json`: sensitivity to impact angle | ~40 s |
| 5 | `python3 tools/paper_mass_sens2.py` | Sled-mass sensitivity (100 / 250 / 400 kg) | seconds |
| 6 | `python3 tools/paper_timestep_check.py` | Time-step check (20 / 10 / 5 µs; max change 0.10 %) | seconds |
| 7 | `python3 tools/paper_figure_data.py` | `paper_figures/data/*.json` | ~15 s |
| 8 | `python3 paper_figures/make_figs.py` and `python3 paper_figures/make_mechanism_figure.py` | The three figures | seconds |

Steps 2–7 read the output of step 1. The breakpoint study and the
space-matched TecPro comparison have their own Python versions in
`tools/breakpoint.py` and `tools/spacematch.py` (they write `results/breakpoint.json` and `results/spacematch.json`); the FEA cross-check is
`tools/python_reference_fea.py`.

## Every crash is simulated in four cases
1. **Real condition** – the barrier that was actually there that day
2. **TecPro** – a standard TecPro barrier in the same place
3. **Complete system, small space** – TecPro unchanged + parallel rams +
   20 cm sled + camera
4. **Complete system, large space** – TecPro unchanged + rams + 2.5 m sled +
   camera-triggered pre-retraction (~2.6 m car travel)

A **fail-safe check** (Case 3 with the system offline must equal TecPro) and
the **theoretical best** (lowest g physically possible with TecPro unchanged,
for each space) are reported alongside every case, together with rebound speed.

Every crash is also run under eight external conditions (dry, light rain,
heavy rain, cold, hot, sun glare, night, worst case), across a range of impact
angles, and against passive TecPro stacked as deep as the space each version
of the system uses (1.2 m and 3.5 m).

## The 15 crashes
| # | Crash | Real barrier | Fatal | Recorded g | Script |
|---|-------|--------------|-------|-----------|--------|
| 1 | Ayrton Senna, Imola 1994 | Concrete | Yes | — | `Case01_Senna_Imola1994.m` |
| 2 | Roland Ratzenberger, Imola 1994 | Concrete | Yes | (500, unverified) | `Case02_Ratzenberger_Imola1994.m` |
| 3 | Anthoine Hubert, Spa 2019 (F2) | Barrier, type not stated (tyres assumed) | Yes | 33.7 | `Case03_Hubert_Spa2019.m` |
| 4 | Romain Grosjean, Bahrain 2020 | Triple guardrail | No | 67 | `Case04_Grosjean_Bahrain2020.m` |
| 5 | Robert Kubica, Canada 2007 | Concrete | No | 75 | `Case05_Kubica_Canada2007.m` |
| 6 | Carlos Sainz, Sochi 2015 | TecPro | No | 42 (FIA ADR) | `Case06_Sainz_Sochi2015.m` |
| 7 | Rubens Barrichello, Imola 1994 | Tyres | No | 95 | `Case07_Barrichello_Imola1994.m` |
| 8 | Mick Schumacher, Jeddah 2022 | Concrete | No | 33 | `Case08_MSchumacher_Jeddah2022.m` |
| 9 | Michael Schumacher, Silverstone 1999 | Tyres | No | — | `Case09_Schumacher_Silverstone1999.m` |
| 10 | Fernando Alonso, Melbourne 2016 | Concrete | No | 45 (lateral) | `Case10_Alonso_Melbourne2016.m` |
| 11 | Greg Moore, California Speedway 1999 (CART) | Concrete | Yes | 154 | `Case11_Moore_Fontana1999.m` |
| 12 | Scott Brayton, Indianapolis 1996 | Concrete | Yes | — | `Case12_Brayton_Indianapolis1996.m` |
| 13 | François Cevert, Watkins Glen 1973 | Armco | Yes | — | `Case13_Cevert_WatkinsGlen1973.m` |
| 14 | Gonzalo Rodríguez, Laguna Seca 1999 (CART) | Tyres on concrete | Yes | 150 (press) | `Case14_Rodriguez_LagunaSeca1999.m` |
| 15 | Dale Earnhardt, Daytona 2001 (NASCAR) | Concrete | Yes | 48–68 (sled tests; 58 used) | `Case15_Earnhardt_Daytona2001.m` |

Cases 11–15 are fatal barrier impacts from before TecPro was introduced
(developed with the FIA Institute in 2006). No fatal impact into a TecPro barrier was found in the sources searched.

Run all fifteen and build the summary with `run('runAllCases.m')`
(or `standalone/ALL_15_CASES_STANDALONE.m` in MATLAB Online).

## Breakpoint study (hypothetical)
`breakpoint/BreakpointStudy.m`: 15 HYPOTHETICAL impacts (150–350 km/h ×
20°/45°/90°, 798 kg car) and the impact energy at which each configuration
first exceeds 40 g and 67 g, including passive TecPro stacked as deep as the
space each version of the system uses (1.2 m and 3.5 m).

## Tentative design
`docs/design_concept.md` — concept layout of the TecPro module on a
hydraulic sled in front of the existing guardrail.

## Finite element analysis
`fea/F1_Sled_Plate_FEA.m` — sled deck under the 600 kN design load
(see `docs/fea_notes.md`).

### Calibration to recorded g (Equivalent Barrier Speed)
Real cars glance off, spin, lose wheels and push barriers back, so the
barrier absorbs less than the full geometric impact energy. For every crash
with a recorded peak g, the impact angle is adjusted until the REAL barrier
in the model reproduces the recorded g (`src/calibrateAngle.m`). TecPro and
our system are then tested at that same, measured severity.
Check: for Grosjean the calibration needs 29.5°; the FIA report gives 29°.

## Model and limitations
- 1-D impulse–momentum model, fixed-step semi-implicit Euler (10 µs step).
- Car and barrier crush in series; crushed material stays crushed.
- Only the velocity component normal to the barrier is absorbed.
- Car, barrier, weather and sensor parameters are engineering estimates and
  are marked as such in the code. Armco and tyre-barrier stiffness must be
  calibrated against recorded crashes before quoting their results.
- Deceleration is used as a proxy for head acceleration in HIC15.
- The model cannot simulate debris or wheels striking the driver.
