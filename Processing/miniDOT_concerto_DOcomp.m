%%% Comparing the miniDOT data to CTD casts near the moorings %%%

%%% Maia Heffernan, July 16 2026

% we don't fully trust the miniDOT data so I am going to compare the
% minidot dissolved oxygen and temperature values to the DO and temp values
% from the concerto we used to cast near each mooring.

clear all, close all


%% load data

% miniDOT data
load miniDOT_MayJun2026_mooringdata_L0.mat

load miniDOT_MayJun2026_raftdata_L0.mat


% CTD cast data for June 3

load Echo_CTD_MayAnd23Jun2026_TowYo_DataAndChannelsOnly_processed_L1.mat

ctd_dt = datetime([data.tstamp], 'ConvertFrom', 'datenum');

ctd_do_mgl = zeros(572, numel(data));
for i = 1:numel(data)
    ctd_do_mgl(:,i) = data(i).values(:,14);
end

ctd_depth = zeros(572, numel(data));
for i = 1:numel(data)
    ctd_depth(:,i) = data(i).values(:,7);
end


% ADCP data

% load Echo_ADCP_flood_cleaned_corrected.mat 
% load Echo_ADCP_ebb_cleaned_corrected.mat 
% 




%% Step 1) determine which CTD cast to use

% look at my notes from the deployment in May and recovery in June for this



% cast at LJN at 20:28 UTC 

ctd_LJN_cast_times = ctd_dt(:,475);
ctd_LJN_cast_do = ctd_do_mgl(:,475);
ctd_LJN_cast_depth = ctd_depth(:,475);


% cast at LJS at 20:57 UTC

ctd_LJS_cast_times = ctd_dt(:,476);
ctd_LJS_cast_do = ctd_do_mgl(:,476);
ctd_LJS_cast_depth = ctd_depth(:,476);

% cast at shellfish rafts at 22:05 UTC -- notably OUTSIDE the rafts

ctd_raft_cast_times = ctd_dt(:,479);
ctd_raft_cast_do = ctd_do_mgl(:,479);
ctd_raft_cast_depth = ctd_depth(:,479);


%% Step 1.5) plot the casts from the concerto

figure(1); clf;

s1 = subplot(1,3,1);

plot(ctd_LJN_cast_do, ctd_LJN_cast_depth, '-^', 'LineWidth', 2, 'MarkerSize', 2.5)
set(gca, 'YDir', 'reverse')
xlabel('DO (mgL^{-1})')
ylabel('Depth (m)')
subtitle('LoveJoy north, 23 June 20:27 UTC')


s2 = subplot(1,3,2);

plot(ctd_LJS_cast_do, ctd_LJS_cast_depth, '-^', 'LineWidth', 2, 'MarkerSize', 2.5)
set(gca, 'YDir', 'reverse')
xlabel('DO (mgL^{-1})')
subtitle('LoveJoy south, 23 June 20:57 UTC')


s3 = subplot(1,3,3);

plot(ctd_raft_cast_do, ctd_raft_cast_depth, '-^', 'LineWidth', 2, 'MarkerSize', 2.5)
set(gca, 'YDir', 'reverse')
xlabel('DO (mgL^{-1})')
subtitle('Outside shellfish rafts, 23 June 22:05 UTC')



linkaxes([s1 s2 s3], 'xy')



%% Step 2) determine the depth of the miniDOT sensors

% I know the depth on the line that the sensors were placed, but depending
% on what the current was doing this could be at a different point in the
% water column

% If I looked at the pressure sensor data, saw what depth the pressure
% sensors were reading and where they are supposed to be I can tell what
% the line angle is.




% determine how fast the current was moving in the water column at each
% mooring

% determine how much of a line angle that would create


%% Step 3) compare the miniDOT values closest to the timestamp and depth from the CTD cast


% find the closest miniDOT timestamp to the ctd_LJN_cast_times

% first numbered cast time
ctd_LJN_topcast_time = ctd_LJN_cast_times(7);

ctd_LJS_topcast_time = ctd_LJS_cast_times(5);


ctd_raftCast_time = ctd_raft_cast_times(5);

% LJN 13m 
[~, closestIndex_LJN13] = min(abs(LJN_13m.UTC_Date___Time - ctd_LJN_topcast_time));
closestMiniDOT_LJN13_do = LJN_13m.DissolvedOxygen(closestIndex_LJN13);
%closestMiniDOT_depth = miniDOT_depth(closestIndex);

% LJN 26m
[~, closestIndex_LJN26] = min(abs(LJN_26m.UTC_Date___Time - ctd_LJN_topcast_time));
closestMiniDOT_LJN26_do = LJN_26m.DissolvedOxygen(closestIndex_LJN26);


%LJS 16m
[~, closestIndex_LJS16] = min(abs(LJS_16m.UTC_Date___Time - ctd_LJS_topcast_time));
closestMiniDOT_LJS16_do = LJS_16m.DissolvedOxygen(closestIndex_LJS16);


%LJS 32m
[~, closestIndex_LJS32] = min(abs(LJS_32m.UTC_Date___Time - ctd_LJS_topcast_time));
closestMiniDOT_LJS32_do = LJS_32m.DissolvedOxygen(closestIndex_LJS32);


% raft 1m 
[~, closestIndex_raft1] = min(abs(raft_1m.UTC_Date___Time - ctd_raftCast_time));
closestMiniDOT_raft1_do = raft_1m.DissolvedOxygen(closestIndex_raft1);



% raft 7m
[~, closestIndex_raft7] = min(abs(raft_7m.UTC_Date___Time - ctd_raftCast_time));
closestMiniDOT_raft7_do = raft_7m.DissolvedOxygen(closestIndex_raft1);



%% Make a plot of the values

% since I dont have the current data from the swifts and I dont know
% exactly what depth the miniDOTs were at I am just going to use the 45
% degree line angle modeled depths to plot the miniDOT readings.

LJN_13m_actual_depth = 11.39*cos(45); % the 11.39 was the measured (as deployed) depth on the mooring line
LJN_26m_actual_depth = 24.46*cos(45); % the 24.46 was the measured (as deployed) depth on the mooring line

LJS_16m_actual_depth = 17.34*cos(45); % the 17.34 was the measured (as deployed) depth on the mooring line
LJS_32m_actual_depth = 33.50*cos(45); % the 33.50 was the measured (as deployed) depth on the mooring line



%% plot it 

y1 = 1;
y7 = 7;


figure(2); clf;

s4 = subplot(1,3,1);

p4 = plot(ctd_LJN_cast_do, ctd_LJN_cast_depth, '-^', 'LineWidth', 2, 'MarkerSize', 2.5);
set(gca, 'YDir', 'reverse')
hold on
p5 = plot(closestMiniDOT_LJN13_do, LJN_13m_actual_depth, 'rx', 'MarkerSize', 10, "LineWidth", 2);
hold on
p6 = plot(closestMiniDOT_LJN26_do, LJN_26m_actual_depth, 'rsquare', 'MarkerSize', 10, "LineWidth", 2);
xlabel('DO (mgL^{-1})')
ylabel('Depth (m)')
subtitle('LoveJoy north, 23 June 20:27 UTC')
legend([p4 p5 p6], "CTD cast", "6m miniDOT", "13m miniDOT")
hold off


s5 = subplot(1,3,2);

p7 = plot(ctd_LJS_cast_do, ctd_LJS_cast_depth, '-^', 'LineWidth', 2, 'MarkerSize', 2.5);
set(gca, 'YDir', 'reverse')
hold on
p8 = plot(closestMiniDOT_LJS16_do, LJS_16m_actual_depth, 'rx', 'MarkerSize', 10, "LineWidth", 2);
hold on
p9 = plot(closestMiniDOT_LJS32_do, LJS_32m_actual_depth, 'rsquare', 'MarkerSize', 10, "LineWidth", 2);
xlabel('DO (mgL^{-1})')
subtitle('LoveJoy south, 23 June 20:57 UTC')
legend([p7 p8 p9], "CTD cast", "9m miniDOT", "18m miniDOT")
hold off

s6 = subplot(1,3,3);

p10 = plot(ctd_raft_cast_do, ctd_raft_cast_depth, '-^', 'LineWidth', 2, 'MarkerSize', 2.5);
hold on
p11 = plot(closestMiniDOT_raft1_do, y1, 'rx', "MarkerSize", 10, "LineWidth", 2);
hold on
p12 = plot(closestMiniDOT_raft7_do, y7, 'rsquare', "MarkerSize", 10, "LineWidth", 2);
set(gca, 'YDir', 'reverse')
xlabel('DO (mgL^{-1})')
subtitle('Outside shellfish rafts, 23 June 22:05 UTC')

legend([p10 p11 p12], "CTD cast", "1m miniDOT", "7m miniDOT")



linkaxes([s4 s5 s6], 'xy')
