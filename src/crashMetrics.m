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
