%% =====================================================================
%  CASE STUDY 2 — ROLAND RATZENBERGER, IMOLA, 30 APRIL 1994
%                 (Villeneuve corner, qualifying 2)                 [FATAL]
%  ---------------------------------------------------------------------
%  Four cases (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - bare concrete wall, no tyres or absorbers
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE (+20 cm)
%    Case 4  COMPLETE SYSTEM, LARGE SPACE (2.5 m sled, ~2.6 m travel)
%  x 7 external conditions x a range of impact angles.
%
%  DOCUMENTED DATA (REFERENCES.md):
%    - Front wing (damaged at Acque Minerali the lap before) failed
%      approaching Villeneuve at ~308 km/h                           [S16]
%    - Impact ~314 km/h; "over 300 km/h"                    [S2][S16][S17]
%    - Bare concrete retaining wall, no tyre barriers                [S2]
%    - Hit "almost head-on", then slid along the wall          [S2][S16]
%    - ~13:15, second qualifying session, Saturday                   [S16]
%    - ~500 g reported by newspapers (NOT from a data recorder)      [S2]
%    - Simtek S941. Death: basilar skull fracture; also aorta rupture
%      and tyre intrusion into the survival cell                     [S4]
%
%  ASSUMPTIONS:
%    - No effective braking after the wing failed (car went straight on,
%      wing under the car), so speed before braking = impact speed
%    - Angle 60 deg nominal ("almost head-on", then slid): swept 20-90
%    - Weather not documented in the sources found: assumed dry, 20 °C
%    - Mass 590 kg: 500 kg car (1994 min, excl. driver) + ~70 kg driver
%      + ~20 kg fuel (low fuel in qualifying)
%
%  WHAT THIS CASE TESTS: an impact with ~2 MJ into the barrier, about
%  ten times Senna's. It shows the LIMIT of any barrier in a small space.
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

crash.id           = 2;
crash.name         = 'Case study 2 — Roland Ratzenberger, Imola 1994 (Villeneuve)';
crash.shortName    = 'Ratzenberger 1994';
crash.vBrake_kmh   = 314;          % no effective braking (ASSUMPTION)
crash.vImpact_kmh  = 314;          % [S2]
crash.realGrip     = 1.0;          % assumed dry
crash.barrierType  = 'concrete';   % [S2]
crash.carEra       = '1994';
crash.mass         = 590;
crash.massNote     = '500 kg car (1994 min, excl. driver) + ~70 kg driver + ~20 kg qualifying fuel (estimate)';
crash.angleNominal = 60;           % ASSUMPTION
crash.angleSweep   = 20:5:90;
crash.angleNote    = 'documented only as "almost head-on", then slid along the wall';
crash.dayCondKey   = 'dry';

out = runCaseStudy(crash, fullfile(here, '..', 'results', 'case02'));
