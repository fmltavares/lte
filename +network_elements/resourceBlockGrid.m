classdef resourceBlockGrid < handle
% Represents the recource block grid that the scheduler must allocate every
% TTI. Frequency length will depend on the frequency bandwidth. Time length
% will always be 1 ms.
% The grids are organized in the following way:
%
% |<----frequency---->
%  ____ ____ ____ ____  ___
% |____|____|____|____|  |  time (2 subframes)
% |____|____|____|____| _|_
%
% Where the frequency width obviously depends on the allocated bandwidth
% and the tiem-dimension width is always 2. Access the grid in the
% following way (example for the user allocation):
%
% user_allocation(time_index,frequency_index);
%
% (c) Josep Colom Ikuno, INTHFT, 2008

   properties
       % whose slot is each
       user_allocation
       % how much power to allocate to each slot, in Watts
       power_allocation
       % number of RB (freq domain)
       n_RB
       % number of symbols per Resource Element (RE), which is 12 subcarriers and 0.5 ms
       sym_per_RB
       % total size of the RB grid in bits
       size_bits

       nCodewords
       nLayers
       tx_mode
   end

   methods
       
       % Class constructor and initialisation. Initialise CQIs to 0
       function obj = resourceBlockGrid(n_RB,sym_per_RB,nCodewords,nLayers)
           obj.user_allocation  = zeros(n_RB,1,'uint16'); % We will assume that the streams cannot be scheduled to different UEs.
           obj.power_allocation = zeros(n_RB,nCodewords); % For now we will only allow for power allocation changes every 1 ms (subframe-based, not slot-based)
           obj.n_RB             = n_RB;
           obj.sym_per_RB       = sym_per_RB;
           obj.size_bits        = zeros(1,nCodewords);
           obj.nCodewords       = nCodewords;
           obj.nLayers          = nLayers;
       end
       
       % Sets the power allocation to a default value. Useful for setting a
       % homogeneous power allocation
       function set_homogeneous_power_allocation(obj,power_in_watts)
           power_per_RB = power_in_watts / obj.n_RB;
           obj.power_allocation = power_per_RB*ones(size(obj.power_allocation));
           % Set the power allocation for stream 1 to 0 W (Stream not active)
           obj.power_allocation(:,2:end) = 0;
       end
       function print(obj)
           fprintf('n_RB=%d\n',obj.n_RB);
       end
   end
end 
