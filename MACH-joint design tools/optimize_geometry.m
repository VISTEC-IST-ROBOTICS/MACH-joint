function [x_opt, fval] = optimize_geometry(r_0, Tz)
%OPTIMIZE_GEOMETRY Optimization using fmincon
% Decision variables: x = [L, r, theta]

    % Initial guess
 
    x0 = [pi*r_0, r_0, 1.5];

    % Bounds [L, r, theta]
    lb = [pi*r_0/10, r_0, pi/4];
    ub = [pi*r_0*10, r_0, pi];

    % Objective function
    fun = @(x) objective_fun(x);

    % Nonlinear constraint
    nonlcon = @(x) constraint_fun(x,Tz);

    % Options
    opts = optimoptions('fmincon', ...
        'Display','iter', ...
        'PlotFcn', {@optimplotfval});

    % Run optimization
    [x_opt, fval] = fmincon(fun, x0, [], [], [], [], lb, ub, nonlcon, opts);

end


%% Objective function
function J = objective_fun(x)
    L = x(1);
    r = x(2);
    th = x(3);

    th2 = th - 1.7;

    term1 = sqrt(L^2 - r^2* th^2);
    term2 = sqrt(L^2 - r^2* th2^2);

    J = (term1 - term2) / (th - th2);
end


%% Nonlinear constraint

function [c, ceq] = constraint_fun(x, Tz)
    L = x(1);
    r = x(2);
    th = x(3);

    % No inequality constraint
    c = [];

    % Equality constraint: sqrt(L^2 - r^2*th^2) = Tz
    ceq = sqrt(L^2 - r^2*th^2) - Tz;
end

