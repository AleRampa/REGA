function HGSprintInfo(species)
%**************************************************************************
%
% HGSprintInfo(species)
%
%**************************************************************************
% 
% HGSprintInfo prints in the command window the info for a species
%
%**************************************************************************
% Inputs:
%--------------------------------------------------------------------------
% species --> A single species
%
% Outputs:
%--------------------------------------------------------------------------
% Command Window Print
%
%**************************************************************************
% *HGS 2.1
% *By Caleb Fuster, Manel Soria and Arnau Mir�
% *ESEIAAT UPC    

    global HGSdata; HGSload();
    
    id=HGSid(species);
    
    if numel(id) ~= 1
        error('Please call HGSprintInfo with just a component');
    end
    
    
    ns = length(HGSdata.Mm);
    if  ns >= id
        fprintf('Species = %s,   state = %s,  <code = %d>\n',HGSdata.name{id},HGSdata.state{id},id);
        ena=HGSdata.ena{id}; % element names
        nat=HGSdata.nat{id};
        ne=numel(ena); % number of elements 
        fprintf('  Composition: ');
        for jj=1:ne
            fprintf('%s-%d  ',ena{jj},nat(jj));
        end
        fprintf('\n');
        fprintf('  Mm = %.4f ',HGSdata.Mm(id));
        fprintf('\n     -----------------\n');
        
    else
        id2 = id-ns;
        fprintf('Combination = <%s>   <code = %d>\n',HGSdata.comb{id2},id);
        cen=HGSdata.cspec{id2}; % combination element names
        cna=HGSdata.cper{id2}; % combination element atoms
        ne=numel(cna); % number of elements 
        fprintf('  Composition-- ');
        for jj=1:ne
            fprintf('%s: %.2f%%.  ',cen{jj},cna(jj));
        end
        fprintf('\n     -----------------\n');
    end
end

