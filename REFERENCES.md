# References

Sources for every value used in this project. IDs (S1, S2, …) are used in
`data/crash_database.csv` and in the comments of each case script.
The numbered list formatted for NHSJS is in `docs/nhsjs_references.md`.

**Status** column: **Opened** = the page was opened and the value checked
against it (October 2026). **Secondary** = the value comes from a source that
could not be opened here (book, paywall or blocked site); it is cited through
the page named, and must be checked in the original before submission.

Where a value is **not** published (for example most impact angles), the case
scripts mark it as an ASSUMPTION and sweep it over a range instead of inventing
one number.

## Crash data

| ID | Source | Used for | Status |
|----|--------|----------|--------|
| S1 | La Repubblica, P. Cascella, *Senna morte al computer*, 13 Mar 1997 (via Wikipedia, *1994 San Marino Grand Prix*) | Senna 211 km/h impact | Secondary |
| S2 | Wikipedia, *1994 San Marino Grand Prix* — https://en.wikipedia.org/wiki/1994_San_Marino_Grand_Prix | Locating primary sources; race-day weather (dry, sunny; no footnote) | Opened (not citable) |
| S3 | Grandprix.com, *Senna – steering failure?*, 27 Feb 1995 — https://www.grandprix.com/ns/ns00033.html | Senna 192 mph (309 km/h) 1.5 s before impact; ~130 mph at impact; heavy braking | Opened |
| S4 | K. Collantine, *How Ratzenberger's death stunned F1*, RaceFans, 30 Apr 2014 — https://www.racefans.net/2014/04/30/today-1994-ratzenbergers-death-stuns-f1/ | Ratzenberger 314.9 km/h into the concrete wall; front wing failure | Opened |
| S5 | B. Spurgeon, International Herald Tribune, 30 Apr 1999; T. Collings, Sunday Telegraph, 1 May 1994 (via Wikipedia) | Ratzenberger "500 g" (not used for calibration) | Secondary |
| S6 | FIA, *FIA concludes investigation into Formula 2 accident at Spa-Francorchamps*, 7 Feb 2020 — https://www.fia.com/news/fia-concludes-investigation-formula-2-accident-spa-francorchamps | Hubert: lost control at 262 km/h; barrier 216 km/h, ~40°, 33.7 g; barrier on the right of the Turn 4 exit run-off (type not stated); rebound; Correa 218 km/h, ~86°, 65.1 g / 81.8 g | Opened |
| S7 | FIA, *FIA concludes investigation into Romain Grosjean's accident at 2020 Bahrain Formula 1 Grand Prix and releases 2021 circuit racing safety initiatives*, 5 Mar 2021 — https://api.fia.com/news/fia-concludes-investigation-romain-grosjeans-accident-2020-bahrain-formula-1-grand-prix-and | Grosjean 241 km/h at loss of control, 192 km/h, 29°, 67 g, triple guardrail | Opened |
| S8 | R. Widdows, *Crash & learn*, Motor Sport, Sep 2007 — https://www.motorsportmagazine.com/archive/article/september-2007/96/crash-learn/ | Kubica 75 g front / 28 g rear (FIA analysis) | Opened |
| S9 | A. Karaczun, *Grand Prix Francji 2007: Kubica przeżył przeciążenie 75 G – wykazał zapis z ADR!*, Auto Świat, 20 Jun 2007 — https://www.auto-swiat.pl/wiadomosci/aktualnosci/grand-prix-francji-2007-kubica-przezyl-przeciazenie-75-g-wykazal-zapis-z-adr/26n69g3 | Kubica 75 g (ADR), >280 km/h at Trulli contact, 232 km/h into the wall | Opened |
| S10 | C. Bradley, *Sainz Sochi crash: FIA reveals dramatic new findings*, Motorsport.com, Oct 2015 — https://www.motorsport.com/f1/news/sainz-sochi-crash-fia-reveals-dramatic-new-findings/652424/ | Sainz 153 km/h to zero in 4 m; "40g-ish"; TecPro rebounded onto the car | Opened |
| S11 | RACER, *F1: Sainz had 46G impact in Sochi shunt*, 11 Oct 2015 — https://racer.com/2015/10/11/sainz-had-46g-impact-in-sochi-shunt/ | Sainz: wall contact at ~204 km/h; early figure ~46 g (team principal F. Tost) | Opened |
| S12 | S. Mitchell-Malm, *Schumacher: Saudi Arabian F1 track changes 'definitely' needed*, The Race, 27 Mar 2022 — https://the-race.com/formula-1/schumacher-saudi-arabian-f1-track-changes-definitely-needed/ | Mick Schumacher ~270 km/h (driver's estimate), 33 g, concrete barrier | Opened |
| S13 | AtlasF1, *The FIA's Conculsions [sic] on Schumacher's Accident*, 13 Jul 1999 — https://archive.atlasf1.com/news/1999/1438.htm | Michael Schumacher: braked at 306 km/h, 107 km/h into the tyre barrier | Opened |
| S14 | GrandPrix247, *FIA: Alonso survived deceleration of 46G in Melbourne shunt*, 7 Jun 2016 — https://www.grandprix247.com/formula-1-news/fia-alonso-survived-deceleration-of-46g-in-melbourne-shunt | Alonso 313 → 305 km/h at car contact; 45 g lateral at the wall; 46 g lateral in the roll; 20 g longitudinal | Opened |
| S15 | K. Collantine, *Why F1 cars keep getting heavier*, RaceFans, 20 Aug 2013 — https://www.racefans.net/?p=93822 | 1994 minimum weight 500 kg excluding driver; driver included from 1995 | Opened |
| S16 | G. Anderson, *Gary Anderson on Imola 1994 and Barrichello's crash*, The Race, 30 Oct 2020 — https://the-race.com/formula-1/gary-anderson-on-imola-1994-and-barrichellos-crash/ | Barrichello ~138 mph (222 km/h), airborne, onto the tyre barrier | Opened |
| S17 | Autosport, *Imola 1994: Memories from Senna's rivals* (interviews from 2011; page undated) — https://www.autosport.com/f1/feature/8165/imola-1994-memories-from-senna-rivals | Barrichello: "measured at 95g" | Opened |
| S18 | FIA, *F2 2018 car unveiled in Monza*, 31 Aug 2017 — https://www.fia.com/news/f2-2018-car-unveiled-monza | F2 car 720 kg with driver on board | Opened |
| S19 | B. Szabo, *F1MATHS: How have the F1 weight limit evolved over the years?*, F1Technical (undated) — https://www.f1technical.net/news/28346 ; Autosport, *How much does an F1 car weigh in 2023 and what's included in the limit?* (undated) — https://www.autosport.com/f1/news/how-much-does-an-f1-car-weigh/10246442/ | 2007 605 kg; 2015–16 702 kg; 2020 746 kg; 2022 798 kg incl. driver, without fuel | Opened |
| S20 | E. Hinton, *Wheels of fortune*, Sports Illustrated, 8 Nov 1999 — https://vault.si.com/vault/1999/11/08/wheels-of-fortune-greg-moores-sudden-death-wont-change-the-way-open-wheel-racers-think | Moore: >220 mph, airborne, cockpit-first into a concrete wall | Opened |
| S20b | D. Proudfoot, J. Taylor, G. Kirby, *Greg Moore: A Legacy of Spirit*, Whitecap Books, 2000, p. 126 (via Wikipedia) | Moore 154 g ("largest ever recorded by a CART crash data sensor") | Secondary |
| S21 | Los Angeles Times via The Seattle Times, *Indy stricken by tragedy -- popular driver Brayton dies in practice*, 18 May 1996 — https://archive.seattletimes.com/archive/19960518/2329825/indy-stricken-by-tragedy----popular-driver-brayton-dies-in-practice | Brayton ~230 mph, right-rear tyre deflation, outside wall in Turn 2 | Opened |
| S22 | A. Marriott, *1973 United States Grand Prix race report*, Motor Sport, Nov 1973 — https://www.motorsportmagazine.com/archive/article/november-1973/25/15th-grand-prix-of-the-united-states | Cevert: "130 m.p.h. +" into the Armco on the far side | Opened |
| S22b | J. Stewart, *Winning Is Not Enough*, Headline, 2007, p. 281 (via Wikipedia) | Cevert 150 mph, almost head-on (value used in the model) | Secondary |
| S23 | Motorsport.com, *CHAMPCAR/CART: Gonzalo Rodriguez dies in crash at Laguna Seca*, 11 Sep 1999 — https://us.motorsport.com/indycar/news/champcar-cart-gonzalo-rodriguez-dies-in-crash-at-laguna-seca/1770406/ | Rodríguez: headfirst into a concrete barrier protected by a tyre wall | Opened |
| S24 | G. Spotts, *Herta wins race overshadowed by tragedy*, SpeedCenter, Sep 1999 — https://speedcenter.com/archive/races99/17laguna/wrapup.html | Rodríguez "in excess of 150 g's"; through the tyre barrier into the concrete wall | Opened |
| S25 | (merged into S23 and S24) | | |
| S26 | Orlando Sentinel / Associated Press via The Seattle Times, *NASCAR links belt, physics in report*, 22 Aug 2001 — https://archive.seattletimes.com/archive/20010822/auto22/nascar-links-belt-physics-in-report | Earnhardt 156–161 mph, concrete wall | Opened |
| S26b | Overdrive, *Earnhardt investigation concludes*, 30 Jan 2002 — https://www.overdriveonline.com/earnhardt-investigation-concludes/ | Earnhardt 12–15° trajectory, Δv > 40 mph | Opened |
| S26c | USA Today, *Transcript of NASCAR's report on Earnhardt crash*, 21 Aug 2001 (site blocked here; via Wikipedia) | 13.6° trajectory; 48–68 g exemplar sled tests | Secondary |
| S27 | Wikipedia, *Lola B99/00* — https://en.wikipedia.org/wiki/Lola_B99/00 | CART car ~700 kg (basis of the 780–800 kg estimates) | Opened (not citable; estimate) |
| S28 | FIA, *Technical List n°71 – List of approved safety barriers according to FIA Standard 3501-2017*, 9 Aug 2018 — https://www.fia.com/sites/default/files/technical_list_ndeg71_-_safety_barriers_homologated_manufacturers.pdf ; TECPRO Barriers company profile (undated) — https://www.fia.com/sites/default/files/basicpage/file/TECPRO%20Barriers.pdf | TecPro approved under FIA 3501-2017 (SB.001.17); developed with the FIA Institute in 2006 | Opened |
| S29 | FIA, *From Auto #18: Barrier breakthrough*, 18 Apr 2017 — https://www.fia.com/news/auto-18-barrier-breakthrough | Sainz: 153 km/h head-on, ADR peak 42 g, stopped in ~4 m; first row lifted onto the car during rebound; TecPro elements redesigned | Opened |

## Technical sources

| ID | Source | Used for | Status |
|----|--------|----------|--------|
| T1 | FIA, *Senna's lasting safety legacy*, 30 Apr 2014 — https://www.fia.com/news/sennas-lasting-safety-legacy | Safety changes after 1994; ADRs from 1997 | Opened |
| T2 | J. D. Reid et al., *New energy-absorbing high-speed safety barrier*, Transportation Research Record 1851, 53–64, 2003, doi:10.3141/1851-06 | SAFER barrier | Opened (abstract) |
| T3 | J. W. Melvin et al., *Biomechanical analysis of Indy race car crashes*, SAE 983161, 1998, doi:10.4271/983161 | Indy car decelerations up to 127 g | Opened (abstract) |
| T4 | J. W. Melvin et al., *Crash protection of stock car racing drivers*, Stapp Car Crash Journal 50, 415–428, 2006, doi:10.4271/2006-22-0016 | Stock-car protection, SAFER | Opened (abstract) |
| T5 | J. D. Reid, R. W. Bielenberg, *Modeling rebound of foam backed racetrack barriers*, 10th Int. LS-DYNA Users Conf., 6-43–6-50, 2008 | Foam recovery and rebound | Opened |
| T6 | J. Holnicki-Szulc et al., *Adaptive impact absorption for safety engineering*, 9th Int. Conf. Shock & Impact Loads on Structures, 2011 | Adaptive (semi-active) impact absorption | Opened |
| T7 | B. F. Spencer et al., *Phenomenological model for magnetorheological dampers*, J. Eng. Mech. 123(3), 230–238, 1997 | Controllable dampers | Opened (record) |
| T8 | D. Fernández Llorca et al., *Vision-based vehicle speed estimation: a survey*, IET ITS 15(8), 987–1005, 2021, doi:10.1049/itr2.12079 | Camera speed estimation | Opened (record) |
| T9 | S. Zang et al., *The impact of adverse weather conditions on autonomous vehicles*, IEEE VT Magazine 14(2), 103–111, 2019, doi:10.1109/MVT.2019.2892497 | Weather effects on perception | Opened (record) |
| T10 | K. L. Campbell, *Energy basis for collision severity*, SAE 740565, 1974, doi:10.4271/740565 | Equivalent barrier speed | Opened (abstract) |
| T11 | E. Hairer, C. Lubich, G. Wanner, Acta Numerica 12, 399–450, 2003, doi:10.1017/S0962492902000144 | Symplectic Euler | Opened (record) |
| T12 | R. Eppinger et al., *Development of improved injury criteria … II*, NHTSA, Nov 1999 — https://www.nhtsa.gov/sites/nhtsa.dot.gov/files/rev_criteria.pdf | HIC15 ≤ 700 (31 % skull-fracture risk) | Opened |
| T13 | J. Hutchinson, M. J. Kaiser, H. M. Lankarani, Applied Mathematics and Computation 96(1), 1–16, 1998, doi:10.1016/S0096-3003(97)10106-0 | HIC definition | Opened (record) |
| T14 | R. D. Cook, D. S. Malkus, M. E. Plesha, R. J. Witt, *Concepts and Applications of Finite Element Analysis*, 4th ed., Wiley, 2002 | Q4 elements, plane stress | Book (record) |
| T15 | G. B. Sinclair, Applied Mechanics Reviews 57(4), 251–298, 2004, doi:10.1115/1.1762503 | Stress singularities | Opened |
| T16 | BS EN 10025-2:2019, BSI, 31 Aug 2019 | S355 steel | Opened (record) |
| T17 | M. Huang, *Vehicle Crash Mechanics*, CRC Press, 2002 | Crash pulses (optional) | Book (record) |

## Values with no source (assumptions, labelled in the code)
Crush curves of TecPro, guardrail, tyre walls and car noses; hydraulic
parameters; the weather model (grip ratios, 0.6 %/°C foam coefficient,
4 %/°C valve lag, camera errors); fuel loads; impact angles of the five
uncalibrated cases; Rodríguez's impact speed; weather on the day where not
documented.
