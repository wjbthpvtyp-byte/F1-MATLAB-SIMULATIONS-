%% =====================================================================
%  CASE STUDY 3 — ANTHOINE HUBERT, SPA-FRANCORCHAMPS, 31 AUG 2019 (F2)   [FATAL]
%  ---------------------------------------------------------------------
%  Four cases (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - run-off barrier at Raidillon exit (type not stated; tyre wall assumed)
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE (+20 cm)
%    Case 4  COMPLETE SYSTEM, LARGE SPACE (2.5 m sled, ~2.6 m travel)
%  x 8 external conditions x a range of impact angles.
%
%  DOCUMENTED DATA (REFERENCES.md):
%    - Barrier impact 216 km/h at ~40 deg, peak 33.7 g               [S6]
%    - Car rebounded toward the track and was hit side-on by Correa
%      at 218 km/h, ~86 deg: 81.8 g on Hubert's car, 65.1 g on Correa's  [S6]
%    - Death from the secondary (car-to-car) impact                     [S6]
%    - Dallara F2 2018: 720 kg incl. driver and fuel                    [S18]
%
%  ASSUMPTIONS:
%    - Barrier type not stated by the FIA: tyre barrier assumed
%    - Weather: dry assumed (not verified in the sources used)
%    - Speed before the barrier unknown -> taken equal to impact speed
%
%  WHY THIS CASE MATTERS: the barrier impact itself was survivable. The
%  danger was the REBOUND back toward the track. Compare the rebound
%  speeds of TecPro and our system (rebound lock) in Figure 1.
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

crash.id              = 3;
crash.name            = 'Case study 3 — Anthoine Hubert, Spa 2019 (F2, Raidillon exit)';
crash.shortName       = 'Hubert 2019';
crash.vBrake_kmh      = 216;         % unknown -> = impact speed (ASSUMPTION)
crash.vImpact_kmh     = 216;         % [S6]
crash.realGrip        = 1.0;         % dry assumed
crash.barrierType     = 'tyre';      % ASSUMPTION (FIA: "barrier")
crash.carEra          = '2020s';
crash.mass            = 720;         % [S18] incl. driver and fuel
crash.massNote        = 'Dallara F2 2018: 720 kg incl. driver and fuel (Wikipedia)';
crash.recordedG       = 33.7;        % [S6]
crash.angleDocumented = 40;          % [S6]
crash.angleNominal    = 40;          % replaced by the calibrated angle
crash.angleSweep      = 5:5:60;
crash.angleNote       = 'FIA: ~40 deg';
crash.dayCondKey      = 'dry';
out = runCaseStudy(crash, fullfile(here, '..', 'results', 'case03'));
