function LTE_plot_sector_SINR_cdfs( sector_data,varargin )
% Plots the ecdf of the target cell's (not sector) SINR
% (c) Josep Colom Ikuno, INTHFT, 2010
% www.nt.tuwien.ac.at

global LTE_config;

if length(varargin)>0
    use_shadowing = true;
    sector_data_no_shadowing = varargin{1};
else
    use_shadowing = false;
end

if use_shadowing
    [f1 x1 flo1 fup1] = ecdf(sector_data);
    [f2 x2 flo2 fup2] = ecdf(sector_data_no_shadowing);
    
    figure(LTE_config.plots.sector_SINR_cdf);
    hold on;
    plot(x1,f1,'k','DisplayName','SINR CDF, macro and shadow fading');
    plot(x2,f2,':k','DisplayName','SINR CDF, macro fading only');
    legend('show','Location','Best');
    grid('on');
    xlabel('SINR (dB)');
    ylabel('F(x)');
    title('Target sector SINR CDF');
else
    [f1 x1 flo1 fup1] = ecdf(sector_data);
    
    figure(LTE_config.plots.sector_SINR_cdf);
    hold on;
    plot(x1,f1,'k','DisplayName','SINR CDF');
    legend('show','Location','Best');
    grid('on');
    xlabel('SINR (dB)');
    ylabel('F(x)');
    title('Target sector SINR CDF');
end

