%%% Plot the depths of the measured sensors on each mooring line (YSIs and Duos) over one deployment window.
%
% For each sensor, the panel shows:
%   gray line  = the continuous sensor record within the deployment window
%   red dots   = the sensor values matched to the SWIFT time steps (closest sample, using knnsearch)
% The InnerNorth panel also shows the bottom tide gauge (Duo sn240150) in blue.
%
% It also prints the range and median of each sensor's continuous and SWIFT-matched values,
% and the time gap (s) between each SWIFT time step and its matched sensor sample.
%
% YSI depth = Depth_m column (m). Duo depth = column 3 of values = sea pressure (dbar, ~ m of seawater).

clear all; close all; clc

%% load the sensor data and the SWIFT data

root = '/Users/heffem3/Library/CloudStorage/GoogleDrive-heffem3@uw.edu/Shared drives/M2O2/Penn Cove 2026/ConcatenatedData/';
duoData = load([root 'DuoTDdata_MayOct2026_concatenated_L1.mat']);
ysiData = load([root 'YSI600LSdata_MayOct2026_concatenated_L1.mat']);

% SWIFT L2 files for the month -- change the folder and file names for each month
swiftDir = '/Users/heffem3/Desktop/M2O2/SWIFTs/FullDatasets/SepOct2026/';
for n = 26:29
    swiftName = sprintf('SWIFT%d', n);
    swiftData.(swiftName) = load(sprintf('%s%s_SDcard_SepOct2026/%s_SDcard_SepOct2026_L2.mat', swiftDir, swiftName, swiftName));
end

% deployment window (UTC datenum), same as deploy_window in mooringSensor_depth.m -- change for each month
winStart = datenum(2026, 9, 24, 19, 30, 0);
winEnd   = datenum(2026, 10, 20, 14, 30, 0);

%% list of sensors to plot

D = duoData.DuoTD_data;

% each row: {panel title, sensor time (datenum), sensor depth (m or dbar), SWIFT on that mooring}
sensors = {
    'LJN YSI 4m (SWIFT28)',              datenum(ysiData.LJN_4m.DateTime),  ysiData.LJN_4m.Depth_m,  'SWIFT28';
    'LJN YSI 8m (SWIFT28)',              datenum(ysiData.LJN_8m.DateTime),  ysiData.LJN_8m.Depth_m,  'SWIFT28';
    'LJS YSI 4m (SWIFT27)',              datenum(ysiData.LJS_4m.DateTime),  ysiData.LJS_4m.Depth_m,  'SWIFT27';
    'LJS YSI 11m (SWIFT27)',             datenum(ysiData.LJS_11m.DateTime), ysiData.LJS_11m.Depth_m, 'SWIFT27';
    'InnerNorth Duo sn240149 (SWIFT26)', D.InnerNorth_sn240149.data.tstamp, D.InnerNorth_sn240149.data.values(:,3), 'SWIFT26';
    'InnerSouth Duo sn240151 (SWIFT29)', D.InnerSouth_sn240151.data.tstamp, D.InnerSouth_sn240151.data.values(:,3), 'SWIFT29'};

% InnerNorth bottom tide gauge, shown on the InnerNorth panel for comparison
gaugeTime = D.InnerNorth_sn240150.data.tstamp;
gaugeP    = D.InnerNorth_sn240150.data.values(:,3);
gaugePanel = 5;   % row of sensors{} that gets the tide gauge

%% plot

figure('Color', 'w', 'Position', [0 0 1600 1100]);
tiledlayout(3, 2, 'TileSpacing', 'compact');

for i = 1:size(sensors, 1)

    sensTime  = sensors{i,2}(:);     % sensor time (datenum), as a column
    sensDepth = sensors{i,3}(:);     % sensor depth / sea pressure, as a column

    % SWIFT time steps for this mooring
    swiftTime = [swiftData.(sensors{i,4}).SWIFT.time]';

    % closest sensor sample to each SWIFT time step
    idx = knnsearch(sensTime, swiftTime);

    % keep only times inside the deployment window
    swiftIn = swiftTime >= winStart & swiftTime <= winEnd;   % SWIFT time steps in the window
    sensIn  = sensTime  >= winStart & sensTime  <= winEnd;   % sensor samples in the window

    nexttile; hold on; box on

    % continuous sensor record
    plot(datetime(sensTime(sensIn), 'ConvertFrom', 'datenum'), sensDepth(sensIn), '-', ...
        'Color', [0.7 0.7 0.7], 'DisplayName', 'continuous');

    % bottom tide gauge on the InnerNorth panel
    if i == gaugePanel
        gaugeIn = gaugeTime >= winStart & gaugeTime <= winEnd;
        plot(datetime(gaugeTime(gaugeIn), 'ConvertFrom', 'datenum'), gaugeP(gaugeIn), '-', ...
            'Color', [0.6 0.8 1], 'DisplayName', 'tide gauge sn240150 (bottom)');
    end

    % sensor values matched to the SWIFT time steps
    plot(datetime(swiftTime(swiftIn), 'ConvertFrom', 'datenum'), sensDepth(idx(swiftIn)), 'r.', ...
        'MarkerSize', 6, 'DisplayName', 'matched to SWIFT');

    set(gca, 'YDir', 'reverse');   % depth increases downward
    ylabel('depth / sea pressure (m / dbar)');
    title(sensors{i,1});
    legend('Location', 'best');

    % print ranges, medians and matching time gaps
    matched = sensDepth(idx(swiftIn));                                 % matched values
    gapSec  = abs(sensTime(idx(swiftIn)) - swiftTime(swiftIn))*86400;  % time gap to matched sample (s)
    fprintf(['%-36s continuous: %6.2f to %6.2f (median %6.2f) | matched: %6.2f to %6.2f (median %6.2f) | ' ...
             'n=%d, max time gap %.0f s, median gap %.0f s\n'], ...
        sensors{i,1}, min(sensDepth(sensIn)), max(sensDepth(sensIn)), median(sensDepth(sensIn), 'omitnan'), ...
        min(matched), max(matched), median(matched, 'omitnan'), numel(matched), max(gapSec), median(gapSec));
end

% tide gauge range
gaugeIn = gaugeTime >= winStart & gaugeTime <= winEnd;
fprintf('tide gauge sn240150: %6.2f to %6.2f (median %6.2f)\n', min(gaugeP(gaugeIn)), max(gaugeP(gaugeIn)), median(gaugeP(gaugeIn)));

%% notes from looking at the SepOct2026 figure
%
% Duos: both swing over about 9-10 m, much more than the tide range of about 4 m on the gauge.
%   Both get close to the bottom at times. InnerSouth reaches 18.8 dbar at a charted 16 m site.
%
% InnerSouth gap: the matched points stop around 17 Oct (only 481 matched points).
%   That's because SWIFT29 has fewer time steps; the Duo kept recording.
%
% YSIs: each one has a firm "deepest" value that it keeps returning to: about 4.4-4.6 m for both
%   4 m sensors and about 8.4-8.5 m for both deep sensors. The LJS 11 m sensor never reads deeper
%   than 8.55 m, even though its distFromTop is 10.5 m.
