# REGA
REGA (Rocket Engine Graph Analyzer) is a set of matlab function which 
facilitate the thermodynamic analysis of a rocket engine by reading its graph

UPC - ESEIAAT - A.A. 2021\2022

Author:

          .o.       oooo                                                          oo8                    
         .888.      `888                                                         .888                    
        .8"888.      888   .ooooo.   .oooo.o  .oooo.o  .oooo.   ooo. .oo.    .oooo888  oooo d8b  .ooooo. 
       .8' `888.     888  d88' `88b d88(  "8 d88(  "8 `P  )88b  `888P"Y88b  d88' `888  `888"8P  d88' `88b
      .88ooo8888.    888  888ooo888 `"Y88b.  `"Y88b.   .oP"888   888   888  888   888   888     888   888
     .8'     `888.   888  888    .o o.  )88b o.  )88b d8(  888   888   888  888   888   888     888   888
    o88o     o8888o o888o `Y8bod8P'  8"888P'  8"888P' `Y888"8o  o888o o888o `Y8bod88P" d888b    `Y8bod8P'

    ooooooooo.                                                                                    
    `888   `Y88.                                                                                  
     888   .d88'  .oooo.   ooo. .oo.  .oo.   oo.ooooo.   .oooo.     oooooooo   oooooooo  .ooooo. 
     888ooo88P'  `P  )88b  `888P"Y88bP"Y88b   888' `88b `P  )88b   d'"7d8P    d'"7d8P   d88' `88b
     888`88b.     .oP"888   888   888   888   888   888  .oP"888    .d8P'      .d8P'    888   888
     888  `88b.  d8(  888   888   888   888   888   888 d8(  888   .d8P'  .P  .d8P'  .P 888   888
    o888o  o888o `Y888"8o  o888o o888o o888o  888bod8P' `Y888"8o d8888888P  d8888888P   `Y8bod8P'
                                              888                                                 
                                             o888o  

To use REGA you must:

- build your graph using for example yEd Graph Editor. Be aware that every
  line needs a unique ID number and every block needs a name and a
  component number. Save the file in .tgf format.

- define the specification for every block (except output blocks) in the
  input file. Every input block (tanks for example) needs to specify the
  state exiting the block, while other components only need extra
  parameters (like pressure ratio, efficiency, etc.) a line could be like
  the one below:

% Type       Component number     mdot [kg/s]      pressure [bar]   temperature [K]     density [kg/m^3]     composition

  Tank              1               93.677              3                21                  70.220              H2

  Or for example:

% Type       Component number      p ratio            eta

  Pump              1              29.1633            0.7

  For input block one must specify the whole state with mdot, pressure,
  temperature, density and composition as the name of the substance (only 
  pure substances are allowed for now)
  The program will read through the file and will pass a vector containing
  the specified parameters in the order they were given in the input file
  to the relative function associated to the block 

- Specify the names of the blocks, the nickname and the associated function
  as suggested from the command >> help REGA

- Define the functions related to every block type by creating a matlab 
  function that takes as inputs: 
    o (state1,params) if the inputs are 1     
    o (state1,state2,params) if the inputs are 2 
    o (state1,nExit,params) if it's a splitter block which takes 1 input

  the function must output [state2,results], where state2 should be the
  exit state (or the exit state related to the nExit-th exit if it is a
  splitter block) and results is a struct with whatever variable you want,
  for example pump block can output the power in this way:

results.power = <calculated_power>;

The program will take care of printing the results correctly

Be aware that states in all the functions are struct with these fields:
- mdot (double) [kg/s]
- p (double) [bar]
- T (double) [K]
- rho (double) [kg/m^3]
- composition (n(string) x 2(double) matrix with the first column being a
  vector of string of the species inside the mixture and the second column
  being the molar fractions of each species)


If you find bugs or errors please submit them

Thank you for your time reading this <3
