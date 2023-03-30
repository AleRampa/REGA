function [species,n,Gmin] = HGSeq(species,n0,T,P,options)
%**************************************************************************
%
% [species,n,deltaG] = HGSeq(species,n,T,P,options)
%
%**************************************************************************
%
% HGSeq calculates the species mols equilibrium at a certain temperature
% and pressure
%
%**************************************************************************
% Inputs:
%--------------------------------------------------------------------------
% species --> String or code of species
% n0 --> [mol] Initial mixture
% T --> [K] Temperature.
% P --> [bar] Pressure
% options --> Options for fmincon (OPTIONAL)
%
% Outputs:
%--------------------------------------------------------------------------
% species --> String or code of species
% n --> [mol] Final mixture
% Gmin --> [kJ] Minimum Gibbs free energy
%
% *************************************************************************
% *HGS 2.1
% *By Caleb Fuster, Manel Soria and Arnau Mir�
% *ESEIAAT UPC    

%% Checks
spec = length(species);

if length(n0) ~= spec
    error('Ups..., Species and mols have not the same length. Check it')
end

if length(T) ~= 1
    error('Ups..., Temperatures length has multiple options. Check it')
end


global HGSdata; HGSload
[id] = HGSid(species);

% Rebuild mixtures
if max(id) > length(HGSdata.Mm)
   [species,n0] = HGSrebuild(species,n0);
   [id] = HGSid(species);
end


%% Options
if ~exist('options','var') || isempty(options)
    options = optimset('Algorithm','interior-point','Display','off','TolX',1e-8);
end


%% Setting fmincon parameters
% [n,Gmin,exitflag] = fmincon(fun,x0,A,b,Aeq,beq,lb,ub,nonlcon,options)

% Function: fun. 
minG = @(n) HGSprop(id,n,T,P,'G');

% Parameters
[A,b,Aeq,beq,lb,ub] = HGSparamFmincon(id,n0);

%% fmincon

[n,Gmin,flag]=fmincon(minG,n0,A,b,Aeq,beq,lb,ub,[],options);

if flag~=1 && flag~=2 
    error('Ups,... fmincon has failed in HGSeq.')
end

end