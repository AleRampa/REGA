function [state3,results] = CombustionChamber(state1,state2,params)

name = "CombustionChamber";
% Check that everything is fine
if ~isstruct(state1)
    error('state1 is not a struct, check the number of input and output for the %s',name)
end

if ~isstruct(state2)
    error('state2 is not a struct, check the number of input and output for the %s',name)
end

if ~isnumeric(params)
    error('params is not a vector, check the number of input and output for the %s',name)
end

%% Function starts here
state3 = state1;
results = [];
end

