# REGA v1.1
REGA (Rocket Engine Graph Analyzer) is a set of matlab functions which 
facilitate the thermodynamic analysis of a liquid rocket engine by reading its graph

UPC - ESEIAAT - A.A. 2021\2022

Author: Alessandro Rampazzo

## Why REGA

Have you ever wondered how on earth rocket scientits understand nightmarish liquid rocket engine graphs like the one below?

![image](https://user-images.githubusercontent.com/90860412/228917424-7bbd1781-2086-456e-a021-8204c1d61ca4.png)
<sup><sub>Image from NASA: https://gandalfddi.z19.web.core.windows.net/Shuttle/SSME_MPS_Info/KSC-SSME_System_Eng_Handbook.pdf</sub></sup>

Well, me too, and I'm one of them. The image above is the flow diagram of the RS-25, also know as the SSME or Space Shuttle Main Engine (now you recall huh) and it would be definetly a pain (and definetely has been) to thermodynamically analyze it from top to bottom.

Fortunately REGA is here! This set of Matlab function reduce the analysis of such engines to drawing a graph, write some functions for the individual components and define some input variable in a text file. Let's step through the passages to get this things working

## The graph

The above diagram is definetly too detailed and complicated to analyze directly and there are many unnecessary fluidic lines that are not fundamental to capture the thermodynamics of the engine such as hydraulic, purge and dump lines.

For this reason we simplify the diagram taking only the most important components, the one that play a significant role in determining the steady state condition of the system. We end up with something like this:

![image](https://user-images.githubusercontent.com/90860412/228891989-ed66f4f8-ecb5-4750-a26e-e823fd7ceff4.png)
<sup><sub>Image from Herbertz, Armin. "Component Modeling for Rocket Engine Cycle Analysis." Transactions of the Japan Society for Aeronautical and Space Sciences, Aerospace Technology Japan 14. 2016</sub></sup>

The image above is clearly still complex (the global thermodynamic variables of the fluid in each region don't help), but much cleaner than the original one.

Actually one can build a diagram in a graph software (yEd for example) representing the simplified engine like this:

![image](https://user-images.githubusercontent.com/90860412/228922523-b8ef0664-a389-4aee-b4e7-fde5faeba80e.png)

Colors have been added to the lines to represent which fluids is meant to pass through them at nominal operative conditions. Note that each line is labelled with a different ascending number starting from 1 as is every component (in this case before the number the name of the component is added). Be sure that there are no typos since the software will read the numbers and the names you gave to the elements and will understand how to behave. Every block you gave the same name will be treated as the same class of components. For example Turbine 1 and Turbine 2 will call the same function once the code meets them.

The only thing left to do is to export the graph in a .tgf format

P.S. At the current version closed cycles are not implemented, since it would mean a jump in complexity and would require time that I currently don't have :(
At the moment closed loops can be dealt by simply breaking the cycle and putting an input and output block next to each other (as it happens in the right side of the graph on the blue LOX feed line). Tank pressurization are also handled in this way. The only downside is that for this method to work at least one state in the loop must be known a priori.

## Matlab functions

Before talking about the function themselves, we need to understand how the thermodynamic variables are assigned. Every line in the graph has a state associated with it, which in Matlab is implemented as a struct with the following fields:

- mdot (double) [kg/s]
- p (double) [bar]
- T (double) [K]
- rho (double) [kg/m^3]
- composition (struct containing the following fields):
  - species (string array of the chemical species present in the mixture)
  - n (molar fractions) 
  
Given this, every block can recieve as many states as you specify in the graph (by terminating a line on it) and output at most two states (by starting a line from it. future version will implement unlimited output states).

the template for a function is the following:

    function [stateOut,results] = CustomBlock(statesIn,nExit,params)
      ...
    end
    
Where:
  - statesIn is a state or a list of states (struct list) given as inputs to the function (the number of inputs, as said before, is determined by the topology of the graph)
  - nExit is a number from 1 to 2 (in the current version) which represents which one of the exiting line is requested. The code always goes for the lines with the smallest number first, so in case of a Splitter 1 in the graph above, nExit = 1 will be linked to line 5 and nExit = 2 to line 15
  - params is a vector containing the parameters of the specific block in the given order as written in the input.txt file (see below)
  - stateOut is the computed requested output state. The output state MUST have all the field input states have.
  - results is a struct with arbitrary numerical fields which can be used to output some informations (power of turbines, efficiencies, etc) if they are not explicitly available at input level. REGA will take care of printing these results in the command window once the analysis is completed.

## Input file

The input file specifies the actual parameters (params variable) of every block.

There are three types of blocks:
- input blocks
- regular blocks
- output blocks

Starting from the easiest, output blocks state the end of a path and do not need any specifications or parameters.
Input blocks (such as KnownState or Tank blocks in the SSME diagram) must befine the entire state as follows:

    % Type       Component number      mdot [kg/s]      pressure [bar]   temperature [K]     density [kg/m^3]     composition
     Tank               1                93.677              3                21                  70.220              H2

REGA classifies them as input block because no line terminates on them (the same but reversed for output blocks)

While for regular blocks a parameter definition example is this:

    % Type       Component number       p ratio            eta
     Pump               1               29.1633            0.7

It must be noted that the line with the % is only for informations purpuses since the software will skip it and read the following as type - component number - params (vector) (in future version the params input could be changed to a struct with the corresponding fields specified in the input file)

## Linking all toghether

To link blocks and functions toghether, as well as specify the input file, the following bit of code is needed:

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

Where we define the component information in a data structures like above (first column is the EXACT name of the component in the graph, second a nickname and third the handle to the function associated with the block), specify the input and graph file and then call REGA with everything.
Blocks and states are list of all computed blocks and states, while travelledBlocks is a ordered lists of all the blocks REGA has passed through or requested states with all the parameters and calculated results. In addition it prints a summary of all the states and blocks to give a rapid feedback on the computation

Now press run and enjoy automatic rocket engine graph calculations :)

This project relies on NFP and HGS from ManeSoria/INIST and ManelSoria/HGS

## Output

An example of output is the following:

    Starting traversing the graph...

    Travelled nodes:
    1: Tnk 1
    2: H2_Pmp 1
    3: H2_Pmp 2
    4: Vlv 1
    5: Spl 1
    6: Spl 2
    7: Vlv 2
    8: Mix 1
    9: Spl 2
    10: H2_HeEx 1
    11: Mix 1
    12: Spl 3
    13: Vlv 3
    14: H2_PreB 1
    15: Spl 3
    16: Vlv 4
    17: O2_PreB 1
    18: Spl 1
    19: H2_HeEx 2
    20: H2_Trb 1
    21: Spl 4
    22: Vlv 5
    23: Out 2
    24: Spl 4
    25: Spl 5
    26: Vlv 6
    27: Mix 2
    28: Spl 5
    29: Spl 6
    30: Vlv 8
    31: CombC 1
    32: Spl 6
    33: Vlv 9
    34: Tnk 2
    35: O2_Pmp 1
    36: KnSt 1
    37: Mix 6
    38: O2_Pmp 2
    39: Spl 7
    40: O2_Trb 1
    41: Out 4
    42: Spl 7
    43: Spl 8
    44: O2_HeEx 1
    45: Vlv 13
    46: Out 3
    47: Spl 8
    48: Spl 9
    49: O2_Pmp 3
    50: Spl 10
    51: Vlv 14
    52: Vlv 15
    53: O2_PreB 1
    54: O2_Trb 2
    55: O2_HeEx 2
    56: Mix 5
    57: Vlv 12
    58: CombC 1
    59: Spl 10
    60: Vlv 16
    61: Vlv 17
    62: H2_PreB 1
    63: H2_Trb 2
    64: Mix 2
    65: Vlv 7
    66: CombC 1
    67: Spl 9
    68: Vlv 10
    69: Vlv 11
    70: CombC 1
    71: CoNzl 1
    72: DiNzl 1
    73: Out 1

    States:

      state ID     from        to      mdot [kg/s]   p [bar]     T [K]     rho [kg/m^3]   composition   n frac[mol]
      ________   ________   ________   ___________   _______   _________   ____________   ___________   ___________

         1        Tnk 1     H2_Pmp 1     73.220       2.070      20.600       70.570           H2           1.000
         2       H2_Pmp 1   H2_Pmp 2     73.220       19.500     22.756       70.496           H2           1.000
         3       H2_Pmp 2    Vlv 1       73.220      486.490     57.309       80.257           H2           1.000
         4        Vlv 1      Spl 1       73.220      463.324     59.066       78.404           H2           1.000
         5        Spl 1      Spl 2       57.760      463.324     59.066       78.404           H2           1.000
         6        Spl 2      Vlv 2       28.880      463.324     59.066       78.404           H2           1.000
         7        Vlv 2      Mix 1       28.880      431.401     61.402       75.829           H2           1.000
         8        Spl 2    H2_HeEx 1     28.880      463.324     59.066       78.404           H2           1.000
         9      H2_HeEx 1    Mix 1       28.880      431.401    258.126       30.873           H2           1.000
         10       Mix 1      Spl 3       57.760      431.400    164.338       43.442           H2           1.000
         11       Spl 3      Vlv 3       37.820      431.400    164.338       43.442           H2           1.000
         12       Vlv 3    H2_PreB 1     37.820      391.470    165.741       40.679           H2           1.000
         13       Spl 3      Vlv 4       19.940      431.400    164.338       43.442           H2           1.000
         14       Vlv 4    O2_PreB 1     19.940      387.253    165.873       40.342           H2           1.000
         15       Spl 1    H2_HeEx 2     15.460      463.324     59.066       78.404           H2           1.000
         16     H2_HeEx 2   H2_Trb 1     15.460      345.506    253.140       26.409           H2           1.000
         17      H2_Trb 1    Spl 4       15.460      261.371    244.891       21.740           H2           1.000
         18       Spl 4      Vlv 5       0.350       261.371    244.891       21.740           H2           1.000
         19       Vlv 5      Out 2       0.350        3.510     252.130       0.337            H2           1.000
         20       Spl 4      Spl 5       15.110      261.371    244.891       21.740           H2           1.000
         21       Spl 5      Vlv 6       1.899       261.371    244.891       21.740           H2           1.000
         22       Vlv 6      Mix 2       1.899       248.216    245.340       20.805           H2           1.000
         23       Spl 5      Spl 6       13.211      261.371    244.891       21.740           H2           1.000
         24       Spl 6      Vlv 8       12.742      261.371    244.891       21.740           H2           1.000
         25       Vlv 8     CombC 1      12.742      230.486    245.932       19.502           H2           1.000
         26       Spl 6      Vlv 9       0.470       261.371    244.891       21.740           H2           1.000
         27       Vlv 9      Mix 5       0.470       248.216    245.340       20.805           H2           1.000
         28       Tnk 2     O2_Pmp 1    439.340       6.890      91.100      1137.990          O2           1.000
         29      O2_Pmp 1    Mix 6      439.340       29.700     92.264      1137.331          O2           1.000
         30       KnSt 1     Mix 6       83.060       29.700    107.800      1056.870          O2           1.000
         31       Mix 6     O2_Pmp 2    522.400       29.700     94.771      1124.948          O2           1.000
         32      O2_Pmp 2    Spl 7      522.400      330.350    108.908      1127.760          O2           1.000
         33       Spl 7     O2_Trb 1     83.061      330.350    108.908      1127.760          O2           1.000
         34      O2_Trb 1    Out 4       83.061       29.700    107.791      1056.861          O2           1.000
         35       Spl 7      Spl 8      439.339      330.350    108.908      1127.760          O2           1.000
         36       Spl 8    O2_HeEx 1     0.750       330.350    108.908      1127.760          O2           1.000
         37     O2_HeEx 1    Vlv 13      0.750       285.523    507.719      199.720           O2           1.000
         38       Vlv 13     Out 3       0.750        2.490     493.905       1.939            O2           1.000
         39       Spl 8      Spl 9      438.589      330.350    108.908      1127.760          O2           1.000
         40       Spl 9     O2_Pmp 3     50.457      330.350    108.908      1127.760          O2           1.000
         41      O2_Pmp 3    Spl 10      50.457      558.721    116.757      1141.462          O2           1.000
         42       Spl 10     Vlv 14      13.559      558.721    116.757      1141.462          O2           1.000
         43       Vlv 14     Vlv 15      13.559      472.691    119.882      1114.634          O2           1.000
         44       Vlv 15   O2_PreB 1     13.559      387.452    122.807      1085.737          O2           1.000
         45       Spl 10     Vlv 16      36.898      558.721    116.757      1141.462          O2           1.000
         46       Vlv 16     Vlv 17      36.898      485.422    119.435      1118.813          O2           1.000
         47       Vlv 17   H2_PreB 1     36.898      391.470    122.677      1087.206          O2           1.000
         48       Spl 9      Vlv 10     388.132      330.350    108.908      1127.760          O2           1.000
         49       Vlv 10     Vlv 11     388.132      284.050    110.486      1111.944          O2           1.000
         50       Vlv 11    CombC 1     388.132      230.373    112.209      1092.245          O2           1.000
         51     H2_PreB 1   H2_Trb 2     74.718      391.470    1105.359      16.965           H            0.000
                                                                                               H2           0.877
                                                                                              H2O           0.123
                                                                                              H2O2          0.000
                                                                                               O            0.000
                                                                                               O2           0.000
                                                                                               OH           0.000
         52      H2_Trb 2    Mix 2       74.718      248.206    1008.706      11.787           H            0.000
                                                                                               H2           0.877
                                                                                              H2O           0.123
                                                                                              H2O2          0.000
                                                                                               O            0.000
                                                                                               O2           0.000
                                                                                               OH           0.000
         53       Mix 2      Vlv 7       76.617      248.210    974.574       11.510           H            0.000
                                                                                               H2           0.883
                                                                                              H2O           0.117
                                                                                              H2O2          0.000
                                                                                               O            0.000
                                                                                               O2           0.000
                                                                                               OH           0.000
         54       Vlv 7     CombC 1      76.617      230.464    973.838       11.069           H            0.000
                                                                                               H2           0.883
                                                                                              H2O           0.117
                                                                                              H2O2          0.000
                                                                                               O            0.000
                                                                                               O2           0.000
                                                                                               OH           0.000
         55     O2_PreB 1   O2_Trb 2     33.499      387.250    832.574       18.947           H            0.000
                                                                                               H2           0.914
                                                                                              H2O           0.086
                                                                                              H2O2          0.000
                                                                                               O            0.000
                                                                                               O2           0.000
                                                                                               OH           0.000
         56      O2_Trb 2  O2_HeEx 2     33.499      251.428    760.179       13.473           H            0.000
                                                                                               H2           0.914
                                                                                              H2O           0.086
                                                                                              H2O2          0.000
                                                                                               O            0.000
                                                                                               O2           0.000
                                                                                               OH           0.000
         57     O2_HeEx 2    Mix 5       33.499      248.202    758.825       13.324           H            0.000
                                                                                               H2           0.914
                                                                                              H2O           0.086
                                                                                              H2O2          0.000
                                                                                               O            0.000
                                                                                               O2           0.000
                                                                                               OH           0.000
         58       Mix 5      Vlv 12      33.969      248.210    747.295       12.911           H            0.000
                                                                                               H2           0.916
                                                                                              H2O           0.084
                                                                                              H2O2          0.000
                                                                                               O            0.000
                                                                                               O2           0.000
                                                                                               OH           0.000
         59       Vlv 12    CombC 1      33.969      230.464    745.787       12.471           H            0.000
                                                                                               H2           0.916
                                                                                              H2O           0.084
                                                                                              H2O2          0.000
                                                                                               O            0.000
                                                                                               O2           0.000
                                                                                               OH           0.000
         60      CombC 1    CoNzl 1     511.459      230.400    3636.834      10.386           H            0.026
                                                                                               H2           0.246
                                                                                              H2O           0.685
                                                                                              H2O2          0.000
                                                                                               O            0.002
                                                                                               O2           0.002
                                                                                               OH           0.038
         61      CoNzl 1    DiNzl 1     511.459      126.335    3326.653      6.226            H            0.026
                                                                                               H2           0.246
                                                                                              H2O           0.685
                                                                                              H2O2          0.000
                                                                                               O            0.002
                                                                                               O2           0.002
                                                                                               OH           0.038
         62      DiNzl 1     Out 1      511.459       0.195     1108.164      0.029            H            0.026
                                                                                               H2           0.246
                                                                                              H2O           0.685
                                                                                              H2O2          0.000
                                                                                               O            0.002
                                                                                               O2           0.002
                                                                                               OH           0.038

    Blocks:

    mdot is in [kg/s], p is in [bar], T is in [K], rho is in [kg/m^3],
    powers are in [MW] and every other quantity is in SI units

      block ID    name     comp n°      mdot         p           T          rho     composition
      ________   ______    _______     ______       ___         ___        _____   _____________

         1        Tnk        1         73.220      2.070       20.600      70.570        H2
         5        Tnk        2        439.340      6.890       91.100     1137.990       O2


      block ID    name     comp n°    param 1     param 2     param 3
      ________   ______    _______   _________   _________   _________

         2       CoNzl       1         0.000       0.259       0.977


      block ID    name     comp n°    param 1     param 2     param 3     param 4      M_exit      F_vac        F_sl      Isp_vac      Isp_sl
      ________   ______    _______   _________   _________   _________   _________    ________    _______      ______    _________    ________

         3       DiNzl       1        -140.890     77.500      2.282       0.987       4.666      2294.085    1879.740    457.225     374.644


      block ID    name     comp n°    param 1
      ________   ______    _______   _________

         6        Vlv        2         1.074
         9        Vlv        1         1.050
         16       Vlv        3         1.102
         17       Vlv        17        1.240
         18       Vlv        16        1.151
         19       Vlv        7         1.077
         23       Vlv        5         74.462
         24       Vlv        6         1.053
         26       Vlv        8         1.134
         28       Vlv        12        1.077
         39       Vlv        13       114.671
         44       Vlv        11        1.233
         45       Vlv        10        1.163
         47       Vlv        15        1.220
         48       Vlv        14        1.182
         49       Vlv        4         1.114
         50       Vlv        9         1.053


      block ID    name     comp n°    param 1     param 2      power
      ________   ______    _______   _________   _________    _______

         7       H2_Pmp      2         24.948      0.730       57.797
         8       H2_Pmp      1         9.420       0.650       2.754


      block ID    name     comp n°    param 1
      ________   ______    _______   _________

         10       Spl        1         3.736
         12       Spl        2         1.000
         14       Spl        3         1.897
         21       Spl        4         0.023
         22       Spl        5         0.144
         25       Spl        6         27.128
         35       Spl        7         0.189
         36       Spl        8         0.002
         37       Spl        9         0.130
         46       Spl        10        0.367


      block ID    name     comp n°    param 1     param 2
      ________   ______    _______   _________   _________

         11     H2_HeEx      1         1.074       93.130
         13     H2_HeEx      2         1.341       47.760


      block ID    name     comp n°    param 1     param 2      power
      ________   ______    _______   _________   _________    _______

         15      H2_Trb      2         1.577       0.780       57.778
         51      H2_Trb      1         1.322       0.520       2.675


      block ID    name     comp n°    param 1
      ________   ______    _______   _________

         20       Mix        2        248.210
         27       Mix        5        248.210
         29       Mix        1        431.400
         31       Mix        6         29.700


      block ID    name     comp n°    param 1     param 2      power
      ________   ______    _______   _________   _________    _______

         30      O2_Pmp      1         4.311       0.630       1.396
         33      O2_Pmp      2         11.123      0.670       20.499
         34      O2_Pmp      3         1.691       0.800       1.263


      block ID    name     comp n°    param 1     param 2      power
      ________   ______    _______   _________   _________    _______

         32      O2_Trb      1         11.123      0.620       1.395
         40      O2_Trb      2         1.540       0.780       21.756


      block ID    name     comp n°    param 1     param 2
      ________   ______    _______   _________   _________

         38     O2_HeEx      1         1.157       0.405
         43     O2_HeEx      2         1.013       -0.405


      block ID    name     comp n°    param 1     param 2     param 3
      ________   ______    _______   _________   _________   _________

         41     H2_PreB      1        391.470      0.000       0.995


      block ID    name     comp n°    param 1     param 2     param 3
      ________   ______    _______   _________   _________   _________

         42     O2_PreB      1        387.250      0.000       0.995


      block ID    name     comp n°      mdot         p           T          rho     composition
      ________   ______    _______     ______       ___         ___        _____   _____________

         55       KnSt       1         83.060      29.700     107.800     1056.870       O2


      block ID    name     comp n°    param 1     param 2     param 3
      ________   ______    _______   _________   _________   _________

         56      CombC       1        230.400      0.000       0.993


    Finished traversing the graph



Thank you for your time reading this
