%%% A script for plotting the bottom DO from all the moorings %%%

% Maia, September 7 2026

clear all, close all

set(groot, 'DefaultAxesFontSize', 14);
set(groot, 'DefaultLegendFontSize', 14);
set(groot, 'DefaultColorbarFontSize', 14);
set(groot, 'DefaultTextFontSize', 14);

%% load in the bottom DO data

% May to June

MayJun = load('TODOdata_MayJun2026_L3.mat');

% June to July

JunJul = load('TODOdata_JunJul2026_L3.mat');

% July to August

JulAug = load('TODOdata_JulAug2026_L3.mat');

%% concatenate the data in time

% LJN
LJN_alldata_time = [MayJun.TODO_data.LoveJoyNorth.data.tstamp; JunJul.TODO_data.LoveJoyNorth.data.tstamp; JulAug.TODO_data.LoveJoyNorth.data.tstamp]; 
LJN_alldata_values = [MayJun.TODO_data.LoveJoyNorth.data.values; JunJul.TODO_data.LoveJoyNorth.data.values; JulAug.TODO_data.LoveJoyNorth.data.values]; 

%LJS
LJS_alldata_time = [MayJun.TODO_data.LoveJoySouth.data.tstamp; JunJul.TODO_data.LoveJoySouth.data.tstamp; JulAug.TODO_data.LoveJoySouth.data.tstamp];
LJS_alldata_values = [MayJun.TODO_data.LoveJoySouth.data.values; JunJul.TODO_data.LoveJoySouth.data.values; JulAug.TODO_data.LoveJoySouth.data.values]; 

% Inner N
InnerN_alldata_time = [MayJun.TODO_data.InnerNorth.data.tstamp; JunJul.TODO_data.InnerNorth.data.tstamp; JulAug.TODO_data.InnerNorth.data.tstamp];
InnerN_alldata_values = [MayJun.TODO_data.InnerNorth.data.values; JunJul.TODO_data.InnerNorth.data.values; JulAug.TODO_data.InnerNorth.data.values]; 

% Inner S
InnerS_alldata_time = [MayJun.TODO_data.InnerSouth.data.tstamp; JunJul.TODO_data.InnerSouth.data.tstamp; JulAug.TODO_data.InnerSouth.data.tstamp];
InnerS_alldata_values = [MayJun.TODO_data.InnerSouth.data.values; JunJul.TODO_data.InnerSouth.data.values; JulAug.TODO_data.InnerSouth.data.values]; 


%% remove gaps larger than 12 hours

[LJN_alldata_time, LJN_alldata_values] = insert_gap_nans(LJN_alldata_time, LJN_alldata_values, 0.5); % 0.5 day threshold
[LJS_alldata_time, LJS_alldata_values] = insert_gap_nans(LJS_alldata_time, LJS_alldata_values, 0.5);
[InnerN_alldata_time, InnerN_alldata_values] = insert_gap_nans(InnerN_alldata_time, InnerN_alldata_values, 0.5);
[InnerS_alldata_time, InnerS_alldata_values] = insert_gap_nans(InnerS_alldata_time, InnerS_alldata_values, 0.5);

%% make the time vectors datetimes

LJN_alldata_time = datetime(LJN_alldata_time, 'ConvertFrom', 'datenum');
LJS_alldata_time = datetime(LJS_alldata_time, 'ConvertFrom', 'datenum');
InnerN_alldata_time = datetime(InnerN_alldata_time, 'ConvertFrom', 'datenum');
InnerS_alldata_time = datetime(InnerS_alldata_time, 'ConvertFrom', 'datenum');



%% colorblind friendly colors

S = load('colorblind_colormap.mat'); 
CT = S.colorblind;

%% Plot DO in one plot

figure(1); clf;
hold on;
plot(LJN_alldata_time, LJN_alldata_values(:,3), '-', 'LineWidth', 2, 'color',CT(6,:), 'DisplayName', 'Love Joy North');
plot(LJS_alldata_time, LJS_alldata_values(:,3), '-', 'LineWidth', 2, 'color',CT(7,:), 'DisplayName', 'Love Joy South');
plot(InnerN_alldata_time, InnerN_alldata_values(:,3), '-', 'LineWidth', 2, 'color',CT(8,:), 'DisplayName', 'Inner North');
plot(InnerS_alldata_time, InnerS_alldata_values(:,3), '-', 'LineWidth', 2, 'color',CT(11,:), 'DisplayName', 'Inner South');
% yline for hypoxic threshold
yline(2, 'LineStyle', '--', 'HandleVisibility', 'off')
hold off;
xlabel('Time');
ylabel('Bottom DO [mg/L]');
title('Bottom DO from all moorings');
legend show;
grid off;

%% Plot temperature


figure(2); clf;
hold on;
plot(LJN_alldata_time, LJN_alldata_values(:,1), 'b.', 'MarkerSize', 7, 'DisplayName', 'Love Joy North');
plot(LJS_alldata_time, LJS_alldata_values(:,1), 'r.', 'MarkerSize', 7, 'DisplayName', 'Love Joy South');
plot(InnerN_alldata_time, InnerN_alldata_values(:,1), 'g.', 'MarkerSize', 7, 'DisplayName', 'Inner North');
plot(InnerS_alldata_time, InnerS_alldata_values(:,1), 'm.', 'MarkerSize', 7, 'DisplayName', 'Inner South');
% yline for hypoxic threshold
hold off;
xlabel('Time');
ylabel('Temperature [°C]');
title('Bottom Temperature from all moorings');
legend show;
grid off;


%% Make a figure with subplots



figure(3); clf; 

s1 = subplot(2,1,1);
hold on;
plot(LJN_alldata_time, LJN_alldata_values(:,3), '-', 'LineWidth', 2, 'color','#24492e', 'DisplayName', 'Love Joy North');
plot(LJS_alldata_time, LJS_alldata_values(:,3), '-', 'LineWidth', 2, 'color','#2c6184', 'DisplayName', 'Love Joy South');
plot(InnerN_alldata_time, InnerN_alldata_values(:,3), '-', 'LineWidth', 2, 'color','#89689d', 'DisplayName', 'Inner North');
plot(InnerS_alldata_time, InnerS_alldata_values(:,3), '-', 'LineWidth', 2, 'color','#e69b99', 'DisplayName', 'Inner South');
% yline for hypoxic threshold
yline(2, 'LineStyle', '--', 'HandleVisibility', 'off')
hold off;
ylabel('Bottom DO [mg/L]');
title('Bottom DO from all moorings');
legend show;
hold off

s2 = subplot(2,1,2);

hold on;
plot(LJN_alldata_time, LJN_alldata_values(:,1), '-', 'LineWidth', 2, 'color','#24492e', 'DisplayName', 'Love Joy North');
plot(LJS_alldata_time, LJS_alldata_values(:,1), '-', 'LineWidth', 2, 'color','#2c6184', 'DisplayName', 'Love Joy South');
plot(InnerN_alldata_time, InnerN_alldata_values(:,1), '-', 'LineWidth', 2, 'color','#89689d', 'DisplayName', 'Inner North');
plot(InnerS_alldata_time, InnerS_alldata_values(:,1), '-', 'LineWidth', 2, 'color','#e69b99','DisplayName', 'Inner South');
% yline for hypoxic threshold
hold off;
xlabel('Time');
ylabel('Temperature [°C]');
title('Bottom temperature from all moorings');
hold off

linkaxes([s1 s2], 'x')

%% Average the data daily

% Calculate daily averages and standard deviations for each site.
% This works directly on the already-concatenated, gap-inserted,
% datetime-converted vectors from earlier in the script
% (e.g. LJN_alldata_time / LJN_alldata_values), using 'omitnan' so that
% the NaN gap-markers from insert_gap_nans (and any missing samples)
% don't wipe out an entire day's average.

[LJN_dailyTime, LJN_dailyMean, LJN_dailyStd]       = daily_average(LJN_alldata_time, LJN_alldata_values);
[LJS_dailyTime, LJS_dailyMean, LJS_dailyStd]       = daily_average(LJS_alldata_time, LJS_alldata_values);
[InnerN_dailyTime, InnerN_dailyMean, InnerN_dailyStd] = daily_average(InnerN_alldata_time, InnerN_alldata_values);
[InnerS_dailyTime, InnerS_dailyMean, InnerS_dailyStd] = daily_average(InnerS_alldata_time, InnerS_alldata_values);

%% plot the daily averages with error bars around the line


% '#00496f', '#0f85a0', '#ed8b00', '#dd4124'

figure(4); clf;
hold on;
plot_shaded(LJN_dailyTime, LJN_dailyMean(:,3), LJN_dailyStd(:,3), '#00496f', 'Love Joy North');
plot_shaded(LJS_dailyTime, LJS_dailyMean(:,3), LJS_dailyStd(:,3), '#0f85a0', 'Love Joy South');
plot_shaded(InnerN_dailyTime, InnerN_dailyMean(:,3), InnerN_dailyStd(:,3), '#ed8b00', 'Inner North');
plot_shaded(InnerS_dailyTime, InnerS_dailyMean(:,3), InnerS_dailyStd(:,3), '#dd4124', 'Inner South');
yline(2, 'LineStyle', '--', 'HandleVisibility', 'off');
hold off;
xlabel('Time');
ylabel('Daily-averaged Bottom DO [mg/L]');
title('Daily-averaged Bottom DO from all moorings (\pm 1 std)');
legend show;
grid off;

%% Plot daily-averaged DO and temperature in one figure with subplots

figure(5); clf;

s3 = subplot(2,1,1);
hold on;
plot_shaded(LJN_dailyTime, LJN_dailyMean(:,3), LJN_dailyStd(:,3), '#00496f', 'Love Joy North');
plot_shaded(LJS_dailyTime, LJS_dailyMean(:,3), LJS_dailyStd(:,3), '#0f85a0', 'Love Joy South');
plot_shaded(InnerN_dailyTime, InnerN_dailyMean(:,3), InnerN_dailyStd(:,3), '#ed8b00', 'Inner North');
plot_shaded(InnerS_dailyTime, InnerS_dailyMean(:,3), InnerS_dailyStd(:,3), '#dd4124', 'Inner South');
yline(2, 'LineStyle', '--', 'HandleVisibility', 'off');
hold off;
ylabel('[mg/L]');
title('Daily-averaged Bottom DO from all moorings (\pm 1 std)');
ylim([0 5])
legend show;
grid off;

s4 = subplot(2,1,2);
hold on;
plot_shaded(LJN_dailyTime, LJN_dailyMean(:,1), LJN_dailyStd(:,1), '#00496f', 'Love Joy North');
plot_shaded(LJS_dailyTime, LJS_dailyMean(:,1), LJS_dailyStd(:,1), '#0f85a0', 'Love Joy South');
plot_shaded(InnerN_dailyTime, InnerN_dailyMean(:,1), InnerN_dailyStd(:,1), '#ed8b00', 'Inner North');
plot_shaded(InnerS_dailyTime, InnerS_dailyMean(:,1), InnerS_dailyStd(:,1), '#dd4124', 'Inner South');
hold off;
xlabel('Time');
ylabel('[°C]');
title('Daily-averaged Bottom Temperature from all moorings (\pm 1 std)');
grid off;

linkaxes([s3 s4], 'x');

%% save this figure to the outdirectory in github

% OutDir = '/Users/heffem3/Documents/GitHub/PennCove_codes/Figures';
% 
% % save the figures here
% 
% saveas(figure(1), fullfile(OutDir, 'BottomDO_MaytoAug.png'));
% 
% saveas(figure(2), fullfile(OutDir, 'BottomTemp_MaytoAug.png'));
% 
% saveas(figure(3), fullfile(OutDir, 'Bottom_DOandTemp_MaytoAug.png'));
% 


%% ---- helper functions ----

function plot_shaded(t, meanVals, stdVals, colorSpec, dispName)
% Plots meanVals vs t with a shaded +/- stdVals band, using colorSpec
% for both the line and a lighter fill of the same hue.
%
% colorSpec can be anything MATLAB's validatecolor() accepts: a short
% code like 'b', a color name like 'blue', or an RGB triplet like
% CT(6,:) from a custom colormap/colorblind-friendly table.
%
% NOTE on NaN handling: plot() naturally breaks a line wherever it hits a
% NaN, so the mean line below is just plotted straight through with NaNs
% left in - that's what creates the visual gap.
% fill()/patch() do NOT behave the same way: a single NaN vertex can
% cause the WHOLE patch to fail to render, rather than just breaking at
% that point. So for the shaded band, we instead find each contiguous
% run of non-NaN data and call fill() separately per run.
 
    upper = meanVals + stdVals;
    lower = meanVals - stdVals;
 
    rgb = validatecolor(colorSpec);       % normalize to an RGB triplet
    faceColor = 0.3 * [1 1 1] + 0.7 * rgb; % lighten it for the shaded band
 
    % --- shaded band: fill each contiguous non-NaN run separately ---
    validMask = ~isnan(meanVals) & ~isnan(stdVals);
    edges = diff([0; validMask; 0]);
    segStarts = find(edges == 1);
    segEnds   = find(edges == -1) - 1;
 
    for k = 1:length(segStarts)
        idx = segStarts(k):segEnds(k);
        if length(idx) < 2
            continue;  % need at least 2 points to draw a band
        end
        tSeg     = t(idx);
        upperSeg = upper(idx);
        lowerSeg = lower(idx);
        fill([tSeg; flipud(tSeg)], [upperSeg; flipud(lowerSeg)], faceColor, ...
             'FaceAlpha', 0.25, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    end
 
    % --- mean line: NaNs left in on purpose so plot() breaks naturally ---
    plot(t, meanVals, '-', 'Color', rgb, 'LineWidth', 2, ...
         'DisplayName', dispName);
end




%% helper function for putting gaps between deployments in the data

function [t_out, v_out] = insert_gap_nans(t_in, v_in, gap_thresh_days)
% t_in: datetime vector, v_in: matching data matrix (rows = time), 
% gap_thresh_days: threshold (in days) above which a gap is considered a break

dt = days(diff(t_in));
gap_idx = find(dt > gap_thresh_days);

t_out = t_in;
v_out = v_in;

% insert from the end backwards so indices don't shift
for k = length(gap_idx):-1:1
    i = gap_idx(k);
    t_nan = t_in(i) + (t_in(i+1) - t_in(i))/2; % midpoint timestamp
    t_out = [t_out(1:i); t_nan; t_out(i+1:end)];
    v_out = [v_out(1:i,:); NaN(1,size(v_in,2)); v_out(i+1:end,:)];
end
end