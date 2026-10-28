function [keys, labels, short, cols] = scenarioLabels()
%SCENARIOLABELS  Names and colours of the four cases used in every crash study.
    keys   = {'real','tecpro','small','large'};
    labels = {'Case 1: Real condition (actual barrier)', ...
              'Case 2: Standard TecPro', ...
              'Case 3: Complete system, small space (+20 cm)', ...
              'Case 4: Complete system, large space (~2.6 m)'};
    short  = {'Real','TecPro','Small','Large'};
    cols   = [0.35 0.35 0.35;   % real
              0.90 0.30 0.20;   % tecpro
              0.20 0.70 0.35;   % complete, small space
              0.10 0.45 0.85];  % complete, large space
end
