%% plotting king county time series of dissolved oxygen


% Reads dissolved oxygen data from three mooring CSV files, computes
% daily mean +/- 1 standard deviation, and plots each mooring as a
% subplot (line = daily mean, shaded band = +/- 1 SD).
%
% Update the file paths below if your CSVs live in a different folder.

clear; clc; close all;

%% ---- USER SETTINGS: file info for each mooring ----
% dateCol/timeCol OR datetimeCol should be set (leave the unused one as '')

files(1).path        = 'Penn_Cove_Entrance_Buoy_Raw_Data_Output_-_Surface_20260915.csv';
files(1).name        = 'Penn Cove Entrance Buoy - Surface';
files(1).dateCol     = 'Date(America/Los_Angeles)';
files(1).timeCol     = 'Time(America/Los_Angeles)';
files(1).datetimeCol = '';
files(1).oxyCol      = 'HCEP(OXY)';

files(2).path        = 'Penn_Cove_Entrance_Buoy_Raw_Data_Output_-_Bottom_20260915.csv';
files(2).name        = 'Penn Cove Entrance Buoy - Bottom';
files(2).dateCol     = '';
files(2).timeCol     = '';
files(2).datetimeCol = 'DateTime';
files(2).oxyCol      = 'Oxygen_mgL';

files(3).path        = 'Coupeville_Wharf_Mooring_Raw_Data_Output_20260915.csv';
files(3).name        = 'Coupeville Wharf Mooring';
files(3).dateCol     = 'Date(America/Los_Angeles)';
files(3).timeCol     = 'Time(America/Los_Angeles)';
files(3).datetimeCol = '';
files(3).oxyCol      = 'HCEP(OXY)';

%% ---- Read + process each file ----
results = struct('name',{},'days',{},'dailyMean',{},'dailyStd',{});

for k = 1:numel(files)
    opts = detectImportOptions(files(k).path, 'VariableNamingRule','preserve');
    opts = setvartype(opts, files(k).oxyCol, 'double');
    % Treat these text values as missing (NaN) for the oxygen column
    opts = setvaropts(opts, files(k).oxyCol, 'TreatAsMissing', {'NA','NaN'});
    T = readtable(files(k).path, opts);

    % Build a datetime vector, whether the file has one combined column
    % or separate Date/Time columns
    if ~isempty(files(k).datetimeCol)
        dt = datetime(T.(files(k).datetimeCol), ...
            'InputFormat','yyyy-MM-dd HH:mm:ss');
    else
        dateStr = string(T.(files(k).dateCol));
        timeStr = string(T.(files(k).timeCol));
        dt = datetime(dateStr + " " + timeStr, ...
            'InputFormat','yyyy-MM-dd HH:mm:ss');
    end

    oxy = T.(files(k).oxyCol);

    % ---- sanity-range filter (catches bad sensor/data errors) ----
    % A spike into the thousands/millions (stuck sensor, corrupted field,
    % etc.) will corrupt the local median/std that the Hampel filter
    % relies on if it isn't removed first, so this runs before Hampel.
    oxyRange = [0, 17];   % mg/L -- adjust if your sensor legitimately reads higher
    oxy(oxy < oxyRange(1) | oxy > oxyRange(2)) = NaN;

    % Drop rows with missing timestamp or oxygen value
    valid = ~isnat(dt) & ~isnan(oxy);
    dt  = dt(valid);
    oxy = oxy(valid);

    % Sort chronologically (raw files may be newest-first)
    [dt, sortIdx] = sort(dt);
    oxy = oxy(sortIdx);

    % ---- Hampel filter: flag & remove outliers ----
    % 5-sample window (2 samples on each side of center) and a
    % 2-standard-deviation threshold. Flagged points are set to NaN
    % (removed) rather than replaced with the filter's estimate.
    [~, isOutlier] = hampel(oxy, 2, 2);
    oxy(isOutlier) = NaN;

    % ---- Remove negative oxygen values (not physically valid) ----
    oxy(oxy < 0) = NaN;

    % Drop points removed by the filter/negative-value check above
    keep = ~isnan(oxy);
    dt  = dt(keep);
    oxy = oxy(keep);

    % Group readings by calendar day, compute mean & std
    dayOf = dateshift(dt, 'start', 'day');
    [uniqueDays, ~, ic] = unique(dayOf);
    dailyMean = accumarray(ic, oxy, [], @mean);
    dailyStd  = accumarray(ic, oxy, [], @std);

    % ---- Reindex onto a continuous daily calendar ----
    % Fills any missing days with NaN so plot/fill draw a visible gap
    % instead of connecting a straight line across skipped days.
    fullDays = (uniqueDays(1) : caldays(1) : uniqueDays(end))';
    [isPresent, loc] = ismember(fullDays, uniqueDays);
    filledMean = NaN(size(fullDays));
    filledStd  = NaN(size(fullDays));
    filledMean(isPresent) = dailyMean(loc(isPresent));
    filledStd(isPresent)  = dailyStd(loc(isPresent));

    results(k).name      = files(k).name;
    results(k).days      = fullDays;
    results(k).dailyMean = filledMean;
    results(k).dailyStd  = filledStd;
end

%% ---- Plot: one subplot per mooring ----
figure('Position',[100 100 900 950]);

% Colorblind-friendly palette (Okabe-Ito): orange, sky blue, bluish green
colors = [230 159 0; 86 180 233; 0 158 115] / 255;

ax = gobjects(numel(results),1);

for k = 1:numel(results)
    ax(k) = subplot(numel(results), 1, k);

    d = results(k).days(:);
    m = results(k).dailyMean(:);
    s = results(k).dailyStd(:);
    c = colors(mod(k-1, size(colors,1)) + 1, :);

    % Shaded +/- 1 SD band
    fill([d; flipud(d)], [m+s; flipud(m-s)], c, ...
        'FaceAlpha', 0.25, 'EdgeColor', 'none');
    hold on;
    plot(d, m, 'Color', c, 'LineWidth', 1.5);
    hold off;

    ylabel('Oxygen (mg/L)');
    title(results(k).name, 'Interpreter','none');
    grid on;
    if ~isempty(d)
        xlim([min(d) max(d)]);
    end
end

xlabel('Date');
sgtitle('Daily-Averaged Dissolved Oxygen (\pm 1 SD)');

% Link x and y axes across all three subplots
linkaxes(ax, 'xy');

%% ---- Second figure: Surface & Bottom overlaid, Coupeville separate ----
% Assumes files(1)=Surface, files(2)=Bottom, files(3)=Coupeville (as set above)
figure('Position',[100 100 900 700]);
ax2 = gobjects(2,1);

% -- Subplot 1: Penn Cove Entrance Buoy, Surface + Bottom overlay --
ax2(1) = subplot(2,1,1);
hold on;
entranceIdx = [1 2];   % indices into results/colors for Surface, Bottom
lineHandles = gobjects(numel(entranceIdx),1);
for j = 1:numel(entranceIdx)
    k = entranceIdx(j);
    d = results(k).days(:);
    m = results(k).dailyMean(:);
    s = results(k).dailyStd(:);
    c = colors(k,:);
    fill([d; flipud(d)], [m+s; flipud(m-s)], c, ...
        'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    lineHandles(j) = plot(d, m, 'Color', c, 'LineWidth', 1.5, ...
        'DisplayName', results(k).name);
end
yline(2, '--', '2 mg/L', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.2, ...
    'LabelHorizontalAlignment', 'left');
hold off;
ylabel('Oxygen (mg/L)');
title('Penn Cove Entrance Buoy: Surface and Bottom');
grid on;
legend(lineHandles, 'Location', 'best');

% -- Subplot 2: Coupeville Wharf Mooring --
ax2(2) = subplot(2,1,2);
k = 3;
d = results(k).days(:);
m = results(k).dailyMean(:);
s = results(k).dailyStd(:);
c = colors(k,:);
fill([d; flipud(d)], [m+s; flipud(m-s)], c, ...
    'FaceAlpha', 0.25, 'EdgeColor', 'none');
hold on;
plot(d, m, 'Color', c, 'LineWidth', 1.5);
yline(2, '--', '2 mg/L', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.2, ...
    'LabelHorizontalAlignment', 'left');
hold off;
ylabel('Oxygen (mg/L)');
title(results(k).name, 'Interpreter', 'none');
grid on;

xlabel('Date');
sgtitle('Daily dissolved oxygen values at the King County moorings in Penn Cove');



% Cap the y-axis at 17 mg/L on both subplots
ylim(ax2(1), [0 17]);
ylim(ax2(2), [0 17]);


% Keep the two subplots' time axes in sync (y left independent, since
% the two panels may have different natural ranges)
linkaxes(ax2, 'x');

%% Add in my current bottom DO data 

MayJun = load('TODOdata_MayJun2026_L3.mat');
JunJul = load('TODOdata_JunJul2026_L3.mat');
JulAug = load('TODOdata_JulAug2026_L3.mat');
AugSep = load('TODOdata_AugSep2026_L3.mat');


%% concatenate the data in time

% LJN
LJN_alldata_time = [MayJun.TODO_data.LoveJoyNorth.data.tstamp; JunJul.TODO_data.LoveJoyNorth.data.tstamp; JulAug.TODO_data.LoveJoyNorth.data.tstamp; AugSep.TODO_data.LoveJoyNorth.data.tstamp]; 
LJN_alldata_values = [MayJun.TODO_data.LoveJoyNorth.data.values; JunJul.TODO_data.LoveJoyNorth.data.values; JulAug.TODO_data.LoveJoyNorth.data.values; AugSep.TODO_data.LoveJoyNorth.data.values]; 

%LJS
LJS_alldata_time = [MayJun.TODO_data.LoveJoySouth.data.tstamp; JunJul.TODO_data.LoveJoySouth.data.tstamp; JulAug.TODO_data.LoveJoySouth.data.tstamp; AugSep.TODO_data.LoveJoySouth.data.tstamp];
LJS_alldata_values = [MayJun.TODO_data.LoveJoySouth.data.values; JunJul.TODO_data.LoveJoySouth.data.values; JulAug.TODO_data.LoveJoySouth.data.values; AugSep.TODO_data.LoveJoySouth.data.values]; 

% Inner N
InnerN_alldata_time = [MayJun.TODO_data.InnerNorth.data.tstamp; JunJul.TODO_data.InnerNorth.data.tstamp; JulAug.TODO_data.InnerNorth.data.tstamp; AugSep.TODO_data.InnerNorth.data.tstamp];
InnerN_alldata_values = [MayJun.TODO_data.InnerNorth.data.values; JunJul.TODO_data.InnerNorth.data.values; JulAug.TODO_data.InnerNorth.data.values; AugSep.TODO_data.InnerNorth.data.values]; 

% Inner S
InnerS_alldata_time = [MayJun.TODO_data.InnerSouth.data.tstamp; JunJul.TODO_data.InnerSouth.data.tstamp; JulAug.TODO_data.InnerSouth.data.tstamp; AugSep.TODO_data.InnerSouth.data.tstamp];
InnerS_alldata_values = [MayJun.TODO_data.InnerSouth.data.values; JunJul.TODO_data.InnerSouth.data.values; JulAug.TODO_data.InnerSouth.data.values; AugSep.TODO_data.InnerSouth.data.values]; 


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


%% Plot bottom oxygen from LJN with the bottom oxygen from the KC moorings


 
ljnTime = LJN_alldata_time(:);
ljnOxy  = LJN_alldata_values(:,3);
oxyRangeLJN = [0, 7];   % mg/L -- same sanity bound used for the KC moorings
 
% Drop missing, then sort chronologically
valid = ~isnat(ljnTime) & ~isnan(ljnOxy);
ljnTime = ljnTime(valid);
ljnOxy  = ljnOxy(valid);
[ljnTime, sortIdx] = sort(ljnTime);
ljnOxy = ljnOxy(sortIdx);
 
% Same Hampel filter + hard range filter used above
[~, isOutlier] = hampel(ljnOxy, 2, 2);
ljnOxy(isOutlier) = NaN;
ljnOxy(ljnOxy < oxyRangeLJN(1) | ljnOxy > oxyRangeLJN(2)) = NaN;
 
keep = ~isnan(ljnOxy);
ljnTime = ljnTime(keep);
ljnOxy  = ljnOxy(keep);
 
% Daily mean/std, reindexed onto a continuous calendar so gaps break the line
dayOf = dateshift(ljnTime, 'start', 'day');
[uniqueDaysLJN, ~, ic] = unique(dayOf);
dailyMeanLJN = accumarray(ic, ljnOxy, [], @mean);
dailyStdLJN  = accumarray(ic, ljnOxy, [], @std);
 
fullDaysLJN = (uniqueDaysLJN(1) : caldays(1) : uniqueDaysLJN(end))';
[isPresent, loc] = ismember(fullDaysLJN, uniqueDaysLJN);
filledMeanLJN = NaN(size(fullDaysLJN));
filledStdLJN  = NaN(size(fullDaysLJN));
filledMeanLJN(isPresent) = dailyMeanLJN(loc(isPresent));
filledStdLJN(isPresent)  = dailyStdLJN(loc(isPresent));
 
% ---- Plot: King County Bottom mooring + your mooring, same axes ----
kcColor  = colors(2,:);           % same color already used for the KC Bottom mooring
ljnColor = [204 121 167] / 255;   % reddish-purple, colorblind-friendly (Okabe-Ito)
 
figure('Position',[100 100 900 500]);
hold on;
 
% King County Bottom mooring
d = results(2).days(:);
m = results(2).dailyMean(:);
s = results(2).dailyStd(:);
fill([d; flipud(d)], [m+s; flipud(m-s)], kcColor, ...
    'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
h1 = plot(d, m, 'Color', kcColor, 'LineWidth', 1.5, ...
    'DisplayName', results(2).name);
 
% Your mooring
fill([fullDaysLJN; flipud(fullDaysLJN)], ...
     [filledMeanLJN + filledStdLJN; flipud(filledMeanLJN - filledStdLJN)], ...
     ljnColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
h2 = plot(fullDaysLJN, filledMeanLJN, 'Color', ljnColor, 'LineWidth', 1.5, ...
    'DisplayName', 'LJN Mooring - Bottom');
 

yline(2, '--', '2 mg/L', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.2, ...
    'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');


hold off;
ylabel('Oxygen (mg/L)');
title('Daily bottom dissolved oxygen from King County mooring and our mooring');
grid on;
legend([h1 h2], 'Location', 'best');
xlabel('Date');

%% Pull in the surface DO data from the LJN SWIFT

% SWIFT 28 is the LJN swift

% read in the concatrnated data

% Read and concatenate SWIFT 28 surface dissolved oxygen data
swift28Files = {'swift28_MayJun2026_cat.mat','swift28_JunJul2026_cat.mat', ...
    'swift28_JulAug2026_cat.mat', 'swift28_AugSep2026_cat.mat'};


swift28_time   = [];
swift28_O2mgl = [];

for i = 1:numel(swift28Files)
    tmp = load(swift28Files{i});
    vn  = fieldnames(tmp);
    s   = tmp.(vn{1});                 % 1x262 struct array

    % Pull the field out of every element, force each to a column, stack them
    t = cellfun(@(x) x(:), {s.time},  'UniformOutput', false);
    v = cellfun(@(x) x(:), {s.O2conc}, 'UniformOutput', false);  

    swift28_time   = [swift28_time;   vertcat(t{:})];
    swift28_O2mgl = [swift28_O2mgl; vertcat(v{:})];
end

%% adjust that data as well

[swift28_time, swift28_O2mgl] = insert_gap_nans(swift28_time, swift28_O2mgl, 0.5);
swift28_time = datetime(swift28_time, 'ConvertFrom', 'datenum');   




%% --- NEW SECTION ADDED SEPTEMBER 28 2026 --- %%
%%


%% ================== ADDENDUM: DAY-OF-YEAR OVERLAY PLOT ==================
% Paste this AFTER the LJN daily-mean section (it needs results, colors,
% fullDaysLJN, filledMeanLJN, filledStdLJN) and BEFORE the helper
% function section at the bottom of your script.
%
% Top panel:    BOTTOM oxygen. King County bottom (one line per year)
%               + your LJN mooring (thick dashed line with markers).
% Bottom panel: SURFACE oxygen, King County (one line per year).
%
% x-axis is "day of year", drawn on a dummy leap year (2000) so the ticks
% can be labeled by month and Feb 29 is handled properly.

% Map any datetime onto the dummy year 2000 (same month/day)
toDummy = @(d) datetime(2000, month(d), day(d));

% Year colors (Okabe-Ito, colorblind-friendly). Add more rows if needed.
yearList   = [2023 2024 2025 2026];
yearColors = [  0 114 178;    % 2023 blue
              230 159   0;    % 2024 orange
                0 158 115;    % 2025 green
               86 180 233] / 255;  % 2026 sky blue
ljnColor2  = [204 121 167] / 255;  % reddish-purple for your mooring

figure('Position',[100 100 950 800]);
ax3 = gobjects(2,1);

panelIdx   = [2 1];                       % results index: 2 = Bottom, 1 = Surface
panelTitle = {'Bottom dissolved oxygen: King County Penn Cove Entrance Buoy vs. our LJN mooring', ...
              'Surface dissolved oxygen: King County Penn Cove Entrance Buoy'};

for p = 1:2
    ax3(p) = subplot(2,1,p);
    hold on;
    k = panelIdx(p);

    d = results(k).days(:);
    m = results(k).dailyMean(:);
    yrs = year(d);

    hYear = gobjects(0);
    for j = 1:numel(yearList)
        sel = (yrs == yearList(j));
        if ~any(sel), continue; end
        hYear(end+1) = plot(toDummy(d(sel)), m(sel), ...
            'Color', yearColors(j,:), 'LineWidth', 1.4, ...
            'DisplayName', sprintf('King County %d', yearList(j))); %#ok<SAGROW>
    end

    yline(2, '--', '2 mg/L', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.2, ...
        'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');

    % ---- Highlight your LJN data on the bottom panel only ----
    if p == 1
        okLJN = ~isnan(filledMeanLJN);
        xL = toDummy(fullDaysLJN(:));
        mL = filledMeanLJN(:);
        sL = filledStdLJN(:);

        % Light +/- 1 SD band behind the line
        fill([xL; flipud(xL)], [mL+sL; flipud(mL-sL)], ljnColor2, ...
            'FaceAlpha', 0.20, 'EdgeColor', 'none', 'HandleVisibility', 'off');

        % Thick dashed line with markers so it stands out from the solid KC lines
        hLJN = plot(xL, mL, '--', 'Color', ljnColor2, 'LineWidth', 3, ...
            'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', ljnColor2, ...
            'MarkerIndices', find(okLJN, 1):3:numel(mL), ...
            'DisplayName', sprintf('OUR LJN mooring, bottom (%d)', year(fullDaysLJN(1))));

        legend([hYear hLJN], 'Location', 'best');
    else
        legend(hYear, 'Location', 'best');
    end

    hold off;
    ylabel('Oxygen (mg/L)');
    title(panelTitle{p}, 'Interpreter', 'none');
    grid on;
    box on;
    xlim([datetime(2000,1,1) datetime(2000,12,31)]);
    ylim([0 17]);
    xtickformat('MMM');
end

% Shade the date range covered by your LJN deployment on the bottom panel
% (drawn behind everything else) to make it obvious which part is "new"
xLJNrange = toDummy([fullDaysLJN(1) fullDaysLJN(end)]);
yl = ylim(ax3(1));
hold(ax3(1), 'on');   % IMPORTANT: without this, fill() wipes the existing lines
hBand = fill(ax3(1), [xLJNrange(1) xLJNrange(2) xLJNrange(2) xLJNrange(1)], ...
             [yl(1) yl(1) yl(2) yl(2)], ljnColor2, ...
             'FaceAlpha', 0.07, 'EdgeColor', 'none', 'HandleVisibility', 'off');
uistack(hBand, 'bottom');
hold(ax3(1), 'off');

xlabel(ax3(2), 'Month (day of year)');
sgtitle('Dissolved oxygen by day of year, all years overlaid');

linkaxes(ax3, 'xy');


%% ============ ADD swift28 SURFACE DATA TO THE SURFACE PANEL ============
% Run AFTER the code above. Needs swift28_time (datetime) and
% swift28_values from your loading/gap-insertion steps.

swTime = swift28_time(:);
swOxy  = swift28_O2mgl(:,1);    
swOxy  = swOxy * 0.032;           % convert µmol/L -> mg/L (O2 = 32 g/mol)
oxyRangeSw = [0, 17];             % mg/L sanity bound (same as the KC surface data)

% Drop missing, then sort chronologically
valid  = ~isnat(swTime) & ~isnan(swOxy);
swTime = swTime(valid);
swOxy  = swOxy(valid);
[swTime, sortIdx] = sort(swTime);
swOxy  = swOxy(sortIdx);

% Same Hampel + range filters used for the other datasets
[~, isOutlier] = hampel(swOxy, 2, 2);
swOxy(isOutlier) = NaN;
swOxy(swOxy < oxyRangeSw(1) | swOxy > oxyRangeSw(2)) = NaN;
keep   = ~isnan(swOxy);
swTime = swTime(keep);
swOxy  = swOxy(keep);

% Daily mean/std on a continuous calendar (gaps break the line)
dayOf = dateshift(swTime, 'start', 'day');
[uniqueDaysSw, ~, ic] = unique(dayOf);
dailyMeanSw = accumarray(ic, swOxy, [], @mean);
dailyStdSw  = accumarray(ic, swOxy, [], @std);

fullDaysSw = (uniqueDaysSw(1) : caldays(1) : uniqueDaysSw(end))';
[isPresent, loc] = ismember(fullDaysSw, uniqueDaysSw);
filledMeanSw = NaN(size(fullDaysSw));
filledStdSw  = NaN(size(fullDaysSw));
filledMeanSw(isPresent) = dailyMeanSw(loc(isPresent));
filledStdSw(isPresent)  = dailyStdSw(loc(isPresent));

% ---- Add to the SURFACE panel (ax3(2)) of the day-of-year figure ----
swColor = [204 121 167] / 255;    % same reddish-purple as the LJN bottom mooring
xS = toDummy(fullDaysSw(:));
mS = filledMeanSw(:);
sS = filledStdSw(:);
okSw = ~isnan(mS);

hold(ax3(2), 'on');               % keep hold on so nothing gets wiped

% Light shaded deployment window (behind everything)
xSwRange = toDummy([fullDaysSw(1) fullDaysSw(end)]);
ylS = ylim(ax3(2));
hBandS = fill(ax3(2), [xSwRange(1) xSwRange(2) xSwRange(2) xSwRange(1)], ...
              [ylS(1) ylS(1) ylS(2) ylS(2)], swColor, ...
              'FaceAlpha', 0.07, 'EdgeColor', 'none', 'HandleVisibility', 'off');
uistack(hBandS, 'bottom');

% +/- 1 SD band
fill(ax3(2), [xS; flipud(xS)], [mS+sS; flipud(mS-sS)], swColor, ...
    'FaceAlpha', 0.20, 'EdgeColor', 'none', 'HandleVisibility', 'off');

% Thick dashed line with markers, matching the LJN style
hSw = plot(ax3(2), xS, mS, '--', 'Color', swColor, 'LineWidth', 3, ...
    'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', swColor, ...
    'MarkerIndices', find(okSw, 1):3:numel(mS), ...
    'DisplayName', sprintf('OUR swift28 mooring, surface (%d)', year(fullDaysSw(1))));

hold(ax3(2), 'off');

% Rebuild the legend (hYear still holds the KC surface handles from the loop above)
legend(ax3(2), [hYear hSw], 'Location', 'best');
title(ax3(2), 'Surface dissolved oxygen: King County Penn Cove Entrance Buoy vs. our swift28 mooring', ...
    'Interpreter', 'none');







%% ===== stop here ===== %%


%% addendum to plot this as day of year plot instead of one long timeseries

% Top panel:    BOTTOM oxygen. King County bottom (one line per year)
%               + LJN mooring (thick dashed line with markers).
% Bottom panel: SURFACE oxygen, King County (one line per year).
%
% x-axis is "day of year", drawn on a dummy leap year (2000) so the ticks
% can be labeled by month and Feb 29 is handled properly.
 
% Map any datetime onto the dummy year 2000 (same month/day)
% toDummy = @(d) datetime(2000, month(d), day(d));
% 
% % Year colors (Okabe-Ito, colorblind-friendly). Add more rows if needed.
% yearList   = [2023 2024 2025 2026];
% yearColors = [  0 114 178;    % 2023 blue
%               230 159   0;    % 2024 orange
%                 0 158 115;    % 2025 green
%                86 180 233] / 255;  % 2026 sky blue
% ljnColor2  = [204 121 167] / 255;  % reddish-purple for your mooring
% 
% figure('Position',[100 100 950 800]);
% ax3 = gobjects(2,1);
% 
% panelIdx   = [2 1];                       % results index: 2 = Bottom, 1 = Surface
% panelTitle = {'Bottom dissolved oxygen: King County Penn Cove Entrance Buoy vs. our LJN mooring', ...
%               'Surface dissolved oxygen: King County Penn Cove Entrance Buoy'};
% 
% for p = 1:2
%     ax3(p) = subplot(2,1,p);
%     hold on;
%     k = panelIdx(p);
% 
%     d = results(k).days(:);
%     m = results(k).dailyMean(:);
%     yrs = year(d);
% 
%     hYear = gobjects(0);
%     for j = 1:numel(yearList)
%         sel = (yrs == yearList(j));
%         if ~any(sel), continue; end
%         hYear(end+1) = plot(toDummy(d(sel)), m(sel), ...
%             'Color', yearColors(j,:), 'LineWidth', 1.4, ...
%             'DisplayName', sprintf('King County %d', yearList(j))); %#ok<SAGROW>
%     end
% 
%     yline(2, '--', '2 mg/L', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.2, ...
%         'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
% 
%     % ---- Highlight your LJN data on the bottom panel only ----
%     if p == 1
%         okLJN = ~isnan(filledMeanLJN);
%         xL = toDummy(fullDaysLJN(:));
%         mL = filledMeanLJN(:);
%         sL = filledStdLJN(:);
% 
%         % Light +/- 1 SD band behind the line
%         fill([xL; flipud(xL)], [mL+sL; flipud(mL-sL)], ljnColor2, ...
%             'FaceAlpha', 0.20, 'EdgeColor', 'none', 'HandleVisibility', 'off');
% 
%         % Thick dashed line with markers so it stands out from the solid KC lines
%         hLJN = plot(xL, mL, '--', 'Color', ljnColor2, 'LineWidth', 3, ...
%             'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', ljnColor2, ...
%             'MarkerIndices', find(okLJN, 1):3:numel(mL), ...
%             'DisplayName', sprintf('OUR LJN mooring, bottom (%d)', year(fullDaysLJN(1))));
% 
%         legend([hYear hLJN], 'Location', 'best');
%     else
%         legend(hYear, 'Location', 'best');
%     end
% 
%     hold off;
%     ylabel('Oxygen (mg/L)');
%     title(panelTitle{p}, 'Interpreter', 'none');
%     grid on;
%     box on;
%     xlim([datetime(2000,1,1) datetime(2000,12,31)]);
%     ylim([0 17]);
%     xtickformat('MMM');
% end
% 
% % Shade the date range covered by your LJN deployment on the bottom panel
% % (drawn behind everything else) to make it obvious which part is "new"
% xLJNrange = toDummy([fullDaysLJN(1) fullDaysLJN(end)]);
% yl = ylim(ax3(1));
% hold(ax3(1), 'on');   % IMPORTANT: without this, fill() wipes the existing lines
% hBand = fill(ax3(1), [xLJNrange(1) xLJNrange(2) xLJNrange(2) xLJNrange(1)], ...
%              [yl(1) yl(1) yl(2) yl(2)], ljnColor2, ...
%              'FaceAlpha', 0.07, 'EdgeColor', 'none', 'HandleVisibility', 'off');
% uistack(hBand, 'bottom');
% hold(ax3(1), 'off');
% 
% xlabel(ax3(2), 'Month (day of year)');
% sgtitle('Dissolved oxygen by day of year, all years overlaid');
% 
% linkaxes(ax3, 'xy');

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