function H = hic15(t, a)
%HIC15  Head Injury Criterion over a 15 ms window.
%   HIC = max over windows (t2-t1 <= 15 ms) of (t2-t1) * [mean a]^2.5, a in g.
%   Car deceleration is used as a proxy for head acceleration; real HIC
%   needs a dummy head sensor. HIC15 = 700 is the usual injury threshold.
    dtc = 1e-4;
    tc  = (t(1):dtc:t(end))';
    if numel(tc) < 3, H = 0; return; end
    ac  = max(interp1(t, a, tc), 0);
    I   = [0; cumsum(ac)*dtc];
    H   = 0;
    for w = 1:min(round(0.015/dtc), numel(I) - 1)
        T   = w*dtc;
        avg = (I(1+w:end) - I(1:end-w))/T;
        H   = max(H, max(T*avg.^2.5));
    end
end
