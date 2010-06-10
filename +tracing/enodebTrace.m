classdef enodebTrace < handle
% This class stores, for each eNodeB the sector traces.
% (c) Josep Colom Ikuno, INTHFT, 2008

   properties
       sector_traces
   end

   methods
       function obj = enodebTrace(eNodeB,RB_grid_object,maxStreams,simulation_length_TTI)
           num_sectors = length(eNodeB.sectors);
           if num_sectors<1
               error('eNodeB must have at least 1 sector');
           end
           obj.sector_traces = tracing.sectorTrace(RB_grid_object,maxStreams,simulation_length_TTI);
           eNodeB.sectors(1).sector_trace = obj.sector_traces;
           for s_=2:num_sectors
               obj.sector_traces(s_) = tracing.sectorTrace(RB_grid_object,maxStreams,simulation_length_TTI);
               eNodeB.sectors(s_).sector_trace = obj.sector_traces(s_);
           end
       end
   end
end 
