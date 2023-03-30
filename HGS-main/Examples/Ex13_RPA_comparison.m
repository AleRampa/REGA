%***********************************************************************************************************
% *HGS 2.1
% *By Caleb Fuster, Manel Soria and Arnau Mir�
% *ESEIAAT UPC      
%***********************************************************************************************************
%
% RPA vs HGStp && HGSisentropic.
% LH2-LOX reaction

% RPA is a code for rocket combustion and expansion in a nozzle.
% Search it on the web for more info. https://www.rocket-propulsion.com/index.htm
% We compare our HGS algorithms with their results for a LH2-LOX combustion

% You can find a screen capture of the RPA solution in the file
% RPA_H2_O2_ex.PNG

% RPA data (ignore H2O2 and HO2 species)
% Combustion data
RPATcomb = 3004.0779; 
RPAcomb = [0.4730081, 0.0000519, 0.5040833, 0.0063140, 0.0001233, 0.0164185];
% Exit of the isentropic expansion
RPATis = 1534.1342;
RPAis = [0.4833980, 0, 0.4833980, 0.0000007, 0, 0.0000183];


% Basic info
of_ratio = 4.1; % The OF Ratio is done with kg oxidizer/ kg fuel
species = {'H2', 'O2', 'H2O', 'OH', 'O', 'H'};
n = zeros(length(species),1);
Tin = 90; % [K]
Tref = 300; % [K]
Pin = 45; % [bar]
Pexit = 1; % [bar]

mH2 = 1; % [kg]
mO2 = mH2 * of_ratio; % [kg]

% Convert kg to mols
MmH2 = HGSsingle('H2','Mm');
MmO2 = HGSsingle('O2','Mm');

n(1) = mH2 / (MmH2/1000);
n(2) = mO2 / (MmO2/1000);

% First of all, we need to calculate de inlet enthalpy using INIST
% (only the values) from a reference T of 300 K.
% deltaH_H2 = (INIST('H2','h_pt',45,300) - INIST('H2','h_pt',45,90)) * mH2
% deltaH_O2 = (INIST('O2','h_pt',45,300) - INIST('O2','h_pt',45,90)) * mO2

deltaH_H2 = 2.8577525044e+03 * mH2 ;
deltaH_O2 = 393.3914211 * mO2 ;

H_H2_HGS = HGSsingle('H2','h',Tref,Pin)*n(1);
H_O2_HGS = HGSsingle('O2','h',Tref,Pin)*n(2);

% Inlet enthalpy
Hin = H_H2_HGS - deltaH_H2 + H_O2_HGS - deltaH_O2;

% Now, we run the combustion with HGStp
[Tcomb,~, ncomb] = HGStp(species,n,'H', Hin, Pin);

% Now, we run the isentropic expansion
[Tis,~,nis,M2,flag] = HGSisentropic(species,ncomb,Tcomb,Pin,'Shifting','P',Pexit);


% Comparing results
fprintf('After the combustion\n')
fprintf('RPA\t %.3f K\t\t HGS: %.3f K \n',RPATcomb,Tcomb)
fprintf('Molar fractions\n');
for ii =1:length(species)
    fprintf('%s\t RPA:%.3e \t\t HGS: %.3e \n',species{ii},ncomb(ii)/sum(ncomb),RPAcomb(ii))
end

fprintf('\n')
fprintf('After the expansion\n')
fprintf('RPA\t %.3f K\t\t HGS: %.3f K \n',RPATis,Tis)
for ii =1:length(species)
    fprintf('%s\t RPA:%.3e \t\t HGS: %.3e \n',species{ii},nis(ii)/sum(nis),RPAis(ii))    
end
