%% =====================================================================
%  F1 SMART BARRIER — FINITE ELEMENT ANALYSIS OF THE SLED DECK PLATE
%  ---------------------------------------------------------------------
%  Question: can the steel deck of the sled carry the largest force the
%  hydraulic system can transmit, with an adequate margin to yield?
%
%  Model    : 2D linear-elastic plane stress, bilinear Q4 elements, 2x2 Gauss
%  Plate    : horizontal sled deck in plan view, 2.0 m along the track (x)
%             x 1.0 m deep (y), thickness t. The car's push is horizontal,
%             i.e. IN the plane of the deck, so plane stress applies.
%  Material : structural steel S355 (E = 210 GPa, nu = 0.3, fy = 355 MPa)
%  Load     : design force F = 600 kN (the controller's maximum target
%             force = the hydraulic system's capacity), applied as a uniform
%             traction on the front edge (y = 1.0 m) over a 0.6 m patch:
%               LC1 centred impact   x = 0.7 ... 1.3 m
%               LC2 impact at the end of the module   x = 0.0 ... 0.6 m
%             The largest force in any Case 3 simulation within the system's
%             energy capacity was 521 kN (Brayton 1996, heavy rain; 15 crashes
%             x 8 conditions). 19 of 120 runs exceeded the capacity (all
%             Ratzenberger and Cevert runs, 3 wet Silverstone 1999 runs).
%  Supports : three hydraulic cylinder mounts on the rear edge (y = 0),
%             0.2 m wide, centred at x = 0.3, 1.0, 1.7 m: uy = 0.
%             Rail guide at the middle mount: ux = 0 (stops rigid sliding).
%  Quasi-static: the load lasts 50-200 ms, far longer than the plate's
%             in-plane natural periods (well below 1 ms), so inertia is
%             neglected.
%  Mesh study: 20x10, 40x20, 80x40 elements.
%
%  Corrections to the first FEA script (see docs/fea_notes.md):
%   - plate thickness is now included (it was implicitly 1 m)
%   - load comes from the dynamic model, applied over a contact patch
%   - discrete cylinder supports instead of a fully clamped edge
%   - stresses averaged from elements to nodes (no griddata edge artefacts)
%   - deformed shape scale chosen automatically
%  =====================================================================
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
outDir = fullfile(here, '..', 'results', 'fea');
if ~exist(outDir, 'dir'), mkdir(outDir); end

%% ---------------- INPUTS ----------------------------------------------
mat.E  = 210e9;   mat.nu = 0.30;   mat.fy = 355e6;
geo.Lx = 2.0;     geo.Ly = 1.0;    geo.t  = 0.020;      % 20 mm deck
F_design = 600e3;                                       % [N]
supports.x = [0.3 1.0 1.7];  supports.w = 0.2;          % cylinder mounts [m]
loadCases = struct('name', {'LC1 centred impact', 'LC2 impact at module end'}, ...
                   'patch', {[0.7 1.3], [0.0 0.6]});
meshes = [20 10; 40 20; 80 40];
bandFromSupports = 0.10;   % stresses reported away from the support edge [m]

%% ---------------- MESH CONVERGENCE STUDY ------------------------------
fprintf('Sled deck FEA: %.0f mm S355 plate, design load %.0f kN\n\n', geo.t*1e3, F_design/1e3);
fprintf('%-26s %8s %14s %18s %8s %12s\n', 'Load case', 'Mesh', 'Max VM (MPa)', ...
        'VM >0.1 m from sup.', 'SF', 'Max u (mm)');
res = struct();
for lc = 1:numel(loadCases)
    for m = 1:size(meshes, 1)
        r = solvePlate(meshes(m,1), meshes(m,2), geo, mat, F_design, ...
                       loadCases(lc).patch, supports, bandFromSupports);
        res(lc, m).r = r;
        fprintf('%-26s %3dx%-4d %14.1f %18.1f %8.2f %12.3f\n', loadCases(lc).name, ...
            meshes(m,1), meshes(m,2), r.vmMax/1e6, r.vmInterior/1e6, ...
            mat.fy/r.vmInterior, r.uMax*1e3);
    end
end
fprintf('\nPeak values at the edges of the supports grow with refinement: that\n');
fprintf('is the stress singularity of a sharp support, not a converged result.\n');
fprintf('Displacement and stress away from the supports converge and are used.\n');

%% ---------------- FIGURES (finest mesh) -------------------------------
for lc = 1:numel(loadCases)
    r = res(lc, end).r;
    f = figure('Name', loadCases(lc).name, 'Color', 'w', 'Position', [60 60 1300 520]);
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    patch('Faces', r.conn, 'Vertices', r.xy, 'FaceVertexCData', r.vmNode/1e6, ...
          'FaceColor', 'interp', 'EdgeColor', 'none');
    hold on; axis equal tight; colormap(gca, jet);
    cb = colorbar; cb.Label.String = 'Von Mises stress (MPa)';
    drawSupportsAndLoad(supports, loadCases(lc).patch, geo);
    xlabel('x along track (m)'); ylabel('y depth (m)');
    title(sprintf('%s: von Mises, %.0f kN, t = %.0f mm', loadCases(lc).name, ...
          F_design/1e3, geo.t*1e3));

    nexttile;
    scale = 0.1*geo.Ly/max(r.uMax, eps);                 % largest motion drawn as 10 % of depth
    def = r.xy + scale*[r.u(1:2:end) r.u(2:2:end)];
    patch('Faces', r.conn, 'Vertices', def, 'FaceVertexCData', r.uMag*1e3, ...
          'FaceColor', 'interp', 'EdgeColor', [0.7 0.7 0.7], 'EdgeAlpha', 0.3);
    hold on; axis equal tight; colormap(gca, parula);
    cb = colorbar; cb.Label.String = 'Displacement (mm)';
    patch('Faces', [1 2 3 4], 'Vertices', [0 0; geo.Lx 0; geo.Lx geo.Ly; 0 geo.Ly], ...
          'FaceColor', 'none', 'EdgeColor', 'k', 'LineStyle', '--');
    xlabel('x along track (m)'); ylabel('y depth (m)');
    title(sprintf('Deformed shape (x%.0f), max %.3f mm', scale, r.uMax*1e3));
    exportgraphics(f, fullfile(outDir, sprintf('fea_LC%d.png', lc)), 'Resolution', 200);
end

%% ---------------- CONVERGENCE TABLE -----------------------------------
rows = {};
for lc = 1:numel(loadCases)
    for m = 1:size(meshes, 1)
        r = res(lc, m).r;
        rows(end+1, :) = {loadCases(lc).name, sprintf('%dx%d', meshes(m,1), meshes(m,2)), ...
            r.vmMax/1e6, r.vmInterior/1e6, mat.fy/r.vmInterior, r.uMax*1e3}; %#ok<SAGROW>
    end
end
T = cell2table(rows, 'VariableNames', {'LoadCase', 'Mesh', 'MaxVonMises_MPa', ...
    'VonMisesAwayFromSupports_MPa', 'SafetyFactor', 'MaxDisplacement_mm'});
writetable(T, fullfile(outDir, 'fea_mesh_convergence.csv'));
fprintf('\nResults saved in %s\n', outDir);


%% =====================================================================
%                          LOCAL FUNCTIONS
%  =====================================================================
function r = solvePlate(nx, ny, geo, mat, F, patchX, supports, band)
    Lx = geo.Lx;  Ly = geo.Ly;  t = geo.t;
    xs = linspace(0, Lx, nx+1);  ys = linspace(0, Ly, ny+1);
    [X, Y] = meshgrid(xs, ys);                      % (ny+1) x (nx+1)
    xy = [reshape(X', [], 1) reshape(Y', [], 1)];   % node k = j*(nx+1) + i + 1
    nid = @(i, j) j*(nx+1) + i + 1;                 % i = 0..nx, j = 0..ny
    nN = (nx+1)*(ny+1);  nE = nx*ny;
    dx = Lx/nx;  dy = Ly/ny;

    D = mat.E/(1 - mat.nu^2) * [1 mat.nu 0; mat.nu 1 0; 0 0 (1 - mat.nu)/2];

    % element stiffness (all elements are identical rectangles)
    g = [-1 1]/sqrt(3);
    Ke = zeros(8);
    for a = g
        for b = g
            Bm = bmat(a, b, dx, dy);
            Ke = Ke + Bm'*D*Bm * (dx*dy/4) * t;
        end
    end

    conn = zeros(nE, 4);  e = 0;
    for j = 0:ny-1
        for i = 0:nx-1
            e = e + 1;
            conn(e,:) = [nid(i,j) nid(i+1,j) nid(i+1,j+1) nid(i,j+1)];
        end
    end
    dofs = zeros(nE, 8);
    dofs(:, 1:2:end) = 2*conn - 1;  dofs(:, 2:2:end) = 2*conn;
    I = repmat(dofs, 1, 8)';                         % row indices
    J = kron(dofs, ones(1, 8))';                     % column indices
    V = repmat(Ke(:), 1, nE);
    K = sparse(I(:), J(:), V(:), 2*nN, 2*nN);

    % consistent nodal loads: uniform traction on the front edge, -y direction
    f = zeros(2*nN, 1);
    q = F/(patchX(2) - patchX(1));                   % [N/m]
    for i = 0:nx-1
        x0 = xs(i+1);  x1 = xs(i+2);
        a = max(x0, patchX(1));  b = min(x1, patchX(2));
        if b > a
            L = b - a;  xm = (a + b)/2;  w1 = (x1 - xm)/dx;
            f(2*nid(i,ny))   = f(2*nid(i,ny))   - q*L*w1;
            f(2*nid(i+1,ny)) = f(2*nid(i+1,ny)) - q*L*(1 - w1);
        end
    end

    % supports: cylinder mounts on the rear edge (uy), rail guide (ux)
    fixed = [];
    for i = 0:nx
        if any(abs(xs(i+1) - supports.x) <= supports.w/2 + 1e-9)
            fixed(end+1) = 2*nid(i, 0); %#ok<AGROW>
        end
    end
    [~, ic] = min(abs(xs - 1.0));
    fixed(end+1) = 2*nid(ic-1, 0) - 1;
    free = setdiff(1:2*nN, fixed);

    u = zeros(2*nN, 1);
    u(free) = K(free, free) \ f(free);

    % stresses at element centres, then averaged to the nodes
    B0 = bmat(0, 0, dx, dy);
    vmE = zeros(nE, 1);
    for e = 1:nE
        s = D*B0*u(dofs(e,:));
        vmE(e) = sqrt(s(1)^2 - s(1)*s(2) + s(2)^2 + 3*s(3)^2);
    end
    vmNode = accumarray(conn(:), repmat(vmE, 4, 1), [nN 1]) ./ ...
             accumarray(conn(:), 1, [nN 1]);

    yc = mean(reshape(xy(conn', 2), 4, []))';
    r.vmMax      = max(vmE);
    r.vmInterior = max(vmE(yc > band));
    r.u = u;  r.uMag = sqrt(u(1:2:end).^2 + u(2:2:end).^2);  r.uMax = max(r.uMag);
    r.xy = xy;  r.conn = conn;  r.vmNode = vmNode;  r.vmElem = vmE;
end

function Bm = bmat(xi, eta, dx, dy)
% Strain-displacement matrix of a rectangular Q4 element (dx by dy).
    dNx = 0.25*[-(1-eta)  (1-eta)  (1+eta) -(1+eta)] * 2/dx;
    dNy = 0.25*[-(1-xi)  -(1+xi)   (1+xi)   (1-xi)]  * 2/dy;
    Bm = zeros(3, 8);
    Bm(1, 1:2:end) = dNx;
    Bm(2, 2:2:end) = dNy;
    Bm(3, 1:2:end) = dNy;
    Bm(3, 2:2:end) = dNx;
end

function drawSupportsAndLoad(supports, patchX, geo)
    for k = 1:numel(supports.x)
        x0 = supports.x(k) - supports.w/2;
        fill([x0 x0+supports.w x0+supports.w x0], [-0.06 -0.06 0 0], [0.3 0.3 0.3], ...
             'EdgeColor', 'none');
    end
    xa = linspace(patchX(1), patchX(2), 5);
    quiver(xa, geo.Ly + 0.12 + 0*xa, 0*xa, -0.1 + 0*xa, 0, 'r', 'LineWidth', 1.5, ...
           'MaxHeadSize', 0.6);
    text(mean(patchX), geo.Ly + 0.16, 'Impact load', 'Color', 'r', ...
         'HorizontalAlignment', 'center');
    text(supports.x(1), -0.10, 'Cylinder mounts', 'HorizontalAlignment', 'left');
    ylim([-0.15 geo.Ly + 0.22]);
end
