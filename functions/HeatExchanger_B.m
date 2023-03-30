function [state2,results] = HeatExchanger_B(state1,params)
% Computes the thermodynamic variables after a heat exchanger knowing the 
% delta T and the p_ratio due to losses in the line

% input params
p_ratio = params(1);
deltaT = params(2); % K

% mass conservation
state2.mdot = state1.mdot; % kg/s

% frozen flow
state2.composition = state1.composition;

% exit temperature
state2.T = state1.T + deltaT; % K

% pure substance
if length(state1.composition.species) == 1
    % exit pressure
    state2.p = state1.p/p_ratio;
    
    % consider parahydrogen if temperature is low enough
    if state1.composition.species == "H2" && state1.T > 14 && state1.T < 400  
        h1 = NFP("pH2",'h_pt',state1.p,state1.T); % kJ/kg
    else
        h1 = NFP(state1.composition.species,'h_pt',state1.p,state1.T); % kJ/kg
    end
    
    % consider parahydrogen if temperature is low enough
    if state2.composition.species == "H2" && state2.T > 14 && state2.T < 400  
        h2 = NFP("pH2",'h_pt',state2.p,state2.T); % kJ/kg
    else
        h2 = NFP(state2.composition.species,'h_pt',state2.p,state2.T); % kJ/kg
    end
    
    % density
    state2.rho = NFP(state2.composition.species,'r_pt',state2.p,state2.T);
    
    % heat exchanged
    results.Qdot = (h2 - h1)*state1.mdot/1e+6; 
    
% mixture (only for gases)   
else
    % molar mass
    MM = HGSprop(cellstr(state1.composition.species),state1.composition.n,state1.T,state1.p,'Mm');
    % exit pressure
    state2.p = state1.p/p_ratio;
    
    % enthalpies
    h1 = HGSprop(cellstr(state1.composition.species),state1.composition.n,state1.T,state1.p,'H')/MM * 1000; % kJ/kg
    h2 = HGSprop(cellstr(state2.composition.species),state2.composition.n,state2.T,state2.p,'H')/MM * 1000; % kJ/kg
    
    % gas constant
    Rg = HGSprop(cellstr(state2.composition.species),state2.composition.n,state2.T,state2.p,'Rg')*1000;
    
    % density
    state2.rho = state2.p*1e+5/(state2.T*Rg);
    
    % heat exchanged   
    results.Qdot = (h2-h1) * state1.mdot/1e+6;
    
end
end