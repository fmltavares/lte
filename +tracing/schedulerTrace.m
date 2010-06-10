classdef schedulerTrace < handle
    % This class stores statistical information about the resource
    % assignment performed by the scheduler each TTI.
    % (c) Josep Colom Ikuno, INTHFT, 2009
    
    properties
        % Average number of RBs assigned per UE
        RBs_per_user
        % Average estimated BLER of the TX TBs
        mean_BLER
    end
    
    methods
        % Class constructor
        function obj = schedulerTrace(simulation_length_TTIs)
            obj.RBs_per_user = zeros(1,simulation_length_TTIs,'single');
            obj.mean_BLER    = NaN(1,simulation_length_TTIs,'single');
        end
        
        % Store trace
        function store(obj,TTI_idx,RBs_per_user,mean_BLER)
            obj.RBs_per_user(TTI_idx) = RBs_per_user;
            obj.mean_BLER(TTI_idx)    = mean_BLER;
        end
    end
    
end

