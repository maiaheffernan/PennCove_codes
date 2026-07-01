%%% Reading in RBR T.ODO data and quick look plots %%%

%%% Maia Heffernan, April 2026

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




SNs = {'241787', '241789', '241791', '241792'}; % Wire walker serial #s not included here: 241790, 241788
moorings = {'LoveJoyNorth', 'LoveJoySouth', 'InnerNorth', 'InnerSouth'}; % these match the order of the serial numbers
months = 'MaytoJun2026'; % edit this based on the data you are downloading

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


    fieldName = sprintf('TODO_data_%s_%s', moorings{i}, months);
    TODO_data.(fieldName) = RSKreaddata(RSKopen(fullFileName));

end

%% pull out the values, cut to the start and end times, and plot

% ---- Pair indices referencing TODO_data positions ----
% pairIndices = [1 2; 3 4; 5 6];

% ---- Labels for the legend ----
sensorNames = {'SN241787', 'SN241788', 'SN241789', 'SN241790', 'SN241791', 'SN241792'};

% ---- Start and end times for sampling ----

startTime = datetime(2026,05,01,19,10,00);
endTime = datetime(2026,05,01,21,40,00);


%% ---------- plot the sensors --------------

% Colors for each sensor
pairColors = lines(length(sensorNames));

figure;
ax1 = subplot(2,1,1); hold(ax1, 'on'); ylabel(ax1, 'Temperature (°C)'); grid(ax1, 'on');
ax2 = subplot(2,1,2); hold(ax2, 'on'); ylabel(ax2, 'DO (mg/L)');         grid(ax2, 'on');
xlabel(ax2, 'Time');

for i = 1:length(sensorNames)
    % Extract and convert timestamps
    tstamp = datetime(TODO_data{i}.data.tstamp, 'ConvertFrom', 'datenum');
    vals   = TODO_data{i}.data.values;

    temp   = vals(:, 1);              % Temperature (°C)
    DO_mgl = vals(:, 2) * 0.031998;  % DO: µmol/L -> mg/L
    DO_umolperkilo = vals(:, 2);

    % Apply time mask
    mask       = (tstamp >= startTime) & (tstamp <= endTime);
    tstamp_f   = tstamp(mask);
    temp_f     = temp(mask);
    DO_f       = DO_mgl(mask);
    DO_umol_f = DO_umolperkilo(mask);

    % Plot
    plot(ax1, tstamp_f, temp_f, 'Color', pairColors(i,:), 'DisplayName', sensorNames{i});
    plot(ax2, tstamp_f, DO_umol_f,   'Color', pairColors(i,:), 'DisplayName', sensorNames{i}); % or just do mg/L
end

legend(ax1, 'Location', 'best');
legend(ax2, 'Location', 'best');
linkaxes([ax1, ax2], 'x'); 



%% If doing multiple rounds comparing the same two sensors


% startTimes = [
%     datetime(2026,04,08,17,49,40),  datetime(2026,04,08,17,52,10),  datetime(2026,04,08,17,54,40);   % Round 1
%     datetime(2026,04,08,17,59,20),  datetime(2026,04,08,18,01,35),  datetime(2026,04,08,18,03,55);   % Round 2
%     datetime(2026,04,08,18,08,30),  datetime(2026,04,08,18,10,45),  datetime(2026,04,08,18,13,00);   % Round 3
% ];
% 
% endTimes = [
%     datetime(2026,04,08,17,51,40),  datetime(2026,04,08,17,54,10),  datetime(2026,04,08,17,56,40);   % Round 1
%     datetime(2026,04,08,18,01,20),  datetime(2026,04,08,18,03,35),  datetime(2026,04,08,18,05,55);   % Round 2
%     datetime(2026,04,08,18,10,30),  datetime(2026,04,08,18,12,45),  datetime(2026,04,08,18,15,00);   % Round 3
% ];

% ---- Colors for each sensor in a pair ----
% pairColors = lines(2);
% 
% numRounds = 3;
% numPairs  = 3;
% 
% for r = 1:numRounds
%     figure;
%     sgtitle(sprintf('Round %d', r));
% 
%     for p = 1:numPairs
%         startTime = startTimes(r, p);
%         endTime   = endTimes(r, p);
% 
%         ax1 = subplot(numPairs, 2, (p-1)*2 + 1); hold on;
%         ax2 = subplot(numPairs, 2, (p-1)*2 + 2); hold on;
% 
%         for s = 1:2
%             idx        = pairIndices(p, s);   % direct index into TODO_data
%             sensorName = sensorNames{idx};
% 
%             % Pull and convert tstamp
%             tstamp = TODO_data{idx}.data.tstamp;
%             tstamp = datetime(tstamp, 'ConvertFrom', 'datenum');
%             vals   = TODO_data{idx}.data.values;
% 
%             temp = vals(:, 1);   % Temperature (°C)
%             DO   = vals(:, 2);   % DO (µmol/L)
% 
%             DO_mgl = DO * 0.031998; % convert DO from µmol/L to mg/L
% 
%             % Apply time mask
%             mask        = (tstamp >= startTime) & (tstamp <= endTime);
%             tstamp_filt = tstamp(mask);
%             temp_filt   = temp(mask);
%             DO_filt     = DO_mgl(mask);
% 
%             % Plot
%             plot(ax1, tstamp_filt, temp_filt, 'Color', pairColors(s,:), 'DisplayName', sensorName);
%             plot(ax2, tstamp_filt, DO_filt,   'Color', pairColors(s,:), 'DisplayName', sensorName);
%         end
% 
%         % Formatting
%         title(ax1, sprintf('Pair %d - Temp', p));
%         title(ax2, sprintf('Pair %d - DO', p));
%         ylabel(ax1, 'Temperature (°C)');
%         ylabel(ax2, 'DO (mg/L)');
%         xlabel(ax1, 'Time');
%         xlabel(ax2, 'Time');
%         legend(ax1, 'Location', 'best');
%         legend(ax2, 'Location', 'best');
%         linkaxes([ax1 ax2], 'x');
%         grid(ax1, 'on');
%         grid(ax2, 'on');
%     end
%     saveas(gcf, sprintf('Round%d_plots.png', r));
% end