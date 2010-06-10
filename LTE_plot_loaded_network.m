function LTE_plot_loaded_network(eNodeBs,networkPathlossMap,varargin)
% Function that shows a few plots after a network has been loaded from a file
% (c) Josep Colom Ikuno, INTHFT, 2008
% www.nt.tuwien.ac.at

% NOTE: the figures_to_plot second optional argument tells what plots to draw:
% 1: antenna gain pattern
% 2: macroscopic pathloss
% 3: sector macroscopic pathlosses (ASSUMING 3 SECTORS)
% 4: sector assignment (with shadow fading)
% 5: sector assignment (no shadow fading). Only if the sahdow fading is defined and used
% 6: shadow fading (if applicable)

global LTE_config;

if length(varargin)>0
    if ~isempty(varargin{1})
        plot_shadow_fading = true;
        networkShadowFadingMap = varargin{1};
    else
        plot_shadow_fading = false;
    end
end

% Not very clean, but will do the trick
roi_to_map_x = networkPathlossMap.roi_x;
roi_to_map_y = networkPathlossMap.roi_y;

macroscopic_pathloss_model = LTE_common_get_macroscopic_pathloss_model;

%% Plot the antenna gain pattern
if LTE_config.show_network>0
    % Let's assume that each antenna is the same (which is for now the
    % case)
    angle = -180:0.1:180;
    gain = zeros(1,length(angle));
    an_antenna = eNodeBs(1).sectors(1).antenna;
    for i_=1:length(angle)
        gain(i_) = an_antenna.gain(angle(i_));
    end
    figure(LTE_config.plots.antenna_gain_pattern);
    clf;
    plot(angle,gain);
    ylim(ylim*1.1);
    title({['Antenna gain, ' an_antenna.antenna_type ' antenna']});
    xlabel({'\theta [°]'});
    ylabel({'gain [dB]'});
    box on;
    grid on;
end

%% Plot of how the macroscopic pathloss looks like
if LTE_config.show_network>0
    % Will set the maximum distance as the diagonal that crosses the ROI
    range = sqrt((roi_to_map_x(2)-roi_to_map_x(1))^2+(roi_to_map_y(2)-roi_to_map_y(1))^2);
    distances = 0:LTE_config.map_resolution:range;
    pathlosses = macroscopic_pathloss_model.pathloss(distances);
    figure(LTE_config.plots.macroscopic_pathloss);
    clf;
    plot(distances,pathlosses);
    title(['Macroscopic pathloss, using ' macroscopic_pathloss_model.name ' model']);
    xlabel('Distance [m]');
    ylabel('Pathloss [dB]');
    box on;
    grid on;
end

%% Plot of sector macroscopic pathlosses (ASSUMING 3 SECTORS)
if LTE_config.show_network>0
    figure(LTE_config.plots.macroscopic_pathloss_sector1);
    number_cols = 3;
    number_rows = ceil(length(eNodeBs)/number_cols);
    for b_ = 1:length(eNodeBs)
        eNodeB_pixel_pos(b_,:) = LTE_common_pos_to_pixel(eNodeBs(b_).pos,networkPathlossMap.coordinate_origin,networkPathlossMap.data_res);
        subplot(number_rows,number_cols,b_);
        imagesc(networkPathlossMap.roi_x,networkPathlossMap.roi_y,networkPathlossMap.pathloss(:,:,1,b_));
        set(gca,'YDir','normal');
        title(['eNodeB ' num2str(b_) ' sector 1']);
        colorbar;
        hold on;
        %scatter(eNodeBs(b_).pos(1),eNodeBs(b_).pos(2),'MarkerEdgeColor','black','MarkerFaceColor','black');
        %text(eNodeBs(b_).pos(1)+5*networkPathlossMap.data_res,eNodeBs(b_).pos(2),num2str(b_));
    end
    
    figure(LTE_config.plots.macroscopic_pathloss_sector2);
    for b_ = 1:length(eNodeBs)
        subplot(number_rows,number_cols,b_);
        imagesc(networkPathlossMap.pathloss(:,:,2,b_));
        set(gca,'YDir','normal');
        title(['eNodeB ' num2str(b_) ' sector 2']);
        colorbar;
        hold on;
        scatter(eNodeB_pixel_pos(b_,1),eNodeB_pixel_pos(b_,2),'MarkerEdgeColor','black','MarkerFaceColor','black');
        text(eNodeB_pixel_pos(b_,1)+2,eNodeB_pixel_pos(b_,2),num2str(b_));
    end
    
    figure(LTE_config.plots.macroscopic_pathloss_sector3);
    for b_ = 1:length(eNodeBs)
        subplot(number_rows,number_cols,b_);
        imagesc(networkPathlossMap.pathloss(:,:,3,b_));
        set(gca,'YDir','normal');
        title(['eNodeB ' num2str(b_) ' sector 3']);
        colorbar;
        hold on;
        scatter(eNodeB_pixel_pos(b_,1),eNodeB_pixel_pos(b_,2),'MarkerEdgeColor','black','MarkerFaceColor','black');
        text(eNodeB_pixel_pos(b_,1)+2,eNodeB_pixel_pos(b_,2),num2str(b_));
    end
end

%% Plot shadow fading
if LTE_config.show_network>0 && plot_shadow_fading
    num_eNodeBs = length(eNodeBs);
    N_cols = 3;
    N_rows = ceil(num_eNodeBs/N_cols);
    figure(LTE_config.plots.shadow_fading_loss);
    for i_=1:num_eNodeBs
        subplot(N_rows,N_cols,i_);
        imagesc(networkShadowFadingMap.roi_x,networkShadowFadingMap.roi_y,networkShadowFadingMap.pathloss(:,:,i_));
        set(gca,'YDir','normal');
        title(['Shadow fading, eNodeB ' num2str(i_)]);
        colorbar;
    end
    
%     % Histogram, to see if they are really gaussian or not
%     size_xy = size(networkShadowFadingMap.pathloss,1)*size(networkShadowFadingMap.pathloss,2);
%     figure(LTE_config.plots.shadow_fading_loss_histogram);
%     for i_=1:num_eNodeBs
%         subplot(N_rows,N_cols,i_);
%         reshaped_map = reshape(networkShadowFadingMap.pathloss(:,:,i_),1,size_xy);
%         map_mean = mean(reshaped_map);
%         map_sd = std(reshaped_map);
%         hist(reshaped_map,75);
%         if i_==1
%             xlimits = xlim;
%             ylimits = ylim*1.2;
%         end
%         xlim(xlimits);
%         ylim(ylimits);
%         grid on;
%         set(gca,'YDir','normal');
%         title(['Shadow fading, eNodeB ' num2str(i_) ' mean: ' num2str(map_mean,'%3.2f') ' sd: ' num2str(map_sd,'%3.2f') ]);
%     end
end
