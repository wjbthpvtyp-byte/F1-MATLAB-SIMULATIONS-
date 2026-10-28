function Ft = solveTarget(KE, d, rem, useRams, useSled, C, P)
%SOLVETARGET  Lowest constant force that still absorbs the kinetic energy KE.
%   d    : current crush depth [m]
%   rem  : sled stroke still available [m]   (rem = P.S - sled travel)
%   The controller wants the force on the driver to be as low and as flat
%   as possible, while making sure the car stops before the barrier,
%   the rams and the sled run out of travel.
    lo = P.Fmin;  hi = P.Fmax;
    if absorbedEnergy(hi, d, rem, useRams, useSled, C, P) < KE
        Ft = hi; return;
    end
    for it = 1:30                                   % bisection
        mid = 0.5*(lo + hi);
        if absorbedEnergy(mid, d, rem, useRams, useSled, C, P) < KE
            lo = mid;
        else
            hi = mid;
        end
    end
    Ft = hi*P.sf;
end

function E = absorbedEnergy(F, d, rem, useRams, useSled, C, P)
% Energy still absorbable if the force on the car is held at F.
    dF = max(foamDepthAt(F, C), d);                 % where the barrier alone reaches F
    if useRams
        % Inside the ram stroke the rams top the force up to a flat F.
        Ebar = F*max(0, min(dF, P.ram_stroke) - d);
        % Beyond the ram stroke the barrier and car nose keep absorbing alone.
        a = max(d, P.ram_stroke);
        if dF > a
            x = linspace(a, dF, 25);
            Ebar = Ebar + trapz(x, crushForce(x, C));
        end
    else
        x = linspace(d, dF, 25);
        Ebar = trapz(x, crushForce(x, C));
    end
    E = Ebar + F*rem*useSled;
end
