function [state2,results] = DivergentNozzle_A(state1,params)
% Computes the thermodynamic variables after a divergent tube assuming
% M = 1 at the beginning, knowing the exchanged heat and the isentropic
% nozzle efficiency

% input parameters
Qdot = params(1); % MW
Aratio = params(2);
D_exit = params(3); % m
eta = params(4);

% exit area
A_exit = D_exit^2*pi/4;

% mass conservation
state2.mdot = state1.mdot; % kg/s

% frozen flow
state2.composition = state1.composition;

% state1 gas properties
gamma_1 = HGSprop(cellstr(state1.composition.species),state1.composition.n,state1.T,state1.p,'gamma');
MM = HGSprop(cellstr(state1.composition.species),state1.composition.n,state1.T,state1.p,'Mm')/1000;

% total temperature and pressure
T0 = state1.T*(gamma_1+1)/2;
p0 = state1.p*((gamma_1+1)/2)^(gamma_1/(gamma_1-1));

% exit Mach
M_exit = fzero(@(M_out) Aratio - 1/M_out*(2/(gamma_1+1)*(1+(gamma_1-1)/2*M_out^2))^((gamma_1+1)/(2*(gamma_1-1))), [1.01,100]);

% isentropic variables
T2_iso = T0/(1+(gamma_1-1)/2*M_exit^2); % K
p2_iso = p0/(1+(gamma_1-1)/2*M_exit^2)^(gamma_1/(gamma_1-1)); % bar

% enthalpies
h1 = HGSprop(cellstr(state1.composition.species),state1.composition.n,state1.T,state1.p,'H')/MM;
h2_iso = HGSprop(cellstr(state2.composition.species),state2.composition.n,T2_iso,p2_iso,'H')/MM;

% exit enthalpy with efficiency
h2 = eta*(h2_iso-h1) + h1 + Qdot*1000/state2.mdot;

% outlet temperature
state2.T = fzero(@(T) h2 - HGSprop(cellstr(state2.composition.species),state2.composition.n,T,state1.p,'H')/MM,T2_iso);

% state1 gas properties
gamma_2 = HGSprop(cellstr(state2.composition.species),state2.composition.n,state2.T,p2_iso,'gamma');
Rg_2 = HGSprop(cellstr(state2.composition.species),state2.composition.n,state2.T,p2_iso,'Rg')*1000;

% other thermodynamic variables
a2 = sqrt(gamma_2*Rg_2*state2.T); % m/s
v2 = M_exit*a2; % m/s
state2.rho = state2.mdot/(A_exit*v2); % kg/m^3
state2.p = (state2.rho*Rg_2*state2.T)/1e+5; % bar

% exit Mach
results.M_exit = M_exit;

% sea level pressure
sl_pressure = 101325;% bar

% performance
results.F_vac = (state2.mdot*v2 + state2.p*1e+5*A_exit)/1000; % N -> kN
results.F_sl = (state2.mdot*v2 + (state2.p*1e+5 - sl_pressure)*A_exit)/1000; % N -> kN
results.Isp_vac = results.F_vac*1000/(state2.mdot * 9.81); % s
results.Isp_sl = results.F_sl*1000/(state2.mdot * 9.81); % s

end




