function [ret] = NFP(varargin)
% NFP - Non-ideal Fluid Properties (previously INIST)
%
% Property of THRUST, unauthorized distribution is not allowed
% version: NFP 1.1
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % Branched and modified from the original ManelSoria/INIST repository %
% % Original head:                                                      %
% % (c) Manel Soria, Caleb Fuster, Lorenzo Frezza                       %
% % Data downloaded from NIST web page                                  %
% % ESEIAAT - UPC - 2014-2021                                           %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%
% properties:
%   - volume:      "v"
%   - energy:      "u"
%   - enthalpy:    "h"
%   - entropy:     "s"
%   - specific heat coeff at constant volume:   "cv"
%   - specific heat coeff at constant pressure: "cp"
%   - sound speed: "a"
%   - viscosity:   "mu"
%   - density:     "r"
%   - thermal conductivity: "k"
%
% Units: 
%  - T: [K]
%  - p: [bar]
%  - h, u: [kJ/kg]
%  - v: [m^3/kg] 
%  - rho: [kg/m^3]
%  - s: [kJ/kgK]
%  - a: [m/s] 
%  - cv, cp: [kJ/kgK]
%  - JT: [bar/K]
%  - mu: [Pa*s]
%  - k: [W/mK]
%  - MM: [kg/mol]
%
% 1st argument: substance name
%               'Database' to return the list of database elements
%
% 2nd and remaining arguments: 
%  critical temperature     "tcrit" 
%  critical pressure        "pcrit"
%  critical volume          "vcrit" 
%  molecular mass           "MM"
%  saturation temperature   "tsat_p", p  
%  saturation pressure      "psat_t", T
%
%  saturated liquid properties as a function of pressure or temperature
%    property + "l" + "_" + "p", p
%    property + "l" + "_" + "t", t
%      ex. "hl_p" calls the enthalpy of saturated liquid at pressure p
%
%  saturated vapor properties as a function of pressure or temperature
%    property + "v" + "_" + "p", p
%    property + "v" + "_" + "t", t
%      ex. "hv_p" calls the enthalpy of saturated vapor at pressure p
%
%  saturated vapor+liquid properties as a function of temperature or 
%  pressure and quality
%    property + "_" + "xt", x, t 
%    property + "_" + "tx", t, x
%    property + "_" + "xp", x, p 
%    property + "_" + "px", p, x
%      ex. "h_xp" calls the enthalpy of saturated vapor+liquid at quality x
%      and pressure p
%
%  non-saturated properties as a function of pressure and temperature
%    property + "_" + "pt", p, t 
%    property + "_" + "tp", t, p
%      ex. "h_tp" calls the enthalpy of non saturated fluid at temperature
%      t and pressure p
%
%  temperature as a function of ...
%     pressure and entropy 't_ps', p, s
%     entropy and pressure 't_sp', s, p  
%     pressure and enthalpy 't_ph', p, h
%     enthalpy and pressure 't_hp', h, p  
%     
%  special functions:
%       'minp'        returns the minimum isobar available
%       'maxp'        idem max isobar
%       'mint'        idem minimum temperature 
%       'maxt'        idem maximum temperature 
%       'isobars'     returns a vector with the available isobars

%{
Changelog:
  > version: 1.3 - 14/12/2022 - Alessandro Rampazzo
    - made string proof for properties input
    - implemented inversion invariance of the variables in the properties
    field: NFP("N2",'h_pt',3,300) == NFP("N2",'h_tp',300,3)
    - changed header and description

  > version: 1.2 - 14/12/2022 - Alessandro Rampazzo
    - fixed a bug in density calculation under biphase condition (tx or px)

  > version: 1.1 - 14/12/2022 - Alessandro Rampazzo
    - branched from the original ManelSoria/INIST repository
%}

global IND

% Creative way to sort addpath. if you don't remove Database path, you
% won't get any problem. However clear all command will trigger the 
% following if in the first use of NFP.
if isempty(IND)
    path = fileparts(which(mfilename));
    addpath(osi([path '\DatabaseNFP']));
end


if strcmp(varargin{1},'Database') % Return a list of species in the database 
    path = fileparts(which(mfilename));
    databasepath = [path '\DatabaseNFP\*.mat'];
    % Adapts path to the OS
    databasepath = osi(databasepath);
    info  = dir(databasepath);
    ret = {info.name};
    ret = strrep(ret,'.mat','');
    return
end

try % load the species needed
    if isempty(IND) || ~isfield(IND,varargin{1})  
        set = load(varargin{1});
        IND.(varargin{1}) = set.(varargin{1});
    end
catch
    error('%s not found',varargin{1})
end


dat = IND.(varargin{1});
prop = lower(char(varargin{2})); 

switch prop
    case 'mm'
        ret=dat.MM;
    case 'tcrit'
        ret=dat.Tsat(end);
    case 'pcrit'
        ret=dat.Psat(end);
    case 'vcrit'
        ret=dat.vl(end);
    case 'isobars'
        ret=[];
        for i=1:length(dat.isoP)
            ret(i)=dat.isoP{i}.P;
        end
    case 'tsat_p' 
        p=varargin{3};
        check_satp(p);
        ret = interp1(dat.Psat,dat.Tsat,p);
    case 'psat_t'
        T=varargin{3};
        check_satT(T);
        ret = interp1(dat.Tsat,dat.Psat,T);
        
%  saturated liquid properties as a function of pressure    
    case 'vl_p',  p=varargin{3}; check_satp(p);ret=interp1(dat.Psat,dat.vl,p);        
    case 'ul_p',  p=varargin{3}; check_satp(p);ret=interp1(dat.Psat,dat.ul,p);
    case 'hl_p',  p=varargin{3}; check_satp(p);ret=interp1(dat.Psat,dat.hl,p);
    case 'sl_p',  p=varargin{3}; check_satp(p);ret=interp1(dat.Psat,dat.sl,p);
    case 'cvl_p', p=varargin{3}; check_undefined_p(p); check_satp(p);ret=interp1(dat.Psat,dat.cvl,p);
    case 'cpl_p', p=varargin{3}; check_undefined_p(p); check_satp(p);ret=interp1(dat.Psat,dat.cpl,p);
    case 'al_p',  p=varargin{3}; check_undefined_p(p); check_satp(p);ret=interp1(dat.Psat,dat.al,p);
    case 'mul_p', p=varargin{3}; check_satp(p);ret=interp1(dat.Psat,dat.mul,p);
    case 'rl_p',  p=varargin{3}; check_satp(p);ret=interp1(dat.Psat,dat.rl,p);
    case 'kl_p',  p=varargin{3}; check_satp(p);ret=interp1(dat.Psat,dat.kl,p);
        
%  saturated vapour properties as a function of pressure        
    case 'vv_p',  p=varargin{3}; check_satp(p);ret=interp1(dat.Psat,dat.vv,p);        
    case 'uv_p',  p=varargin{3}; check_satp(p);ret=interp1(dat.Psat,dat.uv,p);
    case 'hv_p',  p=varargin{3}; check_satp(p);ret=interp1(dat.Psat,dat.hv,p);
    case 'sv_p',  p=varargin{3}; check_satp(p);ret=interp1(dat.Psat,dat.sv,p);
    case 'cvv_p', p=varargin{3}; check_undefined_p(p); check_satp(p);ret=interp1(dat.Psat,dat.cvv,p);
    case 'cpv_p', p=varargin{3}; check_undefined_p(p); check_satp(p);ret=interp1(dat.Psat,dat.cpv,p);
    case 'av_p',  p=varargin{3}; check_undefined_p(p); check_satp(p);ret=interp1(dat.Psat,dat.av,p);    
    case 'muv_p', p=varargin{3}; check_satp(p);ret=interp1(dat.Psat,dat.muv,p);
    case 'rv_p',  p=varargin{3}; check_satp(p);ret=interp1(dat.Psat,dat.rv,p);
    case 'kv_p',  p=varargin{3}; check_satp(p);ret=interp1(dat.Psat,dat.kv,p);    
    
%  saturated liquid properties as a function of temperature        
    case 'vl_t',  t=varargin{3}; check_satT(t);ret=interp1(dat.Tsat,dat.vl,t);        
    case 'ul_t',  t=varargin{3}; check_satT(t);ret=interp1(dat.Tsat,dat.ul,t);
    case 'hl_t',  t=varargin{3}; check_satT(t);ret=interp1(dat.Tsat,dat.hl,t);
    case 'sl_t',  t=varargin{3}; check_satT(t);ret=interp1(dat.Tsat,dat.sl,t);
    case 'cvl_t', t=varargin{3}; check_undefined_t(t); check_satT(t);ret=interp1(dat.Tsat,dat.cvl,t);
    case 'cpl_t', t=varargin{3}; check_undefined_t(t); check_satT(t);ret=interp1(dat.Tsat,dat.cpl,t);
    case 'al_t',  t=varargin{3}; check_undefined_t(t); check_satT(t);ret=interp1(dat.Tsat,dat.al,t);    
    case 'mul_t', t=varargin{3}; check_satT(t);ret=interp1(dat.Tsat,dat.mul,t);
    case 'rl_t',  t=varargin{3}; check_satT(t);ret=interp1(dat.Tsat,dat.rl,t);
    case 'kl_t',  t=varargin{3}; check_satT(t);ret=interp1(dat.Tsat,dat.kl,t);   

        
%  saturated vapour properties as a function of temperature
    case 'vv_t',  t=varargin{3}; check_satT(t);ret=interp1(dat.Tsat,dat.vv,t);        
    case 'uv_t',  t=varargin{3}; check_satT(t);ret=interp1(dat.Tsat,dat.uv,t);
    case 'hv_t',  t=varargin{3}; check_satT(t);ret=interp1(dat.Tsat,dat.hv,t);
    case 'sv_t',  t=varargin{3}; check_satT(t);ret=interp1(dat.Tsat,dat.sv,t);
    case 'cvv_t', t=varargin{3}; check_undefined_t(t); check_satT(t);ret=interp1(dat.Tsat,dat.cvv,t);
    case 'cpv_t', t=varargin{3}; check_undefined_t(t); check_satT(t);ret=interp1(dat.Tsat,dat.cpv,t);
    case 'av_t',  t=varargin{3}; check_undefined_t(t); check_satT(t);ret=interp1(dat.Tsat,dat.av,t);
    case 'muv_t', t=varargin{3}; check_satT(t);ret=interp1(dat.Tsat,dat.muv,t);
    case 'rv_t',  t=varargin{3}; check_satT(t);ret=interp1(dat.Tsat,dat.rv,t);
    case 'kv_t',  t=varargin{3}; check_satT(t);ret=interp1(dat.Tsat,dat.kv,t);  
        
        
%  saturated  properties as a function of temperature and quality
    case 'v_tx',  t=varargin{3};x=varargin{4}; check_satT(t);vap=interp1(dat.Tsat,dat.vv,t);liq=interp1(dat.Tsat,dat.vl,t);ret = x*(vap-liq)+liq;     
    case 'u_tx',  t=varargin{3};x=varargin{4}; check_satT(t);vap=interp1(dat.Tsat,dat.uv,t);liq=interp1(dat.Tsat,dat.ul,t);ret = x*(vap-liq)+liq;
    case 'h_tx',  t=varargin{3};x=varargin{4}; check_satT(t);vap=interp1(dat.Tsat,dat.hv,t);liq=interp1(dat.Tsat,dat.hl,t);ret = x*(vap-liq)+liq;
    case 's_tx',  t=varargin{3};x=varargin{4}; check_satT(t);vap=interp1(dat.Tsat,dat.sv,t);liq=interp1(dat.Tsat,dat.sl,t);ret = x*(vap-liq)+liq;
    case 'cv_tx', t=varargin{3};x=varargin{4}; check_satT(t);check_undefined_t(t);vap=interp1(dat.Tsat,dat.cvv,t);liq=interp1(dat.Tsat,dat.cvl,t);ret = x*(vap-liq)+liq;
    case 'cp_tx', t=varargin{3};x=varargin{4}; check_satT(t);check_undefined_t(t);vap=interp1(dat.Tsat,dat.cpv,t);liq=interp1(dat.Tsat,dat.cpl,t);ret = x*(vap-liq)+liq;
    case 'a_tx',  t=varargin{3};x=varargin{4}; check_satT(t);check_undefined_t(t);vap=interp1(dat.Tsat,dat.av,t);liq=interp1(dat.Tsat,dat.al,t);ret = x*(vap-liq)+liq;
    case 'mu_tx', t=varargin{3};x=varargin{4}; check_satT(t);vap=interp1(dat.Tsat,dat.muv,t);liq=interp1(dat.Tsat,dat.mul,t);ret = x*(vap-liq)+liq;
% error on this line, density is calculated using the harmonic mean
%     case 'r_tx',  t=varargin{3};x=varargin{4}; check_satT(t);vap=interp1(dat.Tsat,dat.rv,t);liq=interp1(dat.Tsat,dat.rl,t);ret = x*(vap-liq)+liq;
    case 'r_tx',  t=varargin{3};x=varargin{4}; check_satT(t);vap=interp1(dat.Tsat,dat.rv,t);liq=interp1(dat.Tsat,dat.rl,t);ret = 1/(x/vap + (1-x)/liq);
    case 'k_tx',  t=varargin{3};x=varargin{4}; check_satT(t);vap=interp1(dat.Tsat,dat.kv,t);liq=interp1(dat.Tsat,dat.kl,t);ret = x*(vap-liq)+liq;


    case 'v_xt',  x=varargin{3};t=varargin{4}; check_satT(t);vap=interp1(dat.Tsat,dat.vv,t);liq=interp1(dat.Tsat,dat.vl,t);ret = x*(vap-liq)+liq;     
    case 'u_xt',  x=varargin{3};t=varargin{4}; check_satT(t);vap=interp1(dat.Tsat,dat.uv,t);liq=interp1(dat.Tsat,dat.ul,t);ret = x*(vap-liq)+liq;
    case 'h_xt',  x=varargin{3};t=varargin{4}; check_satT(t);vap=interp1(dat.Tsat,dat.hv,t);liq=interp1(dat.Tsat,dat.hl,t);ret = x*(vap-liq)+liq;
    case 's_xt',  x=varargin{3};t=varargin{4}; check_satT(t);vap=interp1(dat.Tsat,dat.sv,t);liq=interp1(dat.Tsat,dat.sl,t);ret = x*(vap-liq)+liq;
    case 'cv_xt', x=varargin{3};t=varargin{4}; check_satT(t);check_undefined_t(t);vap=interp1(dat.Tsat,dat.cvv,t);liq=interp1(dat.Tsat,dat.cvl,t);ret = x*(vap-liq)+liq;
    case 'cp_xt', x=varargin{3};t=varargin{4}; check_satT(t);check_undefined_t(t);vap=interp1(dat.Tsat,dat.cpv,t);liq=interp1(dat.Tsat,dat.cpl,t);ret = x*(vap-liq)+liq;
    case 'a_xt',  x=varargin{3};t=varargin{4}; check_satT(t);check_undefined_t(t);vap=interp1(dat.Tsat,dat.av,t);liq=interp1(dat.Tsat,dat.al,t);ret = x*(vap-liq)+liq;
    case 'mu_xt', x=varargin{3};t=varargin{4}; check_satT(t);vap=interp1(dat.Tsat,dat.muv,t);liq=interp1(dat.Tsat,dat.mul,t);ret = x*(vap-liq)+liq;
% error on this line, density is calculated using the harmonic mean
%     case 'r_xt',  x=varargin{3};t=varargin{4}; check_satT(t);vap=interp1(dat.Tsat,dat.rv,t);liq=interp1(dat.Tsat,dat.rl,t);ret = x*(vap-liq)+liq;
    case 'r_xt',  x=varargin{3};t=varargin{4}; check_satT(t);vap=interp1(dat.Tsat,dat.rv,t);liq=interp1(dat.Tsat,dat.rl,t);ret = 1/(x/vap + (1-x)/liq);
    case 'k_xt',  x=varargin{3};t=varargin{4}; check_satT(t);vap=interp1(dat.Tsat,dat.kv,t);liq=interp1(dat.Tsat,dat.kl,t);ret = x*(vap-liq)+liq; 
        

%   saturated  properties as a function of pressure and quality
    case 'v_px',  p=varargin{3};x=varargin{4}; check_satp(p);vap=interp1(dat.Psat,dat.vv,p);liq=interp1(dat.Psat,dat.vl,p);ret = x*(vap-liq)+liq;     
    case 'u_px',  p=varargin{3};x=varargin{4}; check_satp(p);vap=interp1(dat.Psat,dat.uv,p);liq=interp1(dat.Psat,dat.ul,p);ret = x*(vap-liq)+liq;
    case 'h_px',  p=varargin{3};x=varargin{4}; check_satp(p);vap=interp1(dat.Psat,dat.hv,p);liq=interp1(dat.Psat,dat.hl,p);ret = x*(vap-liq)+liq;
    case 's_px',  p=varargin{3};x=varargin{4}; check_satp(p);vap=interp1(dat.Psat,dat.sv,p);liq=interp1(dat.Psat,dat.sl,p);ret = x*(vap-liq)+liq;
    case 'cv_px', p=varargin{3};x=varargin{4}; check_satp(p);check_undefined_p(p);vap=interp1(dat.Psat,dat.cvv,p);liq=interp1(dat.Psat,dat.cvl,p);ret = x*(vap-liq)+liq;
    case 'cp_px', p=varargin{3};x=varargin{4}; check_satp(p);check_undefined_p(p);vap=interp1(dat.Psat,dat.cpv,p);liq=interp1(dat.Psat,dat.cpl,p);ret = x*(vap-liq)+liq;
    case 'a_px',  p=varargin{3};x=varargin{4}; check_satp(p);check_undefined_p(p);vap=interp1(dat.Psat,dat.av,p);liq=interp1(dat.Psat,dat.al,p);ret = x*(vap-liq)+liq;
    case 'mu_px', p=varargin{3};x=varargin{4}; check_satp(p);vap=interp1(dat.Psat,dat.muv,p);liq=interp1(dat.Psat,dat.mul,p);ret = x*(vap-liq)+liq;
% error on this line, density is calculated using the harmonic mean
%     case 'r_px',  p=varargin{3};x=varargin{4}; check_satp(p);vap=interp1(dat.Psat,dat.rv,p);liq=interp1(dat.Psat,dat.rl,p);ret = x*(vap-liq)+liq;
    case 'r_px',  p=varargin{3};x=varargin{4}; check_satp(p);vap=interp1(dat.Psat,dat.rv,p);liq=interp1(dat.Psat,dat.rl,p);ret = 1/(x/vap + (1-x)/liq);
    case 'k_px',  p=varargin{3};x=varargin{4}; check_satp(p);vap=interp1(dat.Psat,dat.kv,p);liq=interp1(dat.Psat,dat.kl,p);ret = x*(vap-liq)+liq;


%   saturated  properties as a function of pressure and quality
    case 'v_xp',  x=varargin{3};p=varargin{4}; check_satp(p);vap=interp1(dat.Psat,dat.vv,p);liq=interp1(dat.Psat,dat.vl,p);ret = x*(vap-liq)+liq;     
    case 'u_xp',  x=varargin{3};p=varargin{4}; check_satp(p);vap=interp1(dat.Psat,dat.uv,p);liq=interp1(dat.Psat,dat.ul,p);ret = x*(vap-liq)+liq;
    case 'h_xp',  x=varargin{3};p=varargin{4}; check_satp(p);vap=interp1(dat.Psat,dat.hv,p);liq=interp1(dat.Psat,dat.hl,p);ret = x*(vap-liq)+liq;
    case 's_xp',  x=varargin{3};p=varargin{4}; check_satp(p);vap=interp1(dat.Psat,dat.sv,p);liq=interp1(dat.Psat,dat.sl,p);ret = x*(vap-liq)+liq;
    case 'cv_xp', x=varargin{3};p=varargin{4}; check_satp(p);check_undefined_p(p);vap=interp1(dat.Psat,dat.cvv,p);liq=interp1(dat.Psat,dat.cvl,p);ret = x*(vap-liq)+liq;
    case 'cp_xp', x=varargin{3};p=varargin{4}; check_satp(p);check_undefined_p(p);vap=interp1(dat.Psat,dat.cpv,p);liq=interp1(dat.Psat,dat.cpl,p);ret = x*(vap-liq)+liq;
    case 'a_xp',  x=varargin{3};p=varargin{4}; check_satp(p);check_undefined_p(p);vap=interp1(dat.Psat,dat.av,p);liq=interp1(dat.Psat,dat.al,p);ret = x*(vap-liq)+liq;
    case 'mu_xp', x=varargin{3};p=varargin{4}; check_satp(p);vap=interp1(dat.Psat,dat.muv,p);liq=interp1(dat.Psat,dat.mul,p);ret = x*(vap-liq)+liq;
% error on this line, density is calculated using the harmonic mean
%     case 'r_xp',  x=varargin{3};p=varargin{4}; check_satp(p);vap=interp1(dat.Psat,dat.rv,p);liq=interp1(dat.Psat,dat.rl,p);ret = x*(vap-liq)+liq;
    case 'r_xp',  x=varargin{3};p=varargin{4}; check_satp(p);vap=interp1(dat.Psat,dat.rv,p);liq=interp1(dat.Psat,dat.rl,p);ret = 1/(x/vap + (1-x)/liq);
    case 'k_xp',  x=varargin{3};p=varargin{4}; check_satp(p);vap=interp1(dat.Psat,dat.kv,p);liq=interp1(dat.Psat,dat.kl,p);ret = x*(vap-liq)+liq;

        
    case {'v_pt','u_pt','h_pt','s_pt','cv_pt','cp_pt','a_pt','jt_pt','mu_pt','r_pt','k_pt',...
            'v_tp','u_tp','h_tp','s_tp','cv_tp','cp_tp','a_tp','jt_tp','mu_tp','r_tp','k_tp'}
        if prop(end) == 't'
            p=varargin{3}; 
            T=varargin{4};
        else
            T=varargin{3};
            p=varargin{4}; 
        end

        checkpT(p,T);
        p1=findp(p);

        switch prop(1)
            case 'v', val1=myi(dat.isoP{p1}.T,dat.isoP{p1}.v,T); val2=myi(dat.isoP{p1+1}.T,dat.isoP{p1+1}.v,T); %[m3/kg] Specific Volume
            case 'u', val1=myi(dat.isoP{p1}.T,dat.isoP{p1}.u,T); val2=myi(dat.isoP{p1+1}.T,dat.isoP{p1+1}.u,T); %[kJ/kg] Internal Energy
            case 'h', val1=myi(dat.isoP{p1}.T,dat.isoP{p1}.h,T); val2=myi(dat.isoP{p1+1}.T,dat.isoP{p1+1}.h,T); %[kJ/kg] Enthalpy
            case 's', val1=myi(dat.isoP{p1}.T,dat.isoP{p1}.s,T); val2=myi(dat.isoP{p1+1}.T,dat.isoP{p1+1}.s,T); %[kJ/kgK] Entropy
            case 'c'
                switch prop(2)
                    case 'v', val1=myi(dat.isoP{p1}.T,dat.isoP{p1}.cv,T); val2=myi(dat.isoP{p1+1}.T,dat.isoP{p1+1}.cv,T); %[kJ/kgK] Specific heat coefficient constant volume
                    case 'p', val1=myi(dat.isoP{p1}.T,dat.isoP{p1}.cp,T); val2=myi(dat.isoP{p1+1}.T,dat.isoP{p1+1}.cp,T); %[kJ/kgK] Specific heat coefficient constant pressure
                end
            case 'a', val1=myi(dat.isoP{p1}.T,dat.isoP{p1}.a,T); val2=myi(dat.isoP{p1+1}.T,dat.isoP{p1+1}.a,T); %[m/s] Sound speed
            case 'm', val1=myi(dat.isoP{p1}.T,dat.isoP{p1}.mu,T); val2=myi(dat.isoP{p1+1}.T,dat.isoP{p1+1}.mu,T); %[uPa*s] Viscosity
            case 'r', val1=myi(dat.isoP{p1}.T,dat.isoP{p1}.r,T); val2=myi(dat.isoP{p1+1}.T,dat.isoP{p1+1}.r,T); %[kg/m^3] Density
            case 'k', val1=myi(dat.isoP{p1}.T,dat.isoP{p1}.k,T); val2=myi(dat.isoP{p1+1}.T,dat.isoP{p1+1}.k,T); %[W/mK] Thermal Conductivity     
        end
        % to account for the bell curve if requesting a value too close to
        % saturation
        if T >= dat.Tsat(1) && T <= dat.Tsat(end)
            psat = NFP(varargin{1},"psat_t",T) ;
            if dat.isoP{p1}.P < psat && dat.isoP{p1+1}.P > psat
                if p > psat
                    ret = interp1([psat, dat.isoP{p1+1}.P(1)],[NFP("N2O",prop(1) + "l_t",T), val2],p);
                else
                    ret = interp1([dat.isoP{p1}.P(1), psat],[val1, NFP("N2O",prop(1) + "v_t",T)],p);
                end
            else
                ret = interp1([dat.isoP{p1}.P(1) dat.isoP{p1+1}.P(1)],[val1 val2],p);
            end
        else
            ret = interp1([dat.isoP{p1}.P(1) dat.isoP{p1+1}.P(1)],[val1 val2],p);
        end
        
    case {'t_ps','t_sp'}
        if prop(end) == 's'
            p=varargin{3}; 
            s=varargin{4};
        else
            s=varargin{3}; 
            p=varargin{4};
        end
        
        checkp(p);
        if (p<dat.Pcrit) 
            sl=NFP(varargin{1},'sl_p',p);
            sv=NFP(varargin{1},'sv_p',p);
            tsat=NFP(varargin{1},'tsat_p',p);
            if s>=sl && s<=sv 
                ret(1) = (s-sl)/(sv-sl);
                ret(2) = tsat;
            else
                eq=@(x) NFP(varargin{1},'s_pt',p,x)-s;
                options=optimset('Display','none');
                ret=fsolve(eq,tsat*1.1,options);
            end
        else
            eq=@(x) NFP(varargin{1},'s_pt',p,x)-s;
            options=optimset('Display','none');
            ret=fsolve(eq,dat.Tcrit*1.1,options);
        end
    case {'t_hp','t_ph'}
        if prop(end) == 'h'
            p=varargin{3}; 
            h=varargin{4};
        else
            h=varargin{3}; 
            p=varargin{4};
        end

        checkp(p);
        if (p<dat.Pcrit) 
            hl=NFP(varargin{1},'hl_p',p);
            hv=NFP(varargin{1},'hv_p',p);
            tsat=NFP(varargin{1},'tsat_p',p);
            if h>=hl && h<=hv 
                ret(1) = (h-hl)/(hv-hl);
                ret(2) = tsat;
            else
                eq=@(x) NFP(varargin{1},'h_pt',p,x)-h;
                options=optimset('Display','none');
                ret=fsolve(eq,tsat*1.1,options);
            end
        else
            eq=@(x) NFP(varargin{1},'h_pt',p,x)-h;
            options=optimset('Display','none');
            ret=fsolve(eq,dat.Tcrit*1.1,options);
        end
        
    case 'minp'
        ret=dat.isoP{1}.P;
        
    case 'maxp'
        ret=dat.isoP{end}.P;
        
    case 'mint'
        ret=dat.isoP{1}.T(1);
        
    case 'maxt'
        ret=dat.isoP{1}.T(end);
        
    otherwise
        error('Unknown input parameter');
end


    function check_satp(p) 
        if p<dat.Psat(1)            
            error(sprintf('uhh? p=%e bar is too low, min sat. pressure for %s is %e bar',p,dat.name,dat.Psat(1)));
        end
        if (p>dat.Psat(end))
            error(sprintf('uhh? p=%e bar is above %s critical pressure=%e bar',p,dat.name,dat.Psat(end)));
        end
    end

    function check_undefined_p(p)
        if p==dat.Pcrit
            error(sprintf('You cannot get the values of cv, cp and a for critical pressure'));
        end
    end

    function check_undefined_t(t)
        if t==dat.Tcrit
            error(sprintf('You cannot get the values of cv, cp and a for critical temperature'));
        end
    end

    function check_satT(T)
        if T<dat.Tsat(1)
            error(sprintf('uhh? T=%e K is too low, min sat. temp. for %s is %e K',T,dat.name,dat.Tsat(1)));
        end
        if (T>dat.Tsat(end))
            error(sprintf('uhh? T=%e K is above %s critical temperature=%e K',T,dat.name,dat.Tsat(end)));
        end
    end

    function checkp(p)
        if ( (p < (dat.isoP{1}.P(1))) || (p > (dat.isoP{end}.P(1)) ) )
            error(sprintf('uhh? P=%e out of range of %s pressure (%e to %e bar)',p,dat.name,dat.isoP{1}.P,dat.isoP{end}.P));
%             error('uhh? P out of range');
        end
    end 

    function checkT(T)
        if ( (T < (dat.isoP{1}.T(1))) || (T > (dat.isoP{1}.T(end))) )
            error(sprintf('uhh? T=%e out of range of %s temperatures (%e to %e K)',T,dat.name,dat.isoP{1}.T(1),dat.isoP{1}.T(end)));
        end
    end 

    function checkpT(P,T) 
        checkp(P);
        checkT(T);
        % Now, we will check that P and T don't match saturation conditions
        if (P>dat.Psat(end)) % supercritical
            return;
        end
        if (T>dat.Tsat(end)) % supercritical
            return;
        end
        
        if ( T<=dat.Tsat(end) )
            Psat=NFP(varargin{1},'Psat_t',T);
            if Psat==P
                error('saturation !');
            end
        end
    end 

    function i=findp(p)
        for i=1:length(dat.isoP)-1
            if ( p >= dat.isoP{i}.P(1) ) && ( p <= dat.isoP{i+1}.P(1) )
                %fprintf('asked for p=%f, found between p=%f and p=%f \n',p,dat.isoP{i}.P,dat.isoP{i+1}.P);
                return
            end
        end
        error('Outside Splendiferous Pressure Range !');
    end

    function y=myi(X,Y,x) % interpolates avoiding l-v phase change singularity
        if x<X(1)
            error('Too low: Splendiferous error');
        end
        if x>X(end)
            error('Too high: Splendiferous error');
        end        
        q=find(diff(X)==0);
        if isempty(q) 
            y=interp1(X,Y,x);
            return
        end    
        if (x<=X(q))
            y=interp1(X(1:q),Y(1:q),x);
        else
            y=interp1(X(q+1:end),Y(q+1:end),x);
        end
    end

end

function [ fname ] = osi( fname )
% Manel Soria July 2019
% operating system independent
% given a path name
% changes / to \ or viceversa, only if needed, to suit the operating system
% eg osi('a/b/c') excuted in a windows machine will return 'a\b\c'

if ismac || isunix % to unix
    fname(fname=='\')='/';
else % windows
    fname(fname=='/')='\';    
end
end