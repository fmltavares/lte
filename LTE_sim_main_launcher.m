close all;
clc;
clear;
clear global;
% clear classes;

%% Load parameters. Now done outside
LTE_load_params;
print_log(1,'Loaded configuration file\n');
LTE_sim_main;
