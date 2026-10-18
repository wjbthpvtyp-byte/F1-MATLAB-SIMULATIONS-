function [R, M, info] = runFourScenarios(crash, car, cond, angleDeg, P)
%RUNFOURSCENARIOS  The four barrier situations every case study compares.
%   1. ACTUAL   - the barrier that was really there that day
%   2. TECPRO   - a standard TecPro barrier in the same place
%   3. SMART    - our system: TecPro (unchanged) + rams + 20 cm sled + camera
%   4. FAILED   - our system with hydraulics/electronics offline
%                 (rams fail open, sled locked) -> must equal TECPRO
%
%   crash : case data (see cases/*.m)    car : carModel.m
%   cond  : weatherScenario.m            angleDeg : impact angle [deg]

    [Pc, vImp_kmh] = applyConditions(P, cond, crash);
    vN = vImp_kmh/3.6 * sind(angleDeg);           % normal component [m/s]

    bActual = barrierModel(crash.barrierType, cond.foamScale);
    bTecPro = barrierModel('tecpro',          cond.foamScale);
    Cact = buildContact(car, bActual);
    Ctec = buildContact(car, bTecPro);

    R.actual = simulateCrash('passive', vN, car, Cact, Pc);
    R.tecpro = simulateCrash('passive', vN, car, Ctec, Pc);
    R.smart  = simulateCrash('smart',   vN, car, Ctec, Pc);
    Poff = Pc;  Poff.systemOnline = false;        % hydraulics/electronics offline
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
