function pregenerated_fast_fading = LTE_init_get_microscale_fading_SL_trace
% Generate the fading parameters that model the fast (microscale) fading at
% system level.
% Author: Josep Colom Ikuno, jcolom@nt.tuwien.ac.at.
% (c) 2009 by INTHFT
% www.nt.tuwien.ac.at

%clc;
%close all;

%% Config

% Possible Tx modes are:
%   1: Single Antenna
%   2: Transmit Diversity
%   3: Open Loop Spatial Multiplexing
%   4: Closed Loop SM
% Number of antenna ports can either be 2 or 4
% Codebook index specifies the codebook index as of TS.36.211 (for closed loop SM)
% nLayers specifies how many layers (symbols) are going to be transmitted.
% Either 1, 2, 3 or 4

standalone = false;
show_trace_generation_debug = true;

if standalone
    % Initial config (standalone example)
    config.system_bandwidth = 3e6;
    config.channel_type = 'PedB';
    config.nTX = 2;
    config.nRX = 2;
    config.trace_length_s = 0.5;
    config.UE_speed = 5 / 3.6; % 5 KM/h, converted to m/s
    config.parallel_toolbox_installed = false;
    
else
    % Initial config (simulator-linked)
    global LTE_config;
    config.system_bandwidth = LTE_config.bandwidth;
    config.channel_type = LTE_config.channel_model.type;
    config.nTX = LTE_config.nTX;
    config.nRX = LTE_config.nRX;
    config.trace_length_s = LTE_config.channel_model.trace_length;
    config.UE_speed = LTE_config.UE_speed; % converted to m/s
    config.parallel_toolbox_installed = LTE_config.parallel_toolbox_installed;
end

% We now have all of the possible precoding combinations stored
precoding_configs = get_all_precoding_combinations;

for i_ = 1:length(precoding_configs)
    precoding_matrices{i_} = get_precoding_matrix(precoding_configs(i_));
end

% Channel trace for the target channel
print_log(1,sprintf('Generating channel trace of length %3.2fs\\n',ceil(config.trace_length_s)));
H_trace1 = LTE_init_generate_FF_tracev2(config.system_bandwidth,config.channel_type,config.nTX,config.nRX,config.trace_length_s,config.UE_speed);
% Interfering channel trace
print_log(1,sprintf('Generating interfering channel trace of length %3.2fs\\n',ceil(config.trace_length_s)));
H_trace2 = LTE_init_generate_FF_tracev2(config.system_bandwidth,config.channel_type,config.nTX,config.nRX,config.trace_length_s,config.UE_speed);

%% Channel normalization

% The average frobenius norm of the channel is nRX x nTX. We will normalize
% it to be nRX. Then, by normalizing the TX antenna power to 1/nTX,
% SNR=1/sigma^2 (from SNR=(Nt||H||^2)/(Nr sigma2)
% The channel matrix trace is put in an object so whenever it is passed on
% to a function, the memory usage is not doubled (data copied to the
% stack).

%H_trace_normalized          = phy_modeling.HTrace;
%H_trace_interf_normalized   = phy_modeling.HTrace;
H_trace_normalized        = H_trace1.H_RB_samples / sqrt(config.nTX);
H_trace_interf_normalized = H_trace2.H_RB_samples / sqrt(config.nTX);

% Free up memory
clear H_trace1;
clear H_trace2;

% The channel trace is stored in H_trace.H_RB_samples, containing a
% (nRX,nTX,subframe_num,sample_num) matrix. We will calculate the SINR
% trace for each of these samples (every 6 subcarriers).

if config.nTX>1 && config.nRX>1
    MIMO = true;
else
    MIMO = false;
end

if MIMO
    if config.parallel_toolbox_installed
        matlabpool open;
    end
    
    %% Get precoding matrices: OLSM, 2 Antenna ports, 2 layers
    codebook_idx = 3;  % 2AT ports, 2 Layers
    precoding_matrix = precoding_matrices{codebook_idx};
    
    OLSM_2x2_trace = phy_modeling.txModeTrace;
    LTE_common_OLSM_2x2_trace(config,H_trace_normalized,H_trace_interf_normalized,precoding_matrix,OLSM_2x2_trace,show_trace_generation_debug);
    
    %% Get TxD precoding matrix for 2x2
    codebook_idx = 1; % 2 AT ports, 2 layers (in TxD nLayers = nAT ports)
    precoding_matrix = precoding_matrices{codebook_idx};
    
    TxD_2x2_trace = phy_modeling.txModeTrace;
    LTE_common_TxD_2x2_trace(config,H_trace_normalized,H_trace_interf_normalized,precoding_matrix,TxD_2x2_trace,show_trace_generation_debug);
    
    if config.parallel_toolbox_installed
        matlabpool close;
    end
else
    %% SISO trace
    SISO_trace = phy_modeling.txModeTrace;
    LTE_common_SISO_trace(config,H_trace_normalized,H_trace_interf_normalized,SISO_trace,show_trace_generation_debug);
end

%% Create output fast fading trace
pregenerated_fast_fading                      = phy_modeling.PregeneratedFastFading;
pregenerated_fast_fading.trace_length_s       = config.trace_length_s;
pregenerated_fast_fading.trace_length_samples = config.trace_length_s / 1e-3;
pregenerated_fast_fading.system_bandwidth     = config.system_bandwidth;
pregenerated_fast_fading.channel_type         = config.channel_type;
pregenerated_fast_fading.nTX                  = config.nTX;
pregenerated_fast_fading.nRX                  = config.nRX;
pregenerated_fast_fading.UE_speed             = config.UE_speed;

pregenerated_fast_fading.t_step               = 1e-3;
pregenerated_fast_fading.f_step               = 15e3*6;

if MIMO
    % TxD trace (mode 2)
    pregenerated_fast_fading.traces{2} = TxD_2x2_trace;
    
    % OLSM trace (mode 3)
    pregenerated_fast_fading.traces{3} = OLSM_2x2_trace;
else
    % SISO trace
    pregenerated_fast_fading.traces{1} = SISO_trace;
end

function precoding_matrices = get_precoding_matrix(precoding_config)
% This function returns the precoding matrix for a specific transmission mode
% Author: Stefan Schwarz, sschwarz@nt.tuwien.ac.at, modified by Josep Colom
% Ikuno, jcolom@nt.tuwien.ac.at
% (c) 2009 by INTHFT
% www.nt.tuwien.ac.at

tx_mode = precoding_config.tx_mode;
nAtPort = precoding_config.nAtPort;
nLayers = precoding_config.nLayers;

%% Check correctness of the combination of nAtPort and nLayers
if tx_mode == 1
    % SISO case
    if (nAtPort~=1 && nLayers~=1)
        error('SISO mode only accepts 1 layers and 1 codeword');
    end
else
    if (nAtPort~=2 && nAtPort~=4)
        error('MIMO modes require of 2 o 4 antenna ports');
    end
    if nLayers > nAtPort
        error('number of layers must be equal or lower than number of antenna ports');
    end
end

if tx_mode == 2
    % TxD mode
    if (nAtPort ~= nLayers)
        error('TxD requires nLayers=nAtPorts');
    end
elseif tx_mode == 3
    % OLSM (named Large CDD in the standard)
    if nLayers == 1
        error('Large delay CDD is only defined for 2, 3 or 4 layers. tx_mode 3 with 1 layer is tx_mode 2 (TS.36.213, table 7.2.3-0)');
    end
elseif tx_mode == 4
    % CLSM
else
    error('tx_mode %d not defined in this function',tx_mode);
end

%% Codebook setting
% CLSM
if tx_mode == 4
    if ~isfield(precoding_config,'codebook_idxs')
        error('For tx_mode 4 a codebook index set must be specified');
    end
    codebook_indexs = precoding_config.codebook_idxs;
    % OLSM
elseif tx_mode == 3
    % OLSM uses codebooks 12-15 in a cyclic way. Thus we set codebook_index to [12 13 14 15]
    if nAtPort==4
        codebook_index = [12 13 14 15];
    elseif nAtPort==2
        codebook_index = 0;
    end
end

LTE_params = LTE_params_function;

% Transmit diversity
if (tx_mode == 2)
    % We call the precoding matrix of TxD Z
    % Matrix corresponding to 36.211 section 6.3.4.3  
    precoding_matrices.Z = LTE_params.Z{nAtPort/2};
    precoding_matrices.name = 'TxD';
    precoding_matrices.tx_mode = tx_mode;
    precoding_matrices.nAtPort = nAtPort;
    precoding_matrices.nLayers = nLayers;

% Open loop spatial multiplexing, section 6.3.4.2.2 (Large CDD)
elseif (tx_mode == 3)   
    precoding_matrices.U = LTE_params.U_l{nLayers};
    precoding_matrices.D = LTE_params.D_l{nLayers};
    if (nAtPort == 2)
        W = LTE_params.W{nLayers}(:,:,codebook_index+1);
    else
        W_temp = 1/sqrt(nLayers)*LTE_params.Wn(:,:,codebook_index+1);
        % nLayers long Cyclic precoding matrix
        W = zeros(4,nLayers,4);
        for ii = 13:16
            W(:,:,ii-12) = W_temp(:,LTE_params.mapping{nLayers}(ii,:),ii-12);
        end
    end
    precoding_matrices.W = W;
    precoding_matrices.name = 'OLSM';
    precoding_matrices.tx_mode = tx_mode;
    precoding_matrices.nAtPort = nAtPort;
    precoding_matrices.nLayers = nLayers;
    precoding_matrices.codebook_index = codebook_index;
    
% Closed loop spatial multiplexing, section 6.3.4.2.1
else
    W = zeros(nAtPort,nLayers,length(codebook_indexs));
    if (nAtPort == 2)
        if (min(codebook_indexs)<0 || max(codebook_indexs)>3) && nLayers ==1
            error('Only codebooks 0-3 are defined for %d layers (see TS.36.211, Table 6.3.4.2.3-1)',nLayers);
        elseif (min(codebook_indexs)<0 || max(codebook_indexs)>2) && nLayers ==2
            error('Only codebooks 0-2 are defined for %d layers (see TS.36.211, Table 6.3.4.2.3-1)',nLayers);
        end
        for cb_ = 1:length(codebook_indexs)
            codebook_index = codebook_indexs(cb_);
            W(:,:,cb_) = LTE_params.W{nLayers}(:,:,codebook_index+1);
        end
    else
        if min(codebook_indexs)<0 || max(codebook_indexs)>15
            error('Only codebooks 0-15 are defined (see TS.36.211, Table 6.3.4.2.3-2)');
        end
        for cb_ = 1:length(codebook_indexs)
            codebook_index = codebook_indexs(cb_);
            W_temp = 1/sqrt(nLayers)*LTE_params.Wn(:,:,codebook_index+1);
            W(:,:,cb_) = W_temp(:,LTE_params.mapping{nLayers}(codebook_index+1,:),1);
        end
    end
    precoding_matrices.W = W;
    precoding_matrices.name = 'CLSM';
    precoding_matrices.tx_mode = tx_mode;
    precoding_matrices.nAtPort = nAtPort;
    precoding_matrices.nLayers = nLayers;
    precoding_matrices.codebook_index = codebook_indexs;
end

function LTE_params = LTE_params_function
% Re-create needed load_parameters data from Link level for the generation of the precoding matrices.
% (c) Josep Colom Ikuno, INTHFT, 2008
% www.nt.tuwien.ac.at


%% Create the Codebook for Precoding

% Transmit diversity
LTE_params.Z{1} =  [1, 0, 1i,  0;
         0,-1,  0, 1i;
         0, 1,  0, 1i;
         1, 0,-1i,  0];
LTE_params.Z{2} =  [1, 0, 0, 0, 1i,  0,  0, 0;
         0, 0, 0, 0,  0,  0,  0, 0;
         0,-1, 0, 0,  0, 1i,  0, 0;
         0, 0, 0, 0,  0,  0,  0, 0;
         0, 1, 0, 0,  0, 1i,  0, 0;
         0, 0, 0, 0,  0,  0,  0, 0;
         1, 0, 0, 0,-1i,  0,  0, 0;
         0, 0, 0, 0,  0,  0,  0, 0;
         0, 0, 0, 0,  0,  0,  0, 0;
         0, 0, 1, 0,  0,  0, 1i, 0;
         0, 0, 0, 0,  0,  0,  0, 0;
         0, 0, 0,-1,  0,  0,  0,1i;
         0, 0, 0, 0,  0,  0,  0, 0;
         0, 0, 0, 1,  0,  0,  0,1i;
         0, 0, 0, 0,  0,  0,  0, 0;
         0, 0, 1, 0,  0,  0,-1i, 0];
     
% Spatial multiplexing
U_temp = [  1,-1,-1,-1;     % Matrix corresponding to vectors u0 ... u15 in Table 6.3.4.2.3-2
            1,-1i,1,1i;
            1,1,-1,1;
            1,1i,1,-1i;
            1,(-1-1i)/sqrt(2), -1i,(1-1i)/sqrt(2);
            1,(1-1i)/sqrt(2), 1i,(-1-1i)/sqrt(2);
            1,(1+1i)/sqrt(2), -1i,(-1+1i)/sqrt(2);
            1,(-1+1i)/sqrt(2), 1i,(1+1i)/sqrt(2);
            1,-1,1,1;
            1,-1i,-1,-1i;
            1,1,1,-1;
            1,1i,-1,1i;
            1,-1,-1,1;
            1,-1,1,-1;
            1,1,-1,-1;
            1,1,1,1;].';
 Wn = zeros(4,4,16); 
 for ii = 1:16 
     LTE_params.Wn(:,:,ii)=diag(ones(1,4))-2*U_temp(:,ii)*U_temp(:,ii)'/(U_temp(:,ii)'*U_temp(:,ii));
 end
 
 % W Matrix according to Table 6.3.4.2.3-1
 LTE_params.W{1} = cat(3,[1;0],[0;1],[1/sqrt(2);1/sqrt(2)],[1/sqrt(2);-1/sqrt(2)],...
        [1/sqrt(2);1i/sqrt(2)],[1/sqrt(2);-1i/sqrt(2)]);
 LTE_params.W{2} = cat(3,1/sqrt(2)*[1,0;0,1],1/(2)*[1,1;1,-1],1/(2)*[1,1;1i,-1i]);
 
 % Large delay CDD  
 LTE_params.U_l{1} = 1;
 LTE_params.U_l{2} = 1/sqrt(2)*[1,1;1,exp(-1i*pi)]; 
 LTE_params.U_l{3} = 1/sqrt(3)*[1,1,1;1,exp(-1i*2*pi/3),exp(-1i*4*pi/3);1,exp(-1i*4*pi/3),exp(-1i*8*pi/3)];
 LTE_params.U_l{4} = 1/2*[1,1,1,1;1,exp(-1i*2*pi/4),exp(-1i*4*pi/4),exp(-1i*6*pi/4);...
                            1,exp(-1i*4*pi/4),exp(-1i*8*pi/4),exp(-1i*12*pi/4);...
                            1,exp(-1i*6*pi/4),exp(-1i*12*pi/4),exp(-1i*18*pi/4)];
 LTE_params.D_l{1} = 1;
 LTE_params.D_l{2} = [1,0;0,exp(-1i*pi)];
 LTE_params.D_l{3} = [1,0,0;0,exp(-1i*2*pi/3),0;0,0,exp(-1i*4*pi/3)];
 LTE_params.D_l{4} = [1,0,0,0;0,exp(-1i*2*pi/4),0,0;0,0,exp(-1i*4*pi/4),0;0,0,0,exp(-1i*6*pi/4)];
 
 % Note that as of v.8.3.0, small delay CDD is removed from the standard
 % (28/05/08	RAN_40	RP-080432	0043	-	Removal of small-delay CDD
 
 % Precoding matrix W columns to take for each layer mapping
 LTE_params.mapping{1} = ones(16,1);
 LTE_params.mapping{2}=[1 4;1 2;1 2;1 2;1 4;1 4;1 3;1 3;1 2;1 4;1 3;1 3;1 2;1 3;1 3;1 2];
 LTE_params.mapping{3}=[1 2 4;1 2 3;1 2 3;1 2 3;1 2 4;1 2 4;1 3 4;1 3 4;1 2 4;1 3 4;1 2 3;1 3 4;1 2 3;1 2 3;1 2 3;1 2 3];
 LTE_params.mapping{4}=[1 2 3 4;1 2 3 4;3 2 1 4;3 2 1 4;1 2 3 4;1 2 3 4;1 3 2 4;
     1 3 2 4;1 2 3 4;1 2 3 4;1 3 2 4;1 3 2 4;1 2 3 4;1 3 2 4;3 2 1 4;1 2 3 4];
 
function precoding_config = get_all_precoding_combinations
% This small helper function returns all possible precoding options for
% LTE.
% (c) Josep Colom Ikuno, INTHFT, 2008
% www.nt.tuwien.ac.at

% TxD

precoding_config.tx_mode = 2;
precoding_config.nAtPort = 2;
precoding_config.nLayers = 2;

precoding_config(2).tx_mode = 2;
precoding_config(2).nAtPort = 4;
precoding_config(2).nLayers = 4;

% Large delay CDD (OLSM)

% No mode with one layer/rank 1 (TxD is used in that case)

precoding_config(3).tx_mode = 3;
precoding_config(3).nAtPort = 2;
precoding_config(3).nLayers = 2;

precoding_config(4).tx_mode = 3;
precoding_config(4).nAtPort = 4;
precoding_config(4).nLayers = 2;

precoding_config(5).tx_mode = 3;
precoding_config(5).nAtPort = 4;
precoding_config(5).nLayers = 3;

precoding_config(6).tx_mode = 3;
precoding_config(6).nAtPort = 4;
precoding_config(6).nLayers = 4;

% CLSM
precoding_config(7).tx_mode = 4;
precoding_config(7).nAtPort = 2;
precoding_config(7).nLayers = 1;
precoding_config(7).codebook_idxs = 0:3;

precoding_config(8).tx_mode = 4;
precoding_config(8).nAtPort = 2;
precoding_config(8).nLayers = 2;
precoding_config(8).codebook_idxs = 0:2;


precoding_config(9).tx_mode = 4;
precoding_config(9).nAtPort = 4;
precoding_config(9).nLayers = 1;
precoding_config(9).codebook_idxs = 0:15;

precoding_config(10).tx_mode = 4;
precoding_config(10).nAtPort = 4;
precoding_config(10).nLayers = 2;
precoding_config(10).codebook_idxs = 0:15;

precoding_config(11).tx_mode = 4;
precoding_config(11).nAtPort = 4;
precoding_config(11).nLayers = 3;
precoding_config(11).codebook_idxs = 0:15;

precoding_config(12).tx_mode = 4;
precoding_config(12).nAtPort = 4;
precoding_config(12).nLayers = 4;
precoding_config(12).codebook_idxs = 0:15;
