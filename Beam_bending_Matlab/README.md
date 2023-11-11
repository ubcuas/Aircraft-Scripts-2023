# Beam-Bending-Simulation

UAS - Aircraft\
Lucas Pavel Rimini \
4th February 2023

Updated: 18th February 2023 by LPR


## 1. Simulating Beam Bending
This MATLAB script calculates the shear, moment, stress, and displacement of a loaded beam supported by two pins. 

### 1.1 Motivation:
The motivation behind this project was to create a tool to help spec booms and spars for current and future projects. 

### 1.2 User-inputted Parameters: 
This MATLAB script **only** works for a beam supported by **two pins**. The list below shows  parameters or details that can be changed: 
* Taper or no taper 
* Inner and outer radius
    * For a tapered boom the root and tip radii are required 
* Elastic modulus 
* Length of the beam 
* Positions of the pins
* *XFLR5* lift force data with respect to position
    * Data is inputted in *local_lift.csv*
* Point loads and their position

### 1.3 Functionality: 
The following list outlines how to use the program. 
1. Find a possible beam online and extract the relevant information from ***1.2 User-inputted Parameters:***
2. Update  *local_lift.csv* 
3. Update the value of the variables in MATLAB
4. Run the code
5. Choose between a taper/non-tapered boom 
6. If applicable, enter point loads and their position relative to `x = 0` on the left most end of the beam
7. Analyze shear, moment, and displacement graphs


If you wish to find max displacement use:
``` matlab
max(abs(displacement))
```


## 2. Understanding the Script 
The following section explains the different sections of this *MATLAB* script. The script is divided into the following sections:

1. Length constants 
2. Material constants
3. 2nd Moment of area
4. Entering point loads
5. Distributed loads from *XFLR5* and weight
6. Shear graph 
7. Moment graph 
8. Displacement graph 
9. Stress
10. Plotting 

(Section 0 is a simple user input for tapered/non-tapered)

### 2.1 Length constants:
There are two *Section 1*, one for tapered and one for non-tapered booms. This section specifies the length of the beam and the pin positions. 

#### **Tapered booms:**
The variables below are specified by the user: 
- `tapered_length` is the tapered length of the beam
- `constant_length` is the length of constant radius before the first pin joint
- `middle_length` is the beam length between the pins 

The variables `total_length`, `pin1_position`, and `pin2_position` are calculated by assuming the beam is symmetrical. 

`x` is the variable used to iterate across the beam. 

#### **Non-tapered booms:**
For a non-tapered boom it is enough to specify `length_before_pin1` and `length_after_pin2` and the pin positions are calculated using symmetry. 

### 2.2 Material constants: 
Material constants include finding functions for the outer diameter and the thickness. 

#### **Tapered booms:**
Tapered booms are made from two sections; a tapered and a non-tapered section. 

Variables that define the non-tapered section begin with "`constant_`" and variables relating to the tapered section begin with "`tapered_`". The "`root`" is the larger end (radius wise) of the beam and the "`tip`" is the smaller one. 

The variable `x_OD` and `x_thickness` are arrays and are calculated using linear interpolations to account for the varying outer diameter and thickness from tip to root. 

#### **Non-tapered booms:**
Non-tapered booms have constant outer diameter (`x_OD`) and thickness (`x_thickness`). 

### 2.3 2nd Moment of area:
The 2nd Moment of area (`I_moa`) is calculated by vectorization. The equation below shows how the equation is derived (this is not from the script):

$$ 
I_{xx} = \frac{1}{4}\pi(r_{out}^4 - r_{in}^4) \\

I_{xx} = \frac{1}{4}\pi \cdot \frac{1}{16}(D^4 - (D-2\cdot t)^4)\\

I_{xx} = \frac{1}{64}\pi(D^4 - (D-2\cdot t)^4)
$$
``` matlab
I_moa = 1/64 * pi() * (diameter^4 - (diameter - 2 * thickness)^4)
```
### 2.4 Entering point loads:
This section allows the user to input point loads along the beam. These load-position pairs will be stored in two arrays that will be accessed later in section "6. Shear graph". 

To enter load-positions pairs a simple while loop is used and new entries are appended to the end of `loads` and `loads_position`. 


### 2.5 Distributed loads from XFLR5 and weight: 
The user has the ability to ignore lift data (in the case of a spar) and weight. As of 4th of February 2023, the distributed weight section has **NOT** been reviewed. 

The `local_lift.csv` should be a two column table with headers (which will be ignored). Ensure that the position is zeroed at the left most end of the beam or the code will not work. Also ensure that the lift force is appropriately calculated. XFLR5 will give you the coefficeint of lift which you will need to convert using the following equation. 

$$
C_L = \frac{2L}{\rho v^2A}
$$

### 2.6 Shear graph: 
This section calculates the shear along the whole beam. To perform this calculation, the assumption of superposition is used to calculate the shear caused by each individual load. 

The following sign convention is used:
- Down is positive 
- Up is negative

The variable `all_loads` is formed by concatenating all of the possible loads: point loads, xflr5 loads, and beam weight loads. `all_positions` is also a concatenation of the position of each load. 

#### **Calculating reaction forces:**
To find the reaction forces at the two pins we will do a sum of forces in the vertical direction and a moment balance about the first pin. Therefore, we consider two cases:
1. The force F is before the first pin, or
2. The force F is after the first pin. 

Based on where the force F is, we can calculate the reaction force at the two pins and store it in the arrays `reaction_force_1` and `reaction_force_2`. 


#### **Calculating individual shear forces:**
In this section we take advantage of superposition and calculate the shear force alone the beam caused by each individual force in `all_loads`. However, we have three forces (the load F, the reaction force at pin 1, and the reaction force at pin 2) and we don't know the order in which come starting from the left. To solve this problem we `sort()` the three positions into a new array called `interesting_positions`. The sort function also gives us the "index" which we can use to sort the forces in the same way as the position. The following if statement creates a `temporary_shear` caused by this individual force which will be added to `shear` where we store the total. 


### 2.7 Moment graph: 
The moment graph can be obtained by calculating the area underneath the shear graph. To do this, I used `cumtrapz()`.


### 2.8 Displacement graph:
The difficulty in this section boils down to the boundary conditions. The beam is supported by two pin joints and therefore the displacement at these two points is zero. However, we can only make use of this information after we integrate the equation for the moment graph (obtained by integrating the shear graph) twice. The more challenging bit is that the shear is a discontinous function thereby making the moment graph a piece-wise defined function. Each piece has to be integrated separetely and then continuity has to be satisfied at the point between two pieces. This constrains introduce 8 constants of integration. 

Similarly to section "2.6 Shear graph:", we have to sort our loads and positions from left to right. Next, I had to convert the arrays into cells because the function `deal()` has cells as its input parameters. There's no real difference between `sorted_loads` and `cell_sorted_loads`. To simplify the code, I labelled the three forces `F1`, `F2`, and `F3` occuring at `L1`, `L2`, and `L3`. These variables are general on purpose because they `F1` could be any of the three forces on the beam. The variables `A` and `B` are created simply for convenience. What follows is three 8x8 matrices that depending on the location of the first occuring force calculate the constants of integration which are needed to find the displacement of the beam. With the constants, we can now find the displacement of the beam from this loading configuration and use superposition once again to obtain the total displacement of the beam at each point. 


### 2.9 Stress: 
The stress in the beam is found with the following equation. 
$$
\frac{\sigma}{y}= \frac{M}{I_{xx}}
$$


## 3. Advice and Improvements
### Advice:
If I were to give advice it would be the following:
1. Try to understand the problem as well as possible. Make sure that the your understand clearly what is asked of you. In particular understand what loading conditions are possible. 
2. Ask for help. Once you understand the problem, be upfront and ask for help from others who have done beam bending in the past and ask for their advice in solving the problem. When I asked for help, I managed to reduce my system from 14 equations to 8 which is significant. 
3. Once you have an idea of how to solve the problem, propose it to your lead. Don't spend time coding something that will not solve the problem. Make sure that they understand how your code will run, and most importantly the limitations of your code. Investing lots of time in designing before building will reduce the risk of you wasting your time. 
4. Write notes as you go in an organized manner. You will forget what your code does within seconds of you not paying attention so right down notes. 
5. Name your variables properly - readability is very important. 
6. Give yourself a large window to code. To give some context, I rewrote this script three times before I was happy with it. Beam bending is a critical aspect of any drones and it's important that any computational tool is written with care. I highly recommend you to give yourself a large window of time in which you can be in a flow state because breaking this problem up in multiple sessions might make you double guess all that you wrote before. 


### Improvements:
1. Check and implement the distributed weight of the beam
2. Include commented conversions from MSI to GPa
3. Create an csv file from which the script reads values such as: ID, OD, elastic modulus, length... for many different beams and then performs all calculations and outputs a file showing all the data to make comparisons easy and fast 
4. Although I have checked this code several times with online calculators, I recommend you check it as well to have some peace of mind
5. Given a loading condition and material, optimize by minimizing displacement and beam mass (possibly a for loop)