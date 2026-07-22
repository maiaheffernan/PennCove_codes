%%% Sea-Bird SeaCat plus profiler readin and quicklook script%%%

%%% Maia, May 21 2026

% modified June 26, 2026

clear all, close all

%% Load in the data from the Sea Bird

% === Sea-Bird data first ===


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