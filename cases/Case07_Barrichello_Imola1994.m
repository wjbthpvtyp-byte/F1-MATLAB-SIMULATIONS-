%% =====================================================================
%  CASE STUDY 7 — RUBENS BARRICHELLO, IMOLA, 29 APRIL 1994 (Variante Bassa, Friday practice)
%  ---------------------------------------------------------------------
%  Four cases (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - tyre barrier
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE (+20 cm)
%    Case 4  COMPLETE SYSTEM, LARGE SPACE (2.5 m sled, ~2.6 m travel)
%  x 8 external conditions x a range of impact angles.
%
%  DOCUMENTED DATA (REFERENCES.md):
%    - 225 km/h when he hit the kerb, launched, landed on top of
%      the tyre barrier                                               [S2]
%    - 95 g; knocked unconscious                                     [S2]
%
%  ASSUMPTIONS:
%    - 1994 car 610 kg (as Case 1)
%    - Airborne impact on top of the tyres: the 1-D model treats it as an
%      equivalent horizontal impact calibrated to the 95 g
%    - Dry (not verified in the sources used)
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

crash.id              = 7;
crash.name            = 'Case study 7 — Rubens Barrichello, Imola 1994 (Variante Bassa)';
crash.shortName       = 'Barrichello 1994';
crash.vBrake_kmh      = 225;         % [S2]
crash.vImpact_kmh     = 225;         % [S2]
crash.realGrip        = 1.0;
crash.barrierType     = 'tyre';      % [S2]
crash.carEra          = '1994';
crash.recordedG       = 95;          % [S2]
crash.angleNominal    = 45;
crash.angleSweep      = 5:5:60;
crash.angleNote       = 'airborne impact, angle not published';
crash.dayCondKey      = 'dry';
out = runCaseStudy(crash, fullfile(here, '..', 'results', 'case07'));
