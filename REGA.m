%% - REGA v1.1
% Rocket Engine Graph Analyzer (REGA)
% © Alessandro Rampazzo
% ESEIAAT - UPC - 2021/2022
%
% REGA takes a graph of a rocket engine and traverses it calculating every
% state of the fluid using functions defined by the user
%
% [blocks,states,travelledBlocks] = REGA(gFileName,iFileName,compInfo,...)
%
% gFileName is the name of the .tgf file containing the graph of the rocket
% engine, iFileName is a .txt file of input data and parameters of the
% blocks (see README for more information) and compInfo is a cell nx3 (n be
% the number of types of blocks) where the first column contains the type
% given as a string (lowercase or uppercase it's the same), the nickname
% and the associated function given as a function handle using @. Input and
% output blocks' functions are not used so every value put in the third
% column is accepted:
%
%       compInfo = {...
%           "Tank","Tnk",0;
%           "Out","Out",0;
%           "Pump","Pmp",@Pump;
%           "Splitter","Spl",@Splitter;
%           "Valve","Vlv",@Valve;
%           "HeatExchanger","HeEx",@HeatExchanger;
%           "Turbine","Trb",@Turbine;
%       	"Nozzle","Nzl",@Nozzle;
%           "Mixer","Mix",@Mixer;
%           "CombustionChamber","CombC",@CombustionChamber};
%       iFileName = "InputData.txt";
%       gFileName = "graph.tgf";
%       REGA(gFileName,iFileName,compInfo);
%
% [blocks,states,travelledBlocks] = REGA(gFileName,iFileName,compInfo,...
%       'logtravellednodes',false,...) to disable the log of travelled nodes
%
% [blocks,states,travelledBlocks] = REGA(gFileName,iFileName,compInfo,...
%       'logstates',false,...) to disable the log of states
%
% [blocks,states,travelledBlocks] = REGA(gFileName,iFileName,compInfo,...
%       'logblocks',false,...) to disable the log of blocks


function [blocks,states,travelledBlocks] = REGA(gFileName,iFileName,compInfo,varargin)

% input errors
if nargin < 3
    error('not enough imput arguments')
elseif mod(nargin,2) == 0
    error('invalid log type')
end

% default logs
options.logtravellednodes = true;
options.logstates = true;
options.logblocks = true;

% extract options from varargin
for i = 1:2:length(varargin)
    if isa(varargin{i+1},'logical')
        options.(lower(varargin{i})) = varargin{i+1};
    else
        error("log must be a bool")
    end
end

% open files
graphFileID = fopen(gFileName,'r');
inputFileID = fopen(iFileName,'r');

%% load connections

conns = [];

% go to connection searching the character '#' in the graph file
line = fgetl(graphFileID);
while line > 0
    s = split(line);
    if s{1} == '#'
        break
    end
    line = fgetl(graphFileID);
end

line = fgetl(graphFileID);

while line > 0
    
    % get connection
    conn = reshape(double(string(split(line))),1,[]);
    
    % check for errors
    if length(conn) < 3
        error("A state has not be associated with a number or there "+...
            "is a dangling arrow in the graph")
    end
    
    % check if the connection number is valid
    checkConn(conns,conn)
    
    % conns is a (number_of _connections x 3) matrix with rows [startNode, endNode, stateID]
    conns(end+1,:) = conn;
    
    % get line
    line = fgetl(graphFileID);
end

% return to the beginning od the file
frewind(graphFileID)

%% load blocks

blocks = {};

line = fgetl(graphFileID);

while line > 0
    
    % split line
    s = split(line);
    
    % stop if the # is reached, end of block list
    if s{1} == '#'
        break
    end
    
    % check for errors in the graph file
    if length(s) == 2
        error("A block misses the component number")
    elseif length(s) == 1
        error("A block has not been named")
    end
    
    % bluid the block
    block.nodeID = double(string(s{1}));
    block.type = string(lower(s{2}));
    block.compN = double(string(s{3}));
    
    % check if component number is valid
    checkBlock(blocks,block)
    
    % find the input and outputs of the block
    block.nInput = getInputN(block.nodeID,conns);
    block.nOutput = getOutputN(block.nodeID,conns);
    
    % add the block to the list
    blocks{end+1} = block;
    
    checkInputOutput(block,blocks)
    
    % add parameters to the block
    % if it's an input block than state must be defined
    if block.nInput == 0
        blocks{end}.state = getData(inputFileID,compInfo,block);
        
        % if not add everything to the params vector
    elseif block.nOutput > 0
        params = getData(inputFileID,compInfo,block);
        if ~isempty(params)
            blocks{end}.params = params;
        end
    end
    
    % get the new line
    line = fgetl(graphFileID);
end

% close files
fclose(inputFileID);
fclose(graphFileID);

%% MAIN LOOP

%initializing states and stateID vectors
states = {};
statesID = [];

% initialize travelled block IDs array
travelledBlocks = [];

count = 1;

fprintf("Starting traversing the graph...\n\n")

if options.logtravellednodes
    fprintf("Travelled nodes:\n")
end

for i = 1:length(blocks)
    if blocks{i}.nInput == 0
        % current node
        cn = i;
        
        % starting node is a tank
        states{end+1} = blocks{cn}.state;
        [nn,sID] = findNextNode(blocks{cn}.nodeID,conns);
        statesID(end+1) = sID;
        
        % the number of exit to choose
        nExit = 1;
        
        % initialize the array of travelled splitters
        splitArray = [];
        done = false;
        while ~done
            
            if options.logtravellednodes
                % printing current node
                disp(count+": " + compInfo(lower(string(compInfo(:,1))) == blocks{cn}.type,2) + " " + blocks{cn}.compN)
            end
            
            count = count + 1;
            travelledBlocks(end+1) = blocks{cn}.nodeID;
            % current node = next node
            cn = nn;
            
            % define a flag that triggers the error of "block not
            % recognized", it is set to false if the block is found inside
            % the following for loop
            flag = true;
            
            % for every defined component
            for t = 1:size(compInfo,1)
                % if the type is in the component list
                if lower(compInfo{t,1}) == blocks{cn}.type
                    
                    % =====================================================
                    
                    if blocks{cn}.nInput == 0 || blocks{cn}.nOutput == 0
                        % it is a input or output block, if there are no
                        % splitter blocks left with untravelled exit put
                        % the flag to false and change tank exiting the
                        % while loop, else go to the last of those blocks.
                        if isempty(splitArray)
                            % change tank
                            done = true;
                            % block found
                            flag = false;
                            break;
                        else
                            % jump to last splitter block traversed with
                            % untravelled exits
                            nn = splitArray(end);
                            % the exit of the splitter block will be 2
                            nExit = 2;
                            % remove the splitter block to the array
                            splitArray = splitArray(1:end-1);
                        end
                        
                    % =====================================================
                    
                    elseif blocks{cn}.nInput == 1 && blocks{cn}.nOutput == 1
                        % component with one input and one output
                        %
                        % get the function handle of the component
                        f = compInfo{t,3};
                        % check if the function is valid
                        checkFunctionHandle(f,blocks{cn}.type)
                        
                        % do the calculation for this block
                        fields = fieldnames(blocks{cn});
                        if any(ismember(fields,'params'))
                            [states{end+1},results] = f(states{statesID == sID},blocks{cn}.params);
                        else
                            [states{end+1},results] = f(states{statesID == sID});
                        end
                        % add the results to the block
                        blocks{cn} = addResultsToBlock(blocks{cn},results);
                        
                        % find the next one
                        [nn,sID] = findNextNode(blocks{cn}.nodeID,conns);
                        % add to the statesID vector the traversed state
                        statesID(end+1) = sID;
                    
                    % =====================================================              
                    
                    elseif blocks{cn}.nInput > 1 && blocks{cn}.nOutput == 1
                        % component like mixers or combustion chambers with
                        % multiple input and one output
                        %                        
                        % get the function handle of the component
                        f = compInfo{t,3};
                        % check if the function is valid
                        checkFunctionHandle(f,blocks{cn}.type)
                        
                        % find both the input states
                        stInArr = findInputStates(cn,conns,blocks{cn}.nInput);                        
                        
                        % if they have been already calculated proceed,
                        % else return to the previous splitter block that
                        % has untravelled exits
                        if all(ismember(stInArr,statesID))
                            states_vec = states{statesID == stInArr(1)};
                            for j = 2:length(stInArr)
                                states_vec = [states_vec,states{statesID == stInArr(j)}];
                            end                            
                            if any(ismember(fields,'params'))
                                [states{end+1},results] = f(states_vec,...
                                    blocks{cn}.params);
                            else
                                [states{end+1},results] = f(states_vec);                               
                            end
                            % add the results to the block
                            blocks{cn} = addResultsToBlock(blocks{cn},results);
                            
                            [nn,sID] = findNextNode(blocks{cn}.nodeID,conns);
                            statesID(end+1) = sID;
                        else
                            if isempty(splitArray)
                                % change tank
                                done = true;
                                % block found
                                flag = false;
                                break;
                            else
                                % jump to last splitter block traversed with
                                % untravelled exits
                                nn = splitArray(end);
                                % the exit of the splitter block will be 2
                                nExit = 2;
                                % remove the splitter block to the array
                                splitArray = splitArray(1:end-1);
                            end
                        end
                        
                    % =====================================================
                        
                    elseif blocks{cn}.nInput == 1 && blocks{cn}.nOutput == 2
                        % block with 1 input and 2 outputs = splitter block
                        %
                        % get the function handle of the component
                        f = compInfo{t,3};
                        % check if the function is valid
                        checkFunctionHandle(f,blocks{cn}.type)
                        
                        % if the exit number is 1 then add the splitter
                        % block to the splitter list
                        if nExit == 1
                            splitArray = [splitArray,cn];
                        end
                        
                        % find the input state
                        stIn = findInputStates(cn,conns,1);
                        
                        % do all the calculation of the block
                        if any(ismember(fields,'params'))
                            [states{end+1},results] = f(states{statesID == stIn},nExit,blocks{cn}.params);
                        else
                            [states{end+1},results] = f(states{statesID == stIn},nExit);
                        end
                        % add the results to the block
                        blocks{cn} = addResultsToBlock(blocks{cn},results);
                        
                        [nn,sID] = findNextNode(blocks{cn}.nodeID,conns,nExit);
                        statesID(end+1) = sID;
                        
                        % set the next exit number to 1
                        nExit = 1;
                        
                    else
                        error("number of input-output of block %s not implemented yet",blocks{cn}.type)
                    end
                    
                    % block found
                    flag = false;
                    break
                end
            end
            
            if flag
                error("block type: ""%s"" not recognized", blocks{cn}.type)
            end
        end
    end
end

if ~exist('cn','var')
    error('no input blocks found')
end

if size(conns,1) ~= length(states)
    error("a problem arose while traversing the graph. Check for loops in "+...
        "the diagram and change them as suggested in the README.md file")
end

if options.logtravellednodes
    % display the last block
    disp(count+": " + compInfo(lower(string(compInfo(:,1))) == blocks{cn}.type,2) + " " + blocks{cn}.compN)
    fprintf("\n")
end

% sort the states based on their ID
[statesID,I] = sort(statesID);
states = states(I);

for i = 1:length(statesID)
    states{i}.ID = statesID(i);
end

if options.logstates
    % print states informations
    printStates(blocks,conns,statesID,states,compInfo)
end

if options.logblocks
    % print blocks informations
    printBlocks(blocks,compInfo)
end

% program finished
fprintf("Finished traversing the graph\n")







%% nested functions

% find the next node knowing the starting node and the exit number
% exit number is the state with the k-est minimum number.
% Example: node (a) goes to node (b) and (c) through state 7 and state 11
% respectively. Then:
%  - exit 1 = state 7 (to node b)
%  - exit 2 = state 11 (to node c)
% at the moment only two exits are implemented
    function [endNode,stateID] = findNextNode(startNode,conns,nExit)
        
        if ~exist("nExit","var")
            nExit = 1;
        end
        
        % number of exits
        n0 = 2;
        n = n0;
        
        eN = ones(1,n0)*1e+300;
        stID = ones(1,n0)*1e+300;
        
        for c = 1:length(conns)
            if startNode == conns(c,1) && n > 1
                eN(n0-n+1) = conns(c,2);
                stID(n0-n+1) = conns(c,3);
                n = n - 1;
            elseif startNode == conns(c,1)
                eN(n0-n+1) = conns(c,2);
                stID(n0-n+1) = conns(c,3);
                break;
            end
        end
        
        [~,ii] = mink(stID,nExit);
        endNode = eN(ii(end));
        stateID = stID(ii(end));
    end

% find both the input states to a node (at the moment only two inputs are
% implemented)
    function stInArr = findInputStates(node,conns,n0)
        % number of input
        n = n0;
        
        stInArr = ones(1,n0)*-1;
        for c = 1:length(conns)
            if node == conns(c,2) && n > 1
                stInArr(n0-n+1) = conns(c,3);
                n = n - 1;
            elseif node == conns(c,2)
                stInArr(n0-n+1) = conns(c,3);
                break;
            end
        end
        
        if all(stInArr(1) == -1)
            error('cannot find a node with this number')
        elseif any(stInArr(1) == -1)
            error("cannot find the input states of node %d,"+...
                "try checking the graph or the component definitions",...
                node)
        end
        
    end

% check if a block has the same type and component number as another one
    function checkBlock(blocks,block)
        for ii = 1:length(blocks)
            if blocks{ii}.type == block.type && blocks{ii}.compN == block.compN
                error("Node %d has the same type and component number as node %d"+...
                    ", change the component number of one of them to avoid this error",ii,length(blocks)+1)
            end
        end
    end

% check if a connection has the same number as another one
    function checkConn(conns,conn)
        for ii = 1:size(conns,1)
            if conns(ii,3) == conn(3)
                error("connection from node %d to node %d has the same number as the "+...
                    "connection from node %d to node %d, change the connection "+...
                    "number of one of them to avoid this error",conn(1),conn(2),...
                    conns(ii,1),conns(ii,2))
            end
        end
    end

% add the results to a block as fields
    function block = addResultsToBlock(block,results)
        % adds all the field of results to the block struct
        if isstruct(results)
            resultsFields = fieldnames(results);
            for ii = 1:length(resultsFields)
                block.(resultsFields{ii}) = results.(resultsFields{ii});
            end
            
        elseif isnumeric(results)
            if ~isempty(results)
                error("results of a function must be a struct or an empty array")
            end
        else
            error("results of a function must be a struct or an empty array")
        end
    end

% check if the variable f is a function handle
    function checkFunctionHandle(f,type)
        if ~isa(f,'function_handle')
            error("you must specify a valid function for the component of type %s",type)
        end
    end

% check that a block has the same number of input and output as every other
% block of the same type
    function checkInputOutput(block,blocks)
        for ii = 1:length(blocks)
            if blocks{ii}.type == block.type
                if blocks{ii}.nInput ~= block.nInput || blocks{ii}.nOutput ~= block.nOutput
                    error("block %d and block %d are of the same type but "+...
                    "have different number of inputs or outputs",block.nodeID,blocks{ii}.nodeID)
                end
            end
        end
    end

% get the number of input of a node
    function N = getInputN(node,conns)
        N = 0;
        for ii = 1:length(conns)
            if conns(ii,2) == node
                N = N+1;
            end
        end
    end

% get the number of output of a node
    function N = getOutputN(node,conns)
        N = 0;
        for ii = 1:length(conns)
            if conns(ii,1) == node
                N = N+1;
            end
        end
    end
end