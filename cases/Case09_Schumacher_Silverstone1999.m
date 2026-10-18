%% =====================================================================
%  CASE STUDY 9 — MICHAEL SCHUMACHER, SILVERSTONE, 11 JULY 1999 (Stowe, lap 1)
%  ---------------------------------------------------------------------
%  Four cases (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - tyre barrier
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE (+20 cm)
%    Case 4  COMPLETE SYSTEM, LARGE SPACE (2.5 m sled, ~2.6 m travel)
%  x 8 external conditions x a range of impact angles.
%
%  DOCUMENTED DATA (REFERENCES.md):
%    - Rear brake failure: braking began at 306 km/h, front wheels
%      locked at 204 km/h, ~1.1 g average in the gravel             [S13]
%    - Hit the tyre barrier at 107 km/h; broken leg                  [S13]
%    - Peak g not published
%
%  ASSUMPTIONS:
%    - 600 kg car incl. driver + ~70 kg lap-1 fuel -> 670 kg
%    - Near head-on: 80 deg nominal, swept
%    - Dry (not verified in the sources used)
%
%  NOTE: no recorded g, so this case is NOT calibrated. The tyre-barrier
%  model is an estimate and likely too stiff for a deep tyre wall; the
%  'Actual' result is therefore an upper bound.
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

crash.id              = 9;
crash.name            = 'Case study 9 — Michael Schumacher, Silverstone 1999 (Stowe)';
crash.shortName       = 'Schumacher 1999';
crash.vBrake_kmh      = 306;         % [S13]
crash.vImpact_kmh     = 107;         % [S13]
crash.realGrip        = 1.0;
crash.barrierType     = 'tyre';      % [S13]
crash.carEra          = '2000s';
crash.mass            = 670;         % ~600 kg + ~70 kg fuel (estimate)
crash.massNote        = '~600 kg incl. driver + ~70 kg lap-1 fuel (estimate)';
crash.angleNominal    = 80;          % ASSUMPTION: near head-on
crash.angleSweep      = 30:5:90;
crash.angleNote       = 'near head-on (assumed 80 deg)';
crash.dayCondKey      = 'dry';
out = runCaseStudy(crash, fullfile(here, '..', 'results', 'case09'));
