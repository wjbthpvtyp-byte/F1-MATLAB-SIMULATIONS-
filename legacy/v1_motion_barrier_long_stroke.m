%% =====================================================================
%  F1 MOTION BARRIER vs STANDARD TECPRO BARRIER — CRASH SIMULATION
%  ---------------------------------------------------------------------
%  Compares what the car (and driver) feels when it hits:
%
%   1) STANDARD TECPRO BARRIER
%      Crushable foam blocks fixed against a wall. The car's own nose
%      (crash structure) crushes after the foam is used up.
%
%   2) MOTION BARRIER (our concept)
%      The same TecPro blocks are mounted on a light sled that can slide
%      back up to S metres. A hydraulic damper behind the sled controls
%      how hard it resists. A camera + ML model predicts the crash, then:
%        a) PRE-RETRACTION: the hydraulics start moving the sled backward
%           just before contact, so the car hits a barrier that is already
%           moving away from it (smaller momentum jump at contact).
%        b) ADAPTIVE DAMPING: after contact the damper force is set every
%           time step so the car stops using (almost) all the available
%           stroke at the lowest constant deceleration:
%                   a_needed = v^2 / (2 * remaining stroke)
%
%   3) MOTION BARRIER — SYSTEM FAILURE
%      Hydraulics locked / electronics offline. The sled cannot move, so it
%      must behave exactly like the standard TecPro barrier (fail-safe check).
%
%  Physics: 1-D impulse-momentum model, solved with a fixed-step
%  semi-implicit Euler integrator (needed because foam crush is
%  history-dependent: crushed foam does not spring back).
%
%  Only the component of velocity NORMAL to the barrier is simulated.
%  The tangential component makes the car slide along the barrier and is
%  not absorbed by it.
%
%  NOTE: Material and car parameters are realistic-order estimates for a
%  student project, not FIA-certified data. Calibrate them against real
%  TecPro test data before quoting numbers.
%
%  Requires MATLAB R2019b or newer (uses tiledlayout / yline).
%  =====================================================================
clear; clc; close all;

%% ===================== 1. CRASH SCENARIO ==============================
crash.speed_kmh = 200;    % car speed just before impact [km/h]
crash.angle_deg = 27;     % angle between car path and barrier [deg]
                          % (90 = head-on; Grosjean Bahrain 2020 ~ 192 km/h)
crash.v_normal  = crash.speed_kmh/3.6 * sind(crash.angle_deg); % [m/s]

%% ===================== 2. MODEL PARAMETERS ============================
g = 9.81;
P.g      = g;
P.mc     = 798;      % car + driver mass [kg] (F1 2026 minimum ~ 768-798 kg)
P.dt     = 1e-5;     % time step [s]
P.tend   = 0.6;      % max simulated time after contact [s]

% --- TecPro foam block stack (force rises as foam is crushed) ---------
P.tec_d  = 1.00;     % usable crush depth of the foam [m]
P.tec_F0 = 60e3;     % crush force at first contact [N]
P.tec_F1 = 360e3;    % crush force when foam is fully crushed [N]

% --- Car nose / crash structure (crushes after the foam) --------------
P.nose_d  = 0.45;    % crush depth of nose structure [m]
P.nose_F0 = 360e3;   % [N]
P.nose_F1 = 420e3;   % [N]
P.kbot    = 1e7;     % stiffness once everything is crushed (bottom-out) [N/m]

% --- Contact behaviour --------------------------------------------------
P.kun    = 2e7;      % unloading stiffness (crushed foam barely springs back) [N/m]
P.ramp   = 0.02;     % initial elastic ramp before crushing starts [m]
P.cdamp  = 2e4;      % contact damping during unloading [N s/m]

% --- Motion barrier hardware -------------------------------------------
P.ms     = 120;      % sled mass (sled + TecPro blocks it carries) [kg]
P.S      = 2.5;      % sled stroke available behind the barrier [m]
P.margin = 0.15;     % stroke kept in reserve by the controller [m]
P.Fmax   = 450e3;    % max hydraulic damper force [N]
P.sf     = 1.15;     % controller safety factor (>1 = stop a bit early)
P.vlock  = 1.5;      % damper stays soft until sled is within this speed of car [m/s]
P.kstop  = 1e8;      % end-stop stiffness if the sled runs out of stroke [N/m]

% --- Camera + ML prediction / pre-retraction ----------------------------
P.v_pre  = 4.0;      % sled retraction speed reached at the moment of contact [m/s]
P.a_pre  = 10*g;     % hydraulic pre-retraction acceleration [m/s^2]
P.t_sense= 0.015;    % time after contact before on-board sensors take over [s]
P.v_err  = 0.0;      % camera speed-prediction error (0.1 = +10 %)
P.t_err  = 0.0;      % camera timing error (+ = retraction starts late) [s]

%% ===================== 3. RUN THE THREE SCENARIOS =====================
fprintf('Impact: %.0f km/h at %.0f deg  ->  normal speed %.1f m/s (%.0f km/h)\n', ...
    crash.speed_kmh, crash.angle_deg, crash.v_normal, crash.v_normal*3.6);
fprintf('Kinetic energy into barrier: %.0f kJ\n\n', 0.5*P.mc*crash.v_normal^2/1e3);

R.tecpro = simulateCrash('tecpro', crash.v_normal, P);
R.motion = simulateCrash('motion', crash.v_normal, P);
R.failed = simulateCrash('failed', crash.v_normal, P);

names  = {'Standard TecPro', 'Motion Barrier', 'Motion Barrier (system failed)'};
fields = {'tecpro', 'motion', 'failed'};
cols   = [0.90 0.30 0.20;   % red    - TecPro
          0.10 0.60 0.90;   % blue   - motion barrier
          0.55 0.55 0.55];  % grey   - failure fallback

%% ===================== 4. INJURY / PERFORMANCE METRICS ================
fprintf('%-32s %9s %10s %9s %10s %9s %8s\n', 'Scenario', 'Peak g', '3ms-clip g', ...
    'Mean g', 'Stop dist', 'Duration', 'HIC15');
fprintf('%s\n', repmat('-', 1, 92));
for k = 1:3
    r = R.(fields{k});
    M(k) = crashMetrics(r, P); %#ok<SAGROW>
    fprintf('%-32s %8.1f g %9.1f g %8.1f g %8.2f m %7.0f ms %8.0f\n', names{k}, ...
        M(k).peak, M(k).clip3, M(k).mean, M(k).stopDist, M(k).duration*1e3, M(k).HIC15);
end
red = 100*(1 - M(2).clip3/M(1).clip3);
fprintf('\n>> Motion barrier reduces the 3 ms peak deceleration by %.0f %%\n', red);
if abs(M(3).clip3 - M(1).clip3) < 0.5
    fprintf('>> Fail-safe check PASSED: with the system offline it behaves exactly like TecPro.\n\n');
else
    fprintf('>> Fail-safe check: failure case differs from TecPro by %.1f g.\n\n', M(3).clip3-M(1).clip3);
end

%% ===================== 5. FIGURE 1 — MAIN COMPARISON ==================
figure('Name','F1 Barrier Crash Comparison','Color','w','Position',[60 60 1300 820]);
tl = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
title(tl, sprintf('F1 Barrier Impact: %.0f km/h at %.0f°  (normal speed %.1f m/s, %.0f kJ)', ...
    crash.speed_kmh, crash.angle_deg, crash.v_normal, 0.5*P.mc*crash.v_normal^2/1e3), ...
    'FontWeight','bold','FontSize',14);

% (a) Deceleration felt by the driver
nexttile; hold on; grid on; box on;
for k = [1 2 3]
    r = R.(fields{k});
    ls = '-'; if k == 3, ls = '--'; end
    plot(r.t*1e3, r.a_g, ls, 'Color', cols(k,:), 'LineWidth', 2);
end
yline(M(1).clip3, ':', sprintf('TecPro peak %.0f g', M(1).clip3), 'Color', cols(1,:), ...
    'LabelHorizontalAlignment','left');
yline(M(2).clip3, ':', sprintf('Motion peak %.0f g', M(2).clip3), 'Color', cols(2,:), ...
    'LabelHorizontalAlignment','right');
xline(0, 'k-', 'Contact', 'LabelVerticalAlignment','bottom');
xlabel('Time from contact (ms)'); ylabel('Deceleration (g)');
title('(a) Deceleration felt by the driver');
legend(names, 'Location','northeast');
xlim([min(R.motion.t)*1e3, max([R.tecpro.t; R.motion.t])*1e3]);

% (b) Car speed
nexttile; hold on; grid on; box on;
for k = 1:2
    r = R.(fields{k});
    plot(r.t*1e3, r.vc*3.6, 'Color', cols(k,:), 'LineWidth', 2);
end
plot(R.motion.t*1e3, R.motion.vb*3.6, '--', 'Color', cols(2,:), 'LineWidth', 1.2);
xline(0, 'k-');
xlabel('Time from contact (ms)'); ylabel('Speed toward barrier (km/h)');
title('(b) Car speed (and sled speed)');
legend({'Car — TecPro','Car — Motion barrier','Sled — Motion barrier'}, 'Location','northeast');

% (c) Force vs car travel (area under curve = energy absorbed)
nexttile; hold on; grid on; box on;
for k = 1:2
    r = R.(fields{k});
    on = r.t >= 0;
    area(r.xc(on), r.F(on)/1e3, 'FaceColor', cols(k,:), 'FaceAlpha', 0.25, ...
        'EdgeColor', cols(k,:), 'LineWidth', 1.8);
end
xlabel('Car travel after contact (m)'); ylabel('Force on car (kN)');
title('(c) Force vs distance — same energy, spread over longer distance');
legend(names(1:2), 'Location','northeast');

% (d) Metrics bar chart
nexttile;
vals = [M(1).clip3 M(2).clip3; M(1).mean M(2).mean; M(1).stopDist*10 M(2).stopDist*10];
b = bar(vals, 'grouped'); grid on; box on;
b(1).FaceColor = cols(1,:); b(2).FaceColor = cols(2,:);
set(gca, 'XTickLabel', {'Peak g (3 ms)', 'Mean g', 'Stop distance (dm)'});
ylabel('Value'); title(sprintf('(d) Summary — peak g reduced by %.0f %%', red));
legend(names(1:2), 'Location','northwest');
for j = 1:2
    xt = b(j).XEndPoints; yt = b(j).YEndPoints;
    text(xt, yt, compose('%.1f', yt), 'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', 'FontWeight','bold');
end

%% ===================== 6. FIGURE 2 — SPEED SWEEP =====================
% How does each barrier cope as the impact gets harder?
vSweep = 8:1:36;                       % normal impact speeds [m/s]
pkT = zeros(size(vSweep)); pkM = pkT;
fprintf('Running speed sweep (%d speeds)...\n', numel(vSweep));
for i = 1:numel(vSweep)
    mT = crashMetrics(simulateCrash('tecpro', vSweep(i), P), P);  pkT(i) = mT.clip3;
    mM = crashMetrics(simulateCrash('motion', vSweep(i), P), P);  pkM(i) = mM.clip3;
end

figure('Name','Speed sweep','Color','w','Position',[100 100 900 520]);
hold on; grid on; box on;
plot(vSweep*3.6, pkT, '-o', 'Color', cols(1,:), 'LineWidth', 2, 'MarkerFaceColor', cols(1,:));
plot(vSweep*3.6, pkM, '-s', 'Color', cols(2,:), 'LineWidth', 2, 'MarkerFaceColor', cols(2,:));
yline(67, 'k--', 'Grosjean, Bahrain 2020 (~67 g)', 'LabelHorizontalAlignment','left');
xline(crash.v_normal*3.6, ':', 'This scenario');
ylim([0 min(150, max(pkT)*1.1)]);
xlabel('Impact speed normal to barrier (km/h)'); ylabel('Peak deceleration, 3 ms clip (g)');
title('Peak g vs impact speed — TecPro bottoms out, motion barrier keeps using its stroke');
legend(names(1:2), 'Location','northwest');

%% ===================== 7. FIGURE 3 — DESIGN & ROBUSTNESS =============
figure('Name','Design & robustness','Color','w','Position',[140 140 1200 450]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');

% (a) Effect of available stroke
Ssweep = 1.0:0.25:4.0; pkS = zeros(size(Ssweep));
for i = 1:numel(Ssweep)
    Q = P; Q.S = Ssweep(i);
    mm = crashMetrics(simulateCrash('motion', crash.v_normal, Q), Q);  pkS(i) = mm.clip3;
end
nexttile; plot(Ssweep, pkS, '-o', 'Color', cols(2,:), 'LineWidth', 2); grid on;
yline(M(1).clip3, '--', 'TecPro', 'Color', cols(1,:));
xlabel('Sled stroke available (m)'); ylabel('Peak g (3 ms)');
title('(a) More stroke = lower g');

% (b) Camera timing error
terr = -0.06:0.01:0.10; pkTe = zeros(size(terr));
for i = 1:numel(terr)
    Q = P; Q.t_err = terr(i);
    mm = crashMetrics(simulateCrash('motion', crash.v_normal, Q), Q);  pkTe(i) = mm.clip3;
end
nexttile; plot(terr*1e3, pkTe, '-o', 'Color', cols(2,:), 'LineWidth', 2); grid on;
yline(M(1).clip3, '--', 'TecPro', 'Color', cols(1,:));
xlabel('Camera timing error (ms)  [+ = late]'); ylabel('Peak g (3 ms)');
title('(b) Prediction timing error');

% (c) Value of pre-retraction (the camera's job)
vp = 0:1:8; pkVp = zeros(size(vp));
for i = 1:numel(vp)
    Q = P; Q.v_pre = vp(i);
    mm = crashMetrics(simulateCrash('motion', crash.v_normal, Q), Q);  pkVp(i) = mm.clip3;
end
nexttile; plot(vp, pkVp, '-o', 'Color', cols(2,:), 'LineWidth', 2); grid on;
xlabel('Sled pre-retraction speed at contact (m/s)'); ylabel('Peak g (3 ms)');
title('(c) Pre-retraction speed (0 = no camera)');

%% ===================== 8. FIGURE 4 — ANIMATION =======================
doAnimation = true;     % set false to skip
saveGIF     = false;    % set true to save 'barrier_crash.gif'
if doAnimation
    animateCrash(R.tecpro, R.motion, P, saveGIF);
end


%% =====================================================================
%                         LOCAL FUNCTIONS
%  =====================================================================
function r = simulateCrash(mode, v0, P)
% mode: 'tecpro' | 'motion' | 'failed'
% Coordinates: car moves in +x. Barrier front face starts at x = 0.
% xb = sled displacement (0 for fixed barriers), d = foam + nose crush.
    dt = P.dt; mc = P.mc; ms = P.ms;
    active = strcmp(mode, 'motion');          % 'failed' = sled locked

    if active && P.v_pre > 0
        t_ramp = P.v_pre / P.a_pre;           % time to reach pre-retraction speed
    else
        t_ramp = 0;
    end
    t0 = -t_ramp - 0.02;                      % start slightly before anything happens

    N = ceil((P.tend - t0)/dt) + 2;
    [t, a_g, vc_h, xc_h, F_h, xb_h, vb_h, d_h, Fd_h] = deal(zeros(N,1));

    tt = t0; xc = v0*t0; vc = v0; xb = 0; vb = 0; dmax = 0;
    contact = false; tc = NaN; v_est = v0*(1 + P.v_err); Fd = 0;

    n = 0;
    while tt < P.tend && n < N
        % ---------- contact force between car and barrier face ---------
        d = xc - xb;
        if d > 0
            if ~contact, contact = true; tc = tt; end
            if d >= dmax                      % loading: crushing new material
                dmax = d;
                F = crushForce(d, P);
                if d < P.ramp, F = F*d/P.ramp; end
            else                              % unloading: crushed foam stays crushed
                F = max(0, crushForce(dmax, P) - P.kun*(dmax - d));
                if F > 0, F = max(0, F + P.cdamp*(vc - vb)); end
            end
        else
            F = 0;
        end

        % ---------- sled + hydraulics (motion barrier only) -------------
        if active
            if ~contact
                % camera has predicted the crash: pre-retract the sled
                Fd = 0;
                if tt >= -t_ramp + P.t_err && vb < P.v_pre
                    ab = P.a_pre;
                else
                    ab = 0;
                end
            else
                % adaptive damper: camera estimate first, then measured speed
                if (tt - tc) < P.t_sense, vctl = v_est; else, vctl = vc; end
                rem = P.S - xb - P.margin;
                if vb < vc - P.vlock
                    Freq = 0;                 % let sled catch up with the car first
                else
                    Freq = P.sf*(mc + ms)*max(vctl,0)^2 / (2*max(rem, 0.01));
                end
                Fd  = min(Freq, P.Fmax) * tanh(vb/0.05);
                Fst = 0; if xb > P.S, Fst = P.kstop*(xb - P.S); end
                ab  = (F - Fd - Fst)/ms;
            end
            vb = vb + ab*dt;  xb = xb + vb*dt;
        end

        % ---------- car ------------------------------------------------
        ac = -F/mc;
        vc = vc + ac*dt;  xc = xc + vc*dt;  tt = tt + dt;

        n = n + 1;
        t(n) = tt; a_g(n) = -ac/P.g; vc_h(n) = vc; xc_h(n) = xc;
        F_h(n) = F; xb_h(n) = xb; vb_h(n) = vb; d_h(n) = d; Fd_h(n) = Fd;

        % ---------- stop when the crash is over --------------------------
        if contact && vc <= 0
            if active && abs(vb) < 0.05, break; end
            if ~active && F == 0, break; end
        end
    end
    r.t = t(1:n); r.a_g = a_g(1:n); r.vc = vc_h(1:n); r.xc = xc_h(1:n);
    r.F = F_h(1:n); r.xb = xb_h(1:n); r.vb = vb_h(1:n); r.d = d_h(1:n);
    r.Fd = Fd_h(1:n); r.mode = mode; r.v0 = v0;
end

function F = crushForce(d, P)
% Loading curve: TecPro foam crushes first (weaker), then the car nose,
% then everything is solid (bottom-out).
    if d <= P.tec_d
        F = P.tec_F0 + (P.tec_F1 - P.tec_F0)*d/P.tec_d;
    elseif d <= P.tec_d + P.nose_d
        F = P.nose_F0 + (P.nose_F1 - P.nose_F0)*(d - P.tec_d)/P.nose_d;
    else
        F = P.nose_F1 + P.kbot*(d - P.tec_d - P.nose_d);
    end
end

function M = crashMetrics(r, P)
    a  = r.a_g;
    w  = max(1, round(3e-3/P.dt));                       % 3 ms window
    aw = movmean(a, w, 'Endpoints','discard');
    M.peak  = max(a);
    M.clip3 = max(aw);                                   % FIA-style 3 ms clip
    on      = r.t >= 0 & a > 0.5;
    M.mean  = mean(a(on));
    M.duration = sum(on)*P.dt;
    M.stopDist = max(r.xc) - 0;                          % car travel after contact
    M.HIC15 = hic15(r.t, a);
end

function H = hic15(t, a)
% Head Injury Criterion over a 15 ms window, using car deceleration as a
% proxy for head acceleration (real HIC uses a dummy head sensor).
    dtc = 1e-4;                                          % resample to 0.1 ms
    tc  = (t(1):dtc:t(end))';
    ac  = max(interp1(t, a, tc), 0);
    I   = [0; cumsum(ac)*dtc];
    H   = 0;
    for w = 1:round(0.015/dtc)
        T   = w*dtc;
        avg = (I(1+w:end) - I(1:end-w)) / T;
        H   = max(H, max(T*avg.^2.5));
    end
end

function animateCrash(rT, rM, P, saveGIF)
% Side-by-side top view of both barriers (slowed down ~20x).
    fig = figure('Name','Crash animation','Color','w','Position',[180 120 1100 560]);
    tAll  = (min([rT.t; rM.t]) : 2e-3 : max([rT.t; rM.t]))';
    carL  = 5.6;  carW = 1.9;                % car footprint [m]
    wallX = P.tec_d + P.S + 0.6;             % rear wall position
    gifName = 'barrier_crash.gif';
    tl = tiledlayout(2,1,'TileSpacing','compact');
    titles = {'Standard TecPro barrier', 'Motion barrier (camera + adaptive hydraulics)'};
    runs   = {rT, rM};
    for f = 1:numel(tAll)
        for k = 1:2
            ax = nexttile(tl, k); cla(ax); hold(ax,'on'); axis(ax,'equal');
            r  = runs{k};
            i  = find(r.t <= tAll(f), 1, 'last'); if isempty(i), i = 1; end
            xc = r.xc(i); xb = r.xb(i); dmax = max(r.d(1:i)); dmax = max(dmax, 0);
            xlim(ax, [-carL-4, wallX+0.5]); ylim(ax, [-2, 2]);
            % rear wall
            fill(ax, [wallX wallX+0.4 wallX+0.4 wallX], [-1.8 -1.8 1.8 1.8], [0.3 0.3 0.3]);
            % hydraulic cylinder (motion barrier only)
            if k == 2
                plot(ax, [xb+P.tec_d, wallX], [0 0], '-', 'Color', [0.2 0.2 0.2], 'LineWidth', 6);
                fill(ax, [xb+P.tec_d xb+P.tec_d+0.15 xb+P.tec_d+0.15 xb+P.tec_d], ...
                    [-1.4 -1.4 1.4 1.4], [0.1 0.4 0.7]);   % sled plate
            end
            % TecPro foam (shrinks as it is crushed)
            crushed = min(dmax, P.tec_d);
            if k == 1, base = 0; else, base = xb; end
            fill(ax, [base+crushed base+P.tec_d base+P.tec_d base+crushed], ...
                [-1.4 -1.4 1.4 1.4], [1.0 0.85 0.2], 'EdgeColor','k');
            % car (nose shortened if it is crushing)
            noseCrush = max(0, dmax - P.tec_d);
            front = min(xc, base + crushed) ;
            fill(ax, [front-carL+noseCrush front front front-carL+noseCrush], ...
                [-carW/2 -carW/2 carW/2 carW/2], [0.85 0.1 0.1]);
            % text
            title(ax, sprintf('%s   |   t = %5.0f ms   |   speed %5.1f km/h   |   %4.1f g', ...
                titles{k}, r.t(i)*1e3, max(r.vc(i),0)*3.6, r.a_g(i)));
            set(ax, 'YTick', []); xlabel(ax, 'x (m)');
        end
        drawnow;
        if saveGIF
            fr = getframe(fig); [im, map] = rgb2ind(frame2im(fr), 128);
            if f == 1
                imwrite(im, map, gifName, 'gif', 'LoopCount', Inf, 'DelayTime', 0.04);
            else
                imwrite(im, map, gifName, 'gif', 'WriteMode', 'append', 'DelayTime', 0.04);
            end
        else
            pause(0.02);
        end
    end
end
