function target_eNodeB_sector = LTE_common_get_target_sector(eNodeBs,networkPathlossMap)

global LTE_config;

if strcmp(LTE_config.target_sector,'center')
    center_pos = [mean(networkPathlossMap.roi_x) mean(networkPathlossMap.roi_y)];
    target_sector = 1;
    target_eNodeB = 1;
    min_distance = [];
    for b_ = 1:length(eNodeBs)
        distance = norm(center_pos-eNodeBs(b_).pos);
        if isempty(min_distance)
            min_distance = distance;
            target_eNodeB = b_;
        else
            if distance<min_distance
                min_distance = distance;
                target_eNodeB = b_;
            end
        end
    end
    target_eNodeB_sector = [target_eNodeB target_sector];
    % calculate
else
    target_eNodeB_sector = LTE_config.target_sector;
end

