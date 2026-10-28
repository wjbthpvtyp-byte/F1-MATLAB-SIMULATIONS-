function S = summarizeStudies(outs, outDir)
%SUMMARIZESTUDIES  One table and one figure comparing all crash studies.
%   outs : cell array of outputs from runCaseStudy
%   Writes results/summary_all_cases.csv and summary_all_cases.png
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    n = numel(outs);
    [keys, labels, short, cols] = scenarioLabels();
    id = zeros(n,1);  name = cell(n,1);  rec = nan(n,1);  angU = zeros(n,1);
    eFrac = nan(n,1);  pk = zeros(n,4);  rb = zeros(n,4);  best = zeros(n,2);
    fs = false(n,1);  vImp = zeros(n,1);  KE = zeros(n,1);  deep = zeros(n,2);
    for i = 1:n
        o = outs{i};
        id(i) = o.crash.id;  name{i} = o.crash.shortName;
        if isfield(o.crash, 'recordedG') && ~isempty(o.crash.recordedG), rec(i) = o.crash.recordedG; end
        angU(i) = o.info.angle;  eFrac(i) = o.cal.energyFraction;
        vImp(i) = o.info.vImpact_kmh;  KE(i) = o.info.KE_kJ;
        for k = 1:4
            pk(i,k) = o.M.(keys{k}).clip3;
            rb(i,k) = o.M.(keys{k}).rebound;
        end
        best(i,:) = [o.info.bestSmall_g o.info.bestLarge_g];
        fs(i) = o.info.failsafeOK;
        deep(i,:) = [o.M.deepSmall.clip3 o.M.deepLarge.clip3];
    end
    vn = matlab.lang.makeValidName(short);
    S = [table(id, name, vImp, angU, KE, rec, eFrac, 'VariableNames', ...
            {'Case','Crash','ImpactSpeed_kmh','AngleUsed_deg','EnergyIntoBarrier_kJ', ...
             'RecordedG','EnergyFraction'}), ...
         array2table(pk, 'VariableNames', strcat('PeakG_', vn)), ...
         array2table(best, 'VariableNames', {'BestPossible_Small','BestPossible_Large'}), ...
         array2table(deep, 'VariableNames', {'DeepTecPro_SmallSpace','DeepTecPro_LargeSpace'}), ...
         array2table(rb, 'VariableNames', strcat('Rebound_kmh_', vn)), ...
         table(100*(1 - pk(:,3)./pk(:,2)), 100*(1 - pk(:,4)./pk(:,2)), fs, 'VariableNames', ...
            {'Reduction_Small_pct','Reduction_Large_pct','FailSafeOK'})];
    writetable(S, fullfile(outDir, 'summary_all_cases.csv'));

    fprintf('\n%s\n  SUMMARY — ALL CASE STUDIES (real day)\n%s\n', repmat('=',1,104), repmat('=',1,104));
    fprintf('%-4s %-20s %8s %9s %9s %9s %9s %9s %10s %10s\n', '#', 'Crash', 'Rec. g', ...
        'Real', 'TecPro', 'Small', 'Large', 'Best(S)', 'Small vs T', 'Rebound T>S');
    for i = 1:n
        fprintf('%-4d %-20s %8s %7.1f g %7.1f g %7.1f g %7.1f g %7.1f g %+9.0f%% %5.1f>%4.1f\n', ...
            id(i), name{i}, num2strOrDash(rec(i)), pk(i,1), pk(i,2), pk(i,3), pk(i,4), ...
            best(i,1), -S.Reduction_Small_pct(i), rb(i,2), rb(i,3));
    end

    f = figure('Name','All case studies','Color','w','Position',[40 40 1500 700]);
    tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
    nexttile;
    b = bar(pk, 'grouped'); grid on; box on;
    for k = 1:4, b(k).FaceColor = cols(k,:); end
    hold on;
    ok = ~isnan(rec);
    plot(find(ok), rec(ok), 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 12);
    yline(67, '--k', '67 g (Grosjean, survived)', 'LabelHorizontalAlignment', 'left');
    set(gca, 'XTick', 1:n, 'XTickLabel', name, 'YScale', 'log');
    ylabel('Peak deceleration, 3 ms clip (g)');
    plot((1:n) + 0.09, deep(:,1), 'kd', 'MarkerFaceColor', cols(3,:), 'MarkerSize', 6);
    plot((1:n) + 0.27, deep(:,2), 'kd', 'MarkerFaceColor', cols(4,:), 'MarkerSize', 6);
    title(sprintf('All %d crashes: real barrier vs TecPro vs our system (diamonds: deep TecPro, same space)', n));
    legend([labels, {'Recorded g (real crash)', '67 g reference', 'Deep TecPro, Case 3 space', ...
        'Deep TecPro, Case 4 space'}], 'Location', 'northeastoutside');
    nexttile;
    b2 = bar(rb, 'grouped'); grid on; box on;
    for k = 1:4, b2(k).FaceColor = cols(k,:); end
    set(gca, 'XTick', 1:n, 'XTickLabel', name);
    ylabel('Rebound toward track (km/h)');
    title('Rebound speed (risk of a secondary impact, as in Hubert 2019)');
    legend(labels, 'Location', 'northeastoutside');
    exportgraphics(f, fullfile(outDir, 'summary_all_cases.png'), 'Resolution', 200);
    fprintf('\nSummary saved in %s\n', outDir);
end

function s = num2strOrDash(x)
    if isnan(x), s = '—'; else, s = sprintf('%.1f', x); end
end
