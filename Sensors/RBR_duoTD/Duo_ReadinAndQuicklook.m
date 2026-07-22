%%% reading in the RBR Duo data and doing some initial plotting %%%

%%% Maia, April 2026

close all; clear all;

%% load in the data

% ==== make sur eyou are in the 'Data' directory that is higher up ===

SNs = {'240149', '240150', '240151'};
moorings = {'InnerNorth', 'InnerNorth', 'InnerSouth'}; % these match the order of the serial numbers
months_dir = 'MaytoJun2026'; % edit this based on the data you are downloading
months_file = 'MayJun2026';

DuoTD_data = struct(); % create an empty struct that I will read data into

for i = 1:length(SNs)

    % setting the folder path first with the understanding that there is a
    % depth component to the name that changes, so I will parse that with
    % the * wild card symbol.

    folderPath = fullfile(sprintf('%s_%s', moorings{i}, months_dir), 'RBR_DuoTD'); % file path from the high-level data directory
    filePattern = sprintf('%s_%s_*_sn%s.rsk', moorings{i}, months_file, SNs{i}); % naming pattern

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


    fieldName = sprintf('DuoTD_data_%s_%s_%s', moorings{i}, months_file, SNs{i});
    DuoTD_data.(fieldName) = RSKreaddata(RSKopen(fullFileName));

end


%% plot a time series of the data with different colors 

struct_names = {'DuoTD_data_InnerNorth_MayJun2026_240149', 'DuoTD_data_InnerNorth_MayJun2026_240150', 'DuoTD_data_InnerSouth_MayJun2026_240151'};

startTime = datetime(2026, 5, 27, 0, 0, 0);
endTime = datetime(2026, 6, 23, 20, 40, 0);


% ===== first temperature =====

figure; hold on;

for i = 1:3
    d = DuoTD_data.(struct_names{i}).data;   % go into struct inside each cell
    
     t = datetime(d.tstamp, 'ConvertFrom', 'datenum');


    idx = t >= startTime & t <= endTime;   % logical mask for time bounds
    plot(t(idx), d.values(idx,1));          % plotting only temp within bounds

    axis tight
end

hold off;
legend('Inner North 240149','Inner North, 240150','Inner South, 240151');
xlabel('Time');
ylabel('Temperature (°C)');
title('Time series of temperature from May to June 2026');


% ===== then pressure ====

figure(2); hold on;

for i = 1:3
    d = DuoTD_data.(struct_names{i}).data;   % go into struct inside each cell
    
     t = datetime(d.tstamp, 'ConvertFrom', 'datenum');

    idx = t >= startTime & t <= endTime;   % logical mask for time bounds
    plot(t(idx), d.values(idx,2));          % plotting only pressure within bounds

    axis tight
end

hold off;
legend('SN 240149','SN 240150','SN 240151');
xlabel('Time');
ylabel('dbar');
title('Time series of pressure from May to June 2026');

%% clean the data by de-spiking with a hampel loop

struct_names = {'DuoTD_data_InnerNorth_MayJun2026_240149', ...
                'DuoTD_data_InnerNorth_MayJun2026_240150', ...
                'DuoTD_data_InnerSouth_MayJun2026_240151'};

outputFolder = pwd;  

for i = 1:3
    % pull out the data structure 
    d = DuoTD_data.(struct_names{i}).data;

    % convert timestamps to datetime
    t = datetime(d.tstamp, 'ConvertFrom', 'datenum');

    % ----- despike temperature  -----
    temp_raw = d.values(:,1);
    temp_clean = hampel(temp_raw, 7, 2);   % window = 7, threshold = 2 std devs

    % ----- despike pressure -----
    pres_raw = d.values(:,2);
    pres_clean = hampel(pres_raw, 5, 2);  

    % build a cleaned copy of the data structure
    d_clean = d;                       % start with original fields (tstamp, values)
    d_clean.values(:,1) = temp_clean;   % overwrite temp column with cleaned version
    d_clean.values(:,2) = pres_clean;   % overwrite pressure column with cleaned version
    d_clean.temp_raw = temp_raw;        % keep raw temp, just in case
    d_clean.pres_raw = pres_raw;        % keep raw pressure, just in case

    % ----- before/after temperature -----
    figure;
    plot(t, temp_raw, 'Color', [0.7 0.7 0.7]); hold on;
    plot(t, temp_clean, 'b', 'LineWidth', 1.2);
    hold off;
    axis tight
    legend('Raw','Despiked');
    xlabel('Time');
    ylabel('Temperature');
    title(struct_names{i}, 'Interpreter', 'none');

    % ----- before/after pressure -----
    figure;
    plot(t, pres_raw, 'Color', [0.7 0.7 0.7]); hold on;
    plot(t, pres_clean, 'r', 'LineWidth', 1.2);
    hold off;
    axis tight
    legend('Raw','Despiked');
    xlabel('Time');
    ylabel('Pressure (dbar)');
    title(struct_names{i}, 'Interpreter', 'none');

    % save out to its own .mat file
    outFile = fullfile(outputFolder, [struct_names{i} '_cleaned_L2.mat']);
    save(outFile, 'd_clean');

    fprintf('Saved cleaned data for %s to %s\n', struct_names{i}, outFile);
end