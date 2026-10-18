%% =====================================================================
%  CASE STUDY 6 — CARLOS SAINZ, SOCHI, 10 OCT 2015 (FP3, Turn 13)
%  ---------------------------------------------------------------------
%  Four cases (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - TecPro (so Case 1 = Case 2 here)
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE (+20 cm)
%    Case 4  COMPLETE SYSTEM, LARGE SPACE (2.5 m sled, ~2.6 m travel)
%  x 8 external conditions x a range of impact angles.
%
%  DOCUMENTED DATA (REFERENCES.md):
%    - 153 km/h into the TecPro barrier, stopped in ~4 m           [S10]
%    - 46 g reported (FIA safety director); later FIA analysis ~40 g [S10][S11]
%    - TecPro rebounded onto the car and trapped him               [S10]
%    - 2015 minimum weight 702 kg                                       [S19]
%
%  ASSUMPTIONS:
%    - Fuel ~30 kg in practice -> 732 kg
%    - 46 g used for calibration (with ~40 g the impact is milder)
%    - Dry (not verified in the sources used)
%
%  WHY THIS CASE MATTERS: the only crash into TecPro itself, and TecPro's
%  rebound was the problem. Our system keeps TecPro and adds rebound lock.
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

crash.id              = 6;
crash.name            = 'Case study 6 — Carlos Sainz, Sochi 2015 (TecPro)';
crash.shortName       = 'Sainz 2015';
crash.vBrake_kmh      = 153;         % unknown -> = impact speed (ASSUMPTION)
crash.vImpact_kmh     = 153;         % [S10]
crash.realGrip        = 1.0;
crash.barrierType     = 'tecpro';    % [S10]
crash.carEra          = '2020s';     % 2014+ nose structure
crash.mass            = 732;         % 702 kg [S19] + ~30 kg fuel (estimate)
crash.massNote        = '702 kg 2015 minimum + ~30 kg practice fuel (estimate)';
crash.recordedG       = 46;          % [S11] (FIA later ~40 g [S10])
crash.angleNominal    = 80;
crash.angleSweep      = 10:5:90;
crash.angleNote       = 'described as near head-on';
crash.dayCondKey      = 'dry';
out = runCaseStudy(crash, fullfile(here, '..', 'results', 'case06'));
