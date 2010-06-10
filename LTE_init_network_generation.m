function [eNodeBs networkPathlossMap networkShadowFadingMap] = LTE_init_network_generation
%% Network generation. Either from a file (cache) or calling the necessary function.
% (c) Josep Colom Ikuno, INTHFT, 2009
% www.nt.tuwien.ac.at

global LTE_config;

% If cache is on and the cache file exists, load network from disk
if LTE_config.cache_network && exist(LTE_config.network_cache,'file')
    print_log(1,sprintf('Loading network from %s\n',LTE_config.network_cache));
    load(LTE_config.network_cache);
    % Change map resolution to match the loaded maps'
    LTE_config.map_resolution = networkPathlossMap.data_res;
% If not, then create it
else 
    % Generate network (eNodeBs and macroscopic pathloss)
    print_log(1,'Generating network\n');
    switch LTE_config.network_source
        case 'generated'
            [eNodeBs networkPathlossMap] = LTE_init_generate_network;
            % Other case here -> other sources, eg. Network planning tool
        otherwise
            error([LTE_config.network_source ' network source not supported\n']);
    end
    % Generate shadow fading
    if strcmp(LTE_config.network_source,'generated')
        print_log(1,'Generating shadow fading\n');
        switch LTE_config.shadow_fading_type
            case 'claussen'
                [LTE_config.roi_x LTE_config.roi_y] = networkPathlossMap.valid_range;
                networkShadowFadingMap = LTE_init_generate_claussen_shadow_fading_map(eNodeBs);
            otherwise
                error([LTE_config.shadow_fading_type ' shadow fading type not supported']);
        end
    else
        error('only "generated" supported for now');
    end
    
    %% Fill in sector assignment (takes into account the shadow fading)
    if exist('networkShadowFadingMap','var')
        networkPathlossMap.sector_assignment = LTE_common_calculate_sector_assignment(networkPathlossMap);
        networkPathlossMap.sector_assignment = LTE_common_calculate_sector_assignment(networkPathlossMap,networkShadowFadingMap);
    else
        networkPathlossMap.sector_assignment = LTE_common_calculate_sector_assignment(networkPathlossMap);
    end
    
    % Save network
    if LTE_config.cache_network
        print_log(1,'Saving network to file\n');
        if exist('networkShadowFadingMap','var')
            save(LTE_config.network_cache,'eNodeBs','networkPathlossMap','networkShadowFadingMap');
        else
            save(LTE_config.network_cache,'eNodeBs','networkPathlossMap');
        end
    end
end

% Add number of antennas information
for b_=1:length(eNodeBs)
    for s_=1:length(eNodeBs(1).sectors)
        eNodeBs(b_).sectors(s_).nTX = LTE_config.nTX;
    end
end

% Configure the case for zero-delay
if LTE_config.feedback_channel_delay==0
    for b_=1:length(eNodeBs)
        for s_=1:length(eNodeBs(1).sectors)
            eNodeBs(b_).sectors(s_).zero_delay_feedback = true;
        end
    end
end

% Configure unquantized feedback
if LTE_config.unquantized_CQI_feedback
    for b_=1:length(eNodeBs)
        for s_=1:length(eNodeBs(1).sectors)
            eNodeBs(b_).sectors(s_).unquantized_CQI_feedback = true;
        end
    end
end

