% Reading in and cleaning moored concerto data 

% Maia H. July 2026


clear all, close all

%% load in the rsk files

% not including the WW data because I am going to read those in with the
% cast processing script

SNs = {'066057', '209886'}; % Wire walker serial #s not included here: 241790 (WWN), 241788 (WWS)
moorings = {'LoveJoyNorth', 'InnerSouth'}; % these match the order of the serial numbers
months = 'JulAug2026'; % edit this based on the data you are downloading

concerto_data = struct(); % create an empty struct that I will read data into

for i = 1:length(SNs)

    % setting the folder path first with the understanding that there is a
    % depth component to the name that changes, so I will parse that with
    % the * wild card symbol.

    folderPath = fullfile(sprintf('%s_%s', moorings{i}, months), 'RBR_concerto'); % file path from the high-level data directory
    filePattern = sprintf('%s_%s_*_sn%s.rsk', moorings{i}, months, SNs{i}); % naming pattern

    fileInfo = dir(fullfile(folderPath, filePattern));  

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
    concerto_data.(fieldName) = RSKreaddata(RSKopen(fullFileName));

end



%% cut the timestamps to the section we are interested in for each month

% trim the timestamps
    % for junjul
        % startTime = datetime(2026, 6, 26, 0, 0, 0);
        % endTime   = datetime(2026, 7, 21, 16, 30, 0);

    % for May to June
        % startTime = datetime(2026, 5, 27, 0, 0, 0);
        % endTime = datetime(2026, 6, 23, 20, 40, 0);
        % startTime_dn = datenum(startTime);
        % endTime_dn   = datenum(endTime);

   % for July to August


       startTime = datetime(2026, 7, 25, 12, 0, 0);
       endTime = datetime(2026, 8, 25, 12, 0, 0);
       startTime_dn = datenum(startTime);
       endTime_dn   = datenum(endTime);

for i = 1:length(moorings)
    moorName  = moorings{i};
    thisSensor = concerto_data.(moorName);

    % Remove data points outside the specified time range
    validIndices = thisSensor.data.tstamp >= startTime_dn & thisSensor.data.tstamp <= endTime_dn;
    thisSensor.data.values = thisSensor.data.values(validIndices, :);
    thisSensor.data.tstamp = thisSensor.data.tstamp(validIndices);

    concerto_data.(moorName) = thisSensor;
end
%% plot the data

% relevant channel numbers for LoveJoy North (there are others-- maybe look at turbidity):
    % temperature: 2
    % pressure: 3
    % depth: 8
    % salinity: 9

% relevant channel numbers for Inner South (there are others-- maybe look at turbidity):
    % temperature: 2
    % pressure: 3
    % depth: 7
    % salinity: 8
    % do : 11 (% saturation)

figure(1); clf;

ax1 = subplot(3,1,1); hold(ax1, 'on');
ax2 = subplot(3,1,2); hold(ax2, 'on');
ax3 = subplot(3,1,3); hold(ax3, 'on');

% -- use this for when you only have the LJN sensor (inner south added for
    % Jul to Aug deployment) ---------
        % for ii = 1:length(SNs)
        % 
        %     fieldName = sprintf('%s', moorings{ii});
        % 
        %     % Extract raw values
        %     temp_vals = concerto_data.(fieldName).data.values(:,2);
        %     sal_vals = concerto_data.(fieldName).data.values(:,9);
        %     tstamp = concerto_data.(fieldName).data.tstamp;
        % 
        %     % Plot DO on top subplot
        %     plot(ax1, tstamp, sal_vals, 'DisplayName', moorings{ii});
        % 
        %     % Plot temp on bottom subplot
        %     plot(ax2, tstamp, temp_vals, 'DisplayName', moorings{ii});
        % end
% --------------------

% otherwise use this to plot them both 


    % Plot salinity on top subplot
    plot(ax1, concerto_data.LoveJoyNorth.data.tstamp, concerto_data.LoveJoyNorth.data.values(:,9), '-r','DisplayName', 'LoveJoy north');
        hold on
    plot(ax1, concerto_data.InnerSouth.data.tstamp, concerto_data.InnerSouth.data.values(:,8), '-b','DisplayName', 'Inner south');
        hold off

    
    % Plot temp on bottom subplot
    plot(ax2, concerto_data.LoveJoyNorth.data.tstamp, concerto_data.LoveJoyNorth.data.values(:,2), '-r','DisplayName', 'LoveJoy north');
        hold on 
    plot(ax2, concerto_data.InnerSouth.data.tstamp, concerto_data.InnerSouth.data.values(:,2), '-b','DisplayName', 'Inner south');
        hold off

    % add a third subplot for hte DO data from inner south concerto
 
    plot(ax3, concerto_data.InnerSouth.data.tstamp, concerto_data.InnerSouth.data.values(:,11), '-b','DisplayName', 'Inner south');
    hold on
    yline(30, '--k', 'HandleVisibility', 'off')



% plot formatting

    axes(ax1);
        datetick('x');
        ylim([25 30])
        xlabel('Time'); ylabel('Salinity (PSU)');
        title('Raw bottom salinity data');
        legend('Location', 'best');
        grid on;
        axis tight;
    
    
    axes(ax2);
        datetick('x');
        ylim([8 12])
        xlabel('Time'); ylabel('Temp (\circC)');
        title('Raw bottom temperature data');
        legend('Location', 'best');
        grid on;
        axis tight;



    axes(ax3);
        datetick('x');
        %ylim([0 12])
        xlabel('Time'); ylabel('DO (% saturation)');
        title('Raw bottom dissolved oxygen data');
        legend('Location', 'best');
        grid on;
        axis tight;

 linkaxes([ax1 ax2 ax3], 'x')


 % --- save the figure to github ---

 outDir = '/Users/heffem3/Documents/GitHub/PennCove_codes/Figures/JulAug2026/RawData_plots';

 % make sure the directory exists; create it if not
 if ~exist(outDir, 'dir')
     mkdir(outDir);
 end

figName = sprintf('BottomConcerto_timeseries_JulAug2026.png'); 
outFile = fullfile(outDir, figName);

exportgraphics(figure(1), outFile, 'Resolution', 300);


 

%% save the raw data

raw_values = concerto_data;

save mooredConcertoData_JulAug_2026_raw.mat concerto_data

%% clean the data 

concerto_data = raw_values;  

% starting with the Ruskin despike function

channel_name_list = {'Conductivity', 'Temperature', 'Pressure', 'Backscatter1', ...
    'Backscatter2', 'Backscatter3', 'Sea Pressure', 'Depth', 'Salinity', ...
    'Speed of Sound', 'Specific conductivity'};

for j = 1:length(SNs)
    fieldName = sprintf('%s', moorings{j});
    rsk = concerto_data.(fieldName);   % start from this mooring's data

    for i = 1:length(channel_name_list)
        [rsk, spike] = RSKdespike(rsk, 'channel', channel_name_list{i}, ...
            'threshold', 1, 'windowLength', 11, 'action', 'nan'); % each sample point is every 2 minutes, so this looks at hte surroudning 22 minutes of data. This seems like a robust amount of time to compare for spiking.
        fprintf('%s - %s: %d spikes flagged\n', fieldName, channel_name_list{i}, length(spike));
    end

    concerto_data.(fieldName) = rsk;   % write the fully despiked rsk back
end
%% plot cleaned data


figure(2); clf;

ax3 = subplot(2,1,1); hold(ax3, 'on');
ax4 = subplot(2,1,2); hold(ax4, 'on');

for ii = 1:length(SNs)

    fieldName = sprintf('%s', moorings{ii});

    % Extract raw values

    temp_vals = concerto_data.(fieldName).data.values(:,2);
    sal_vals = concerto_data.(fieldName).data.values(:,9);
    tstamp = concerto_data.(fieldName).data.tstamp;

    % Plot DO on top subplot
    plot(ax3, tstamp, sal_vals, 'DisplayName', moorings{ii});

    % Plot temp on bottom subplot
    plot(ax4, tstamp, temp_vals, 'DisplayName', moorings{ii});
end


% plot formatting

    axes(ax3);
        datetick('x');
        ylim([25 30])
        xlabel('Time'); ylabel('Salinity (PSU)');
        title('Cleaned bottom salinity data');
        legend('Location', 'best');
        grid on;
        axis tight;
    
    
    axes(ax4);
        datetick('x');
        ylim([8 12])
        xlabel('Time'); ylabel('Temp (\circC)');
        title('Cleaned bottom temperature data');
        legend('Location', 'best');
        grid on;
        axis tight;

 linkaxes([ax3 ax4], 'x')
%% interactive cleanup with brushing - cycles through all moorings

channelsToClean = [2 9]; % column 2 = temp, column 9 = salinity PSU

for i = 1:length(moorings)
    moorName = moorings{i};
    d = concerto_data.(moorName).data;

    for c = channelsToClean

        if c == 2
            chanLabel = 'Temp';
        elseif c == 9
            chanLabel = 'Salinity';
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

    concerto_data.(moorName).data = d;
end

fprintf('\nDone. Re-plot to check results.\n');
 %% save out the cleaned data

 save("CleanedData/mooredConcertoData_MayJun2026_L2.mat", "concerto_data")