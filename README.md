# F1 Smart Barrier — Crash Simulation Study

MATLAB simulations of a camera-controlled hydraulic barrier for Formula 1
circuits, tested against 10 real crashes (3 of them fatal).

## Design principles
1. **The standard TecPro barrier is not changed.** Same blocks, same depth.
2. **Very little extra space.** The whole system adds only 20 cm of depth.

## The system
| Part | What it does | Extra depth |
|------|--------------|-------------|
| **Parallel hydraulic rams** | Sit between the TecPro stacks, flush with the face. Add force while the foam is still soft, so the push on the car is flat instead of rising. | 0 cm |
| **Force-limiting sled** | The barrier module sits on a sled that stays locked until the force reaches the target, then slides back up to 20 cm. Stops the force rising at the end. | 20 cm |
| **Camera + ML prediction** | Predicts impact speed before contact, so the controller can set the lowest flat force that still stops the car. On-board sensors correct it every 1 ms after contact. | — |
| **Fail-safe** | If offline: ram valves open (no force), sled locked → behaves exactly like TecPro. | — |

## Repository layout
```
src/       Shared simulation engine (used by every case)
cases/     One script per real crash (Case01 ... Case10)
data/      crash_database.csv - the 10 crashes with source IDs
docs/      external_factors.md - weather/temperature effects
legacy/    Earlier concept scripts (v1 long-stroke, v2 smart barrier)
results/   Figures and CSV tables written by the case scripts
REFERENCES.md  All sources (S1, S2, ...) for the paper
```

## How to run
Open MATLAB (R2020a or newer), go to the repository folder and run a case:
```matlab
run('cases/Case01_Senna_Imola1994.m')
```
Each case adds `src/` to the path itself and saves figures and CSV tables
to `results/caseXX/`.

## Every case compares four barrier situations
1. **Actual** – the barrier that was really there
2. **TecPro** – a standard TecPro barrier in the same place
3. **Smart** – our system
4. **Smart (failed)** – our system offline (fail-safe check)

…under seven external conditions (dry, light rain, heavy rain, cold, hot,
sun glare, worst case) and across a range of impact angles when the angle
was not published.

## The 10 crashes
| # | Crash | Barrier | Fatal | Script |
|---|-------|---------|-------|--------|
| 1 | Ayrton Senna, Imola 1994 | Concrete | Yes | `Case01_Senna_Imola1994.m` ✅ |
| 2 | Roland Ratzenberger, Imola 1994 | Concrete | Yes | planned |
| 3 | Anthoine Hubert, Spa 2019 (F2) | Barrier + secondary impact | Yes | planned |
| 4 | Romain Grosjean, Bahrain 2020 | Armco | No | planned |
| 5 | Robert Kubica, Canada 2007 | Concrete | No | planned |
| 6 | Carlos Sainz, Sochi 2015 | TecPro | No | planned |
| 7 | Rubens Barrichello, Imola 1994 | Tyres | No | planned |
| 8 | Mick Schumacher, Jeddah 2022 | Concrete | No | planned |
| 9 | Michael Schumacher, Silverstone 1999 | Tyres | No | planned |
| 10 | Fernando Alonso, Melbourne 2016 | Wall + gravel | No | planned |

## Model and limitations
- 1-D impulse–momentum model, fixed-step semi-implicit Euler (10 µs step).
- Car and barrier crush in series; crushed material stays crushed.
- Only the velocity component normal to the barrier is absorbed.
- Car, barrier, weather and sensor parameters are engineering estimates and
  are marked as such in the code. Armco and tyre-barrier stiffness must be
  calibrated against recorded crashes before quoting their results.
- Deceleration is used as a proxy for head acceleration in HIC15.
- The model cannot simulate debris or wheels striking the driver.
