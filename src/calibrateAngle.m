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
