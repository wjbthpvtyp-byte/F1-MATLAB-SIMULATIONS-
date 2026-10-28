# Tentative design — TecPro module on a hydraulic sled, in front of the existing guardrail

Status: **concept design**, sized from the simulation and FEA results in this
repository. Not built or tested. Every dimension is a starting point for
detailed design.

## Layout (one module, plan view, track at the top)

```
 TRACK  ───────────────────────────────────────────────────────────►  traffic
 ┌──────────────────────── low-friction face panel (spans modules) ────────┐
 │  TecPro stack A  │ ram │ ram │  TecPro stack B                          │  1.0 m
 │  (standard,      │ pad │ pad │  (standard,                              │  TecPro
 │   unchanged)     │     │     │   unchanged)                             │  depth
 ├──────────────────┴─────┴─────┴──────────────────────────────────────────┤
 │                 sled deck, S355 steel 20 mm, 2.0 m x 1.0 m               │
 └───── cylinder ─────────── cylinder ─────────── cylinder ────────────────┘
        x = 0.3 m            x = 1.0 m             x = 1.7 m
 ═════════════ 0.20 m sled stroke gap (the only added depth) ═══════════════
 ███████████ reaction beam anchored to the foundation slab ███████████████
 ─────────── existing guardrail, kept as secondary containment ────────────
```

## Components

| Component | Tentative specification | Source of the number |
|---|---|---|
| TecPro stacks | Standard homologated blocks, 1.0 m deep, two stacks per 2.0 m module, strapped as today | Constraint 1 |
| Impact rams | 2 per module in the gap between stacks, pads flush with the barrier face; 150 kN each (300 kN per module); 0.95 m stroke; proportional valves, ≤ 2 ms response; act in compression only | `defaultParams.m`: `Fram_max`, `ram_stroke`, `tau` |
| Sled deck | S355 steel plate, 20 mm, 2.0 m along the track × 1.0 m deep, on two linear rails | `fea/F1_Sled_Plate_FEA.m` |
| Sled cylinders | 3 per module at x = 0.3, 1.0, 1.7 m, mounted horizontally under the deck in a foundation trench so they add no depth; 0.20 m stroke (0.18 m usable + 0.02 m rebound reserve); pressure-relief valves set by the controller; total capacity 600 kN | `P.S`, `P.S_reserve`, `P.Fmax` |
| Reaction beam | Steel beam anchored to a reinforced-concrete foundation slab behind the sled; takes the 600 kN design load | FEA design load |
| Existing guardrail | Kept in place behind the reaction beam as secondary containment. It is **not** in the primary load path: a guardrail is not designed to take 600 kN | — |
| Face panel | Continuous low-friction panel across modules so a glancing car slides along instead of snagging at module joints | Rationale only, not simulated |
| Perception | Trackside camera on a post upstream of the barrier; ML model estimates speed and impact point; sends the target force before contact | Proposed, not built |
| On-board sensors | Displacement and pressure sensors on the sled and rams; correct the target every 1 ms from 15 ms after contact | `P.t_sense`, `P.t_upd` |
| Hydraulic power | Accumulator and valve block per group of modules; fail-open ram valves and locked sled cylinders on loss of power | Fail-safe requirement |

## Fail-safe states

| Failure | Ram valves | Sled cylinders | Barrier behaves as |
|---|---|---|---|
| Normal operation | Controlled | Controlled | Smart barrier |
| Camera blind (rain, spray, glare) | Idle for first 15 ms, then sensor-controlled | Locked, then sensor-controlled | TecPro for 15 ms, then smart barrier |
| Power / electronics / hydraulic loss | Fail open (no force) | Locked | Standard TecPro |

## Open design questions
- Out-of-plane loads on the deck (impact force acts ~0.3–0.5 m above it) and
  plate buckling — need a 3D shell model.
- Module-to-module behaviour when a car hits a joint.
- Maintenance: resetting the sled after an impact, replacing crushed TecPro.
- Cost and installation depth of the foundation trench.
