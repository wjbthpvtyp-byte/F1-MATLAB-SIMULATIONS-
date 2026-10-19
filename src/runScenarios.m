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
%   Space-matched references (not cases): passive TecPro as deep as the
%   space of Case 3 (1.2 m, R.deepSmall) and of Case 4 (3.5 m, R.deepLarge).
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

    % Space-matched passive references: TecPro stacked as deep as the space
    % each configuration of our system occupies (1.0 m + sled stroke).
    Cds = buildContact(car, barrierModel('tecpro', cond.foamScale, 1.0 + P.S));
    Cdl = buildContact(car, barrierModel('tecpro', cond.foamScale, 1.0 + P.S_large));
    R.deepSmall = simulateCrash('passive', vN, car, Cds, Pc);
    R.deepLarge = simulateCrash('passive', vN, car, Cdl, Pc);

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
