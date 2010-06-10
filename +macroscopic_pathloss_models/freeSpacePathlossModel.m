classdef freeSpacePathlossModel < macroscopic_pathloss_models.generalPathlossModel
    % Free space pathloss model
    % (c) Josep Colom Ikuno, INTHFT, 2008
    properties
        frequency % Frequency in HERTZs
    end

    methods
        function obj = freeSpacePathlossModel(frequency)
            obj.frequency = frequency;
            obj.name = 'free space';
        end
        % Returns the free-space pathloss in dB. Note: distance in METERS
        function pathloss_in_db = pathloss(obj,distance)
            % Restrict that pathloss must be bigger than 0 dB
            pathloss_in_db = max(10*log10((4*pi/299792458*distance*obj.frequency).^2),0);
        end
    end
end
