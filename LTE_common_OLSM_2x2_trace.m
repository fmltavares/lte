function [ output_args ] = LTE_common_OLSM_2x2_trace( config,H_trace_normalized,H_trace_interf_normalized,precoding_matrix,trace_to_fill,debug_output )
% Generate the fading trace for the 2x2 OLSM LTE mode
% Author: Josep Colom Ikuno, jcolom@nt.tuwien.ac.at.
% (c) 2009 by INTHFT
% www.nt.tuwien.ac.at

fprintf('OLSM: 2x2\n');

% Re-create config params from input
system_bandwidth = config.system_bandwidth;
channel_type     = config.channel_type;
nTX              = config.nTX;
nRX              = config.nRX;
trace_length_s   = config.trace_length_s;
UE_speed         = config.UE_speed;

num_W_matrices = size(precoding_matrix.W,3);
for i_=1:num_W_matrices
    WDU(:,:,i_) = precoding_matrix.W(:,:,i_) * precoding_matrix.D * precoding_matrix.U;
end

% delete me
% WDU = precoding_matrix.W(:,:,i_) * [1 0;0 1] * precoding_matrix.U;
% WDU2 = precoding_matrix.W(:,:,i_) * [1 0;0 -1] * precoding_matrix.U;
% end delete me

% NOTE: W*D*U = F
%       pinv(HF)*(HF) = A

% Preallocate
TTI_length = trace_length_s*1000;
nLayers    = precoding_matrix.nLayers;
SC_samples = size(H_trace_normalized,4);

H0F      = zeros(nRX,nLayers,TTI_length,SC_samples);
H1F      = zeros(nRX,nLayers,TTI_length,SC_samples);
H0F_pinv = zeros(nLayers,nRX,TTI_length,SC_samples);
A        = zeros(nLayers,nLayers,TTI_length,SC_samples);
C        = zeros(nLayers,nLayers,TTI_length,SC_samples);

%delete me
% H0F2      = zeros(nRX,nLayers,TTI_length,SC_samples);
% H1F2      = zeros(nRX,nLayers,TTI_length,SC_samples);
% H0F2_pinv = zeros(nLayers,nRX,TTI_length,SC_samples);
% A2        = zeros(nLayers,nLayers,TTI_length,SC_samples);
% C2        = zeros(nLayers,nLayers,TTI_length,SC_samples);
% end delete me

parfor TTI_ = 1:TTI_length
    % This construction allows a parfor construct to be used here
    TTI_H       = H_trace_normalized(:,:,TTI_,:);
    TTI_H_inter = H_trace_interf_normalized(:,:,TTI_,:);
    [   H0F(:,:,TTI_,:)...
        H1F(:,:,TTI_,:)...
        H0F_pinv(:,:,TTI_,:)...
        A(:,:,TTI_,:)...
        C(:,:,TTI_,:) ] = calculate_TTI_params(TTI_H,TTI_H_inter,WDU,nRX,nLayers,SC_samples);
    
    % delete me
%     [   H0F2(:,:,TTI_,:)...
%         H1F2(:,:,TTI_,:)...
%         H0F2_pinv(:,:,TTI_,:)...
%         A2(:,:,TTI_,:)...
%         C2(:,:,TTI_,:) ] = calculate_TTI_params2(TTI_H,TTI_H_inter,WDU2,nRX,nLayers,SC_samples);
    % end delete me
end

%% Extract now the fading parameters

zeta  = zeros(nLayers,TTI_length,SC_samples); % Scales the received signal (1 for perfect channel knowledge)
for layer_idx = 1:nLayers
    zeta(layer_idx,:,:) = squeeze(abs(A(layer_idx,layer_idx,:,:)).^2);
end
chi   = squeeze(sum(abs(A).^2,2)) - zeta; % Represents inter-layer interference (0 for perfect channel knowledge)
psi   = squeeze(sum(abs(H0F_pinv).^2,2)); % Scales the noise
theta = squeeze(sum(abs(C).^2,2));        % Scales the interference

% delete me
% zeta2  = zeros(nLayers,TTI_length,SC_samples); % Scales the received signal (1 for perfect channel knowledge)
% for layer_idx = 1:nLayers
%     zeta2(layer_idx,:,:) = squeeze(abs(A2(layer_idx,layer_idx,:,:)).^2);
% end
% chi2   = squeeze(sum(abs(A2).^2,2)) - zeta2; % Represents inter-layer interference (0 for perfect channel knowledge)
% psi2   = squeeze(sum(abs(H0F2_pinv).^2,2)); % Scales the noise
% theta2 = squeeze(sum(abs(C2).^2,2));        % Scales the interference
% end delete me

% For the 2-layer case, the D matrix is cyclically changed between
% [1 0;0-1] and [1 0;0 1]
% Thus, the noise and interference enhancement is averaged between the 2 layers.
% Since the rest or the values are (for now) 1 or 0, they are not averaged
psi = mean(psi,1);
theta = mean(theta,1);
% Trick to still have matching dimensions
psi   = repmat(psi,[nLayers 1 1]);
theta = repmat(theta,[nLayers 1 1]);

%% Some testing (specially norms)

if debug_output
    norms_A = zeros(1,TTI_length);
    norms_H0_normalized = zeros(1,TTI_length);
    norms_H1_normalized = zeros(1,TTI_length);
    for TTI_ = 1:TTI_length
        norms_H0(TTI_) = norm(H_trace_normalized(:,:,TTI_,1),'fro')^2;
        norms_H1(TTI_) = norm(H_trace_interf_normalized(:,:,TTI_,1),'fro')^2;
        norms_H0F(TTI_)= norm(H0F(:,:,TTI_,1),'fro')^2;
        norms_A(TTI_)  = norm(A(:,:,TTI_,1),'fro')^2;
        norms_B(TTI_)  = norm(H0F_pinv(:,:,TTI_,1),'fro')^2;
        norms_C(TTI_)  = norm(C(:,:,TTI_,1),'fro')^2;
    end
    fprintf('<||H0||^2> = %3.2f\n',mean(norms_H0));
    fprintf('<||H1||^2> = %3.2f\n',mean(norms_H1));
    fprintf('<||F||^2>  = %3.2f\n',norm(WDU,'fro')^2);
    fprintf('<||H0F||^2>  = %3.2f\n',mean(norms_H0F));
    fprintf('<||A||^2>  = %3.2f\n',mean(norms_A));
    fprintf('<||B||^2>  = %3.2f\n',mean(norms_B));
    fprintf('<||C||^2>  = %3.2f\n',mean(norms_C));
    
    fprintf('Averages:\n');
    fprintf(' psi:   %3.2f\n',mean(psi(:)));
    fprintf(' theta: %3.2f\n',mean(theta(:)));
end

%% Fill in the output trace object
trace_to_fill.tx_mode          = 3;
trace_to_fill.trace_length_s   = trace_length_s;
trace_to_fill.system_bandwidth = system_bandwidth;
trace_to_fill.channel_type     = channel_type;
trace_to_fill.nTX              = nTX;
trace_to_fill.nRX              = nRX;
trace_to_fill.UE_speed         = UE_speed;

trace_to_fill.trace.zeta  = zeta;
trace_to_fill.trace.chi   = chi;
trace_to_fill.trace.psi   = psi;
trace_to_fill.trace.theta = theta;

%% Some plotting

if debug_output
    figure;
    hold on;
    plot(norms_H0,'k','Displayname','||H_0||_{F}^2 (Channel norm)');
    plot(norms_H1,'k:','Displayname','||H_1||_{F}^2 (Interf channel norm)');
    plot(zeta(1,:,1),'r','Displayname','\zeta (RX power)');
    plot(chi(1,:,1),'g','Displayname','\chi (inter-layer interf)');
    plot(psi(1,:,1),'b','Displayname','\psi (noise enhancement)');
    plot(theta(1,:,1),'m','Displayname','\theta (inter-cell interference)');
    set(gca,'Yscale','log');
    title('OLSM, Layer 1, subcarrier 1');
    grid on;
    legend('show','Location','best');
    
    figure;
    hold on;
    plot(norms_H0,'k','Displayname','||H_0||_{F}^2 (Channel norm)');
    plot(norms_H1,'k:','Displayname','||H_1||_{F}^2 (Interf channel norm)');
    plot(zeta(2,:,1),'r','Displayname','\zeta (RX power)');
    plot(chi(2,:,1),'g','Displayname','\chi (inter-layer interf)');
    plot(psi(2,:,1),'b','Displayname','\psi (noise enhancement)');
    plot(theta(2,:,1),'m','Displayname','\theta (inter-cell interference)');
    set(gca,'Yscale','log');
    title('OLSM, Layer 2, subcarrier 1');
    grid on;
    legend('show','Location','best');
end

function [H0F H1F H0F_pinv A C] = calculate_TTI_params(H_trace_normalized,H_trace_interf_normalized,WDU,nRX,nLayers,SC_samples)
% H_trace_normalized(:,:,1,N_SCs)
% H_trace_interf_normalized(:,:,1,N_SCs)

H0F      = zeros(nRX,nLayers,1,SC_samples);
H1F      = zeros(nRX,nLayers,1,SC_samples);
H0F_pinv = zeros(nLayers,nRX,1,SC_samples);
A        = zeros(nLayers,nLayers,1,SC_samples);
C        = zeros(nLayers,nLayers,1,SC_samples);

for SC_sample = 1:SC_samples
    current_H0 = H_trace_normalized(:,:,1,SC_sample);
    current_H1 = H_trace_interf_normalized(:,:,1,SC_sample);
    %for W_idx = 1:num_W_matrices
    W_idx = 1;
    % Get the pinv(HWDU) matrix for each TTI, SC sample and precoding matrix
    H0F(:,:,1,SC_sample)      = current_H0 * WDU(:,:,W_idx);
    H1F(:,:,1,SC_sample)      = current_H1;% * WDU(:,:,W_idx);
    H0F_pinv(:,:,1,SC_sample) = pinv(H0F(:,:,1,SC_sample));
    A(:,:,1,SC_sample)        = H0F_pinv(:,:,1,SC_sample) * H0F(:,:,1,SC_sample);
    C(:,:,1,SC_sample)        = H0F_pinv(:,:,1,SC_sample) * H1F(:,:,1,SC_sample);
    %end
end

% delete me
% function [H0F H1F H0F_pinv A C] = calculate_TTI_params2(H_trace_normalized,H_trace_interf_normalized,WDU,nRX,nLayers,SC_samples)
% % H_trace_normalized(:,:,1,N_SCs)
% % H_trace_interf_normalized(:,:,1,N_SCs)
% 
% H0F      = zeros(nRX,nLayers,1,SC_samples);
% H1F      = zeros(nRX,nLayers,1,SC_samples);
% H0F_pinv = zeros(nLayers,nRX,1,SC_samples);
% A        = zeros(nLayers,nLayers,1,SC_samples);
% C        = zeros(nLayers,nLayers,1,SC_samples);
% 
% for SC_sample = 1:SC_samples
%     current_H0 = H_trace_normalized(:,:,1,SC_sample);
%     current_H1 = H_trace_interf_normalized(:,:,1,SC_sample);
%     %for W_idx = 1:num_W_matrices
%     W_idx = 1;
%     % Get the pinv(HWDU) matrix for each TTI, SC sample and precoding matrix
%     H0F(:,:,1,SC_sample)      = current_H0 * WDU(:,:,W_idx);
%     H1F(:,:,1,SC_sample)      = current_H1;% * WDU(:,:,W_idx);
%     H0F_pinv(:,:,1,SC_sample) = pinv(H0F(:,:,1,SC_sample));
%     A(:,:,1,SC_sample)        = H0F_pinv(:,:,1,SC_sample) * H0F(:,:,1,SC_sample);
%     C(:,:,1,SC_sample)        = H0F_pinv(:,:,1,SC_sample) * H1F(:,:,1,SC_sample);
%     %end
% end
% end delete me