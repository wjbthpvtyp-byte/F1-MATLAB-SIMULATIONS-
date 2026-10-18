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
