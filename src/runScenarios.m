function [R, M, info] = runScenarios(crash, car, cond, angleDeg, P)
%RUNSCENARIOS  Every barrier option compared in each case study.
%
%   BASELINES
%     actual  - the barrier that was really there that day
%     tecpro  - a standard TecPro barrier in the same place
%   OUR SYSTEM - FOUR OPTIONS (TecPro always unchanged)
%     sled    - option 1: TecPro + 20 cm force-limiting sled
%     rams    - option 2: TecPro + parallel hydraulic rams (0 cm extra)
%     nocam   - option 3: rams + sled, NO camera (on-board sensors only)
%     smart   - option 4: COMPLETE system: rams + sled + camera prediction
%   FAIL-SAFE CHECK
%     failed  - complete system with hydraulics/electronics offline
%               (rams fail open, sled locked) -> must equal TecPro
%
%   crash : case data (see cases/*.m)    car : carModel.m
%   cond  : weatherScenario.m            angleDeg : impact angle [deg]

    [Pc, vImp_kmh] = applyConditions(P, cond, crash);
    vN = vImp_kmh/3.6 * sind(angleDeg);           % normal component [m/s]

    bActual = barrierModel(crash.barrierType, cond.foamScale);
    bTecPro = barrierModel('tecpro',          cond.foamScale);
    Cact = buildContact(car, bActual);
    Ctec = buildContact(car, bTecPro);

    Pnc  = Pc;  Pnc.cameraOK      = false;        % option 3: no camera
    Poff = Pc;  Poff.systemOnline = false;        % fail-safe test

    R.actual = simulateCrash('passive', vN, car, Cact, Pc);
    R.tecpro = simulateCrash('passive', vN, car, Ctec, Pc);
    R.sled   = simulateCrash('sled',    vN, car, Ctec, Pc);
    R.rams   = simulateCrash('rams',    vN, car, Ctec, Pc);
    R.nocam  = simulateCrash('smart',   vN, car, Ctec, Pnc);
    R.smart  = simulateCrash('smart',   vN, car, Ctec, Pc);
    R.failed = simulateCrash('smart',   vN, car, Ctec, Poff);

    f = fieldnames(R);
    for k = 1:numel(f), M.(f{k}) = crashMetrics(R.(f{k}), Pc); end

    info.vImpact_kmh = vImp_kmh;
    info.vNormal     = vN;
    info.KE_kJ       = 0.5*car.mass*vN^2/1e3;
    info.angle       = angleDeg;
    info.barrierName = bActual.name;
    info.cond        = cond;
end
