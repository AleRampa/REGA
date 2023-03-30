clc
clear
close all

addpath("../")
addpath("../functions")
addpath("../HGS-main")
addpath("../NFP-main")

% To run the script you need:
% - .tgf file of the graph
% - .txt file of the input parameters
% - set of functions for every block

% associating name of the block to nickname and function
compInfo = {...
    "Tank","Tnk",0;
    "Out","Out",0;
    "KnownState","KnSt",0;
    "H2_Pump","H2_Pmp",@Pump;
    "O2_Pump","O2_Pmp",@Pump;
    "Splitter","Spl",@Splitter;
    "Valve","Vlv",@Valve;
    "H2_HeatExchanger","H2_HeEx",@HeatExchanger_A;
    "O2_HeatExchanger","O2_HeEx",@HeatExchanger_A;
    "H2_Turbine","H2_Trb",@Turbine;
    "O2_Turbine","O2_Trb",@Turbine;
    "ConvergentNozzle","CoNzl",@ConvergentNozzle_A;
    "DivergentNozzle","DiNzl",@DivergentNozzle_A;   
    "Mixer","Mix",@Mixer;
    "H2_Preburner","H2_PreB",@CombustionChamber;
    "O2_Preburner","O2_PreB",@CombustionChamber;
    "CombustionChamber","CombC",@CombustionChamber};

% input file
iFileName = "SSME_InputData.txt";

% graph file
gFileName = "SSME.tgf";

[blocks,states,travelledBlocks] = REGA(gFileName,iFileName,compInfo);



