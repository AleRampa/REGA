function [state_exit,results] = Mixer(states,params)
% Computes the thermodynamic variables after a mixer knowing the mixing
% pressure

% input parameters
pMix = params(1);

% check if input pressures are above the combustion chamber pressure
tol = 1e-3;
for st = 1:length(states)
    if (states(st).p - pMix)/pMix < -tol
        error("inlet pressures are lower than the mixer pressure")
    end
end

% valve every one of the input states to bring its pressure to the pcc
for st = 1:length(states)
    states(st) = Valve(states(st),states(st).p/pMix);
end

% compose the total species array
species_tot = states(1).composition.species;
for i = 2:length(states)
    species_tot = union(species_tot,states(st).composition.species);
end

% moles/s for every species
n = zeros(size(species_tot));

for i = 1:length(species_tot)
    
    for st = 1:length(states)
        MM_tot = HGSprop(cellstr(states(st).composition.species),states(st).composition.n,300,1,'Mm')/1000; % kg/mol
        
        idx = ismember(states(st).composition.species,species_tot(i));      
        if any(idx)
            n(i) = n(i) + states(st).composition.n(idx) * states(st).mdot/MM_tot;
        end
    end
end

% this function must be 0 for the outlet temperature
hasToBeZero = @(T) 0; % kJ

% pressure and temperature limits
pMin = 1e+300;
TMin = 1e+300;
pMax = 0;
TMax = 0;

for st = 1:length(states)
    if pMin > states(st).p
        pMin = states(st).p;
    end
    
    if pMax < states(st).p
        pMax = states(st).p;
    end
    
    if TMin > states(st).T
        TMin = states(st).T;
    end
    
    if TMax < states(st).T
        TMax = states(st).T;
    end
end


for st = 1:length(states)
    MM_tot = HGSprop(cellstr(states(st).composition.species),states(st).composition.n,300,1,'Mm')/1000; % kg/mol
    
    for i = 1 : length(states(st).composition.species)
        % try with NFP, if NFP does not implement the substance than switch to
        % HGS
        try
            %dummy
            NFP(states(st).composition.species(i),'h_pt',pMax,TMax);
            NFP(states(st).composition.species(i),'h_pt',pMin,TMin);
            
            MM = getMM(states(st).composition.species(i)); % kg/mol
            hasToBeZero = @(T) hasToBeZero(T) + ...
                (NFP(states(st).composition.species(i),'h_pt',states(st).p,T) - ...
                NFP(states(st).composition.species(i),'h_pt',states(st).p,states(st).T)) * ...
                states(st).mdot * states(st).composition.n(i) * MM/MM_tot; % kJ
        catch ME
            if ME.message(end-length('not found')+1:end) == "not found" ||...
                    ME.message(length('uhh? T=1.000000e+03 ')+1:length('uhh? T=1.000000e+03 ')+length('out of range')) == "out of range"               
                hasToBeZero = @(T) hasToBeZero(T) +...
                    (HGSsingle(char(states(st).composition.species(i)),'h',T,states(st).p) - ...
                    HGSsingle(char(states(st).composition.species(i)),'h',states(st).T,states(st).p)) * ...
                    states(st).mdot * states(st).composition.n(i)/MM_tot; % kJ
            else
                error(ME.message)
            end
        end
    end
end
% xval = linspace(275,800);
% yval = zeros(size(xval));
% for i = 1:length(xval)
%     yval(i) = hasToBeZero(xval(i));
% end
% plot(xval,yval)

% exit pressure
state_exit.p = states(st).p; % bar

% frozen flow
state_exit.composition.species = species_tot;
state_exit.composition.n = n/sum(n);

% mass conservation
state_exit.mdot = 0; % kg/s
for st = 1:length(states)
    state_exit.mdot = state_exit.mdot + states(st).mdot; % kg/s
end

% outlet temperature
state_exit.T = fzero(hasToBeZero,[TMin,TMax]); % K

% density
rho_vec = zeros(size(species_tot)); % kg/m^3
mass_vec = rho_vec; % kg/s

for i = 1:length(species_tot)  
    
    MM = getMM(species_tot(i)); % kg/mol
    
    mass_vec(i) = n(i) * MM; % kg/s
    
    try
        rho_vec(i) = NFP(species_tot(i),'r_pt',state_exit.p,state_exit.T); % kg/m^3
    catch ME
        if ME.message(end-length('not found')+1:end) == "not found" ||...
            ME.message(length('uhh? T=1.000000e+03 ')+1:length('uhh? T=1.000000e+03 ')+length('out of range')) == "out of range"
            Rg = HGSprop({char(species_tot(i))},state_exit.T,state_exit.p,'Rg')*1000; % kJ/kgK -> J/kgK
            rho_vec(i) = state_exit.p*1e+5/(state_exit.T*Rg); % kg/m^3
        else
            error(ME.message)
        end
    end
end
state_exit.rho = sum(mass_vec)/(sum(mass_vec./rho_vec)); % kg/m^3

% default empty output
results = [];

    function MM = getMM(sp)
        MM = HGSsingle(char(sp),'Mm',300,1)/1000; % kg/mol
    end
end

