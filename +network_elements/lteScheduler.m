classdef lteScheduler < handle
    % Implements common methods needed by any implementation of an LTE
    % scheduler (eg. Round Robin, Best CQI...)
    % (c) Josep Colom Ikuno, INTHFT, 2009
    
    properties
        % Where this scheduler is attached
       attached_eNodeB_sector
       % Copy of the CQI tables
       CQI_range
       CQI_tables
       CQIs_efficiency % In order to avoid getting this every TTI
       % The algorithm used to average the several SINRs into a single TB SINR
       SINR_averager
       % BLER data and CQI mapping
       BLER_curves
       CQI_mapper
       
       % Target system BLER
       target_BLER = 0.1;
       
       % Where trace data is saved
       trace
       
       % Genie information (eg: all of the eNodeBs and UEs)
       genie
       
       % UE trace: from where the historical information (ie. UE throughput) is extracted
       UE_traces
       % In order to know how many TTIs to skip when looking for throughput
       % (in reality you would not know instantly whether the TB was received correctly or not)
       feedback_delay_TTIs
       
       % network clock. Tells the scheduler in what TTI he is
       clock
    end
    
    methods(Abstract)
        schedule_users(obj,RB_grid,attached_UEs,last_received_feedbacks)
        add_UE(obj,UE_id)
        remove_UE(obj,UE_id)
    end
    
    methods
        
        % Class constructor
        function obj = lteScheduler(attached_eNodeB_sector)
            obj.attached_eNodeB_sector = attached_eNodeB_sector;
            CQI_range = LTE_common_get_CQI_params('range');
            obj.CQI_tables = LTE_common_get_CQI_params(CQI_range(1)); % To initialize the struct
            for i_=CQI_range(1):CQI_range(2)
                obj.CQI_tables(i_) = LTE_common_get_CQI_params(i_);
            end
            obj.CQI_range = CQI_range(1):CQI_range(2);
            obj.CQIs_efficiency = [0 [obj.CQI_tables.efficiency]]; % Take note of CQI 0 also
            obj.clock = attached_eNodeB_sector.parent_eNodeB.clock;
        end
        
        % Find the optimum CQI values for a set of N codewords
        function [assigned_CQI predicted_BLER predicted_SINR] = get_optimum_CQIs(obj,CQIs_to_average_all,nCodewords)
            if nCodewords==1
                if ~isempty(CQIs_to_average_all)
                    CQIs_to_average = CQIs_to_average_all;
                    [assigned_CQI predicted_BLER predicted_SINR]= obj.get_optimum_CQI(CQIs_to_average);
                else
                    assigned_CQI = 0;
                    predicted_BLER = 0;
                    predicted_SINR = NaN;
                end
            else
                for cw_=1:nCodewords
                    if ~isempty(CQIs_to_average_all)
                        CQIs_to_average = CQIs_to_average_all(:,cw_);
                        [assigned_CQI(cw_) predicted_BLER(cw_) predicted_SINR(cw_)]= obj.get_optimum_CQI(CQIs_to_average);
                    else
                        assigned_CQI(cw_) = 0;
                        predicted_BLER(cw_) = 0;
                        predicted_SINR(cw_) = NaN;
                    end
                end
            end
        end
        
        % For a set of SINR values, this functions averages them using the
        % scheduler's SINR averaging algorithm and outputs the MCS that
        % most closely approaches the target BLER (set at 0.1)
        function [assigned_CQI predicted_BLER effective_SINR] = get_optimum_CQI(obj,CQIs_to_average)
            
            UE_estimated_SINR_dB = obj.CQI_mapper.CQI_to_SINR(CQIs_to_average);
            UE_estimated_SINR_linear = 10.^(0.1*UE_estimated_SINR_dB);
            
            averaged_SINR_MCS_dependent_linear = obj.SINR_averager.average(UE_estimated_SINR_linear,obj.CQI_range);
            averaged_SINR_MCS_dependent_log    = 10*log10(averaged_SINR_MCS_dependent_linear);
            
            predicted_BLERs = zeros(1,length(obj.CQI_range));
            for i_=obj.CQI_range
                predicted_BLERs(i_) = obj.BLER_curves.get_BLER(i_,averaged_SINR_MCS_dependent_log(i_));
            end
            
            % Objective is the closest smaller or equal to 10% BLER (BLER 0 is preferred to BLER 1)
            % Case of a VERY good channel
            if predicted_BLERs(end) == 0
                assigned_CQI = 15;
            % Case of a bad channel
            elseif predicted_BLERs(1) >= obj.target_BLER
                assigned_CQI = 1;
            else
                abs_diffs = predicted_BLERs-obj.target_BLER;
                abs_diffs = round(abs_diffs*1000)/1000; % To avoid small statistical mistakes in the BLER plots. No change assuming that the target BLER is in the order of 10%
                assigned_CQI = find(abs_diffs<=0,1,'last');
            end
            predicted_BLER = predicted_BLERs(assigned_CQI);
            effective_SINR = averaged_SINR_MCS_dependent_log(assigned_CQI);
        end
        
        function CQI_spectral_efficiency = get_spectral_efficiency(obj,CQI_matrix)
            % Returns the spectral efficiencies related to the CQIs in the
            % matrix. In case of unquantized feedback, it floors the CQI
            % values to the nearest usable CQI
            CQI_idx                 = floor(CQI_matrix)+1; % Get CQI indexes
            CQI_idx(CQI_idx<1)      = 1;       % Clip extremes
            CQI_idx(CQI_idx>16)     = 16;
            sizes_CQI_feedback      = size(CQI_idx);
            CQI_idx_vector          = uint16(CQI_idx(:)); % To avoid an error caused by Matlab sometimes saying those were not integers
            CQI_spectral_efficiency = reshape(obj.CQIs_efficiency(CQI_idx_vector),sizes_CQI_feedback);
        end
        
        function UE_resource_assignment = get_max_UEs(obj,metric_matrix,UE_assignment)
            % Scans a nUExM matrix and returns for each column the index of
            % the highest value. In case more than one UE has the same
            % metric value, one of these ones is randomly selected. Assume
            % all values to be non-negative and 0 as "out-of-range"
            max_metric = max(metric_matrix,[],1);
            UE_resource_assignment = zeros(length(max_metric),1);
            for rb_=1:length(max_metric)
                if max_metric(rb_)~=0
                    candidates = find(metric_matrix(:,rb_)==max_metric(rb_));
                    UE_resource_assignment(rb_) = UE_assignment(candidates(ceil(rand*length(candidates)))); % Choose a random UE from the set
                end 
            end
        end
    end
    
end

