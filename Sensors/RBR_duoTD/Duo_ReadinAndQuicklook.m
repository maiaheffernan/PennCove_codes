%%% reading in the RBR Duo data and doing some initial plotting %%%

%%% Maia, April 2026

close all; clear all;

%% load in the data

SN_endings = {'49', '50', '51'};
ending_numbers = {'1631', '1628', '1630'};

for i = 1:length(SN_endings)
    fileName = sprintf('2401%s_20260415_%s.rsk', SN_endings{i}, ending_numbers{i});
    duo_data{i} = RSKreaddata(RSKopen(fileName));
end


%% plot a time series of the data with different colors 

% ===== first temperature =====

figure; hold on;

for i = 1:3
    d = duo_data{i}.data;   % go into struct inside each cell
    
     t = datetime(d.tstamp, 'ConvertFrom', 'datenum');
    plot(t, d.values(:,1)); % plotting only temp
    axis tight
end

hold off;
legend('SN 240149','SN 240150','SN 240151');
xlabel('Time');
ylabel('dbar');
title('Time series of temperature from RBR Duo bucket test');


% ===== then pressure ====

figure(2); hold on;

for i = 1:3
    d = duo_data{i}.data;   % go into struct inside each cell
    
     t = datetime(d.tstamp, 'ConvertFrom', 'datenum');
    plot(t, d.values(:,2)); % plotting only pressure
    axis tight
end

hold off;
legend('SN 240149','SN 240150','SN 240151');
xlabel('Time');
ylabel('dbar');
title('Time series of pressure from RBR Duo bucket test');

%% make a table of this data so it is easily seeable