classdef uplinkChannelModel < handle
% Represents the up channel model that a specific user possesses. Each UE
% instance will have its own specific channel model. It implements a
% circular buffer as a means to achieve the delay.
% note that it is designed to work in the following way:
%  1- UE inserts feedback
%  2- eNodeB retrieves feedback
%
% Note that it is not implemented with a FIFO class due to the fact that
% the TTI has to be checked prior to extracting the feedback.
% (c) Josep Colom Ikuno, INTHFT, 2008

   properties
       % Feedback buffer. Implements the delay as a circular buffer of length N
       feedback_buffer
       % Current_index where the data was last written
       insert_index
       % Current_index from where to retrieve the data
       retrieve_index
       % Delay in TTIs
       feedback_delay
       
       % User to which this channel model is attached to
       attached_UE
   end

   methods
       % class constructor
       function obj = uplinkChannelModel(aUE,n_RB,num_streams,delay)
           
           % zero-delay is implemented as zero delay for CQI feedback BUT
           % one-TTI delay for the ACK/NACK, as it is not possible to
           % implement the reception before the scheduling.
           % This is treated in the eNodeBsector.receive_UE_feedback
           % function (CQI is taken directly from the UE and not from the UL channel).
           if delay==0
               delay = 1;
           end
           
           obj.attached_UE    = aUE;
           obj.retrieve_index = 1;
           obj.insert_index   = delay; % Since the feedback is introduced
                                       % buffer AFTER the eNodeB retrieves
                                       % it, this is delay. IF you would
                                       % introduce the feedback BEFORE the
                                       % eNodeB reads it, change this to be
                                       % delay + 1
           obj.feedback_delay = delay;
           
           % Define the feedback message structure. TTI 0 represents an invalid value
           sample_feedback_structure.nCodewords   = 0;
           sample_feedback_structure.TTI_idx      = 0;
           sample_feedback_structure.CQI          = -1*ones(num_streams,n_RB);
           sample_feedback_structure.ACK          = false(1,num_streams);
           sample_feedback_structure.TB_size      = zeros(1,num_streams);
           sample_feedback_structure.UE_scheduled = false(1,num_streams);
           
           % Allocate and initialise the feedback buffer
           obj.feedback_buffer = repmat(sample_feedback_structure,1,delay+1);           
       end
       
       % Introduce a feedback into the channel
       function send_feedback(obj,nCodewords,CQI_value,ACK,TB_size,UE_scheduled) 
           % Index where to insert the feedback (circular delay buffer)
           obj.insert_index   = obj.insert_index + 1;
           if obj.insert_index==length(obj.feedback_buffer)+1
               obj.insert_index = 1;
           end
           
           obj.retrieve_index = obj.retrieve_index + 1;
           if obj.retrieve_index==length(obj.feedback_buffer)+1
               obj.retrieve_index = 1;
           end
           
           obj.feedback_buffer(obj.insert_index).nCodewords   = nCodewords;
           obj.feedback_buffer(obj.insert_index).TTI_idx      = obj.attached_UE.clock.current_TTI;
           obj.feedback_buffer(obj.insert_index).CQI          = CQI_value;
           obj.feedback_buffer(obj.insert_index).ACK          = ACK;
           obj.feedback_buffer(obj.insert_index).TB_size      = TB_size;
           obj.feedback_buffer(obj.insert_index).UE_scheduled = UE_scheduled;
       end
       
       % Retrieve a feedback from the channel
       function retrieved_feedback = get_feedback(obj)
           last_feedback = obj.feedback_buffer(obj.retrieve_index);
           current_tti = obj.attached_UE.clock.current_TTI;
           if (current_tti==last_feedback.TTI_idx+obj.feedback_delay)&&(last_feedback.TTI_idx~=0)
               retrieved_feedback = last_feedback;
           else
               retrieved_feedback = [];
           end
       end
       
   end
end 
