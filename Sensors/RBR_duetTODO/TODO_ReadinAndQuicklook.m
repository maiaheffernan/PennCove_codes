%%% Reading in RBR T.ODO data and quick look plots %%%

%%% Maia Heffernan, April 2026

% You will need the RSKtools toolbox for this script 

clear all; close all;


% Add rsktools folder to path if you need to: 
addpath('/Users/heffem3/Documents/MATLAB/rbr-rsktools-7a76410a599a')

%% load in the data 

SN_endings = {'87', '88', '89', '90', '91', '92'};
%ending_numbers = {'1446', '1445', '1447', '1449', '1449', '1448'};

for i = 1:length(SN_endings)
    fileName = sprintf('Robertson_TODO2417%s_23May2026.rsk', SN_endings{i});
    TODO_data{i} = RSKreaddata(RSKopen(fileName));
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