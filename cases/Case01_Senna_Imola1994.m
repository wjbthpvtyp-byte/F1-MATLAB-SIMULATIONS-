%% =====================================================================
%  CASE 1 — AYRTON SENNA, IMOLA, 1 MAY 1994 (Tamburello)   [FATAL]
%  ---------------------------------------------------------------------
%  Compares four barrier situations for the same impact:
%    1. ACTUAL  - unprotected concrete wall (what was there)
%    2. TECPRO  - a standard TecPro barrier in the same place
%    3. SMART   - our system: TecPro unchanged + parallel rams + 20 cm sled
%                 + camera prediction
%    4. FAILED  - our system with hydraulics/electronics offline
%  ...and repeats them for different external conditions (rain, heat,
%  cold, sun glare) and for a range of impact angles.
%
%  DOCUMENTED DATA (see REFERENCES.md, refs [S1]-[S4]):
%    - Speed into Tamburello: ~309 km/h (192 mph) 1.5 s before impact
%    - Impact speed: 211 km/h (131 mph) after heavy braking, two downshifts
%    - Barrier: unprotected concrete wall, ~38 m from the track
%    - Impact angle: described only as "shallow" (no number published)
%    - Weather: dry and sunny; crash at 14:17 local time, lap 7
%    - Safety car laps 1-5 after start-line crash: tyre temperatures dropped
%    - Cause of death: head injuries from right-front wheel/suspension parts
%      striking the helmet (the deceleration itself may have been survivable)
%
%  ASSUMPTIONS (clearly marked, varied in sweeps):
%    - Impact angle: 25 deg nominal, swept 10-45 deg
%    - Air temperature: 20 deg C (not documented)
%    - Car + driver + fuel mass: 610 kg (see carModel.m)
%    - Car crush stiffness: 1994-era estimate (see carModel.m)
%
%  LIMITATION: this 1-D model computes deceleration on the car. It cannot
%  model the wheel/suspension striking the helmet. Lower deceleration and
%  less intrusion make such strikes less likely, but the paper must not
%  claim the system would definitely have prevented this death.
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));
outDir = fullfile(here, '..', 'results', 'case01');
if ~exist(outDir, 'dir'), mkdir(outDir); end

%% ------------------------- 1. CASE DATA ------------------------------
crash.id          = 1;
crash.name        = 'Ayrton Senna — Imola 1994 (Tamburello)';
crash.vBrake_kmh  = 309;      % speed before braking/sliding [km/h]   [S1][S3]
crash.vImpact_kmh = 211;      % documented impact speed      [km/h]   [S1][S2]
crash.realGrip    = 1.0;      % dry track on the day                  [S2]
crash.barrierType = 'concrete';                                     % [S1][S2]
crash.fatal       = true;
angleNominal      = 25;       % ASSUMPTION: documented only as "shallow"
angleSweep        = 10:2.5:45;

car = carModel('1994');
P   = defaultParams();

fprintf('%s\n%s\n', crash.name, repmat('=',1,60));
fprintf('Car mass used: %.0f kg  (%s)\n', car.mass, car.massNote);

%% ------------------- 2. THE ACTUAL DAY (dry, sunny) ------------------
dayCond = weatherScenario('dry');
[R, M, info] = runFourScenarios(crash, car, dayCond, angleNominal, P);

scen  = {'actual','tecpro','smart','failed'};
label = {'Actual: concrete wall','Standard TecPro','Smart barrier','Smart barrier (system failed)'};
cols  = [0.35 0.35 0.35; 0.90 0.30 0.20; 0.20 0.70 0.35; 0.60 0.60 0.60];

fprintf('\nReal-day conditions: %s, impact %.0f km/h at %.0f deg -> %.1f m/s normal, %.0f kJ\n\n', ...
    dayCond.name, info.vImpact_kmh, info.angle, info.vNormal, info.KE_kJ);
fprintf('%-32s %9s %9s %10s %9s\n','Scenario','Peak g','HIC15','Car travel','Rebound');
for k = 1:4
    m = M.(scen{k});
    fprintf('%-32s %7.1f g %9.0f %8.2f m %6.1f km/h\n', label{k}, m.clip3, m.HIC15, m.stopDist, m.rebound);
end
fprintf('\nSmart vs actual wall : %5.1f %% lower peak g\n', 100*(1 - M.smart.clip3/M.actual.clip3));
fprintf('Smart vs TecPro      : %5.1f %% lower peak g\n', 100*(1 - M.smart.clip3/M.tecpro.clip3));
fprintf('Fail-safe check      : failed = %.1f g, TecPro = %.1f g\n', M.failed.clip3, M.tecpro.clip3);

% --- Figure 1: deceleration on the real day -----------------------------
f1 = figure('Name','Case 1 — real day','Color','w','Position',[40 60 1250 520]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
nexttile; hold on; grid on; box on;
for k = 1:4
    ls = '-'; if k == 4, ls = '--'; end
    plot(R.(scen{k}).t*1e3, R.(scen{k}).a_g, ls, 'Color', cols(k,:), 'LineWidth', 2);
end
set(gca, 'YScale', 'log'); ylim([1 1000]);
yline(67, ':', 'Grosjean 2020 (67 g, survived)', 'LabelHorizontalAlignment','left');
xlabel('Time from contact (ms)'); ylabel('Deceleration (g, log scale)');
title(sprintf('Case 1: %.0f km/h at %.0f° (assumed), dry', info.vImpact_kmh, angleNominal));
legend(label, 'Location','northeast');

nexttile; hold on; grid on; box on;
vals = cellfun(@(s) M.(s).clip3, scen);
b = bar(vals, 'FaceColor','flat'); b.CData = cols;
set(gca,'XTick',1:4,'XTickLabel',{'Concrete','TecPro','Smart','Smart (failed)'},'YScale','log');
text(1:4, vals, compose('%.0f g', vals), 'HorizontalAlignment','center', ...
    'VerticalAlignment','bottom','FontWeight','bold');
ylabel('Peak deceleration, 3 ms clip (g)'); ylim([1 2000]);
title('Peak g by barrier');
exportgraphics(f1, fullfile(outDir, 'case01_real_day.png'), 'Resolution', 200);

%% ------------------ 3. IMPACT ANGLE SWEEP (unknown angle) ------------
fprintf('\nRunning angle sweep...\n');
pkA = zeros(4, numel(angleSweep));
for i = 1:numel(angleSweep)
    [~, Mi] = runFourScenarios(crash, car, dayCond, angleSweep(i), P);
    for k = 1:4, pkA(k,i) = Mi.(scen{k}).clip3; end
end
f2 = figure('Name','Case 1 — angle sweep','Color','w','Position',[80 80 900 520]);
hold on; grid on; box on;
for k = 1:3
    plot(angleSweep, pkA(k,:), '-o', 'Color', cols(k,:), 'LineWidth', 2, 'MarkerFaceColor', cols(k,:));
end
plot(angleSweep, pkA(4,:), '--', 'Color', cols(4,:), 'LineWidth', 1.5);
xline(angleNominal, ':', 'Nominal (assumed)');
set(gca,'YScale','log');
xlabel('Impact angle to wall (deg)  —  documented only as "shallow"');
ylabel('Peak deceleration, 3 ms clip (g)');
title('Case 1: effect of the unknown impact angle');
legend(label, 'Location','northwest');
exportgraphics(f2, fullfile(outDir, 'case01_angle_sweep.png'), 'Resolution', 200);

%% ------------------ 4. EXTERNAL CONDITIONS ---------------------------
condKeys = {'dry','light_rain','heavy_rain','cold','hot','sun_glare','worst'};
nC = numel(condKeys);
pkC = zeros(nC, 4);  hicC = pkC;  vImp = zeros(nC,1);  condNames = cell(nC,1);
fprintf('Running %d external-condition scenarios...\n', nC);
for i = 1:nC
    c = weatherScenario(condKeys{i});
    [~, Mi, Ii] = runFourScenarios(crash, car, c, angleNominal, P);
    condNames{i} = c.name;  vImp(i) = Ii.vImpact_kmh;
    for k = 1:4
        pkC(i,k)  = Mi.(scen{k}).clip3;
        hicC(i,k) = Mi.(scen{k}).HIC15;
    end
end

fprintf('\n%-44s %8s %9s %8s %8s %8s\n','Condition','v (km/h)','Concrete','TecPro','Smart','Failed');
for i = 1:nC
    fprintf('%-44s %8.0f %7.0f g %6.1f g %6.1f g %6.1f g\n', condNames{i}, vImp(i), pkC(i,:));
end

f3 = figure('Name','Case 1 — conditions','Color','w','Position',[120 120 1250 560]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
nexttile;
bb = bar(pkC(:,2:3), 'grouped'); grid on; box on;
bb(1).FaceColor = cols(2,:); bb(2).FaceColor = cols(3,:);
set(gca,'XTick',1:nC,'XTickLabel',condNames,'XTickLabelRotation',30);
ylabel('Peak deceleration, 3 ms clip (g)');
title('TecPro vs smart barrier under each condition');
legend({'Standard TecPro','Smart barrier'}, 'Location','northwest');
nexttile;
red = 100*(1 - pkC(:,3)./pkC(:,2));
bar(red, 'FaceColor', cols(3,:)); grid on; box on;
set(gca,'XTick',1:nC,'XTickLabel',condNames,'XTickLabelRotation',30);
ylabel('Peak g reduction vs TecPro (%)');
title('How much the smart system still helps');
yline(0,'k-');
exportgraphics(f3, fullfile(outDir, 'case01_conditions.png'), 'Resolution', 200);

%% ------------------ 5. SAVE RESULTS FOR THE PAPER ---------------------
T = table(condNames, vImp, pkC(:,1), pkC(:,2), pkC(:,3), pkC(:,4), ...
          hicC(:,1), hicC(:,2), hicC(:,3), ...
    'VariableNames', {'Condition','ImpactSpeed_kmh','PeakG_Concrete','PeakG_TecPro', ...
                      'PeakG_Smart','PeakG_SmartFailed','HIC_Concrete','HIC_TecPro','HIC_Smart'});
writetable(T, fullfile(outDir, 'case01_conditions.csv'));
TA = array2table([angleSweep' pkA'], 'VariableNames', ...
    {'Angle_deg','PeakG_Concrete','PeakG_TecPro','PeakG_Smart','PeakG_SmartFailed'});
writetable(TA, fullfile(outDir, 'case01_angle_sweep.csv'));
fprintf('\nFigures and CSV tables saved in %s\n', outDir);
