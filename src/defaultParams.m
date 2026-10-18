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
