function out = runCaseStudy(crash, outDir)
%RUNCASESTUDY  Full analysis of one real crash: 4 cases x 7 conditions x angles.
%   out = runCaseStudy(crash, outDir)
%
%   crash fields (see cases/*.m):
%     id, name, shortName           identification
%     vBrake_kmh, vImpact_kmh       speed before braking/sliding and at impact
%     realGrip                      grip on the real day (1 = dry)
%     barrierType                   'concrete' | 'armco' | 'tyre' | 'tecpro'
%     carEra                        '1994' | '2020s'
%     mass (optional)               override car+driver+fuel mass [kg]
%     massNote (optional)           where the mass comes from
%     angleNominal, angleSweep      impact angle used and range swept [deg]
%     angleNote                     how the angle was obtained
%     dayCondKey                    weather on the real day (weatherScenario key)
%
%     recordedG (optional)          recorded peak g -> impact is calibrated
%     angleDocumented (optional)    published impact angle [deg]
%
%   Produces: console summary, 3 figures (PNG) and 2 CSV tables in outDir.

    if ~exist(outDir, 'dir'), mkdir(outDir); end
    tag = sprintf('case%02d', crash.id);

    car = carModel(crash.carEra);
    if isfield(crash, 'mass') && ~isempty(crash.mass)
        car.mass = crash.mass;
        if isfield(crash, 'massNote'), car.massNote = crash.massNote; end
    end
    P = defaultParams();
    [keys, labels, short, cols] = scenarioLabels();
    nS = numel(keys);

    fprintf('%s\n%s\n', crash.name, repmat('=', 1, 70));
    fprintf('Car mass used: %.0f kg  (%s)\n', car.mass, car.massNote);

    % --- calibrate to the recorded g-force when one exists -------------
    hasRec = isfield(crash, 'recordedG') && ~isempty(crash.recordedG);
    cal = struct('angle', NaN, 'energyFraction', NaN);
    if hasRec
        [ang, cal] = calibrateAngle(crash, car, P);
        fprintf('Recorded peak: %.1f g  ->  equivalent impact angle %.1f deg', crash.recordedG, ang);
        if ~isnan(cal.energyFraction)
            fprintf(' (documented %.0f deg; barrier absorbed %.0f %% of the geometric energy)', ...
                crash.angleDocumented, 100*cal.energyFraction);
        end
        fprintf('\n');
        crash.angleNominal = ang;
        crash.angleNote = sprintf('calibrated to the recorded %.1f g', crash.recordedG);
    end
    fprintf('Impact angle : %.1f deg  (%s)\n', crash.angleNominal, crash.angleNote);

    %% ---------------- 1. THE REAL DAY --------------------------------
    dayCond = weatherScenario(crash.dayCondKey);
    [R, M, info] = runScenarios(crash, car, dayCond, crash.angleNominal, P);

    fprintf('\nReal day: %s | impact %.0f km/h at %.0f deg -> %.1f m/s into barrier | energy %.0f kJ\n', ...
        dayCond.name, info.vImpact_kmh, info.angle, info.vNormal, info.KE_kJ);
    fprintf('Real barrier: %s\n\n', info.barrierName);
    fprintf('%-48s %9s %10s %8s %10s %10s\n', 'Case', 'Peak g', 'vs TecPro', 'HIC15', 'Car travel', 'Rebound');
    for k = 1:nS
        m = M.(keys{k});
        fprintf('%-48s %7.1f g %+9.1f%% %8.0f %8.2f m %6.2f km/h\n', labels{k}, m.clip3, ...
            100*(m.clip3/M.tecpro.clip3 - 1), m.HIC15, m.stopDist, m.rebound);
    end
    fprintf('\nTheoretical best (perfect controller, TecPro unchanged):\n');
    fprintf('   small space (+%.0f cm): %.1f g   -> Case 3 reaches %.1f g\n', ...
        100*P.S, info.bestSmall_g, M.small.clip3);
    fprintf('   large space (+%.1f m): %.1f g   -> Case 4 reaches %.1f g\n', ...
        P.S_large, info.bestLarge_g, M.large.clip3);
    fprintf('Fail-safe check (Case 3 offline): %.1f g vs TecPro %.1f g -> %s\n', ...
        M.failsafe.clip3, M.tecpro.clip3, string(info.failsafeOK));

    % --- Figure 1: the real day ---------------------------------------
    f1 = figure('Name', sprintf('%s — real day', crash.shortName), 'Color', 'w', ...
        'Position', [30 50 1500 560]);
    tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile; hold on; grid on; box on;
    for k = 1:nS
        lw = 2.2; if k == 1, lw = 1.2; end
        plot(R.(keys{k}).t*1e3, R.(keys{k}).a_g, 'Color', cols(k,:), 'LineWidth', lw);
    end
    plot(R.failsafe.t*1e3, R.failsafe.a_g, '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.2);
    allG = cellfun(@(s) M.(s).clip3, keys);
    ylim([0 min(1.15*max(allG(2:end)), 1.15*max(allG))]);
    xlabel('Time from contact (ms)'); ylabel('Deceleration (g)');
    title(sprintf('%.0f km/h at %.0f°, %s', info.vImpact_kmh, crash.angleNominal, lower(dayCond.name)));
    legend([labels, {'Fail-safe check: Case 3 offline'}], 'Location', 'southoutside');

    nexttile; hold on; grid on; box on;
    b = bar(allG, 'FaceColor', 'flat'); b.CData = cols;
    plot([2.6 3.4], [1 1]*info.bestSmall_g, 'k-', 'LineWidth', 2);
    plot([3.6 4.4], [1 1]*info.bestLarge_g, 'k-', 'LineWidth', 2);
    set(gca, 'XTick', 1:nS, 'XTickLabel', short, 'YScale', 'log');
    text(1:nS, allG, compose('%.0f g', allG), 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
    ylabel('Peak deceleration, 3 ms clip (g, log)');
    ylim([max(1, 0.5*min(allG)) 3*max(allG)]);
    if hasRec
        yline(crash.recordedG, '--', sprintf('Recorded %.0f g', crash.recordedG), ...
            'LabelHorizontalAlignment', 'left');
    end
    title('Peak g  (black line = theoretical best)');

    nexttile; hold on; grid on; box on;
    reb = cellfun(@(s) M.(s).rebound, keys);
    b2 = bar(reb, 'FaceColor', 'flat'); b2.CData = cols;
    set(gca, 'XTick', 1:nS, 'XTickLabel', short);
    text(1:nS, reb, compose('%.1f', reb), 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
    ylabel('Rebound speed toward the track (km/h)');
    title('Rebound (lower = less risk of secondary impact)');
    exportgraphics(f1, fullfile(outDir, [tag '_real_day.png']), 'Resolution', 200);

    %% ---------------- 2. ANGLE SWEEP ------------------------------------
    fprintf('\nRunning angle sweep (%d angles)...\n', numel(crash.angleSweep));
    nA = numel(crash.angleSweep);
    pkA = zeros(nS, nA);  bestA = zeros(2, nA);
    for i = 1:nA
        [~, Mi, Ii] = runScenarios(crash, car, dayCond, crash.angleSweep(i), P);
        for k = 1:nS, pkA(k,i) = Mi.(keys{k}).clip3; end
        bestA(:,i) = [Ii.bestSmall_g; Ii.bestLarge_g];
    end
    f2 = figure('Name', sprintf('%s — angle sweep', crash.shortName), 'Color', 'w', ...
        'Position', [70 70 1000 580]);
    hold on; grid on; box on;
    for k = 1:nS
        plot(crash.angleSweep, pkA(k,:), '-o', 'Color', cols(k,:), 'LineWidth', 2, ...
            'MarkerFaceColor', cols(k,:), 'MarkerSize', 4);
    end
    plot(crash.angleSweep, bestA(1,:), ':', 'Color', cols(3,:), 'LineWidth', 1.5);
    plot(crash.angleSweep, bestA(2,:), ':', 'Color', cols(4,:), 'LineWidth', 1.5);
    xline(crash.angleNominal, ':', 'Angle used');
    yline(67, '--k', 'Grosjean 2020: 67 g, survived', 'LabelHorizontalAlignment', 'left');
    set(gca, 'YScale', 'log');
    xlabel(sprintf('Impact angle to barrier (deg)  —  %s', crash.angleNote));
    ylabel('Peak deceleration, 3 ms clip (g)');
    title(sprintf('%s: effect of impact angle', crash.shortName));
    legend([labels, {'Theoretical best, small space', 'Theoretical best, large space'}], ...
        'Location', 'northwest');
    exportgraphics(f2, fullfile(outDir, [tag '_angle_sweep.png']), 'Resolution', 200);

    %% ---------------- 3. EXTERNAL CONDITIONS ----------------------------
    condKeys = {'dry', 'light_rain', 'heavy_rain', 'cold', 'hot', 'sun_glare', 'night', 'worst'};
    nC = numel(condKeys);
    pkC = zeros(nC, nS);  hicC = pkC;  trC = pkC;  rbC = pkC;  vImp = zeros(nC,1);
    condNames = cell(nC,1);  fsOK = false(nC,1);
    fprintf('Running %d external conditions...\n', nC);
    for i = 1:nC
        c = weatherScenario(condKeys{i});
        [~, Mi, Ii] = runScenarios(crash, car, c, crash.angleNominal, P);
        condNames{i} = c.name;  vImp(i) = Ii.vImpact_kmh;  fsOK(i) = Ii.failsafeOK;
        for k = 1:nS
            pkC(i,k)  = Mi.(keys{k}).clip3;
            hicC(i,k) = Mi.(keys{k}).HIC15;
            trC(i,k)  = Mi.(keys{k}).stopDist;
            rbC(i,k)  = Mi.(keys{k}).rebound;
        end
    end
    fprintf('\nPeak g (3 ms clip):\n%-44s %6s', 'Condition', 'km/h');
    fprintf(' %8s', short{:});  fprintf(' %9s\n', 'Fail-safe');
    for i = 1:nC
        fprintf('%-44s %6.0f', condNames{i}, vImp(i));  fprintf(' %8.1f', pkC(i,:));
        fprintf(' %9s\n', string(fsOK(i)));
    end

    f3 = figure('Name', sprintf('%s — conditions', crash.shortName), 'Color', 'w', ...
        'Position', [110 110 1400 600]);
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    nexttile;
    bb = bar(pkC(:,2:4), 'grouped'); grid on; box on;
    for j = 1:3, bb(j).FaceColor = cols(j+1,:); end
    set(gca, 'XTick', 1:nC, 'XTickLabel', condNames, 'XTickLabelRotation', 30);
    ylabel('Peak deceleration, 3 ms clip (g)');
    title('Cases 2–4 under each external condition');
    legend(labels(2:4), 'Location', 'northwest');
    nexttile;
    red = 100*(1 - pkC(:,3:4)./pkC(:,2));
    bb2 = bar(red, 'grouped'); grid on; box on;
    bb2(1).FaceColor = cols(3,:);  bb2(2).FaceColor = cols(4,:);
    set(gca, 'XTick', 1:nC, 'XTickLabel', condNames, 'XTickLabelRotation', 30);
    ylabel('Peak g reduction vs TecPro (%)');
    title('How much our system helps in each condition');
    yline(0, 'k-');
    legend(labels(3:4), 'Location', 'southoutside');
    exportgraphics(f3, fullfile(outDir, [tag '_conditions.png']), 'Resolution', 200);

    %% ---------------- 4. SAVE TABLES ------------------------------------
    vn = matlab.lang.makeValidName(short);
    T = [table(condNames, vImp, 'VariableNames', {'Condition', 'ImpactSpeed_kmh'}), ...
         array2table(pkC,  'VariableNames', strcat('PeakG_',     vn)), ...
         array2table(hicC, 'VariableNames', strcat('HIC_',       vn)), ...
         array2table(trC,  'VariableNames', strcat('Travel_m_',  vn)), ...
         array2table(rbC,  'VariableNames', strcat('Rebound_kmh_', vn)), ...
         table(fsOK, 'VariableNames', {'FailSafeOK'})];
    writetable(T, fullfile(outDir, [tag '_conditions.csv']));
    TA = [table(crash.angleSweep(:), 'VariableNames', {'Angle_deg'}), ...
          array2table(pkA', 'VariableNames', strcat('PeakG_', vn)), ...
          array2table(bestA', 'VariableNames', {'Best_Small', 'Best_Large'})];
    writetable(TA, fullfile(outDir, [tag '_angle_sweep.csv']));
    fprintf('\nFigures and CSV tables saved in %s\n', outDir);

    out.R = R;  out.M = M;  out.info = info;  out.cal = cal;
    out.conditions = T;  out.angles = TA;
    out.crash = crash;  out.car = car;
end
