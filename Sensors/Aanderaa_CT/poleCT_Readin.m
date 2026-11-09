%%% Loading in the poleCT data from the Echo surveys %%%

% Maia heffernan, July 15, 2026

clear all, close all

%% load in the data

fname1 = '/Users/heffem3/Library/CloudStorage/GoogleDrive-heffem3@uw.edu/Shared drives/M2O2/Penn Cove 2026/Oct2026/Data/Echo/PoleCT/Echo_PoleCT_23Sep2026_ebbt';
fname2 = '/Users/heffem3/Library/CloudStorage/GoogleDrive-heffem3@uw.edu/Shared drives/M2O2/Penn Cove 2026/Oct2026/Data/Echo/PoleCT/Echo_PoleCT_23Sep2026_flood';

poleCTdata_ebb = readtable(fname1);
poleCTdata_flood = readtable(fname2);


%% fix any variable names in the table

% === combine the first two columns into a datetime ===

% ebb 

    cleanDate = erase(poleCTdata_ebb.Var1, {'[', ']', ''''});
    cleanTime = erase(poleCTdata_ebb.Var2, {'[', ']', ''''});

    combinedStr = strcat(cleanDate, {' '}, cleanTime);

    poleCTdata_ebb.DateTime = datetime(combinedStr, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');

    % erase the incorrect vars
    poleCTdata_ebb.Var1 = erase(poleCTdata_ebb.Var1, "'");
    poleCTdata_ebb.Var2 = erase(poleCTdata_ebb.Var2, "'");
    
    
clear cleanDate cleanTime
 
%flood

    cleanDate = erase(poleCTdata_flood.Var1, {'[', ']', ''''});
    cleanTime = erase(poleCTdata_flood.Var2, {'[', ']', ''''});

    combinedStr = strcat(cleanDate, {' '}, cleanTime);

    poleCTdata_flood.DateTime = datetime(combinedStr, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');


% === get rid of the variable name columns and rename the data columns with the correct label ===

% ebb

    % Loop through variables, looking for "label" columns (cell arrays of char)
    % paired with a data column right after them
    varsToRemove = {};
    i = 1;
    while i < width(poleCTdata_ebb)
        thisVar = poleCTdata_ebb.(poleCTdata_ebb.Properties.VariableNames{i});
        
        % Check if this column is a cell array of char (i.e., a "label" column)
        if iscell(thisVar) && ischar(thisVar{1})
            % Grab the label from the first row
            rawLabel = thisVar{1};
            
            % Clean it up: strip brackets/quotes, replace invalid chars for a
            % valid MATLAB variable name
            cleanLabel = erase(rawLabel, {'[', ']', ''''});
            cleanLabel = matlab.lang.makeValidName(cleanLabel);
            
            % Rename the NEXT column (the actual data) to this label
            nextVarName = poleCTdata_ebb.Properties.VariableNames{i+1};
            poleCTdata_ebb.Properties.VariableNames{nextVarName} = cleanLabel;
            
            % Mark this label column for removal
            varsToRemove{end+1} = poleCTdata_ebb.Properties.VariableNames{i};
            
            i = i + 2;  % skip past the pair
        else
            i = i + 1;
        end
    end
    
    % Remove all the label columns
    poleCTdata_ebb(:, varsToRemove) = [];


% flood 

    % Loop through variables, looking for "label" columns (cell arrays of char)
        % paired with a data column right after them
        varsToRemove = {};
        i = 1;
        while i < width(poleCTdata_flood)
            thisVar = poleCTdata_flood.(poleCTdata_flood.Properties.VariableNames{i});
            
            % Check if this column is a cell array of char (i.e., a "label" column)
            if iscell(thisVar) && ischar(thisVar{1})
                % Grab the label from the first row
                rawLabel = thisVar{1};
                
                % Clean it up: strip brackets/quotes, replace invalid chars for a
                % valid MATLAB variable name
                cleanLabel = erase(rawLabel, {'[', ']', ''''});
                cleanLabel = matlab.lang.makeValidName(cleanLabel);
                
                % Rename the NEXT column (the actual data) to this label
                nextVarName = poleCTdata_flood.Properties.VariableNames{i+1};
                poleCTdata_flood.Properties.VariableNames{nextVarName} = cleanLabel;
                
                % Mark this label column for removal
                varsToRemove{end+1} = poleCTdata_flood.Properties.VariableNames{i};
                
                i = i + 2;  % skip past the pair
            else
                i = i + 1;
            end
        end
        
        % Remove all the label columns
        poleCTdata_flood(:, varsToRemove) = [];


%% plot the data as a time series

figure(1)

s1 = subplot(2,2,1);

p1 = plot(poleCTdata_ebb.DateTime, poleCTdata_ebb.SalinityPSU, 'b.-');
ylabel('Salinity (PSU)')
title('Ebb tide')
subtitle('Surface salinity')
axis tight

s2 = subplot(2,2,2);

p2 = plot(poleCTdata_flood.DateTime, poleCTdata_flood.SalinityPSU, 'b.-');
title('Flood tide')
subtitle('Surface salinity')
axis tight

s3 = subplot(2,2,3);

p3 = plot(poleCTdata_ebb.DateTime, poleCTdata_ebb.TemperatureDeg_C, 'r.-');
subtitle('Surface temperature')
ylabel('Temperature (deg C)')
xlabel('Time')
axis tight


s4 = subplot(2,2,4);

p4 = plot(poleCTdata_flood.DateTime, poleCTdata_flood.TemperatureDeg_C, 'r.-');
subtitle('Surface temperature')
xlabel('Time')
axis tight

%% Just the individual flood and ebb tides

figure(2)

s5 = subplot(2,1,1);

p5 = plot(poleCTdata_ebb.DateTime, poleCTdata_ebb.SalinityPSU, 'b.-');
ylabel('Salinity (PSU)')
title('Ebb tide')
axis tight

s6 = subplot(2,1,2);

p6 = plot(poleCTdata_ebb.DateTime, poleCTdata_ebb.TemperatureDeg_C, 'r.-');
ylabel('Temperature (deg C)')
xlabel('Time')
axis tight

linkaxes([s5 s6], 'x')


figure(3)

s7 = subplot(2,1,1);

p7 = plot(poleCTdata_flood.DateTime, poleCTdata_flood.SalinityPSU, 'b.-');
ylabel('Salinity (PSU)')
title('Flood tide')
axis tight

s8 = subplot(2,1,2);

p8 = plot(poleCTdata_flood.DateTime, poleCTdata_flood.TemperatureDeg_C, 'r.-');
ylabel('Temperature (deg C)')
xlabel('Time')
axis tight

linkaxes([s7 s8], 'x')

%% remove any outliers in the timeseries

% remove salinity values less than 8 PSU because these dips indicate the
% boat is moving between transect lines and there is likely bubbles in teh salinity measurement


% ebb
% 
% badRows_ebb = poleCTdata_ebb.SalinityPSU < 8 | poleCTdata_ebb.TemperatureDeg_C > 18;
% fprintf('Removing %d of %d rows from ebb data due to bad salinity or temperature\n', sum(badRows_ebb), height(poleCTdata_ebb));
% poleCTdata_ebb(badRows_ebb, :) = [];
% 
% 
% % flood
% 
% badRows_flood = poleCTdata_flood.SalinityPSU < 8 | poleCTdata_flood.TemperatureDeg_C > 18;
% fprintf('Removing %d of %d rows from flood data due to bad salinity or temperature\n', sum(badRows_flood), height(poleCTdata_flood));
% poleCTdata_flood(badRows_flood, :) = [];




%% remove any outliers in the timeseries
% remove salinity values less than 8 PSU because these dips indicate the
% boat is moving between transect lines and there is likely bubbles in the salinity measurement
% also remove indices where the temperature is too high to be realistic for
% the water and ALSO if the water temperature changes too quickly

timeVar  = 'DateTime';   % name of time column in the dataframe
tempJump = 2;            % deg C
tempWin  = minutes(5);   % window length

% ebb
badRows_ebb = poleCTdata_ebb.SalinityPSU < 8 | poleCTdata_ebb.TemperatureDeg_C > 18;
fprintf('Removing %d of %d rows from ebb data due to bad salinity or temperature\n', sum(badRows_ebb), height(poleCTdata_ebb));
poleCTdata_ebb(badRows_ebb, :) = [];
% temperature spikes (run after the cutoffs above so bad data doesn't skew the window)
spikeRows_ebb = findTempSpikes(poleCTdata_ebb.(timeVar), poleCTdata_ebb.TemperatureDeg_C, tempJump, tempWin);
fprintf('Removing %d of %d rows from ebb data due to temperature spikes > %g C within %s\n', sum(spikeRows_ebb), height(poleCTdata_ebb), tempJump, string(tempWin));
poleCTdata_ebb(spikeRows_ebb, :) = [];

% flood
badRows_flood = poleCTdata_flood.SalinityPSU < 8 | poleCTdata_flood.TemperatureDeg_C > 18;
fprintf('Removing %d of %d rows from flood data due to bad salinity or temperature\n', sum(badRows_flood), height(poleCTdata_flood));
poleCTdata_flood(badRows_flood, :) = [];
spikeRows_flood = findTempSpikes(poleCTdata_flood.(timeVar), poleCTdata_flood.TemperatureDeg_C, tempJump, tempWin);
fprintf('Removing %d of %d rows from flood data due to temperature spikes > %g C within %s\n', sum(spikeRows_flood), height(poleCTdata_flood), tempJump, string(tempWin));
poleCTdata_flood(spikeRows_flood, :) = [];


%% re-plot these figures 


figure(4); clf;

s9 = subplot(2,1,1);

p9 = plot(poleCTdata_ebb.DateTime, poleCTdata_ebb.SalinityPSU, 'b-.');
ylabel('Salinity (PSU)')
title('Ebb tide')
axis tight

s10 = subplot(2,1,2);

p10 = plot(poleCTdata_ebb.DateTime, poleCTdata_ebb.TemperatureDeg_C, 'r-.');
ylabel('Temperature (deg C)')
xlabel('Time')
axis tight

linkaxes([s9 s10], 'x')


figure(5); clf;

s11 = subplot(2,1,1);

p11 = plot(poleCTdata_flood.DateTime, poleCTdata_flood.SalinityPSU, 'b-.');
ylabel('Salinity (PSU)')
title('Flood tide')
axis tight

s12 = subplot(2,1,2);

p12 = plot(poleCTdata_flood.DateTime, poleCTdata_flood.TemperatureDeg_C, 'r-.');
ylabel('Temperature (deg C)')
xlabel('Time')
axis tight

linkaxes([s11 s12], 'x')



%% local function for temperature spike cleaning
function isSpike = findTempSpikes(t, T, maxJump, win)
    % Flags points whose temperature differs from the median of the
    % surrounding window (centered, length = win) by more than maxJump.
    % Handles duplicate timestamps by collapsing them to one value per
    % unique time before computing the running median.
    isSpike = false(size(T));
    ok = ~isnat(t) & ~isnan(T);            % ignore missing times/values
    Tok = T(ok);
    [tu, ~, ic] = unique(t(ok));           % sorted unique times; ic maps rows -> unique times
    Tu = accumarray(ic, Tok, [], @median); % one temperature per unique time
    localMed = movmedian(Tu, win, 'SamplePoints', tu);
    isSpike(ok) = abs(Tok - localMed(ic)) > maxJump;  % compare each original row to its local median
end