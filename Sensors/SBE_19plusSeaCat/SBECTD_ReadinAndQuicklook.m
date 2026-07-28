%%% Sea-Bird SeaCat plus profiler readin and quicklook script%%%

%%% Maia, May 21 2026

% modified June 26, 2026

clear all, close all

%% Load in the data from the Sea Bird

% === Sea-Bird data as .hex files ===


fid = fopen('Robertson_CTD_25May2026_SAR003.hex', 'r'); %'May192026_SBEbucketTest.cnv'
nHeaders = 0;
colNames = {};
while ~feof(fid)
    line = fgetl(fid);
    nHeaders = nHeaders + 1;
    if contains(line, '# name')
        parts = strsplit(line, '=');
        colNames{end+1} = strtrim(parts{2});
        fprintf('added a column')
    end
    if contains(line, '*END*')
        fprintf('broke')
        break
    end
end
fclose(fid);

% Read the data
seabirdData = readmatrix('Robertson_CTD_25May2026_SAR003.hex', 'FileType', 'text', 'NumHeaderLines', nHeaders);

% Check your columns
for i = 1:length(colNames)
    fprintf('Column %d: %s\n', i, colNames{i});
end


% === pulling out the variables ===

SBE_salinity_PSU = seabirdData(:, 1);
SBE_temp_degC = seabirdData(:, 5);
SBE_pressure_db = seabirdData(:, 2);
SBE_seconds = seabirdData(:, 6);
SBE_minutes = seabirdData(:, 7);
SBE_hours = seabirdData(:, 8);
SBE_juliandays = seabirdData(:, 9);


% === putting the time data into a datetime ===

year = 2026;
SBE_datetime = datetime(year, 1, 1) - days(1) + days(SBE_juliandays);

%%

% Open the binary file
fid = fopen('Robertson_CTD_25May2026_SAR003.hex', 'r');

% Read the raw bytes as unsigned 8-bit integers
rawBytes = fread(fid, Inf, 'uint8');

% Close the file
fclose(fid);

% Convert the raw bytes into a readable Hex string matrix
hexStrings = dec2hex(rawBytes);

%% For .cap files

fid = fopen('LoveJoySouth_JunJul2026_bottom_sn4762.cap', 'r');
if fid == -1
    error('Cannot open file.');
end

lineNum = 1;
while ~feof(fid)
    tline = fgetl(fid);
    if ischar(tline)
        % Store or parse each line as needed
        capData{lineNum} = tline; 
        lineNum = lineNum + 1;
    end
end

%% == parsing the .cap structure ==


% === NOTE ====

% I know which channel is which in teh comma separated variables in the .cap file 
% based on the .xmlcon Sensor index:

% <SensorArray Size="3" >
%   <Sensor index="0" SensorID="58" >  -->  Temperature Sensor
%  <Sensor index="1" SensorID="3"  >  --> Conductivity Sensor
%  <Sensor index="2" SensorID="46" > --> Pressure Sensor

% the forth channel is the derived salinity value


% =================


% Remove the Seaterm header lines at the beginning and end 
capData([1:3, end]) = [];

n = numel(capData);

% Preallocate
temp = nan(n,1);
cond = nan(n,1);
press = nan(n,1);
sal = nan(n,1);
dateStr = strings(n,1);
timeStr = strings(n,1);

for i = 4:n
    line = capData{i};           % extract the char array from the nested cell
    parts = strsplit(line, ',');   % split on commas
    parts = strtrim(parts);        % remove leading/trailing whitespace

    temp(i)  = str2double(parts{1});
    cond(i)  = str2double(parts{2});
    press(i) = str2double(parts{3});
    sal(i)   = str2double(parts{4});
    dateStr(i) = parts{5};
    timeStr(i) = parts{6};
end

% Combine date + time into a single datetime column
dateTime = datetime(strcat(dateStr, {' '}, timeStr), ...
    'InputFormat', 'dd MMM yyyy HH:mm:ss');

% Final table (easier to work with than a raw matrix, but you can convert)
seacatData = table(temp, cond, press, sal, dateTime, ...
    'VariableNames', {'Temperature','Conductivity','Pressure','Salinity','DateTime'});

% Numeric 37355x6 matrix instead:
% (datenum for the time column since you can't put datetime in a plain double matrix)
% seacatMatrix = [temp, cond, press, sal, datenum(dateTime), datenum(dateTime)];



%% == see if any lines were corrupted (they will be NaNed out from str2double ====

% Check for NaN values in the seacatData and report any corrupted lines
corruptedLines = isnan(seacatData.Temperature) | isnan(seacatData.Conductivity) | ...
                 isnan(seacatData.Pressure) | isnan(seacatData.Salinity);

sum(corruptedLines);

%% applying the time cutoff

startTime = datetime(2026, 6, 26, 00, 0, 0);
endTime = datetime(2026, 7, 21, 16, 30, 0);

% Filter the seacatData based on the time cutoff
outOfRange = seacatData.DateTime < startTime | seacatData.DateTime > endTime;


dataVars = seacatData.Properties.VariableNames;

    for v = 1:numel(dataVars)
        col = seacatData.(dataVars{v});

        if isa(col, 'double')
       
            col(outOfRange, :) = NaN;
            seacatData.(dataVars{v}) = col;

        else
            
            col(outOfRange, :) = NaT; % for the datetime column
            seacatData.(dataVars{v}) = col;
        end
    end



%% save the raw seabird data to the general data file

% Save the seabird data to a .mat file for future analysis
save('/Users/heffem3/Library/CloudStorage/GoogleDrive-heffem3@uw.edu/Shared drives/M2O2/Penn Cove 2026/July2026/Data/seabirdData_JunJul2026_raw.mat', 'seacatData')

%% plot the raw data

figure(1); clf;

s1 = subplot(2,1,1);

    p1 = plot(seacatData.DateTime, seacatData.Temperature, 'r.-');
        ylabel('Temperature (°C)')
        title('Raw SeaBird CTD data for June to July')

s2 = subplot(2,1,2);

    p2 = plot(seacatData.DateTime, seacatData.Salinity, 'b.-');
        ylabel('Salinity (ppt)')
        xlabel('Time')

    
    
 linkaxes([s1 s2], 'x')

