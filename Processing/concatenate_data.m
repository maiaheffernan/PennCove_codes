function concatenate_data(rootDir, sensorType)


%%%%% Concatenating months of data %%%%%

%%% Created to easily be able to combine two datasets into one .mat file
% Maia H. July 2026


% Notes to myself:
% I want this to be a function that I can easily call by just putting in
% two datasets into the call line. The function should be able to read in
% the .mat files, determine what type of data they are, and concatenate
% them in time accordingly. So .mat files with ruskin structures will be
% different than .mat files with tables vs. SWIFT files, etc.

% The function call should have the inputs be the .mat files I am
% interested in, so the number of varargin will vary. When naming the final
% data product, the function should ask the user what months they want to
% concatenate/are represented in the data for the sake of the file name.
% The user should then input the month names into the command line and the
% function will take that input and make it part of the file name. 

%% Here is the plan for the function:

% 1. Go into Google Drive and find the raw data files I want to concatenate. 
%    - The user should give the file path to the highest level directory that contains the raw data files they want to concatenate. The function should then search through all the subdirectories and find all the raw data files in that directory and its subdirectories.
%    - This will go by sensor type (i.e. all the TODO data files or the soloT data files, etc.)
%     So basically I should be able to say in the funcitno call that I want to concatenate all the raw data files for a certain sensor type.

% 2. Read in the data files and determine what type of data they are (i.e. table, structure, etc.)

% 3. Concatenate the data in time, making sure to check for any overlapping time periods and removing duplicates. 
%     - Before ANY data is removed, the function should ask the user if they want to remove duplicates or not. The function should SPECIFICALLY point out WHERE the duplicates are in the data. If they do, then the function will remove duplicates and concatenate the data. If they don't, then the function will just concatenate the data without removing duplicates.

% 4. Save the concatenated data as a new .mat file with a name that includes the months represented in the data. The function should also make .csv and .nc files from this data as well.

% 5. The function should also generate a quicklook plot of the concatenated data and save it as a .png file with the same name as the .mat file.
%     - The .mat file should be saved to Google Drive in a new folder called "ConcatenatedData."
%.    - The .png file should be saved to the same folder as the .mat file and ALSO to a new directory called "Concatenated_Quicklook_Plots" in the PennCove_codes/Figures directory.


% To Do (Maia): May-Jun LJN_26m (miniDOT) is missing the
% CoordinatedUniversalTime and DissolvedOxygenSaturation columns. Fix that
% data file. Until then, combining the miniDOT tables will error.

%% 1. Find the raw data files for this sensor type

% Each sensor's raw files are found by their file name. The * stands for
% the months, so this keeps working as new months are added.
switch lower(sensorType)
    case 'concerto'
        filePattern = 'mooredConcertoData_*_raw.mat';
    case 'todo'
        filePattern = 'TODOdata_*_raw.mat';
    case 'duo'
        filePattern = 'DuoTDdata_*_raw.mat';
    case 'seacat'
        filePattern = 'seabirdData_*_raw.mat';
    case 'solo'
        filePattern = 'SoloTdata_*_raw.mat';
    case 'ysi'
        filePattern = 'YSI600LSdata_*_raw.mat';
    case 'minidot'
        % this matches both the mooringdata and the raftdata files
        filePattern = 'miniDOT_*data_raw.mat';
    otherwise
        error(['Unknown sensor type "%s". Options are: concerto, todo, ', ...
            'duo, seacat, solo, ysi, minidot.'], sensorType);
end

% the ** tells dir to search rootDir and all of its subdirectories
fileInfo = dir(fullfile(rootDir, '**', filePattern));

if isempty(fileInfo)
    error('No files matching %s were found under %s.', filePattern, rootDir);
end

% show what was found so it can be checked before any data is loaded
fprintf('\nFound %d raw file(s) for %s:\n', numel(fileInfo), sensorType);
for iFile = 1:numel(fileInfo)
    relativeFolder = erase(fileInfo(iFile).folder, [rootDir, filesep]);
    fprintf('  %2d) %s/%s (%.1f MB)\n', iFile, relativeFolder, ...
        fileInfo(iFile).name, fileInfo(iFile).bytes/1e6);
end

reply = input('Load these files? (y/n): ', 's');
if ~strcmpi(strtrim(reply), 'y')
    fprintf('Stopped. No data was loaded.\n');
    return
end

%% 2. Load the files and work out what type of data each one holds

% Every instrument from every file goes into one list called segments.
% Each entry is one instrument from one deployment, so the same instrument
% shows up once per month. Chunk 3 joins the matching entries together.
segments = struct('instrument', {}, 'dataType', {}, 'sourceFile', {}, 'data', {});

for iFile = 1:numel(fileInfo)
    fprintf('Loading %s ...\n', fileInfo(iFile).name);
    loaded = load(fullfile(fileInfo(iFile).folder, fileInfo(iFile).name));

    % a file can hold several variables (e.g. LJN_4m, LJN_8m, ...)
    varNames = fieldnames(loaded);
    for iVar = 1:numel(varNames)
        segments = [segments, find_instruments(loaded.(varNames{iVar}), ...
            varNames{iVar}, fileInfo(iFile).name)]; %#ok<AGROW>
    end
end

% show what was found for each instrument
instrumentNames = unique({segments.instrument});
fprintf('\nLoaded %d instrument(s) from %d file(s):\n', ...
    numel(instrumentNames), numel(fileInfo));
for iInst = 1:numel(instrumentNames)
    isThisInst = strcmp({segments.instrument}, instrumentNames{iInst});
    theseTypes = unique({segments(isThisInst).dataType});
    fprintf('  %-30s %-12s in %d file(s)\n', instrumentNames{iInst}, ...
        strjoin(theseTypes, ' + '), sum(isThisInst));
end


%% 3. Join each instrument's months together in time

% Nothing is removed in this section without asking first.
combined = struct();

for iInst = 1:numel(instrumentNames)
    thisName = instrumentNames{iInst};
    isThisInst = strcmp({segments.instrument}, thisName);
    theseSegments = segments(isThisInst);
    segments(isThisInst) = [];   % frees memory as each instrument is joined
    fprintf('\n--- %s ---\n', thisName);

    % put this instrument's files in time order (all-NaN placeholders go last)
    nFiles = numel(theseSegments);
    firstTime = NaT(nFiles, 1);
    lastTime = NaT(nFiles, 1);
    for iSeg = 1:nFiles
        segmentTime = get_time(theseSegments(iSeg));
        firstTime(iSeg) = min(segmentTime);
        lastTime(iSeg) = max(segmentTime);
    end
    [firstTime, fileOrder] = sort(firstTime);
    lastTime = lastTime(fileOrder);
    theseSegments = theseSegments(fileOrder);

    % stack the files, with a record of which file each row came from
    [joined, t, source] = join_segments(theseSegments, thisName);

    % --- NaT times: point out where they are, then ask ---
    removableNaT = false(size(t));
    sourceNames = categories(source);
    for iSource = 1:numel(sourceNames)
        inFile = source == sourceNames{iSource};
        fileNaT = isnat(t(inFile));
        if all(fileNaT)
            fprintf('  %s has no valid times (all-NaN placeholder). Keeping it.\n', ...
                sourceNames{iSource});
        elseif any(fileNaT)
            fprintf('  NaT times in %s: %d of %d rows, at file rows %s\n', ...
                sourceNames{iSource}, sum(fileNaT), numel(fileNaT), ...
                describe_rows(find(fileNaT)));
            removableNaT(inFile) = fileNaT;
        end
    end
    if any(removableNaT) && ask_yes_no(sprintf( ...
            '  Remove these %d NaT rows from %s? (y/n): ', sum(removableNaT), thisName))
        joined = select_rows(joined, ~removableNaT);
        t = t(~removableNaT);
        source = source(~removableNaT);
        fprintf('  Removed %d NaT rows.\n', sum(removableNaT));
    end

    % sort everything in time (any NaT rows that were kept go to the end)
    [t, timeOrder] = sort(t);
    joined = select_rows(joined, timeOrder);
    source = source(timeOrder);

    % --- overlapping deployments: point out where they are ---
    for iSeg = 1:nFiles-1
        if lastTime(iSeg) >= firstTime(iSeg+1)
            fprintf('  Overlap: %s ends %s, but %s starts %s\n', ...
                theseSegments(iSeg).sourceFile, string(lastTime(iSeg)), ...
                theseSegments(iSeg+1).sourceFile, string(firstTime(iSeg+1)));
        end
    end

    % --- repeated timestamps: point out where they are, then ask ---
    isRepeat = [false; diff(t) == 0];
    if any(isRepeat)
        repeatRows = find(isRepeat);
        laterFile = string(source(repeatRows));
        earlierFile = string(source(repeatRows - 1));
        filePairs = unique([earlierFile, laterFile], 'rows');

        fprintf('  Repeated timestamps: %d row(s)\n', numel(repeatRows));
        for iPair = 1:size(filePairs, 1)
            inPair = earlierFile == filePairs(iPair, 1) & laterFile == filePairs(iPair, 2);
            pairTimes = t(repeatRows(inPair));
            fprintf('    %d row(s) in %s repeat %s, from %s to %s\n', sum(inPair), ...
                filePairs(iPair, 2), filePairs(iPair, 1), ...
                string(pairTimes(1)), string(pairTimes(end)));
        end

        if ask_yes_no(sprintf( ...
                '  Remove these %d repeated rows from %s, keeping the first of each? (y/n): ', ...
                numel(repeatRows), thisName))
            joined = select_rows(joined, ~isRepeat);
            t = t(~isRepeat);
            fprintf('  Removed %d repeated rows.\n', numel(repeatRows));
        end
    end

    fprintf('  Joined: %d rows, %s to %s, from %d file(s)\n', numel(t), ...
        string(min(t)), string(max(t)), nFiles);
    combined.(thisName) = joined;
end


%% 4. Save the concatenated data as .mat, .csv, and .nc

% ask which months are in the data, for the file names
months = '';
while isempty(months)
    months = strtrim(input('Months in this data, for the file name (e.g. MayOct2026): ', 's'));
end

outDir = fullfile(rootDir, 'ConcatenatedData');
if ~isfolder(outDir)
    mkdir(outDir);
end

% e.g. TODOdata_MayOct2026_concatenated.mat
baseName = sprintf('%s_%s_concatenated', extractBefore(filePattern, '_*'), months);
matFile = fullfile(outDir, [baseName, '.mat']);
csvFile = fullfile(outDir, [baseName, '.csv']);
ncFile = fullfile(outDir, [baseName, '.nc']);
pngFile = fullfile(outDir, [baseName, '.png']);

% the second copy of the plot goes in PennCove_codes/Figures
repoFigDir = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
    'Figures', 'Concatenated_Quicklook_Plots');
repoPngFile = fullfile(repoFigDir, [baseName, '.png']);

% the SoloT CSV would be too large to be useful, so it is skipped
makeCsv = ~strcmpi(sensorType, 'solo');

% ask before replacing anything that already exists
outFiles = {matFile, ncFile, pngFile, repoPngFile};
if makeCsv
    outFiles{end+1} = csvFile;
end
existingFiles = outFiles(cellfun(@isfile, outFiles));
if ~isempty(existingFiles)
    fprintf('\nThese files already exist:\n');
    fprintf('  %s\n', existingFiles{:});
    if ~ask_yes_no('Replace them? (y/n): ')
        fprintf('Stopped. Nothing was saved.\n');
        return
    end
    delete(existingFiles{:});
end

% .mat: same variables as the raw files, so plotting code carries over.
% -v7.3 is needed because the SoloT data is larger than 2 GB.
fprintf('\nSaving %s ...\n', matFile);
toSave = struct();
switch lower(sensorType)
    case 'concerto'
        toSave.concerto_data = combined;
    case 'todo'
        toSave.TODO_data = combined;
    case 'duo'
        toSave.DuoTD_data = combined;
    case 'solo'
        % put back the mooring > serial number nesting of the raw files
        instruments = fieldnames(combined);
        for iInst = 1:numel(instruments)
            nameParts = split(instruments{iInst}, '_');
            toSave.soloT_data.(nameParts{1}).(nameParts{2}) = combined.(instruments{iInst});
        end
    otherwise
        toSave = combined;   % tables are saved as separate variables
end
save(matFile, '-struct', 'toSave', '-v7.3');

% .csv: one row per instrument per timestamp
if makeCsv
    fprintf('Saving %s ...\n', csvFile);
    writetable(build_csv_table(combined), csvFile, 'Encoding', 'UTF-8');
else
    fprintf('Skipping the .csv for %s.\n', sensorType);
end

% .nc: one group per instrument, because each has its own timestamps
fprintf('Saving %s ...\n', ncFile);
write_netcdf(combined, ncFile);


%% 5. Make the quicklook plot and save it as a .png

fprintf('Saving %s ...\n', pngFile);
make_quicklook(combined, sensorType, baseName, pngFile);

% save a second copy in PennCove_codes/Figures
if ~isfolder(repoFigDir)
    mkdir(repoFigDir);
end
copyfile(pngFile, repoPngFile);

fprintf('\nDone. Files are in %s\n', outDir);


%% Helper functions

function found = find_instruments(item, itemName, sourceFile)
% Looks through one loaded variable and returns an entry for each
% instrument inside it. Tables are one instrument each. RSK structs can be
% nested (SoloT is mooring > serial number), so this keeps opening structs
% until it reaches one that holds data and channels.

found = struct('instrument', {}, 'dataType', {}, 'sourceFile', {}, 'data', {});

if istable(item)
    found = struct('instrument', itemName, 'dataType', 'table', ...
        'sourceFile', sourceFile, 'data', item);

elseif isstruct(item) && isfield(item, 'data') && isfield(item, 'channels')
    found = struct('instrument', clean_instrument_name(itemName), ...
        'dataType', 'RSK struct', 'sourceFile', sourceFile, 'data', item);

elseif isstruct(item)
    subNames = fieldnames(item);
    for iSub = 1:numel(subNames)
        found = [found, find_instruments(item.(subNames{iSub}), ...
            [itemName, '_', subNames{iSub}], sourceFile)]; %#ok<AGROW>
    end

else
    warning('Skipping %s in %s: it is a %s, not a table or RSK struct.', ...
        itemName, sourceFile, class(item));
end


function cleanName = clean_instrument_name(name)
% Makes RSK names match from month to month by removing the outer struct
% name and the months. For example:
%   TODO_data_LoveJoyNorth                         -> LoveJoyNorth
%   soloT_data_LoveJoyNorth_sn212861               -> LoveJoyNorth_sn212861
%   DuoTD_data_DuoTD_data_InnerNorth_JunJul2026_240149 -> InnerNorth_sn240149

cleanName = regexprep(name, '^((concerto_data|TODO_data|DuoTD_data|soloT_data)_)+', '');
cleanName = regexprep(cleanName, '_[A-Za-z]+\d{4}_(\d+)$', '_sn$1');


function t = get_time(segment)
% Returns one file's time column as a datetime, whichever format it is in.

if strcmp(segment.dataType, 'RSK struct')
    t = datetime(segment.data.data.tstamp, 'ConvertFrom', 'datenum');
    return
end

T = segment.data;
if ismember('DateTime', T.Properties.VariableNames)
    t = T.DateTime;              % SeaCat and YSI
else
    t = T.UTC_Date___Time;       % miniDOT
end

% the all-NaN placeholder tables store their time column as NaN numbers
if ~isdatetime(t)
    t = NaT(height(T), 1);
end


function [joined, t, source] = join_segments(theseSegments, thisName)
% Stacks one instrument's files, which must already be in time order.
% Stops with an error if the files don't hold the same columns.

nFiles = numel(theseSegments);
times = cell(nFiles, 1);
nRows = zeros(nFiles, 1);
for iSeg = 1:nFiles
    times{iSeg} = get_time(theseSegments(iSeg));
    nRows(iSeg) = numel(times{iSeg});
end
t = vertcat(times{:});

% which file each row came from (categorical keeps this small in memory)
fileNumber = repelem((1:nFiles)', nRows);
source = categorical(fileNumber, 1:nFiles, {theseSegments.sourceFile});

if strcmp(theseSegments(1).dataType, 'table')
    tables = {theseSegments.data}';
    firstVars = tables{1}.Properties.VariableNames;

    for iSeg = 2:nFiles
        differing = setxor(tables{iSeg}.Properties.VariableNames, firstVars);
        if ~isempty(differing)
            error('%s: %s has different columns from %s. Differing columns: %s', ...
                thisName, theseSegments(iSeg).sourceFile, ...
                theseSegments(1).sourceFile, strjoin(differing, ', '));
        end

        % placeholder tables store times as NaN numbers, which can't be
        % stacked with datetimes, so change them to NaT
        for iVar = 1:numel(firstVars)
            varName = firstVars{iVar};
            if isdatetime(tables{1}.(varName)) && ~isdatetime(tables{iSeg}.(varName))
                tables{iSeg}.(varName) = NaT(height(tables{iSeg}), 1, ...
                    'TimeZone', tables{1}.(varName).TimeZone, ...
                    'Format', tables{1}.(varName).Format);
            end
        end
    end

    joined = vertcat(tables{:});
    joined.SourceFile = source;

else
    % the channel list can be longer than the data columns, so only the
    % channels that have a column are compared
    nCols = size(theseSegments(1).data.data.values, 2);
    firstChannels = theseSegments(1).data.channels(1:nCols);
    tstamps = cell(nFiles, 1);
    values = cell(nFiles, 1);

    for iSeg = 1:nFiles
        thisRsk = theseSegments(iSeg).data;
        if size(thisRsk.data.values, 2) ~= nCols || ...
                ~isequal({thisRsk.channels(1:nCols).longName}, {firstChannels.longName}) || ...
                ~isequal({thisRsk.channels(1:nCols).units}, {firstChannels.units})
            error('%s: the data columns in %s do not match those in %s.', thisName, ...
                theseSegments(iSeg).sourceFile, theseSegments(1).sourceFile);
        end
        tstamps{iSeg} = thisRsk.data.tstamp;
        values{iSeg} = thisRsk.data.values;
    end

    % metadata comes from the first deployment
    joined = theseSegments(1).data;
    joined.data.tstamp = vertcat(tstamps{:});
    joined.data.values = vertcat(values{:});
    joined.data.sourceFile = source;
end


function selected = select_rows(joined, rows)
% Picks out rows of a joined instrument, whether it is a table or RSK struct.

if istable(joined)
    selected = joined(rows, :);
else
    selected = joined;
    selected.data.tstamp = joined.data.tstamp(rows);
    selected.data.values = joined.data.values(rows, :);
    selected.data.sourceFile = joined.data.sourceFile(rows);
end


function text = describe_rows(rows)
% Turns row numbers like [1 2 3 9 10] into the text "1-3, 9-10".

rows = rows(:);
blockStarts = rows([true; diff(rows) > 1]);
blockEnds = rows([diff(rows) > 1; true]);
blocks = compose('%d-%d', blockStarts, blockEnds);
isSingleRow = blockStarts == blockEnds;
blocks(isSingleRow) = compose('%d', blockStarts(isSingleRow));

maxShown = 10;
if numel(blocks) > maxShown
    text = sprintf('%s, and %d more blocks', ...
        strjoin(blocks(1:maxShown), ', '), numel(blocks) - maxShown);
else
    text = char(strjoin(blocks, ', '));
end


function answer = ask_yes_no(prompt)
% Asks a y/n question and returns true only for y.

answer = strcmpi(strtrim(input(prompt, 's')), 'y');


function T = instrument_table(joined, instrumentName)
% Puts one instrument into the output layout: DateTime, Instrument,
% SourceFile, then its data columns. RSK columns are labeled with units.

if istable(joined)
    dataType = 'table';
    timeColumn = intersect({'DateTime', 'UTC_Date___Time'}, joined.Properties.VariableNames);
    dataColumns = removevars(joined, [timeColumn, {'SourceFile'}]);
    source = joined.SourceFile;
else
    dataType = 'RSK struct';
    channels = joined.channels(1:size(joined.data.values, 2));
    headers = strcat({channels.longName}, ' (', {channels.units}, ')');
    dataColumns = array2table(joined.data.values, 'VariableNames', headers);
    source = joined.data.sourceFile;
end

t = get_time(struct('dataType', dataType, 'data', joined));
t.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
instrument = repmat(categorical({instrumentName}), numel(t), 1);
T = [table(t, instrument, source, 'VariableNames', ...
    {'DateTime', 'Instrument', 'SourceFile'}), dataColumns];


function csvTable = build_csv_table(combined)
% Stacks all instruments into one table, sorted in time. A channel that an
% instrument doesn't measure is NaN for that instrument's rows.

instruments = fieldnames(combined);
tables = cell(numel(instruments), 1);
allColumns = {};
for iInst = 1:numel(instruments)
    tables{iInst} = instrument_table(combined.(instruments{iInst}), instruments{iInst});
    allColumns = unique([allColumns, tables{iInst}.Properties.VariableNames], 'stable');
end

for iInst = 1:numel(instruments)
    missingColumns = setdiff(allColumns, tables{iInst}.Properties.VariableNames);
    for iCol = 1:numel(missingColumns)
        tables{iInst}.(missingColumns{iCol}) = NaN(height(tables{iInst}), 1);
    end
end

csvTable = sortrows(vertcat(tables{:}), 'DateTime');


function write_netcdf(combined, ncFile)
% Writes one NetCDF group per instrument, each with its own time dimension.

instruments = fieldnames(combined);
for iInst = 1:numel(instruments)
    T = instrument_table(combined.(instruments{iInst}), instruments{iInst});
    group = ['/', instruments{iInst}];
    dims = {[group, '/time'], height(T)};

    write_nc_variable(ncFile, [group, '/time'], dims, posixtime(T.DateTime), ...
        'Time', 'seconds since 1970-01-01 00:00:00');

    % store which file each row came from as a number, with the key alongside
    write_nc_variable(ncFile, [group, '/source_file_index'], dims, ...
        double(T.SourceFile), 'Index into the source_files attribute', '');
    ncwriteatt(ncFile, [group, '/source_file_index'], 'source_files', ...
        strjoin(categories(T.SourceFile), ', '));

    dataNames = setdiff(T.Properties.VariableNames, ...
        {'DateTime', 'Instrument', 'SourceFile'}, 'stable');
    for iCol = 1:numel(dataNames)
        header = dataNames{iCol};
        column = T.(header);
        units = '';

        if isdatetime(column)
            column = posixtime(column);
            units = 'seconds since 1970-01-01 00:00:00';
        elseif isduration(column)
            column = seconds(column);
            units = 'seconds';
        else
            unitText = regexp(header, '\((.*)\)$', 'tokens', 'once');
            if ~isempty(unitText)
                units = unitText{1};
            end
        end

        % NetCDF names can't hold every character, so make a simple name
        % and keep the original text in long_name
        ncName = matlab.lang.makeValidName(regexprep(header, ' \(.*\)$', ''));
        write_nc_variable(ncFile, [group, '/', ncName], dims, double(column), header, units);
    end
end


function write_nc_variable(ncFile, varPath, dims, values, longName, units)
% Creates one compressed NetCDF variable and writes its data and labels.

nccreate(ncFile, varPath, 'Dimensions', dims, 'Datatype', 'double', ...
    'Format', 'netcdf4', 'FillValue', NaN, 'DeflateLevel', 4);
ncwrite(ncFile, varPath, values);
ncwriteatt(ncFile, varPath, 'long_name', longName);
if ~isempty(units)
    ncwriteatt(ncFile, varPath, 'units', units);
end


function make_quicklook(combined, sensorType, titleText, pngFile)
% Plots each variable in its own panel, with one line per instrument. SoloT
% only has temperature, so it gets one panel per mooring instead.

instruments = fieldnames(combined);
switch lower(sensorType)
    case 'concerto'
        panelColumns = {'Salinity', 'Temperature', 'Dissolved O22'};
    case 'todo'
        panelColumns = {'Temperature', 'Dissolved Oxygen'};
    case 'duo'
        panelColumns = {'Temperature', 'Depth'};
    case 'seacat'
        panelColumns = {'Temperature', 'Salinity'};
    case 'ysi'
        panelColumns = {'Temp_C', 'Sal_ppt'};
    case 'minidot'
        panelColumns = {'Temperature', 'DissolvedOxygen'};
    case 'solo'
        panelColumns = {'Temperature'};
end

if strcmpi(sensorType, 'solo')
    panelTitles = unique(extractBefore(instruments, '_sn'), 'stable');
    panelMembers = cellfun(@(m) instruments(startsWith(instruments, [m, '_'])), ...
        panelTitles, 'UniformOutput', false);
    panelColumns = repmat(panelColumns, numel(panelTitles), 1);
else
    panelTitles = repmat({''}, numel(panelColumns), 1);
    panelMembers = repmat({instruments}, numel(panelColumns), 1);
end

% each line is thinned to at most this many points, to keep the plot
% readable and quick. This only affects the plot, not the saved data.
maxPoints = 20000;

% colors stay with the instrument from panel to panel
lineColors = {'#2a78d6', '#eb6834', '#1baf7a', '#eda100', '#e87ba4', '#008300', '#6250d6'};

nPanels = numel(panelColumns);
fig = figure('Color', 'w', 'Units', 'inches', 'Position', [1, 1, 11, 2.4*nPanels + 0.8]);
layout = tiledlayout(fig, nPanels, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(layout, titleText, 'Interpreter', 'none', 'FontSize', 13);

axesList = gobjects(nPanels, 1);
for iPanel = 1:nPanels
    ax = nexttile(layout);
    hold(ax, 'on');
    axesList(iPanel) = ax;
    members = panelMembers{iPanel};
    yLabelText = panelColumns{iPanel};

    for iMember = 1:numel(members)
        T = instrument_table(combined.(members{iMember}), members{iMember});
        headers = T.Properties.VariableNames;

        % RSK columns are named like "Temperature (°C)"
        column = find(strcmp(headers, panelColumns{iPanel}) | ...
            startsWith(headers, [panelColumns{iPanel}, ' (']), 1);
        if isempty(column)
            continue    % this instrument doesn't measure this variable
        end

        rows = 1:max(1, ceil(height(T)/maxPoints)):height(T);
        [plotTime, plotValues] = break_at_gaps(T.DateTime(rows), T{rows, column}, hours(6));
        plot(ax, plotTime, plotValues, 'Color', lineColors{iMember}, ...
            'LineWidth', 0.8, 'DisplayName', members{iMember});
        yLabelText = headers{column};
    end

    ylabel(ax, yLabelText, 'Interpreter', 'none');
    title(ax, panelTitles{iPanel}, 'Interpreter', 'none', 'FontWeight', 'normal');
    grid(ax, 'on');
    ax.GridColor = [0.75, 0.75, 0.72];
    box(ax, 'off');
    if numel(members) > 1
        legend(ax, 'Location', 'eastoutside', 'Interpreter', 'none', 'Box', 'off');
    end
end

linkaxes(axesList, 'x');
exportgraphics(fig, pngFile, 'Resolution', 300);


function [plotTime, plotValues] = break_at_gaps(t, values, maxGap)
% Adds a blank point wherever the time jumps by more than maxGap, so the
% plotted line stops at a gap instead of drawing straight across it.

newRow = (1:numel(t))' + cumsum([0; diff(t) > maxGap]);
plotTime = NaT(newRow(end), 1);
plotValues = NaN(newRow(end), 1);
plotTime(newRow) = t;
plotValues(newRow) = values;
