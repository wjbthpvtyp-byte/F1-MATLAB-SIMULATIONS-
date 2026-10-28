function C = buildContact(car, barrier)
%BUILDCONTACT  Combine car crush and barrier crush into one contact curve.
%   The car and the barrier are in SERIES: the same force F acts on both,
%   so the total crush is   d_total(F) = d_barrier(F) + d_car(F).
%   The weaker element therefore crushes first, automatically.
%
%   The result is stored on uniform grids so the time loop can look up
%   force-from-crush (crushForce) and crush-from-force (foamDepthAt) fast.

    Fmax = 3e6;                                   % table range [N]
    Fq   = linspace(0, Fmax, 6001)';              % uniform force grid
    dq   = elemDepth(Fq, barrier) + elemDepth(Fq, car);

    C.kEnd = 1/(1/barrier.kEnd + 1/car.kEnd);     % series stiffness beyond table

    % force-from-crush on a uniform crush grid
    C.dd   = 1e-4;
    C.dTab = (0:C.dd:dq(end))';
    C.FTab = interp1(dq, Fq, C.dTab, 'linear');
    C.dEnd = C.dTab(end);  C.FEnd = C.FTab(end);

    % crush-from-force on the uniform force grid
    C.dF    = Fq(2) - Fq(1);
    C.FTab2 = Fq;  C.dTab2 = dq;

    C.carName = car.name;  C.barrierName = barrier.name;
end

function d = elemDepth(F, e)
% Deformation of one element (car or barrier) under force F.
    d = zeros(size(F));
    in = F <= e.F(end);
    d(in)  = interp1(e.F, e.d, F(in), 'linear');
    d(~in) = e.d(end) + (F(~in) - e.F(end))/e.kEnd;
end
