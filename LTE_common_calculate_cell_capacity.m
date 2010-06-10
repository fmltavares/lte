function [ sector_capacity SINR_dB_target_sector ] = LTE_common_calculate_cell_capacity(networkPathlossMap,eNodeBs,CQI_mapper,varargin)
% Calculates average cell capacity based on the system settings and returns
% the cdf of the SINR for the target sector and cell (the same, just that smoother)
% (c) Josep Colom Ikuno, INTHFT, 2008
% www.nt.tuwien.ac.at

global LTE_config;

if length(varargin)>0
    shadow_fading_used = true;
    networkShadowFadingMap = varargin{1};
else
    shadow_fading_used = false;
end

if length(varargin)>1
    real_data = varargin{2};
else
    real_data = false;
end

if shadow_fading_used
    print_log(1,sprintf('Calculating average sector capacity (macroscopic and shadow fading)\n'));
else
    print_log(1,sprintf('Calculating average sector capacity (macroscopic fading)\n'));
end

%% Preallocate for the SINR matrices
target_sector = 1;
num_eNodeBs = length(eNodeBs);
num_sectors = 3;

% Look for the eNodeB closer to the center (0,0) and store the eNodeBs'
% pixel position (for plotting purposes)
closest_distance = 10000;
target_cell = 5;
eNodeB_pixel_pos = zeros(num_eNodeBs,2);
RX_powers_W = zeros(size(networkPathlossMap.pathloss));
for b_ = 1:num_eNodeBs
    eNodeB_pixel_pos(b_,:) = LTE_common_pos_to_pixel(eNodeBs(b_).pos,networkPathlossMap.coordinate_origin,networkPathlossMap.data_res);
    distance = sqrt(eNodeBs(b_).pos(1)^2+eNodeBs(b_).pos(2)^2);
    if distance<closest_distance
        closest_distance = distance;
        target_cell = b_;
    end
    
    % Matrix containing the received power
    if shadow_fading_used
        shadow_fading_new_map_size   = [size(networkPathlossMap.pathloss,1) size(networkPathlossMap.pathloss,2)];
        shadow_fading_current_eNodeB = 10.^(imresize(networkShadowFadingMap.pathloss(:,:,b_),shadow_fading_new_map_size)/10);
    else
        shadow_fading_current_eNodeB = 1;
    end
    for s_ = 1:num_sectors
        RX_powers_W(:,:,s_,b_) = eNodeBs(b_).sectors(s_).max_power./10.^(networkPathlossMap.pathloss(:,:,s_,b_)/10) ./ shadow_fading_current_eNodeB;
    end
end

% Create list of pixels belonging to this sector and the sector edges
if shadow_fading_used
    sector_assignment = networkPathlossMap.sector_assignment;
else
    sector_assignment = networkPathlossMap.sector_assignment_no_shadowing;
end
sector_map_all = uint16(10*sector_assignment(:,:,2)+sector_assignment(:,:,1));
all_edges = edge(sector_map_all,'sobel',0);
target_cell_area              = (sector_assignment(:,:,2)==target_cell);
target_sector_area            = (sector_assignment(:,:,1)==target_sector) & target_cell_area;
target_sector_size            = sum(sum(target_sector_area));
target_sector_area_edges      = edge(uint8(target_sector_area));
target_sector_area_edges_list = zeros(sum(sum(target_sector_area_edges)),2);
all_edges_list                = zeros(sum(sum(all_edges)),2);
[target_sector_area_edges_list(:,2) target_sector_area_edges_list(:,1)] = find(target_sector_area_edges);
[all_edges_list(:,2)                all_edges_list(:,1)]                = find(all_edges);

target_sector_area_edges_list_pos = LTE_common_pixel_to_pos(target_sector_area_edges_list,networkPathlossMap.coordinate_origin,networkPathlossMap.data_res);
all_edges_list_pos                = LTE_common_pixel_to_pos(all_edges_list,networkPathlossMap.coordinate_origin,networkPathlossMap.data_res);

% Create list of all the pixels
roi_width_pixels = size(networkPathlossMap.pathloss,2);
roi_height_pixels = size(networkPathlossMap.pathloss,1);
position_grid_pixels = zeros(roi_height_pixels*roi_width_pixels,2);
position_grid_pixels(:,1) = reshape(repmat(1:roi_width_pixels,roi_height_pixels,1),1,roi_width_pixels*roi_height_pixels);
position_grid_pixels(:,2) = repmat(1:roi_height_pixels,1,roi_width_pixels);
position_grid_meters = LTE_common_pixel_to_pos(position_grid_pixels,networkPathlossMap.coordinate_origin,networkPathlossMap.data_res);

%% Calculate SINR map for all sectors
SINR_linear_all = zeros(size(RX_powers_W));
thermal_noise_W = 10^(LTE_config.UE.thermal_noise_density/10) / 1000 * LTE_config.bandwidth * 10^(LTE_config.UE.receiver_noise_figure/10);

for b_=1:num_eNodeBs
    for s_=1:num_sectors
        interf_eNodeBs = [1:(b_-1) (b_+1):num_eNodeBs];
        interf_sectors = [1:(s_-1) (s_+1):num_sectors];
        
        SINR_linear_all(:,:,s_,b_) = RX_powers_W(:,:,s_,b_) ./ (sum(sum(RX_powers_W,4),3) + thermal_noise_W - RX_powers_W(:,:,s_,b_));
    end
end
SINR_dB_all = 10*log10(SINR_linear_all);

% Calculate the matrix needed to show the SINR difference map
SINR_dB_all_sorted = reshape(SINR_dB_all,size(SINR_dB_all,1),size(SINR_dB_all,2),[]);
SINR_dB_all_sorted = sort(SINR_dB_all_sorted,3);

max_SINR_dB_all  = SINR_dB_all_sorted(:,:,end);
diff_SINR_dB_all = SINR_dB_all_sorted(:,:,end)-SINR_dB_all_sorted(:,:,end-1);

SINR_linear = SINR_linear_all(:,:,target_sector,target_cell);
SINR_dB     = SINR_dB_all(:,:,target_sector,target_cell);
SINR_linear_target_sector = SINR_linear(target_sector_area);
SINR_dB_target_sector     = SINR_dB(target_sector_area);     % You can use these two values to get a cdf of the cell/sector SINR
SINR_dB_target_cell       = max_SINR_dB_all(target_cell_area);

%% Calculate average capacity (finally!!!)
bandwidth = LTE_config.N_RB*LTE_config.RB_bandwidth;
CP_length_s = LTE_config.CP_length_samples/LTE_config.fs;
symbol_length_s = LTE_config.TTI_length/(LTE_config.N_sym*2);
CP_ratio = 1-(CP_length_s/symbol_length_s);

nTXantennas = 1;
subcarriers_per_RB = 12;
switch nTXantennas
    case 1
        nRef_sym = 4;
    case 2
        nRef_sym = 8;
    case 4
        nRef_sym = 12;
end
subframe_size_Sym = LTE_config.N_sym*subcarriers_per_RB*2*LTE_config.N_RB;       % 2 for 2 slots (2x0.5 ms)

RefSym_ratio = 1-(nRef_sym / (LTE_config.N_sym*subcarriers_per_RB*nTXantennas)); % Ratio of reference_symbols/total_subframe_symbols
SyncSym_ratio = 1-(72 / (subframe_size_Sym*5)); % 72 symbols used for sync every 5 subframes

% Integrate over all of the target cell area (sum). Apply correction factors for used bandwidth, Cyclic Prefix and reference/sync symbols.
sector_avg_capacity_bps = bandwidth/target_sector_size*CP_ratio*RefSym_ratio*SyncSym_ratio*sum(log2(1+SINR_linear_target_sector));
sector_min_capacity_bps = bandwidth*CP_ratio*RefSym_ratio*SyncSym_ratio*min(log2(1+SINR_linear_target_sector));
sector_max_capacity_bps = bandwidth*CP_ratio*RefSym_ratio*SyncSym_ratio*max(log2(1+SINR_linear_target_sector));

sector_avg_capacity_mbps = sector_avg_capacity_bps / 1e6;
sector_min_capacity_mbps = sector_min_capacity_bps / 1e6;
sector_max_capacity_mbps = sector_max_capacity_bps / 1e6;

sector_capacity.avg_mbps = sector_avg_capacity_mbps;
sector_capacity.min_mbps = sector_min_capacity_mbps;
sector_capacity.max_mbps = sector_max_capacity_mbps;

%% Begin plotting
if LTE_config.show_network>0
    if shadow_fading_used
        figure(LTE_config.plots.sector_SINR);
    else
        figure(LTE_config.plots.sector_SINR_no_shadowing);
    end
    
    % Plot SINR (target sector)
    % subplot(2,2,1);
    % imagesc(networkPathlossMap.roi_x,networkPathlossMap.roi_y,SINR_dB);
    % set(gca,'YDir','normal');
    % if shadow_fading_used
    %     title(sprintf('Target sector SINR (macroscopic and shadow fading). Average capacity: %3.2f Mbps, %s pathloss',sector_avg_capacity_bps/1e6,networkPathlossMap.name));
    % else
    %     title(sprintf('Target sector SINR (macroscopic fading). Average capacity: %3.2f Mbps, %s pathloss',sector_avg_capacity_bps/1e6,networkPathlossMap.name));
    % end
    % colorbar;
    % caxis([-10 max(SINR_dB(:))]);
    % xlabel('x pos [m]');
    % ylabel('y pos [m]');
    % hold on;
    %
    % % Plot target sector boundary
    % scatter(target_sector_area_edges_list_pos(:,1),target_sector_area_edges_list_pos(:,2),'.','MarkerEdgeColor','w','SizeData', 1);
    %
    % % Plot where the BTs are and add a text legend to know where are the BTSs
    % for b_ = 1:length(eNodeBs)
    %     scatter(eNodeBs(b_).pos(1),eNodeBs(b_).pos(2),'MarkerEdgeColor','w','MarkerFaceColor','w');
    %     text(eNodeBs(b_).pos(1)+7*networkPathlossMap.data_res,eNodeBs(b_).pos(2),num2str(b_),'Color','w');
    % end
    
    % Plot difference between max and 2nd strongest SINR (visualizes cell edge)
    subplot(2,2,3);
    caxis_max = 10;
    imagesc(networkPathlossMap.roi_x,networkPathlossMap.roi_y,diff_SINR_dB_all);
    set(gca,'YDir','normal');
    if shadow_fading_used
        title(sprintf('SINR difference (macroscopic and shadow fading). caxis limited to %ddB',caxis_max));
    else
        title(sprintf('SINR difference (macroscopic fading). caxis limited to %ddB',caxis_max));
    end
    colorbar;
    caxis([0 caxis_max]);
    xlabel('x pos [m]');
    ylabel('y pos [m]');
    hold on;
    
    % Plot where the BTs are and add a text legend to know where are the BTSs
    for b_ = 1:length(eNodeBs)
        scatter(eNodeBs(b_).pos(1),eNodeBs(b_).pos(2),'MarkerEdgeColor','w','MarkerFaceColor','w');
        text(eNodeBs(b_).pos(1)+7*networkPathlossMap.data_res,eNodeBs(b_).pos(2),num2str(b_),'Color','w');
    end
    
    
    %% Plot CQIs
    subplot(2,2,2);
    imagesc(networkPathlossMap.roi_x,networkPathlossMap.roi_y,CQI_mapper.SINR_to_CQI(SINR_dB));
    set(gca,'YDir','normal');
    if shadow_fading_used
        title('Target sector CQIs (macroscopic and shadow fading).');
    else
        title('Target sector CQIs (macroscopic fading).');
    end
    colorbar('YTick',0:15);
    hold on;
    
    % Plot target sector boundary
    scatter(target_sector_area_edges_list_pos(:,1),target_sector_area_edges_list_pos(:,2),'.','MarkerEdgeColor','w','SizeData', 1);
    
    % Plot where the BTs are and add a text legend to know where are the BTSs
    for b_ = 1:length(eNodeBs)
        scatter(eNodeBs(b_).pos(1),eNodeBs(b_).pos(2),'MarkerEdgeColor','k','MarkerFaceColor','w');
        if b_==target_cell
            text(eNodeBs(b_).pos(1)+7*networkPathlossMap.data_res,eNodeBs(b_).pos(2),num2str(b_),'Color','w');
        end
    end
    
    % Zoom in to just the center eNodeB, sector 1 (just for the case where no
    % shadow fading is used or if explicitly stated)
    if ~shadow_fading_used && ~real_data
        edge_pos_max  = [ max(target_sector_area_edges_list_pos(:,1)) max(target_sector_area_edges_list_pos(:,2)) ];
        edge_pos_min  = [ min(target_sector_area_edges_list_pos(:,1)) min(target_sector_area_edges_list_pos(:,2)) ];
        diff_edge_pos = abs(edge_pos_max - edge_pos_min);
        xlim([edge_pos_min(1) edge_pos_max(1)]+0.25*diff_edge_pos(1)*[-1 1]);
        ylim([edge_pos_min(2) edge_pos_max(2)]+0.25*diff_edge_pos(2)*[-1 1]);
    end
    xlabel('x pos [m]');
    ylabel('y pos [m]');
    
    %% Plot SINR (all sectors)
    subplot(2,2,1);
    imagesc(networkPathlossMap.roi_x,networkPathlossMap.roi_y,max_SINR_dB_all);
    set(gca,'YDir','normal');
    if shadow_fading_used
        title(sprintf('ROI max SINR (SISO, macroscopic and shadow fading)'));
    else
        title(sprintf('ROI max SINR (SISO, macroscopic fading)'));
    end
    colorbar;
    caxis([-7 17]);
    xlabel('x pos [m]');
    ylabel('y pos [m]');
    hold on;
    
    % Plot target sector boundary
    if ~shadow_fading_used && ~real_data
        scatter(all_edges_list_pos(:,1),all_edges_list_pos(:,2),'.','MarkerEdgeColor','w','SizeData', 1);
    end
    
    % Plot where the BTs are and add a text legend to know where are the BTSs
    for b_ = 1:length(eNodeBs)
        scatter(eNodeBs(b_).pos(1),eNodeBs(b_).pos(2),'MarkerEdgeColor','k','MarkerFaceColor','w');
        text(eNodeBs(b_).pos(1)+7*networkPathlossMap.data_res,eNodeBs(b_).pos(2),num2str(b_),'Color','k');
    end
    
    % Plot the sector boundaries
    plot_only_edges = false;
    %figure(LTE_config.plots.sector_assignment_no_shadowing);
    subplot(2,2,4);
    if shadow_fading_used
        sector_map_to_plot = uint16(10*networkPathlossMap.sector_assignment(:,:,2)+networkPathlossMap.sector_assignment(:,:,1));
    else
        sector_map_to_plot = uint16(10*networkPathlossMap.sector_assignment_no_shadowing(:,:,2)+networkPathlossMap.sector_assignment_no_shadowing(:,:,1));
    end
    if plot_only_edges
        sector_map_to_plot = double(edge(sector_map_to_plot,'sobel',0))*0.4;
    end
    imagesc(networkPathlossMap.roi_x,networkPathlossMap.roi_y,sector_map_to_plot);
    set(gca,'YDir','normal');
    if shadow_fading_used
        title(sprintf('Cell and sector assignment (macroscopic and shadow fading)'));
    else
        title(sprintf('Cell and sector assignment (macroscopic fading)'));
    end
    if plot_only_edges
        the_colormap = [1,1,1;0.984126984126984,0.984126984126984,0.984126984126984;0.968253968253968,0.968253968253968,0.968253968253968;0.952380952380952,0.952380952380952,0.952380952380952;0.936507936507937,0.936507936507937,0.936507936507937;0.920634920634921,0.920634920634921,0.920634920634921;0.904761904761905,0.904761904761905,0.904761904761905;0.888888888888889,0.888888888888889,0.888888888888889;0.873015873015873,0.873015873015873,0.873015873015873;0.857142857142857,0.857142857142857,0.857142857142857;0.841269841269841,0.841269841269841,0.841269841269841;0.825396825396825,0.825396825396825,0.825396825396825;0.809523809523810,0.809523809523810,0.809523809523810;0.793650793650794,0.793650793650794,0.793650793650794;0.777777777777778,0.777777777777778,0.777777777777778;0.761904761904762,0.761904761904762,0.761904761904762;0.746031746031746,0.746031746031746,0.746031746031746;0.730158730158730,0.730158730158730,0.730158730158730;0.714285714285714,0.714285714285714,0.714285714285714;0.698412698412698,0.698412698412698,0.698412698412698;0.682539682539683,0.682539682539683,0.682539682539683;0.666666666666667,0.666666666666667,0.666666666666667;0.650793650793651,0.650793650793651,0.650793650793651;0.634920634920635,0.634920634920635,0.634920634920635;0.619047619047619,0.619047619047619,0.619047619047619;0.603174603174603,0.603174603174603,0.603174603174603;0.587301587301587,0.587301587301587,0.587301587301587;0.571428571428571,0.571428571428571,0.571428571428571;0.555555555555556,0.555555555555556,0.555555555555556;0.539682539682540,0.539682539682540,0.539682539682540;0.523809523809524,0.523809523809524,0.523809523809524;0.507936507936508,0.507936507936508,0.507936507936508;0.492063492063492,0.492063492063492,0.492063492063492;0.476190476190476,0.476190476190476,0.476190476190476;0.460317460317460,0.460317460317460,0.460317460317460;0.444444444444444,0.444444444444444,0.444444444444444;0.428571428571429,0.428571428571429,0.428571428571429;0.412698412698413,0.412698412698413,0.412698412698413;0.396825396825397,0.396825396825397,0.396825396825397;0.380952380952381,0.380952380952381,0.380952380952381;0.365079365079365,0.365079365079365,0.365079365079365;0.349206349206349,0.349206349206349,0.349206349206349;0.333333333333333,0.333333333333333,0.333333333333333;0.317460317460317,0.317460317460317,0.317460317460317;0.301587301587302,0.301587301587302,0.301587301587302;0.285714285714286,0.285714285714286,0.285714285714286;0.269841269841270,0.269841269841270,0.269841269841270;0.253968253968254,0.253968253968254,0.253968253968254;0.238095238095238,0.238095238095238,0.238095238095238;0.222222222222222,0.222222222222222,0.222222222222222;0.206349206349206,0.206349206349206,0.206349206349206;0.190476190476190,0.190476190476190,0.190476190476190;0.174603174603175,0.174603174603175,0.174603174603175;0.158730158730159,0.158730158730159,0.158730158730159;0.142857142857143,0.142857142857143,0.142857142857143;0.126984126984127,0.126984126984127,0.126984126984127;0.111111111111111,0.111111111111111,0.111111111111111;0.0952380952380952,0.0952380952380952,0.0952380952380952;0.0793650793650794,0.0793650793650794,0.0793650793650794;0.0634920634920635,0.0634920634920635,0.0634920634920635;0.0476190476190476,0.0476190476190476,0.0476190476190476;0.0317460317460317,0.0317460317460317,0.0317460317460317;0.0158730158730159,0.0158730158730159,0.0158730158730159;0,0,0;];
        colormap(the_colormap);
        caxis([0 1]);
    else
        colormap('jet');
        colorbar;
    end
    hold on;
    
    % Plot where the BTs are and add a text legend to know where are the BTSs
    for b_ = 1:length(eNodeBs)
        eNodeB_pixel_pos(b_,:) = LTE_common_pos_to_pixel(eNodeBs(b_).pos,networkPathlossMap.coordinate_origin,networkPathlossMap.data_res);
        scatter(eNodeBs(b_).pos(1),eNodeBs(b_).pos(2),'MarkerEdgeColor','k','MarkerFaceColor','w');
        text(eNodeBs(b_).pos(1)+6*networkPathlossMap.data_res,eNodeBs(b_).pos(2),num2str(b_));
    end
    xlabel('x pos [m]');
    ylabel('y pos [m]');
end
