folder1 = '.\VTC_CDFs';
files1 = {'OLSM best cqi 200_files','OLSM round robin 186_files','TxD best cqi 200_files','TxD round robin 200_files'};
names  = {'OLSM, max C/I' 'OLSM, round robin' 'TxD, max C/I' 'TxD, round robin'};
colors = {':k' 'k' ':r' 'r'};

close all
fig_1 = figure;
fig_2 = figure;
% fig_3 = figure;
% fig_4 = figure;
axes_1 = axes('Parent',fig_1);
axes_2 = axes('Parent',fig_2);
% axes_3 = axes('Parent',fig_3);
% axes_4 = axes('Parent',fig_4);
hold(axes_1,'on');
hold(axes_2,'on');
% hold(axes_3,'on');
% hold(axes_4,'on');
for i_=1:length(files1)
    load(fullfile(folder1,files1{i_}));
    [f1,x1] = ecdf(mean_throughput);
    [f2,x2] = ecdf(mean_RBs);
    [f3,x3] = ecdf(total_TB_CQIs);
    [f4,x4] = ecdf(cell_mean_throughput);
    plot(axes_1,x1,f1,colors{i_},'DisplayName',names{i_});
    plot(axes_2,x2,f2,colors{i_},'DisplayName',names{i_});
    %plot(axes_3,x3,f3,colors{i_},'DisplayName',names{i_});
    %plot(axes_4,x4,f4,colors{i_},'DisplayName',names{i_});
end
xlim(axes_1,[-50 600]);
legend(axes_1,'show','Location','SouthEast');
grid(axes_1,'on');
xlabel(axes_1,'UE throughput (kb/s)');
ylabel(axes_1,'F(x)');
title(axes_1,'UE throughput, 20 UEs/sector, 5 MHz bandwidth');
hold(axes_1,'off');

xlim(axes_2,[0 5]);
legend(axes_2,'show','Location','SouthEast');
grid(axes_2,'on');
xlabel(axes_2,'Mean assigned RBs (RBs)');
ylabel(axes_2,'F(x)');
hold(axes_2,'off');

% xlim(axes_3,[0 15]);
% legend(axes_3,'show','Location','NorthWest');
% grid(axes_3,'on');
% xlabel(axes_3,'Assigned TB CQI');
% ylabel(axes_3,'F(x)');
% hold(axes_3,'off');
% 
% xlim(axes_4,[-1 25]);
% %legend(axes_4,'show','Location','SouthEast');
% grid(axes_4,'on');
% xlabel(axes_4,'Cell throughput (Mb/s)');
% ylabel(axes_4,'F(x)');
% hold(axes_4,'off');
