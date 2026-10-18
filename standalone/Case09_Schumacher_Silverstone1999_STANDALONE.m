%% =====================================================================
%  CASE STUDY 9 — MICHAEL SCHUMACHER, SILVERSTONE, 11 JULY 1999 (Stowe, lap 1)
%  ---------------------------------------------------------------------
%  Four cases (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - tyre barrier
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE (+20 cm)
%    Case 4  COMPLETE SYSTEM, LARGE SPACE (2.5 m sled, ~2.6 m travel)
%  x 8 external conditions x a range of impact angles.
%
%  DOCUMENTED DATA (REFERENCES.md):
%    - Rear brake failure: braking began at 306 km/h, front wheels
%      locked at 204 km/h, ~1.1 g average in the gravel             [S13]
%    - Hit the tyre barrier at 107 km/h; broken leg                  [S13]
%    - Peak g not published
%
%  ASSUMPTIONS:
%    - 600 kg car incl. driver + ~70 kg lap-1 fuel -> 670 kg
%    - Near head-on: 80 deg nominal, swept
%    - Dry (not verified in the sources used)
%
%  NOTE: no recorded g, so this case is NOT calibrated. The tyre-barrier
%  model is an estimate and likely too stiff for a deep tyre wall; the
%  'Actual' result is therefore an upper bound.
%  =====================================================================
clear; clc; close all;
% STANDALONE: the whole simulation engine is included at the bottom of this file.

crash.id              = 9;
crash.name            = 'Case study 9 — Michael Schumacher, Silverstone 1999 (Stowe)';
crash.shortName       = 'Schumacher 1999';
crash.vBrake_kmh      = 306;         % [S13]
crash.vImpact_kmh     = 107;         % [S13]
crash.realGrip        = 1.0;
crash.barrierType     = 'tyre';      % [S13]
crash.carEra          = '2000s';
crash.mass            = 670;         % ~600 kg + ~70 kg fuel (estimate)
crash.massNote        = '~600 kg incl. driver + ~70 kg lap-1 fuel (estimate)';
crash.angleNominal    = 80;          % ASSUMPTION: near head-on
crash.angleSweep      = 30:5:90;
crash.angleNote       = 'near head-on (assumed 80 deg)';
crash.dayCondKey      = 'dry';
out = runCaseStudy(crash, fullfile(pwd, 'results_case09'));


%% =====================================================================
%                SIMULATION ENGINE (generated from src/ — do not edit here)
%  =====================================================================

function [P2, vImpact] = applyConditions(P, cond, crash)
%APPLYCONDITIONS  Apply weather/temperature to the solver settings and impact speed.
%   [P2, vImpact] = applyConditions(P, cond, crash)
%     crash.vImpact_kmh : documented impact speed (dry, real day)  [km/h]
%     crash.vBrake_kmh  : speed when braking/sliding started       [km/h]
%     crash.realGrip    : grip on the real day (1 = dry)
%   Returns the impact speed [km/h] for these conditions.
%
%   Less grip -> less speed is scrubbed off before the wall. The kinetic
%   energy removed by braking/sliding scales with grip:
%     v_imp^2 = v_brake^2 - (grip/realGrip)*(v_brake^2 - v_real^2)

    P2 = P;
    P2.tau      = cond.tau;
    P2.cameraOK = cond.cameraOK;
    P2.v_err    = cond.v_err;

    vb = crash.vBrake_kmh;  vr = crash.vImpact_kmh;
    ratio = cond.grip / crash.realGrip;
    vImpact = sqrt(max(vb^2 - ratio*(vb^2 - vr^2), 0));
end

function b = barrierModel(type, foamScale)
%BARRIERMODEL  Crush behaviour of a trackside barrier.
%   b = barrierModel(type)            type: 'concrete','armco','tyre','tecpro'
%   b = barrierModel(type, foamScale) scales the force of deformable
%                                     barriers (temperature effect, see
%                                     applyConditions.m). Default 1.
%
%   Force b.F(i) is reached at barrier deformation b.d(i). Beyond the last
%   point the barrier is solid (stiffness b.kEnd).
%
%   CONCRETE is effectively rigid. TECPRO values follow the concept model
%   used throughout this project. ARMCO and TYRE values are first estimates
%   and MUST be calibrated against recorded crashes (Grosjean 2020 for
%   Armco, Schumacher 1999 / Barrichello 1994 for tyres).

    if nargin < 2, foamScale = 1; end

    switch lower(type)
        case 'concrete'
            b.name = 'Unprotected concrete wall';
            b.d = [0  0.001];   b.F = [0  0.5e6];   b.kEnd = 5e8;
        case 'armco'
            b.name = 'Steel guardrail (Armco)';
            b.d = [0  0.05  0.60];  b.F = [0  150e3  350e3];  b.kEnd = 5e8;
        case 'tyre'
            b.name = 'Tyre barrier';
            b.d = [0  0.02  0.70];  b.F = [0  40e3   300e3];  b.kEnd = 5e8;
        case 'tecpro'
            b.name = 'TecPro barrier';
            b.d = [0  0.02  1.00];  b.F = [0  60e3   360e3];  b.kEnd = 5e8;
        otherwise
            error('barrierModel: unknown type "%s"', type);
    end
    if ~strcmpi(type, 'concrete')
        b.F = b.F * foamScale;
    end
    b.type = lower(type);
end

function C = buildContact(car, barrier)
%BUILDCONTACT  Combine car crush and barrier crush into one contact curve.
%   The car and the barrier are in SERIES: the same force F acts on both,
%   so the total crush is   d_total(F) = d_barrier(F) + d_car(F).
%   The weaker element therefore crushes first, automatically.
%
%   The result is stored on uniform grids so the time loop can look up
%   force-from-crush (crushForce) and crush-from-force (foamDepthAt) fast.

    Fmax = 3e6;                                   % table range [N]
    Fq   = linspace(0, Fmax, 6001)';              % uniform force grid
    dq   = elemDepth(Fq, barrier) + elemDepth(Fq, car);

    C.kEnd = 1/(1/barrier.kEnd + 1/car.kEnd);     % series stiffness beyond table

    % force-from-crush on a uniform crush grid
    C.dd   = 1e-4;
    C.dTab = (0:C.dd:dq(end))';
    C.FTab = interp1(dq, Fq, C.dTab, 'linear');
    C.dEnd = C.dTab(end);  C.FEnd = C.FTab(end);

    % crush-from-force on the uniform force grid
    C.dF    = Fq(2) - Fq(1);
    C.FTab2 = Fq;  C.dTab2 = dq;

    C.carName = car.name;  C.barrierName = barrier.name;
end

function d = elemDepth(F, e)
% Deformation of one element (car or barrier) under force F.
    d = zeros(size(F));
    in = F <= e.F(end);
    d(in)  = interp1(e.F, e.d, F(in), 'linear');
    d(~in) = e.d(end) + (F(~in) - e.F(end))/e.kEnd;
end

function [ang, info] = calibrateAngle(crash, car, P)
%CALIBRATEANGLE  Equivalent impact angle that reproduces the recorded g-force.
%   Real crashes lose energy that a 1-D model does not see: the car glances
%   off, spins, sheds wheels, pushes the barrier back. Accident
%   reconstruction handles this with an EQUIVALENT BARRIER SPEED. Here the
%   impact angle is adjusted until the REAL barrier in the model gives the
%   recorded peak g (crash.recordedG) on the real day. TecPro and our
%   system are then tested at exactly the same, measured, severity.
%
%   info.energyFraction = calibrated / geometric normal energy (if the
%   documented angle crash.angleDocumented is known), i.e. how much of the
%   car's energy the barrier actually had to absorb.

    cond = weatherScenario(crash.dayCondKey);
    [Pc, vImp] = applyConditions(P, cond, crash);
    C = buildContact(car, barrierModel(crash.barrierType, cond.foamScale));
    g = @(a) calibPeakG(a, vImp, car, C, Pc);

    lo = 0.5;  hi = 90;
    if g(hi) < crash.recordedG
        ang = hi;                                  % even head-on is too gentle
    else
        for it = 1:25
            mid = 0.5*(lo + hi);
            if g(mid) < crash.recordedG, lo = mid; else, hi = mid; end
        end
        ang = 0.5*(lo + hi);
    end
    info.angle   = ang;
    info.vNormal = vImp/3.6*sind(ang);
    info.modelG  = g(ang);
    if isfield(crash, 'angleDocumented') && ~isempty(crash.angleDocumented)
        info.energyFraction = (sind(ang)/sind(crash.angleDocumented))^2;
    else
        info.energyFraction = NaN;
    end
end

function G = calibPeakG(a, vImp, car, C, Pc)
% Peak g of the real barrier at impact angle a (helper for calibration).
    r = simulateCrash('passive', vImp/3.6*sind(a), car, C, Pc);
    m = crashMetrics(r, Pc);
    G = m.clip3;
end

function car = carModel(era)
%CARMODEL  Mass and front crush behaviour of an F1 car of a given era.
%   car = carModel('2020s'), carModel('2000s') or carModel('1994')
%
%   The crush curve is piecewise linear: force car.F(i) is reached at
%   crush depth car.d(i). Beyond the last point the survival cell is
%   treated as almost rigid (stiffness car.kEnd).
%
%   ALL CRUSH VALUES ARE ENGINEERING ESTIMATES (not FIA homologation data)
%   and are tuned in the calibration step against recorded crash g-forces.

    switch lower(era)
        case {'2020s','modern'}
            % 2020s cars: long homologated nose impact structure.
            car.name = '2020s F1 car';
            car.mass = 798;                     % FIA minimum incl. driver [kg]
            car.massNote = 'FIA minimum weight incl. driver (2020s regulations)';
            car.d = [0     0.10   0.46];        % crush depth [m]  (tapered nose:
            car.F = [0     300e3  420e3];       % force [N]         force builds over 10 cm)
            car.kEnd = 1e7;                     % survival cell [N/m]

        case '1994'
            % 1994 cars: shorter, weaker nose; no rear/side impact tests yet.
            car.name = '1994 F1 car (Williams FW16 class)';
            % 500 kg minimum car weight WITHOUT driver (RaceFans, min-weight
            % history) + ~70 kg driver + ~40 kg fuel early in a refuelling race.
            car.mass = 610;
            car.massNote = '500 kg car (1994 min, excl. driver) + ~70 kg driver + ~40 kg fuel (estimate)';
            car.d = [0     0.08   0.36];
            car.F = [0     220e3  300e3];
            car.kEnd = 1e7;

        case '2000s'
            % 1999-2010 cars: homologated nose, lighter than today.
            car.name = '1999-2010 F1 car';
            car.mass = 600;                     % ~600 kg incl. driver (1995-2007 era rules)
            car.massNote = '~600 kg minimum incl. driver (estimate for the era)';
            car.d = [0     0.10   0.40];
            car.F = [0     260e3  360e3];
            car.kEnd = 1e7;

        otherwise
            error('carModel: unknown era "%s"', era);
    end
end

function M = crashMetrics(r, P)
%CRASHMETRICS  Injury and performance numbers for one simulated impact.
%   M.clip3     peak deceleration averaged over 3 ms (FIA-style)      [g]
%   M.peak      raw peak deceleration                               [g]
%   M.mean      mean deceleration while decelerating                [g]
%   M.HIC15     Head Injury Criterion (car decel as head proxy)     [-]
%   M.stopDist  car travel after contact                            [m]
%   M.duration  time with deceleration > 0.5 g                      [s]
%   M.rebound   speed the car bounces back toward the track         [km/h]
    a = r.a_g;
    w = max(1, round(3e-3/P.dt));
    M.peak     = max(a);
    if numel(a) > w
        M.clip3 = max(movmean(a, w, 'Endpoints','discard'));
    else
        M.clip3 = M.peak;
    end
    on         = a > 0.5;
    M.mean     = mean(a(on));
    M.duration = sum(on)*P.dt;
    M.stopDist = max(r.xc);
    M.HIC15    = hic15(r.t, a);
    M.rebound  = r.reboundSpeed*3.6;
end

function F = crushForce(d, C)
%CRUSHFORCE  Loading force when the car+barrier contact is crushed by d [m].
%   Fast table lookup (works for scalars and vectors).
    F = zeros(size(d));
    in  = d <= C.dEnd;
    din = d(in);
    x   = max(din(:), 0)/C.dd;                 % force column shape so it matches C.FTab
    i   = min(floor(x), numel(C.dTab) - 2);
    w   = x - i;
    F(in)  = (1 - w).*C.FTab(i+1) + w.*C.FTab(i+2);
    F(~in) = C.FEnd + C.kEnd*(d(~in) - C.dEnd);
end

function P = defaultParams()
%DEFAULTPARAMS  Solver, hydraulic and controller settings shared by all cases.
%   Car and barrier properties live in carModel.m and barrierModel.m.
%   Weather/temperature effects are applied by applyConditions.m.

    P.g     = 9.81;
    P.dt    = 1e-5;      % time step [s]
    P.tend  = 0.5;       % max simulated time after contact [s]

    % --- contact behaviour (crushed material barely springs back) -------
    P.kun   = 2e7;       % unloading stiffness [N/m]
    P.cdamp = 1e5;       % contact damping while unloading [N s/m]

    % --- smart barrier: (A) parallel hydraulic impact rams --------------
    P.Fram_max   = 300e3;   % combined force of all rams [N]
    P.ram_stroke = 0.95;    % ram stroke, inside the TecPro depth [m]
    P.tau        = 0.002;   % valve response time [s]

    % --- smart barrier: (B) force-limiting sled ---------------------------
    P.S     = 0.20;      % extra depth = sled stroke [m]
    P.ms    = 100;       % moving mass (sled + TecPro + rams) [kg]
    P.cs    = 5e3;       % viscous resistance of sled valve [N s/m]
    P.kstop = 1e8;       % sled end-stop stiffness [N/m]
    P.vlock = 1.5;       % sled slides freely until within this speed of the car [m/s]
    P.v_pre = 0;         % camera-triggered pre-retraction speed [m/s] (0 = off)
    P.a_pre = 10*9.81;   % pre-retraction acceleration [m/s^2]
    P.S_reserve   = 0.02;  % sled stroke kept for the rebound lock [m]
    P.reboundLock = true;  % after the car stops, release so foam springs back into the sled
    P.F_release   = 5e3;   % sled hold force during rebound lock [N]

    % --- Case 4: complete system WITH large space (first concept) --------
    P.S_large     = 2.5; % sled stroke [m] -> ~2.6 m car travel
    P.v_pre_large = 6;   % pre-retraction speed when there is room for it [m/s]
    P.pre_frac    = 0.3; % never retract faster than 30 % of the predicted impact speed

    % --- smart barrier: (C) controller + camera ---------------------------
    P.Fmin      = 30e3;  % lowest target force [N]
    P.Fmax      = 600e3; % highest target force [N]
    P.sf        = 1.0;   % safety factor on target force
    P.t_sense   = 0.015; % on-board sensors take over after contact [s]
    P.t_upd     = 1e-3;  % controller update period [s]
    P.v_err     = 0.0;   % camera speed error (+0.1 = predicts 10 % too fast)
    P.cameraOK  = true;  % false = camera blind (rain spray, glare, failure)
    P.systemOnline = true; % false = whole smart system offline (fail-safe test)
end

function d = foamDepthAt(F, C)
%FOAMDEPTHAT  Crush depth at which the contact force reaches F (inverse of crushForce).
    if F <= 0, d = 0; return; end
    Fend = C.FTab2(end);
    if F >= Fend
        d = C.dTab2(end) + (F - Fend)/C.kEnd;
        return;
    end
    x = F/C.dF;
    i = floor(x);
    w = x - i;
    d = (1 - w)*C.dTab2(i+1) + w*C.dTab2(i+2);
end

function H = hic15(t, a)
%HIC15  Head Injury Criterion over a 15 ms window.
%   HIC = max over windows (t2-t1 <= 15 ms) of (t2-t1) * [mean a]^2.5, a in g.
%   Car deceleration is used as a proxy for head acceleration; real HIC
%   needs a dummy head sensor. HIC15 = 700 is the usual injury threshold.
    dtc = 1e-4;
    tc  = (t(1):dtc:t(end))';
    if numel(tc) < 3, H = 0; return; end
    ac  = max(interp1(t, a, tc), 0);
    I   = [0; cumsum(ac)*dtc];
    H   = 0;
    for w = 1:min(round(0.015/dtc), numel(I) - 1)
        T   = w*dtc;
        avg = (I(1+w:end) - I(1:end-w))/T;
        H   = max(H, max(T*avg.^2.5));
    end
end

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

function [R, M, info] = runScenarios(crash, car, cond, angleDeg, P)
%RUNSCENARIOS  The four cases compared for every crash.
%
%   CASE 1  real    - REAL CONDITION: the barrier that was actually there
%   CASE 2  tecpro  - standard TecPro barrier in the same place
%   CASE 3  small   - COMPLETE SYSTEM, SMALL SPACE (TecPro unchanged,
%                     parallel rams + 20 cm sled + camera)
%   CASE 4  large   - COMPLETE SYSTEM, LARGE SPACE (TecPro unchanged,
%                     rams + 2.5 m sled + camera pre-retraction, ~2.6 m travel)
%
%   Fail-safe check (not a case): Case 3 with the system offline must give
%   exactly the TecPro result. Returned as R.failsafe / M.failsafe.
%
%   crash : case data (see cases/*.m)    car : carModel.m
%   cond  : weatherScenario.m            angleDeg : impact angle [deg]

    [Pc, vImp_kmh] = applyConditions(P, cond, crash);
    vN = vImp_kmh/3.6 * sind(angleDeg);           % normal component [m/s]

    bReal   = barrierModel(crash.barrierType, cond.foamScale);
    bTecPro = barrierModel('tecpro',          cond.foamScale);
    Creal = buildContact(car, bReal);
    Ctec  = buildContact(car, bTecPro);

    Plarge = Pc;  Plarge.S = P.S_large;  Plarge.v_pre = P.v_pre_large;
    Poff   = Pc;  Poff.systemOnline = false;

    R.real     = simulateCrash('passive', vN, car, Creal, Pc);
    R.tecpro   = simulateCrash('passive', vN, car, Ctec,  Pc);
    R.small    = simulateCrash('smart',   vN, car, Ctec,  Pc);
    R.large    = simulateCrash('smart',   vN, car, Ctec,  Plarge);
    R.failsafe = simulateCrash('smart',   vN, car, Ctec,  Poff);

    f = fieldnames(R);
    for k = 1:numel(f), M.(f{k}) = crashMetrics(R.(f{k}), Pc); end

    info.vImpact_kmh = vImp_kmh;
    info.vNormal     = vN;
    info.KE_kJ       = 0.5*car.mass*vN^2/1e3;
    info.angle       = angleDeg;
    info.barrierName = bReal.name;
    info.cond        = cond;
    info.failsafeOK  = abs(M.failsafe.clip3 - M.tecpro.clip3) < 0.1;
    % lowest g physically possible in each space (perfect controller)
    KE = 0.5*car.mass*vN^2;
    info.bestSmall_g = theoreticalBest(KE, P.S,       car, Ctec, Pc);
    info.bestLarge_g = theoreticalBest(KE, P.S_large, car, Ctec, Pc);
end

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

function r = simulateCrash(mode, v0, car, C, P)
%SIMULATECRASH  1-D impact of an F1 car into a barrier.
%   r = simulateCrash(mode, v0, car, C, P)
%     mode : 'passive' - ordinary barrier described by contact curve C
%            'sled'    - C + 20 cm force-limiting sled only
%            'rams'    - C + parallel hydraulic rams only
%            'smart'   - C + rams + sled + camera   (our system)
%            (a failed smart barrier = 'passive' with a TecPro curve)
%     v0   : impact speed NORMAL to the barrier [m/s]
%     car  : from carModel.m      C : from buildContact.m
%     P    : from defaultParams.m (+ applyConditions.m)
%
%   Fixed-step semi-implicit Euler. Crushed material keeps its crush
%   (plastic), so the loop tracks the maximum crush dmax.

    dt = P.dt;  mc = car.mass;  ms = P.ms;
    useRams = any(strcmp(mode, {'rams','smart'}));
    useSled = any(strcmp(mode, {'sled','smart'}));
    if isfield(P,'systemOnline') && ~P.systemOnline
        useRams = false; useSled = false;         % fail-safe: rams open, sled locked
    end
    active  = useRams || useSled;

    N = ceil(P.tend/dt) + 2;
    [t, a_g, vc_h, xc_h, F_h, Ff_h, Fr_h, xb_h, d_h] = deal(zeros(N,1));

    tt = 0; xc = 0; vc = v0; xb = 0; vb = 0; dmax = 0; Fr = 0;
    Ft = Inf;                                     % Inf = no target set
    if active && P.cameraOK                       % camera prediction before contact
        vEst = v0*(1 + P.v_err);
        Ft = solveTarget(0.5*mc*vEst^2, 0, max(P.S - P.S_reserve, 0)*useSled, ...
                         useRams, useSled, C, P);
    end
    tNext = P.t_sense;                            % first on-board measurement

    % ---------- camera-triggered PRE-RETRACTION (large-space version) ----
    % The hydraulics start moving the sled backward just before contact,
    % so the car meets a barrier that is already moving away from it.
    pre = useSled && active && P.cameraOK && P.v_pre > 0;
    if pre
        % never retract faster than a fraction of the predicted impact speed,
        % otherwise a gentle impact would never reach the barrier
        vpre = min(P.v_pre, P.pre_frac*v0*(1 + P.v_err));
        tr = vpre/P.a_pre;                        % time to reach retraction speed
        tp = -tr - 0.005;  xc = v0*tp;            % car position when retraction starts
        while tp < 0
            if tp >= -tr && vb < vpre, vb = min(vpre, vb + P.a_pre*dt); end
            xb = xb + vb*dt;  xc = xc + vc*dt;  tp = tp + dt;
        end
    end

    stopped = false;                              % becomes true when the car has stopped
    n = 0;
    while tt < P.tend && n < N
        % ---------- barrier + car crush -----------------------------------
        d = xc - xb;
        if d > 0
            if d >= dmax
                dmax = d;  Ff = crushForce(d, C);
            else
                Ff = max(0, crushForce(dmax, C) - P.kun*(dmax - d));
                if Ff > 0, Ff = max(0, Ff + P.cdamp*(vc - vb)); end
            end
        else
            Ff = 0;
        end

        % ---------- controller: closed-loop update every t_upd -----------
        if active && tt >= tNext
            tNext = tNext + P.t_upd;
            if vc > 0.5
                Ft = solveTarget(0.5*mc*vc^2, max(d,0), max(P.S - P.S_reserve - xb,0)*useSled, ...
                                 useRams, useSled, C, P);
            end
        end

        % ---------- REBOUND LOCK: the car has stopped ----------------------
        % Rams release and the sled valve drops to a small hold force, so the
        % springing-back foam pushes the light sled backward (into the reserve
        % stroke) instead of pushing the car back toward the track.
        if active && P.reboundLock && ~stopped && vc <= 0
            stopped = true;
        end

        % ---------- (A) parallel rams -----------------------------------
        if useRams
            cmd = 0;
            if isfinite(Ft) && d > 0 && vc > 0 && ~stopped && d < P.ram_stroke
                cmd = min(max(Ft - Ff, 0), P.Fram_max);
            end
            Fr = Fr + (cmd - Fr)*dt/P.tau;        % valve lag
            if vc - vb <= 0
                Fr = 0;                           % a damper resists compression only;
            end                                   % it cannot push the car back out
        end
        F = Ff + Fr;

        % ---------- (B) force-limiting sled ------------------------------
        if useSled
            Fs  = Ft*(mc + ms)/mc;                % valve force; Inf -> stays locked
            if stopped, Fs = P.F_release; end     % rebound lock: let the sled give way
            if vb > 0 && vb < vc - P.vlock
                Fs = 0;                           % let the sled catch up with the car
            end
            Fst = 0; if xb > P.S, Fst = P.kstop*(xb - P.S); end
            if pre && d <= 0 && vb > 0
                xb = xb + vb*dt;                  % actuator holds retraction speed until contact
            elseif vb <= 0 && F <= Fs && Fst == 0
                vb = 0;                           % sled locked
            else
                % damping acts on sled speed RELATIVE to the car, so it only
                % stops the sled running ahead of (or lagging) the car
                vb = vb + (F - Fs - P.cs*(vb - vc) - Fst)/ms*dt;
                if vb < 0, vb = 0; end
                xb = xb + vb*dt;
            end
        end

        % ---------- car --------------------------------------------------
        ac = -F/mc;
        vc = vc + ac*dt;  xc = xc + vc*dt;  tt = tt + dt;

        n = n + 1;
        t(n) = tt; a_g(n) = -ac/P.g; vc_h(n) = vc; xc_h(n) = xc;
        F_h(n) = F; Ff_h(n) = Ff; Fr_h(n) = Fr; xb_h(n) = xb; d_h(n) = d;

        if vc <= 0 && F < 1, break; end
    end
    r.t = t(1:n); r.a_g = a_g(1:n); r.vc = vc_h(1:n); r.xc = xc_h(1:n);
    r.F = F_h(1:n); r.Ff = Ff_h(1:n); r.Fr = Fr_h(1:n);
    r.xb = xb_h(1:n); r.d = d_h(1:n); r.mode = mode; r.v0 = v0;
    r.reboundSpeed = max(0, -min(r.vc));          % speed bouncing back toward track
end

function Ft = solveTarget(KE, d, rem, useRams, useSled, C, P)
%SOLVETARGET  Lowest constant force that still absorbs the kinetic energy KE.
%   d    : current crush depth [m]
%   rem  : sled stroke still available [m]   (rem = P.S - sled travel)
%   The controller wants the force on the driver to be as low and as flat
%   as possible, while making sure the car stops before the barrier,
%   the rams and the sled run out of travel.
    lo = P.Fmin;  hi = P.Fmax;
    if absorbedEnergy(hi, d, rem, useRams, useSled, C, P) < KE
        Ft = hi; return;
    end
    for it = 1:30                                   % bisection
        mid = 0.5*(lo + hi);
        if absorbedEnergy(mid, d, rem, useRams, useSled, C, P) < KE
            lo = mid;
        else
            hi = mid;
        end
    end
    Ft = hi*P.sf;
end

function E = absorbedEnergy(F, d, rem, useRams, useSled, C, P)
% Energy still absorbable if the force on the car is held at F.
    dF = max(foamDepthAt(F, C), d);                 % where the barrier alone reaches F
    if useRams
        % Inside the ram stroke the rams top the force up to a flat F.
        Ebar = F*max(0, min(dF, P.ram_stroke) - d);
        % Beyond the ram stroke the barrier and car nose keep absorbing alone.
        a = max(d, P.ram_stroke);
        if dF > a
            x = linspace(a, dF, 25);
            Ebar = Ebar + trapz(x, crushForce(x, C));
        end
    else
        x = linspace(d, dF, 25);
        Ebar = trapz(x, crushForce(x, C));
    end
    E = Ebar + F*rem*useSled;
end

function S = summarizeStudies(outs, outDir)
%SUMMARIZESTUDIES  One table and one figure comparing all crash studies.
%   outs : cell array of outputs from runCaseStudy
%   Writes results/summary_all_cases.csv and summary_all_cases.png
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    n = numel(outs);
    [keys, labels, short, cols] = scenarioLabels();
    id = zeros(n,1);  name = cell(n,1);  rec = nan(n,1);  angU = zeros(n,1);
    eFrac = nan(n,1);  pk = zeros(n,4);  rb = zeros(n,4);  best = zeros(n,2);
    fs = false(n,1);  vImp = zeros(n,1);  KE = zeros(n,1);
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
    end
    vn = matlab.lang.makeValidName(short);
    S = [table(id, name, vImp, angU, KE, rec, eFrac, 'VariableNames', ...
            {'Case','Crash','ImpactSpeed_kmh','AngleUsed_deg','EnergyIntoBarrier_kJ', ...
             'RecordedG','EnergyFraction'}), ...
         array2table(pk, 'VariableNames', strcat('PeakG_', vn)), ...
         array2table(best, 'VariableNames', {'BestPossible_Small','BestPossible_Large'}), ...
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
    title('All 10 crashes: real barrier vs TecPro vs our system');
    legend([labels, {'Recorded g (real crash)'}], 'Location', 'northeastoutside');
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

function gBest = theoreticalBest(KE, S, car, C, P)
%THEORETICALBEST  Lowest possible peak deceleration [g] for this crash and space.
%   With TecPro unchanged, the foam only crushes where its own force is at
%   least the force on the car. The best any controller can do is hold one
%   constant force F from first contact to stop, using the rams while the
%   foam is softer than F and then the sled stroke S:
%            F * (crush depth where foam reaches F + S) = KE
%   (no hardware limits, no valve lag, perfect camera).
    Q = P;  Q.Fmax = 2e7;  Q.Fmin = 1;  Q.sf = 1;  Q.ram_stroke = Inf;
    F = solveTarget(KE, 0, S, true, S > 0, C, Q);
    gBest = F/(car.mass*P.g);
end

function c = weatherScenario(key, airTempC)
%WEATHERSCENARIO  External conditions that can affect the crash and our system.
%   c = weatherScenario(key)            key: 'dry','light_rain','heavy_rain',
%                                            'cold','hot','sun_glare','night','worst'
%   c = weatherScenario(key, airTempC)  override the air temperature
%
%   What each condition changes (see docs/external_factors.md):
%     grip      run-off/track grip relative to dry -> changes impact speed
%     airTemp   foam stiffness and hydraulic oil viscosity (valve speed)
%     cameraOK  false = camera cannot see the car (spray, glare, smoke)
%     v_err     camera speed-estimate error (+ = predicts too fast)
%
%   The size of every effect is an ENGINEERING ASSUMPTION for this study,
%   chosen to be on the cautious side, and should be refined with tests.

    c.key = key;  c.grip = 1.0;  c.airTemp = 20;
    c.cameraOK = true;  c.v_err = 0.0;
    switch key
        case 'dry'
            c.name = 'Dry, sunny';
        case 'light_rain'
            c.name = 'Light rain';    c.grip = 0.75; c.airTemp = 15; c.v_err = 0.10;
        case 'heavy_rain'
            c.name = 'Heavy rain + spray (camera blind)';
            c.grip = 0.55; c.airTemp = 12; c.cameraOK = false;
        case 'cold'
            c.name = 'Cold (5 °C)';   c.airTemp = 5;
        case 'hot'
            c.name = 'Hot (40 °C air)'; c.airTemp = 40;
        case 'sun_glare'
            c.name = 'Low sun glare (camera +20 % error)'; c.v_err = 0.20;
        case 'night'
            c.name = 'Night race, floodlights (camera +10 % error)'; c.v_err = 0.10; c.airTemp = 22;
        case 'worst'
            c.name = 'Worst case: cold heavy rain, camera blind';
            c.grip = 0.55; c.airTemp = 5; c.cameraOK = false;
        otherwise
            error('weatherScenario: unknown key "%s"', key);
    end
    if nargin > 1 && ~isempty(airTempC), c.airTemp = airTempC; end

    % --- temperature effects (assumed, linear around 20 °C) --------------
    % Polyethylene foam gets stiffer when cold, softer when hot: ~0.6 %/°C.
    c.foamScale = 1 - 0.006*(c.airTemp - 20);
    % Hydraulic oil gets thicker when cold -> valves react more slowly.
    c.tau = 0.002*(1 + 0.04*max(0, 20 - c.airTemp));
end
