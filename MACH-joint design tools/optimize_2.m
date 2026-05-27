clc;
clear all
% fixed parameters ===================
scale = 1.5
r = 11*scale
Tz = 10*scale
OD_base = 48;
z_o = 10.5

w =1
dtheta = 1.7
E = 2300*10^6;        % Pa
sigma_max =79*10^6;
%=====================================

[x_opt, fval] = optimize_geometry(r,Tz);

%%
L_opt = x_opt(1)
l = L_opt/3
r  = x_opt(2)
qi = x_opt(3) - dtheta
qf= x_opt(3)

[dphi, phi_mid, b] = helical_link_design(L_opt, r, qi, qf, l, E, sigma_max);

%%

Tz_min = sqrt(L_opt^2 - r^2*qf^2)
Tz_max = sqrt(L_opt^2 - r^2*qi^2)
[h_t_opt, l_t_opt] = geom_parameter_opt(Tz_min, Tz_max, z_o,OD_base);


