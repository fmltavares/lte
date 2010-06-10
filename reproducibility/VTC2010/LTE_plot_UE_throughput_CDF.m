clear all;
folder = './results/';
type = {'OLSM best cqi','OLSM round robin','TxD best cqi','TxD round robin'};
%type = {'OLSM round robin','TxD best cqi','TxD round robin'};
max_files = 1000;

for type_idx = 1:length(type)
    clear mean_throughput
    clear UE_pos
    clear mean_RBs
    clear files
    clear total_TB_CQIs
    
    files_ls = ls(fullfile(folder,type{type_idx},'*TTIs*.mat'));
    for file_idx = 1:size(files_ls,1)
        files{file_idx} = fullfile(folder,type{type_idx},files_ls(file_idx,:));
    end
    
    %close all;
    
    %% Load all files and process info
    load(files{1});
    
    % Geometry factor
    % geometry_factor = zeros(1,length(files)*length(UEs));
    % mean_throughput = zeros(1,length(files)*length(UEs));
    % mean_RBs        = zeros(1,length(files)*length(UEs));
    
    users_plot = figure(1);
    users_axes = gca;
    hold(users_axes,'on');
    files_to_load = min(max_files,length(files));
    total_TB_CQIs = [];
    for file_idx = 1:files_to_load
        load(files{file_idx});
        
        fprintf('Loading file %d/%d, total %d files in folder\n',file_idx,files_to_load,length(files));
        
        cell_mean_throughput(file_idx) = mean(sum(simulation_traces.eNodeB_tx_traces(5).sector_traces(1).acknowledged_data,1))./ LTE_config.TTI_length ./ 1e6;
        
        for u_=1:length(UEs)
            % In Kbps
            assigned_RBs = simulation_traces.UE_traces(u_).assigned_RBs>0;
            used_TB_CQIs = simulation_traces.UE_traces(u_).TB_CQI(assigned_RBs);
            total_TB_CQIs = [total_TB_CQIs;used_TB_CQIs];
            throughput_this_user = double(simulation_traces.UE_traces(u_).TB_size(1,:)) .* double(simulation_traces.UE_traces(u_).ACK(1,:)) ./ LTE_config.TTI_length ./ 1e3;
            mean_throughput(u_+(file_idx-1)*length(UEs)) = mean(throughput_this_user);
            UE_pos(u_+(file_idx-1)*length(UEs),:) = UEs(u_).pos;
            mean_RBs(u_+(file_idx-1)*length(UEs)) = mean(simulation_traces.UE_traces(1).assigned_RBs(1,:));
        end
    end
    scatter(users_axes,UE_pos(:,1),UE_pos(:,2),'b','.');
    title(users_axes,'UE positions');
    xlabel(users_axes,'x-position [m]');
    ylabel(users_axes,'y-position [m]');
    hold(users_axes,'off');
    
    save(sprintf('./results/CDF/%s %d_files.mat',type{type_idx},length(files)),'mean_throughput','UE_pos','mean_RBs','total_TB_CQIs','cell_mean_throughput');
    
    figure;
    cdfplot(mean_throughput);
end

% %% Post-processing
% 
% numbins = 9;
% geom_factors     = zeros(1,numbins-1);
% geom_throughputs = zeros(1,numbins-1);
% 
% bins = linspace(min(geometry_factor),max(geometry_factor),numbins+2);
% bins = bins(2:end-1);
% for geom_factor_idx = 1:length(bins)-1
%     minimum = bins(geom_factor_idx);
%     maximum = bins(geom_factor_idx+1);
%     
%     geom_factors(geom_factor_idx)     = mean([minimum maximum]);
% end
% 
% for geom_factor_idx = 1:length(bins)-1
%     minimum = bins(geom_factor_idx);
%     if geom_factor_idx==1
%         minimum = min(geometry_factor);
%     end
%     maximum = bins(geom_factor_idx+1);
%     if geom_factor_idx==(length(bins)-1)
%         maximum = Inf;
%     end
%     
%     values_idx = (geometry_factor>=minimum)&(geometry_factor<maximum);
%     geom_throughputs(geom_factor_idx) = mean(mean_throughput(values_idx));
% end
% 
% figure;
% title('UE throughput, 5 MHz, 20 UEs per sector');
% xlabel('geometry factor [dB]');
% ylabel('throughput [kB]');
% plot(geom_factors,geom_throughputs);
% 
% % Throughput CDF
% figure;
% cdfplot(mean_throughput);
% 
% % RB ass CDF
% figure;
% cdfplot(mean_RBs);
