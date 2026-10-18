%% =====================================================================
%  CASE 1 — AYRTON SENNA, IMOLA, 1 MAY 1994 (Tamburello)   [FATAL]
%  ---------------------------------------------------------------------
%  The same impact is simulated in FOUR CASES (see src/runScenarios.m):
%    Case 1  REAL CONDITION  - unprotected concrete wall (what was there)
%    Case 2  TECPRO          - standard TecPro barrier in the same place
%    Case 3  COMPLETE SYSTEM, SMALL SPACE - TecPro unchanged + parallel
%            hydraulic rams + 20 cm sled + camera
%    Case 4  COMPLETE SYSTEM, LARGE SPACE - TecPro unchanged + rams +
%            2.5 m sled + camera-triggered pre-retraction (~2.6 m travel)
%  Fail-safe check: Case 3 with the system offline must equal Case 2.
%  Each case is repeated for 7 external conditions and a range of angles.
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
% Standalone version: every engine function is included at the bottom of
% this file, so no other files are needed. Results go to ./results_case01
outDir = fullfile(pwd, 'results_case01');
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
fprintf('Real barrier: %s\n\n', info.barrierName);
fprintf('%-48s %9s %10s %8s %10s %9s\n','Case','Peak g','vs TecPro','HIC15','Car travel','Rebound');
for k = 1:nS
    m = M.(keys{k});
    fprintf('%-48s %7.1f g %+9.1f%% %8.0f %8.2f m %6.1f km/h\n', labels{k}, m.clip3, ...
        100*(m.clip3/M.tecpro.clip3 - 1), m.HIC15, m.stopDist, m.rebound);
end
fprintf('\nFail-safe check (Case 3 offline): %.1f g vs TecPro %.1f g -> %s\n', ...
    M.failsafe.clip3, M.tecpro.clip3, string(info.failsafeOK));

% --- Figure 1: the real day -----------------------------------------------
f1 = figure('Name','Case study 1 — real day','Color','w','Position',[30 50 1400 600]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
nexttile; hold on; grid on; box on;
for k = 2:nS                       % the concrete wall is off the scale (see bar chart)
    plot(R.(keys{k}).t*1e3, R.(keys{k}).a_g, 'Color', cols(k,:), 'LineWidth', 2.2);
end
plot(R.failsafe.t*1e3, R.failsafe.a_g, '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.2);
xlabel('Time from contact (ms)'); ylabel('Deceleration (g)');
title(sprintf('Senna 1994: %.0f km/h at %.0f° (assumed), dry and sunny', info.vImpact_kmh, angleNominal));
legend([labels(2:nS), {'Fail-safe check: Case 3 offline'}], 'Location','southoutside');

nexttile; hold on; grid on; box on;
vals = cellfun(@(s) M.(s).clip3, keys);
b = bar(vals, 'FaceColor','flat'); b.CData = cols;
set(gca,'XTick',1:nS,'XTickLabel',{'1: Concrete wall','2: TecPro','3: Small space','4: Large space'}, ...
    'YScale','log');
text(1:nS, vals, compose('%.0f g', vals), 'HorizontalAlignment','center', ...
    'VerticalAlignment','bottom','FontWeight','bold');
ylabel('Peak deceleration, 3 ms clip (g, log scale)'); ylim([5 1000]);
title('Peak g in each case');
exportgraphics(f1, fullfile(outDir, 'case01_real_day.png'), 'Resolution', 200);

%% ------------------ 3. IMPACT ANGLE SWEEP (unknown angle) ------------
fprintf('\nRunning angle sweep...\n');
pkA = zeros(nS, numel(angleSweep));
for i = 1:numel(angleSweep)
    [~, Mi] = runScenarios(crash, car, dayCond, angleSweep(i), P);
    for k = 1:nS, pkA(k,i) = Mi.(keys{k}).clip3; end
end
f2 = figure('Name','Case study 1 — angle sweep','Color','w','Position',[70 70 950 560]);
hold on; grid on; box on;
for k = 1:nS
    plot(angleSweep, pkA(k,:), '-o', 'Color', cols(k,:), 'LineWidth', 2, ...
        'MarkerFaceColor', cols(k,:), 'MarkerSize', 4);
end
xline(angleNominal, ':', 'Nominal (assumed)');
yline(67, '--k', 'Grosjean 2020: 67 g, survived', 'LabelHorizontalAlignment','left');
set(gca,'YScale','log');
xlabel('Impact angle to wall (deg)  —  documented only as "shallow"');
ylabel('Peak deceleration, 3 ms clip (g)');
title('Senna 1994: effect of the unknown impact angle');
legend(labels, 'Location','northwest');
exportgraphics(f2, fullfile(outDir, 'case01_angle_sweep.png'), 'Resolution', 200);

%% ------------------ 4. EXTERNAL CONDITIONS ---------------------------
condKeys = {'dry','light_rain','heavy_rain','cold','hot','sun_glare','worst'};
nC = numel(condKeys);
pkC = zeros(nC, nS);  hicC = pkC;  trC = pkC;  vImp = zeros(nC,1);
condNames = cell(nC,1);  fsOK = false(nC,1);
fprintf('Running %d external-condition scenarios...\n', nC);
for i = 1:nC
    c = weatherScenario(condKeys{i});
    [~, Mi, Ii] = runScenarios(crash, car, c, angleNominal, P);
    condNames{i} = c.name;  vImp(i) = Ii.vImpact_kmh;  fsOK(i) = Ii.failsafeOK;
    for k = 1:nS
        pkC(i,k)  = Mi.(keys{k}).clip3;
        hicC(i,k) = Mi.(keys{k}).HIC15;
        trC(i,k)  = Mi.(keys{k}).stopDist;
    end
end

fprintf('\nPeak g (3 ms clip):\n%-44s %6s', 'Condition', 'km/h');
fprintf(' %8s', short{:});  fprintf(' %9s\n', 'Fail-safe');
for i = 1:nC
    fprintf('%-44s %6.0f', condNames{i}, vImp(i));  fprintf(' %8.1f', pkC(i,:));
    fprintf(' %9s\n', string(fsOK(i)));
end

f3 = figure('Name','Case study 1 — conditions','Color','w','Position',[110 110 1400 600]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
nexttile;
bb = bar(pkC(:,2:4), 'grouped'); grid on; box on;
for j = 1:3, bb(j).FaceColor = cols(j+1,:); end
set(gca,'XTick',1:nC,'XTickLabel',condNames,'XTickLabelRotation',30);
ylabel('Peak deceleration, 3 ms clip (g)');
title('Cases 2–4 under each external condition');
legend(labels(2:4), 'Location','northwest');
nexttile;
red = 100*(1 - pkC(:,3:4)./pkC(:,2));
bb2 = bar(red, 'grouped'); grid on; box on;
bb2(1).FaceColor = cols(3,:);  bb2(2).FaceColor = cols(4,:);
set(gca,'XTick',1:nC,'XTickLabel',condNames,'XTickLabelRotation',30);
ylabel('Peak g reduction vs TecPro (%)');
title('How much our system helps in each condition');
yline(0,'k-');
legend(labels(3:4), 'Location','southoutside');
exportgraphics(f3, fullfile(outDir, 'case01_conditions.png'), 'Resolution', 200);

%% ------------------ 5. SAVE RESULTS FOR THE PAPER ---------------------
vn = matlab.lang.makeValidName(short);
T = [table(condNames, vImp, 'VariableNames', {'Condition','ImpactSpeed_kmh'}), ...
     array2table(pkC,  'VariableNames', strcat('PeakG_',  vn)), ...
     array2table(hicC, 'VariableNames', strcat('HIC_',    vn)), ...
     array2table(trC,  'VariableNames', strcat('Travel_m_', vn)), ...
     table(fsOK, 'VariableNames', {'FailSafeOK'})];
writetable(T, fullfile(outDir, 'case01_conditions.csv'));
TA = [table(angleSweep', 'VariableNames', {'Angle_deg'}), ...
      array2table(pkA', 'VariableNames', strcat('PeakG_', vn))];
writetable(TA, fullfile(outDir, 'case01_angle_sweep.csv'));
fprintf('\nFigures and CSV tables saved in %s\n', outDir);


%% =====================================================================
%                SIMULATION ENGINE (same code as src/ in the repo)
%  =====================================================================

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

    % --- Case 4: complete system WITH large space (first concept) --------
    P.S_large     = 2.5; % sled stroke [m] -> ~2.6 m car travel
    P.v_pre_large = 6;   % pre-retraction speed when there is room for it [m/s]

    % --- smart barrier: (C) controller + camera ---------------------------
    P.Fmin      = 80e3;  % lowest target force [N]
    P.Fmax      = 600e3; % highest target force [N]
    P.sf        = 1.0;   % safety factor on target force
    P.t_sense   = 0.015; % on-board sensors take over after contact [s]
    P.t_upd     = 1e-3;  % controller update period [s]
    P.v_err     = 0.0;   % camera speed error (+0.1 = predicts 10 % too fast)
    P.cameraOK  = true;  % false = camera blind (rain spray, glare, failure)
    P.systemOnline = true; % false = whole smart system offline (fail-safe test)
end

function car = carModel(era)
%CARMODEL  Mass and front crush behaviour of an F1 car of a given era.
%   car = carModel('2020s') or carModel('1994')
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
            car.d = [0     0.01   0.46];        % crush depth [m]
            car.F = [0     360e3  420e3];       % force [N]
            car.kEnd = 1e7;                     % survival cell [N/m]

        case '1994'
            % 1994 cars: shorter, weaker nose; no rear/side impact tests yet.
            car.name = '1994 F1 car (Williams FW16 class)';
            % 500 kg minimum car weight WITHOUT driver (RaceFans, min-weight
            % history) + ~70 kg driver + ~40 kg fuel early in a refuelling race.
            car.mass = 610;
            car.massNote = '500 kg car (1994 min, excl. driver) + ~70 kg driver + ~40 kg fuel (estimate)';
            car.d = [0     0.01   0.36];
            car.F = [0     250e3  300e3];
            car.kEnd = 1e7;

        otherwise
            error('carModel: unknown era "%s"', era);
    end
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

function c = weatherScenario(key, airTempC)
%WEATHERSCENARIO  External conditions that can affect the crash and our system.
%   c = weatherScenario(key)            key: 'dry','light_rain','heavy_rain',
%                                            'cold','hot','sun_glare','worst'
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
        Ft = solveTarget(0.5*mc*vEst^2, 0, P.S*useSled, useRams, useSled, C, P);
    end
    tNext = P.t_sense;                            % first on-board measurement

    % ---------- camera-triggered PRE-RETRACTION (large-space version) ----
    % The hydraulics start moving the sled backward just before contact,
    % so the car meets a barrier that is already moving away from it.
    pre = useSled && active && P.cameraOK && P.v_pre > 0;
    if pre
        tr = P.v_pre/P.a_pre;                     % time to reach retraction speed
        tp = -tr - 0.005;  xc = v0*tp;            % car position when retraction starts
        while tp < 0
            if tp >= -tr && vb < P.v_pre, vb = min(P.v_pre, vb + P.a_pre*dt); end
            xb = xb + vb*dt;  xc = xc + vc*dt;  tp = tp + dt;
        end
    end

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
                Ft = solveTarget(0.5*mc*vc^2, max(d,0), max(P.S - xb,0)*useSled, ...
                                 useRams, useSled, C, P);
            end
        end

        % ---------- (A) parallel rams -----------------------------------
        if useRams
            cmd = 0;
            if isfinite(Ft) && d > 0 && vc > 0 && d < P.ram_stroke
                cmd = min(max(Ft - Ff, 0), P.Fram_max);
            end
            Fr = Fr + (cmd - Fr)*dt/P.tau;        % valve lag
        end
        F = Ff + Fr;

        % ---------- (B) force-limiting sled ------------------------------
        if useSled
            Fs  = Ft*(mc + ms)/mc;                % valve force; Inf -> stays locked
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
