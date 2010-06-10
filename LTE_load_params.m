% Load the LTE System Level Simulator config parameters
% (c) Josep Colom Ikuno, INTHFT, 2008
% www.nt.tuwien.ac.at

global LTE_config;

%% Debug options
LTE_config.debug_level = 1;  % 0=no output
                             % 1=basic output
                             % 2=extended output
                             
%% Plotting options
LTE_config.show_network = 1; % 0= show no plots
                             % 1= show some plots
                             % 2= show ALL plots (moving UEs)
                             % 3=plot even all of the pregenerated fast fading

%% General options
LTE_config.frequency       = 2e9;           % Frequency in Hz
LTE_config.bandwidth       = 5e6;           % Frequency in Hz

LTE_config.UEs_only_in_target_sector = true;% Whether you want UEs to be places on the whole ROI or only in the target sector
LTE_config.target_sector = 'center';        % 'auto' for specifying the target sector to be the center one
                                            % a [eNodeB_id sector_id] vector otherwise
LTE_config.nTX           = 2;
LTE_config.nRX           = 2;
LTE_config.tx_mode       = 3;

%% Random number generation options
LTE_config.seedRandStream = false;
LTE_config.RandStreamSeed = 0;      % Only used if the latter is set to 'true'

%% Simulation time
LTE_config.simulation_time_tti = 1000; % Simulation time in TTIs

LTE_config.latency_time_scale = 25;   % Number of TTIs used to calculate the average throughput (exponential filtering)
                                      % See: P. Viswanath, D. Tse and R. Laroia, "Opportunistic Beamforming using Dumb Antennas", IEEE Transactions on Information Theory, vol. 48(6), June, 2002.

%% Cache options. Saves the generated eNodeBs, Pathloss map and Shadow fading map to a .mat file
LTE_config.cache_network = true;
LTE_config.network_cache = 'auto';
LTE_config.delete_ff_trace_at_end = true; % Reduces the amount needed to store the traces by deleting the fading parameters trace from the results file
LTE_config.UE_cache      = true;  % Option to save the user position to a file. This works in the following way:
                                  %   - cache=true and file exists: read position from file
                                  %   - cache=true and file does not exist: create UEs and save to cache
                                  %   - cache=false: do not use cache at all
LTE_config.UE_cache_file = 'auto';
% LTE_config.UE_cache_file = fullfile('./data_files/UE_cache_1rings_target_sector_only_1UEs_sector_20091013_101909.mat');

%% How to generate the network. If the map is loaded, this parameters will be overridden by the loaded map
LTE_config.network_source = 'generated';

% Configure the network source. Overridden if a pregenerated network pathloss map is used.
switch LTE_config.network_source
    case 'generated'
        % Network size
        LTE_config.inter_eNodeB_distance = 500; % In meters. When the network is generated, this determines the
                                                % distance between the eNodeBs.
        LTE_config.map_resolution = 5; % In meters/pixel. Also the resolution used for initial user creation
        LTE_config.nr_eNodeB_rings = 1; % Number of eNodeB rings
        LTE_config.minimum_coupling_loss = 70; % Minimum Coupling Loss: the parameter describing the minimum 
                                               % loss in signal [dB] between BS and UE or UE and UE in the worst 
                                               % case and is defined as the minimum distance loss including 
                                               % antenna gains measured between antenna connectors.
                                               % Recommended in TS 36.942 are 70 dB for urban areas, 80 dB for rural.                                              % is 

        % Models to choose
        % Available are:
        %  'free space': (more something for testing purposes than to really use it...)
        %  'cost231'
        %  'TS36942': Recommended by TS 36.942, subclause 4.5
        %  'TS25814': Recommended by TS 25.814 (Annex). The same as in HSDPA
        LTE_config.macroscopic_pathloss_model = 'TS25814';
        
        % Additional pathloss model configuration parameters. Will depend on which model is chosen.
        % Available options are:
        %  'urban_micro' (COST231)
        %  'urban_macro' (COST231)
        %  'suburban_macro' (COST231)
        %  'urban' (TS36942)
        %  'rural' (TS36942)
        LTE_config.macroscopic_pathloss_model_settings.environment = '';
        
        % eNodeB settings
        LTE_config.eNodeB_tx_power = 20; % eNodeB's transmit poower, in Watts.
                                         % Recommended by TS.36.814 are:
                                         % 43 dBm for 1.25, 5 MHz carrier
                                         % 46/49 dBm for 10, 20 MHz carrier
        
    % Add here cases for other sources (eg. netowrk planning tools)
    otherwise
        error([LTE_config.network_source ' network source not supported']);
end

%% Generation of the shadow fading
LTE_config.shadow_fading_type = 'claussen'; % Right now only 2D space-correlated shadow fading maps implemented

% Configure the network source
switch LTE_config.shadow_fading_type
    case 'claussen'
        LTE_config.shadow_fading_map_resolution = 5; % Recommended value for 8 neighbors
        LTE_config.shadow_fading_n_neighbors    = 8; % Either 4 or 8
        LTE_config.shadow_fading_mean           = 0;
        LTE_config.shadow_fading_sd             = 10;
        LTE_config.r_eNodeBs                    = 0.5; % inter-site shadow fading correlation
    otherwise
        error([LTE_config.shadow_fading_type ' shadow fading type not supported']);
end

%% Microscale Fading Generation config
% Microscale fading trace to be used between the eNodeB and its attached UEs.
LTE_config.use_fast_fading                = true;
LTE_config.channel_model.type = 'PedB'; % 'PedB' 'extPedB' --> the PDP to use
LTE_config.channel_model.trace_length = 15; % Length of the trace in seconds. Be wary of the size you choose, as it will be loaded in memory.
LTE_config.pregenerated_ff_file           = 'auto';
LTE_config.pregenerated_ff_file           = fullfile('./data_files','ff_30.0s_2x2_PedB_5.0MHz_5Kmph_20100205_121257.mat');
%LTE_config.pregenerated_ff_file           = fullfile('./data_files','ff_1.0s_2x2_PedB_5.0MHz_5Kmph_20091009_164702.mat');

% With this option set to 'true', even if cache is present, the channel trace will be recalculated
LTE_config.recalculate_fast_fading = false;

%% UE (users) settings
% note that for reducing trace sizes, the UE_id is stored as a uint16, so
% up to 65535 users in total are supported. To change that, modify the scheduler class.
LTE_config.UE.receiver_noise_figure = 9;    % Receiver noise figure in dB
LTE_config.UE.thermal_noise_density = -174; % Thermal noise density in dBm/Hz
LTE_config.UE_per_eNodeB = 20;    % number of users per eNodeB sector
LTE_config.UE_speed      = 5/3.6; % Speed at which the UEs move. In meters/second: 5 Km/h = 1.38 m/s

%% eNodeB options
% LTE_config.antenna.antenna_gain_pattern = 'berger';
LTE_config.antenna.antenna_gain_pattern = 'TS 36.942'; % As defined in TS 36.942. Identical to Berger, but with a 65° 3dB lobe

% LTE_config.antenna.mean_antenna_gain = 14; % For a berger antenna
% LTE_config.antenna.mean_antenna_gain = 15; % LTE antenna, rural area (900 MHz)
LTE_config.antenna.mean_antenna_gain = 15; % LTE antenna, urban area (2000 MHz)
% LTE_config.antenna.mean_antenna_gain = 12; % LTE antenna, urban area (900 MHz)

%% Scheduler options
LTE_config.scheduler        = 'proportional fair';  % 'round robin', 'best cqi' or 'proportional fair'
% LTE_config.scheduler_params.alpha = 1;          % Additional configuration parameters for the scheduler (defau
% LTE_config.scheduler_params.beta  = 1;
LTE_config.power_allocation = 'homogeneous;'; % 'right now no power loading is implemented, so just leave it as 'homogeneous'



%% Uplink channel options
LTE_config.feedback_channel_delay = 3; % In TTIs
LTE_config.unquantized_CQI_feedback = false;

%% SINR averaging options
LTE_config.SINR_averaging.algorithm = 'MIESM';
LTE_config.SINR_averaging.BICM_capacity_tables = 'data_files/BICM_capacity_tables_5000_realizations.mat';
%LTE_config.SINR_averaging.algorithm = 'EESM';
%LTE_config.SINR_averaging.MCSs      = [0  1  2    3   4    5   6    7    8    9    10   11   12   13   14   15];
%LTE_config.SINR_averaging.betas     = [1  1  1.44 1.4 1.48 1.5 1.62 3.10 4.32 5.37 7.71 15.5 19.6 24.7 27.6 28];
                                                               
%% Where to save the results
LTE_config.results_folder         = './results';
LTE_config.results_file           = 'auto'; % NOTE: 'auto' assigns a filename automatically

%% Whether to store some extra data or not
LTE_config.traces_config.trace_SINR            = false;
LTE_config.traces_config.trace_geometry_factor = false;

%% Values that should not be changed
LTE_config.RB_bandwidth    = 180e3;         % Frequency in Hz
LTE_config.TTI_length      = 1e-3;          % Length of a TTI (subframe), in seconds.
LTE_config.cyclic_prefix   = 'normal';      % 'normal' or 'extended' cyclic prefix
LTE_config.maxStreams      = 2;             % Maximum number of codewords per TTI. For LTE, that's 2.
                                            % Took the name from HSDPA. In
                                            % the LTE standard is actually referred as 'codewords'

LTE_load_params_dependant;
