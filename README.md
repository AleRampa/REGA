# REGA v1.1
REGA (Rocket Engine Graph Analyzer) is a set of matlab functions which 
facilitate the thermodynamic analysis of a liquid rocket engine by reading its graph

UPC - ESEIAAT - A.A. 2021\2022

Author: Alessandro Rampazzo

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
