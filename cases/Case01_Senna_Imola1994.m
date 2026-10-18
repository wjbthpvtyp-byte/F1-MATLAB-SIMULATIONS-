%% =====================================================================
%  CASE 1 — AYRTON SENNA, IMOLA, 1 MAY 1994 (Tamburello)   [FATAL]
%  ---------------------------------------------------------------------
%  Same impact, every barrier option (see src/runScenarios.m):
%    BASELINES : Actual barrier (unprotected concrete wall) | Standard TecPro
%    OUR SYSTEM: Option 1 sled only | Option 2 rams only |
%                Option 3 rams + sled, no camera | Option 4 COMPLETE system
%    FAIL-SAFE : complete system offline (must equal TecPro)
%  ...repeated for 7 external conditions (rain, heat, cold, sun glare...)
%  and for a range of impact angles (angle not published).
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
[R, M, info] = runScenarios(crash, car, dayCond, angleNominal, P);
[keys, labels, short, cols] = scenarioLabels();
nS = numel(keys);

fprintf('\nReal-day conditions: %s, impact %.0f km/h at %.0f deg -> %.1f m/s normal, %.0f kJ\n', ...
    dayCond.name, info.vImpact_kmh, info.angle, info.vNormal, info.KE_kJ);
fprintf('Actual barrier: %s\n\n', info.barrierName);
fprintf('%-44s %9s %9s %8s %10s %9s\n','Scenario','Peak g','vs TecPro','HIC15','Car travel','Rebound');
for k = 1:nS
    m = M.(keys{k});
    fprintf('%-44s %7.1f g %+8.1f%% %8.0f %8.2f m %6.1f km/h\n', labels{k}, m.clip3, ...
        100*(m.clip3/M.tecpro.clip3 - 1), m.HIC15, m.stopDist, m.rebound);
end
fprintf('\nCamera adds (option 3 -> 4): %.1f g lower peak\n', M.nocam.clip3 - M.smart.clip3);
fprintf('Fail-safe check: failed = %.1f g, TecPro = %.1f g\n', M.failed.clip3, M.tecpro.clip3);

% --- Figure 1: the real day -----------------------------------------------
f1 = figure('Name','Case 1 — real day','Color','w','Position',[30 50 1400 600]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
nexttile; hold on; grid on; box on;
for k = 2:nS                                   % actual wall is off the scale; shown in bar chart
    ls = '-'; lw = 1.6;
    if strcmp(keys{k},'failed'), ls = '--'; end
    if any(strcmp(keys{k},{'tecpro','smart'})), lw = 2.6; end
    plot(R.(keys{k}).t*1e3, R.(keys{k}).a_g, ls, 'Color', cols(k,:), 'LineWidth', lw);
end
xlabel('Time from contact (ms)'); ylabel('Deceleration (g)');
title(sprintf('Case 1: %.0f km/h at %.0f° (assumed), dry and sunny', info.vImpact_kmh, angleNominal));
legend(labels(2:nS), 'Location','southoutside');

nexttile; hold on; grid on; box on;
vals = cellfun(@(s) M.(s).clip3, keys);
b = bar(vals, 'FaceColor','flat'); b.CData = cols;
set(gca,'XTick',1:nS,'XTickLabel',short,'YScale','log');
text(1:nS, vals, compose('%.0f g', vals), 'HorizontalAlignment','center', ...
    'VerticalAlignment','bottom','FontWeight','bold');
ylabel('Peak deceleration, 3 ms clip (g, log scale)'); ylim([10 1000]);
title('Peak g: actual concrete wall vs every option');
exportgraphics(f1, fullfile(outDir, 'case01_real_day.png'), 'Resolution', 200);

%% ------------------ 3. IMPACT ANGLE SWEEP (unknown angle) ------------
fprintf('\nRunning angle sweep...\n');
pkA = zeros(nS, numel(angleSweep));
for i = 1:numel(angleSweep)
    [~, Mi] = runScenarios(crash, car, dayCond, angleSweep(i), P);
    for k = 1:nS, pkA(k,i) = Mi.(keys{k}).clip3; end
end
f2 = figure('Name','Case 1 — angle sweep','Color','w','Position',[70 70 950 560]);
hold on; grid on; box on;
for k = 1:nS
    ls = '-o'; if strcmp(keys{k},'failed'), ls = '--'; end
    plot(angleSweep, pkA(k,:), ls, 'Color', cols(k,:), 'LineWidth', 1.8, 'MarkerSize', 4);
end
xline(angleNominal, ':', 'Nominal (assumed)');
set(gca,'YScale','log');
xlabel('Impact angle to wall (deg)  —  documented only as "shallow"');
ylabel('Peak deceleration, 3 ms clip (g)');
title('Case 1: effect of the unknown impact angle');
legend(labels, 'Location','northwest');
exportgraphics(f2, fullfile(outDir, 'case01_angle_sweep.png'), 'Resolution', 200);

%% ------------------ 4. EXTERNAL CONDITIONS ---------------------------
condKeys = {'dry','light_rain','heavy_rain','cold','hot','sun_glare','worst'};
nC = numel(condKeys);
pkC = zeros(nC, nS);  hicC = pkC;  vImp = zeros(nC,1);  condNames = cell(nC,1);
fprintf('Running %d external-condition scenarios...\n', nC);
for i = 1:nC
    c = weatherScenario(condKeys{i});
    [~, Mi, Ii] = runScenarios(crash, car, c, angleNominal, P);
    condNames{i} = c.name;  vImp(i) = Ii.vImpact_kmh;
    for k = 1:nS
        pkC(i,k)  = Mi.(keys{k}).clip3;
        hicC(i,k) = Mi.(keys{k}).HIC15;
    end
end

fprintf('\nPeak g (3 ms clip) for every condition and option:\n');
fprintf('%-42s %6s', 'Condition', 'km/h');  fprintf(' %9s', short{:});  fprintf('\n');
for i = 1:nC
    fprintf('%-42s %6.0f', condNames{i}, vImp(i));  fprintf(' %9.1f', pkC(i,:));  fprintf('\n');
end

f3 = figure('Name','Case 1 — conditions','Color','w','Position',[110 110 1400 600]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
nexttile;
sel = 2:6;                                     % TecPro + 4 options
bb = bar(pkC(:,sel), 'grouped'); grid on; box on;
for j = 1:numel(sel), bb(j).FaceColor = cols(sel(j),:); end
set(gca,'XTick',1:nC,'XTickLabel',condNames,'XTickLabelRotation',30);
ylabel('Peak deceleration, 3 ms clip (g)');
title('TecPro vs our four options under each condition');
legend(labels(sel), 'Location','northwest');
nexttile;
red = 100*(1 - pkC(:,3:6)./pkC(:,2));
bb2 = bar(red, 'grouped'); grid on; box on;
for j = 1:4, bb2(j).FaceColor = cols(j+2,:); end
set(gca,'XTick',1:nC,'XTickLabel',condNames,'XTickLabelRotation',30);
ylabel('Peak g reduction vs TecPro (%)  [negative = worse]');
title('How much each option helps (or hurts)');
yline(0,'k-');
legend(labels(3:6), 'Location','southoutside');
exportgraphics(f3, fullfile(outDir, 'case01_conditions.png'), 'Resolution', 200);

%% ------------------ 5. SAVE RESULTS FOR THE PAPER ---------------------
T = array2table(pkC, 'VariableNames', strcat('PeakG_', matlab.lang.makeValidName(short)));
T = [table(condNames, vImp, 'VariableNames', {'Condition','ImpactSpeed_kmh'}), T, ...
     array2table(hicC, 'VariableNames', strcat('HIC_', matlab.lang.makeValidName(short)))];
writetable(T, fullfile(outDir, 'case01_conditions.csv'));
TA = [table(angleSweep', 'VariableNames', {'Angle_deg'}), ...
      array2table(pkA', 'VariableNames', strcat('PeakG_', matlab.lang.makeValidName(short)))];
writetable(TA, fullfile(outDir, 'case01_angle_sweep.csv'));
fprintf('\nFigures and CSV tables saved in %s\n', outDir);
