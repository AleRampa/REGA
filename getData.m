function out = getData(FID,compInfo,block)
% returns the data of the requested block loaded from the input file

% return to the beginning of the file
frewind(FID);

% get the first line
line = fgetl(FID);

nline = 1;
while line > 0
    try        
        s = removeSpaces(line);
        % spaces lines are considered comments
        if isempty(s)
            s = {'%'};
        end
        % comments
        if string(s{1}(1)) ~= "%"
            s = string(removeTabs(s));
            % if the block name is recognized and it's not an output block
            if lower(s(1)) == block.type && double(s(2)) == block.compN && block.nOutput > 0
                % input blocks must define the state
                if block.nInput == 0
                    out.mdot = double(s(3));
                    out.p = double(s(4));
                    out.T = double(s(5));
                    out.rho = double(s(6));
                    out.composition.species = string(s(7));
                    out.composition.n = 1;
                % if is not an input block then add the variables to params
                elseif ismember(block.type,lower(string(compInfo(:,1))))
                    out = double(s(3:end));
                else
                    error("component of type %s not recognized",s(1));
                end
                return
            % if it's an output block
            elseif block.nOutput == 0
                out = [];
                return
            end
        end
    catch ME
        error("Error on line %d of input file:\n ""%s""" +...
            "\n"+ME.message+"\nCheck for typos in the input file or in"+...
            " the component definition",nline,line)
    end
    
    line = fgetl(FID);
    nline = nline + 1;
    % empty lines are considered comments
    if isempty(line)
        line = '%';
    end
end
error("component %s %d not found in input file",block.type,block.compN);

%% nested functions
    function S = removeTabs(ss)
        S = {};
        for i = 1:length(ss)
            % splitting the tabs
            ss_temp = split(ss{i},char(9));
            % removing empty entries
            ss_temp = ss_temp(~cellfun('isempty',ss_temp));
            S(end+1:end+length(ss_temp)) = ss_temp;
        end
    end

    function ss = removeSpaces(line)
        ss = split(line,' ');
        % removing empty entries
        ss = ss(~cellfun('isempty',ss));
    end
end


