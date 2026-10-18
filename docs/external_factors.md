# External factors and how they affect the smart barrier

Every case study is re-run under several external conditions
(`src/weatherScenario.m`). This file explains what each condition changes
and why. **The sizes of these effects are engineering assumptions** chosen
for this study; they should be refined with material and sensor tests.

| Condition | Effect on the crash | Effect on our system | How it is modelled |
|-----------|--------------------|----------------------|--------------------|
| **Rain (light)** | Less grip on track and run-off, so less speed is lost before the wall → higher impact speed | Spray and water on the lens make the camera's speed estimate less accurate | grip 0.75 of dry; camera speed error +10 %; air 15 °C |
| **Rain (heavy) + spray** | Much less grip → much higher impact speed | Camera may not see the car at all. The barrier then waits for its own on-board sensors (first 15 ms unassisted) | grip 0.55; camera blind; air 12 °C |
| **Cold (5 °C)** | — | Foam is stiffer (harder push early), hydraulic oil is thicker → valves react more slowly | foam force +9 %; valve time 2 ms → 3.2 ms |
| **Hot (40 °C air)** | — | Foam is softer (more crush needed). Oil is thinner (no slowdown modelled) | foam force −12 % |
| **Low sun glare** | — | Camera over-estimates speed → controller starts too firm | camera error +20 % |
| **Worst case** | Cold heavy rain | Camera blind + slow valves + very high impact speed | grip 0.55, 5 °C, camera blind |

## How grip changes impact speed
The speed lost between losing control and hitting the barrier comes from
braking and sliding, which depend on grip. For a documented dry crash:

    v_impact^2 = v_brake^2 - (grip / real_grip) * (v_brake^2 - v_real_impact^2)

Example, Senna 1994: 309 km/h before braking, 211 km/h at the wall (dry).
With grip 0.55 the same event would reach the wall at about 260 km/h.

## Other real-world factors noted but not simulated
- **Cold tyres after a safety car** (Imola 1994, laps 1–5): affects how the
  crash *starts*, not how the barrier absorbs it.
- **Debris and dust on camera lenses:** treated like spray (camera blind).
- **Night races / floodlights:** camera exposure; treat like glare.
- **Multiple cars arriving together:** not modelled (1 car per impact).
- **Glancing impacts:** only the speed component normal to the barrier is
  absorbed; the sideways component makes the car slide along the barrier.
