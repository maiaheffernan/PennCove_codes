%%% Applying a Godin filter to the bottom DO data to see general trends

% Maia, September 7 2026

clear all, close all

%% load in the bottom DO data

% May to June

MayJun = load('TODOdata_MayJun2026_L3.mat');

% June to July

JunJul = load('TODOdata_JunJul2026_L3.mat');

% July to August

JulAug = load('TODOdata_JulAug2026_L3.mat');

%% pull out the different monthly data and timestamps and apply a godin filter


months = {'MayJun', 'JunJul', 'JulAug'};
moorings = {'LoveJoyNorth', 'LoveJoySouth', 'InnerNorth', 'InnerSouth'};

for i = 1:length(months)
    for ii = 1:length(moorings)

    % Extract data and timestamps for the current month and mooring
        currentMonthData = eval(months{i});
        %thisMooring = currentMonthData.moorings{ii};
        currentTime = currentMonthData.TODO_data.(moorings{ii}).data.tstamp;
        currentValues = currentMonthData.TODO_data.(moorings{ii}).data.values;

    % Apply the Godin filter to the current month's data
    [filteredTime, filteredValues] = godin_filter(datetime(currentTime, 'ConvertFrom', 'datenum'), currentValues);

    % Store the filtered values for the current mooring and month
    results.(months{i}).(moorings{ii}) = table(filteredTime, filteredValues);
    end
end

%% Plot it all together

months = {'MayJun', 'JunJul', 'JulAug'};
moorings = {'LoveJoyNorth', 'LoveJoySouth', 'InnerNorth', 'InnerSouth'};
colors = lines(length(months));

figure;
for ii = 1:length(moorings)
    subplot(length(moorings), 1, ii);
    hold on;
    for i = 1:length(months)
        data = results.(months{i}).(moorings{ii});
        DO = data.filteredValues(:,3);   % third column = DO, mg/L
        plot(data.filteredTime, DO, ...
            'Color', colors(i,:), 'DisplayName', months{i});
    end
    hold off;
    title(moorings{ii}, 'Interpreter', 'none');
    ylabel('DO (mg/L)');
    legend('show');
    grid on;
end
xlabel('Time');
sgtitle('Godin-filtered DO concentration by mooring and month');

%% pull out just the first month (May to June) and plot it with the tide


% Extract the first month's data for plotting with tide
firstMonth = 'MayJun';
tideData = load('DuoTD_data_InnerNorth_MaytoJun2026_240150_cleaned_L2.mat'); % Load tide data
tideTime = datetime(tideData.d_clean.tstamp, 'ConvertFrom', 'datenum'); % Assuming tide data has a time field
presValues = tideData.d_clean.values(:,3); % channel 3 is sea pressure
tideValues = presValues - mean(presValues, 'omitnan');


% --- Tide subplot (plot once) ---
s1 = subplot(2,1,1);
plot(tideTime, tideValues, 'DisplayName', 'Tide', 'Color', 'r');
ylabel('SSH (m)');
title(['DO and Tide for ', firstMonth], 'Interpreter', 'none');


% --- DO subplot (loop over moorings) ---
s2 = subplot(2,1,2);
hold on
for iii = 1:length(moorings)
    data = results.(firstMonth).(moorings{iii});
    DO = data.filteredValues(:,3);
    plot(data.filteredTime, DO, 'DisplayName', moorings{iii});
end
hold off
xlabel('Time');
ylabel('DO concentration [mg/L]');
legend show;
grid off;

linkaxes([s1 s2], 'x');

clear tideTime tideData presValues tideValues


%% June to July

% Extract the first month's data for plotting with tide
secondMonth = 'JunJul';
tideData = load('DuoTD_data_InnerNorth_JunJul2026_240150_cleaned_L2.mat'); % Load tide data
tideTime = datetime(tideData.d_clean.tstamp, 'ConvertFrom', 'datenum'); % Assuming tide data has a time field
presValues = tideData.d_clean.values(:,3); % channel 3 is sea pressure
tideValues = presValues - mean(presValues, 'omitnan');


figure; clf;

% --- Tide subplot (plot once) ---
s1 = subplot(2,1,1);
plot(tideTime, tideValues, 'DisplayName', 'Tide', 'Color', 'r');
ylabel('SSH (m)');
title(['DO and Tide for ', secondMonth], 'Interpreter', 'none');


% --- DO subplot (loop over moorings) ---
s2 = subplot(2,1,2);
hold on
for iii = 1:length(moorings)
    data = results.(secondMonth).(moorings{iii});
    DO = data.filteredValues(:,3);
    plot(data.filteredTime, DO, 'DisplayName', moorings{iii});
end
hold off
xlabel('Time');
ylabel('DO concentration [mg/L]');
legend show;
grid off;

linkaxes([s1 s2], 'x');

clear tideTime tideData presValues tideValues

%% July to August 

% Extract the first month's data for plotting with tide
thirdMonth = 'JulAug';
tideData = load('DuoTD_data_InnerNorth_JunJul2026_240150_cleaned_L2.mat'); % Load tide data
tideTime = datetime(tideData.d_clean.tstamp, 'ConvertFrom', 'datenum'); % Assuming tide data has a time field
presValues = tideData.d_clean.values(:,3); % channel 3 is sea pressure
tideValues = presValues - mean(presValues, 'omitnan');


figure; clf;

% --- Tide subplot (plot once) ---
s1 = subplot(2,1,1);
plot(tideTime, tideValues, 'DisplayName', 'Tide', 'Color', 'r');
ylabel('SSH (m)');
title(['DO and Tide for ', thirdMonth], 'Interpreter', 'none');


% --- DO subplot (loop over moorings) ---
s2 = subplot(2,1,2);
hold on
for iii = 1:length(moorings)
    data = results.(thirdMonth).(moorings{iii});
    DO = data.filteredValues(:,3);
    plot(data.filteredTime, DO, 'DisplayName', moorings{iii});
end
hold off
xlabel('Time');
ylabel('DO concentration [mg/L]');
legend show;
grid off;

linkaxes([s1 s2], 'x');
