%%% reading in the RBR Solo T data and doing some initial plotting %%%

%%% Created by Maia, April 2026

% last modified: June 26, 2026, Maia
%   Modifications include putting in code to specify the mooring and the
%   depth of each of the serial numbers and plotting the data per mooring

close all; clear all;


%% load in the data

% === make sure you are  in the higher-up DATA directory for the month oyu
% want ====

moorings = {'LoveJoyNorth', 'LoveJoySouth', 'InnerNorth', 'InnerSouth'};
solo_SNs = { ...
    {'212861', '212864', '212865', '212866', '212863', '212867', '212862'}, ...  % LoveJoyNorth
    {'212833', '212834', '212857', '212858', '212859', '212860', '212832'}, ...  % LoveJoySouth
    {'212868', '212869', '212870', '212871', '212872', '212873', '212874'}, ...  % InnerNorth
    {'212875', '212876', '212877', '212878', '212879', '212880', '212881'} ...   % InnerSouth
    };
months_dir  = 'JunJul2026';  % used for the DIRECTORY name (includes year)

soloT_data = struct();  % top-level struct; one field per mooring

for i = 1:length(moorings)
    SNs_thisMooring = solo_SNs{i};
    moorName = moorings{i};

    soloT_data.(moorName) = struct();  % sub-struct for this mooring

    for j = 1:length(SNs_thisMooring)
        sn = SNs_thisMooring{j};
        folderPath = fullfile(sprintf('%s_%s', moorName, months_dir), 'RBR_soloT');
        filePattern = sprintf('%s_%s_*_sn%s.rsk', moorName, months_dir, sn);
        fileInfo = dir(fullfile(folderPath, filePattern));

        if isempty(fileInfo)
            warning('No file found for %s (SN %s) — check path/pattern.', moorName, sn);
            continue
        elseif length(fileInfo) > 1
            warning('Multiple matches for %s (SN %s); using the first one.', moorName, sn);
        end

        fullFileName = fullfile(fileInfo(1).folder, fileInfo(1).name);
        fprintf('Opening: %s (%.1f KB)\n', fullFileName, fileInfo(1).bytes/1024);

        if fileInfo(1).bytes < 10000
            warning('File looks suspiciously small — likely a Google Drive placeholder, not fully synced.');
        end

        fieldName = sprintf('sn%s', sn);  % just the SN now, since mooring is already the outer struct
        soloT_data.(moorName).(fieldName) = RSKreaddata(RSKopen(fullFileName));
    end
end

%% plot a time series of the data with different colors 

% ===== put in the start and end times =====

startTime = datetime(2026, 6, 25, 19, 0, 0);
endTime = datetime(2026, 7, 21, 16, 30, 0);

startTime_dn =datenum(startTime);
endTime_dn =datenum(endTime);

moorings = {'LoveJoyNorth', 'LoveJoySouth', 'InnerNorth', 'InnerSouth'};

figure;
ax = gobjects(length(moorings), 1);

for i = 1:length(moorings)
    moorName = moorings{i};
    ax(i) = subplot(length(moorings), 1, i);
    hold on

    snFields = fieldnames(soloT_data.(moorName));

    for j = 1:length(snFields)
        sn = snFields{j};
        thisSensor = soloT_data.(moorName).(sn);

        t = datetime(thisSensor.data.tstamp, 'ConvertFrom', 'datenum');  % convert datenum -> datetime
        plot(t, thisSensor.data.values, 'DisplayName', sn);
    end

    title(moorName, 'Interpreter', 'none');
    ylabel('Temp (\circC)');
    legend('show', 'Location', 'eastoutside');
    grid on
end

xlabel('Time');
linkaxes(ax, 'xy');

xlim(ax(1), [startTime endTime]);

%% plot histograms of the data to see the distribution

figure;
ax = gobjects(length(moorings), 1);

for i = 1:length(moorings)
    moorName = moorings{i};
    ax(i) = subplot(length(moorings), 1, i);
    hold on

    snFields = fieldnames(soloT_data.(moorName));

    for j = 1:length(snFields)
        sn = snFields{j};
        thisSensor = soloT_data.(moorName).(sn);

        
        histogram(thisSensor.data.values, 'DisplayName', sn);
    end

    title(moorName, 'Interpreter', 'none');
    xlabel('Temp (\circC)');
    legend('show', 'Location', 'eastoutside');
    grid on
end

linkaxes(ax, 'xy');

%% save the raw data

save InnerSouth_JunJul2026_soloT_raw.mat soloT_data

%% remove the data points before startTime and after endTime

for i = 1:length(moorings)
    moorName = moorings{i};
    snFields = fieldnames(soloT_data.(moorName));
    
    for j = 1:length(snFields)
        sn = snFields{j};
        thisSensor = soloT_data.(moorName).(sn);
        
        % Remove data points outside the specified time range
        validIndices = thisSensor.data.tstamp >= startTime_dn & thisSensor.data.tstamp <= endTime_dn;
        thisSensor.data.values = thisSensor.data.values(validIndices);
        thisSensor.data.tstamp = thisSensor.data.tstamp(validIndices);
        
        soloT_data.(moorName).(sn) = thisSensor;  % Update the struct with filtered data
    end
end


%% clean the temperature data by de-spiking with 

% Apply a de-spiking algorithm to the temperature data
for i = 1:length(moorings)
    moorName = moorings{i};
    snFields = fieldnames(soloT_data.(moorName));
    
    for j = 1:length(snFields)
        sn = snFields{j};
        thisSensor = soloT_data.(moorName).(sn);
        
        % De-spike the temperature values
        thisSensor.data.values = despike(thisSensor.data.values);
        soloT_data.(moorName).(sn) = thisSensor;  % Update the struct with cleaned data
    end
end