classdef UE < handle
    % Class that represents an LTE UE (user)
    % (c) Josep Colom Ikuno, INTHFT, 2008
    
    properties
        % Unique UE id
        id
        % pos in meters (x,y)
        pos
        % eNodeB to where this user ir attached
        attached_eNodeB
        % eNodeB's sector to which the UE is attached
        attached_sector
        % Walking model for this user
        walking_model
        % Downlink channel model for this user
        downlink_channel
        % Uplink channel model for this user
        uplink_channel
        % noise figure for this specific UE
        receiver_noise_figure
        % Number of receive antennas
        nRX
        
        % trace that stores info about what happened
        trace
        % network clock. Tells the UE in what TTI he is
        clock
        % performs the mapping between SINR and CQI
        CQI_mapper
        
        % Data to be fed back to the eNodeB. It is used to pass the
        % feedback data to the send_feedback() function
        feedback_nCodewords
        feedback_measured_CQI
        feedback_TB_ACK
        feedback_TB_size
        feedback_TB_was_scheduled
        
        % Whether the CQI feedback should be unquantized. Having this set
        % to true is equivalent to directly sending the SINR
        unquantized_CQI_feedback = false;
        
        % Will decide whether a give TB made it or not
        BLER_curves
        
        % Gives the means to average the several Transport Block (TB) SINRs
        SINR_averager
        
        % Signaling from the eNodeB to this UE. This is a direct channel
        % between the eNodeB and this UE, where it gets signaled
        % UE-specific signaling information. The signaled information and
        % where it is located is as follows:
        %   UEsignaling:
        %     - TB_CQI           % CQI used for the transmission of each codeword
        %     - TB_size          % size of the current TB, in bits
        %     - tx_mode          % transmission mode used (SISO, tx diversity, spatial multiplexing)
        %     - rv_idx           % redundancy version index for each codeword
        %   downlink_channel.RB_grid
        %     - user_allocation  % what UE every RB belongs to
        %     - power_allocation % how much power to allocate to each RB,
        %     - n_RB             % RB grid size (frequency)
        %     - sym_per_RB       % number of symbols per RB (12 subcarriers, 0.5ms)
        %     - size_bits        % total size of the RB grid in bits
        %     - numStreams       % maximum number of allowed streams. Resource allocation is described for all of them
        eNodeB_signaling
        
       % Extra tracing options (default options)
       trace_SINR = false;
       trace_geometry_factor = false;
       
       % This is the information that the link quality model conveys to the
       % link performance model
       last_measured_SINR_dB
       last_measured_SINR_linear
       last_measured_geometry_factor_dB
       last_measured_geometry_factor_linear
    end

    methods
        function print(obj)
            if isempty(obj.attached_eNodeB)
                fprintf('User %d, (%d,%d), not attached to an eNodeB\n',obj.id,obj.pos(1),obj.pos(2));
            else
                fprintf('User %d, (%d,%d), eNodeB %d, sector %d\n',obj.id,obj.pos(1),obj.pos(2),obj.attached_eNodeB.id,obj.attached_sector);
            end
            obj.walking_model.print;
        end
        % Move this user according to its settings
        function move(obj)
            new_pos = obj.walking_model.move_back(obj.pos);
            obj.pos = new_pos;
        end
        % Move this user to where it was the last TTI before according to
        % its settings
        function move_back(obj)
            old_pos = obj.walking_model.move(obj.pos);
            obj.pos = old_pos;
        end
        function UE_in_roi = is_in_roi(a_UE,roi_x_range,roi_y_range)
            % Tells you whether a user in in the Region of Interest (ROI) or not
            % (c) Josep Colom Ikuno, INTHFT, 2008
            % input:    a_UE         ... the UE in question
            %           roi_x_range  ... roi x range. minimum and maximum x coordinates
            %                            which are valid
            %           roi_y_range  ... roi y range. minimum and maximum y coordinates
            %                            which are valid
            % output:   UE_in_roi  ... true or false, whether the UE is inside or not

            UE_pos_x = a_UE.pos(1);
            UE_pos_y = a_UE.pos(2);

            if UE_pos_x<roi_x_range(1) || UE_pos_x>roi_x_range(2)
                UE_in_roi = false;
                return;
            end

            if UE_pos_y<roi_y_range(1) || UE_pos_y>roi_y_range(2)
                UE_in_roi = false;
                return;
            end
            UE_in_roi = true;
        end
        % Starts handover procedures from the currently attached eNodeB to
        % the specified target_eNodeB
        % for now... immediate handover. A proper implementation remains
        % pending.
        function start_handover(obj,target_eNodeB,target_sector)            
            % Remove the user from the eNodeB and its scheduler
            obj.attached_eNodeB.sectors(obj.attached_sector).scheduler.remove_UE(obj.id);
            obj.attached_eNodeB.deattachUser(obj);
            % Add the user to the eNodeB and its scheduler
            target_eNodeB.attachUser(obj,target_sector);
            target_eNodeB.sectors(target_sector).scheduler.add_UE(obj.id);
        end

        % Measure whatever needs to be measured and send a feedback to the
        % attached eNodeB
        function send_feedback(obj)
            obj.uplink_channel.send_feedback(...
                obj.feedback_nCodewords,...
                obj.feedback_measured_CQI,...
                obj.feedback_TB_ACK,...
                obj.feedback_TB_size,...
                obj.feedback_TB_was_scheduled);
        end
        
        % Calculates the receiver SINR, which is the metric used to measure
        % link quality
        function link_quality_model(obj)
            interfering_eNodeBs              = obj.attached_eNodeB.neighbors;
            user_macroscopic_pathloss        = obj.downlink_channel.macroscopic_pathloss;   % Already includes the antenna gain (dB)
            user_macroscopic_pathloss_linear = 10^(0.1*user_macroscopic_pathloss);
            user_shadow_fading_loss          = obj.downlink_channel.shadow_fading_pathloss; % Shadow fading loss (dB)
            user_shadow_fading_loss_linear   = 10^(0.1*user_shadow_fading_loss);
            
            % Get current time
            t = obj.clock.time;

            % ToDo: change 'stream' for 'codeword' and add 'layer'. For
            % now: quick patch
            the_RB_grid = obj.downlink_channel.RB_grid;
            nCodewords = the_RB_grid.nCodewords;
            nLayers    = the_RB_grid.nLayers;
            tx_mode    = the_RB_grid.tx_mode;
            
            switch tx_mode
                case 1
                    MIMO = false; % SISO mode
                otherwise
                    MIMO = true;  % MIMO modes
            end
            
            % Get fast fading trace for this subframe
            user_microscale_fading_params      = obj.downlink_channel.fast_fading_pathloss(t,MIMO);
            user_microscale_fading_mode_params = user_microscale_fading_params{tx_mode};
            
            %% The SINR calculation is done under the following circumstances:
            % Power allocation is done on a per-subframe (1 ms) and RB basis
            % The fast fading trace is given for every 6 subcarriers (every
            % 90 KHz), so as to provide enough samples related to a
            % worst-case-scenario channel length

            % TX power for each layer (ToDo: recode this properly: right now homogeneous power assumed)
            TX_power_layer_half_RB = the_RB_grid.power_allocation(1,1)/(2*nLayers); % Already divided by 2 (6-subcarrier freq bins) and nLayers
            
            % Apply attenuation            
            RX_power = TX_power_layer_half_RB./user_macroscopic_pathloss_linear./user_shadow_fading_loss_linear.*user_microscale_fading_mode_params.zeta;
            
%             if obj.trace_geometry_factor
%                 geometry_factor_tx = sum(TX_power,2)./user_macroscopic_pathloss_linear;
%             end
            
            % Get interfering eNodeBs
            interfering_eNodeBs_id        = [interfering_eNodeBs.id];
            interfering_sectors_idx       = kron((interfering_eNodeBs_id-1)*3,[1 1 1]) + kron(ones(1,length(interfering_eNodeBs_id)),[1 2 3]);
            if ~MIMO
                microscale_interfering_thetas = user_microscale_fading_mode_params.theta(interfering_sectors_idx,:);
            else
                microscale_interfering_thetas = user_microscale_fading_mode_params.theta(:,interfering_sectors_idx,:);
            end
            
            if obj.trace_geometry_factor
                geometry_factor_rx = zeros([length(geometry_factor_tx),length(interfering_eNodeBs(1).sectors),length(interfering_eNodeBs)]);;
            end
            
            interf_shadow_fading = zeros(size(microscale_interfering_thetas));
            interf_macro_fading  = zeros(size(microscale_interfering_thetas));
            
            % Macro and Shadow fading pathloss. eNodeB and sector dependent
            interferingEnodeBids = [interfering_eNodeBs.id];
            interfering_macroscopic_pathloss_eNodeB = obj.downlink_channel.interfering_macroscopic_pathloss(interferingEnodeBids);
            interfering_macroscopic_pathloss_eNodeB_linear = 10.^(0.1*interfering_macroscopic_pathloss_eNodeB);
            interfering_shadow_fading_loss        = obj.downlink_channel.interfering_shadow_fading_pathloss(interferingEnodeBids);
            interfering_shadow_fading_loss_linear = 10.^(0.1*interfering_shadow_fading_loss);
            
            for b_=1:length(interfering_eNodeBs)
                
                if ~MIMO
                    interf_macro_fading((b_-1)*3+1,:)  = interfering_macroscopic_pathloss_eNodeB_linear(1,b_);
                    interf_macro_fading((b_-1)*3+2,:)  = interfering_macroscopic_pathloss_eNodeB_linear(2,b_);
                    interf_macro_fading((b_-1)*3+3,:)  = interfering_macroscopic_pathloss_eNodeB_linear(3,b_);
                    interf_shadow_fading([(b_-1)*3+1,(b_-1)*3+2,(b_-1)*3+3],:) = interfering_shadow_fading_loss_linear(b_);
                else
                    interf_macro_fading(:,(b_-1)*3+1,:)  = interfering_macroscopic_pathloss_eNodeB_linear(1,b_);
                    interf_macro_fading(:,(b_-1)*3+2,:)  = interfering_macroscopic_pathloss_eNodeB_linear(2,b_);
                    interf_macro_fading(:,(b_-1)*3+3,:)  = interfering_macroscopic_pathloss_eNodeB_linear(3,b_);
                    interf_shadow_fading(:,[(b_-1)*3+1,(b_-1)*3+2,(b_-1)*3+3],:) = interfering_shadow_fading_loss_linear(b_);
                end
                
                % ToDo: redo the geometry factor calculation
                % if obj.trace_geometry_factor
                %     geometry_factor_rx(:,s_,b_) = sum(interfering_TX_power,2)./interfering_macroscopic_pathloss_linear;
                % end
            end
            
            % Calculate thermal noise
            thermal_noise_watts_per_RB = 10^(0.1*(obj.downlink_channel.thermal_noise_dBW_RB + obj.receiver_noise_figure));
            
            % Add noise to the interfering RX power (ToDo: fix the
            % assumtion that we use the same power on all eNodeBs)
            
            if ~MIMO
                interfering_rx_power = squeeze(sum(TX_power_layer_half_RB./interf_macro_fading./interf_shadow_fading.*microscale_interfering_thetas,1));
                SINR_linear = user_microscale_fading_mode_params.zeta.*RX_power ./ (user_microscale_fading_mode_params.psi.*thermal_noise_watts_per_RB/2 + interfering_rx_power); % Divide thermal noise by 2: Half-RB frequency bins
            else
                interfering_rx_power = squeeze(sum(TX_power_layer_half_RB./interf_macro_fading./interf_shadow_fading.*microscale_interfering_thetas,2));
                SINR_linear = user_microscale_fading_mode_params.zeta.*RX_power ./ (user_microscale_fading_mode_params.chi*TX_power_layer_half_RB + user_microscale_fading_mode_params.psi.*thermal_noise_watts_per_RB/2 + interfering_rx_power); % Divide thermal noise by 2: Half-RB frequency bins
            end
            SINR_dB     = 10*log10(SINR_linear);
            
            % Finish this!!!!!!!
            
            % Geometry factor
            % if obj.trace_geometry_factor
            %    geometry_factor_rx_sum = sum(sum(geometry_factor_rx,2),3);
            %    geometry_factor_linear = geometry_factor_tx ./ geometry_factor_rx_sum;
            %    geometry_factor_log    = 10*log10(geometry_factor_linear);
            %    obj.last_measured_geometry_factor_dB = geometry_factor_log;
            %    obj.last_measured_geometry_factor_linear = geometry_factor_linear;
            % end
            
            % For SM we send 2 CQIs, one for each of the codewords (which in the 2x2
            % case are also the layers). For TxD, both layers have the same SINR
            % The CQI is calculated as a linear averaging of the SINRs in
            % dB. This is done because like this the Tx has an "overall
            % idea" of the state of the RB, not just a sample of it.
            switch tx_mode
                case 1 % SISO
                    SINRs_to_map_to_CQI = (SINR_dB(1:2:end)+SINR_dB(1:2:end))/2;
                    obj.last_measured_SINR_dB     = SINR_dB;
                    obj.last_measured_SINR_linear = SINR_linear;
                case 2 % TxD
                    % Both layers have the same SINR
                    SINRs_to_map_to_CQI = (SINR_dB(1,1:2:end)+SINR_dB(1,2:2:end))/2;
                    obj.last_measured_SINR_dB     = SINR_dB(1,:);
                    obj.last_measured_SINR_linear = SINR_linear(1,:);
                case 3 % OLSM
                    SINRs_to_map_to_CQI = (SINR_dB(:,1:2:end)+SINR_dB(:,2:2:end))/2;
                    obj.last_measured_SINR_dB     = SINR_dB;
                    obj.last_measured_SINR_linear = SINR_linear;
                otherwise
                    error('TX mode not yet supported');
            end
            
            % Send as feedback the CQI for each RB.
            if obj.unquantized_CQI_feedback
                obj.feedback_measured_CQI = obj.CQI_mapper.SINR_to_CQI(SINRs_to_map_to_CQI,false);
            else
                % flloring the CQI provides much better results than
                % rounding it, as by rounding it to a higher CQI you will
                % very easily jump the BLER to 1. The other way around it
                % will jump to 0.
                %obj.feedback_measured_CQI = round(obj.CQI_mapper.SINR_to_CQI(SINRs_to_map_to_CQI));
                obj.feedback_measured_CQI = floor(obj.CQI_mapper.SINR_to_CQI(SINRs_to_map_to_CQI));
            end
        end
        
        % Evaluate whether this TB arrived correctly by using the data from
        % the link quality model and feeding it to the link performance
        % model (BLER curves)
        function link_performance_model(obj)
            the_RB_grid = obj.downlink_channel.RB_grid;
            stream_number = the_RB_grid.nCodewords;
            SINR_dB     = obj.last_measured_SINR_dB;
            SINR_linear = obj.last_measured_SINR_linear;
            TB_CQI     = obj.eNodeB_signaling.TB_CQI;
            
            % Preallocate variables to store in trace
            TB_SINR_dB = zeros(1,stream_number);
            ACK        = zeros(1,stream_number);
            BLER       = zeros(1,stream_number);
            TB_size    = obj.eNodeB_signaling.TB_size; % Already contains 0 for the unused streams
            
            % Calculate TB SINR
            user_RBs           = (the_RB_grid.user_allocation==obj.id);
            assigned_RBs       = obj.eNodeB_signaling.num_assigned_RBs;
            tx_mode            = obj.eNodeB_signaling.tx_mode;
            nLayers            = obj.eNodeB_signaling.nLayers;
            nCodewords         = obj.eNodeB_signaling.nCodewords;
            rv_idxs            = obj.eNodeB_signaling.rv_idx;
            
            % NOTE: This needs to be changed into a per-layer SINR. A layer-to-stream translation will be needed
            UE_TB_SINR_idxs = logical(kron(user_RBs',[1 1])); % [1 0] should yield the target BLER more accurately (but of course less realistically,
            % as you only average over the feedbacked subcarriers and not all of the ones available on the trace)
            
            % Set feedback for all streams
            if assigned_RBs~=0
                switch tx_mode
                    case 1
                        % SISO
                        TB_SINRs_linear = SINR_linear(UE_TB_SINR_idxs);
                        TB_SINR_linear  = obj.SINR_averager.average(TB_SINRs_linear,TB_CQI);
                        TB_SINR_log     = 10*log10(TB_SINR_linear);
                        BLER            = obj.BLER_curves.get_BLER(TB_CQI,TB_SINR_log);
                        % Receive
                        ACK = [BLER<rand false];
                    case 2
                        %TxD (2x2)
                        TB_SINRs_linear = SINR_linear(UE_TB_SINR_idxs);
                        TB_SINR_linear  = obj.SINR_averager.average(TB_SINRs_linear,TB_CQI);
                        TB_SINR_log     = 10*log10(TB_SINR_linear);
                        BLER            = obj.BLER_curves.get_BLER(TB_CQI,TB_SINR_log);
                        % Receive
                        ACK = [BLER<rand false];
                    case 3
                        % OLSM (2x2)
                        UE_TB_SINR_idxs_layer = logical(kron(UE_TB_SINR_idxs,[1;1]));
                        TB_SINRs_linear = reshape(SINR_linear(UE_TB_SINR_idxs_layer),nLayers,[]);
                        for layer_=1:nLayers
                            TB_SINR_linear(layer_) = obj.SINR_averager.average(TB_SINRs_linear(layer_,:),TB_CQI(layer_));
                            TB_SINR_log(layer_)    = 10*log10(TB_SINR_linear(layer_));
                            BLER(layer_)           = obj.BLER_curves.get_BLER(TB_CQI(layer_),TB_SINR_log(layer_));
                        end
                        % Receive
                        ACK = BLER<rand(1,nLayers);
                    otherwise
                        error('Mode not yet supported');
                end
            else
                BLER = false(1,nLayers);
                ACK  = false(1,nCodewords);
            end
            
            % Prepare feedback
            obj.feedback_nCodewords           = nCodewords;
            obj.feedback_TB_ACK               = ACK;
            if nCodewords==1
                obj.feedback_TB_size          = [TB_size zeros(1,2:nCodewords)]';
            else
                obj.feedback_TB_size          = TB_size';
            end
            obj.feedback_TB_was_scheduled = (assigned_RBs~=0)';
            
            % Optional traces
            if obj.trace_SINR
                extra_traces{1} = SINR_dB;
            else
                extra_traces{1} = [];
            end
            
%             if obj.trace_geometry_factor
%                 extra_traces{2} = obj.last_measured_geometry_factor_dB;
%             else
%                 extra_traces{2} = [];
%             end
            
            % Store trace of the relevant information
            tti_idx = obj.clock.current_TTI;
            
            % Store trace
            obj.trace.store(...
                nCodewords,...
                obj.feedback_measured_CQI,...
                obj.attached_eNodeB.id,...
                obj.attached_sector,...
                obj.pos,tti_idx,...
                assigned_RBs,...
                ACK',...
                TB_CQI,...
                TB_size,...
                BLER,...
                extra_traces);
        end
    end
end
