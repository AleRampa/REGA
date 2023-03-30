function [state2,results] = Turbine(state1,params)
% Computes the thermodynamic variables after a turbine assuming
% isentropic expansion with efficiency and knowing the pressure ratio

% input parameters
p_ratio = params(1);
eta = params(2);

% mass conservation
state2.mdot = state1.mdot;

% frozen flow
state2.composition = state1.composition;

% pure substance
if length(state1.composition.species) == 1
    
    % parahydrogen is not considered since the turbine should run hot
    % inlet enthalpy
    h1 = NFP(state1.composition.species,'h_pt',state1.p,state1.T); % kJ/kg
    
    % inlet entropy
    s1 = NFP(state1.composition.species,'s_pt',state1.p,state1.T); % kJ/kgK   
    
    % exit pressure
    state2.p = state1.p / p_ratio; % bar
    
    % isentropic transformation
    s2 = s1; % kJ/kgK 
    
    % isentropic temperature
    T2_iso = NFP(state1.composition.species,'t_ps',state2.p,s2); % K
    
    % isentropic enthalpy
    h2_iso = NFP(state1.composition.species,'h_pt',state2.p,T2_iso); % kJ/kg
    
    % real deltah and outlet enthalpy 
    deltah = (h2_iso - h1) * eta; % kJ/kg
    h2 = deltah + h1; % kJ/kg
    
    % outlet temperature
    state2.T = NFP(state1.composition.species,'t_hp',h2,state2.p); % K
    
    % density
    state2.rho = NFP(state1.composition.species,'r_pt',state2.p,state2.T); % kg/m^3

% mixture (only for gases)
else  
    % equivalent molar mass
    MM_eq = HGSprop(cellstr(state1.composition.species),state1.composition.n,state1.T,state1.p,'Mm')/1000; % kg/mol
    
    % inlet enthalpy     
    h1 = HGSprop(cellstr(state1.composition.species),state1.composition.n,state1.T,state1.p,'H')/MM_eq; % kJ/kg
    
    % inlet entropy
    s1 = HGSprop(cellstr(state1.composition.species),state1.composition.n,state1.T,state1.p,'S')/MM_eq; % kJ/kgK
    % pressione e temperatura input.
    
    % outlet pressure
    state2.p = state1.p / p_ratio; % bar
    
    % isentropic transformation
    s2 = s1; % kJ/kgK
    
    % isentropic temperature
    T2_iso = fzero(@(T) s2 - HGSprop(cellstr(state2.composition.species),state2.composition.n,T,state2.p,'S')/MM_eq,state1.T); % K
    
    % isentropic enthalpy
    h2_iso = HGSprop(cellstr(state1.composition.species),state2.composition.n,T2_iso,state2.p,'H')/MM_eq; % kJ/kgK
    
    % real deltah and outlet enthalpy 
    deltah = (h2_iso - h1) * eta; % kJ/kg
    h2 = deltah + h1; % kJ/kg
    
    % outlet temperature
    state2.T = fzero(@(T) h2 - HGSprop(cellstr(state2.composition.species),state2.composition.n,T,state2.p,'H')/MM_eq,T2_iso); % K
       
    % gas constant
    Rg = HGSprop(cellstr(state2.composition.species),state2.composition.n,state2.T,state2.p,'Rg')*1000; % J/kgK
    
    % density
    state2.rho = state2.p*1e+5/(state2.T*Rg); % kg/m^3
    
end

% output power
results.power = abs((h2-h1)*state2.mdot)/1000; % MW
end
