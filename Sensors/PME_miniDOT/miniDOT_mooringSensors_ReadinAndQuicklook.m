%%% PME miniDOT moorings readin and quicklook %%%

%%% created on July 1, 2026. Maia H. 

clear all; close all;


%% load the data

% == MAKE SURE YOU ARE IN THE 'DATA' DIRECTORY FOR THE MONTH YOU ARE INTERESTED IN ==

LJN_13m = readtable('LoveJoyNorth_MaytoJun2026/miniDOT/LoveJoyNorth_MaytoJune2026_13m_sn372740/LoveJoyNorth_MaytoJun2026_13m_sn372740_CAT.TXT');
%LJN_26m = readtable('LoveJoyNorth_MaytoJun2026/miniDOT/LoveJoyNorth_MaytoJune2026_26m_sn419387/LoveJoyNorth_MaytoJun2026_26m_sn419387_CAT.TXT');

LJS_16m = readtable('/Users/heffem3/Library/CloudStorage/GoogleDrive-heffem3@uw.edu/Shared drives/M2O2/Penn Cove 2026/June2026/Data/LoveJoySouth_MaytoJun2026/miniDOT/LoveJoySouth_MaytoJune_16m_sn279558/LoveJoySouth_MaytoJun2026_16m_sn279558_CAT.TXT');
LJS_32m = readtable('/Users/heffem3/Library/CloudStorage/GoogleDrive-heffem3@uw.edu/Shared drives/M2O2/Penn Cove 2026/June2026/Data/LoveJoySouth_MaytoJun2026/miniDOT/LoveJoySouth_MaytoJune_32m_sn305219/LoveJoySouth_MaytoJun2026_32m_sn305219_CAT.TXT');


% somehow the LJN 26 m concatenation got messed up and it brought in data
% from only April. But the daily files have data so I just have to
% concatenate those.
% 
% See script: miniDOT_DailyDataConcatenation.m in the
% Processing directory of PennCove_codes Github repo



% load the LJN_26m manually concatenated data and remove all the data until
% the deployment time because for some reason this has April data too?
    
    load('/Users/heffem3/Library/CloudStorage/GoogleDrive-heffem3@uw.edu/Shared drives/M2O2/Penn Cove 2026/June2026/Data/LoveJoyNorth_MaytoJun2026/miniDOT/LoveJoyNorth_MaytoJune2026_26m_sn419387/LJN_26m_MayJun2026.mat');
    
    LJN_26m = concatenatedData;

%% Trim the data so that only date from the deployment time winow for all sensors is represented

% for may to june 2026, all moorings were deployed by 2026 May 27 00:00 UTC
% and the timeseries should stop at 2026 June 23 20:00 UTC which was before
% the first mooring was recovered.

% Define the time range for trimming the data
startTime = datetime(2026, 5, 27, 0, 0, 0);
endTime = datetime(2026, 6, 23, 20, 40, 0);

% Trim the data for each mooring to the defined time range
LJN_13m = LJN_13m(LJN_13m.UTC_Date___Time >= startTime & LJN_13m.UTC_Date___Time <= endTime, :);
LJN_26m = LJN_26m(LJN_26m.UTC_Date___Time >= startTime & LJN_26m.UTC_Date___Time <= endTime, :);
LJS_16m = LJS_16m(LJS_16m.UTC_Date___Time >= startTime & LJS_16m.UTC_Date___Time <= endTime, :);
LJS_32m = LJS_32m(LJS_32m.UTC_Date___Time >= startTime & LJS_32m.UTC_Date___Time <= endTime, :);



%% plot timeseries 

figure(1); clf;

hold on;
p1 = plot(LJN_13m.UTC_Date___Time, LJN_13m.DissolvedOxygen, 'b-', 'LineWidth', 1.0);
p2 = plot(LJN_26m.UTC_Date___Time, LJN_26m.DissolvedOxygen, 'm-', 'LineWidth', 1.0);
p3 = plot(LJS_16m.UTC_Date___Time, LJS_16m.DissolvedOxygen, 'g-', 'LineWidth', 1.0);
p4 = plot(LJS_32m.UTC_Date___Time, LJS_32m.DissolvedOxygen, 'r-', 'LineWidth', 1.0);

yline(2, 'k--', 'LineWidth', 1.5)

legend([p1 p2 p3 p4], 'LoveJoyNorth 13m', 'LoveJoyNorth 26m', 'LoveJoySouth 16m', 'LoveJoySouth 32m')
axis tight
xlabel('Time')
ylabel('Dissolved Oxygen (mgL^{-1})')
title('Dissolved oxygen time series from the moorings')
hold off

%saveas(gcf, 'miniDOT_DO_timeseries_May2026_moorings.png');



figure(2); clf;

hold on;
p5 = plot(LJN_13m.UTC_Date___Time, LJN_13m.Temperature, 'b-', 'LineWidth', 1.0);
p6 = plot(LJN_26m.UTC_Date___Time, LJN_26m.Temperature, 'm-', 'LineWidth', 1.0);
p7 = plot(LJS_16m.UTC_Date___Time, LJS_16m.Temperature, 'g-', 'LineWidth', 1.0);
p8 = plot(LJS_32m.UTC_Date___Time, LJS_32m.Temperature, 'r-', 'LineWidth', 1.0);

legend([p5 p6 p7 p8], 'LoveJoyNorth 13m', 'LoveJoyNorth 26m', 'LoveJoySouth 16m', 'LoveJoySouth 32m')
axis tight
xlabel('Time')
ylabel('Temperature (°C)')
title('Temperature time series from the moorings')

%saveas(gcf, 'miniDOT_Temp_timeseries_May2026_moorings.png');


%% Plot histograms for Dissolved Oxygen 

figure(3); clf;

s1 = subplot(2,2,1);
histogram(LJN_13m.DissolvedOxygen);
xlabel('Dissolved oxygen concentration (mgL^{-1})')
ylabel('Frequency')
title('LoveJoyNorth 13m')

s2 = subplot(2,2,2);
histogram(LJN_26m.DissolvedOxygen);
xlabel('Dissolved oxygen concentration (mgL^{-1})')
ylabel('Frequency')
title('LoveJoyNorth 26m')

s3 = subplot(2,2,3);
histogram(LJS_16m.DissolvedOxygen);
xlabel('Dissolved oxygen concentration (mgL^{-1})')
ylabel('Frequency')
title('LoveJoySouth 16m')

s4 = subplot(2,2,4);
histogram(LJS_32m.DissolvedOxygen);
xlabel('Dissolved oxygen concentration (mgL^{-1})')
ylabel('Frequency')
title('LoveJoySouth 32m')

sgtitle('Dissolved Oxygen Distributions from the Moorings')

linkaxes([s1 s2 s3 s4],'x')
%saveas(gcf, 'miniDOT_DO_hist_May2026_moorings.png');

%% Plot histograms for Temperature 


figure(4); clf;

s5 = subplot(2,2,1);
histogram(LJN_13m.Temperature);
xlabel('Temperature (°C)')
ylabel('Frequency')
title('LoveJoyNorth 13m')

s6 = subplot(2,2,2);
histogram(LJN_26m.Temperature);
xlabel('Temperature (°C)')
ylabel('Frequency')
title('LoveJoyNorth 26m')

s7 = subplot(2,2,3);
histogram(LJS_16m.Temperature);
xlabel('Temperature (°C)')
ylabel('Frequency')
title('LoveJoySouth 16m')

s8 = subplot(2,2,4);
histogram(LJS_32m.Temperature);
xlabel('Temperature (°C)')
ylabel('Frequency')
title('LoveJoySouth 32m')

sgtitle('Temperature Distributions from the Moorings')


linkaxes([s5 s6 s7 s8],'x')
%saveas(gcf, 'miniDOT_Temp_hist_May2026_moorings.png');


%% save out the data


save miniDOT_MayJun2026_mooringdata_L0 LJN_26m LJN_13m LJS_16m LJS_32m



