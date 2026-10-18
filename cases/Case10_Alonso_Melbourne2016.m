%% =====================================================================
%  CASE STUDY 10 — FERNANDO ALONSO, MELBOURNE, 20 MARCH 2016
%  ---------------------------------------------------------------------
%  Four cases (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - concrete wall (then a roll in the gravel)
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE (+20 cm)
%    Case 4  COMPLETE SYSTEM, LARGE SPACE (2.5 m sled, ~2.6 m travel)
%  x 8 external conditions x a range of impact angles.
%
%  DOCUMENTED DATA (REFERENCES.md):
%    - 313 km/h at the start of the move, 305 km/h at contact with
%      Gutierrez; front-right suspension failed                       [S14]
%    - Outside wall: 45 g lateral; roll in gravel 46 g; landing 20 g  [S14]
%    - Airborne 0.9 s, ~540 deg rotation; rib fractures               [S14]
%    - 2016 minimum weight 702 kg                                       [S19]
%
%  ASSUMPTIONS:
%    - Wall impact speed not published: 305 km/h used as upper bound
%    - Fuel ~70 kg -> 772 kg
%    - Glancing wall hit: calibrated to the 45 g wall reading
%    - Dry (not verified in the sources used)
%
%  LOW CONFIDENCE: lateral, multi-impact crash. Only the first wall hit is
%  modelled; the roll in the gravel is outside the barrier's reach.
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

crash.id              = 10;
crash.name            = 'Case study 10 — Fernando Alonso, Melbourne 2016';
crash.shortName       = 'Alonso 2016';
crash.vBrake_kmh      = 313;         % [S14]
crash.vImpact_kmh     = 305;         % [S14] speed at car contact (upper bound)
crash.realGrip        = 1.0;
crash.barrierType     = 'concrete';
crash.carEra          = '2020s';
crash.mass            = 772;         % 702 kg [S19] + ~70 kg fuel (estimate)
crash.massNote        = '702 kg 2016 minimum + ~70 kg fuel (estimate)';
crash.recordedG       = 45;          % [S14] lateral, outside wall
crash.angleNominal    = 20;
crash.angleSweep      = 2:2:30;
crash.angleNote       = 'glancing; angle not published';
crash.dayCondKey      = 'dry';
out = runCaseStudy(crash, fullfile(here, '..', 'results', 'case10'));
