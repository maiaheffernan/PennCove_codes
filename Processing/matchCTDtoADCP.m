function [CTD_flood, CTD_ebb] = matchCTDtoADCP(ADCP_flood_file, ADCP_ebb_file, ...
                                                 CTD_flood_file, CTD_ebb_file, ...
                                                 label, outputFolder)
%MATCHCTDTOADCP Find nearest ADCP lat/lon for each CTD cast, plot tracks, and save results
%
%   [CTD_flood, CTD_ebb] = matchCTDtoADCP(ADCP_flood_file, ADCP_ebb_file, ...
%                                          CTD_flood_file, CTD_ebb_file, ...
%                                          label, outputFolder)
%
%   Inputs:
%       ADCP_flood_file  - path to flood ADCP .mat file
%       ADCP_ebb_file    - path to ebb ADCP .mat file
%       CTD_flood_file   - path to flood CTD .mat file
%       CTD_ebb_file     - path to ebb CTD .mat file
%       label            - string used to name outputs, e.g. '22Jul2026'
%       outputFolder     - folder to save the figure into
%
%   Outputs:
%       CTD_flood, CTD_ebb - structs with lat/lon added to each cast
%
%   Saves:
%       <outputFolder>/Echo_surveyTracks_<label>.png
%       Echo_CTD_<label>_flood_L2_withlatlon.mat
%       Echo_CTD_<label>_ebb_L2_withlatlon.mat



% Example call:
  % [CTD_flood, CTD_ebb] = matchCTDtoADCP( ...
  %     'Echo_ADCP_22Jul2026_flood_cleaned_corrected.mat', ...
  %     'Echo_ADCP_22Jul2026_ebb_cleaned_corrected.mat', ...
  %     'Echo_CTD_22Jul2026_flood_TowYo_DataAndChannelsOnly_processed_L1.mat', ...
  %     'Echo_CTD_21Jul2026_and_22Jul2026ebb_TowYo_DataAndChannelsOnly_processed_L1.mat', ...
  %     '22Jul2026', ...
  %     '/Users/heffem3/Documents/GitHub/PennCove_codes/Figures/TransectSurveys');

%% load in the ADCP and casting data

ADCP_flood = load(ADCP_flood_file);
ADCP_ebb   = load(ADCP_ebb_file);

CTD_ebb   = load(CTD_ebb_file);
CTD_flood = load(CTD_flood_file);


%% troubleshoot the error by printing hte file paths

ADCP_flood_file
ADCP_ebb_file
CTD_flood_file
CTD_ebb_file

%% find the ADCP timestamp closest to each CTD cast: FLOOD

CTD_flood = matchOneTide(ADCP_flood, CTD_flood);

%% find the ADCP timestamp closest to each CTD cast: EBB

CTD_ebb = matchOneTide(ADCP_ebb, CTD_ebb);

%% plot the tracks

figure('Visible', 'on'); clf;

s1 = subplot(2,1,1);
hold on
ce = nan(numel(CTD_ebb.data), 1);
for ii = 1:numel(CTD_ebb.data)
    ce(ii) = CTD_ebb.data(ii).tstamp(10,:);
    scatter(CTD_ebb.data(ii).lon, CTD_ebb.data(ii).lat, 10, ce(ii), 'filled');
end
colormap('parula');
cb = colorbar;
cb.TickLabels = datestr(cb.Ticks, 'mm/dd HH:MM');
ylabel(cb, 'Time (UTC)');
ylabel('Latitude')
xlabel('Longitude')
title([label ' CTD tracks'], 'Interpreter', 'none')
subtitle('Ebb')

s2 = subplot(2,1,2);
hold on
cf = nan(numel(CTD_flood.data), 1);
for iii = 1:numel(CTD_flood.data)
    cf(iii) = CTD_flood.data(iii).tstamp(10,:);
    scatter(CTD_flood.data(iii).lon, CTD_flood.data(iii).lat, 10, cf(iii), 'filled');
end
colormap('parula');
cb = colorbar;
cb.TickLabels = datestr(cb.Ticks, 'mm/dd HH:MM');
ylabel(cb, 'Time (UTC)');
ylabel('Latitude')
subtitle('Flood')

% save figure, named using the label
fileName = sprintf('Echo_surveyTracks_%s.png', label);
fullPath = fullfile(outputFolder, fileName);
saveas(gcf, fullPath);

%% Save out CTD lat/lon variables, named using the label

save(sprintf('Echo_CTD_%s_flood_L2_withlatlon.mat', label), 'CTD_flood');
save(sprintf('Echo_CTD_%s_ebb_L2_withlatlon.mat', label), 'CTD_ebb');

end


%% ---- helper: match one tide's CTD casts to nearest ADCP fix ----
function CTD = matchOneTide(ADCP, CTD)

if isfield(ADCP, 'lapData')
    % nested-by-lap structure
    nLaps = numel(ADCP.lapData);

    adcp_time = [];
    adcp_lat  = [];
    adcp_lon  = [];

    for i = 1:nLaps
        adcp_time = [adcp_time, ADCP.lapData(i).time(:)'];
        adcp_lat  = [adcp_lat,  ADCP.lapData(i).lat(:)'];
        adcp_lon  = [adcp_lon,  ADCP.lapData(i).lon(:)'];
    end
else
    % flat structure (time/lat/lon directly on ADCP)
    adcp_time = ADCP.time(:)';
    adcp_lat  = ADCP.lat(:)';
    adcp_lon  = ADCP.lon(:)';
end

adcp_datetime = datetime(adcp_time, 'ConvertFrom', 'datenum');

nCasts = numel(CTD.data);

CTD_lat  = nan(nCasts, 1);
CTD_lon  = nan(nCasts, 1);
CTD_time = NaT(nCasts, 1);

for i = 1:nCasts
    ts = CTD.data(i).tstamp;

    if isnumeric(ts)
        ts_dt = datetime(ts, 'ConvertFrom', 'datenum');
    else
        ts_dt = ts;
    end

    validIdx = find(~isnat(ts_dt), 1, 'first');

    if isempty(validIdx)
        fprintf('whole cast is NaT, skip idx %d\n', i);
        continue
    end

    castTime = ts_dt(validIdx);
    CTD_time(i) = castTime;

    [~, idx] = min(abs(adcp_datetime - castTime));

    CTD_lat(i) = adcp_lat(idx);
    CTD_lon(i) = adcp_lon(idx);

    CTD.data(i).lat = CTD_lat(i);
    CTD.data(i).lon = CTD_lon(i);
end

end


%% ---- haversine distance (unused in main body, kept for later use) ----
function d = haversine_km(lat1, lon1, lat2, lon2)
    R = 6371; % Earth radius in km

    lat1 = deg2rad(lat1);
    lon1 = deg2rad(lon1);
    lat2 = deg2rad(lat2);
    lon2 = deg2rad(lon2);

    dlat = lat2 - lat1;
    dlon = lon2 - lon1;

    a = sin(dlat/2).^2 + cos(lat1) .* cos(lat2) .* sin(dlon/2).^2;
    c = 2 * atan2(sqrt(a), sqrt(1-a));

    d = R * c;
end