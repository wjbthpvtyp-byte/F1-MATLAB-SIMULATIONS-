function F = crushForce(d, C)
%CRUSHFORCE  Loading force when the car+barrier contact is crushed by d [m].
%   Fast table lookup (works for scalars and vectors).
    F = zeros(size(d));
    in  = d <= C.dEnd;
    din = d(in);
    x   = max(din(:), 0)/C.dd;                 % force column shape so it matches C.FTab
    i   = min(floor(x), numel(C.dTab) - 2);
    w   = x - i;
    F(in)  = (1 - w).*C.FTab(i+1) + w.*C.FTab(i+2);
    F(~in) = C.FEnd + C.kEnd*(d(~in) - C.dEnd);
end
