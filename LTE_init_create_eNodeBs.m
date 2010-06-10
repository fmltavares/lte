function [ eNodeBs ] = LTE_init_create_eNodeBs
% Creates an hexagonal set of eNodeBs according to the loaded paramerters
% BTS generation is taken from the xf_generate_hsdpa_network from 
% Martin Wrulich's MIMO-HSDPA simulator
% (c) Josep Colom Ikuno, Martin Wrulich INTHFT, 2008

global LTE_config;

% Distance between BTSs
inter_bts_distance = LTE_config.inter_eNodeB_distance;
% Number of BTS rings in the network map
n_rings = LTE_config.nr_eNodeB_rings;

%total nr. of eNodeBs
% each ring consists of 6 NodeBs at the corners of the hexagon
% each edge then has "i-1" further NodeBs, where "i" is the ring index
% total_nr_eNodeB = sum(6*(1:n_rings))+1;


[tmp_gridx,tmp_gridy] = meshgrid(-n_rings:n_rings,...
    (-n_rings:n_rings)*sin(pi/3)); %regular grid
if mod(n_rings,2) == 0
    tmp_shift_idx = 2:2:2*n_rings+1; %shift all even rows
else
    tmp_shift_idx = 1:2:2*n_rings+1; %shift all odd rows
end

tmp_gridx(tmp_shift_idx,:) = tmp_gridx(tmp_shift_idx,:) + 0.5; %shift

rot = @(w_) [cos(w_),-sin(w_);sin(w_),cos(w_)]; %rotation operator
for i_ = 1:7
    %border of the network
    tmp_hex(i_,:) = ((n_rings+0.5)*rot(pi/3)^(i_-1)*[1;0]).'; %#ok<AGROW>
end

tmp_valid_positions = inpolygon(tmp_gridx,tmp_gridy,tmp_hex(:,1),tmp_hex(:,2));
tmp_x = tmp_gridx(tmp_valid_positions);
tmp_y = tmp_gridy(tmp_valid_positions);

%% Create the eNodeB array
for b_ = 1:length(tmp_x)
    eNodeBs(b_) = network_elements.eNodeB;
    eNodeBs(b_).id = b_;
    eNodeBs(b_).pos = [tmp_x(b_)*inter_bts_distance tmp_y(b_)*inter_bts_distance];
end

%% Calculate which are the nighboring eNodeBs
for b_ = 1:length(eNodeBs)
    eNodeBs(b_).neighbors = LTE_init_get_eNodeB_neighbors(eNodeBs(b_),eNodeBs,inter_bts_distance+1);
end
