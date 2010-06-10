function [eNodeBs networkMacroscopicPathlossMap] = LTE_init_generate_network
% Generate an hexagonal network with a free space pathloss model
% (c) Josep Colom Ikuno, INTHFT, 2008
% www.nt.tuwien.ac.at
% output:   eNodeBs            ... contains info reagarding the BTSs and its
%                                  sectors
%           pathloss_data      ... [heightxwidthx3xnBTS] double
%                                  Pathloss data for each sector (including
%                                  antenna gain).
%                                  [y,x,sector_num,brts_num]

%% Necessary data loaded in the LTE_init_config config
global LTE_config;
% Hardcoded number of sectors. For now...
number_of_sectors = 3;
% Antenna pattern to use
antenna_gain_pattern = LTE_config.antenna.antenna_gain_pattern;
% Mean antenna gain
mean_antenna_gain    = LTE_config.antenna.mean_antenna_gain;
% Meters/pixel, resolution of the map
data_res             = LTE_config.map_resolution;
% eNodeB tx power (Watts/sector)
eNodeB_sector_tx_power = LTE_config.eNodeB_tx_power;

%% Some initialisation params
ROI_increase_factor = 0.1;

%% Create the eNodeBs
print_log(1,'Creating eNodeBs\n');
eNodeBs = LTE_init_create_eNodeBs;

% Add the Antennas to the eNodeBs
for b_ = 1:length(eNodeBs)
    % Create the eNodeB_sector objects
    % Writing eNodeBs(b_).sectors(1) gave me an error. Maybe a bug??
    eNodeBs(b_).sectors    = network_elements.eNodeB_sector;
    for s_ = 1:number_of_sectors
        eNodeBs(b_).sectors(s_) = network_elements.eNodeB_sector;
        eNodeBs(b_).sectors(s_).parent_eNodeB = eNodeBs(b_);
        eNodeBs(b_).sectors(s_).id = s_;
        eNodeBs(b_).sectors(s_).azimuth = wrapTo360(30 + 120*(s_-1));
        eNodeBs(b_).sectors(s_).max_power = eNodeB_sector_tx_power;

        switch antenna_gain_pattern
            case 'berger'
                eNodeBs(b_).sectors(s_).antenna = antennas.bergerAntenna(mean_antenna_gain);
            case 'TS 36.942'
                eNodeBs(b_).sectors(s_).antenna = antennas.TS36942Antenna(mean_antenna_gain);
            case 'omnidirectional'
                eNodeBs(b_).sectors(s_).antenna = antennas.omnidirectionalAntenna;
            otherwise
                error('This antenna is not supported');
        end
    end
end

%% Plot the antenna gain pattern
if LTE_config.show_network>0
    % Let's assume that each antenna is the same (which is for now the
    % case)
    angle = -180:0.1:180;
    gain = zeros(1,length(angle));
    for i_=1:length(angle)
        gain(i_) = eNodeBs(1).sectors(1).antenna.gain(angle(i_));
    end
end

%% Create the macroscopit pahloss model that will be used
macroscopic_pathloss_model = LTE_common_get_macroscopic_pathloss_model;

%% Calculate ROI

% BTS positions
tx_pos = zeros(length(eNodeBs),2);
for b_ = 1:length(eNodeBs)
    tx_pos(b_,:) = eNodeBs(b_).pos;
end

% Calculate ROI border points in ABSOLUTE coordinates
roi_x = [min(tx_pos(:,1)),max(tx_pos(:,1))];
roi_y = [min(tx_pos(:,2)),max(tx_pos(:,2))];


%% Define an area of the ROI to map
% roi_reduction_factor times smaller and draw it. ABSOLUTE COORDINATES
roi_x = roi_x + ROI_increase_factor*abs(roi_x(2)-roi_x(1))*[-1,1];
roi_y = roi_y + ROI_increase_factor*abs(roi_y(2)-roi_y(1))*[-1,1];

roi_maximum_pixels = LTE_common_pos_to_pixel( [roi_x(2) roi_y(2)], [roi_x(1) roi_y(1)], data_res);

roi_height_pixels = roi_maximum_pixels(2);
roi_width_pixels  = roi_maximum_pixels(1);

% Find the BTS that is nearest to the middle of the ROI
if strcmp(LTE_config.target_sector,'center')
    middle_ = [mean(roi_x),mean(roi_y)];
    target_bts = 1;
    for i_ = 1:length(eNodeBs)
        if norm(tx_pos(i_,:)-middle_) < norm(tx_pos(target_bts,:)-middle_)
            target_bts = i_;
        end
    end
    LTE_config.target_sector    = target_bts;
    LTE_config.target_sector(2) = 1;
else
    target_bts = LTE_config.target_sector(1);
end

eNodeBs(target_bts).target_cell = true;

%% Create pathlossMap
networkMacroscopicPathlossMap                        = channel_gain_wrappers.macroscopicPathlossMap;
networkMacroscopicPathlossMap.data_res               = data_res;
networkMacroscopicPathlossMap.roi_x                  = roi_x;
networkMacroscopicPathlossMap.roi_y                  = roi_y;

%% Put the pathloss for every pixel in the ROI in a 3D matrix.
% The equivalent "real-life" size of each pixel is determined by the
% data_res variable.

print_log(1,'Creating cell pathloss map\n');
distance_matrix      = zeros(roi_height_pixels,roi_width_pixels,length(eNodeBs));
theta_matrix         = zeros(roi_height_pixels,roi_width_pixels,number_of_sectors,length(eNodeBs));

% Generate distance and angle matrix
position_grid_pixels = zeros(roi_height_pixels*roi_width_pixels,2);
position_grid_pixels(:,1) = reshape(repmat(1:roi_width_pixels,roi_height_pixels,1),1,roi_width_pixels*roi_height_pixels);
position_grid_pixels(:,2) = repmat(1:roi_height_pixels,1,roi_width_pixels);
position_grid_meters = LTE_common_pixel_to_pos(position_grid_pixels,networkMacroscopicPathlossMap.coordinate_origin,networkMacroscopicPathlossMap.data_res);

for b_ = 1:length(eNodeBs)
    distances = sqrt((position_grid_meters(:,1)-eNodeBs(b_).pos(1)).^2 + (position_grid_meters(:,2)-eNodeBs(b_).pos(2)).^2);
    distance_matrix(:,:,b_) = reshape(distances,roi_height_pixels,roi_width_pixels);
    for s_ = 1:number_of_sectors
        angle_grid = rad2deg(atan2((position_grid_meters(:,2)-eNodeBs(b_).pos(2)),(position_grid_meters(:,1)-eNodeBs(b_).pos(1)))) - wrapTo360(-eNodeBs(b_).sectors(s_).azimuth+90); % Convert the azimuth (0°=North, 90°=East, 180^=South, 270°=West) degrees to cartesian
        theta_matrix(:,:,s_,b_) = reshape(angle_grid,roi_height_pixels,roi_width_pixels);
    end
end

% Calculate macroscopic pathloss using the macroscopic pathloss model
cell_pathloss_data = macroscopic_pathloss_model.pathloss(distance_matrix);

% Just in case...
cell_pathloss_data(isnan(cell_pathloss_data)) = 0;
cell_pathloss_data(cell_pathloss_data < 0)    = 0;

% Set sector_azimuth to (-180,180)
theta_matrix = theta_matrix + 180;
theta_matrix = mod(theta_matrix,360);
theta_matrix = theta_matrix - 180;

%% Plot the omnidirectional pathloss for each cell
% if LTE_config.show_network>0
%     figure;
%     number_cols = 3;
%     number_rows = ceil(length(eNodeBs)/number_cols);
%     for b_ = 1:length(eNodeBs)
%         subplot(number_rows,number_cols,b_);
%         imagesc(cell_pathloss_data(:,:,b_));
%         set(gca,'YDir','normal');
%         title(['eNodeB ' num2str(b_)]);
%         colorbar;
%         hold on;
%         scatter(eNodeB_pixel_pos(b_,1),eNodeB_pixel_pos(b_,2),'MarkerEdgeColor','black','MarkerFaceColor','black');
%         text(eNodeB_pixel_pos(b_,1)+2,eNodeB_pixel_pos(b_,2),num2str(b_));
%     end
% end

%% Sector pathloss
print_log(1,'Creating sector pathloss map (applying sector antenna gains)\n');

% Memory preallocation
sector_pathloss_data       = zeros(roi_height_pixels,roi_width_pixels,number_of_sectors,length(eNodeBs));

% Prefill sector_pathloss_data with the omdirectional pathloss
for b_ = 1:length(eNodeBs)
    for s_ = 1:number_of_sectors
        % Just copy the corresponding pathloss matrix to the variable
        sector_pathloss_data(:,:,s_,b_) = cell_pathloss_data(:,:,b_);
    end
end

%% Evaluate the antenna gain
sector_antenna_gain = eNodeBs(b_).sectors(s_).antenna.gain(theta_matrix);

%% Calculate final pathloss. With and without minimum coupling loss
sector_final_pathloss_data = sector_pathloss_data - sector_antenna_gain;

%% Apply Minimum Coupling Loss (MCL). After the antenna gain, as TS.942-900
%  states: RX_PWR = TX_PWR – Max (pathloss – G_TX – G_RX, MCL)
%  KNOWN ISSUE: this assumes that G_RX is 0dB, which will normally be the
%  case for a mobile terminal. This would have to be moved to the link
%  level model (UE) if G_RX is to be taken into account
print_log(1,['Applying Minimum Coupling Loss of ' num2str(LTE_config.minimum_coupling_loss) 'dB\n']);
sector_final_pathloss_data = max(sector_final_pathloss_data,LTE_config.minimum_coupling_loss);

%% Fill in pathloss data in the pathlossMap
networkMacroscopicPathlossMap.pathloss = sector_final_pathloss_data;

networkMacroscopicPathlossMap.name         = macroscopic_pathloss_model.name;
