function [state2,results] = HeatExchanger_A(state1,params)
% Computes the thermodynamic variables after a heat exchanger knowing the 
% exchanged heat and the p_ratio due to losses in the line

% input params
p_ratio = params(1);
Qdot = params(2); % MW

% mass conservation
state2.mdot = state1.mdot; % kg/s

% frozen flow
state2.composition = state1.composition;

% pure substance
if length(state1.composition.species) == 1
    % consider parahydrogen if temperature is low enough
    if state1.composition.species == "H2" && state1.T > 14 && state1.T < 400  
        h1 = NFP("pH2",'h_pt',state1.p,state1.T); % kJ/kg
    else
        h1 = NFP(state1.composition.species,'h_pt',state1.p,state1.T); % kJ/kg
    end
    
    % outlet enthalpy
    h2 = Qdot*1000/state2.mdot + h1; % kJ/kg
    
    % exit pressure
    state2.p = state1.p/p_ratio; % bar
    
    % consider parahydrogen if the temperature is low enough
    try
        if state1.composition.species == "H2" && state1.T > 14 && state1.T < 400
            state2.T = NFP("pH2",'t_hp',h2,state2.p); % K
            state2.rho = NFP("pH2",'r_pt',state2.p,state2.T); % kg/m^3
        else
            state2.T = NFP(state2.composition.species,'t_hp',h2,state2.p); % K
            state2.rho = NFP(state2.composition.species,'r_pt',state2.p,state2.T); % kg/m^3
        end
    catch ME
        if ME.message(length('uhh? T=1.000000e+03 ')+1:length('uhh? T=1.000000e+03 ')+length('out of range')) == "out of range"
            state2.T = NFP(state2.composition.species,'t_hp',h2,state2.p); % K
            state2.rho = NFP(state2.composition.species,'r_pt',state2.p,state2.T); % kg/m^3
        else
            error(ME.message)
        end
    end
    
% mixture (only for gases)
else
    % equivalent molar mass 
    MM_eq = HGSprop(cellstr(state1.composition.species),state1.composition.n,state1.T,state1.p,'Mm')/1000; % g/mol -> kg/mol
    
    % exit pressure
    state2.p = state1.p/p_ratio; % bar
    
    % enthalpies
    h1 = HGSprop(cellstr(state1.composition.species),state1.composition.n,state1.T,state1.p,'H')/MM_eq; % kJ/kg   
    h2 = Qdot*1000/state2.mdot + h1; % kJ/kg   
    
    % exit temperature 
    state2.T = fzero(@(T) h2 - HGSprop(cellstr(state2.composition.species),state2.composition.n,T,state2.p,'H')/MM_eq,state1.T); % K
    
    % gas constant
    Rg = HGSprop(cellstr(state2.composition.species),state2.composition.n,state2.T,state2.p,'Rg')*1000; % kJ/kgK -> J/kgK
    
    % density
    state2.rho = state2.p*1e+5/(state2.T*Rg); % kg/m^3
end

% default empty output
results = [];
end