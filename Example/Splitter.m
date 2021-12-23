function  [state_out,results] = Splitter(state1,nExit,params)

name = "Splitter";
% Check that everything is fine
if ~isstruct(state1)
    error('state1 is not a struct, check the number of input and output for the %s',name)
end

if ~isscalar(nExit)
    error('nExit is not a scalar, check the number of input and output for the %s',name)
end

if ~isnumeric(params)
    error('params is not a vector, check the number of input and output for the %s',name)
end

%% Function starts here
% state2 and state3 should be defined here
state3 = state1;
state2 = state1;
results = [];

%% choose which state to output

if nExit == 1
    state_out = state2;
elseif nExit == 2
    state_out = state3;
else
    error('splitter has only 2 exits')
end

end