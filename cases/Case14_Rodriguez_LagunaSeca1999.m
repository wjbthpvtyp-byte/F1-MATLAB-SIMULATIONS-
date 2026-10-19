%% =====================================================================
%  CASE STUDY 14 — GONZALO RODRIGUEZ, LAGUNA SECA, 11 SEPT 1999 (CART practice)   [FATAL]
%  ---------------------------------------------------------------------
%  A documented FATAL barrier impact from before TecPro was introduced
%  (FIA homologation 2006). Asks: what would the same impact have done
%  into TecPro, and into our system, at the same severity?
%
%  Four cases (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - tyre barrier in front of a concrete wall
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE (+20 cm)
%    Case 4  COMPLETE SYSTEM, LARGE SPACE (2.5 m sled, ~2.6 m travel)
%  + space-matched deep TecPro references, 8 conditions, angle sweep.
%
%  DOCUMENTED DATA (REFERENCES.md):
%    - Overshot the braking point at the Corkscrew at top speed, hit
%      the tyre barrier and the concrete wall behind it, flipped over
%                                                          [S23][S24][S25]
%    - The wall had only a thin layer of tyres                        [S23]
%    - Impact reported at more than 150 g                             [S24]
%    - Killed instantly: basilar skull fracture / massive head and
%      neck injuries                                             [S23][S25]
%    - Lola B99/00: 700 kg                                             [S27]
%
%  ASSUMPTIONS:
%    - Impact speed not published: 250 km/h assumed. Only the weather
%      scenarios depend on it; the real-day impact is calibrated to 150 g
%    - 700 kg car + driver + fuel -> 780 kg (estimate)
%    - Dry, 20 deg C
%
%  LIMITATIONS: the car flipped over the wall; only the frontal impact is modelled.
%  150 g is a press figure ("in excess of").
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

crash.id              = 14;
crash.name            = 'Case study 14 — Gonzalo Rodriguez, Laguna Seca 1999 (CART)';
crash.shortName       = 'Rodriguez 1999';
crash.vBrake_kmh      = 250;         % ASSUMPTION
crash.vImpact_kmh     = 250;         % ASSUMPTION (not published)
crash.realGrip        = 1.0;
crash.barrierType     = 'tyre';      % [S23] thin tyre layer on concrete
crash.carEra          = 'cart1990s';
crash.mass            = 780;
crash.massNote        = 'Lola B99/00 700 kg [S27] + driver + fuel (estimate)';
crash.recordedG       = 150;         % [S24]
crash.angleNominal    = 60;          % replaced by the calibrated angle
crash.angleSweep      = 5:5:60;
crash.angleNote       = 'front-first; angle not published';
crash.dayCondKey      = 'dry';
out = runCaseStudy(crash, fullfile(here, '..', 'results', 'case14'));
