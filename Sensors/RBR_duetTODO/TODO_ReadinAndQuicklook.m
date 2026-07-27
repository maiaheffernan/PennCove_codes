%%% Reading in RBR T.ODO data and quick look plots %%%

%%% Maia Heffernan, April 2026

% edited July 1, 2026. Maia H.

% You will need the RSKtools toolbox for this script 

clear all; close all;


% Add rsktools folder to path if you need to: 
% addpath('/Users/heffem3/Documents/MATLAB/rbr-rsktools-7a76410a599a')

%% load in the data 

% The data files are organized by recovery month and mooring name in Google
% Drive, so this makes pulling out the TODO-specific data a little
% complicated. So, to read all the data into this script you must go to the
% high-level 'Data' directory where you can see all the mooring name
% directories. Then run this section which seraches for the files that end
% with the serial numbers of the TODOs. This should hopefully pull all the
% data into your workspace in one go.




% === MAKE SURE YOU ARE IN THE 'DATA' DIRECTORY FOR THE MONTH YOU ARE INTERESTED IN ====




SNs = {'241787', '241789', '241791', '241792'}; % Wire walker serial #s not included here: 241790 (WWN), 241788 (WWS)
moorings = {'LoveJoyNorth', 'LoveJoySouth', 'InnerNorth', 'InnerSouth'}; % these match the order of the serial numbers
months = 'JunJul2026'; % edit this based on the data you are downloading

TODO_data = struct(); % create an empty struct that I will read data into

for i = 1:length(SNs)

    % setting the folder path first with the understanding that there is a
    % depth component to the name that changes, so I will parse that with
    % the * wild card symbol.

    folderPath = fullfile(sprintf('%s_%s', moorings{i}, months), 'RBR_TODO'); % file path from the high-level data directory
    filePattern = sprintf('%s_%s_*_sn%s.rsk', moorings{i}, months, SNs{i}); % naming pattern

    fileInfo = dir(fullfile(folderPath, filePattern));  % dir() resolves the wildcard * symbol

% some info in case something went weird with the data load-in

     if isempty(fileInfo)
        warning('No file found for %s (SN %s) — check path/pattern.', moorings{i}, SNs{i});
        continue
    elseif length(fileInfo) > 1
        warning('Multiple matches for %s (SN %s); using the first one.', moorings{i}, SNs{i});
    end

    fullFileName = fullfile(fileInfo(1).folder, fileInfo(1).name); % put the file path and name together to get the full directions


    fprintf('Opening: %s (%.1f KB)\n', fullFileName, fileInfo(1).bytes/1024);
    
    if fileInfo(1).bytes < 10000  % real .rsk files are almost never this small
        warning('File looks suspiciously small — likely a Google Drive placeholder, not fully synced.');
    end


    fieldName = sprintf('%s', moorings{i});
    TODO_data.(fieldName) = RSKreaddata(RSKopen(fullFileName));

end

%% convert the DO values to mg/L from umol/L

% conversion: DO value (umol/L) * 0.031998 = DO value (mg/L)

% Convert DO values to mg/L for each sensor in the TODO_data struct
for i = 1:length(SNs)
    fieldName = sprintf('%s', moorings{i});
    TODO_data.(fieldName).data.values(:, 3) = TODO_data.(fieldName).data.values(:, 2) * 0.031998; % Convert to mg/L

    % add a channel name and ID for the new mg/L variable created above

    newIdx = numel(TODO_data.(fieldName).channels) + 1;
    TODO_data.(fieldName).channels(newIdx).shortName     = 'doxy32';
    TODO_data.(fieldName).channels(newIdx).longName      = 'Dissolved Oxygen';
    TODO_data.(fieldName).channels(newIdx).units         = 'mg/L';
    TODO_data.(fieldName).channels(newIdx).unitsPlainText = 'mg/L';
    TODO_data.(fieldName).channels(newIdx).channelID     = newIdx;

end



%% plot the raw data


figure(1); clf;

ax1 = subplot(2,1,1); hold(ax1, 'on');
ax2 = subplot(2,1,2); hold(ax2, 'on');

for ii = 1:length(SNs)

    fieldName = sprintf('%s', moorings{ii});

    % Extract raw values
    DO_mgl_vals = TODO_data.(fieldName).data.values(:,3);
    temp_vals = TODO_data.(fieldName).data.values(:,1);
    tstamp = TODO_data.(fieldName).data.tstamp;

    % Plot DO on top subplot
    plot(ax1, tstamp, DO_mgl_vals, 'DisplayName', moorings{ii});

    % Plot temp on bottom subplot
    plot(ax2, tstamp, temp_vals, 'DisplayName', moorings{ii});
end


% plot formatting

    axes(ax1);
        yline(2, 'k--', 'HandleVisibility', 'off');
        datetick('x');
        ylim([0 10])
        xlabel('Time'); ylabel('DO (mg/L)');
        title('Raw bottom dissolved oxygen data');
        legend('Location', 'best');
        grid on;
    
    
    axes(ax2);
        datetick('x');
        ylim([8 12])
        xlabel('Time'); ylabel('Temp (\circC)');
        title('Raw bottom temperature data');
        legend('Location', 'best');
        grid on;

  

   
        
%% Save out the figure to my raw data figures on GitHub 

% CHANGE THE MONTH DIRECTORY IN THE FILE PATH BELOW AS NEEDED

outDir = '/Users/heffem3/Documents/GitHub/PennCove_codes/Figures/MayJun2026/RawData_plots';

% make sure the directory exists; create it if not
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

figName = sprintf('TODO_QuickLook_%s.png', months); 
outFile = fullfile(outDir, figName);

% Save 
exportgraphics(figure(1), outFile, 'Resolution', 300);

%% save out the raw data to Google Drive

raw_values = TODO_data; % in case I need to use it in this script

save TODOdata_JunJul2026_raw.mat TODO_data

%% clean the data with a hampel filter and rate of change flagging

% == first look to see what the best filtering bounds are going to be ==

windowSizes = [3 5 7 11 15];
nSigmas     = [2 2.5 3 4];

nFlagged = zeros(length(windowSizes), length(nSigmas));

% this is with temperature-- do tje same with DO
for w = 1:length(windowSizes)
    for k = 1:length(moorings)
        moorName = moorings{k};
        thisSensor = raw_values.(moorName);

        for s = 1:length(nSigmas)
            [~, outliers] = hampel(thisSensor.data.values(:,3), windowSizes(w), nSigmas(s));
            nFlagged(w,s) = sum(outliers);
        end
    end

end

disp(array2table(nFlagged, 'RowNames', string(windowSizes)+"_win", ...
    'VariableNames', "sigma"+string(nSigmas)))

% look for where the values are plateauing in the number of data points
% flagged-- this means that the filter is reaching the end of its
% effectiveness and I;ve likely cut out all the bad data 



clear thisSensor

%% Choose how much to filter changes in DO and temp buy looking at the distributions in swings

windowSpan = 5;
halfWin = floor(windowSpan/2);  % centered window

allSwingDO   = [];
allSwingTemp = [];

for k = 1:length(moorings)
    thisSensor = raw_values.(moorings{k});

    swingDO_k   = movmax(thisSensor.data.values(:,3), [halfWin halfWin]) - ...
                  movmin(thisSensor.data.values(:,3), [halfWin halfWin]);  
    swingTemp_k = movmax(thisSensor.data.values(:,1), [halfWin halfWin]) - ...
                  movmin(thisSensor.data.values(:,1), [halfWin halfWin]);

    allSwingDO   = [allSwingDO;   swingDO_k];
    allSwingTemp = [allSwingTemp; swingTemp_k];
end

figure; histogram(allSwingDO, 200); title('5-sample DO swing distribution (all moorings)');
disp('DO swing percentiles [95 99 99.5 99.9]:')
disp(prctile(allSwingDO, [95 99 99.5 99.9]))

figure; histogram(allSwingTemp, 200); title('5-sample Temp swing distribution (all moorings)');
disp('Temp swing percentiles [95 99 99.5 99.9]:')
disp(prctile(allSwingTemp, [95 99 99.5 99.9]))

% choose maxRateDO / maxRateTemp from these pooled values. choose values between the 99th and 99.5th percentile

clear thisSensor swingDO_k swingTemp_k



%% clean

TODO_data = raw_values;  

% trim the timestamps
startTime = datetime(2026, 6, 26, 0, 0, 0);
endTime   = datetime(2026, 7, 21, 16, 30, 0);
startTime_dn = datenum(startTime);
endTime_dn   = datenum(endTime);

% rate of change thresholds (per 1-minute sample) -- update these based on
% the pooled percentiles above
maxRateDO   = 0.3;
maxRateTemp = 0.3;

windowSpan = 5;
halfWin    = floor(windowSpan/2);   % centered window
padSamples = 3;                      % dilate flagged spikes by this many samples each side

for i = 1:length(moorings)
    moorName  = moorings{i};
    thisSensor = TODO_data.(moorName);

    % Remove data points outside the specified time range
    validIndices = thisSensor.data.tstamp >= startTime_dn & thisSensor.data.tstamp <= endTime_dn;
    thisSensor.data.values = thisSensor.data.values(validIndices, :);
    thisSensor.data.tstamp = thisSensor.data.tstamp(validIndices);

    % Hampel filter on each channel
    [~, tempOutliers]  = hampel(thisSensor.data.values(:, 1), 5, 3);
    [~, doOutliers]    = hampel(thisSensor.data.values(:, 2), 5, 3);
    [~, domglOutliers] = hampel(thisSensor.data.values(:, 3), 5, 3);
    hampel_bad = tempOutliers | doOutliers | domglOutliers;

    % rate of change filter -- centered window
    swingTemp = movmax(thisSensor.data.values(:,1), [halfWin halfWin], 'omitnan') - ...
            movmin(thisSensor.data.values(:,1), [halfWin halfWin], 'omitnan');
    swingDO   = movmax(thisSensor.data.values(:,3), [halfWin halfWin], 'omitnan') - ...
            movmin(thisSensor.data.values(:,3), [halfWin halfWin], 'omitnan');

    tempRateExceed = swingTemp > maxRateTemp;
    doRateExceed   = swingDO   > maxRateDO;

    rate_bad_raw = tempRateExceed | doRateExceed;

    % dilate flagged points so the edges of a spike get caught too
    rate_bad = movmax(rate_bad_raw, [padSamples padSamples]);

    % combine both filters
    bad_rows = hampel_bad | rate_bad;

    % save flag masks
    thisSensor.data.bad_rows     = bad_rows;
    thisSensor.data.hampel_bad   = hampel_bad;
    thisSensor.data.rate_bad_raw = rate_bad_raw;
    thisSensor.data.rate_bad     = rate_bad;

    % NaN out flagged rows (all channels)
    thisSensor.data.values(bad_rows, :) = NaN;

    TODO_data.(moorName) = thisSensor;
end






%% check to see if the residuals are normally distributed

% reason: sensor noise should be normally distributed because it would be
% consistent noise from the sensor in various conditions. So, if the
% residuals are NOT normally distributed then I know that there is an issue
% with the cleaned values in which there are still spikes in the data that
% I need to account for with a tighter spiking filter.

% do this for all channels (temp, DO mgl, DO % saturation)

resid = thisSensor.data.values(:,3) - movmedian(thisSensor.data.values(:,3), 7);

figure; clf;
histogram(resid, 100)

clear thisSensor


%% plot cleaned data

figure; clf;

ax1 = subplot(2,1,1); hold(ax1, 'on');
ax2 = subplot(2,1,2); hold(ax2, 'on');

for ii = 1:length(SNs)

    fieldName = sprintf('%s', moorings{ii});

    % Extract raw values
    DO_mgl_vals = TODO_data.(fieldName).data.values(:,3);
    temp_vals = TODO_data.(fieldName).data.values(:,1);
    tstamp = TODO_data.(fieldName).data.tstamp;

    % Plot DO on top subplot
    plot(ax1, tstamp, DO_mgl_vals, 'DisplayName', moorings{ii});

    % Plot temp on bottom subplot
    plot(ax2, tstamp, temp_vals, 'DisplayName', moorings{ii});
end


% plot formatting

    axes(ax1);
        yline(2, 'k--', 'HandleVisibility', 'off');
        datetick('x');
        ylim([0 10])
        xlabel('Time'); ylabel('DO (mg/L)');
        title('Cleaned bottom dissolved oxygen data');
        legend('Location', 'best');
        axis tight
    
    
    axes(ax2);
        datetick('x');
        ylim([8 12])
        xlabel('Time'); ylabel('Temp (\circC)');
        title('Cleaned bottom temperature data');
        legend('Location', 'best');
        axis tight


%% find the location of the spikes that still persist

moorName = 'LoveJoyNorth';  % the one with the obvious spike near 07/12
d = TODO_data.(moorName).data;

% high-going spikes
[sortedVals, idx] = sort(d.values(:,3), 'descend', 'MissingPlacement', 'last');
top20 = idx(1:20);

fprintf('--- Top 20 highest DO values ---\n')
for k = 1:20
    fprintf('idx %d | time %s | DO %.2f mg/L | hampel_bad=%d | rate_bad=%d | bad_rows=%d\n', ...
        top20(k), datestr(d.tstamp(top20(k))), d.values(top20(k),3), ...
        d.hampel_bad(top20(k)), d.rate_bad(top20(k)), d.bad_rows(top20(k)));
end

% low-going spikes/dropouts -- ascending sort, ignoring NaNs
[sortedValsLow, idxLow] = sort(d.values(:,3), 'ascend', 'MissingPlacement', 'last');
bottom20 = idxLow(1:20);

fprintf('\n--- Bottom 20 lowest DO values ---\n')
for k = 1:20
    fprintf('idx %d | time %s | DO %.2f mg/L | hampel_bad=%d | rate_bad=%d | bad_rows=%d\n', ...
        bottom20(k), datestr(d.tstamp(bottom20(k))), d.values(bottom20(k),3), ...
        d.hampel_bad(bottom20(k)), d.rate_bad(bottom20(k)), d.bad_rows(bottom20(k)));
end

% Inspect surrounding window at a specific flagged index
spikeIdx = top20(1);  % change this to whichever index matches the visible spike

fprintf('\nValue at spike: %.2f\n', d.values(spikeIdx,3));
fprintf('Values in surrounding window:\n');
disp(d.values(max(1,spikeIdx-5):min(numel(d.tstamp),spikeIdx+5), 3))

%% manually remove other outliers


moorName = 'InnerNorth';
d = TODO_data.(moorName).data;

regionIdx = find(d.tstamp >= datenum(datetime(2026,6,26)) & d.tstamp <= datenum(datetime(2026,6,29)));
[~, localSortIdx] = sort(d.values(regionIdx,3), 'descend', 'MissingPlacement','last');
candidateIdx = regionIdx(localSortIdx(1:10));

for k = 1:10
    fprintf('idx %d | %s | DO %.2f\n', candidateIdx(k), datestr(d.tstamp(candidateIdx(k))), d.values(candidateIdx(k),3));
end


%% manually flag remaining spikes that survived automated filtering

% Each entry: mooring name, approximate datetime, brief reason

manualFlags = {
    'InnerNorth',   datetime(2026,6,27,14,32,0), 'single-point DO spike, visually obvious in plot';
    'InnerNorth',   datetime(2026,6,27,14,45,0), 'single-point temp spike';
    % 'InnerNorth', datetime(2026,6,27,3,50,0), 'single-point DO spike';
    % 'InnerNorth', datetime(2026,6,27,3,49,0), 'single-point DO spike';
    % 'InnerNorth', datetime(2026,6,27,3,48,0), 'single-point DO spike';
    % 'InnerNorth', datetime(2026,6,27,3,47,0), 'single-point DO spike';
    % 'InnerNorth', datetime(2026,6,27,3,46,0), 'single-point DO spike';
    % 'InnerNorth', datetime(2026,6,27,3,45,0), 'single-point DO spike';
    % 'InnerNorth', datetime(2026,6,27,3,44,0), 'single-point DO spike';
    % 'InnerNorth', datetime(2026,6,27,3,43,0), 'single-point DO spike';
    % 'InnerNorth', datetime(2026,6,27,3,42,0), 'single-point DO spike';
    % 'InnerNorth', datetime(2026,6,27,3,41,0), 'single-point DO spike';
    'InnerNorth', datetime(2026,6,27,5,51,0), 'single-point DO spike';
    'InnerNorth', datetime(2026,6,27,5,55,0), 'single-point DO spike';
    'InnerNorth', datetime(2026,6,27,5,53,0), 'single-point DO spike';
    'InnerNorth', datetime(2026,6,27,5,52,0), 'single-point DO spike';
    'InnerNorth', datetime(2026,6,27,5,54,0), 'single-point DO spike';
    % 'InnerNorth', datetime(2026,6,27,6,20,0), 'single-point DO spike';
    % 'InnerNorth', datetime(2026,6,27,6,17,0), 'single-point DO spike';
    % 'InnerNorth', datetime(2026,6,27,6,19,0), 'single-point DO spike';
    % 'InnerNorth', datetime(2026,6,27,6,18,0), 'single-point DO spike';
    % 'InnerNorth', datetime(2026,6,27,6,16,0), 'single-point DO spike';


    'InnerSouth', datetime(2026,6,27,3,50,0), 'single-point DO spike';
    'InnerSouth', datetime(2026,6,27,3,49,0), 'single-point DO spike';
    'InnerSouth', datetime(2026,6,27,3,48,0), 'single-point DO spike';
    'InnerSouth', datetime(2026,6,27,3,47,0), 'single-point DO spike';
    'InnerSouth', datetime(2026,6,27,3,46,0), 'single-point DO spike';
    'InnerSouth', datetime(2026,6,27,3,45,0), 'single-point DO spike';
    'InnerSouth', datetime(2026,6,27,3,44,0), 'single-point DO spike';
    'InnerSouth', datetime(2026,6,27,3,43,0), 'single-point DO spike';
    'InnerSouth', datetime(2026,6,27,3,42,0), 'single-point DO spike';
    'InnerSouth', datetime(2026,6,27,3,41,0), 'single-point DO spike';

    'LoveJoyNorth', datetime(2026,6,26,12,11,0),   'single-point DO spike';
    'LoveJoyNorth', datetime(2026,6,26,12,13,0),   'single-point DO spike';
    'LoveJoyNorth', datetime(2026,6,26,12,12,0),   'single-point DO spike';
    'LoveJoyNorth', datetime(2026,6,26,12,09,0),   'single-point DO spike';
    'LoveJoyNorth', datetime(2026,6,26,12,16,0),   'single-point DO spike';
    'LoveJoyNorth', datetime(2026,6,26,12,10,0),   'single-point DO spike';
    'LoveJoyNorth', datetime(2026,6,26,12,15,0),   'single-point DO spike';
    'LoveJoyNorth', datetime(2026,7,3,9,10,0),   'single-point DO dropout near 07/03';
    'LoveJoyNorth', datetime(2026,6,27,3,49,0),   'single-point DO spike';
    'LoveJoyNorth', datetime(2026,6,27,3,50,0),   'single-point DO spike';
    'LoveJoyNorth', datetime(2026,6,27,3,51,0),   'single-point DO spike';

    'LoveJoySouth', datetime(2026,6,28,11,11,0), 'single-point DO spike';
    'LoveJoySouth', datetime(2026,6,28,11,10,0), 'single-point DO spike';
    'LoveJoySouth', datetime(2026,6,28,12,7,0),  'single-point DO spike';
    'LoveJoySouth', datetime(2026,6,28,11,7,0),  'single-point DO spike';
    'LoveJoySouth', datetime(2026,6,28,12,11,0), 'single-point DO spike';
    'LoveJoySouth', datetime(2026,6,28,12,4,0),  'single-point DO spike';
    'LoveJoySouth', datetime(2026,6,28,11,49,0), 'single-point DO spike';
    'LoveJoySouth', datetime(2026,6,28,11,19,0), 'single-point DO spike';
    'LoveJoySouth', datetime(2026,6,28,11,48,0), 'single-point DO spike';
    'LoveJoySouth', datetime(2026,6,28,11,45,0), 'single-point DO spike';
};
    
    
for m = 1:length(moorings)
    n = length(TODO_data.(moorings{m}).data.tstamp);
    TODO_data.(moorings{m}).data.manual_flag = false(n,1);
end

for i = 1:size(manualFlags,1)
    moorName = manualFlags{i,1};
    targetTime = datenum(manualFlags{i,2});

    d = TODO_data.(moorName).data;

    % find nearest sample in time
    [~, idx] = min(abs(d.tstamp - targetTime));

    [minDiff, idx] = min(abs(d.tstamp - targetTime));
    if minDiff*24*60 > 2  % more than 2 minutes off
        warning('%s: nearest timestamp is %.1f min from target %s — check this one', ...
            moorName, minDiff*24*60, datestr(targetTime));
    end

    fprintf('%s: flagging idx %d (%s), DO=%.2f, Temp=%.2f\n', ...
        moorName, idx, datestr(d.tstamp(idx)), d.values(idx,3), d.values(idx,1));

    d.values(idx, :) = NaN;
    d.manual_flag(idx) = true;   % record of manual removals

    TODO_data.(moorName).data = d;
end

%% interactive cleanup with brushing - cycles through all moorings

channelsToClean = [1 3]; % column 1 = temp, column 3 = DO mg/L

for i = 1:length(moorings)
    moorName = moorings{i};
    d = TODO_data.(moorName).data;

    for c = channelsToClean

        if c == 1
            chanLabel = 'Temp';
        elseif c == 3
            chanLabel = 'DO';
        end

        figure(100); clf;
        h = plot(d.tstamp, d.values(:,c));
        datetick('x');
        title(sprintf('%s - %s : brush bad points, then press ENTER in Command Window', moorName, chanLabel));
        xlabel('Time'); ylabel(chanLabel);

        % turn on brushing mode automatically
        brush on;

        fprintf('\n=== %s - %s ===\n', moorName, chanLabel);
        fprintf('Brush the bad points on the figure, then press ENTER here to continue...\n');
        pause; % waits for you to hit Enter in the command window after brushing

        brush off;

        brushedIdx = find(get(h, 'BrushData'));

        if isempty(brushedIdx)
            fprintf('No points brushed for %s - %s, skipping.\n', moorName, chanLabel);
        else
            d.values(brushedIdx, :) = NaN;   % NaN out entire row across all channels

            if ~isfield(d, 'manual_flag')
                d.manual_flag = false(length(d.tstamp),1);
            end
            d.manual_flag(brushedIdx) = true;

            fprintf('Removed %d brushed points from %s - %s\n', numel(brushedIdx), moorName, chanLabel);
        end
    end

    TODO_data.(moorName).data = d;
end

fprintf('\nDone. Re-plot to check results.\n');
%% re-plot cleaned data

figure; clf;

ax1 = subplot(2,1,1); hold(ax1, 'on');
ax2 = subplot(2,1,2); hold(ax2, 'on');

for ii = 1:length(SNs)

    fieldName = sprintf('%s', moorings{ii});

    % Extract raw values
    DO_mgl_vals = TODO_data.(fieldName).data.values(:,3);
    temp_vals = TODO_data.(fieldName).data.values(:,1);
    tstamp = TODO_data.(fieldName).data.tstamp;

    % Plot DO on top subplot
    plot(ax1, tstamp, DO_mgl_vals, 'DisplayName', moorings{ii});

    % Plot temp on bottom subplot
    plot(ax2, tstamp, temp_vals, 'DisplayName', moorings{ii});
end


% plot formatting

    axes(ax1);
        yline(2, 'k--', 'HandleVisibility', 'off');
        datetick('x');
        ylim([0 10])
        xlabel('Time'); ylabel('DO (mg/L)');
        title('Cleaned bottom dissolved oxygen data');
        legend('Location', 'best');
        axis tight
    
    
    axes(ax2);
        datetick('x');
        ylim([8 12])
        xlabel('Time'); ylabel('Temp (\circC)');
        title('Cleaned bottom temperature data');
        legend('Location', 'best');
        axis tight


%% save out the cleaned data

save TODOdata_JunJul2026_L3.mat TODO_data