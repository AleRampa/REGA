function printStates(blocks,conns,statesID,states,compInfo)
% print the states in a table format

fprintf("States:\n\n")
fprintf("  <strong>state ID     from        to      mdot [kg/s]   p [bar]     T [K]     rho [kg/m^3]   composition   n frac[mol]</strong>\n")
fprintf("  <strong>________   ________   ________   ___________   _______   _________   ____________   ___________   ___________</strong>\n\n")

nicknames = string(compInfo(:,[1,2]));
nicknames(:,1) = lower(nicknames(:,1));

% spacings
sp = [6,11,11,12,13,11,13,15,15];

for i = 1:length(statesID)
    
    conn = conns(conns(:,3) == statesID(i),:);
    
    str = "";
    
    rem = 0;
    
    s = [...
        string(statesID(i)),...
        sprintf("%s %d",nicknames(nicknames == blocks{conn(1)}.type,2),blocks{conn(1)}.compN),...
        sprintf("%s %d",nicknames(nicknames == blocks{conn(2)}.type,2),blocks{conn(2)}.compN),...
        sprintf('%1.3f',states{i}.mdot),...
        sprintf('%1.3f',states{i}.p),...
        sprintf('%1.3f',states{i}.T),...
        sprintf('%1.3f',states{i}.rho)];
    
    l_1 = 0;
    for j = 1:length(s)
        l_2 = length(char(s(j)));
        wspaces = max(1,sp(j) - (l_1+l_2)/2);
        str = str + join(repmat(" ",1,floor(wspaces+rem)),'');
        str = str + s(j);
        rem = rem + wspaces - floor(wspaces+rem);
        l_1 = l_2;
    end
    
    s = sprintf('%s',states{i}.composition.species(1));    
    l_2 = length(s);
    wspaces = max(1,sp(end-1) - (l_1+l_2)/2);
    str = str + join(repmat(" ",1,floor(wspaces+rem)),'');
    str = str + s;
    rem = rem + wspaces - floor(wspaces+rem);
    l_1 = l_2;
    
    s = sprintf('%1.3f',states{i}.composition.n(1));    
    l_2 = length(s);
    wspaces = max(1,sp(end) - (l_1+l_2)/2);
    str = str + join(repmat(" ",1,floor(wspaces+rem)),'');
    str = str + s;
    
    fprintf(str + "\n");
    rem = 0;
    l_1 = 0;
    str = "";
    
    for j = 2:length(states{i}.composition.species)
        fprintf("                                                                             ")
        
        s = sprintf('%s',states{i}.composition.species(j));
        l_2 = length(s);
        wspaces = max(1,sp(end-1) - (l_1+l_2)/2);
        str = str + join(repmat(" ",1,floor(wspaces+rem)),'');
        str = str + s;
        rem = rem + wspaces - floor(wspaces+rem);
        l_1 = l_2;
        
        s = sprintf('%1.3f',states{i}.composition.n(j));
        l_2 = length(s);
        wspaces = max(1,sp(end) - (l_1+l_2)/2);
        str = str + join(repmat(" ",1,floor(wspaces+rem)),'');
        str = str + s;        
        
        fprintf(str + "\n");
        l_1 = 0;
        rem = 0;
        str = "";
    end  
end
fprintf("\n")
end