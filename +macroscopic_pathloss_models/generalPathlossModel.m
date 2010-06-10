classdef generalPathlossModel < handle
    % Abstract class that represents a pathloss model
    % (c) Josep Colom Ikuno, INTHFT, 2008
    properties
        % this model's name
        name
    end
    methods (Abstract)
        pathloss_in_db = pathloss(distance)
    end
end
