function [state2,results] = Valve(state1,params)

name = "Valve";
% Check that everything is fine
if ~isstruct(state1)
    error('state1 is not a struct, check the number of input and output for the %s',name)
end

if ~isnumeric(params)
    error('params is not a vector, check the number of input and output for the %s',name)
end

%% Function starts here
state2 = state1;
results = [];

end
