function [G] = HGSg(S,H,T)
%**************************************************************************
%
% [G] = HGSg(S,H,T)
%
%**************************************************************************
%
% HGSg calculates the species free Gibbs energy using enthalpy, enthropy 
% and temperature
%
%**************************************************************************
% Inputs:
%--------------------------------------------------------------------------
% S --> [kJ/(mol*K)] Entropy
% H --> [kJ/mol] Enthalpy
% T --> [K] Temperature
%
% Outputs:
%--------------------------------------------------------------------------
% G --> [kJ/mol] Free Gibbs energy
%
%**************************************************************************
% *HGS 2.1
% *By Caleb Fuster, Manel Soria and Arnau Mir�
% *ESEIAAT UPC    

G = H - T*S; % [kJ/mol]

end