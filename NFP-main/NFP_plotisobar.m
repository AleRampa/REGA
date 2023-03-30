function pl = NFP_plotisobar(dat,pv,varargin)
% NFP - Non-ideal Fluid Properties (previously INIST)
%
% Property of THRUST, unauthorized distribution is not allowed
% version: NFP_plotisobar 1.1
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % Branched and modified from the original ManelSoria/INIST repository %
% % Original head:                                                      %
% % (c) Manel Soria, Caleb Fuster, Lorenzo Frezza                       %
% % Data downloaded from NIST web page                                  %
% % ESEIAAT - UPC - 2014-2021                                           %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%
% NFP_plotisobar(dat,p,color,thickness)
% NFP_plotisobar:  plot isobar vector
% dat: species
% p: isobar vector
% color (optional): isobar colors 
% thickness (optional): line thickness
%
% examples:
% NFP_plotisobar('N2',[10,20],'k',2)

%{
Changelog:
  > version: 1.1 - 14/12/2022 - Alessandro Rampazzo
    - branched from the original ManelSoria/INIST repository
%}


global IND

path = fileparts(which(mfilename));
addpath(genpath(path));

try
    if isempty(IND) || ~isfield(IND,dat)  
        set = load(dat);
        IND.(dat) = set.(dat);
    end
catch
    error('%s not found',dat)
end

switch numel(varargin)
    case 0
        color='k';
        thickness=1;
    case 1
        color=varargin{1};
        thickness=1;
    case 2
        color=varargin{1};
        thickness=varargin{2};
    otherwise
        error('uhh too many arguments');
end

for j=1:length(pv)% plot isobar number j
   ok = 0;
   for  ii=1:length(IND.(dat).isoP)
       if IND.(dat).isoP{ii}.P==pv(j)
           pl = plot(IND.(dat).isoP{ii}.s,IND.(dat).isoP{ii}.T,color,'LineWidth',thickness);
           hold on
           ok = 1;
           break;
       end  
       if ii < length(IND.(dat).isoP) && IND.(dat).isoP{ii+1}.P > pv(j) && IND.(dat).isoP{ii}.P < pv(j)
           Snext = IND.(dat).isoP{ii+1}.s;
           Sprev = IND.(dat).isoP{ii}.s;
           Pnext = IND.(dat).isoP{ii+1}.P;
           Pprev = IND.(dat).isoP{ii}.P;           
           Tprev = IND.(dat).isoP{ii}.T;
           Tnext = IND.(dat).isoP{ii+1}.T;
           
           lprev = length(Sprev);
           lnext = length(Snext);
           if lnext ~= lprev 
              if lnext < lprev 
                  Sprev = Sprev(2:end);
                  Tprev = Tprev(2:end);
              else
                  Snext = Snext(2:end);
                  Tnext = Tnext(2:end);
              end
           end
               
           S = (Snext - Sprev) ./ (Pnext -Pprev) .* (pv(j) - Pprev) + Sprev;
           T = (Tnext+Tprev)/2;
           
           pl = plot(S,T,color,'LineWidth',thickness);
           hold on
           ok = 1;
           break;
       end   
   end
   if ok == 0
      error('Isobar (%e) not found',pv(j)) 
   end
end

% plot saturation bell
plot(IND.(dat).sl,IND.(dat).Tsat,'r','LineWidth',thickness);
plot(IND.(dat).sv,IND.(dat).Tsat,'r','LineWidth',thickness);


title(IND.(dat).name);
xlabel('s (kJ/kgK)');
ylabel('T (K)');

grid

return

end


