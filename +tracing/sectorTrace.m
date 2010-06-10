classdef sectorTrace < handle
% This class stores, for each eNodeB's sector the traces that we wanto to store. eg, CQI assignments,
% throughput, etc, etc.
% (c) Josep Colom Ikuno, INTHFT, 2008

   properties
       % whose slot is each
       user_allocation
       % how much power to allocate to each slot, in Watts
       power_allocation
       % Current insertion index. One trace is stored every TTI, so no need
       % to care about "holes". This is equal to the TTI
       TTI_idx
       % Sent data this TTI (bits)
       sent_data
       % Data that was acknowledged (bits)
       acknowledged_data
       % Equivalent but for TBs
       expected_ACKs % Total number of TBs sent (eg. sum of ACKs and NACKs)
       received_ACKs % The ones that were ACKs
   end

   methods
       function obj = sectorTrace(RB_grid_object,maxStreams,simulation_length_TTI)
           %time_slots_power_allocation = size(RB_grid_object.power_allocation,1);
           n_RB = RB_grid_object.n_RB;
           obj.user_allocation   = zeros(n_RB,simulation_length_TTI,'uint16');
           %obj.power_allocation  = zeros(time_slots_power_allocation,n_RB,maxStreams,simulation_length_TTI);
           obj.sent_data         = zeros(maxStreams,simulation_length_TTI,'uint32');
           obj.acknowledged_data = zeros(maxStreams,simulation_length_TTI,'uint32');
           obj.expected_ACKs     = zeros(maxStreams,simulation_length_TTI,'uint16');
           obj.received_ACKs     = zeros(maxStreams,simulation_length_TTI,'uint16');
           obj.TTI_idx = 1;
       end
       % Stores 
       function store(obj,the_RB_grid)
           obj.user_allocation(:,obj.TTI_idx) = the_RB_grid.user_allocation;
           %obj.power_allocation(:,:,:,obj.TTI_idx) = the_RB_grid.power_allocation;
           obj.sent_data(1:the_RB_grid.nCodewords,obj.TTI_idx) = the_RB_grid.size_bits;
           obj.TTI_idx = 1 + obj.TTI_idx;
       end
       % Add the trace from a feedback report
       function store_ACK_report(obj,nCodewords,UE_scheduled,ACK,TB_size,trace_TTI)
           % Do this just in case the ACK report is incorrectly filled. The
           % most important check is whether the user was scheduled or not.
           correct_TB_size = uint32(UE_scheduled .* ACK(:) .* TB_size(:));
           obj.acknowledged_data(:,trace_TTI) = obj.acknowledged_data(:,trace_TTI) + correct_TB_size;
           max_streams = size(obj.expected_ACKs,1);
           if UE_scheduled
               obj.expected_ACKs(:,trace_TTI) = obj.expected_ACKs(:,trace_TTI) + [ones(nCodewords,1,'uint16');zeros(max_streams-nCodewords,1,'uint16')];
               obj.received_ACKs(:,trace_TTI) = obj.received_ACKs(:,trace_TTI) + uint16(ACK(:));
           end
       end
   end
end 
