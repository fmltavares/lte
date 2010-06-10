classdef fastFadingWrapper < handle
% Wraps a trace of pregenerated fast fading coefficients
% (c) Josep Colom Ikuno, INTHFT, 2008

   properties
       ff_trace
       starting_point
       interfering_starting_points
   end

   methods
       % Class constructor. num_eNodeBs and num_sectors are used to add a
       % correct number of interferers (one per eNodeBs and sector)
       function obj = fastFadingWrapper(pregenerated_ff,starting_point,num_eNodeBs,num_sectors)
           switch starting_point
               case 'random'
                   start_point_t             = rand * pregenerated_ff.trace_length_s;
                   interferer_start_points_t = rand(num_eNodeBs,num_sectors) * pregenerated_ff.trace_length_s;
                   start_point_idx           = floor(start_point_t / pregenerated_ff.t_step) + 1;
                   start_points_idx_interf   = floor(interferer_start_points_t / pregenerated_ff.t_step) + 1;
               otherwise
                   error('Only a random starting point is now allowed');
           end
           obj.ff_trace = pregenerated_ff;
           obj.starting_point = start_point_idx;
           obj.interfering_starting_points = start_points_idx_interf;
       end

       function microscale_fading = generate_fast_fading(obj,t,MIMO)
           % Index for the target channel
           index_position = floor(t/obj.ff_trace.t_step);
           index_position_plus_start = index_position + obj.starting_point;
           index_position_mod = (mod(index_position_plus_start,obj.ff_trace.trace_length_samples))+1;
           
           % Get the indexes for the interfering channels
           index_position_plus_start_interf = index_position + obj.interfering_starting_points;
           index_position_interf_mod        = (mod(index_position_plus_start_interf,obj.ff_trace.trace_length_samples))+1;
           
           if MIMO % MIMO traces
               % TxD trace
               microscale_fading{2}.zeta  = squeeze(obj.ff_trace.traces{2}.trace.zeta(:,index_position_mod,:));
               microscale_fading{2}.chi   = squeeze(obj.ff_trace.traces{2}.trace.chi(:,index_position_mod,:));
               microscale_fading{2}.psi   = squeeze(obj.ff_trace.traces{2}.trace.psi(:,index_position_mod,:));
               
               microscale_fading{2}.theta = squeeze(obj.ff_trace.traces{2}.trace.theta(:,index_position_interf_mod(:),:));
               microscale_fading{2}.eNodeBs_sectors = size(index_position_plus_start_interf);
               
               % OLSM trace
               microscale_fading{3}.zeta  = squeeze(obj.ff_trace.traces{3}.trace.zeta(:,index_position_mod,:));
               microscale_fading{3}.chi   = squeeze(obj.ff_trace.traces{3}.trace.chi(:,index_position_mod,:));
               microscale_fading{3}.psi   = squeeze(obj.ff_trace.traces{3}.trace.psi(:,index_position_mod,:));
               
               microscale_fading{3}.theta = squeeze(obj.ff_trace.traces{3}.trace.theta(:,index_position_interf_mod(:),:));
               microscale_fading{3}.eNodeBs_sectors = size(index_position_plus_start_interf);
           else % SISO traces
               
               % SISO trace
               microscale_fading{1}.zeta  = squeeze(obj.ff_trace.traces{1}.trace.zeta(index_position_mod,:));
               microscale_fading{1}.psi   = squeeze(obj.ff_trace.traces{1}.trace.psi(index_position_mod,:));
               
               microscale_fading{1}.theta = squeeze(obj.ff_trace.traces{1}.trace.theta(index_position_interf_mod(:),:));
               microscale_fading{1}.eNodeBs_sectors = size(index_position_plus_start_interf);
           end
       end
   end
end 
