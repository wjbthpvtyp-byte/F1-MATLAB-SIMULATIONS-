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
            Fs  = Ft*(mc + ms)/mc;                % Inf -> stays locked
            Fst = 0; if xb > P.S, Fst = P.kstop*(xb - P.S); end
            if vb <= 0 && F <= Fs && Fst == 0
                vb = 0;
            else
                vb = vb + (F - Fs - P.cs*vb - Fst)/ms*dt;
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
