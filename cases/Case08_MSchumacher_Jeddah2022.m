%% =====================================================================
%  CASE STUDY 8 — MICK SCHUMACHER, JEDDAH, 26 MARCH 2022 (qualifying, Turn 10)
%  ---------------------------------------------------------------------
%  Four cases (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - concrete wall
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE (+20 cm)
%    Case 4  COMPLETE SYSTEM, LARGE SPACE (2.5 m sled, ~2.6 m travel)
%  x 8 external conditions x a range of impact angles.
%
%  DOCUMENTED DATA (REFERENCES.md):
%    - ~270 km/h (driver's estimate), lost the rear in the esses     [S12]
%    - 33 g; unhurt, missed the race                                 [S12]
%    - 2022 minimum weight 798 kg incl. driver, excl. fuel           [S19]
%
%  ASSUMPTIONS:
%    - Fuel ~15 kg in qualifying -> 813 kg
%    - Glancing impact: calibrated to the 33 g
%    - Night race under floodlights, dry
%
%  LOW CONFIDENCE: a glancing, mostly side-on hit. The 1-D frontal-crush
%  model only approximates it; treat the results as indicative.
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

crash.id              = 8;
crash.name            = 'Case study 8 — Mick Schumacher, Jeddah 2022 (Turn 10)';
crash.shortName       = 'M. Schumacher 2022';
crash.vBrake_kmh      = 270;         % [S12] driver estimate
crash.vImpact_kmh     = 270;         % [S12]
crash.realGrip        = 1.0;
crash.barrierType     = 'concrete';  % [S12]
crash.carEra          = '2020s';
crash.mass            = 813;         % 798 kg [S19] + ~15 kg fuel (estimate)
crash.massNote        = '798 kg 2022 minimum incl. driver + ~15 kg qualifying fuel (estimate)';
crash.recordedG       = 33;          % [S12]
crash.angleNominal    = 15;
crash.angleSweep      = 2:2:30;
crash.angleNote       = 'glancing; angle not published';
crash.dayCondKey      = 'night';
out = runCaseStudy(crash, fullfile(here, '..', 'results', 'case08'));
