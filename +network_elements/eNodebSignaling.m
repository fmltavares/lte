classdef eNodebSignaling <handle
% Represents the signaling from the eNodeB to each UE.
%
% (c) Josep Colom Ikuno, INTHFT, 2008

   properties
       TB_CQI           % CQI used for the transmission of each codeword
       TB_size          % size of the current TB, in bits
       num_assigned_RBs % Number of assigned RBs
       tx_mode          % transmission mode used (SISO, tx diversity, spatial multiplexing)
       nLayers
       nCodewords       % How many codewords are being sent
       rv_idx           % redundancy version index (HARQ) for each codeword
       genie_TB_SINR    % Estimated TB SINR as calculated by the eNodeB
       
       % Other signaling, such as X-layer, could be placed here
   end

   methods
   end
end 
