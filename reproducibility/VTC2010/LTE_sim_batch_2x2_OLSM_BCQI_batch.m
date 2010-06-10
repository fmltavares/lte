close all;
clc;
clear;
clear global;
global simulation_number;

for simulation_number=1:200
    close all;
    clc;
    clear;
    clear global LTE_config;
    global simulation_number;
    % Load parameters
    LTE_load_params_2x2_OLSM_BCQI;
    print_log(1,'Loaded configuration file\n');
    LTE_sim_main
end
