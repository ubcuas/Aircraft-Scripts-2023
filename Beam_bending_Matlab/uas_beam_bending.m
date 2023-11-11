%%  UAS Aircraft: Beam Bending
%   Author: Lucas Pavel Rimini
%   Last Revision: 13th February 2023 by LPR


clear; clc; close; 


%   0. Is the beam tapered or not? 
tapered_or_not = input('Is the beam tapered? (y/n)', 's');

beam_mass = 0.508023; 
elastic_modulus = 227 * 10^9;   % 33msi = 227GPa

if tapered_or_not == 'y'
    %   1. Length constants:
    tapered_length = 0.8;         
    constant_length = 0;
    middle_length = 1;
    
    total_length = tapered_length + constant_length + middle_length + constant_length + tapered_length;
    pin1_position = tapered_length + constant_length;
    pin2_position = total_length - (tapered_length + constant_length);
    
    x = linspace(0, total_length, 10000);
    
    
    %   2. Material constants:
    %       OD = outer diamater 
    %       ID = inner diamater 

    constant_root_OD = 0.809*2.54/100;
    constant_root_ID = 0.765*2.54/100;
    constant_tip_OD = constant_root_OD;
    constant_tip_ID = constant_root_ID;
    constant_thickness = (constant_root_OD - constant_root_ID)/2; 
    
    tapered_root_OD = 0.809*2.54/100;
    tapered_root_ID = 0.765*2.54/100;
    tapered_tip_OD = 0.46*2.54/100;
    tapered_tip_ID = 0.415*2.54/100;
    tapered_tip_thickness = (tapered_tip_OD - tapered_tip_ID)/2;
    tapered_root_thickness = (tapered_root_OD - tapered_root_ID)/2;
    
    %       2.1 Now we create a function of the outer diameter and the thickness based on the position x along the beam 
    
    x_OD = zeros(1, length(x));
    x_thickness = zeros(1, length(x));
    
    for i = 1:length(x)
        if x(i) <= tapered_length
            x_OD(i) = x(i)/tapered_length * (tapered_root_OD - tapered_tip_OD) + tapered_tip_OD;
            x_thickness(i) = x(i)/tapered_length * (tapered_root_thickness - tapered_tip_thickness) + tapered_tip_thickness;
    
        elseif x(i) <= (total_length - tapered_length)
            x_OD(i) = constant_root_OD;
            x_thickness(i) = constant_thickness;
    
        else
            x_OD(i) = (x(i) - (total_length - tapered_length))/tapered_length * (tapered_tip_OD - tapered_root_OD) + tapered_root_OD;
            x_thickness(i) = (x(i) - (total_length - tapered_length))/tapered_length * (tapered_tip_thickness - tapered_root_thickness) + tapered_root_thickness;
        end
    end
else
    %   1. Length constants:
    length_before_pin1 = 0;
    length_after_pin2 = 0;
    total_length = 1;
    middle_length = total_length - length_after_pin2 - length_before_pin1;
    
    pin1_position = length_before_pin1;
    pin2_position = total_length - (length_after_pin2);
    
    x = linspace(0, total_length, 10000);
    
    
    %   2. Material constants:
    %       OD = outer diamater 
    %       ID = inner diamater 
    
    x_OD = (0.835*25.4)/1000;
    x_ID = (0.75*25.4)/1000;
    x_thickness = (x_OD - x_ID)/2;
end


%   3. 2nd Moment of Area
I_moa = 1/64 * pi() * (x_OD.^4 - (x_OD - 2*x_thickness).^4);


%   4. Entering point loads:
loads = [];
loads_position = [];
i = 1;
answer = input('Do you want to input a load (y/n): ', 's');

while answer == 'y'
    temp = input('Input the load force (N) and the load position w.r.t. to left most part of the wing (x = 0) in the form [ , ]: ');
    loads(i) = temp(1);
    loads_position(i) = temp(2);
    i = i + 1;
    answer = input('Do you want to input a point load? (y/n): ', 's');
end


%   5. Distributed loads from XFLR5 and weight:
filename = 'local_lift.csv';
xflr5_data = table2array(readtable(filename));
xflr5_positions = transpose(xflr5_data(:, 1));
xflr5_loads = transpose(xflr5_data(:, 2));
beam_weight_loads = ones(1, length(x)) * beam_mass * 9.81/length(x);
beam_weight_positions = x;

consider_xflr5 = input('Consider lift force? (y/n)', 's');
if consider_xflr5 == 'n'
    xflr5_positions = [];
    xflr5_loads = [];
end

consider_weight = input('Consider weight of beam? (y/n)', 's');
if consider_weight == 'n'
    beam_weight_loads = [];
    beam_weight_positions = [];
end


%   6. Shear graph: 
all_loads = cat(2, loads, xflr5_loads, beam_weight_loads);
all_positions = cat(2, loads_position, xflr5_positions, beam_weight_positions);

temporary_shear = zeros(1, length(x));
shear = zeros(1, length(x));
reaction_force_1 = zeros(1, length(all_loads));
reaction_force_2 = zeros(1, length(all_loads));


%       6.1 Calculating the reaction forces:
for i = 1:length(all_loads)
    if all_positions(i) <= pin1_position
        reaction_force_2(i) = all_loads(i) * (pin1_position - all_positions(i))/middle_length;
        reaction_force_1(i) = -all_loads(i) - reaction_force_2(i);

    else
        reaction_force_2(i) = -all_loads(i) * (all_positions(i) - pin1_position)/middle_length;
        reaction_force_1(i) = -all_loads(i) - reaction_force_2(i);
    end

end


%       6.2 Creating the individual shear forces:
for i = 1:length(all_loads)
    [intersting_positions, index] = sort([all_positions(i), pin1_position, pin2_position]);
    intersting_loads = [all_loads(i), reaction_force_1(i), reaction_force_2(i)];

    for j = 1:length(x)
        if x(j) < intersting_positions(1)
            temporary_shear(j) = 0;

        elseif x(j) < intersting_positions(2)
            temporary_shear(j) = -intersting_loads(index(1));
        
        elseif x(j) < intersting_positions(3)
            temporary_shear(j) = - (intersting_loads(index(1)) + intersting_loads(index(2)));
        
        else
            temporary_shear(j) = 0;
        end
    end
    
    shear = shear + temporary_shear;
end


%   7. Moment graph:
moment = cumtrapz(shear) * total_length/length(x);


%   8. Displacement graph:
displacement = zeros(1, length(x));

for i = 1:length(all_loads)
    [sorted_positions, index] = sort([all_positions(i), pin1_position, pin2_position]);
    unsorted_loads = [all_loads(i), reaction_force_1(i), reaction_force_2(i)];
    sorted_loads = unsorted_loads(index);

    cell_sorted_loads = num2cell(sorted_loads);
    cell_sorted_positions = num2cell(sorted_positions);

    [F1, F2, F3] = deal(cell_sorted_loads{:});
    [L1, L2, L3] = deal(cell_sorted_positions{:});
    A = F1 * L1;
    B = F1 + F2;
    
    if all_positions(i) < pin1_position
        matrix = [
            1 -1 0 0 0 0 0 0 (F1/2 * L1 ^2);
            0 1 -1 0 0 0 0 0 (-F2/2 * L2^2 + (L3*B - A) * L2);
            0 0 1 -1 0 0 0 0 (-B/2 * L3^2);
            0 L2 0 0 0 1 0 0 (F1/6 * L2^3 - A/2 * L2^2);
            0 0 L2 0 0 0 1 0 (B* (L2^3 * 1/6 - L3 * L2^2 * 1/2));
            0 0 L3 0 0 0 1 0 (-1/3 * B * L3^3);
            0 0 0 L3 0 0 0 1 0;
            L1 -L1 0 0 1 -1 0 0 (1/3 * F1 * L1^3);
            ];

        solved_matrix = rref(matrix);

    elseif all_positions(i) < pin2_position
        matrix = [
            1 -1 0 0 0 0 0 0 (F1/2 * L1 ^2);
            0 1 -1 0 0 0 0 0 (-F2/2 * L2^2 + (L3*B - A) * L2);
            0 0 1 -1 0 0 0 0 (-B/2 * L3^2);
            L1 0 0 0 1 0 0 0 0;
            0 L1 0 0 0 1 0 0 (-1/3 * F1 * L1^3);
            0 0 L3 0 0 0 1 0 (-1/3 * B * L3^3);
            0 0 0 L3 0 0 0 1 0;
            0 L2 -L2 0 0 1 -1 0 (-1/6 * F2* L2^3 + (L3 * B - A) * 1/2 * L2^2);
            ];

        solved_matrix = rref(matrix);

    else
        matrix = [
            1 -1 0 0 0 0 0 0 (F1/2 * L1 ^2);
            0 1 -1 0 0 0 0 0 (-F2/2 * L2^2 + (L3*B - A) * L2);
            0 0 1 -1 0 0 0 0 (-B/2 * L3^2);
            L1 0 0 0 1 0 0 0 0;
            0 L1 0 0 0 1 0 0 (-1/3 * F1 * L1^3);
            0 L2 0 0 0 1 0 0 (1/6 * F1 * L2^3 - 1/2 * A * L2^2);
            0 0 L2 0 0 0 1 0 (B * (1/6 * L2^3 - 1/2 * L3 * L2^2));
            0 0 L3 -L3 0 0 1 -1 (-1/3 * B * L3^3)
            ];

        solved_matrix = rref(matrix);

    end

    solved_constants = num2cell(solved_matrix(:, end));
    [C0, C1, C2, C3, K0, K1, K2, K3] = deal(solved_constants{:});
    
    %   Here we find the displacement caused by the individual load with the constants solved above
    for j = 1:length(x)
        
        if x(j) < L1
            displacement(j) = displacement(j) + (C0 * x(j) + K0);
     
        elseif x(j) < L2
            displacement(j) = displacement(j) + (-1/6 * F1 * x(j)^3 + A/2 * x(j)^2 + C1*x(j) + K1);

        elseif x(j) < L3
            displacement(j) = displacement(j) + (-1/6 * B * x(j)^3 + L3/2 * B *x(j)^2 + C2*x(j) + K2);

        else
            displacement(j) = displacement(j) + (C3 * x(j) + K3);
        
        end
    end
end

displacement = displacement .* 1./(elastic_modulus .* I_moa);


%   9. Stress: 
stress = moment ./ I_moa .* -x_OD/2 * 10^-9;


%   10. Plotting:
subplot(2, 2, 1);
plot(x, shear, 'LineWidth', 3);
grid on;
xlabel('x Position (m)');
ylabel('Shear (N)');
title('Shear graph');

subplot(2, 2, 2);
plot(x, moment, 'LineWidth', 3);
grid on;
xlabel('x Position (m)');
ylabel('Moment (Nm)');
title('Moment graph');

subplot(2, 2, 3);
plot(x, stress, 'LineWidth', 3);
grid on;
xlabel('x Position (m)');
ylabel('Stress 10^9 (GPa)');
title('Stress graph');

subplot(2, 2, 4);
plot(x, displacement, 'LineWidth', 3);
grid on;
xlabel('x Position (m)');
ylabel('Displacement (m)');
title('Displacement graph');

disp(['The max displacement is: ', num2str(max(abs(displacement))*1000), ' mm']);
disp(['The max sterss is: ', num2str(max(abs(stress))*1000), ' MPa']);
