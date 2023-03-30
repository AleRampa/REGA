function [Cv] = HGScv(Cp)
%**************************************************************************
%
% [Cv] = HGScv(Cp)
%
%**************************************************************************
%
% HGScv calculates the species Constant volume coeficient using constant
% pressure coeficient
%
%**************************************************************************
% Inputs:
%--------------------------------------------------------------------------
% Cp --> [kJ/(mol*K)] Constant pressure coefficient
%
% Outputs:
%--------------------------------------------------------------------------
% Cv --> [kJ/(mol*K)] Constant volume coefficient
%
%**************************************************************************
% *HGS 2.1
% *By Caleb Fuster, Manel Soria and Arnau Mir�
% *ESEIAAT UPC    

global R

Cv = Cp - R;  

end