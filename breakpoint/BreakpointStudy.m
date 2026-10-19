%% =====================================================================
%  BREAKPOINT STUDY — 15 HYPOTHETICAL IMPACTS + ENERGY BREAKPOINTS
%  ---------------------------------------------------------------------
%  These impacts are HYPOTHETICAL. They are not real crashes. They push
%  each barrier configuration past its limit to find where it stops
%  protecting the driver.
%
%  Car      : 2020s F1 car, 798 kg (2022 minimum incl. driver), dry, 20 °C
%  Grid     : speeds 150, 200, 250, 300, 350 km/h x angles 20, 45, 90 deg
%             = 15 hypothetical scenarios (H01 ... H15)
%  Configurations (same as the case studies, plus same-space references):
%    TecPro 1.0 m           standard barrier
%    Deep TecPro 1.2 m      passive, same space as the small system
%    Small system (Case 3)  TecPro + rams + 0.20 m sled + camera
%    Deep TecPro 3.5 m      passive, same space as the large system
%    Large system (Case 4)  TecPro + rams + 2.5 m sled + pre-retraction
%  Breakpoint: the normal impact energy at which the 3 ms peak deceleration
%  first exceeds a reference level, found by bisection on the normal speed.
%  Reference levels: 40 g, and 67 g (Grosjean 2020, survived). These are
%  reference points for comparison, NOT injury thresholds.
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));
outDir = fullfile(here, '..', 'results', 'breakpoint');
if ~exist(outDir, 'dir'), mkdir(outDir); end

car = carModel('2020s');                 % 798 kg
P   = defaultParams();
Plarge = P;  Plarge.S = P.S_large;  Plarge.v_pre = P.v_pre_large;
C.tec    = buildContact(car, barrierModel('tecpro', 1, 1.0));
C.deepS  = buildContact(car, barrierModel('tecpro', 1, 1.0 + P.S));
C.deepL  = buildContact(car, barrierModel('tecpro', 1, 1.0 + P.S_large));

cfgKeys  = {'tecpro', 'deepS', 'small', 'deepL', 'large'};
cfgNames = {'TecPro 1.0 m', 'Deep TecPro 1.2 m (passive)', 'Small system, +0.20 m (Case 3)', ...
            'Deep TecPro 3.5 m (passive)', 'Large system, +2.5 m (Case 4)'};
cols = [0.90 0.30 0.20; 0.95 0.65 0.55; 0.20 0.70 0.35; 0.55 0.70 0.95; 0.10 0.45 0.85];
peak = @(k, vn) runCfg(k, vn, car, C, P, Plarge);

%% ---------------- 1. THE 15 HYPOTHETICAL SCENARIOS ---------------------
speeds = [150 200 250 300 350];  angles = [20 45 90];
nH = numel(speeds)*numel(angles);
H = zeros(nH, 4 + numel(cfgKeys));       % id, speed, angle, KE, peaks...
h = 0;
fprintf('%-4s %8s %6s %8s %10s', 'ID', 'km/h', 'deg', 'v_n m/s', 'KE kJ');
fprintf(' %10s', 'TecPro', 'Deep1.2', 'Small', 'Deep3.5', 'Large');  fprintf('\n');
for v = speeds
    for a = angles
        h = h + 1;
        vn = v/3.6*sind(a);
        KE = 0.5*car.mass*vn^2/1e3;
        pk = cellfun(@(k) peak(k, vn), cfgKeys);
        H(h,:) = [h v a KE pk];
        fprintf('H%02d  %8d %6d %8.1f %10.0f', h, v, a, vn, KE);  fprintf(' %8.1f g', pk);  fprintf('\n');
    end
end
T = array2table(H, 'VariableNames', [{'ID','Speed_kmh','Angle_deg','NormalEnergy_kJ'}, ...
    strcat('PeakG_', cfgKeys)]);
writetable(T, fullfile(outDir, 'breakpoint_15_scenarios.csv'));

%% ---------------- 2. BREAKPOINTS ----------------------------------------
levels = [40 67];
BP = zeros(numel(cfgKeys), numel(levels));
for k = 1:numel(cfgKeys)
    for j = 1:numel(levels)
        lo = 1;  hi = 120;
        if peak(cfgKeys{k}, hi) < levels(j)
            vn = hi;
        else
            for it = 1:22
                mid = 0.5*(lo + hi);
                if peak(cfgKeys{k}, mid) < levels(j), lo = mid; else, hi = mid; end
            end
            vn = 0.5*(lo + hi);
        end
        BP(k,j) = 0.5*car.mass*vn^2/1e3;
    end
end
fprintf('\nBreakpoint = normal impact energy at which the peak first exceeds the level\n');
fprintf('%-34s %14s %14s\n', 'Configuration', 'at 40 g (kJ)', 'at 67 g (kJ)');
for k = 1:numel(cfgKeys)
    fprintf('%-34s %14.0f %14.0f\n', cfgNames{k}, BP(k,1), BP(k,2));
end
TB = table(cfgNames(:), BP(:,1), BP(:,2), 'VariableNames', ...
    {'Configuration', 'Breakpoint40g_kJ', 'Breakpoint67g_kJ'});
writetable(TB, fullfile(outDir, 'breakpoint_energies.csv'));

%% ---------------- 3. PEAK g vs ENERGY CURVES -----------------------------
E = linspace(20, 2000, 60);                       % normal energy [kJ]
curves = zeros(numel(cfgKeys), numel(E));
for i = 1:numel(E)
    vn = sqrt(2*E(i)*1e3/car.mass);
    for k = 1:numel(cfgKeys), curves(k,i) = peak(cfgKeys{k}, vn); end
end
f = figure('Name', 'Breakpoint study', 'Color', 'w', 'Position', [60 60 1100 600]);
hold on; grid on; box on;
for k = 1:numel(cfgKeys)
    ls = '-';  if any(strcmp(cfgKeys{k}, {'deepS','deepL'})), ls = '--'; end
    plot(E, curves(k,:), ls, 'Color', cols(k,:), 'LineWidth', 2.2);
end
plot(H(:,4), H(:,5:end), 'k.', 'MarkerSize', 10, 'HandleVisibility', 'off');
yline(67, ':k', '67 g (Grosjean 2020, survived)', 'LabelHorizontalAlignment', 'left');
yline(40, ':k', '40 g', 'LabelHorizontalAlignment', 'left');
set(gca, 'YScale', 'log');  ylim([5 1500]);
xlabel('Normal impact energy (kJ)');  ylabel('Peak deceleration, 3 ms clip (g)');
title('Where each barrier configuration breaks (798 kg car, dry; dots = the 15 hypothetical scenarios)');
legend(cfgNames, 'Location', 'northwest');
exportgraphics(f, fullfile(outDir, 'breakpoint_curves.png'), 'Resolution', 200);
fprintf('\nResults saved in %s\n', outDir);


function g = runCfg(k, vn, car, C, P, Plarge)
% Peak 3 ms deceleration of configuration k at normal speed vn.
    switch k
        case 'tecpro', r = simulateCrash('passive', vn, car, C.tec,   P);
        case 'deepS',  r = simulateCrash('passive', vn, car, C.deepS, P);
        case 'small',  r = simulateCrash('smart',   vn, car, C.tec,   P);
        case 'deepL',  r = simulateCrash('passive', vn, car, C.deepL, P);
        case 'large',  r = simulateCrash('smart',   vn, car, C.tec,   Plarge);
    end
    m = crashMetrics(r, P);
    g = m.clip3;
end
