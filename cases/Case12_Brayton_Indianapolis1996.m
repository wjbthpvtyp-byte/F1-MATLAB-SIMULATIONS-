%% =====================================================================
%  CASE STUDY 12 — SCOTT BRAYTON, INDIANAPOLIS, 17 MAY 1996 (practice)   [FATAL]
%  ---------------------------------------------------------------------
%  A documented FATAL barrier impact from before TecPro was introduced
%  (FIA homologation 2006). Asks: what would the same impact have done
%  into TecPro, and into our system, at the same severity?
%
%  Four cases (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - outside concrete retaining wall
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE (+20 cm)
%    Case 4  COMPLETE SYSTEM, LARGE SPACE (2.5 m sled, ~2.6 m travel)
%  + space-matched deep TecPro references, 8 conditions, angle sweep.
%
%  DOCUMENTED DATA (REFERENCES.md):
%    - Rear tyre deflated entering Turn 2; car spun and slid across the
%      track with almost no loss of speed                              [S21]
%    - Hit the outside retaining wall at more than 230 mph (370 km/h) [S21]
%    - Killed instantly: basilar skull fracture                       [S21]
%
%  ASSUMPTIONS:
%    - Lola T95/00 ~700 kg + driver + fuel -> 780 kg (estimate)
%    - No recorded peak, angle not published: 20 deg nominal (spinning car
%      sliding into an oval wall), swept 5-40 deg
%    - Dry, 20 deg C
%
%  LIMITATIONS: oval circuit; ovals now use SAFER barriers rather than TecPro.
%  Not calibrated: results depend on the assumed angle (see the sweep).
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

crash.id              = 12;
crash.name            = 'Case study 12 — Scott Brayton, Indianapolis 1996 (practice)';
crash.shortName       = 'Brayton 1996';
crash.vBrake_kmh      = 370;         % [S21] little speed lost while sliding
crash.vImpact_kmh     = 370;         % [S21]
crash.realGrip        = 1.0;
crash.barrierType     = 'concrete';  % [S21]
crash.carEra          = 'cart1990s';
crash.mass            = 780;
crash.massNote        = '~700 kg car + driver + fuel (estimate)';
crash.angleNominal    = 20;          % ASSUMPTION
crash.angleSweep      = 5:2.5:40;
crash.angleNote       = 'not published (assumed 20 deg)';
crash.dayCondKey      = 'dry';
out = runCaseStudy(crash, fullfile(here, '..', 'results', 'case12'));
