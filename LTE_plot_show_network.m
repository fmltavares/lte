function eNodeBs_pos = LTE_plot_show_network( eNodeBs, UEs, map_res, current_TTI )
% Shows the network as it is right now. Plots the eNodeB and UE positions
% output:   eNodeBs  ... vector of eNodeBs to plot
%           UEs      ... vector of UEs to plot
%           map_res  ... resolution of the map: meters/pixel
%
% (c) Josep Colom Ikuno, INTHFT, 2008

global LTE_config;

figure(LTE_config.plots.user_positions);
clf;

hold on;
grid on;

eNodeBs_pos = zeros(length(eNodeBs),2);

for b_=1:length(eNodeBs)
    % Plot a line that tells where the antennas are pointing
    vector_length = 40;
    origin = eNodeBs(b_).pos;
    eNodeBs_pos(b_,:) = origin;
    for s_=1:length(eNodeBs(b_).sectors)
        angle = wrapTo360(-eNodeBs(b_).sectors(s_).azimuth+90);
        vector = vector_length*[ cosd(angle) sind(angle) ];
        destiny = vector + origin;

        plot([origin(1) destiny(1)],[origin(2) destiny(2)]);
    end
    % Plot the eNodeBs
    scatter(eNodeBs(b_).pos(1),eNodeBs(b_).pos(2),'Marker','o','MarkerFaceColor','red','MarkerEdgeColor','black');
    text(eNodeBs(b_).pos(1)+map_res*5,eNodeBs(b_).pos(2),num2str(eNodeBs(b_).id));
end

for u_=1:length(UEs)
    scatter(UEs(u_).pos(1),UEs(u_).pos(2),'Marker','.','MarkerFaceColor','black','MarkerEdgeColor','black');
    text(UEs(u_).pos(1)+map_res*1,UEs(u_).pos(2),num2str(UEs(u_).id),'FontSize',8);
end
title(['eNodeB and UE positions, TTI ' num2str(current_TTI)]);
xlabel('x pos [m]');
ylabel('y pos [m]');
axis equal;
