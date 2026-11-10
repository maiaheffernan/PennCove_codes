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
