classdef simTraces < handle
% This class stores in an ordered way the traces of all of the enodeBs and
% UEs.
% (c) Josep Colom Ikuno, INTHFT, 2008

   properties
       % Traces of what the UE sends and receives
       UE_traces
       % Traces of what the eNodeb sends
       eNodeB_tx_traces
       % Traces of the UEs feedback
       eNodeB_rx_feedback_traces
       % Traces from the schedulers
       scheduler_traces
   end
end 
