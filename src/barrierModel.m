function b = barrierModel(type, foamScale, depth)
%BARRIERMODEL  Crush behaviour of a trackside barrier.
%   b = barrierModel(type)            type: 'concrete','armco','tyre','tecpro'
%   b = barrierModel(type, foamScale, depth): depth = TecPro stack depth
%   b = barrierModel(type, foamScale) scales the force of deformable
%                                     barriers (temperature effect, see
%                                     applyConditions.m). Default 1.
%
%   Force b.F(i) is reached at barrier deformation b.d(i). Beyond the last
%   point the barrier is solid (stiffness b.kEnd).
%
%   CONCRETE is effectively rigid. TECPRO values follow the concept model
%   used throughout this project. ARMCO and TYRE values are first estimates
%   and MUST be calibrated against recorded crashes (Grosjean 2020 for
%   Armco, Schumacher 1999 / Barrichello 1994 for tyres).

    if nargin < 2 || isempty(foamScale), foamScale = 1; end
    if nargin < 3 || isempty(depth), depth = 1.0; end   % TecPro stack depth [m]

    switch lower(type)
        case 'concrete'
            b.name = 'Unprotected concrete wall';
            b.d = [0  0.001];   b.F = [0  0.5e6];   b.kEnd = 5e8;
        case 'armco'
            b.name = 'Steel guardrail (Armco)';
            b.d = [0  0.05  0.60];  b.F = [0  150e3  350e3];  b.kEnd = 5e8;
        case 'tyre'
            b.name = 'Tyre barrier';
            b.d = [0  0.02  0.70];  b.F = [0  40e3   300e3];  b.kEnd = 5e8;
        case 'tecpro'
            % More rows of the same blocks in series: same forces, crush
            % depths scaled with the stack depth (deep TecPro reference).
            b.name = sprintf('TecPro barrier (%.2f m)', depth);
            b.d = [0  0.02  1.00]*depth;  b.F = [0  60e3   360e3];  b.kEnd = 5e8;
        otherwise
            error('barrierModel: unknown type "%s"', type);
    end
    if ~strcmpi(type, 'concrete')
        b.F = b.F * foamScale;
    end
    b.type = lower(type);
end
