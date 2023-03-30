function [state2,results] = ConvergentNozzle_A(state1,params)
% Computes the thermodynamic variables after a convergent tube assuming
% M = 1 at the end, knowing the exchanged heat and the isentropic nozzle
% efficiency

% input parameters
Qdot = params(1); % MW
D_throat = params(2); % m
eta = params(3);

% exit area
A_throat = D_throat^2*pi/4; % m^2

% mass conservation
state2.mdot = state1.mdot; % kg/s

% frozen flow
state2.composition = state1.composition;

% total temperature
T0 = state1.T; % K

% state1 gas properties
gamma_1 = HGSprop(cellstr(state1.composition.species),state1.composition.n,state1.T,state1.p,'gamma');
MM = HGSprop(cellstr(state1.composition.species),state1.composition.n,state1.T,state1.p,'Mm')/1000; % g/mol -> kg/mol

% isentropic variables
T2_iso = 2*T0/(gamma_1+1); % K 
p2_iso = state1.p*((gamma_1+1)/2)^(gamma_1/(gamma_1-1)); % bar

% enthalpies
h1 = HGSprop(cellstr(state1.composition.species),state1.composition.n,state1.T,state1.p,'H')/MM; % kJ/mol -> kJ/kg
h2_iso = HGSprop(cellstr(state1.composition.species),state1.composition.n,T2_iso,p2_iso,'H')/MM; % kJ/mol -> kJ/kg

% exit enthalpy with efficiency
h2 = eta*(h2_iso-h1) + h1 + Qdot*1000/state2.mdot; % kJ/kg

% outlet temperature
state2.T = fzero(@(T) h2 - HGSprop(cellstr(state2.composition.species),state2.composition.n,T,p2_iso,'H')/MM,T2_iso); % K

% state2 gas properties
gamma_2 = HGSprop(cellstr(state2.composition.species),state2.composition.n,state2.T,p2_iso,'gamma');
Rg_2 = HGSprop(cellstr(state2.composition.species),state2.composition.n,state2.T,p2_iso,'Rg')*1000; % kJ/kgK -> J/kgK

% other thermodynamic variables
a2 = sqrt(gamma_2*Rg_2*state2.T); % m/s
v2 = a2; % m/s
state2.rho = state2.mdot/(A_throat*v2); % kg/m^3
state2.p = (state2.rho*Rg_2*state2.T)/1e+5; % bar

% default empty output
results = [];

end




