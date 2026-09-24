%%% SWIFT battery check and rough daily drawdown %%%

% Maia Heffernan, Sept. 21 2026



%%% STEPS
% 1) check SWIFT telemetry for entire month of september
% 2) pull in all the SWIFTS
% 3) pull out most recent voltage from each SWIFT
% 4) average voltage per day (24 hour average)
% 5) report out the values

clear, close

%% load in the telemetry data

swift09 = load('/Users/heffem3/Desktop/M2O2/SWIFTs/TelemetryChecks/Sep21check/SWIFT09_telemetry.mat');

swift18 = load('/Users/heffem3/Desktop/M2O2/SWIFTs/TelemetryChecks/Sep21check/SWIFT18_telemetry.mat');

swift26 = load('/Users/heffem3/Desktop/M2O2/SWIFTs/TelemetryChecks/Sep21check/SWIFT26_telemetry.mat');

swift27 = load('/Users/heffem3/Desktop/M2O2/SWIFTs/TelemetryChecks/Sep21check/SWIFT27_telemetry.mat');

swift28 = load('/Users/heffem3/Desktop/M2O2/SWIFTs/TelemetryChecks/Sep21check/SWIFT28_telemetry.mat');

swift29 = load('/Users/heffem3/Desktop/M2O2/SWIFTs/TelemetryChecks/Sep21check/SWIFT29_telemetry.mat');

%% plot the battery voltages


swiftid = {'09', '18', '26', '27', '28', '29'};

for i = 1:length(swiftid)
    swiftData = eval(['swift' swiftid{i}]);
    dataFields = fieldnames(swiftData);
    battery = swiftData.(dataFields{1});
    swiftstruct = swiftData.(dataFields{2});
    plot([swiftstruct.time], battery(:), 'DisplayName', ['SWIFT ' swiftid{i}]);
    hold on
    datetick
    legend
end



%% pull out most recent battery voltage


% put the recent volatges in a table with the swift ID headers

% recentVoltage = nan(1, numel(swiftid));

for ii = 1:length(swiftid)
    swiftData = eval(['swift' swiftid{ii}]);
    dataFields = fieldnames(swiftData);
    battery = swiftData.(dataFields{1});
    swiftstruct = swiftData.(dataFields{2});
    recentVoltage(ii) = battery(end);

end


recentVoltageTable = table(string(swiftid(:)), recentVoltage(:), ...
    'VariableNames', {'Swift','Most_recent_voltage'});


% 
% 
% 
% 
% recentVoltageTable = array2table(recentVoltage, ...
%     'VariableNames', matlab.lang.makeValidName("SWIFT_" + swiftid));
% recentVoltageTable.Properties.RowNames = {'MostRecentVoltage'};



%% make a 24 hour average of the voltages



nSwift = length(swiftid);
dailyMean = cell(nSwift,1);   % per-swift results
dailyDays = cell(nSwift,1);

for iii = 1:nSwift
    swiftData   = eval(['swift' swiftid{iii}]);
    dataFields  = fieldnames(swiftData);
    battery     = swiftData.(dataFields{1});
    swiftstruct = swiftData.(dataFields{2});

    time    = [swiftstruct.time];
    time    = time(:);
    battery = battery(:);

    % (optional) drop samples that follow a gap > 1 hr; time is in datenum days
    valid = [true; diff(time) <= 1/24];
    time    = time(valid);
    battery = battery(valid);

    % assign each sample to its calendar day
    t = datetime(time, 'ConvertFrom', 'datenum');
    day = dateshift(t, 'start', 'day');

    % average battery within each day
    [uniqueDays, ~, idx] = unique(day);
    dailyMean{iii} = accumarray(idx, battery, [], @mean);
    dailyDays{iii} = uniqueDays;

    dailyMax{iii} = accumarray(idx, battery, [], @max);
    dailyMin{iii} = accumarray(idx, battery, [], @min);
end

% put all 6 swifts on one common daily time axis
allDays = unique(vertcat(dailyDays{:}));
dailyVoltage = NaN(numel(allDays), nSwift);

for iii = 1:nSwift
    [~, loc] = ismember(dailyDays{iii}, allDays);
    dailyVoltage(loc, iii) = dailyMean{iii};
end

% build the daily maxs and mins
dailyMaxV = NaN(numel(allDays), nSwift);
dailyMinV = NaN(numel(allDays), nSwift);

for iii = 1:nSwift
    [~, loc] = ismember(dailyDays{iii}, allDays);
    dailyMaxV(loc, iii) = dailyMax{iii};
    dailyMinV(loc, iii) = dailyMin{iii};
end

%% plot the daily average voltage 


figure
plot(allDays, dailyVoltage, '.-')
legend(swiftid)
ylabel('Daily mean battery voltage')


%% find the daily mean % Option 1: mean of day-to-day differences
dV = diff(dailyVoltage);                    % negative = decrease
avgChange = mean(dV, 1, 'omitnan');         % V/day

% Option 2: linear fit
nSwift = size(dailyVoltage, 2);
slopePerDay = NaN(1, nSwift);
dayNum = days(allDays - allDays(1));

for iii = 1:nSwift
    ok = ~isnan(dailyVoltage(:,iii));
    p = polyfit(dayNum(ok), dailyVoltage(ok,iii), 1);
    slopePerDay(iii) = p(1);                % V/day, negative = decreasing
end

% Option 3: discharge days only
dVdis = dV;
dVdis(dVdis > 0) = NaN;                     % ignore days where voltage rose
avgDischarge = mean(dVdis, 1, 'omitnan');   % negative values


dailyDraw = dailyMaxV - dailyMinV;              % V lost within each day
avgDailyDrawdown = mean(dailyDraw, 1, 'omitnan');   % 1 x 6, positive = loss



daily_drawdown_results = table(string(swiftid(:)), avgChange(:), slopePerDay(:), avgDailyDrawdown(:), ...
    'VariableNames', {'Swift','MeanDiff_V_per_day','Slope_V_per_day', 'Average_daily_drawdown_V_not_including_charging'});




%% calcualte the average daily recovery of battery 

% recovery from today's min to the next day's max
dailyRecover = dailyMaxV(2:end,:) - dailyMinV(1:end-1,:);
avgDailyRecovery = mean(dailyRecover, 1, 'omitnan');

% net daily balance
netDailyBalance = avgDailyRecovery - avgDailyDrawdown;


%% how many days were used to calculat each average

nValidDays = sum(~isnan(dailyDraw), 1);   % count per mooring
%% make a table of the results

final_results = table(string(swiftid(:)), slopePerDay(:), avgDailyDrawdown(:), ...
    avgDailyRecovery(:), netDailyBalance(:), nValidDays(:), recentVoltage(:), ...
    'VariableNames', {'Swift','Slope_V_per_day','AvgDrawdown_V', ...
    'AvgRecovery_V','NetBalance_V','N_days_averaged', 'Most_recent_voltage'})


%% make this an xlsx table

writetable(final_results, 'swift_September_battery_summary.xlsx')



%%

% does the daily max itself trend down?
maxTrend = NaN(1,nSwift);
for iii = 1:nSwift
    ok = ~isnan(dailyMaxV(:,iii));
    p = polyfit(dayNum(ok), dailyMaxV(ok,iii), 1);
    maxTrend(iii) = p(1);
end
%% plot the averages on top of the daily values 

% daily values should be grayed out



