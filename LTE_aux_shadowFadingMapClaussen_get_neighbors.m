function s_tilde = LTE_aux_shadowFadingMapClaussen_get_neighbors(s,position,values)
% Gives back a column of all the s_n values, as described by Claussen's paper
% Works over a 3-D map (for all eNodeBs) for speed (vectorization)
% Had to be placed outside of the class directory due to some awkward
% behaviour of the newly introduced Object oriented programming from Matlab.
% (c) Josep Colom Ikuno, INTHFT, 2008
switch values
    case 4
        offsets = [
            -1  -1
            -0  -1
            1  -1
            -1   0
            ];
    case 8
        offsets = [
            -1  -1
            -0  -1
            1  -1
            -1   0
            -1  -2
            1  -2
            -2  -1
            2  -1
            ];
    otherwise
        error('Only 4 and 8 values supported');
end
s_tilde = zeros(values,size(s,3));
for i_=1:size(offsets,1)
    neighbor_position = position + offsets(i_,:);
    if sum(neighbor_position<=0)==0
        if neighbor_position(2)<=size(s,1) && neighbor_position(1)<=size(s,2)
            s_tilde(i_,:) = s(neighbor_position(2),neighbor_position(1),:);
        end
    end
end
