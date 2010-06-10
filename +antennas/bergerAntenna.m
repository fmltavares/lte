classdef bergerAntenna < antennas.antenna
    % A Berger antenna
    % (c) Josep Colom Ikuno, INTHFT, 2008

    methods
        function obj = bergerAntenna(mean_antenna_gain)
            obj.antenna_type = 'berger';
            obj.mean_antenna_gain = mean_antenna_gain;
        end
        function print(obj)
            fprintf('Berger antenna, mean gain: %d\n',obj.mean_antenna_gain);
        end
        function antenna_gain = gain(obj,theta)
            antenna_gain = -min(12*(theta/70).^2,20) + obj.mean_antenna_gain;
        end
        function minmaxgain = min_max_gain(obj)
            % minmaxgain(1) = -min(12*(180/70)^2,20) + obj.mean_antenna_gain;
            minmaxgain(1) = obj.gain(180);
            minmaxgain(2) = obj.mean_antenna_gain;
        end
    end
end
