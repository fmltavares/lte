classdef sinrAverager < handle
    % Defines the abstract classes needed by a class that implements a SINR
    % averaging method
    % (c) Josep Colom Ikuno, INTHFT, 2008

   properties
   end

   methods (Abstract)
       effective_SINR = average(SINR_vector,MCSs)
   end
end 
