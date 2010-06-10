function [ output_args ] = LTE_common_TxD_2x2_trace( config,H_trace_normalized,H_trace_interf_normalized,precoding_matrix,trace_to_fill,debug_output )
% Generate the fading trace for the 2x2 TxD LTE mode
% Author: Josep Colom Ikuno, jcolom@nt.tuwien.ac.at.
% (c) 2009 by INTHFT
% www.nt.tuwien.ac.at

fprintf('TxD: 2x2\n');

% Re-create config params from input
system_bandwidth = config.system_bandwidth;
channel_type     = config.channel_type;
nTX              = config.nTX;
nRX              = config.nRX;
trace_length_s   = config.trace_length_s;
UE_speed         = config.UE_speed;

% 1/sqrt(2)*precoding_matrix.Z
% We will use the equivalent channel expression instead of the matrix
% representation in the standard.

% Preallocate
TTI_length = trace_length_s*1000;
nLayers    = precoding_matrix.nLayers;
SC_samples = size(H_trace_normalized,4);

H_tilde1      = zeros(2*nTX,nRX,TTI_length,SC_samples);
H_tilde2      = zeros(2*nTX,nRX,TTI_length,SC_samples);
H_tilde1_pinv = zeros(nRX,2*nTX,TTI_length,SC_samples);
A             = zeros(nRX,nRX,TTI_length,SC_samples);
C             = zeros(nRX,nRX,TTI_length,SC_samples);

parfor TTI_ = 1:TTI_length
    % This construction allows a parfor construct to be used here
    TTI_H       = H_trace_normalized(:,:,TTI_,:);
    TTI_H_inter = H_trace_interf_normalized(:,:,TTI_,:);
    
    [   H_tilde1_pinv(:,:,TTI_,:)...
        A(:,:,TTI_,:)...
        C(:,:,TTI_,:) ] = calculate_TTI_params(TTI_H,TTI_H_inter,nTX,nRX,SC_samples);
end

%% Extract now the fading parameters

% Scales the received signal (1 for perfect channel knowledge)
zeta  = zeros(nLayers,TTI_length,SC_samples);

% Represents inter-layer interference (0 for perfect channel knowledge)
chi   = zeros(nLayers,TTI_length,SC_samples);

% Scales the noise
psi   = zeros(nLayers,TTI_length,SC_samples);

% Scales the interference
theta = zeros(nLayers,TTI_length,SC_samples);

for layer_idx = 1:nLayers
    zeta(layer_idx,:,:) = squeeze(abs(A(layer_idx,layer_idx,:,:)).^2);
end
chi   = squeeze(sum(abs(A).^2,2)) - zeta;
psi   = squeeze(sum(abs(H_tilde1_pinv).^2,2));
theta = squeeze(sum(abs(C).^2,2));


%% Some testing (specially norms)

if debug_output
    norms_A = zeros(1,TTI_length);
    norms_H0_normalized = zeros(1,TTI_length);
    norms_H1_normalized = zeros(1,TTI_length);
    for TTI_ = 1:TTI_length
        norms_H0(TTI_) = norm(H_trace_normalized(:,:,TTI_,1),'fro')^2;
        norms_H1(TTI_) = norm(H_trace_interf_normalized(:,:,TTI_,1),'fro')^2;
        norms_A(TTI_)  = norm(A(:,:,TTI_,1),'fro')^2;
        norms_B(TTI_)  = norm(H_tilde1_pinv(:,:,TTI_,1),'fro')^2;
        norms_C(TTI_)  = norm(C(:,:,TTI_,1),'fro')^2;
    end
    fprintf('<||H0||^2> = %3.2f\n',mean(norms_H0));
    fprintf('<||H1||^2> = %3.2f\n',mean(norms_H1));
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
    title('TxD, Layer 1, subcarrier 1');
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
    title('TxD, Layer 2, subcarrier 1');
    grid on;
    legend('show','Location','best');
end

function [H_tilde1_pinv A C] = calculate_TTI_params(H_trace_normalized,H_trace_interf_normalized,nTX,nRX,SC_samples)
% H_trace_normalized(:,:,1,N_SCs)
% H_trace_interf_normalized(:,:,1,N_SCs)

H_tilde1_pinv = zeros(nRX,2*nTX,1,SC_samples);
A             = zeros(nRX,nRX,1,SC_samples);
C             = zeros(nRX,nRX,1,SC_samples);

for SC_sample = 1:SC_samples
    H_tilde1 = [
        H_trace_normalized(1,:,1,SC_sample).'  H_trace_normalized(2,:,1,SC_sample).'
        H_trace_normalized(2,:,1,SC_sample)'  -H_trace_normalized(1,:,1,SC_sample)'
        ];
    H_tilde2 = [
        H_trace_interf_normalized(1,:,1,SC_sample).'  H_trace_interf_normalized(2,:,1,SC_sample).'
        H_trace_interf_normalized(2,:,1,SC_sample)'  -H_trace_interf_normalized(1,:,1,SC_sample)'
        ];
    H_tilde1_pinv(:,:,1,SC_sample) = pinv(H_tilde1);
    A(:,:,1,SC_sample) = H_tilde1_pinv(:,:,1,SC_sample)*H_tilde1;
    C(:,:,1,SC_sample) = H_tilde1_pinv(:,:,1,SC_sample)*H_tilde2;
end
