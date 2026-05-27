clc; clear; close all;

% ===== Structural Constants =====
s_lamda = 1; 
L_0 = s_lamda*35.97; % Nominal length of the helical link
r = s_lamda*11;      % Radius of the helix profile
k_link = s_lamda*5 ; % Axial stiffness of the link (EI/L^3)

% ===== Twisting Constants (Material & Geometry) =====
E_mod    = 2300;     % MPa (N/mm^2)
b        = 1.97;     % mm
I_area   = (b^4)/12; % mm^4
phi_init = 0.69;     % rad
q_init   = (L_0 / r) * cos(phi_init);

% ===== Create UI =====
fig = uifigure('Name','MACH-joint Full Energy Breakdown','Position',[100 100 1000 900]);
uilabel(fig, ...
    'Text','MACH-joint simulator', ...
    'Position',[250 860 500 30], ...
    'FontSize',20, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','center');

% ===== Axes Setup (Symmetrical 3x2 Grid) =====
axBar     = uiaxes(fig,'Position',[20 660 430 190]);  % Elongation (Top Left)
axPhi     = uiaxes(fig,'Position',[20 460 430 190]);  % Pitch Angle (Middle Left)
axSide    = uiaxes(fig,'Position',[50 150 430 280]);  % Side View (Bottom Left)

axEnergyB = uiaxes(fig,'Position',[500 660 430 190]); % Strain Energy (Top Right)
axEnergyT = uiaxes(fig,'Position',[500 460 430 190]); % Twisting Energy (Middle Right)
axIso     = uiaxes(fig,'Position',[500 170 430 230]); % 3D View (Bottom Right)

axesList = [axBar axPhi axSide axIso axEnergyB axEnergyT];
for ax = axesList
    grid(ax,'on'); hold(ax,'on');
end

% Labels and Titles
title(axSide,'Side (y-z)');
title(axIso,'3D View');
title(axBar,'Elongation of each helical link');
title(axPhi,'Pitch Angle (\phi) per link');
title(axEnergyB,'Strain Energy (V_b) per Link');
title(axEnergyT,'Twisting Energy (V_{tw}) per Link');

xlabel(axSide,'y'); ylabel(axSide,'z');
xlabel(axIso,'x'); ylabel(axIso,'y'); zlabel(axIso,'z');
ylabel(axBar,'\epsilon [mm]');
ylabel(axPhi,'\phi [rad]');
ylabel(axEnergyB,'V_b [mJ]');
ylabel(axEnergyT,'V_{tw} [mJ]');

% Axis Limits & Properties
xlim(axSide,[-20*s_lamda 20*s_lamda]); ylim(axSide,[0 s_lamda*40]);
xlim(axIso,[-20*s_lamda 20*s_lamda]); ylim(axIso,[-20*s_lamda 20*s_lamda]); zlim(axIso,[0 40*s_lamda]);
axis(axSide,'manual'); axis(axIso,'manual');
daspect(axSide,[1 1 1]); daspect(axIso,[1 1 1]);
axis(axSide,'vis3d'); axis(axIso,'vis3d');

view(axSide,0,90);
view(axIso,65,15);
camproj(axIso,'orthographic');

% Colorbar Setup
colormap(axIso, turbo(256));
caxis(axIso, [0 4*s_lamda]);

%cb = colorbar(axIso);
%cb.Label.String = '|\epsilon_b|';
%cb.Position = [0.92 0.2 0.02 0.4];
%cb.FontSize = 9;

% ===== Initialize Graphics Handles =====
h = struct(); 
h.label_q   = uilabel(fig,'Position',[50 115 300 20]);
h.label_qb  = uilabel(fig,'Position',[500 115 300 20]);
h.label_dTz = uilabel(fig,'Position',[500 55 300 20]);

% Interaction Force Dashboard (Gradient of Energy)
h.panel_force = uipanel(fig, 'Title', 'Interaction Forces / Moments (Energy Gradients)', ...
    'Position', [50 10 400 45], 'FontSize', 12, 'FontWeight', 'bold');
h.val_Fz  = uilabel(h.panel_force, 'Position', [10 5 120 20], 'Text', 'P: 0.00 N');
h.val_Mb  = uilabel(h.panel_force, 'Position', [130 5 120 20], 'Text', 'M_b: 0.00 N.m');
h.val_Tq  = uilabel(h.panel_force, 'Position', [270 5 200 20], 'Text', 'Tau_q: 0.00 N.m');

% Pre-allocate lines for plotting
h.linesSide = gobjects(1,4);
h.linesIso  = gobjects(1,4);
for k=1:4
    h.linesSide(k) = plot(axSide, NaN, NaN, 'LineWidth', 1.5);
    h.linesIso(k)  = plot3(axIso, NaN, NaN, NaN, 'LineWidth', 1.5);
end
h.centerSide = plot(axSide, NaN, NaN, 'b', 'LineWidth', 2);
h.centerIso  = plot3(axIso, NaN, NaN, NaN, 'b', 'LineWidth', 2);

% Pre-allocate bars
h.barStrain  = bar(axBar, zeros(1,4), 'FaceColor', 'flat', 'EdgeColor', 'k');
h.barPhi     = bar(axPhi, zeros(1,4), 'FaceColor', 'flat', 'EdgeColor', 'k');
h.barEnergyB = bar(axEnergyB, zeros(1,4), 'FaceColor', 'flat', 'EdgeColor', 'k');
h.barEnergyT = bar(axEnergyT, zeros(1,4), 'FaceColor', 'flat', 'EdgeColor', 'k');

% Pre-allocate text objects for numbers on bars
h.textStrain  = gobjects(1,4);
h.textPhi     = gobjects(1,4);
h.textEnergyB = gobjects(1,4);
h.textEnergyT = gobjects(1,4);
for k=1:4
    h.textStrain(k)  = text(axBar, k, 0, '0.00', 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    h.textPhi(k)     = text(axPhi, k, 0, '0.00', 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    h.textEnergyB(k) = text(axEnergyB, k, 0, '0.00', 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    h.textEnergyT(k) = text(axEnergyT, k, 0, '0.00', 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
end

h.ylineEB = yline(axEnergyB, 0, '--r', 'Sum = 0.000 mJ', 'LineWidth', 1.5, 'LabelHorizontalAlignment','left');
h.ylineET = yline(axEnergyT, 0, '--r', 'Sum = 0.000 mJ', 'LineWidth', 1.5, 'LabelHorizontalAlignment','left');

% Axis scaling and ticks for bar charts
ylim(axBar, [-8*s_lamda 8*s_lamda]); 
xticks(axBar, 1:4); xticklabels(axBar, {'0','\pi/2','-\pi/2','\pi'});

ylim(axPhi, [0 1.5]); 
xticks(axPhi, 1:4); xticklabels(axPhi, {'0','\pi/2','-\pi/2','\pi'});

ylim(axEnergyB, [0 s_lamda*110]); 
xticks(axEnergyB, 1:4); xticklabels(axEnergyB, {'0','\pi/2','-\pi/2','\pi'});

ylim(axEnergyT, [0 s_lamda*110]); % Adjusted max range to match typical twist energies better
xticks(axEnergyT, 1:4); xticklabels(axEnergyT, {'0','\pi/2','-\pi/2','\pi'});

h.cmap = turbo(256);
h.cmax = 4;

% ===== Sliders =====
slider_q   = uislider(fig,'Position',[50 100 400 3],'Limits',[pi/2 3],'Value',0.8*pi);
slider_qb  = uislider(fig,'Position',[500 100 400 3],'Limits',[0.0001 1.0],'Value',0.0004);
slider_dTz = uislider(fig,'Position',[500 40 400 3],'Limits',[-5 5],'Value',0);

% ===== Callbacks =====
updateParams = @(q, qb, dtz) updatePlot(q, qb, dtz, h, L_0, r, k_link, E_mod, I_area, phi_init);
slider_q.ValueChangingFcn   = @(s,e) updateParams(e.Value, slider_qb.Value, slider_dTz.Value);
slider_qb.ValueChangingFcn  = @(s,e) updateParams(slider_q.Value, e.Value, slider_dTz.Value);
slider_dTz.ValueChangingFcn = @(s,e) updateParams(slider_q.Value, slider_qb.Value, e.Value);

% Initial Draw
updatePlot(slider_q.Value, slider_qb.Value, slider_dTz.Value, h, L_0, r, k_link, E_mod, I_area, phi_init);

% =======================================================================
function updatePlot(q_f, q_b, dT_z, h, L_0, r, k_link, E_mod, I_area, phi_init)
    q_b = max(q_b, 1e-5);
    
    h.label_q.Text   = sprintf('q = %.2f', q_f);
    h.label_qb.Text  = sprintf('q_b = %.4f', q_b);
    h.label_dTz.Text = sprintf('elongation z = %.4f', dT_z);
    
    u = linspace(0, q_f, 100); 
    v = linspace(0, q_b, 100); 
    T_z = sqrt(max(L_0^2 - r^2*q_f^2, 0)); 
    R = max((T_z + dT_z) / q_b, 1e-6);     
    shifts = [0, pi/2, -pi/2, pi];
    
    epsilon_b  = zeros(1,4); 
    phi_curr   = zeros(1,4); 
    linkColors = zeros(4,3);
    
    % ===== Geometric Position, Elongation & Phi Updates =====
    for k = 1:4
        shift = shifts(k);
        Sx = r*cos(u+shift);
        Sy = R*cos(v)-R + r*sin(u+shift).*cos(v);
        Sz = R*sin(v)   + r*sin(u+shift).*sin(v);
        
        dSx = gradient(Sx,u);
        dSy = gradient(Sy,u);
        dSz = gradient(Sz,u);
        L_b = trapz(u, sqrt(dSx.^2+dSy.^2+dSz.^2)); 
        
        epsilon_b(k) = (L_b-L_0); 
        
        % Local pitch angle per link
        phi_curr(k) = atan(sqrt(max(0, L_b^2 - (r*q_f)^2)) / (r*q_f));
        
        colorIdx = max(1, min(256, round((abs(epsilon_b(k))/h.cmax)*255) + 1));
        c = h.cmap(colorIdx, :);
        linkColors(k,:) = c;
        
        set(h.linesSide(k), 'XData', Sy, 'YData', Sz, 'Color', c);
        set(h.linesIso(k), 'XData', Sx, 'YData', Sy, 'ZData', Sz, 'Color', c);
    end
    
    set(h.centerSide, 'XData', R*cos(v)-R, 'YData', R*sin(v));
    set(h.centerIso, 'XData', zeros(size(v)), 'YData', R*cos(v)-R, 'ZData', R*sin(v));
    
    % ===== Interaction Forces (Energy Gradients) =====
    delta = 0.0005; 
    
    U_plus_qb  = computeTotalEnergy(q_f, q_b + delta, dT_z, L_0, r, k_link, E_mod, I_area, phi_init);
    U_minus_qb = computeTotalEnergy(q_f, q_b - delta, dT_z, L_0, r, k_link, E_mod, I_area, phi_init);
    M_b = (U_plus_qb - U_minus_qb) / (2 * delta*1000);
    
    U_plus_dTz  = computeTotalEnergy(q_f, q_b, dT_z + delta, L_0, r, k_link, E_mod, I_area, phi_init);
    U_minus_dTz = computeTotalEnergy(q_f, q_b, dT_z - delta, L_0, r, k_link, E_mod, I_area, phi_init);
    F_z = (U_plus_dTz - U_minus_dTz) / (2 * delta);
    
    U_plus_qf  = computeTotalEnergy(q_f + delta, q_b, dT_z, L_0, r, k_link, E_mod, I_area, phi_init);
    U_minus_qf = computeTotalEnergy(q_f - delta, q_b, dT_z, L_0, r, k_link, E_mod, I_area, phi_init);
    Tau_q = (U_plus_qf - U_minus_qf) / (2 * delta*1000);
    
    h.val_Fz.Text  = sprintf('F_z: %+.3f N', F_z);
    h.val_Mb.Text  = sprintf('M_b: %+.3f N.m', M_b);
    h.val_Tq.Text  = sprintf('Tau_q: %+.3f N.m', Tau_q);
    
    % ===== Calculate Energies (U_b and U_tw) =====
    k_tw = (4.5 * E_mod * I_area) / L_0;
    dphi = phi_curr - phi_init;
    
    U_b  = 0.5 * k_link * (epsilon_b.^2); 
    U_tw = 0.5 * k_tw * (dphi.^2);
    
    % Update Charts
    set(h.barStrain, 'YData', epsilon_b, 'CData', linkColors);
    set(h.barPhi, 'YData', phi_curr, 'CData', linkColors);
    set(h.barEnergyB, 'YData', U_b, 'CData', linkColors);
    set(h.barEnergyT, 'YData', U_tw, 'CData', linkColors);
    
    set(h.ylineEB, 'Value', sum(U_b), 'Label', sprintf('Sum V_b = %.3f mJ', sum(U_b)));
    set(h.ylineET, 'Value', sum(U_tw), 'Label', sprintf('Sum V_{tw} = %.3f mJ', sum(U_tw)));
    
    % Update Text Markers
    for k = 1:4
        % Strain
        if epsilon_b(k) >= 0
            valign = 'bottom'; yOffset = 0.2; 
        else
            valign = 'top'; yOffset = -0.2; 
        end
        set(h.textStrain(k), 'Position', [k, epsilon_b(k) + yOffset, 0], ...
            'String', sprintf('%.2f', epsilon_b(k)), 'VerticalAlignment', valign);
        
        % Phi
        set(h.textPhi(k), 'Position', [k, phi_curr(k) + 0.05, 0], ...
            'String', sprintf('%.3f', phi_curr(k)), 'VerticalAlignment', 'bottom');
            
        % Strain Energy
        set(h.textEnergyB(k), 'Position', [k, U_b(k) + 0.5, 0], ...
            'String', sprintf('%.2f', U_b(k)), 'VerticalAlignment', 'bottom');
            
        % Twisting Energy
        set(h.textEnergyT(k), 'Position', [k, U_tw(k) + 0.2, 0], ...
            'String', sprintf('%.2f', U_tw(k)), 'VerticalAlignment', 'bottom');
    end
end

% =======================================================================
% Isolated Function to Fast-Compute System Energy for Gradient Calculation
function U_total_sys = computeTotalEnergy(q_f, q_b, dT_z, L_0, r, k_link, E_mod, I_area, phi_init)
    q_b = max(q_b, 1e-5);
    u = linspace(0, q_f, 20); 
    v = linspace(0, q_b, 20); 
    T_z = sqrt(max(L_0^2 - r^2*q_f^2, 0)); 
    R = max((T_z + dT_z) / q_b, 1e-6);     
    shifts = [0, pi/2, -pi/2, pi];
    
    U_total_sys = 0;
    k_tw = (4.5 * E_mod * I_area) / L_0;
    
    for k = 1:4
        shift = shifts(k);
        Sx = r*cos(u+shift);
        Sy = R*cos(v)-R + r*sin(u+shift).*cos(v);
        Sz = R*sin(v)   + r*sin(u+shift).*sin(v);
        
        dSx = gradient(Sx,u);
        dSy = gradient(Sy,u);
        dSz = gradient(Sz,u);
        L_b = trapz(u, sqrt(dSx.^2+dSy.^2+dSz.^2)); 
        
        % Link Bending Energy
        eps_b = (L_0 - L_b);
        U_b = 0.5 * k_link * (eps_b^2);
        
        % Link Twisting Energy
        phi_curr = atan(sqrt(max(0, L_b^2 - (r*q_f)^2)) / (r*q_f));
        dphi = phi_curr - phi_init;
        U_tw = 0.5 * k_tw * (dphi^2);
        
        % Sum to total system energy
        U_total_sys = U_total_sys + U_b + U_tw;
    end
end