# References

Sources for every crash value used in this project. IDs (S1, S2, …) are used in
`data/crash_database.csv` and in the comments of each case script.

Where a value is **not** published (for example most impact angles), the case
scripts mark it as an ASSUMPTION and sweep it over a range instead of inventing
one number.

| ID | Source | Used for |
|----|--------|----------|
| S1 | Wikipedia, *Death of Ayrton Senna* (cites Williams 2010 telemetry, La Repubblica) — https://en.wikipedia.org/wiki/Death_of_Ayrton_Senna | Senna: 309 km/h entry, 211 km/h impact, concrete wall, cause of death |
| S2 | Wikipedia, *1994 San Marino Grand Prix* — https://en.wikipedia.org/wiki/1994_San_Marino_Grand_Prix | Senna, Ratzenberger, Barrichello speeds/g; race-day weather (dry, sunny); safety car laps 1–5 |
| S3 | GrandPrix.com, Feb 27 1995 (Italian investigation / data) — https://www.grandprix.com/ns/ns00033.html | Senna: 192 mph 1.5 s before impact, braking timeline, wall 38 m from track |
| S4 | Wikipedia, *Roland Ratzenberger* — https://en.wikipedia.org/wiki/Roland_Ratzenberger | Ratzenberger crash mechanism and injuries |
| S5 | (see S2; 314 km/h and 500 g cited there to RaceFans, Motorsport.com, International Herald Tribune, Sunday Telegraph) | Ratzenberger speed / g (g value unverified) |
| S6 | FIA, *FIA concludes investigation into Formula 2 accident at Spa-Francorchamps* — https://www.fia.com/news/fia-concludes-investigation-formula-2-accident-spa-francorchamps | Hubert/Correa speeds, angles, g |
| S7 | FIA, *FIA concludes investigation into Romain Grosjean's accident* — https://api.fia.com/news/fia-concludes-investigation-romain-grosjeans-accident-2020-bahrain-formula-1-grand-prix-and | Grosjean 192 km/h, 29°, 67 g, triple guardrail |
| S8 | Motor Sport Magazine, *Crash & learn* (Sept 2007) — https://www.motorsportmagazine.com/archive/article/september-2007/96/crash-learn/ | Kubica 75 g front / 28 g rear |
| S9 | Auto Świat, Kubica ADR data — https://www.auto-swiat.pl/wiadomosci/aktualnosci/grand-prix-francji-2007-kubica-przezyl-przeciazenie-75-g-wykazal-zapis-z-adr/26n69g3 | Kubica 232 km/h impact |
| S10 | Motorsport.com, *Sainz Sochi crash: FIA reveals dramatic new findings* — https://www.motorsport.com/f1/news/sainz-sochi-crash-fia-reveals-dramatic-new-findings/652424/ | Sainz 153 km/h, stopped in ~4 m, TecPro rebound |
| S11 | RACER, *Sainz had 46g impact in Sochi shunt* — https://racer.com/2015/10/11/sainz-had-46g-impact-in-sochi-shunt/ | Sainz 46 g |
| S12 | The Race, *Schumacher: Saudi Arabian F1 track changes 'definitely' needed* — https://the-race.com/formula-1/schumacher-saudi-arabian-f1-track-changes-definitely-needed/ | Mick Schumacher ~270 km/h, 33 g, concrete |
| S13 | AtlasF1, *The FIA's conclusions on Schumacher's accident* (1999) — https://archive.atlasf1.com/news/1999/1438.htm | M. Schumacher 306 → 107 km/h, tyre barrier |
| S14 | GrandPrix247, *FIA: Alonso survived deceleration of 46G* — https://www.grandprix247.com/formula-1-news/fia-alonso-survived-deceleration-of-46g-in-melbourne-shunt | Alonso speeds and g |
| S15 | RaceFans, F1 minimum weight history — https://www.racefans.net/?p=93822 | 1994 minimum weight ~500 kg excluding driver |
| S16 | GrandPrix247, *Roland Ratzenberger: A horrid Saturday at Imola 1994 remembered* (30 Apr 2025) — https://www.grandprix247.com/2025/04/30/roland-ratzenberger-his-final-lap-at-imola-1994-f1-accident-anniversary/ | Ratzenberger: wing failed at ~308 km/h, outside concrete barrier, slid along wall, ~13:15, qualifying 2 |
| S17 | Formula1.com, *A racer through and through — Ratzenberger remembered* (2014) — https://www.formula1.com/en/latest/features/2014/4/A-racer-through-and-through---Ratzenberger-remembered.html | Ratzenberger: >300 km/h, front wing failure after Acque Minerali off |
| S18 | Wikipedia, *Dallara F2 2018* — https://en.wikipedia.org/wiki/Dallara_F2_2018 | F2 car: 720 kg incl. driver and fuel |
| S19 | GPFans, *F1 car weight explained* — https://www.gpfans.com/en/f1-news/1028252/f1-car-weight-explained/ ; F1Technical, *F1MATHS: weight limit evolution* — https://www.f1technical.net/news/28346 | Minimum weights: 2007 605 kg, 2015–16 702 kg, 2020 746 kg, 2022 798 kg (incl. driver, excl. fuel) |
| S20 | Wikipedia, *Greg Moore (racing driver)* — https://en.wikipedia.org/wiki/Greg_Moore_(racing_driver) | >350 km/h, airborne, concrete at 90°, 154 g, fatal |
| S21 | Wikipedia, *Scott Brayton* — https://en.wikipedia.org/wiki/Scott_Brayton | >370 km/h into outside wall, basilar skull fracture |
| S22 | Wikipedia, *François Cevert* — https://en.wikipedia.org/wiki/Fran%C3%A7ois_Cevert | ~241 km/h (Stewart), guardrail near 90°, fatal |
| S23 | Wikipedia, *Gonzalo Rodríguez (racing driver)* — https://en.wikipedia.org/wiki/Gonzalo_Rodr%C3%ADguez_(racing_driver) | Tyre barrier + concrete wall, thin tyres, basilar skull fracture |
| S24 | SpeedCenter, *Laguna Seca 1999 wrap-up* — https://speedcenter.com/archive/races99/17laguna/wrapup.html | Rodríguez impact "in excess of 150 g's" |
| S25 | Motorsport.com, *Gonzalo Rodriguez dies in crash at Laguna Seca* — https://us.motorsport.com/indycar/news/champcar-cart-gonzalo-rodriguez-dies-in-crash-at-laguna-seca/1770406/ | Concrete barrier protected by tyre wall, massive head and neck injuries |
| S26 | Wikipedia, *Death of Dale Earnhardt* — https://en.wikipedia.org/wiki/Death_of_Dale_Earnhardt | 253–259 km/h, 13.6° trajectory, Δv 68–71 km/h, 48–68 g sled tests |
| S27 | Wikipedia, *Lola B99/00* — https://en.wikipedia.org/wiki/Lola_B99/00 | CART car 700 kg |
| S28 | Wikipedia, *Tecpro barrier* — https://en.wikipedia.org/wiki/Tecpro_barrier | TecPro homologated 2006; no fatal TecPro impact recorded there |

## Note for the paper
Wikipedia pages are used here to locate primary sources. For the final paper,
cite the primary sources they reference (FIA reports, Williams telemetry
book, court verdicts, Autosport/Motorsport articles) wherever possible.
