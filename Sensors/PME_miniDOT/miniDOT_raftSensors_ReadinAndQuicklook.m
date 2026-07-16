%%% PME miniDOT raft sensors readin and quicklook %%%

%%% Maia, April 2026
% updated June 2026, Maia
% renamed on July 1, 2026. Maia H. 

clear all; close all;


%% load in the data

raft_1m = readtable("RaftSensor_MaytoJune_sn454936/Cat.TXT");

raft_7m = readtable("RaftSensor_MaytoJune_sn445289/Cat.TXT");

%% Trim the data so that only date from the deployment time winow for all sensors is represented

% for may to june 2026, all moorings were deployed by 2026 May 27 00:00 UTC
% and the timeseries should stop at 2026 June 23 20:00 UTC which was before
% the first mooring was recovered.

% Define the time range for trimming the data
startTime = datetime(2026, 5, 27, 18, 0, 0);
endTime = datetime(2026, 6, 23, 20, 0, 0);

% Trim the data for each mooring to the defined time range
raft_1m = raft_1m(raft_1m.UTC_Date___Time >= startTime & raft_1m.UTC_Date___Time <= endTime, :);
raft_7m  = raft_7m(raft_7m.UTC_Date___Time >= startTime & raft_7m.UTC_Date___Time <= endTime, :);


%% plot timeseries 

figure(1); clf;

hold on;
p1 = plot(raft_1m.UTC_Date___Time, raft_1m.DissolvedOxygen, 'b-', 'LineWidth', 2.0);
p2 = plot(raft_7m.UTC_Date___Time, raft_7m.DissolvedOxygen, 'm-', 'LineWidth', 2.0);
yline(2, 'k--', 'LineWidth', 1.5)

legend([p1 p2], '1m depth', '7m depth')
xlabel('Time')
ylabel('Dissolved Oxygen (mgL^{-1})')
title('Dissolved oxygen time series from the shellfish rafts')
axis tight
hold off

saveas(gcf, 'miniDOT_DO_timeseries_May2026_rafts.png');

figure(2); clf;

p1 = plot(raft_1m.UTC_Date___Time, raft_1m.Temperature, 'b-', 'LineWidth', 2.0);
hold on;
p2 = plot(raft_7m.UTC_Date___Time, raft_7m.Temperature, 'm-', 'LineWidth', 2.0);

legend([p1 p2], '1m depth', '7m depth')
xlabel('Time')
ylabel('Temperature (°C)')
title('Temperature time series from the shellfish rafts')
axis tight

saveas(gcf, 'miniDOT_Temp_timeseries_May2026_rafts.png');


%% Plot histograms


figure(3); clf;

hist(raft_1m.DissolvedOxygen);
xlabel('Dissolved oxygen concentration (mgL^{-1})')
ylabel('Frequency')
title('1m shellfish raft sensor DO distribution')

saveas(gcf, 'miniDOT_1mDO_hist_May2026_rafts.png');

figure(4); clf;

hist(raft_7m.DissolvedOxygen);
xlabel('Dissolved oxygen concentration (mgL^{-1})')
ylabel('Frequency')
title('7m shellfish raft sensor DO distribution')

saveas(gcf, 'miniDOT_7mDO_hist_May2026_rafts.png');

%% Plot histograms for Temperature

figure(5); clf;

hist(raft_1m.Temperature);
xlabel('Temperature (°C)')
ylabel('Frequency')
title('1m shellfish raft sensor Temperature distribution')

saveas(gcf, 'miniDOT_1mTemp_hist_May2026_rafts.png');


figure(6); clf;
hist(raft_7m.Temperature);
xlabel('Temperature (°C)')
ylabel('Frequency')
title('7m shellfish raft sensor Temperature distribution')

saveas(gcf, 'miniDOT_7mTemp_hist_May2026_rafts.png');


