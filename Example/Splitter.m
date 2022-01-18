function  [state_exit,results] = Splitter(state1,nExit,params)
% state2 and state3 should be defined here
state3 = state1;
state2 = state1;
results = [];

%% choose which state to output

if nExit == 1
    state_exit = state2;
elseif nExit == 2
    state_exit = state3;
else
    error('splitter has only 2 exits')
end

end