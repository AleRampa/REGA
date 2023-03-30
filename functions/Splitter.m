function [state_out,results] = Splitter(state1,nExit,params)
% Computes the thermodynamic variables after a splitter knowing the 
% mass splitter ratio

% input params
mdot_ratio = params(1); % kg/s

% same thermodynamic variables as input except for the mass flow rate
state_out = state1; 

% choose exit
if nExit == 1   
    % first exit
    state_out.mdot = state1.mdot * mdot_ratio/(1+mdot_ratio); % kg/s
elseif nExit == 2
    % second exit
    state_out.mdot = state1.mdot * 1/(1+mdot_ratio); % kg/s
else
    error('splitter has only 2 exits')
end

% default empty output
results = [];
end