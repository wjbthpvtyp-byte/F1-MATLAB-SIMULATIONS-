%% =====================================================================
%  CASE STUDY 11 — GREG MOORE, CALIFORNIA SPEEDWAY, 31 OCT 1999 (CART)   [FATAL]
%  ---------------------------------------------------------------------
%  A documented FATAL barrier impact from before TecPro was introduced
%  (FIA homologation 2006). Asks: what would the same impact have done
%  into TecPro, and into our system, at the same severity?
%
%  Four cases (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - infield concrete wall with no tyre wall
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE (+20 cm)
%    Case 4  COMPLETE SYSTEM, LARGE SPACE (2.5 m sled, ~2.6 m travel)
%  + space-matched deep TecPro references, 8 conditions, angle sweep.
%
%  DOCUMENTED DATA (REFERENCES.md):
%    - Entered the infield grass at more than 220 mph (350 km/h),
%      went airborne ~30 ft and barrel-rolled                         [S20]
%    - Hit an immovable infield concrete wall with no tyre wall,
%      at a 90-degree angle                                           [S20]
%    - 154 g recorded by the car's crash data sensor                  [S20]
%    - Died of severe head and internal injuries                      [S20]
%
%  ASSUMPTIONS:
%    - Car ~700 kg [S27] + driver + fuel -> 800 kg (estimate)
%    - The car was rolling, so only part of its energy went into the wall:
%      the impact is calibrated to the recorded 154 g
%    - Dry, 20 deg C
%
%  LIMITATIONS: oval circuit; ovals now use SAFER barriers rather than TecPro.
%  Rolling, airborne impact approximated by a 1-D equivalent impact.
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

crash.id              = 11;
crash.name            = 'Case study 11 — Greg Moore, California Speedway 1999 (CART)';
crash.shortName       = 'Moore 1999';
crash.vBrake_kmh      = 350;         % [S20]
crash.vImpact_kmh     = 350;         % [S20] "more than 220 mph" into the grass
crash.realGrip        = 1.0;
crash.barrierType     = 'concrete';  % [S20]
crash.carEra          = 'cart1990s';
crash.recordedG       = 154;         % [S20]
crash.angleDocumented = 90;          % [S20]
crash.angleNominal    = 30;          % replaced by the calibrated angle
crash.angleSweep      = 5:5:60;
crash.angleNote       = 'documented 90 deg after barrel roll';
crash.dayCondKey      = 'dry';
out = runCaseStudy(crash, fullfile(here, '..', 'results', 'case11'));
