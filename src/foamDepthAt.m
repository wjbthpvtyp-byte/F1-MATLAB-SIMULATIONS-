function d = foamDepthAt(F, C)
%FOAMDEPTHAT  Crush depth at which the contact force reaches F (inverse of crushForce).
    if F <= 0, d = 0; return; end
    Fend = C.FTab2(end);
    if F >= Fend
        d = C.dTab2(end) + (F - Fend)/C.kEnd;
        return;
    end
    x = F/C.dF;
    i = floor(x);
    w = x - i;
    d = (1 - w)*C.dTab2(i+1) + w*C.dTab2(i+2);
end
