classdef antenna < handle
    % This Abstract class represents an antenna
    % (c) Josep Colom Ikuno, INTHFT, 2008

    properties
        antenna_type
        mean_antenna_gain
    end

    methods (Abstract)
        % Print some info
        print(obj)
        % Returns antenna gain as a function of theta
        antenna_gain = gain(obj,theta)
        % Returns the maximum and minimum antenna gain [min max]
        minmaxgain = min_max_gain(obj)
    end
end
