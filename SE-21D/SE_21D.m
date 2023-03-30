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
    "Pump","Pmp",@Pump;
    "Splitter","Spl",@Splitter;
    "Valve","Vlv",@Valve;
    "HeatExchanger","HeEx",@HeatExchanger_B;
    "Turbine","Trb",@Turbine;   
    "Mixer","Mix",@Mixer;
    "CombustionChamber","CombC",@CombustionChamber;
    "ConvergentNozzle","CoNzl",@ConvergentNozzle_A;
    "DivergentNozzle","DiNzl",@DivergentNozzle_A};

% input file
iFileName = "SE-21D_InputData.txt";

% graph file
gFileName = "SE-21D.tgf";

[blocks,states,travelledBlocks] = REGA(gFileName,iFileName,compInfo);



