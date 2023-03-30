function HGSload
%**************************************************************************
%
% HGSload 
%
%**************************************************************************
% 
% HGSload loads as global variable HGSdata
%
%**************************************************************************
% Inputs:
%--------------------------------------------------------------------------
%
% Outputs:
%--------------------------------------------------------------------------
% HGSdata is load in the global workspace
%
%**************************************************************************
% *HGS 2.1
% *By Caleb Fuster, Manel Soria and Arnau Mir�
% *ESEIAAT UPC    

global HGSdata;
if ~isstruct(HGSdata) 
    try
        load('HGSdata')
    catch
       error('HGSdata.mat can not be find in the current paths.\n Use HGSdataDownload to create the data') 
    end
end

end

