function [state_exit,results] = CombustionChamber(states,params)
% Computes the thermodynamic variables after a combustion chamber assuming
% non-ideal combustion with efficiency, dissociation and knowing the 
% exchanged heat

% consider dissociation? default true
if length(params) > 3
    diss = params(4);
else
    diss = true;
end

% input parameters
pcc = params(1); % bar
Q_loss = params(2); % MW
eta_cstar = params(3);

% check if input pressures are above the combustion chamber pressure
tol = 1e-3;
for st = 1:length(states)
    if (states(st).p - pcc)/pcc < -tol
        error("inlet pressures are lower than the combustion chamber pressure")
    end
end

% valve every one of the input states to bring its pressure to the pcc
for st = 1:length(states)
    states(st) = Valve(states(st),states(st).p/pcc);
end

% compose the input species as "reagents"
reagents = states(1).composition.species;
for i = 2:length(states)
    reagents = union(reagents,states(st).composition.species);
end

% based on the variable dissociation select the products, only H2 and O2
% are implemented for now
if diss
    if any(ismember(reagents,"H2")) && any(ismember(reagents,"O2"))
        products = ["O","H","H2O","H2O2","OH"];
    else
        products = [];
    end
else
    if any(ismember(reagents,"H2")) && any(ismember(reagents,"O2"))
        products = ["H2O"];
    else
        products = [];
    end
end

% compose the total species
species_in = union(reagents,products);

% input moles/s
n_in = zeros(size(species_in)); % mol

for i = 1:length(species_in)
    
    for st = 1:length(states)
        MM_eq = HGSprop(cellstr(states(st).composition.species),states(st).composition.n,300,1,'Mm')/1000; % g/mol -> kg/mol
       
        idx = ismember(states(st).composition.species,species_in(i));
        
        if any(idx)
            n_in(i) = n_in(i) + states(st).composition.n(idx) * states(st).mdot/MM_eq; % mol
        end
    end
end

% reference temperature to couple HGS to NFP
Tref = 500; % K 

% calculation of inlet enthalpy
H1 = 0;

for st = 1:length(states)
    MM_eq = HGSprop(cellstr(states(st).composition.species),states(st).composition.n,300,1,'Mm')/1000; % g/mol -> kg/mol
    
    for i = 1 : length(states(st).composition.species)
        % try with NFP, if NFP does not implement the substance than switch to
        % HGS 
        
        MM = getMM(states(st).composition.species(i)); % kg/mol
        try
            h_NFP = NFP(states(st).composition.species(i),'h_pt',states(st).p,states(st).T); % kJ/kg
            
            h_ref_NFP = NFP(states(st).composition.species(i),'h_pt',states(st).p,Tref); % kJ/kg
            
            deltah = h_ref_NFP - h_NFP; % kJ/kg
                                  
            h_HGS = HGSsingle(char(states(st).composition.species(i)),'h',Tref,states(st).p)/MM; % kJ/mol -> kJ/kg
            
            h = h_HGS - deltah; % kJ/kg
            
        catch ME
            if ME.message(end-length('not found')+1:end) == "not found" ||...
                    ME.message(length('uhh? T=1.000000e+03 ')+1:length('uhh? T=1.000000e+03 ')+length('out of range')) == "out of range"                
                % try HGS
                h = HGSsingle(char(states(st).composition.species(i)),'h',states(st).T,states(st).p)/MM;
            else
                error(ME.message)
            end
        end
        % sum the enthalpy of the species to the total inlet enthalpy
        H1 = H1 + h * states(st).mdot * states(st).composition.n(i) * MM/MM_eq; %kJ
    end
end

% adding the lost heat
H1 = H1 + Q_loss*1e3; % kJ

% solve the combustion
[Tcc_ideal,species_out_ideal,n_out_ideal] = HGStp(cellstr(species_in),n_in,'H',H1,pcc);

% ideal combustion properties
gamma_ideal = HGSprop(species_out_ideal,n_out_ideal,Tcc_ideal,pcc,'gamma');
Rg_ideal =  HGSprop(species_out_ideal,n_out_ideal,Tcc_ideal,pcc,'Rg')*1000; % kJ/kgK -> J/kgK
Gamma_ideal = gamma_ideal*(2/(gamma_ideal+1))^((gamma_ideal+1)/(2*(gamma_ideal-1)));
cstar_ideal = 1/Gamma_ideal * sqrt(gamma_ideal * Rg_ideal * Tcc_ideal); % m/s

% applying efficiency
cstar = cstar_ideal * eta_cstar; % m/s

% solving iteratively the combustion with efficiency
tol = 1e-4;
err = 1e+300;
iter = 0;
itMax = 100;

% initialize variables
Tcc = Tcc_ideal; % K
n_out = n_out_ideal; % mol
species_out = species_out_ideal;

while iter < itMax && err > tol
    iter = iter + 1;
    gamma = HGSprop(species_out,n_out,Tcc,pcc,'gamma');
    Rg =  HGSprop(species_out,n_out,Tcc,pcc,'Rg')*1000; % kJ/kgK -> J/kgK
    Gamma = gamma*(2/(gamma+1))^((gamma+1)/(2*(gamma-1)));
    Tcc0 = Tcc; % K
    Tcc = (cstar * Gamma)^2 / (gamma*Rg); % K
    [species_out,n_out] = HGSeq(species_out,n_out,Tcc,pcc);
    err = abs(Tcc - Tcc0);
end

% calculating exit variables
state_exit.composition.species = string(species_out);
state_exit.composition.n = n_out/sum(n_out);
state_exit.T = Tcc; % K
state_exit.p = pcc; % bar
Rg = HGSprop(cellstr(state_exit.composition.species),state_exit.composition.n*100,state_exit.T,state_exit.p,'Rg')*1000; % kJ/kgK -> J/kgK
state_exit.rho = state_exit.p*1e+5/(state_exit.T*Rg); % kg/m^3

% mass conservation
state_exit.mdot = 0;
for st = 1:length(states)
    state_exit.mdot = state_exit.mdot + states(st).mdot; % kg/s
end

% default empty output
results = [];

% nested function for MM of a species in kg/mol
    function MM = getMM(sp)
        MM = HGSsingle(char(sp),'Mm',300,1)/1000; % kg/mol
    end

end

