%%% Testing the tidal time series from May 2026 to see how many transects we need %%%

%%% Maia Heffernan, Jun 20, 2026

clear all, close all

%% data

flist = dir('Robertson_ADCP_27May2026_*_cleaned.mat');

% don't want the LTA files for this analysis
isLTA = contains({flist.name}, 'LTA');
flist(isLTA) = [];


% sort files naturally by lap number
[~, sortIdx] = sort(extractLapNum({flist.name}));
flist = flist(sortIdx);

% preallocated array to hold the data inside a struct
allData = cell(numel(flist), 1);

for k = 1:numel(flist)
    fname = fullfile(flist(k).folder, flist(k).name); % calls the folder as well as the name so I can use this script in another directory
    allData{k} = load(fname);
    fprintf('Loaded: %s\n', flist(k).name);
end

%% concatenate the variables into one long times series

% some of the variables need to be vertically concatenated and some
% horizontally concatenated based on their dimensions. Also I only need one
% copy of hte depth variable, z, because it is the same in all the
% timeseries. Similarly, I am going to skip over the readme varible and
% only keep one because it will give an error in the concatenation.



% ---- preallocate wich variables are for horz vs. vert cat ----

varNames = fieldnames(allData{1});
vertcatVars = {'time', 'east', 'error', 'north', 'up'};  % N x 30, stack in time
horzcatVars = {'depth', 'lat', 'lon'};                   % 1 x N, stack in time
keepOnceVars = {'z'};                                     % fixed depth-bin grid
skipVars = {'readme'};                                    % handled separately


combined_data = struct();

% ---- initialize empty arrays for the concatenation ----

for v = 1:numel(vertcatVars)
    combined_data.(vertcatVars{v}) = [];
end
for v = 1:numel(horzcatVars)
    combined_data.(horzcatVars{v}) = [];
end

% ---- loop through the files and concatenate ----

for k = 1:numel(allData)
    for v = 1:numel(vertcatVars)
        combined_data.(vertcatVars{v}) = [combined_data.(vertcatVars{v}); allData{k}.(vertcatVars{v})];
    end
    for v = 1:numel(horzcatVars)
        combined_data.(horzcatVars{v}) = [combined_data.(horzcatVars{v}), allData{k}.(horzcatVars{v})];
    end
end

% ---- keep z and readme from the first file only -----

for v = 1:numel(keepOnceVars)
    combined_data.(keepOnceVars{v}) = allData{1}.(keepOnceVars{v});
end
combined_data.readme = allData{1}.readme;


%% Pulling out the half hour and hour time stamps


% add a datetime version of time to the struct
combined_data.datetime = datetime(combined_data.time, 'ConvertFrom', 'datenum');

% --- target timestamps at every hour and half-hour within the data range
% ---
t0 = dateshift(combined_data.datetime(1), 'start', 'hour');   % round down to nearest hour
t1 = dateshift(combined_data.datetime(end), 'end', 'hour');    % round up to nearest hour
halfHourTargets = (t0:minutes(30):t1)';
hourTargets = (t0:hours(1):t1)';

% --- find nearest index for half-hour targets ---

maxGap = minutes(10); % how far the time value can be from the tru half hour or hour mark

halfHourIdx = nan(numel(halfHourTargets), 1);
for i = 1:numel(halfHourTargets)
    [minDiff, idx] = min(abs(combined_data.datetime - halfHourTargets(i)));
    if minDiff <= maxGap
        halfHourIdx(i) = idx;
    end
end
halfHourIdx = halfHourIdx(~isnan(halfHourIdx));

% --- find nearest index for hour targets---
hourIdx = nan(numel(hourTargets), 1);
for i = 1:numel(hourTargets)
    [minDiff, idx] = min(abs(combined_data.datetime - hourTargets(i)));
    if minDiff <= maxGap
        hourIdx(i) = idx;
    end
end
hourIdx = hourIdx(~isnan(hourIdx));
%% Plot a time series of all the data, then just every 30 minutes, then every hour

binNum = 4;

figure(1); clf;

p1= plot(combined_data.datetime, combined_data.east(:, binNum), '-ks', 'LineWidth',2,'MarkerSize',10);

    hold on

p2 = plot(combined_data.datetime(halfHourIdx), combined_data.east(halfHourIdx, binNum), '-m^', 'LineWidth',2,'MarkerSize',10);

    hold on

p3 = plot(combined_data.datetime(hourIdx), combined_data.east(hourIdx, binNum), '-c.', 'LineWidth',2,'MarkerSize',10);

    xlabel('Time');
    ylabel('East velocity (ms^{-1})');
    title('East/west velocity at 5m depth for different time intervals');
    legend([p1 p2 p3], 'Full time series', 'Half-hourly', 'Hourly')
    fontsize(gcf, 14, 'points')

yline(0, '--r', 'HandleVisibility', 'off')

    grid on;
    hold off;







%% Helper function to extract the lap number from filenames for sorting
function nums = extractLapNum(names)
    nums = zeros(size(names));
    for i = 1:numel(names)
        tok = regexp(names{i}, 'lap(\d+)', 'tokens');
        nums(i) = str2double(tok{1}{1});
    end
end

%% plot a time series at a specific lat/lon point which might be more helpful 



latPoint = combined_data.lat(5); 
lonPoint = combined_data.lon(5); 

figure(2); clf;
plot(combined_data.datetime, combined_data.east(5, :), '-b', 'LineWidth', 2);
hold on;
plot(combined_data.datetime(halfHourIdx), combined_data.east(halfHourIdx, latPoint), '-ro', 'MarkerSize', 8);
plot(combined_data.datetime(hourIdx), combined_data.east(hourIdx, latPoint), '-g*', 'MarkerSize', 8);
xlabel('Time');
ylabel('East velocity (ms^{-1})');
title(['East velocity at ', num2str(combined_data.lat(latPoint)), '° latitude']);
legend('Full time series', 'Half-hourly', 'Hourly');
fontsize(gcf, 14, 'points');
grid on;
hold off;