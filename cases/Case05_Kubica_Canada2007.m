%% =====================================================================
%  CASE STUDY 5 — ROBERT KUBICA, MONTREAL, 10 JUNE 2007
%  ---------------------------------------------------------------------
%  Four cases (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - concrete wall
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE (+20 cm)
%    Case 4  COMPLETE SYSTEM, LARGE SPACE (2.5 m sled, ~2.6 m travel)
%  x 8 external conditions x a range of impact angles.
%
%  DOCUMENTED DATA (REFERENCES.md):
%    - Over 280 km/h when he clipped Trulli; 232 km/h into the wall  [S9]
%    - 75 g at the front of the car, 28 g at the rear (FIA / ADR)     [S8][S9]
%    - Concussion; survival cell intact                                  [S8]
%    - 2007 minimum weight 605 kg                                       [S19]
%
%  ASSUMPTIONS:
%    - Fuel ~50 kg at that stage of a refuelling race -> 655 kg
%    - Impact angle not published: calibrated to the 75 g front reading
%    - Dry (not verified in the sources used)
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

crash.id              = 5;
crash.name            = 'Case study 5 — Robert Kubica, Canada 2007';
crash.shortName       = 'Kubica 2007';
crash.vBrake_kmh      = 280;         % [S9] "over 280 km/h"
crash.vImpact_kmh     = 232;         % [S9]
crash.realGrip        = 1.0;
crash.barrierType     = 'concrete';
crash.carEra          = '2000s';
crash.mass            = 655;         % 605 kg [S19] + ~50 kg fuel (estimate)
crash.massNote        = '605 kg 2007 minimum + ~50 kg fuel (estimate)';
crash.recordedG       = 75;          % [S8][S9] front of car
crash.angleNominal    = 45;
crash.angleSweep      = 5:5:60;
crash.angleNote       = 'angle not published';
crash.dayCondKey      = 'dry';
out = runCaseStudy(crash, fullfile(here, '..', 'results', 'case05'));
