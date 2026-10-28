%% =====================================================================
%  RUN ALL 10 CASE STUDIES AND BUILD THE SUMMARY
%  ---------------------------------------------------------------------
%  Runs every script in cases/ (each saves its own figures and tables in
%  results/caseXX/), then writes results/summary_all_cases.csv/.png.
%  Takes several minutes: each case runs ~150 crash simulations.
%  =====================================================================
clear; clc; close all;
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
files = dir(fullfile(root, 'cases', 'Case*.m'));
outs = cell(numel(files), 1);
for i = 1:numel(files)
    fprintf('\n\n>>>>>> %s\n', files(i).name);
    outs{i} = runCaseFile(fullfile(files(i).folder, files(i).name));
end
summarizeStudies(outs, fullfile(root, 'results'));

function out = runCaseFile(path)
% Runs one case script inside its own workspace and returns its 'out'.
    run(path);
    close all;
end
