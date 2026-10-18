%% =====================================================================
%  CASE STUDY 4 — ROMAIN GROSJEAN, BAHRAIN, 29 NOV 2020 (Turn 3, lap 1)
%  ---------------------------------------------------------------------
%  Four cases (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - triple steel guardrail (Armco)
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE (+20 cm)
%    Case 4  COMPLETE SYSTEM, LARGE SPACE (2.5 m sled, ~2.6 m travel)
%  x 8 external conditions x a range of impact angles.
%
%  DOCUMENTED DATA (REFERENCES.md):
%    - Lost control at 241 km/h; hit barrier at 192 km/h, 29 deg      [S7]
%    - Resultant peak 67 g; survival cell pierced the guardrail          [S7]
%    - Burns to hands; out unaided after 27 s                            [S7]
%    - 2020 minimum weight 746 kg (incl. driver, excl. fuel)            [S19]
%
%  ASSUMPTIONS:
%    - Fuel on lap 1: ~100 kg (estimate) -> 846 kg
%    - Night race under floodlights, dry (not verified in the sources used)
%
%  VALIDATION: with the documented 29 deg, the model's Armco case should
%  give close to the recorded 67 g. The calibration prints the angle it
%  needs; if it is close to 29 deg, the model is consistent with the FIA data.
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

crash.id              = 4;
crash.name            = 'Case study 4 — Romain Grosjean, Bahrain 2020 (Turn 3)';
crash.shortName       = 'Grosjean 2020';
crash.vBrake_kmh      = 241;         % [S7] speed when control was lost
crash.vImpact_kmh     = 192;         % [S7]
crash.realGrip        = 1.0;
crash.barrierType     = 'armco';     % [S7] triple guardrail
crash.carEra          = '2020s';
crash.mass            = 846;         % 746 kg [S19] + ~100 kg lap-1 fuel (estimate)
crash.massNote        = '746 kg 2020 minimum incl. driver + ~100 kg lap-1 fuel (estimate)';
crash.recordedG       = 67;          % [S7]
crash.angleDocumented = 29;          % [S7]
crash.angleNominal    = 29;
crash.angleSweep      = 10:5:60;
crash.angleNote       = 'FIA: 29 deg';
crash.dayCondKey      = 'night';
out = runCaseStudy(crash, fullfile(here, '..', 'results', 'case04'));
