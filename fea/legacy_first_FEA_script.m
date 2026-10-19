% =========================================================
%  F1 Retractable Barrier — Finite Element Analysis (FEA)
%  2D Plane Stress — Von Mises Stress & Strain Mesh Plots
%  Models the barrier plate under F1 impact load
% =========================================================

clear; clc; close all;

%% ── MATERIAL PROPERTIES (Steel barrier plate) ────────────
E  = 200e9;   % Pa  | Young's modulus (steel)
nu = 0.30;    % [-] | Poisson's ratio
ty = 250e6;   % Pa  | Yield strength

%% ── GEOMETRY ─────────────────────────────────────────────
Lx = 2.0;   % m | Barrier width
Ly = 1.0;   % m | Barrier height

%% ── MESH PARAMETERS ──────────────────────────────────────
nx = 30;    % elements in x
ny = 15;    % elements in y

% Node coordinates
x_nodes = linspace(0, Lx, nx+1);
y_nodes = linspace(0, Ly, ny+1);
[X, Y]  = meshgrid(x_nodes, y_nodes);

nNodes   = (nx+1)*(ny+1);
nElem    = nx*ny;
nDOF     = nNodes * 2;   % 2 DOF per node (ux, uy)

% Node numbering: node(i,j) = (j-1)*(nx+1) + i  [row-major]
nodeID = reshape(1:nNodes, nx+1, ny+1)';  % (ny+1) x (nx+1)

%% ── ELEMENT CONNECTIVITY (Q4 bilinear quads) ─────────────
conn = zeros(nElem, 4);
eID  = 0;
for j = 1:ny
    for i = 1:nx
        eID = eID + 1;
        n1 = nodeID(j,   i  );
        n2 = nodeID(j,   i+1);
        n3 = nodeID(j+1, i+1);
        n4 = nodeID(j+1, i  );
        conn(eID,:) = [n1 n2 n3 n4];
    end
end

%% ── PLANE STRESS CONSTITUTIVE MATRIX ─────────────────────
C = (E/(1-nu^2)) * [1  nu 0;
                     nu 1  0;
                     0  0  (1-nu)/2];

%% ── ASSEMBLE GLOBAL STIFFNESS MATRIX ─────────────────────
K = sparse(nDOF, nDOF);

% Gauss quadrature points & weights (2x2)
gp = [-1/sqrt(3), 1/sqrt(3)];
gw = [1, 1];

fprintf('Assembling stiffness matrix...\n');

for e = 1:nElem
    nodes_e = conn(e,:);             % 4 node IDs
    xe = X(1, mod(nodes_e-1,nx+1)+1 );  % x-coords (approx via mesh)
    
    % Get actual nodal coords
    coords = zeros(4,2);
    for k=1:4
        nd = nodes_e(k);
        [row,col] = find(nodeID == nd);
        coords(k,1) = x_nodes(col);
        coords(k,2) = y_nodes(row);
    end
    
    Ke = zeros(8,8);
    
    for i=1:2
        for j=1:2
            xi  = gp(i); eta = gp(j);
            wi  = gw(i); wj  = gw(j);
            
            % Shape functions N1..N4
            N  = 0.25*[(1-xi)*(1-eta); (1+xi)*(1-eta); ...
                       (1+xi)*(1+eta); (1-xi)*(1+eta)];
            
            % Shape fn derivatives w.r.t. xi, eta
            dN_dxi  = 0.25*[-(1-eta);  (1-eta);  (1+eta); -(1+eta)];
            dN_deta = 0.25*[-(1-xi); -(1+xi);  (1+xi);  (1-xi)];
            
            % Jacobian
            J = [dN_dxi'; dN_deta'] * coords;
            detJ = det(J);
            dN_dx = J \ [dN_dxi'; dN_deta'];
            dN_dx = dN_dx';  % 4x2
            
            % B matrix (3x8)
            B = zeros(3,8);
            for k=1:4
                B(1,2*k-1) = dN_dx(k,1);
                B(2,2*k  ) = dN_dx(k,2);
                B(3,2*k-1) = dN_dx(k,2);
                B(3,2*k  ) = dN_dx(k,1);
            end
            
            Ke = Ke + wi*wj * B' * C * B * detJ;
        end
    end
    
    % Assemble into global K
    dofs = zeros(1,8);
    for k=1:4
        dofs(2*k-1) = 2*nodes_e(k)-1;
        dofs(2*k  ) = 2*nodes_e(k);
    end
    K(dofs, dofs) = K(dofs, dofs) + Ke;
end

fprintf('Assembly complete.\n');

%% ── BOUNDARY CONDITIONS ───────────────────────────────────
% Left edge (x=0): fixed in x (retract side — barrier slides)
% Bottom edge (y=0): fixed in y (mounting rail)
fixed_dofs = [];

% Left edge nodes: col 1 of nodeID → fix ux
left_nodes = nodeID(:,1);
fixed_dofs = [fixed_dofs; 2*left_nodes(:)-1];   % ux DOFs

% Bottom edge: fix uy
bottom_nodes = nodeID(1,:);
fixed_dofs = [fixed_dofs; 2*bottom_nodes(:)];    % uy DOFs

fixed_dofs = unique(fixed_dofs);
free_dofs  = setdiff(1:nDOF, fixed_dofs)';

%% ── APPLY LOAD ────────────────────────────────────────────
% F1 car impact force distributed along right edge (x = Lx)
% From earlier simulation: retractable barrier sees ~120 kN
F_total = 120e3;   % N (distributed)

f = zeros(nDOF, 1);
right_nodes = nodeID(:, end);   % right edge nodes
n_right = length(right_nodes);
F_per_node = F_total / n_right;

for k = 1:n_right
    nd = right_nodes(k);
    f(2*nd-1) = -F_per_node;   % negative x-direction (impact pushes left)
end

%% ── SOLVE ─────────────────────────────────────────────────
fprintf('Solving system...\n');
U = zeros(nDOF, 1);
U(free_dofs) = K(free_dofs, free_dofs) \ f(free_dofs);
fprintf('Solve complete.\n');

%% ── COMPUTE STRESS & STRAIN AT ELEMENT CENTROIDS ─────────
sigma_vm = zeros(nElem, 1);   % Von Mises stress
eps_vm   = zeros(nElem, 1);   % equivalent strain
sigma_xx = zeros(nElem, 1);
sigma_yy = zeros(nElem, 1);
tau_xy   = zeros(nElem, 1);
elem_cx  = zeros(nElem, 1);
elem_cy  = zeros(nElem, 1);

for e = 1:nElem
    nodes_e = conn(e,:);
    
    coords = zeros(4,2);
    for k=1:4
        nd = nodes_e(k);
        [row,col] = find(nodeID == nd);
        coords(k,1) = x_nodes(col);
        coords(k,2) = y_nodes(row);
    end
    elem_cx(e) = mean(coords(:,1));
    elem_cy(e) = mean(coords(:,2));
    
    % Evaluate at centroid (xi=0, eta=0)
    xi=0; eta=0;
    dN_dxi  = 0.25*[-(1-eta);  (1-eta);  (1+eta); -(1+eta)];
    dN_deta = 0.25*[-(1-xi); -(1+xi);  (1+xi);  (1-xi)];
    J = [dN_dxi'; dN_deta'] * coords;
    dN_dx = (J \ [dN_dxi'; dN_deta'])';
    
    B = zeros(3,8);
    for k=1:4
        B(1,2*k-1) = dN_dx(k,1);
        B(2,2*k  ) = dN_dx(k,2);
        B(3,2*k-1) = dN_dx(k,2);
        B(3,2*k  ) = dN_dx(k,1);
    end
    
    dofs = zeros(1,8);
    for k=1:4
        dofs(2*k-1) = 2*nodes_e(k)-1;
        dofs(2*k  ) = 2*nodes_e(k);
    end
    Ue = U(dofs);
    
    strain = B * Ue;       % [eps_xx; eps_yy; gamma_xy]
    stress = C * strain;   % [sig_xx; sig_yy; tau_xy]
    
    sigma_xx(e) = stress(1);
    sigma_yy(e) = stress(2);
    tau_xy(e)   = stress(3);
    
    % Von Mises stress
    sigma_vm(e) = sqrt(stress(1)^2 - stress(1)*stress(2) + ...
                       stress(2)^2 + 3*stress(3)^2);
    
    % Equivalent strain
    eps_vm(e) = sigma_vm(e) / E;
end

%% ── NODAL AVERAGING ──────────────────────────────────────
% Interpolate element centroid values to nodes for smooth mesh plot
sigma_node = griddata(elem_cx, elem_cy, sigma_vm/1e6, X, Y, 'linear');
strain_node = griddata(elem_cx, elem_cy, eps_vm*1e3,  X, Y, 'linear');
% Fill NaN edges
sigma_node(isnan(sigma_node)) = 0;
strain_node(isnan(strain_node)) = 0;

%% ── DISPLACEMENT FIELD ───────────────────────────────────
ux_node = reshape(U(1:2:end), nx+1, ny+1)';
uy_node = reshape(U(2:2:end), nx+1, ny+1)';
disp_mag = sqrt(ux_node.^2 + uy_node.^2)*1e3;  % mm

%% ═══════════════════════════════════════════════════════════
%                        PLOTS
% ═══════════════════════════════════════════════════════════
bg = [0.08 0.08 0.12];

%% ── FIGURE 1: Von Mises Stress ───────────────────────────
figure('Name','Von Mises Stress','Color',bg,'Position',[50 400 700 420]);
ax1 = axes; set(ax1,'Color',bg,'XColor','w','YColor','w','FontSize',11);
hold on;

pcolor(X, Y, sigma_node);
shading interp;
colormap(ax1, hot);
cb = colorbar; cb.Color = 'w'; cb.Label.String = 'Von Mises Stress (MPa)';
cb.Label.Color = 'w'; cb.Label.FontSize = 11;

% Overlay mesh
for j=1:ny+1
    plot(x_nodes, y_nodes(j)*ones(1,nx+1), 'w-', 'LineWidth',0.15);
end
for i=1:nx+1
    plot(x_nodes(i)*ones(1,ny+1), y_nodes, 'w-','LineWidth',0.15);
end

% Yield contour
[~,hc] = contour(X, Y, sigma_node, [ty/1e6 ty/1e6], 'c-','LineWidth',2);
text(0.05, 0.92, sprintf('Yield line (%.0f MPa)', ty/1e6), 'Units','normalized',...
    'Color','c','FontSize',10,'FontWeight','bold');

% Impact arrow
annotation('arrow',[0.87 0.81],[0.5 0.5],'Color','y','LineWidth',2,'HeadWidth',12);
text(Lx*1.02, Ly/2, 'Impact','Color','y','FontSize',10,'FontWeight','bold');

xlabel('x (m)','Color','w'); ylabel('y (m)','Color','w');
title('Von Mises Stress Distribution — F1 Barrier FEA','Color','w',...
    'FontSize',14,'FontWeight','bold');
axis equal tight; xlim([-0.05 Lx+0.15]);

%% ── FIGURE 2: Equivalent Strain ──────────────────────────
figure('Name','Equivalent Strain','Color',bg,'Position',[780 400 700 420]);
ax2 = axes; set(ax2,'Color',bg,'XColor','w','YColor','w','FontSize',11);
hold on;

pcolor(X, Y, strain_node);
shading interp;
colormap(ax2, parula);
cb2 = colorbar; cb2.Color = 'w';
cb2.Label.String = 'Equivalent Strain (×10⁻³)';
cb2.Label.Color = 'w'; cb2.Label.FontSize = 11;

for j=1:ny+1
    plot(x_nodes, y_nodes(j)*ones(1,nx+1),'w-','LineWidth',0.15);
end
for i=1:nx+1
    plot(x_nodes(i)*ones(1,ny+1), y_nodes,'w-','LineWidth',0.15);
end

annotation('arrow',[0.87 0.81],[0.5 0.5],'Color','y','LineWidth',2,'HeadWidth',12);
text(Lx*1.02, Ly/2, 'Impact','Color','y','FontSize',10,'FontWeight','bold');

xlabel('x (m)','Color','w'); ylabel('y (m)','Color','w');
title('Equivalent Strain Distribution — F1 Barrier FEA','Color','w',...
    'FontSize',14,'FontWeight','bold');
axis equal tight; xlim([-0.05 Lx+0.15]);

%% ── FIGURE 3: Displacement Magnitude ────────────────────
figure('Name','Displacement','Color',bg,'Position',[50 50 700 380]);
ax3 = axes; set(ax3,'Color',bg,'XColor','w','YColor','w','FontSize',11);
hold on;

pcolor(X, Y, disp_mag);
shading interp;
colormap(ax3, cool);
cb3 = colorbar; cb3.Color = 'w';
cb3.Label.String = 'Displacement Magnitude (mm)';
cb3.Label.Color = 'w'; cb3.Label.FontSize = 11;

% Deformed mesh overlay (scaled)
scale = 50;
for j=1:ny+1
    xd = x_nodes + scale*ux_node(j,:);
    yd = y_nodes(j) + scale*uy_node(j,:);
    plot(xd, yd, 'w-','LineWidth',0.4);
end
for i=1:nx+1
    xd = x_nodes(i) + scale*ux_node(:,i)';
    yd = y_nodes  + scale*uy_node(:,i)';
    plot(xd, yd,'w-','LineWidth',0.4);
end

text(0.02,0.05,sprintf('Deformed shape scale: ×%d',scale),'Units','normalized',...
    'Color',[0.8 0.8 0.8],'FontSize',9);

xlabel('x (m)','Color','w'); ylabel('y (m)','Color','w');
title('Displacement Field + Deformed Mesh (Scaled)','Color','w',...
    'FontSize',14,'FontWeight','bold');
axis equal tight; xlim([-0.1 Lx+0.2]);

%% ── FIGURE 4: Combined Dashboard ─────────────────────────
figure('Name','FEA Dashboard','Color',bg,'Position',[780 50 700 420]);

subplot(1,2,1);
set(gca,'Color',bg,'XColor','w','YColor','w','FontSize',9); hold on;
pcolor(X, Y, sigma_node); shading interp; colormap(gca, hot);
cb = colorbar; cb.Color='w'; cb.FontSize=8;
title('Von Mises (MPa)','Color','w','FontSize',11,'FontWeight','bold');
axis equal tight; xlabel('x (m)','Color','w'); ylabel('y (m)','Color','w');

subplot(1,2,2);
set(gca,'Color',bg,'XColor','w','YColor','w','FontSize',9); hold on;
pcolor(X, Y, strain_node); shading interp; colormap(gca, parula);
cb2 = colorbar; cb2.Color='w'; cb2.FontSize=8;
title('Equiv. Strain (×10⁻³)','Color','w','FontSize',11,'FontWeight','bold');
axis equal tight; xlabel('x (m)','Color','w');

sgtitle(sprintf('F1 Retractable Barrier FEA  |  Load: %.0f kN  |  Material: Steel', ...
    F_total/1e3), 'Color','w','FontSize',12,'FontWeight','bold');

%% ── PRINT SUMMARY ────────────────────────────────────────
fprintf('\n============================================\n');
fprintf('   FEA RESULTS SUMMARY                      \n');
fprintf('============================================\n');
fprintf('Mesh            : %d × %d Q4 elements\n', nx, ny);
fprintf('Total nodes     : %d | DOFs: %d\n', nNodes, nDOF);
fprintf('Applied load    : %.1f kN (right edge)\n', F_total/1e3);
fprintf('--------------------------------------------\n');
fprintf('Max Von Mises   : %.2f MPa\n', max(sigma_vm)/1e6);
fprintf('Yield strength  : %.1f MPa\n', ty/1e6);
if max(sigma_vm) > ty
    fprintf('  ⚠  YIELDING DETECTED — barrier deforms plastically\n');
else
    fprintf('  ✓  Below yield — elastic deformation only\n');
end
fprintf('Max displacement: %.4f mm\n', max(disp_mag(:)));
fprintf('Max equiv strain: %.4f ×10⁻³\n', max(eps_vm)*1e3);
fprintf('============================================\n');