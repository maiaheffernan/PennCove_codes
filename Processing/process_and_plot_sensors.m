%% process_and_plot_sensors.m
%
% Processes three period-structures (MayJun, JunJul, JulAug), each with
% identical layout:
%   Period.TODO_data.(SensorName).data.tstamp  -> Nx1 datenum
%   Period.TODO_data.(SensorName).data.data    -> Nx3 measurement matrix
%
% For each sensor, computes daily mean and daily std (per column),
% concatenates the three periods in chronological order, removes any
% duplicate calendar days at the seams (in case periods overlap), and
% plots each channel as a time series with the std shaded around it.

%% ---- USER SETUP ----
% Make sure MayJun, JunJul, JulAug are already loaded in the workspace.
periodNames = {'MayJun','JunJul','JulAug'};   % chronological order
sensorNames = {'LoveJoyNorth','LoveJoySouth','InnerNorth','InnerSouth'};
channelNames = {'Temperature (°C)','DO (µmol/L)','DO (mg/L)'};  % rename as needed


%% ---- STEP 1: compute daily mean/std for every period x sensor ----
daily = struct();  % daily.(sensor).(period).dt / .meanData / .stdData

for p = 1:length(periodNames)
    pname = periodNames{p};
    S = eval(pname);  % grabs the variable named e.g. 'MayJun' from workspace

    for s = 1:length(sensorNames)
        sname = sensorNames{s};

        tstamp = S.TODO_data.(sname).data.tstamp;   % Nx1 datenum
        meas   = S.TODO_data.(sname).data.values;      % Nx3 matrix

        dt = datetime(tstamp, 'ConvertFrom', 'datenum');
        dayKey = dateshift(dt, 'start', 'day');
        uniqueDays = unique(dayKey);
        nDays = length(uniqueDays);

        meanData = nan(nDays, 3);
        stdData  = nan(nDays, 3);

        for d = 1:nDays
            idx = (dayKey == uniqueDays(d));
            meanData(d,:) = mean(meas(idx,:), 1);
            stdData(d,:)  = std(meas(idx,:), 0, 1);
        end

        daily.(sname).(pname).dt       = uniqueDays;
        daily.(sname).(pname).meanData = meanData;
        daily.(sname).(pname).stdData  = stdData;
    end
end

%% ---- STEP 2: concatenate periods chronologically per sensor, dedupe ----
combined = struct();  % combined.(sensor).dt / .meanData / .stdData

for s = 1:length(sensorNames)
    sname = sensorNames{s};

    dtAll   = [];
    meanAll = [];
    stdAll  = [];

    for p = 1:length(periodNames)
        pname = periodNames{p};
        dtAll   = [dtAll;   daily.(sname).(pname).dt];        %#ok<AGROW>
        meanAll = [meanAll; daily.(sname).(pname).meanData];  %#ok<AGROW>
        stdAll  = [stdAll;  daily.(sname).(pname).stdData];   %#ok<AGROW>
    end

    % Sort chronologically (should already be sorted, but just in case)
    [dtAll, sortIdx] = sort(dtAll);
    meanAll = meanAll(sortIdx,:);
    stdAll  = stdAll(sortIdx,:);

    % Remove duplicate calendar days (keep first occurrence)
    [dtUnique, uniqueIdx] = unique(dtAll, 'first');
    if length(dtUnique) < length(dtAll)
        fprintf('%s: removed %d duplicate day(s) at period boundaries.\n', ...
                sname, length(dtAll) - length(dtUnique));
    end

    combined.(sname).dt       = dtUnique;
    combined.(sname).meanData = meanAll(uniqueIdx,:);
    combined.(sname).stdData  = stdAll(uniqueIdx,:);
end

%% ---- STEP 3: plot each sensor, each channel, with shaded std ----
for s = 1:length(sensorNames)
    sname = sensorNames{s};
    dt      = combined.(sname).dt;
    meanD   = combined.(sname).meanData;
    stdD    = combined.(sname).stdData;

    figure('Name', sname, 'Color', 'w');
    for c = 1:3
        subplot(3,1,c);
        plotShadedTimeseries(dt, meanD(:,c), stdD(:,c));
        ylabel(channelNames{c});
        if c == 1
            title(sname, 'Interpreter', 'none');
        end
        if c == 3
            xlabel('Date');
        end
    end
end

%% ---- Local function: shaded error time series plot ----
function plotShadedTimeseries(dt, meanVals, stdVals)
    % Plots meanVals vs dt as a line, with +/- stdVals shaded around it.
    upper = meanVals + stdVals;
    lower = meanVals - stdVals;

    % Build the patch for the shaded region
    xPatch = [dt; flipud(dt)];
    yPatch = [upper; flipud(lower)];

    hold on;
    fill(xPatch, yPatch, [0.3 0.5 0.9], ...
         'FaceAlpha', 0.25, 'EdgeColor', 'none', 'HandleVisibility','off');
    plot(dt, meanVals, '-', 'Color', [0.1 0.2 0.6], 'LineWidth', 1.5);
    hold off;
    grid on;
    box on;
end