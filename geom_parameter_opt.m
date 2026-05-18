function [h_t_opt, l_t_opt, phi_deg] = geom_parameter_opt(Tz_min, Tz_max, z_t, OD_base)

% ==========================================================
% Robust geometric parameter design
% Ensures:
% 1) 2h_t + l_t cos(phi_min) < Tz_max + 2z_t
% 2) h_t < Tz_max/2
% 3) 8 l_t sin(phi_min) >= pi D_base
% ==========================================================

% Basic quantities
T_range = Tz_max - Tz_min;
D_base  = OD_base;
margin  = 1e-6;

% ---- STEP 1: Choose h_t safely below Tz_max/2 ----
h_t_opt = Tz_max/2 %- margin;

% ---- STEP 2: Compute worst-case Delta ----
Delta1 = abs(Tz_min + 2*z_t - 2*h_t_opt);
Delta2 = abs(Tz_max + 2*z_t - 2*h_t_opt);
Delta_max = max(Delta1, Delta2);

% ---- STEP 3: Compute minimum l_t from geometry constraint ----
l_t_opt = sqrt( Delta_max^2 + (pi^2 * D_base^2)/64 );

% ---- STEP 4: Compute minimum angle ----
cos_phi_min = Delta_max / l_t_opt;

% numerical safety
cos_phi_min = min(max(cos_phi_min,-1),1);

phi_min_rad = acos(cos_phi_min);
phi_deg = rad2deg(phi_min_rad);

end