function [ output_args ] = LTE_init_generate_users(eNodeBs,networkMacroscopicPathlossMap)
% Get a cell assignment matrix. Here I will directly take it from the
% networkMacroscopicPathlossMap, but the following code could generate an equivalent
% one for any type of pathloss model.
%
% global LTE_config;
% [ x_range y_range ] = networkMacroscopicPathlossMap.valid_range;
% step = LTE_config.map_resolution;
% array_x =min(x_range):step:max(x_range);
% array_y =min(y_range):step:max(y_range);
% loss = zeros(length(array_y),length(array_x));
% for x_ = 1:length(array_x)
%     for y_ = 1:length(array_y)
%         pos = [array_x(x_) array_y(y_)];
%         assignment_map(y_,x_) = networkMacroscopicPathlossMap.cell_assignment(pos(1),pos(2));
%     end
% end
%
% (c) Josep Colom Ikuno, INTHFT, 2008

global LTE_config;

use_UE_cache = LTE_config.UE_cache;
cache_file_exists = exist(LTE_config.UE_cache_file,'file');

%% Data needed also for plotting: generate every time
sector_surfaces = networkMacroscopicPathlossMap.sector_sizes;
% Calculate how many users per sector
norm_sector_surface = sector_surfaces / sector_surfaces(LTE_config.target_sector(1),LTE_config.target_sector(2));
users_sector = round(norm_sector_surface*LTE_config.UE_per_eNodeB);
% All the possible positions for a given sector
sector_positions = cell(size(networkMacroscopicPathlossMap.sector_sizes));
% Where our users will be positions (for each eNodeB and sector)
user_positions_pixels = cell(size(networkMacroscopicPathlossMap.sector_sizes));
% Assign random positions to each UE
sector = 1;
bts    = 2;
for b_ = 1:length(eNodeBs)
    for s_ = 1:length(eNodeBs(1).sectors)
        if users_sector(b_,s_)~=0
            sector_positions_matrix = networkMacroscopicPathlossMap.sector_assignment(:,:,sector)==s_ & networkMacroscopicPathlossMap.sector_assignment(:,:,bts)==b_;
            [row,col] = find(sector_positions_matrix);
            sector_positions{b_,s_} = [col,row];
            user_positions_pixels{b_,s_} = sector_positions{b_,s_}(ceil(size(sector_positions{b_,s_},1)*rand(1,users_sector(b_,s_))),:);
        else
            sector_positions{b_,s_} = [];
            user_positions_pixels{b_,s_} = [];
        end
    end
end

%% Creating or loading UE position, depending on the configuration

% Create UEs
UEs = network_elements.UE;
if (~use_UE_cache) || (use_UE_cache&&~cache_file_exists)    
    userID = 1;
    for b_ = 1:length(eNodeBs)
        for s_ = 1:length(eNodeBs(1).sectors)
            
            % Generate only necessary users
            if ~LTE_config.UEs_only_in_target_sector
                UEs_to_create = 1:size(user_positions_pixels{b_,s_},1);
            else
                if b_==LTE_config.target_sector(1) && s_==LTE_config.target_sector(2)
                    UEs_to_create = 1:size(user_positions_pixels{b_,s_},1);
                else
                    UEs_to_create = [];
                end
            end
            
            UE_positions = zeros(userID,2);
            for u_ = UEs_to_create
                % General UE settings that can be saved and re-used
                UEs(userID)     = network_elements.UE;
                UEs(userID).id  = userID;
                UEs(userID).pos = LTE_common_pixel_to_pos( user_positions_pixels{b_,s_}(u_,:), networkMacroscopicPathlossMap.coordinate_origin, LTE_config.map_resolution);
                % Add noise figure
                UEs(userID).receiver_noise_figure = LTE_config.UE.receiver_noise_figure;
                % Generate a walking model for the user
                UEs(userID).walking_model = walking_models.straightWalkingModel(LTE_config.UE_speed*LTE_config.TTI_length); % Since no angle is specified, a random one is chosen
                UE_positions(userID,:) = user_positions_pixels{b_,s_}(u_,:);
                
                userID = userID + 1;
            end
        end
    end
    print_log(1,sprintf('Saving UE positions to %s\n',LTE_config.UE_cache_file));
    save(LTE_config.UE_cache_file,'UEs','UE_positions');
else
    % Load UEs
    print_log(1,sprintf('Loading UE positions from %s\n',LTE_config.UE_cache_file));
    load(LTE_config.UE_cache_file);
end

% Assign the UEs to their nearest (in pathloss) eNodeB and assign some extra parameters
UE_positions_m = zeros(length(UEs),2);
for u_ = 1:length(UEs)
    % To be sure: assign each user according to the cell assignment map
    [ eNodeB_id sector_num ] = networkMacroscopicPathlossMap.cell_assignment(UEs(u_).pos);
    UEs(u_).attached_eNodeB = eNodeBs(eNodeB_id);
    UEs(u_).attached_sector = sector_num;
    
    % Additional tracing options
    UEs(u_).trace_SINR = LTE_config.traces_config.trace_SINR;
    UEs(u_).trace_geometry_factor = LTE_config.traces_config.trace_geometry_factor;
    
    % Set the channel model for the user
    % This is now done outside of the function
    
    % Attach UE to eNodeB
    eNodeBs(eNodeB_id).attachUser(UEs(u_),sector_num);
    UE_positions_m(u_,:) = UEs(u_).pos;
end

%% Plot where the users are (pixel positions)
if LTE_config.show_network>0
    figure(LTE_config.plots.initial_UE_positions);
    hold on;
    roi_min = [min(networkMacroscopicPathlossMap.roi_x) min(networkMacroscopicPathlossMap.roi_y)];
    total_elements = length(eNodeBs)*length(eNodeBs(1).sectors);
    h = (1:total_elements)/total_elements;
    % the best way I could find to generate a randomly selected saturated colormap for the different sectors
    colormaps = hsv2rgb([h' ones(length(h),2)]);
    colormap_permutation = randperm(size(colormaps,1));
    colormaps = colormaps(colormap_permutation,:);
    i_=1;
    for b_ = 1:length(eNodeBs)
        for s_ = 1:length(eNodeBs(1).sectors)
            if ~isempty(sector_positions{b_,s_})
                current_sector_positions = LTE_common_pixel_to_pos(sector_positions{b_,s_},roi_min,networkMacroscopicPathlossMap.data_res);
                scatter(current_sector_positions(:,1),current_sector_positions(:,2),'+','MarkerEdgeColor',colormaps(i_,:),'MarkerFaceColor',colormaps(i_,:));
                i_ = i_+1;
            end
        end
    end
    scatter(UE_positions_m(:,1),UE_positions_m(:,2),'o','MarkerEdgeColor','k','MarkerFaceColor','w');
    
    title(sprintf('UE initial positions: %d eNodeBs, %d sectors/eNodeB ',length(eNodeBs),length(eNodeBs(1).sectors)));
    xlim(networkMacroscopicPathlossMap.roi_x);
    ylim(networkMacroscopicPathlossMap.roi_y);
    xlabel('x pos [m]');
    ylabel('y pos [m]');
end

% Choose as many points per cell as users
output_args = UEs;
