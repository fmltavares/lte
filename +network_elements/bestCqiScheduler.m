classdef bestCqiScheduler < network_elements.lteScheduler
% A best CQI LTE scheduler.
% (c) Josep Colom Ikuno, INTHFT, 2009

   properties
       % See the lteScheduler class for a list of inherited attributes
   end

   methods
       
       % Class constructor. Just specify where to attach the scheduler
       function obj = bestCqiScheduler(attached_eNodeB_sector)
           % Fill in basic parameters (handled by the superclass constructor)
           obj = obj@network_elements.lteScheduler(attached_eNodeB_sector);
       end
       
       % Print some info
       function print(obj)
           fprintf('Best CQI scheduler\n');
       end
       
       % Dummy functions required by the lteScheduler Abstract class implementation
       % Add UE (no memory, so empty)
       function add_UE(obj,UE_id)
       end
       % Delete UE (no memory, so empty)
       function remove_UE(obj,UE_id)
       end
       
       % Schedule the users in the given RB grid
       function schedule_users(obj,RB_grid,attached_UEs,last_received_feedbacks)
           % Power allocation
           % Nothing here. Leave the default one (homogeneous)
           
           RB_grid.size_bits = 0;
           
           % For now use the static tx_mode assignment
           RB_grid.size_bits = 0;
           nCodewords  = RB_grid.nCodewords;
           nLayers     = RB_grid.nLayers;
           tx_mode     = RB_grid.tx_mode;
           
           if ~isempty(attached_UEs)
               
               if nCodewords==1
                   UE_id_list = obj.get_max_UEs(last_received_feedbacks.CQI(:,:,1),last_received_feedbacks.UE_id);
               else
                   % Throughput-wise maximization (sum the expected throughput from both streams)
                   quantized_feedback_efficiency = obj.get_spectral_efficiency(last_received_feedbacks.CQI);
                   quantized_feedback_efficiency_sum = sum(quantized_feedback_efficiency,3);
                   UE_id_list =  obj.get_max_UEs(quantized_feedback_efficiency_sum,last_received_feedbacks.UE_id);
               end
               
               % Fill in RB grid
               RB_grid.user_allocation(:) = UE_id_list;
               
               % CQI assignment. TODO: implement HARQ
               RB_grid_size_bits = 0;
               predicted_UE_BLERs = NaN(nCodewords,length(attached_UEs));
               assigned_UE_RBs    = zeros(1,length(attached_UEs));
               for u_=1:length(attached_UEs)
                   if last_received_feedbacks.feedback_received(u_)
                       
                       UE_CQI_feedback = squeeze(last_received_feedbacks.CQI(u_,:,:));
                       
                       % Do not use RBs with a CQI of 0 (they are lost)
                       if nCodewords == 1
                           RB_grid.user_allocation((RB_grid.user_allocation==u_)&(UE_CQI_feedback'<1)) = 0;
                       else
                           % For the case where more than 1 codewords are
                           % sent, all CWs must have a CQI >0
                           zero_CQIs = sum(UE_CQI_feedback<1,2);
                           RB_grid.user_allocation((RB_grid.user_allocation==u_)&(zero_CQIs>=1)) = 0;
                       end
                       
                       assigned_RBs = (RB_grid.user_allocation==u_);
                       if nCodewords==1
                           CQIs_to_average_all = UE_CQI_feedback(assigned_RBs);
                       else
                           CQIs_to_average_all = UE_CQI_feedback(assigned_RBs,:);
                       end
                       
                       if isempty(CQIs_to_average_all)
                           UE_scheduled = false;
                       else
                           UE_scheduled = true;
                       end
                       
                       if UE_scheduled
                           % Simplified this piece of code by using the superclass, as all types of scheduler will to make use of it.
                           [assigned_CQI predicted_UE_BLERs(:,u_) estimated_TB_SINR] = obj.get_optimum_CQIs(CQIs_to_average_all,nCodewords);
                           % Signal down the user CQI assignment
                           attached_UEs(u_).eNodeB_signaling.TB_CQI = assigned_CQI;
                           
                           attached_UEs(u_).eNodeB_signaling.nCodewords    = nCodewords;
                           attached_UEs(u_).eNodeB_signaling.nLayers       = nLayers;
                           attached_UEs(u_).eNodeB_signaling.tx_mode       = tx_mode;
                           attached_UEs(u_).eNodeB_signaling.genie_TB_SINR = estimated_TB_SINR;
                       end
                   else
                       % How this right now works: no feedback->CQI of 1
                       UE_scheduled = true;
                       attached_UEs(u_).eNodeB_signaling.TB_CQI(1:nCodewords) = 1;
                       % Signal down the user CQI assignment
                       attached_UEs(u_).eNodeB_signaling.nCodewords    = nCodewords;
                       attached_UEs(u_).eNodeB_signaling.nLayers       = nLayers;
                       attached_UEs(u_).eNodeB_signaling.tx_mode       = tx_mode;
                       attached_UEs(u_).eNodeB_signaling.genie_TB_SINR = NaN;
                       predicted_UE_BLERs(u_) = 0; % Dummy value to avoid a NaN
                   end
                   
                   if UE_scheduled
                       TB_CQI_params = obj.CQI_tables(attached_UEs(u_).eNodeB_signaling.TB_CQI);
                       modulation_order = [TB_CQI_params.modulation_order];
                       coding_rate = [TB_CQI_params.coding_rate_x_1024]/1024;
                       num_assigned_RB  = squeeze(sum(RB_grid.user_allocation==attached_UEs(u_).id));
                       TB_size_bits = floor(RB_grid.sym_per_RB .* num_assigned_RB .* modulation_order .* coding_rate);
                   else
                       num_assigned_RB = 0;
                       TB_size_bits = 0;
                   end
                   
                   attached_UEs(u_).eNodeB_signaling.num_assigned_RBs = num_assigned_RB;
                   attached_UEs(u_).eNodeB_signaling.TB_size = TB_size_bits;
                   attached_UEs(u_).eNodeB_signaling.rv_idx = 0;
                   
                   RB_grid_size_bits = RB_grid_size_bits + TB_size_bits;
                   
                   assigned_UE_RBs(u_) = num_assigned_RB;
               end
               
               RB_grid.size_bits = RB_grid_size_bits;
               
               % TODO: HARQ handling, #streams decision and tx_mode decision. Also power loading
               
               % Store trace
               TTI_idx = obj.attached_eNodeB_sector.parent_eNodeB.clock.current_TTI;
               obj.trace.store(TTI_idx,mean(assigned_UE_RBs),mean(predicted_UE_BLERs(isfinite(predicted_UE_BLERs))));
           end
       end
   end
end 
