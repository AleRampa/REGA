function printBlocks(blocks,compInfo)
% print the blocks in a table format

paramNames = string([]);
resultNames = string([]);
seenBlockTypes = string([]);

for i = 1:length(blocks)
    proceed = false;
    if isempty(seenBlockTypes)
        seenBlockTypes(1) = blocks{i}.type;
        proceed = true;
    elseif ~ismember(seenBlockTypes,blocks{i}.type)
        seenBlockTypes(end+1) = blocks{i}.type;
        proceed = true;
    end
    
    if proceed
        if isfield(blocks{i},'params')
            if blocks{i}.nInput == 0
                paramNames(:,end+1) = string(fieldnames(blocks{i}.state));
                resultNames(1,end+1) = string(missing);
            else
                paramNames(1,end+1) = "param "+1;
                for j = 2:length(blocks{i}.params)
                    paramNames(j,end) = "param "+j;
                end
                fields = fieldnames(blocks{i});
                resultNames(1:length(fields(7:end)),end+1) = string(fields(7:end));
            end
        else
            if blocks{i}.nInput == 0
                paramNames(:,end+1) = string(fieldnames(blocks{i}.state));
                resultNames(1,end+1) = string(missing);
            elseif blocks{i}.nOutput == 0
                paramNames(1,end+1) = string(missing);
                resultNames(1,end+1) = string(missing);
            else
                paramNames(1,end+1) = string(missing);
                fields = fieldnames(blocks{i});
                resultNames(1:length(fields(6:end)),end+1) = string(fields(6:end));
            end
        end
    end
end


fprintf("Blocks:\n\n")

fprintf("mdot is in [kg/s], p is in [bar], T is in [K], rho is in [kg/m^3],\n"+...
    "powers are in [MW] and every other quantity is in SI units\n\n");
nicknames = string(compInfo(:,[1,2]));
nicknames(:,1) = lower(nicknames(:,1));

% header spacings
sp_head = [8,ones(1,20)*12];
% number spacings
sp = [6,10,10,ones(1,20)*12];

for i = 1:length(seenBlockTypes)
    
    rem = 0;
    
    header =    "  <strong>block ID    name     comp n°";
    subheader = "  <strong>________   ______    _______ ";
    
    params = paramNames(~ismissing(paramNames(:,i)),i)';
    results = resultNames(~ismissing(resultNames(:,i)),i)';
    s_head = [params,results];
    
    if isempty(s_head)
        continue
    end
    
    l_1 = 0;
    for k = 1:length(s_head)
        l_2 = length(char(s_head(k)));
        wspaces = max(1,sp_head(k) - (l_1+l_2)/2);
        header = header + join(repmat(" ",1,floor(wspaces+rem)),'');
        header = header + s_head(k);
        subheader = subheader + join(repmat(" ",1,max(floor(wspaces+rem-2),1)),'');
        subheader = subheader + join(repmat("_",1,2+length(char(s_head(k)))),'');
        rem = rem + wspaces - floor(wspaces+rem);
        l_1 = l_2;
    end
    header = header + "</strong>\n";
    subheader = subheader + "</strong>\n\n";
    fprintf(header)
    fprintf(subheader)
    
    for k = 1:length(blocks)
        if blocks{k}.type == seenBlockTypes(i)
            str = "";
            
            rem = 0;
            
            s = [...
                blocks{k}.nodeID,...
                sprintf("%s",nicknames(nicknames == blocks{k}.type,2)),...
                sprintf("%d",blocks{k}.compN),...
                repmat(missing,1,length(s_head))];
                       
            if blocks{k}.nInput == 0                                
                for j = 1:length(s_head)
                    ss = split(s_head(j));
                    if ss{1} == "composition"
                        s(3+j) = sprintf("%s",blocks{k}.state.(ss{1}).species);
                    else
                        s(3+j) = sprintf("%1.3f",blocks{k}.state.(ss{1}));
                    end
                end
            else
                % params
                for j = 1:length(params)
                    s(3+j) = sprintf("%1.3f",blocks{k}.params(j));
                                          
                end
                start_j = j;
                % results
                for j = 1:length(results)
                    value = blocks{k}.(results(j));
                    if ischar(value)
                        value = string(value);
                    end
                    
                    if isscalar(value)
                        if isstring(value)
                            s(3+start_j+j) = sprintf("%s",value);
                        elseif isnumeric(value)
                            s(3+start_j+j) = sprintf("%1.3f",value);
                        end
                    else
                        warning("one of the results of the block %s %d has"+...
                            " a type that is not implemented for the display"+...
                            "of the results",blocks{k}.type,blocks{k}.compN)
                        s(start_j+j) = ""; 
                    end                       
                end
            end
            
            l_1 = 0;
            for j = 1:length(s)
                l_2 = length(char(s(j)));
                wspaces = max(1,sp(j) - (l_1+l_2)/2);
                str = str + join(repmat(" ",1,floor(wspaces+rem)),'');
                str = str + s(j);
                rem = rem + wspaces - floor(wspaces+rem);
                l_1 = l_2;
            end
            
            fprintf(str+"\n")
        end        
    end
    fprintf("\n\n")
end
end
