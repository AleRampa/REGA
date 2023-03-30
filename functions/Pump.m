function [state2,results] = Pump(state1,params)
% Computes the thermodynamic variables after a pump assuming
% isentropic compression with efficiency and knowing the pressure ratio

% input parameters
p_ratio = params(1);
eta = params(2);

% mass conservation
state2.mdot = state1.mdot; % kg/s

% frozen flow
state2.composition = state1.composition;

% single substance
if length(state1.composition.species) == 1
    
    % consider parahydrogen if the temperature is low enough
    if state1.composition.species == "H2" && state1.T > 14 && state1.T < 400
        h1 = NFP("pH2",'h_pt',state1.p,state1.T); % kJ/kg
        s1 = NFP("pH2",'s_pt',state1.p,state1.T); % kJ/kgK
    else
        h1 = NFP(state1.composition.species,'h_pt',state1.p,state1.T); % kJ/kg
        s1 = NFP(state1.composition.species,'s_pt',state1.p,state1.T); % kJ/kgK
    end
    
    % outlet pressure
    state2.p = state1.p * p_ratio; % bar
    
    % isentropic transformation
    s2 = s1; % kJ/kgK
    
    % consider parahydrogen if the temperature is low enough
    try
        if state1.composition.species == "H2" && state1.T > 14 && state1.T < 400
            % isentropic variables
            T2_iso = NFP("pH2",'t_ps',state2.p,s2); % K
            h2_iso = NFP("pH2",'h_pt',state2.p,T2_iso); % kJ/kg
            % outlet enthalpy
            h2 = (h2_iso - h1)/eta + h1; % kJ/kg
            % outlet temperature
            state2.T = NFP("pH2",'t_hp',h2,state2.p); % K
            % density
            state2.rho = NFP("pH2",'r_pt',state2.p,state2.T); % kg/m^3
        else
            T2_iso = NFP(state2.composition.species,'t_ps',state2.p,s2); % K
            h2_iso = NFP(state2.composition.species,'h_pt',state2.p,T2_iso); % kJ/kg
            h2 = (h2_iso - h1)/eta + h1; % kJ/kg
            state2.T = NFP(state2.composition.species,'t_hp',h2,state2.p); % K
            state2.rho = NFP(state2.composition.species,'r_pt',state2.p,state2.T); % kg/m^3
        end
    catch ME
        if ME.message(length('uhh? T=1.000000e+03 ')+1:length('uhh? T=1.000000e+03 ')+length('out of range')) == "out of range"
            T2_iso = NFP(state2.composition.species,'t_ps',state2.p,s2); % K
            h2_iso = NFP(state2.composition.species,'h_pt',state2.p,T2_iso); % kJ/kg
            h2 = (h2_iso - h1)/eta + h1; % kJ/kg
            state2.T = NFP(state2.composition.species,'t_hp',h2,state2.p); % K
            state2.rho = NFP(state2.composition.species,'r_pt',state2.p,state2.T); % kg/m^3
        else
            error(ME.message)
        end
    end
% mixture (not implemented yet)
else
    error("Pump is implemented for pure substance and input is a mixture")    
end


% output power
results.power = abs((h2 - h1)*state2.mdot)/1000;   % MW


end

