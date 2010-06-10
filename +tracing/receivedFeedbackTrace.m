classdef receivedFeedbackTrace < handle
% This class stores all of the feedbacks received by eNodeBs in the
% network. It is done like this in order to be able to preallocate the space
% (you don't a priori know where each user will be).
% (c) Josep Colom Ikuno, INTHFT, 2008

   properties
       % To which UE this belongs
       UE_id
       % To which eNodeB-sector this belongs
       eNodeB_id
       sector_id
       % When was this received
       tti_idx
       % Idx that is now available to write
       current_idx
       % Info transmitted by the UE
       CQI
       ACK
       TB_size
       UE_scheduled
   end

   methods
       function obj = receivedFeedbackTrace(simulation_length_TTI,numUEs,n_RB,maxStreams,unquantized_CQI_feedback)
           % Trace of sent CQIs is initialized to -1 (an invalid value)
           obj.UE_id        = zeros(1,simulation_length_TTI*numUEs,'int32')-1;
           obj.eNodeB_id    = zeros(1,simulation_length_TTI*numUEs,'uint16');
           obj.sector_id    = zeros(1,simulation_length_TTI*numUEs,'uint8');
           obj.tti_idx      = zeros(1,simulation_length_TTI*numUEs)-1;
           
           % Info transmitted by the UE
           if unquantized_CQI_feedback
               obj.CQI      = zeros(n_RB,maxStreams,simulation_length_TTI*numUEs,'single')-1;
           else
               obj.CQI      = zeros(n_RB,maxStreams,simulation_length_TTI*numUEs,'int8')-1;
           end
           
           obj.ACK          = false(maxStreams,simulation_length_TTI*numUEs);
           obj.TB_size      = zeros(maxStreams,simulation_length_TTI*numUEs);
           % ToDo: improved UE_scheduled structure (get rid of the
           % per-stream handling)
           obj.UE_scheduled = false(maxStreams,simulation_length_TTI*numUEs);
           
           obj.current_idx  = 1;
       end
       function store(obj,CQI,ACK,TB_size,UE_scheduled,UE_id,eNodeB_id,sector_id,tti_idx)
           % Store the values           
           obj.UE_id(obj.current_idx)     = UE_id;
           obj.eNodeB_id(obj.current_idx) = eNodeB_id;
           obj.sector_id(obj.current_idx) = sector_id;
           obj.tti_idx(obj.current_idx)   = tti_idx;
           
           obj.CQI(:,1:size(CQI,1),obj.current_idx)       = CQI';
           obj.ACK(1:length(ACK),obj.current_idx)         = ACK;
           obj.TB_size(1:length(TB_size),obj.current_idx) = TB_size;
           obj.UE_scheduled(:,obj.current_idx)            = UE_scheduled;
           
           % Advance the counter 1 position
           obj.current_idx = obj.current_idx + 1;
       end
   end
end 
