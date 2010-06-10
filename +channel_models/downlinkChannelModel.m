classdef downlinkChannelModel < handle
% Represents the downlink channel model that a specific user possesses. Each UE
% instance will have its own specific channel model.
% (c) Josep Colom Ikuno, INTHFT, 2008

   properties
       % These could actually be maps or an implementation that directly
       % calculates every time it is invoked.
       macroscopic_pathloss_model_is_set = false;
       macroscopic_pathloss_model
       shadow_fading_model_is_set = false;
       shadow_fading_model
       fast_fading_model_is_set = false;
       fast_fading_model
       
       % Noise power per RB
       thermal_noise_watts_RB
       thermal_noise_dBW_RB
       
       % User to which this channel model is attached to
       attached_UE
       
       % This variables model the downlink signaling and the data that was
       % transmitted
       % RB_grid (retrieved via a function call)
       
   end

   methods
       % class constructor
       function obj = downlinkChannelModel(aUE)
           obj.attached_UE = aUE;
       end
       % Returns the macroscopic pathloss in dB between the given user's
       % position and his eNodeB sector. Returns 0 in case no model is specified.
       function pathloss = macroscopic_pathloss(obj)
           if ~obj.macroscopic_pathloss_model_is_set
               pathloss = 0;
               return
           else
               % Get eNodeB id and sector number
               eNodeB_id = obj.attached_UE.attached_eNodeB.id;
               sector_id = obj.attached_UE.attached_sector;
               pos = obj.attached_UE.pos;
               % Now get the pathloss
               pathloss = obj.macroscopic_pathloss_model.get_pathloss(pos,sector_id,eNodeB_id);
           end
       end
       
       % Returns the macroscopic pathloss in dB between the given user's
       % position and a given eNodeB.
       function pathloss = interfering_macroscopic_pathloss(obj,interferingEnodeBids)
           if ~obj.macroscopic_pathloss_model_is_set
               pathloss = 0;
               return
           else
               pos = obj.attached_UE.pos;
               % Now get the pathloss
               pathloss = squeeze(obj.macroscopic_pathloss_model.get_pathloss(pos,:,interferingEnodeBids));
           end
       end
       
       % Returns the shadow fading pathloss in dB between the given user's
       % position and his eNodeB sector. Returns 0 in case no model is specified (for
       % example, when Odyssey data would be used).
       function pathloss = shadow_fading_pathloss(obj)
           if ~obj.shadow_fading_model_is_set
               pathloss = 0;
               return
           else
               % Get eNodeB id and sector number
               eNodeB_id = obj.attached_UE.attached_eNodeB.id;
               pos = obj.attached_UE.pos;
               pathloss = obj.shadow_fading_model.get_pathloss(pos,eNodeB_id);
           end
       end
       
       % Returns the shadow fading pathloss in dB between the given user's 
       % position and a given eNodeB. Returns 0 in case no model is specified (for
       % example, when Odyssey data would be used).
       function pathloss = interfering_shadow_fading_pathloss(obj,interferingEnodeBids)
           if ~obj.shadow_fading_model_is_set
               pathloss = 0;
               return
           else
               pos = obj.attached_UE.pos;
               pathloss = squeeze(obj.shadow_fading_model.get_pathloss(pos,interferingEnodeBids));
           end
       end
       
       % Returns the pathloss in LINEAR between the given user's
       % position and his eNodeB sector caused by fast fading. Actually
       % returns the frequency impulse response, so the frequency
       % selectivity can then be applied for each subcarrier. Probably this
       % is the only point in the simulator where we actually care about
       % subcarriers.
       % Returns 0 in case no model is specified.
       function ff_loss = fast_fading_pathloss(obj,t,MIMO)
           if ~obj.fast_fading_model_is_set
               ff_loss = 1;
               return
           else
               ff_loss = obj.fast_fading_model.generate_fast_fading(t,MIMO);
           end
       end
       
       % Returns the pathloss in LINEAR between the given user's
       % position and the specified eNodeB sector caused by fast fading.
       % The channel model keeps a fast fading realization for each eNodeB
       % stored, so it can then be retrieved when this eNodeB is
       % nieghboring/interfering
       function ff_loss = interfering_fast_fading_pathloss(obj,t,interferingEnodeB)
           if ~obj.fast_fading_model_is_set
               ff_loss = 1;
               return
           else
               % Get eNodeB id and sector number
               eNodeB_id = interferingEnodeB.id;
               sector_number = length(interferingEnodeB.sectors);
               ff_loss = zeros(obj.RB_grid.n_RB*2,sector_number);
               for s_ = 1:sector_number
                   % Get interfering Fast Fading
                   ff_loss(:,s_) = obj.interfering_fast_fading_models{eNodeB_id,s_}.generate_fast_fading(t);
               end               
           end
       end
       
       % Returns the RB_grid so this UE can know what belongs to him
       function the_RB_grid = RB_grid(obj)
           sector_num  = obj.attached_UE.attached_sector;
           the_RB_grid = obj.attached_UE.attached_eNodeB.sectors(sector_num).RB_grid;
       end
       % Set a macroscopic pathloss model
       function set_macroscopic_pathloss_model(obj,macroscopic_pathloss_model)
           obj.macroscopic_pathloss_model = macroscopic_pathloss_model;
           obj.macroscopic_pathloss_model_is_set = true;
       end
       % Set a shadow fading model
       function set_shadow_fading_model(obj,shadow_fading_model)
           obj.shadow_fading_model = shadow_fading_model;
           obj.shadow_fading_model_is_set = true;
       end
       % Set a fast fading model
       function set_fast_fading_model_model(obj,fast_fading_model)
           obj.fast_fading_model = fast_fading_model;
           obj.fast_fading_model_is_set = true;
       end
       
       % Sends data to the given UE ( to be called from the eNodeB). NOT
       % USED RIGHT NOW
       function send_data(obj)
       end
       % Receives the data. Applies the BLER given in the BLER tables
       function ACK = receive_data(obj,stream_num)
           
       end
   end
end 
