function [ output_args ] = LTE_common_SISO_trace( config,H_trace_normalized,H_trace_interf_normalized,trace_to_fill,debug_output )
% Generate the fading trace for the SISO LTE mode
% Author: Josep Colom Ikuno, jcolom@nt.tuwien.ac.at.
% (c) 2009 by INTHFT
% www.nt.tuwien.ac.at

fprintf('SISO\n');

% Re-create config params from input
system_bandwidth = config.system_bandwidth;
channel_type     = config.channel_type;
nTX              = config.nTX;
nRX              = config.nRX;
trace_length_s   = config.trace_length_s;
UE_speed         = config.UE_speed;

TTI_length = trace_length_s*1000;
zeta  = abs(squeeze(1./H_trace_normalized .* H_trace_normalized)).^2;
% chi doesn't exist, as there is only one stream being transmitted
psi   = abs(squeeze(1./H_trace_normalized)).^2;
theta = abs(squeeze(1./H_trace_normalized .* H_trace_interf_normalized)).^2;

%% Fill in the output trace object
trace_to_fill.tx_mode          = 1;
trace_to_fill.trace_length_s   = trace_length_s;
trace_to_fill.system_bandwidth = system_bandwidth;
trace_to_fill.channel_type     = channel_type;
trace_to_fill.nTX              = nTX;
trace_to_fill.nRX              = nRX;
trace_to_fill.UE_speed         = UE_speed;

trace_to_fill.trace.zeta  = zeta;
trace_to_fill.trace.psi   = psi;
trace_to_fill.trace.theta = theta;

%% Some plotting

if debug_output
    figure;
    hold on;
    plot(zeta(1,:,1),'r','Displayname','\zeta (RX power)');
    plot(psi(1,:,1),'b','Displayname','\psi (noise enhancement)');
    plot(theta(1,:,1),'m','Displayname','\theta (inter-cell interference)');
    set(gca,'Yscale','log');
    title('SISO, subcarrier 1');
    grid on;
    legend('show','Location','best');
end
