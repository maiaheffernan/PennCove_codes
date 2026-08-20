%%% Plotting the salinity, temperature, and DO variables from transecting
%%% 

% Created by Maia Heffernan, August 2026


% To use this script, you first need to perform the following steps:
%   1) Clean the CTD data using the CastDataProcessing_RuskinSteps.m script
%       (located in the /Sensors/RBR_concerto directorty in PennCove_codes github),
% 
%   2) Clean the ADCP data using the TransectADCP_readin_andQuickLook.m script 
%       (located in the /Sensors/RDIworkhorse_ADCP.m in PennCove_codes github).
% 
%   3) After cleaning you will need to add the ADCP's lat and lon locations to
%       each CTD cast by matching up the timestamps. You can do this in the
%       findingCTD_latAndlons.m script (in the /Processing directory in github).

% Note that the ADCP data that was used to create this script was run
%    through the heading correction script, so the data is already separated
%    out into the individual transect lines in the structure. You will need to
%    do this separately if the ADCP data has not been separated into lines. 



clear all, close all

%% load in data

% CTD transect data

CTD_data_ebb = load('Echo_CTD_22Jul2026_ebb_L2_withlatlon.mat');                 %load('Echo_CTD_21Jul2026_and_22Jul2026ebb_TowYo_DataAndChannelsOnly_processed_L1.mat');

CTD_data_flood = load('Echo_CTD_22Jul2026_flood_L2_withlatlon.mat');                %load('Echo_CTD_22Jul2026_flood_TowYo_DataAndChannelsOnly_processed_L1.mat');

% ADCP transect data

ADCP_data_ebb = load('Echo_ADCP_22Jul2026_ebb_cleaned_corrected.mat'); % heading correction applied

ADCP_data_flood = load('Echo_ADCP_22Jul2026_flood_cleaned_corrected.mat'); % heading correction applied

%% Split up the CTD casts into the specific transect lines



tol = 30; % tolerance window in seconds for finding the closest CTD cast with ADCP reading

matchedCTD_ebb = struct('line', {}, 'casts', {}, 'nCasts', {});

% ---- Ebb ----

% pull out the line timestamps from the ADCP

for i = 1:length(ADCP_data_ebb.lapData)
    timestamps_ebb = ADCP_data_ebb.lapData(i).time; % Extract timestamps for the current transect line
    matches_ebb = []; % matched CTD casts for this line
    matchTimes_ebb = [];   % first valid timestamp for each matched CTD cast

    % -- find first timestep in each CTD cast -- %

    for j = 1:length(CTD_data_ebb.CTD_ebb.data)
        tstamps = CTD_data_ebb.CTD_ebb.data(j).tstamp;

        % find the first non-NaN timestamp in this CTD cast
        firstValidValue = NaN;
        for k = 1:length(tstamps)
            if ~isnan(tstamps(k))
                firstValidValue = tstamps(k);
                break;
            end
        end

        if isnan(firstValidValue)
            continue % skip casts with no valid timestamp at all
        end


      % -- find how close this cast's timestamp is to any ADCP time on this
      % line --


        minDiff = min(abs(timestamps_ebb - firstValidValue));

        if minDiff <= tol
            matches_ebb = [matches_ebb, CTD_data_ebb.CTD_ebb.data(j)]; 
            matchTimes_ebb = [matchTimes_ebb, firstValidValue];
        end
    end

    % -- store everything for this line as one struct entry --
    matchedCTD_ebb(i).line   = i;
    matchedCTD_ebb(i).casts  = matches_ebb;
    matchedCTD_ebb(i).castTimes = matchTimes_ebb;
    matchedCTD_ebb(i).nCasts = length(matches_ebb);
end

% --- clear the i, j, k tickers for the flood --- 
clear i j k
% ---------------------

% --- Flood ---


matchedCTD_flood = struct('line', {}, 'casts', {}, 'nCasts', {});


% pull out the line timestamps from the ADCP

for i = 1:length(ADCP_data_flood.lapData)
    timestamps_flood = ADCP_data_flood.lapData(i).time; % Extract timestamps for the current transect line
    matches_flood = []; % matched CTD casts for this line
    matchTimes_flood = [];   % first valid timestamp for each matched CTD cast

    % -- find first timestep in each CTD cast -- %

    for j = 1:length(CTD_data_flood.CTD_flood.data)
        tstamps_flood = CTD_data_flood.CTD_flood.data(j).tstamp;

        % find the first non-NaN timestamp in this CTD cast
        firstValidValue_flood = NaN;
        for k = 1:length(tstamps_flood)
            if ~isnan(tstamps_flood(k))
                firstValidValue_flood = tstamps_flood(k);
                break;
            end
        end

        if isnan(firstValidValue_flood)
            continue % skip casts with no valid timestamp at all
        end


      % -- find how close this cast's timestamp is to any ADCP time on this
      % line --


        minDiff = min(abs(timestamps_flood - firstValidValue_flood));

        if minDiff <= tol
            matches_flood = [matches_flood, CTD_data_flood.CTD_flood.data(j)]; 
            matchTimes_flood = [matchTimes_flood, firstValidValue_flood];
        end
    end

    % -- store everything for this line as one struct entry --
    matchedCTD_flood(i).line   = i;
    matchedCTD_flood(i).casts  = matches_flood;
    matchedCTD_flood(i).castTimes = matchTimes_flood;
    matchedCTD_flood(i).nCasts = length(matches_flood);
end


%% Plot the ebb transect timeseries with the transect line colored by time


cmap_sal = cmocean('haline');
cmap_temp = cmocean('thermal');
cmap_do = cmocean('oxy');


% column indices within the "values" matrix
col_temp  = 2;
col_depth = 7;
col_sal   = 8;
col_do    = 14;


% the ebb data has data from the previous two trips, so this is the first
% index number that has ONLY the casts from the 22 of July 2026 which is
% the day I want
startIdx = 36;


% plotting

for ii = 1:length(matchedCTD_ebb)
    casts     = matchedCTD_ebb(ii).casts(startIdx:end);
    castTimes = matchedCTD_ebb(ii).castTimes(startIdx:end);
    nCasts    = length(casts);

    if nCasts == 0
        continue % nothing to plot for this line
    end

    % --- preallocate matrices for easy calling in the plot ---
    nRows   = size(casts(1).values, 1); % 560
    salMat  = NaN(nRows, nCasts);
    tempMat = NaN(nRows, nCasts);
    doMat   = NaN(nRows, nCasts);
    lonVals = NaN(1, nCasts);
    latVals = NaN(1, nCasts);

    for m = 1:nCasts
        tempMat(:, m) = casts(m).values(:, col_temp);
        salMat(:, m)  = casts(m).values(:, col_sal);
        doMat(:, m)   = casts(m).values(:, col_do);
        lonVals(m)    = casts(m).lon;
        latVals(m)    = casts(m).lat;
    end

    depthVec = casts(1).values(:, col_depth); 

    % --- plot ---
    figure(ii)

    s1 = subplot(4,1,1);
    pcolor(castTimes, depthVec, tempMat); shading flat
    set(s1, 'YDir', 'reverse')
    colormap(s1, cmap_temp); colorbar
    ylabel('Depth (m)'); title(sprintf('Line %d: Temperature', ii))

    s2 = subplot(4,1,2);
    pcolor(castTimes, depthVec, salMat); shading flat
    set(s2, 'YDir', 'reverse')
    colormap(s2, cmap_sal); colorbar
    ylabel('Depth (m)'); title('Salinity')

    s3 = subplot(4,1,3);
    pcolor(castTimes, depthVec, doMat); shading flat
    set(s3, 'YDir', 'reverse')
    colormap(s3, cmap_do); colorbar
    ylabel('Depth (m)'); title('Dissolved Oxygen')

    s4 = subplot(4,1,4);
    scatter(lonVals, latVals, 60, castTimes, 'filled')
    colormap(s4, parula); colorbar
    xlabel('Longitude'); ylabel('Latitude'); title('Cast track (colored by time)')

end
%% plot the flood transect timeseries with the transect line colore by time

