% example of REGA

clc
clear
close all

compInfo = {...
    "Tank","Tnk",0;
    "Out","Out",0;
    "Pump","Pmp",@Pump;
    "Splitter","Spl",@Splitter;
    "Valve","Vlv",@Valve;
    "HeatExchanger","HeEx",@HeatExchanger;
    "Turbine","Trb",@Turbine;
    "ConvergentNozzle","CoNzl",@ConvergentNozzle;
    "DivergentNozzle","DiNzl",@DivergentNozzle;
    "Mixer","Mix",@Mixer;
    "CombustionChamber","CombC",@CombustionChamber};

iFileName = "SE-21D_inputData.txt";
gFileName = "SE-21D.tgf";

[blocks,states,travelledBlocks] = REGA(gFileName,iFileName,compInfo,...
    "logtravellednodes",true,"logblocks",true,"logstates",true);

