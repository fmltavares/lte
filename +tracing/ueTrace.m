classdef ueTrace < handle
% This class stores, for each UE the traces that we wanto to store. eg, CQI,
% throughput, etc, etc.
% (c) Josep Colom Ikuno, INTHFT, 2008

   properties
       latency_time_scale % This is used to compute the averate throughput using an exponential filter
       TTI_length_s
       nCodewords
       CQI_sent
       attached_eNodeB
       attached_sector
       position
       assigned_RBs
       ACK
       TB_CQI
       TB_size
       BLER % The used BLER for this TB
       avg_throughput
       
       % Optional traces (can be turned on/off in the config file)
       trace_SINR = false;
       SINR            % Stores the TB SINR
       trace_geometry_factor = false;
       geometry_factor % Stores the SINR (dB) due only to macroscale pathloss
   end

   methods
       function obj = ueTrace(simulation_length_TTI,n_RB,maxStreams,traces_config,latency_time_scale,TTI_length_s)
           
           % Trace of sent CQIs is initialized to -1 (an invalid value).
           % Storing more than 1 CQI feedback per TTI is supported.
           if traces_config.unquantized_CQI_feedback
               obj.CQI_sent    = zeros(maxStreams,n_RB,simulation_length_TTI,'single')-1;
           else
               obj.CQI_sent    = zeros(maxStreams,n_RB,simulation_length_TTI,'int8')-1;
           end
           
           obj.latency_time_scale = latency_time_scale;
           obj.TTI_length_s       = TTI_length_s;
           obj.nCodewords         = zeros(1,simulation_length_TTI,'uint8');
           obj.attached_eNodeB    = zeros(1,simulation_length_TTI,'uint16');
           obj.attached_sector    = zeros(1,simulation_length_TTI,'uint8');
           obj.position           = NaN(2,simulation_length_TTI);
           obj.assigned_RBs       = zeros(maxStreams,simulation_length_TTI,'uint8');
           obj.ACK                = false(maxStreams,simulation_length_TTI);
           obj.TB_CQI             = NaN(maxStreams,simulation_length_TTI,'single');
           obj.TB_size            = zeros(maxStreams,simulation_length_TTI,'uint32'); % Max is 80*6*200 (20 MHz, 1 ms for 1 user)
           obj.BLER               = zeros(maxStreams,simulation_length_TTI);
           obj.avg_throughput     = zeros(maxStreams,simulation_length_TTI);
           
           % Not yet adapted to MIMO transmissions
           if traces_config.trace_SINR
               obj.trace_SINR = true;
               obj.SINR = zeros(maxStreams,2*n_RB,simulation_length_TTI);
           end
           
           if traces_config.trace_geometry_factor
               obj.trace_geometry_factor = true;
               obj.geometry_factor = zeros(2,simulation_length_TTI);
           end
       end
       % Trace this specific TTI
       function store(obj,nCodewords,CQI,attached_eNodeB,attached_sector,position,tti_idx,assigned_RBs,ACK,TB_CQI,TB_size,BLER,extra_traces)
           % Optional varargin variables to trace are:
           %  - extra_traces{1} -> SINR
           %  - extra_traces{2} -> geometry_factor
           
           obj.nCodewords(tti_idx)                          = nCodewords;
           obj.CQI_sent(1:size(CQI,1),:,tti_idx)            = CQI;
           obj.attached_eNodeB(tti_idx)                     = attached_eNodeB;
           obj.attached_sector(tti_idx)                     = attached_sector;
           obj.position(:,tti_idx)                          = position;
           obj.assigned_RBs(1:size(assigned_RBs,1),tti_idx) = assigned_RBs;
           obj.ACK(1:size(ACK,1),tti_idx)                   = ACK;
           obj.TB_CQI(1:length(TB_CQI),tti_idx)             = TB_CQI;
           obj.TB_size(1:length(TB_size),tti_idx)           = TB_size;
           obj.BLER(1:length(BLER),tti_idx)                 = BLER;
           
           throughput = TB_size(:).*ACK(:) / obj.TTI_length_s;
           if tti_idx==1
               obj.avg_throughput(1:length(throughput),tti_idx) = throughput;
           else
               obj.avg_throughput(1:length(throughput),tti_idx) = (1-1/obj.latency_time_scale)*obj.avg_throughput(1:length(throughput),tti_idx-1) + 1/obj.latency_time_scale*throughput(:);
           end
           
           if obj.trace_SINR
               obj.SINR(:,:,tti_idx) = extra_traces{1};
           end
           
           if obj.trace_geometry_factor
               obj.geometry_factor(:,tti_idx) = extra_traces{2};
           end
       end
   end
end 
