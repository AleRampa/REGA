function [state2,results] = Valve(state1,params)
% Computes the thermodynamic variables after a valve knowing the pressure
% ratio

% input params
p_ratio = params(1);

% mass conservation
state2.mdot = state1.mdot;

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
    
    % exit enthalpy
    h2 = h1; % kJ/kg
    
    % exit pressure
    state2.p = state1.p / p_ratio; % bar
    
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
    MM_eq = HGSprop(cellstr(state1.composition.species),state1.composition.n,300,1,'Mm')/1000; % kg/mol
        
    % exit pressure
    state2.p = state1.p / p_ratio;
    
    % initialize a function which has to be 0 for the output temperature
    hasToBeZero = @(T) 0; % kJ
    
    % temperatures limits
    TMax = max(999,state1.T+10);
    TMin = min(373.15,state1.T);
    
    for i = 1 : length(state1.composition.species)
        % try with NFP, if NFP does not implement the substance than switch to
        % HGS
        try
            %dummy
            NFP(state1.composition.species(i),'h_pt',state1.p,TMax);

            MM = HGSsingle(char(state1.composition.species(i)),'Mm',300,1)/1000; % kg/mol
            hasToBeZero = @(T) hasToBeZero(T) + ...
                (NFP(state1.composition.species(i),'h_pt',state2.p,T) - ...
                NFP(state1.composition.species(i),'h_pt',state1.p,state1.T)) * ...
                state1.mdot * state1.composition.n(i) * MM/MM_eq; % kJ
        catch ME
            if ME.message(end-length('not found')+1:end) == "not found" ||...
                    ME.message(length('uhh? T=1.000000e+03 ')+1:length('uhh? T=1.000000e+03 ')+length('out of range')) == "out of range"
                
                hasToBeZero = @(T) hasToBeZero(T) +...
                    (HGSsingle(char(state1.composition.species(i)),'h',T,state2.p) - ...
                    HGSsingle(char(state1.composition.species(i)),'h',state1.T,state1.p)) * ...
                    state1.mdot * state1.composition.n(i)/MM_eq; % kJ
            else
                error(ME.message)
            end
        end
    end
    
    % output temperature
    state2.T = fzero(@(T) hasToBeZero(T),[TMin,TMax]); % K
    
    % gas constant
    Rg = HGSprop(cellstr(state2.composition.species),state2.composition.n,state2.T,state2.p,'Rg')*1000;
    
    % density
    state2.rho = state2.p*1e+5/(state2.T*Rg);
    
end

% default empty output
results = [];
end
