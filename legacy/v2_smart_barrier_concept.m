%% =====================================================================
%  F1 SMART BARRIER — CRASH SIMULATION  (v2: TecPro unchanged, small depth)
%  ---------------------------------------------------------------------
%  DESIGN PRINCIPLES
%   1. The standard TecPro barrier is NOT changed. Same blocks, same depth.
%   2. Very little extra space: the whole system adds only S = 20 cm.
%   Everything else (hydraulics, valves, camera, controller) is ours to use.
%
%  WHY A SIMPLE "MOVING BARRIER" IS NOT ENOUGH
%   TecPro foam is soft at first and gets harder as it is crushed, so the
%   driver feels a rising force that peaks at the very end. If you only put
%   a sliding sled BEHIND the TecPro (in series), the car still feels the
%   foam's force, and with 20 cm of travel you gain only a few percent.
%
%  OUR SYSTEM — TWO HYDRAULIC PARTS
%   A) PARALLEL IMPACT RAMS (0 cm extra depth)
%      Hydraulic rams are installed between the TecPro stacks, with their
%      pads flush with the barrier face. When the car hits, the rams push
%      back WITH the foam. Their valves add force when the foam is still
%      soft, so the total force is flat instead of rising:
%            F_ram = F_target - F_foam      (only ever pushes, never pulls)
%      A flat force stops the car in a shorter distance at a lower peak g.
%
%   B) 20 cm FORCE-LIMITING SLED (series)
%      The TecPro + rams module sits on a sled with a hydraulic relief valve.
%      It stays locked until the force on the car reaches F_target, then
%      slides back (max 20 cm), so the force cannot rise above the target.
%
%   C) CAMERA + ML PREDICTION
%      Before contact, the camera predicts the impact speed and the car's
%      mass is known (FIA minimum weight + fuel). From this the controller
%      calculates the LOWEST constant force that still stops the car within
%      the available crush depth + sled stroke:
%            KE = F_target * (crush depth used + sled stroke)
%      After contact, on-board sensors measure the real speed every 1 ms
%      and correct F_target (closed loop), so camera errors are fixed fast.
%
%   FAIL-SAFE: if the system is offline, the ram valves fail OPEN (no force)
%   and the sled stays LOCKED, so the barrier behaves exactly like TecPro.
%
%  MODEL: 1-D impulse-momentum, fixed-step semi-implicit Euler (dt = 10 us).
%  Only the velocity component NORMAL to the barrier is absorbed.
%  Parameters are realistic-order estimates for a student project, not
%  FIA-certified data. Calibrate before quoting numbers.
%
%  Requires MATLAB R2019b or newer.
%  =====================================================================
clear; clc; close all;

%% ===================== 1. CRASH SCENARIO ==============================
crash.speed_kmh = 200;    % car speed just before impact [km/h]
crash.angle_deg = 27;     % angle between car path and barrier [deg] (90 = head-on)
crash.v_normal  = crash.speed_kmh/3.6 * sind(crash.angle_deg);   % [m/s]

%% ===================== 2. PARAMETERS ==================================
g = 9.81;
P.g    = g;
P.mc   = 798;        % car + driver [kg]
P.dt   = 1e-5;       % time step [s]
P.tend = 0.5;        % max simulated time [s]

% --- Standard TecPro (UNCHANGED) ---------------------------------------
P.tec_d  = 1.00;     % foam crush depth [m]
P.tec_F0 = 60e3;     % force at first contact [N]
P.tec_F1 = 360e3;    % force when fully crushed [N]

% --- Car nose crash structure (crushes after the foam) -----------------
P.nose_d  = 0.45;    P.nose_F0 = 360e3;   P.nose_F1 = 420e3;
P.kbot    = 1e7;     % stiffness after everything is crushed [N/m]

% --- Contact behaviour ---------------------------------------------------
P.kun   = 2e7;       % unloading stiffness of crushed foam [N/m]
P.ramp  = 0.02;      % initial elastic ramp [m]
P.cdamp = 1e5;       % contact damping while unloading [N s/m]

% --- (A) Parallel hydraulic impact rams ---------------------------------
P.Fram_max   = 300e3;   % total force all rams can give [N]
P.ram_stroke = 0.95;    % ram stroke, inside the TecPro depth [m]
P.tau        = 0.002;   % valve response time (first-order lag) [s]

% --- (B) Force-limiting sled ---------------------------------------------
P.S   = 0.20;        % EXTRA depth: sled stroke [m]   <-- principle 2
P.ms  = 100;         % sled + TecPro + rams moving mass [kg]
P.cs  = 5e3;         % viscous resistance of sled valve [N s/m]
P.kstop = 1e8;       % end-stop stiffness [N/m]

% --- (C) Controller / camera ---------------------------------------------
P.Fmin    = 80e3;    % lowest target force the controller may choose [N]
P.Fmax    = 600e3;   % highest target force [N]
P.sf      = 1.0;     % safety factor on target force
P.t_sense = 0.015;   % on-board sensors take over this long after contact [s]
P.t_upd   = 1e-3;    % controller update period [s]
P.v_err   = 0.0;     % camera speed error (0.1 = predicts 10 % too fast)

%% ===================== 3. RUN SCENARIOS ===============================
v = crash.v_normal;
KE = 0.5*P.mc*v^2;
fprintf('Impact: %.0f km/h at %.0f deg -> normal speed %.1f m/s (%.0f km/h), KE = %.0f kJ\n', ...
    crash.speed_kmh, crash.angle_deg, v, v*3.6, KE/1e3);
fprintf('Extra depth used by the smart system: %.0f cm\n\n', P.S*100);

cfg   = {'tecpro', 'sled', 'rams', 'smart', 'failed'};
names = {'Standard TecPro', ...
         'TecPro + 20 cm sled only', ...
         'TecPro + parallel rams only', ...
         'SMART BARRIER (rams + sled + camera)', ...
         'Smart barrier — system failed'};
for k = 1:numel(cfg)
    R.(cfg{k}) = simulateCrash(cfg{k}, v, P);
    M.(cfg{k}) = crashMetrics(R.(cfg{k}), P);
end

cT = [0.90 0.30 0.20];  cS = [0.10 0.55 0.90];  cR = [0.95 0.65 0.10];
cB = [0.20 0.70 0.35];  cF = [0.50 0.50 0.50];

fprintf('%-40s %9s %9s %10s %10s %7s\n','Scenario','Peak g','Mean g','Car travel','Extra depth','HIC15');
fprintf('%s\n', repmat('-',1,92));
extra = [0 P.S 0 P.S P.S];
for k = 1:numel(cfg)
    m = M.(cfg{k});
    fprintf('%-40s %7.1f g %7.1f g %8.2f m %8.0f cm %8.0f\n', names{k}, m.clip3, m.mean, ...
        m.stopDist, extra(k)*100, m.HIC15);
end
red = 100*(1 - M.smart.clip3/M.tecpro.clip3);
fprintf('\n>> Smart barrier lowers the peak deceleration by %.0f %% (%.1f g -> %.1f g)\n', ...
    red, M.tecpro.clip3, M.smart.clip3);
fprintf('>> Car stops in %.2f m instead of %.2f m\n', M.smart.stopDist, M.tecpro.stopDist);
if abs(M.failed.clip3 - M.tecpro.clip3) < 0.5
    fprintf('>> Fail-safe check PASSED: offline system behaves exactly like TecPro.\n\n');
end

%% ===================== 4. FIGURE 1 — MAIN RESULT =====================
figure('Name','Smart barrier vs TecPro','Color','w','Position',[50 50 1350 820]);
tl = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
title(tl, sprintf(['Smart Barrier vs Standard TecPro  |  %.0f km/h at %.0f°  (%.1f m/s normal, %.0f kJ)', ...
    '  |  TecPro unchanged, +%.0f cm depth'], crash.speed_kmh, crash.angle_deg, v, KE/1e3, P.S*100), ...
    'FontWeight','bold','FontSize',13);

% (a) g-force
nexttile; hold on; grid on; box on;
plot(R.tecpro.t*1e3, R.tecpro.a_g, 'Color', cT, 'LineWidth', 2.2);
plot(R.smart.t*1e3,  R.smart.a_g,  'Color', cB, 'LineWidth', 2.2);
plot(R.failed.t*1e3, R.failed.a_g, '--', 'Color', cF, 'LineWidth', 1.4);
yline(M.tecpro.clip3, ':', sprintf('TecPro %.0f g', M.tecpro.clip3), 'Color', cT, ...
    'LabelHorizontalAlignment','left');
yline(M.smart.clip3, ':', sprintf('Smart %.0f g', M.smart.clip3), 'Color', cB, ...
    'LabelHorizontalAlignment','right');
xlabel('Time from contact (ms)'); ylabel('Deceleration on driver (g)');
title('(a) What the driver feels');
legend(names([1 4 5]), 'Location','southoutside');

% (b) Force vs distance, showing who carries the load
nexttile; hold on; grid on; box on;
r = R.smart; on = r.t >= 0 & [true; diff(r.xc) > 0];
ha = area(r.xc(on), [r.Ff(on) r.Fr(on)]/1e3, 'LineStyle','none');
ha(1).FaceColor = [1.0 0.85 0.2];  ha(2).FaceColor = cR;
plot(R.tecpro.xc, R.tecpro.F/1e3, 'Color', cT, 'LineWidth', 2.2);
xline(P.tec_d, '--k', 'TecPro fully crushed', 'LabelVerticalAlignment','bottom');
xlabel('Car travel after contact (m)'); ylabel('Force on car (kN)');
title('(b) Force vs distance — rams fill the gap while foam is soft');
legend({'Smart: TecPro foam force','Smart: hydraulic ram force','Standard TecPro'}, ...
    'Location','southoutside');

% (c) Car speed + sled motion
nexttile; hold on; grid on; box on;
yyaxis left
plot(R.tecpro.t*1e3, R.tecpro.vc*3.6, '-', 'Color', cT, 'LineWidth', 2);
plot(R.smart.t*1e3,  R.smart.vc*3.6,  '-', 'Color', cB, 'LineWidth', 2);
ylabel('Car speed into barrier (km/h)'); set(gca,'YColor','k');
yyaxis right
plot(R.smart.t*1e3, R.smart.xb*100, '--', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5);
yline(P.S*100, ':', 'Sled limit');
ylabel('Sled travel (cm)'); set(gca,'YColor',[0.3 0.3 0.3]);
xlabel('Time from contact (ms)');
title('(c) Car speed and sled movement');
legend({'Car — TecPro','Car — Smart','Sled travel'}, 'Location','southoutside');

% (d) Contribution of each part
nexttile; hold on; grid on; box on;
vals = [M.tecpro.clip3 M.sled.clip3 M.rams.clip3 M.smart.clip3];
b = bar(vals, 'FaceColor','flat');
b.CData = [cT; cS; cR; cB];
set(gca,'XTick',1:4,'XTickLabel',{'TecPro','+ sled (20 cm)','+ rams (0 cm)','Rams + sled'});
ylabel('Peak deceleration, 3 ms clip (g)');
title(sprintf('(d) What each part contributes — total %.0f %% lower', red));
text(1:4, vals, compose('%.1f g', vals), 'HorizontalAlignment','center', ...
    'VerticalAlignment','bottom','FontWeight','bold');
ylim([0 max(vals)*1.15]);

%% ===================== 5. FIGURE 2 — SPEED SWEEP =====================
vSweep = 8:1:36;
pk = zeros(3, numel(vSweep));
sweepCfg = {'tecpro','rams','smart'};
fprintf('Running speed sweep...\n');
for i = 1:numel(vSweep)
    for j = 1:3
        mm = crashMetrics(simulateCrash(sweepCfg{j}, vSweep(i), P), P);
        pk(j,i) = mm.clip3;
    end
end
figure('Name','Speed sweep','Color','w','Position',[90 90 950 540]);
hold on; grid on; box on;
plot(vSweep*3.6, pk(1,:), '-o', 'Color', cT, 'LineWidth', 2, 'MarkerFaceColor', cT);
plot(vSweep*3.6, pk(2,:), '-^', 'Color', cR, 'LineWidth', 1.5);
plot(vSweep*3.6, pk(3,:), '-s', 'Color', cB, 'LineWidth', 2, 'MarkerFaceColor', cB);
yline(67, 'k--', 'Grosjean, Bahrain 2020 (~67 g)', 'LabelHorizontalAlignment','left');
xline(v*3.6, ':', 'This scenario');
ylim([0 min(160, max(pk(:))*1.1)]);
xlabel('Impact speed normal to barrier (km/h)'); ylabel('Peak deceleration, 3 ms clip (g)');
title('Peak g vs impact speed — biggest gains in severe crashes where TecPro bottoms out');
legend({'Standard TecPro','TecPro + rams (0 cm)','Smart barrier (rams + 20 cm sled)'}, ...
    'Location','northwest');

%% ===================== 6. FIGURE 3 — DESIGN & ROBUSTNESS =============
figure('Name','Design & robustness','Color','w','Position',[130 130 1300 430]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');

% (a) How much extra depth is worth it?
Ss = 0:0.05:0.40; pS = zeros(size(Ss));
for i = 1:numel(Ss)
    Q = P; Q.S = Ss(i);
    mm = crashMetrics(simulateCrash('smart', v, Q), Q); pS(i) = mm.clip3;
end
nexttile; plot(Ss*100, pS, '-o', 'Color', cB, 'LineWidth', 2); grid on;
yline(M.tecpro.clip3, '--', 'TecPro', 'Color', cT);
xlabel('Extra depth / sled stroke (cm)'); ylabel('Peak g (3 ms)');
title('(a) Extra depth vs peak g');

% (b) Camera speed-prediction error
ve = -0.30:0.05:0.30; pV = zeros(size(ve));
for i = 1:numel(ve)
    Q = P; Q.v_err = ve(i);
    mm = crashMetrics(simulateCrash('smart', v, Q), Q); pV(i) = mm.clip3;
end
nexttile; plot(ve*100, pV, '-o', 'Color', cB, 'LineWidth', 2); grid on;
yline(M.tecpro.clip3, '--', 'TecPro', 'Color', cT);
xlabel('Camera speed error (%)  [+ = predicts too fast]'); ylabel('Peak g (3 ms)');
title('(b) Camera prediction error');

% (c) Hydraulic valve response time
taus = [0.5 1 2 3 5 8 12]*1e-3; pTau = zeros(size(taus));
for i = 1:numel(taus)
    Q = P; Q.tau = taus(i);
    mm = crashMetrics(simulateCrash('smart', v, Q), Q); pTau(i) = mm.clip3;
end
nexttile; plot(taus*1e3, pTau, '-o', 'Color', cB, 'LineWidth', 2); grid on;
yline(M.tecpro.clip3, '--', 'TecPro', 'Color', cT);
xlabel('Valve response time (ms)'); ylabel('Peak g (3 ms)');
title('(c) How fast the hydraulics must react');

%% ===================== 7. FIGURE 4 — ANIMATION =======================
doAnimation = true;     % set false to skip
saveGIF     = false;    % true -> saves 'smart_barrier.gif'
if doAnimation
    animateCrash(R.tecpro, R.smart, P, saveGIF);
end


%% =====================================================================
%                          LOCAL FUNCTIONS
%  =====================================================================
function r = simulateCrash(cfg, v0, P)
% cfg: 'tecpro' | 'sled' | 'rams' | 'smart' | 'failed'
% x axis: car moves +x, barrier face starts at x = 0.
% xb = sled travel, d = crush of foam (car position relative to sled).
    dt = P.dt; mc = P.mc; ms = P.ms;
    useRams = any(strcmp(cfg, {'rams','smart'}));
    useSled = any(strcmp(cfg, {'sled','smart'}));   % 'failed' = rams open, sled locked
    active  = useRams || useSled;

    N = ceil(P.tend/dt) + 2;
    [t, a_g, vc_h, xc_h, F_h, Ff_h, Fr_h, xb_h, d_h, Ft_h] = deal(zeros(N,1));

    tt = 0; xc = 0; vc = v0; xb = 0; vb = 0; dmax = 0; Fr = 0;
    Ft = Inf;
    if active      % camera prediction -> first target force, set before contact
        vEst = v0*(1 + P.v_err);
        Ft = solveTarget(0.5*mc*vEst^2, 0, P.S*useSled, useRams, useSled, P);
    end
    tNext = P.t_sense;

    n = 0;
    while tt < P.tend && n < N
        % ---------- TecPro foam (unchanged) -----------------------------
        d = xc - xb;
        if d > 0
            if d >= dmax
                dmax = d; Ff = crushForce(d, P);
                if d < P.ramp, Ff = Ff*d/P.ramp; end
            else
                Ff = max(0, crushForce(dmax, P) - P.kun*(dmax - d));
                if Ff > 0, Ff = max(0, Ff + P.cdamp*(vc - vb)); end
            end
        else
            Ff = 0;
        end

        % ---------- controller: closed-loop correction every 1 ms ------
        if active && tt >= tNext
            tNext = tNext + P.t_upd;
            if vc > 0.5
                Ft = solveTarget(0.5*mc*vc^2, max(d,0), max(P.S - xb,0)*useSled, ...
                                 useRams, useSled, P);
            end
        end

        % ---------- (A) parallel rams: add force while foam is soft ----
        if useRams
            cmd = 0;
            if d > 0 && vc > 0 && d < P.ram_stroke
                cmd = min(max(Ft - Ff, 0), P.Fram_max);
            end
            Fr = Fr + (cmd - Fr)*dt/P.tau;       % valve response lag
        else
            Fr = 0;
        end
        F = Ff + Fr;                              % total force on car

        % ---------- (B) force-limiting sled ------------------------------
        if useSled
            Fs  = Ft*(mc + ms)/mc;                % valve force: sled decelerates with car
            Fst = 0; if xb > P.S, Fst = P.kstop*(xb - P.S); end
            if vb <= 0 && F <= Fs && Fst == 0
                vb = 0;                           % sled locked
            else
                vb = vb + (F - Fs - P.cs*vb - Fst)/ms*dt;
                if vb < 0, vb = 0; end
                xb = xb + vb*dt;
            end
        end

        % ---------- car ------------------------------------------------
        ac = -F/mc;
        vc = vc + ac*dt;  xc = xc + vc*dt;  tt = tt + dt;

        n = n + 1;
        t(n) = tt; a_g(n) = -ac/P.g; vc_h(n) = vc; xc_h(n) = xc; F_h(n) = F;
        Ff_h(n) = Ff; Fr_h(n) = Fr; xb_h(n) = xb; d_h(n) = d;
        if isfinite(Ft), Ft_h(n) = Ft; else, Ft_h(n) = NaN; end

        if vc <= 0 && F < 1, break; end           % crash over
    end
    r.t = t(1:n); r.a_g = a_g(1:n); r.vc = vc_h(1:n); r.xc = xc_h(1:n);
    r.F = F_h(1:n); r.Ff = Ff_h(1:n); r.Fr = Fr_h(1:n); r.xb = xb_h(1:n);
    r.d = d_h(1:n); r.Ft = Ft_h(1:n); r.cfg = cfg; r.v0 = v0;
end

function Ft = solveTarget(KE, d, rem, useRams, useSled, P)
% Lowest constant force that absorbs the remaining kinetic energy KE,
% starting from foam crush d with 'rem' metres of sled stroke left.
    lo = P.Fmin; hi = P.Fmax;
    if absorbedEnergy(hi, d, rem, useRams, useSled, P) < KE, Ft = hi; return; end
    for it = 1:30                                    % bisection
        mid = 0.5*(lo + hi);
        if absorbedEnergy(mid, d, rem, useRams, useSled, P) < KE
            lo = mid;
        else
            hi = mid;
        end
    end
    Ft = hi*P.sf;
end

function E = absorbedEnergy(F, d, rem, useRams, useSled, P)
% Energy the barrier can still absorb if the car force is held at F.
    dF = max(foamDepthAt(F, P), d);                  % where foam alone reaches F
    if useRams
        Efoam = F*(dF - d);                          % rams top up to a flat F
        if dF > P.ram_stroke
            Efoam = min(Efoam, F*max(0, P.ram_stroke - d));
        end
    else
        x = linspace(d, dF, 25);
        Efoam = trapz(x, crushForce(x, P));          % foam only
    end
    E = Efoam + F*rem*useSled;
end

function d = foamDepthAt(F, P)
% Inverse of crushForce: crush depth where the loading force reaches F.
    if F <= P.tec_F0
        d = 0;
    elseif F <= P.tec_F1
        d = (F - P.tec_F0)/(P.tec_F1 - P.tec_F0)*P.tec_d;
    elseif F <= P.nose_F0
        d = P.tec_d;
    elseif F <= P.nose_F1
        d = P.tec_d + (F - P.nose_F0)/(P.nose_F1 - P.nose_F0)*P.nose_d;
    else
        d = P.tec_d + P.nose_d + (F - P.nose_F1)/P.kbot;
    end
end

function F = crushForce(d, P)
% TecPro loading curve, then car nose, then bottom-out (vectorised).
    F = zeros(size(d));
    a = d <= P.tec_d;
    b = d > P.tec_d & d <= P.tec_d + P.nose_d;
    c = d > P.tec_d + P.nose_d;
    F(a) = P.tec_F0 + (P.tec_F1 - P.tec_F0)*d(a)/P.tec_d;
    F(b) = P.nose_F0 + (P.nose_F1 - P.nose_F0)*(d(b) - P.tec_d)/P.nose_d;
    F(c) = P.nose_F1 + P.kbot*(d(c) - P.tec_d - P.nose_d);
end

function M = crashMetrics(r, P)
    a  = r.a_g;
    w  = max(1, round(3e-3/P.dt));
    M.peak     = max(a);
    M.clip3    = max(movmean(a, w, 'Endpoints','discard'));   % FIA-style 3 ms clip
    on         = a > 0.5;
    M.mean     = mean(a(on));
    M.duration = sum(on)*P.dt;
    M.stopDist = max(r.xc);
    M.HIC15    = hic15(r.t, a);
end

function H = hic15(t, a)
% Head Injury Criterion (15 ms), car deceleration used as head proxy.
    dtc = 1e-4; tc = (t(1):dtc:t(end))';
    ac  = max(interp1(t, a, tc), 0);
    I   = [0; cumsum(ac)*dtc];
    H   = 0;
    for w = 1:round(0.015/dtc)
        T = w*dtc;
        if w >= numel(I), break; end
        avg = (I(1+w:end) - I(1:end-w))/T;
        H = max(H, max(T*avg.^2.5));
    end
end

function animateCrash(rT, rS, P, saveGIF)
% Top view, TecPro (top) vs smart barrier (bottom), slowed down.
    fig = figure('Name','Crash animation','Color','w','Position',[160 100 1150 600]);
    tAll = (0:1e-3:max([rT.t; rS.t]))';
    carL = 5.6; carW = 1.9;
    wallX = P.tec_d + P.S + 0.15;
    tl = tiledlayout(2,1,'TileSpacing','compact');
    runs = {rT, rS};
    ttl  = {'Standard TecPro', sprintf('Smart barrier (TecPro + rams + %.0f cm sled)', P.S*100)};
    gifName = 'smart_barrier.gif';
    for f = 1:numel(tAll)
        for k = 1:2
            ax = nexttile(tl, k); cla(ax); hold(ax,'on'); axis(ax,'equal');
            r = runs{k};
            i = find(r.t <= tAll(f), 1, 'last'); if isempty(i), i = 1; end
            xb = r.xb(i); dm = max([0; r.d(1:i)]); crushed = min(dm, P.tec_d);
            xlim(ax, [-carL-1.5, wallX+0.5]); ylim(ax, [-2.2 2.2]);
            % rear wall
            fill(ax, [wallX wallX+0.3 wallX+0.3 wallX], [-2 -2 2 2], [0.3 0.3 0.3]);
            % TecPro foam stacks (yellow), shrinking as they are crushed
            ys = [-1.8 -0.7; 0.7 1.8];
            if k == 2, ys = [-1.8 -1.1; -0.35 0.35; 1.1 1.8]; end
            for s = 1:size(ys,1)
                fill(ax, [xb+crushed xb+P.tec_d xb+P.tec_d xb+crushed], ...
                    [ys(s,1) ys(s,1) ys(s,2) ys(s,2)], [1 0.85 0.2], 'EdgeColor','k');
            end
            if k == 1
                fill(ax, [crushed P.tec_d P.tec_d crushed], [-0.7 -0.7 0.7 0.7], ...
                    [1 0.85 0.2], 'EdgeColor','k');
            else
                % hydraulic rams between the stacks (orange), pads at the face
                for yy = [-0.72 0.72]
                    fill(ax, [xb+crushed xb+P.tec_d xb+P.tec_d xb+crushed], ...
                        yy + [-0.18 -0.18 0.18 0.18], [0.95 0.55 0.1], 'EdgeColor','k');
                end
                % sled base plate + valve
                fill(ax, [xb+P.tec_d xb+P.tec_d+0.06 xb+P.tec_d+0.06 xb+P.tec_d], ...
                    [-1.9 -1.9 1.9 1.9], [0.1 0.4 0.7]);
                text(ax, wallX-0.05, 2.05, sprintf('sled %2.0f cm', xb*100), ...
                    'HorizontalAlignment','right','FontSize',9);
            end
            % car (red)
            front = min(r.xc(i), xb + crushed);
            fill(ax, [front-carL front front front-carL], ...
                [-carW/2 -carW/2 carW/2 carW/2], [0.85 0.1 0.1]);
            title(ax, sprintf('%s   |   t = %3.0f ms   |   %5.1f km/h   |   %4.1f g', ...
                ttl{k}, r.t(i)*1e3, max(r.vc(i),0)*3.6, r.a_g(i)));
            set(ax,'YTick',[]); xlabel(ax,'x (m)');
        end
        drawnow;
        if saveGIF
            [im, map] = rgb2ind(frame2im(getframe(fig)), 128);
            if f == 1
                imwrite(im, map, gifName, 'gif', 'LoopCount', Inf, 'DelayTime', 0.05);
            else
                imwrite(im, map, gifName, 'gif', 'WriteMode','append', 'DelayTime', 0.05);
            end
        else
            pause(0.03);
        end
    end
end
