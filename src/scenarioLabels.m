function [keys, labels, short, cols] = scenarioLabels()
%SCENARIOLABELS  Names and colours used for the scenarios in every case.
    keys   = {'actual','tecpro','sled','rams','nocam','smart','failed'};
    labels = {'Actual barrier (real day)', 'Standard TecPro', ...
              'Option 1: sled only (20 cm)', 'Option 2: rams only (0 cm)', ...
              'Option 3: rams + sled, no camera', 'Option 4: COMPLETE (rams + sled + camera)', ...
              'Complete system FAILED (offline)'};
    short  = {'Actual','TecPro','Sled','Rams','Rams+Sled','Complete','Failed'};
    cols   = [0.35 0.35 0.35;   % actual
              0.90 0.30 0.20;   % tecpro
              0.10 0.55 0.90;   % sled
              0.95 0.65 0.10;   % rams
              0.55 0.35 0.80;   % rams+sled no camera
              0.20 0.70 0.35;   % complete
              0.60 0.60 0.60];  % failed
end
