# REGA v1.1
REGA (Rocket Engine Graph Analyzer) is a set of matlab functions which 
facilitate the thermodynamic analysis of a liquid rocket engine by reading its graph

UPC - ESEIAAT - A.A. 2021\2022

Author: Alessandro Rampazzo

## Why REGA

Have you ever wondered how on earth rocket scientits understand liquid rocket engine graphs like the one below?

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

Colors have been added to the lines to represent which fluids is meant to pass through them at nominal operative conditions. Note that each line is labelled with a different ascending number starting from 1 as is every component (in this case before the number the name of the component is added). Be sure that there are no typos since the software will read the numbers and the names you gave to the elements and will understand how to beahve. Every block you gave the same name will be treated as the same class of components. For example Turbine 1 and Turbine 2 will call the same function once the code meets them.

The only thing left to do is to export the graph in a .tgf format

P.S. At the current version closed cycles are not implemented, since it would mean a jump in complexity and require time that currently I don't have :(
At the moment closed loop cycles can be dealt by simply breaking the cycle and putting an input and output block next to each other (as it happens in the right side of the graph on the LOX feed line). Tank pressurization are also handled in this way. The only downside is that for this method to work at least one state in the loop must be known a priori.

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
  - results is a struct with arbitrary numerical fields which can be used to output some informations (power of turbines, efficiencies, etc) if they are not explicitly available at input level. REGA will take care of printing these results in the command window once the anslysis is completed.

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

While for regular blocks a parameter definition example is this:

    % Type       Component number       p ratio            eta
     Pump               1               29.1633            0.7

It must be noted that the line with the % is only for informations purpuses since the software will skip it and read the following as type - component number - params (vector)

To use REGA you must:

- build your graph using for example yEd Graph Editor. Be aware that every
  line needs a unique ID number and every block needs a name and a
  component number. Save the file in .tgf format.

- define the specification for every block (except output blocks) in the
  input file. Every input block (tanks for example) needs to specify the
  state exiting the block, while other components only need extra
  parameters (like pressure ratio, efficiency, etc.) a line could be like
  the one below:

% Type       Component number      mdot [kg/s]      pressure [bar]   temperature [K]     density [kg/m^3]     composition

  Tank              1                93.677              3                21                  70.220              H2

  Or for example:

% Type       Component number       p ratio            eta

  Pump              1               29.1633            0.7

  For input block one must specify the whole state with mdot, pressure,
  temperature, density and composition as a struct with the name of the
  pure substances and the relative molar fractions
  The program will read through the file and will pass a vector containing
  the input states and the parameters specified in the input file in the
  order they were given to the relative function associated to the block

- Specify the names of the blocks, the nickname and the associated function
  as suggested from the command ">> help REGA"

- Define the functions related to every block type by creating a matlab 
  function that takes as inputs: 
  * (state1,params) if the inputs are 1     
  * ([state1,state2,...,stateN],params) if the inputs are > 1 (first 
    argument is a struct array)
  * (state1,nExit,params) if it's a splitter block that takes 1 input

  the function must output [state_exit,results], where state_exit should be
  the exit state (or the exit state related to the nExit-th exit if it is a
  splitter block. However at the moment only splitters with 2 output are
  implemented) and results is a struct with whatever variable you want, for
  example pump block can output the power in this way:

results.power = <calculated_power>;

The program will take care of printing the results correctly

Be aware that states in all the functions are structs with these fields:
- mdot (double) [kg/s]
- p (double) [bar]
- T (double) [K]
- rho (double) [kg/m^3]
- composition (struct containing the following fields:
  - species (string array of the chemical species present in the mixture)
  - n (molar fractions) 

This program works well with NFP and HGS from ManelSoria/INIST and ManelSoria/HGS

Note: loops are not implemented yet. A way to avoid the problem is to break
the loop at some point with an "Out" block and a "KnownState" block, where
the loop ends and start respectively. "KnownState" block is equivalent to a
"Tank" block

Note2: splitter blocks choose as first output state the one with the
smallest ID number associated to the state 

If you find bugs or errors please submit them

Thank you for your time reading this <3
