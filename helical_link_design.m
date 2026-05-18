function [dphi, phi_mid, b] = helical_link_design(L, r, qi, qf, l, E, sigma_max)
%HELICAL_LINK_DESIGN Compute bending range and required thickness
%
% Inputs:
%   L           - link length
%   r           - radius
%   qi, qf      - initial and final twist angles
%   l           - flexible length
%   E           - Young's modulus
%   sigma_max   - allowable stress
%
% Outputs:
%   dphi        - bending range (Delta phi)
%   phi_mid     - midpoint angle
%   b           - required thickness

    % Helical angles
    phi_i = atan( sqrt(L^2 - r^2*qi^2) / (r*qi) )
    phi_f = atan( sqrt(L^2 - r^2*qf^2) / (r*qf) )

    % Bending range
    dphi = phi_i - phi_f;

    % Mid configuration
    phi_mid = (phi_i + phi_f)/2;

    % Thickness from PRBM
    b = l * (4*sigma_max) / (E*dphi);

end
