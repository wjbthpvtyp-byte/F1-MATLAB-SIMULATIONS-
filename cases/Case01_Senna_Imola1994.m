%% =====================================================================
%  CASE STUDY 1 — AYRTON SENNA, IMOLA, 1 MAY 1994 (Tamburello)   [FATAL]
%  ---------------------------------------------------------------------
%  Four cases (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - unprotected concrete wall (what was there)
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE (+20 cm)
%    Case 4  COMPLETE SYSTEM, LARGE SPACE (2.5 m sled, ~2.6 m travel)
%  x 7 external conditions x a range of impact angles.
%
%  DOCUMENTED DATA (REFERENCES.md):
%    - ~309 km/h (192 mph) 1.5 s before impact                     [S1][S3]
%    - 211 km/h (131 mph) at impact, after heavy braking            [S1][S2]
%    - Unprotected concrete wall, ~38 m from the track              [S1][S3]
%    - Angle described only as "shallow" (no number published)      [S1]
%    - Dry and sunny; 14:17 local time, lap 7                       [S2]
%    - Safety car laps 1-5 after start crash: tyres cooled          [S2]
%    - Death: right-front wheel/suspension struck the helmet        [S1]
%
%  ASSUMPTIONS: angle 25 deg (swept 10-45), 20 °C air, 610 kg, 1994-era
%  nose crush stiffness (src/carModel.m).
%
%  LIMITATION: a 1-D model cannot simulate the wheel striking the helmet.
%  The paper must not claim the system would definitely have saved him.
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

crash.id           = 1;
crash.name         = 'Case study 1 — Ayrton Senna, Imola 1994 (Tamburello)';
crash.shortName    = 'Senna 1994';
crash.vBrake_kmh   = 309;          % [S1][S3]
crash.vImpact_kmh  = 211;          % [S1][S2]
crash.realGrip     = 1.0;          % dry  [S2]
crash.barrierType  = 'concrete';   % [S1][S2]
crash.carEra       = '1994';       % 610 kg default (see carModel)
crash.angleNominal = 25;           % ASSUMPTION
crash.angleSweep   = 10:2.5:45;
crash.angleNote    = 'documented only as "shallow"';
crash.dayCondKey   = 'dry';

out = runCaseStudy(crash, fullfile(here, '..', 'results', 'case01'));
