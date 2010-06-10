function sector_assignment = LTE_common_calculate_sector_assignment(networkPathlossMap,varargin)
% Fills in the sector assignment data of the pathloss data object. If
% shadow fading is also given, it also takes it into account.
% (c) Josep Colom Ikuno, INTHFT, 2008
% input:    sector_pathloss_data ... uint8(N,M,nSectors,nBTs) NxM map of the nBTSsxnSectors pathloss 

% Check whether shadow fading is used
if length(varargin)>0
    print_log(1,'Calculating sector assignment based on pathloss maps (macroscopic and shadow fading)\n');
    shadow_fading_used = true;
    networkShadowFadingMap = varargin{1};
else
    print_log(1,'Calculating sector assignment based on pathloss maps (macroscopic fading)\n');
    shadow_fading_used = false;
end

% Calculate total received power matrix (done with power as to take into
% account the possibly different powers assigned to each eNodeB/sector)
total_pathloss_map = zeros(size(networkPathlossMap.pathloss));
num_eNodeBs = size(networkPathlossMap.pathloss,4);
num_sectors = size(networkPathlossMap.pathloss,3);
pathloss_size = [size(networkPathlossMap.pathloss,1) size(networkPathlossMap.pathloss,2)];

for b_=1:num_eNodeBs
    if shadow_fading_used
        shadow_fading_map = imresize(networkShadowFadingMap.pathloss(:,:,b_),pathloss_size);
    else
        shadow_fading_map = 0;
    end
    for s_=1:num_sectors
        total_pathloss_map(:,:,s_,b_) = networkPathlossMap.pathloss(:,:,s_,b_) + shadow_fading_map;
    end
end

% Only up to 256 BTss, that should be enough!!!
cell_assignment = zeros(size(networkPathlossMap.pathloss,1),size(networkPathlossMap.pathloss,2),2,'uint8');

sector = 1;
bts    = 2;

for x_pos = 1:size(total_pathloss_map,1)
    for y_pos = 1:size(total_pathloss_map,2)
        pixel = squeeze(total_pathloss_map(x_pos,y_pos,:,:));
        minimum = min(min(pixel));
        [ sector_num bts_num ] = find(pixel==minimum);
        
        sector_assignment(x_pos,y_pos,sector) = sector_num(1);
        sector_assignment(x_pos,y_pos,bts)    = bts_num(1);
    end
end

sector_surfaces = zeros(num_eNodeBs,num_sectors);
for b_ = 1:num_eNodeBs
    for s_ = 1:num_sectors
        sector_surfaces(b_,s_) = sum(sum(sector_assignment(:,:,sector)==s_ & sector_assignment(:,:,bts)==b_));
    end
end

if shadow_fading_used
    networkPathlossMap.sector_assignment = sector_assignment;
    networkPathlossMap.sector_sizes      = sector_surfaces;
else
    networkPathlossMap.sector_assignment              = sector_assignment;
    networkPathlossMap.sector_sizes                   = sector_surfaces;
    networkPathlossMap.sector_assignment_no_shadowing = sector_assignment;
    networkPathlossMap.sector_sizes_no_shadowing      = sector_surfaces;
end