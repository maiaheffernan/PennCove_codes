%%% reading in the RBR Solo T data and doing some initial plotting %%%

%%% Maia, April 2026

close all; clear all;

%% load in the data


SN_endings = {'32', '33', '34', '57', '58', '59', '60', '61', '62', '63',...
              '64', '65', '66', '67', '68', '69', '70', '71', '72', '73',...
              '74', '75', '76', '77', '78', '79', '80', '81'};
ending_numbers = {'1600', '1601', '1600', '1559', '1558', '1557', '1602', '1608', ...
                  '1607', '1606', '1607', '1605', '1603', '1604', '1609', '1612', ...
                  '1614', '1611', '1611', '1613', '1617', '1610', '1615', '1614', ...
                  '1616', '1617', '1618', '1616'};
 
for i = 1:length(SN_endings)
    fileName = sprintf('2128%s_20260415_%s.rsk', SN_endings{i}, ending_numbers{i});
    soloT_data{i} = RSKreaddata(RSKopen(fileName));
end

%% plot a time series of the data with different colors 

% ===== put in the start and end times =====

startTime = datetime(2026,04,15,20,21,00);
endTime = datetime(2026,04,15,20,31,00);


% ===== first temperature =====

figure; hold on;

for i = 1:28
    d = soloT_data{i}.data;                                    % no () needed, it's a struct
    t = datetime(d.tstamp, 'ConvertFrom', 'datenum');
    mask = (t >= startTime) & (t <= endTime);
    
    t_filtered   = t(mask);
    val_filtered = d.values(mask, :);                          % apply mask to values array

    plot(t_filtered, val_filtered);
    axis tight
end

hold off;
legend(SN_endings, 'Location','southwest');
xlabel('Time');
ylabel('dbar');
title('Time series of temperature from RBR Solo T bucket test');