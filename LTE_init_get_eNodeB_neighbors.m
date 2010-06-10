function neighboring_eNodeBs = LTE_init_get_eNodeB_neighbors(this_eNodeB,eNodeBs,distance_threshold)
% Generates a list of neighboring eNodeBs for the given eNodeB.
% If distance<=distance_threshold, then 2 given eNodeBs are neighbors.
% (c) Josep Colom Ikuno, Martin Wrulich INTHFT, 2008
% input:    this_eNodeB          ... our considered eNodeB
%           eNodeBs              ... all the eNodeBs. Note that
%                                    eNodeBs(i).id==i must be fulfilled!!
% output:   neighboring_eNodeBs  ... the neighboring eNodeBs

% We will store the distances here
% eNodeB_ID, distance
pos_idx = 1;
for b_ = 1:length(eNodeBs)
    vector = eNodeBs(b_).pos - this_eNodeB.pos;
    distance = sqrt(sum(vector.^2));
    if distance~=0
        pos_distance(pos_idx,1) = eNodeBs(b_).id;
        pos_distance(pos_idx,2) = distance;
        pos_idx = pos_idx + 1;
    end
end

pos_distance = sortrows(pos_distance,2);

pos_idx = 1;
for b_ = 1:size(pos_distance,1)
    if pos_distance(b_,2)<=distance_threshold
        neighboring_eNodeBs(pos_idx) = eNodeBs(pos_distance(b_,1));
        pos_idx = pos_idx + 1;
    end
end
