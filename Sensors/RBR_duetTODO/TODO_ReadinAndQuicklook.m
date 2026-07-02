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

%% convert the DO values to mg/L from umol/L

% conversion: DO value (umol/L) * 0.031998 = DO value (mg/L)

% Convert DO values to mg/L for each sensor in the TODO_data struct
for i = 1:length(SNs)
    fieldName = sprintf('TODO_data_%s_%s', moorings{i}, months);
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

    fieldName = sprintf('TODO_data_%s_%s', moorings{ii}, months);

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



