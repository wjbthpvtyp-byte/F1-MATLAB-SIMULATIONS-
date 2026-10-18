function gBest = theoreticalBest(KE, S, car, C, P)
%THEORETICALBEST  Lowest possible peak deceleration [g] for this crash and space.
%   With TecPro unchanged, the foam only crushes where its own force is at
%   least the force on the car. The best any controller can do is hold one
%   constant force F from first contact to stop, using the rams while the
%   foam is softer than F and then the sled stroke S:
%            F * (crush depth where foam reaches F + S) = KE
%   (no hardware limits, no valve lag, perfect camera).
    Q = P;  Q.Fmax = 2e7;  Q.Fmin = 1;  Q.sf = 1;  Q.ram_stroke = Inf;
    F = solveTarget(KE, 0, S, true, S > 0, C, Q);
    gBest = F/(car.mass*P.g);
end
