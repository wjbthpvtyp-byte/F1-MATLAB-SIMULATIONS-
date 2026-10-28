%% =====================================================================
%  CASE STUDY 13 — FRANCOIS CEVERT, WATKINS GLEN, 6 OCT 1973 (qualifying)   [FATAL]
%  ---------------------------------------------------------------------
%  A documented FATAL barrier impact from before TecPro was introduced
%  (FIA homologation 2006). Asks: what would the same impact have done
%  into TecPro, and into our system, at the same severity?
%
%  Four cases (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - steel guardrail (Armco)
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE (+20 cm)
%    Case 4  COMPLETE SYSTEM, LARGE SPACE (2.5 m sled, ~2.6 m travel)
%  + space-matched deep TecPro references, 8 conditions, angle sweep.
%
%  DOCUMENTED DATA (REFERENCES.md):
%    - Spun in the Esses and swerved across the track at about
%      150 mph (241 km/h), per Jackie Stewart                          [S22]
%    - Hit the outside guardrail almost head-on, at a near 90 deg angle,
%      uprooting and lifting the barrier                               [S22]
%    - Killed instantly by the guardrail                               [S22]
%
%  ASSUMPTIONS:
%    - 1973 car ~575 kg + driver + fuel -> 650 kg (estimate)
%    - Speed from an eyewitness; angle 80 deg nominal, swept 30-90 deg
%    - Dry, 20 deg C
%
%  LIMITATIONS: no crash structure in 1973 cars; the barrier itself caused the
%  fatal injuries, which a 1-D model cannot represent. Not calibrated.
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

crash.id              = 13;
crash.name            = 'Case study 13 — Francois Cevert, Watkins Glen 1973';
crash.shortName       = 'Cevert 1973';
crash.vBrake_kmh      = 241;         % [S22] eyewitness
crash.vImpact_kmh     = 241;         % [S22]
crash.realGrip        = 1.0;
crash.barrierType     = 'armco';     % [S22]
crash.carEra          = '1973';
crash.angleNominal    = 80;          % [S22] "near 90 deg"
crash.angleSweep      = 30:5:90;
crash.angleNote       = 'near 90 deg (80 deg used)';
crash.dayCondKey      = 'dry';
out = runCaseStudy(crash, fullfile(here, '..', 'results', 'case13'));
