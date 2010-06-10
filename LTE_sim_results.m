% Makes some plots with the traces resulting from the LTE SL simulation
% The results are stored in the simulation_traces variable
%
% (c) Josep Colom Ikuno, INTHFT, 2009

print_log(1,'Closing all open figures\n');

close all;
%clear all;
%load results_tests;

print_log(1,'Plotting results\n');

%% Plot GUI showing the available macroscopic pathlosses
LTE_GUI_pathloss_antenna_info;

CQI_15_params = LTE_common_get_CQI_params(15);

%% Maximum bitrate according to the efficiency (bits/Hz) for CQI 15 and not taking into account pilot overhead
% Change this!
max_bitrate = LTE_config.sym_per_RB * CQI_15_params.modulation_order * LTE_config.N_RB / 0.5e-3;

%% Plot end state of the network at the end of the simulation
LTE_plot_show_network(eNodeBs,UEs,LTE_config.map_resolution,networkClock.current_TTI);

%% Plot the eNodeBs' positions and write some output statistics
figure;
clf;
hold on;
text_shifting = 2.5;
text_interline = 4;
for b_=1:length(eNodeBs)
    % Plot a line that tells where the antennas are pointing
    vector_length = 40;
    origin = eNodeBs(b_).pos;
    for s_=1:length(eNodeBs(b_).sectors)
        angle = eNodeBs(b_).sectors(s_).azimuth;
        vector = vector_length*[ cosd(angle) sind(angle) ];
        destiny = vector + origin;

        plot([origin(1) destiny(1)],[origin(2) destiny(2)]);
    end
    % Plot the eNodeBs
    scatter(eNodeBs(b_).pos(1),eNodeBs(b_).pos(2),'Marker','o','MarkerFaceColor','red','MarkerEdgeColor','black');
    text(eNodeBs(b_).pos(1)+15*text_shifting,eNodeBs(b_).pos(2)+15*text_interline,['eNodeB ' num2str(eNodeBs(b_).id)]);
end

xlim(xlim.*[1 1.8]);
ylim(ylim*1.4);
title(sprintf('Network BLER and throughput using %d MHz bandwidth, %3.2f Mbps maximum ',LTE_config.bandwidth/1000000,max_bitrate/1000000));
xlabel('x pos [m]');
ylabel('y pos [m]');

%% Plot the throughput and BLER
num_streams = size(simulation_traces.eNodeB_rx_feedback_traces.ACK,1);
for b_ = 1:length(eNodeBs)
    for s_ = 1:length(eNodeBs(b_).sectors)
        eNodeB_idx = eNodeBs(b_).id;
        sector_idx = s_;
        stream_num = 1;

        sent_data = double(simulation_traces.eNodeB_tx_traces(eNodeB_idx).sector_traces(sector_idx).sent_data(:));
        acknowledged_data = double(simulation_traces.eNodeB_tx_traces(eNodeB_idx).sector_traces(sector_idx).acknowledged_data(:));
        received_ACKs = sum(double(simulation_traces.eNodeB_tx_traces(eNodeB_idx).sector_traces(sector_idx).received_ACKs(:)));
        expected_ACKs = sum(double(simulation_traces.eNodeB_tx_traces(eNodeB_idx).sector_traces(sector_idx).expected_ACKs(:)));
        missing_ACKs  = expected_ACKs - received_ACKs;
        avg_BLER = missing_ACKs ./ expected_ACKs;
        avg_throughput = sum(acknowledged_data)/(LTE_config.simulation_time_tti*LTE_config.TTI_length);
        
        % Data to write to the plot
        sector_output_to_plot = sprintf('S%d, %3.2f, %3.2f Mbps',sector_idx,avg_BLER,avg_throughput/1e6);
        % Add data to the plot
        text(eNodeBs(b_).pos(1)+15*text_shifting,eNodeBs(b_).pos(2)-15*text_interline*(s_-1),sector_output_to_plot,...
            'FontSize',8,...
            'FontName','Arial');
    end
end

%% Lauch UE_trace GUI
LTE_GUI_show_UE_traces(LTE_config,simulation_traces,eNodeBs,UEs);
pause(2);

%% Plot RB grid UE assignment
LTE_GUI_show_cell_traces(LTE_config,simulation_traces,eNodeBs,UEs);
