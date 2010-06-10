classdef roundRobinScheduler < network_elements.lteScheduler
% An LTE round Robin scheduler.
% (c) Josep Colom Ikuno, INTHFT, 2008

   properties
       % Where the scheduler will store which users to serve first (round robin fashion)
       UE_queue
       
       % See the lteScheduler class for a list of inherited attributes
   end

   methods
       
       % Class constructor. UE_queue size needs to be specified large
       % enough so it won't overflow
       function obj = roundRobinScheduler(attached_eNodeB_sector,queue_size)
           % Fill in basic parameters (handled by the superclass constructor)
           obj = obj@network_elements.lteScheduler(attached_eNodeB_sector);
           
           obj.UE_queue              = utils.fifoQueue(queue_size);
       end
       
       % Print some info
       function print(obj)
           fprintf('Round Robin scheduler\n');
       end
       
       % Add a UE to the queue. It could be done so each TTI the scheduler
       % gets a UE list from the eNodeB, but such a query is not necessary.
       % Just updating when a UE attaches or drops is sufficient.
       function add_UE(obj,UE_id)
           obj.UE_queue.insert(UE_id);
       end
       
       % Delete an UE_id from the queue
       function remove_UE(obj,UE_id)
           obj.UE_queue.delete(UE_id);
       end
       
       % Next user to serve. If the queue is empty, returns 0
       function UE_id = get_next_user(obj)
           % Get the next user to be scheduled
           if obj.UE_queue.size==0
               UE_id = 0;
           else
               UE_id = obj.UE_queue.extract;
               % In case a UE was de-attached, discard the deleted UEs
               while (UE_id==0)&&obj.UE_queue.size~=0
                   UE_id = obj.UE_queue.extract;
               end
           end
           % Put the user in the queue again so it can be re-scheduled
           if UE_id~=0
               obj.UE_queue.insert(UE_id);
           end
       end
       
       % Schedule the users in the given RB grid
       function schedule_users(obj,RB_grid,attached_UEs,last_received_feedbacks)
           % Power allocation
           % Nothing here. Leave the default one (homogeneous)
           
           % For now use the static tx_mode assignment
           RB_grid.size_bits = 0;
           nCodewords  = RB_grid.nCodewords;
           nLayers     = RB_grid.nLayers;
           tx_mode     = RB_grid.tx_mode;
           
           if ~isempty(attached_UEs)
               % Unused codewords are set to 0
               for RB_idx=1:size(RB_grid.user_allocation,1)
                   current_UE_id = obj.get_next_user;
                   RB_grid.user_allocation(RB_idx) = current_UE_id;
               end
               
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
                           
                           attached_UEs(u_).eNodeB_signaling.nCodewords = nCodewords;
                           attached_UEs(u_).eNodeB_signaling.nLayers    = nLayers;
                           attached_UEs(u_).eNodeB_signaling.tx_mode    = tx_mode;
                           attached_UEs(u_).eNodeB_signaling.genie_TB_SINR = estimated_TB_SINR;
                       end
                   else
                       % How this right now works: no feedback->CQI of 1
                       UE_scheduled = true;
                       attached_UEs(u_).eNodeB_signaling.TB_CQI(1:nCodewords) = 1;
                       % Signal down the user CQI assignment
                       attached_UEs(u_).eNodeB_signaling.nCodewords = nCodewords;
                       attached_UEs(u_).eNodeB_signaling.nLayers    = nLayers;
                       attached_UEs(u_).eNodeB_signaling.tx_mode    = tx_mode;
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
