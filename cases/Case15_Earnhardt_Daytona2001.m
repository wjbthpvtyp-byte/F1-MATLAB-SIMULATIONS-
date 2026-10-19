%% =====================================================================
%  CASE STUDY 15 — DALE EARNHARDT, DAYTONA, 18 FEB 2001 (NASCAR, last lap)   [FATAL]
%  ---------------------------------------------------------------------
%  A documented FATAL barrier impact from before TecPro was introduced
%  (FIA homologation 2006). Asks: what would the same impact have done
%  into TecPro, and into our system, at the same severity?
%
%  Four cases (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - concrete retaining wall
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE (+20 cm)
%    Case 4  COMPLETE SYSTEM, LARGE SPACE (2.5 m sled, ~2.6 m travel)
%  + space-matched deep TecPro references, 8 conditions, angle sweep.
%
%  DOCUMENTED DATA (REFERENCES.md):
%    - Impact speed 157-161 mph (253-259 km/h)                       [S26]
%    - Trajectory angle 13.6 deg; heading 55-59 deg                    [S26]
%    - Delta-V 42-44 mph (68-71 km/h) incl. contact with Schrader's car;
%      pulse ~80 ms; sled tests -48 to -68 g                           [S26]
%    - Basilar skull fracture; seat belt separation a contributing
%      factor (NASCAR investigation)                                   [S26]
%
%  ASSUMPTIONS:
%    - Stock car ~1,540 kg + driver -> 1,600 kg (estimate)
%    - Calibrated to 58 g, the middle of the 48-68 g sled-test range
%    - Dry, 20 deg C
%
%  LIMITATIONS: a stock car, not a single-seater; oval wall (SAFER barriers were
%  introduced after this crash). The car crush curve is an estimate.
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

crash.id              = 15;
crash.name            = 'Case study 15 — Dale Earnhardt, Daytona 2001 (NASCAR)';
crash.shortName       = 'Earnhardt 2001';
crash.vBrake_kmh      = 256;         % [S26] 253-259 km/h
crash.vImpact_kmh     = 256;         % [S26]
crash.realGrip        = 1.0;
crash.barrierType     = 'concrete';  % [S26]
crash.carEra          = 'stockcar';
crash.recordedG       = 58;          % [S26] middle of 48-68 g
crash.angleDocumented = 13.6;        % [S26] trajectory angle
crash.angleNominal    = 13.6;
crash.angleSweep      = 4:2:30;
crash.angleNote       = 'trajectory angle 13.6 deg (NASCAR)';
crash.dayCondKey      = 'dry';
out = runCaseStudy(crash, fullfile(here, '..', 'results', 'case15'));
