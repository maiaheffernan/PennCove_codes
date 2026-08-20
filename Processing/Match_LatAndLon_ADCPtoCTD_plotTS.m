%%%% Finding the nearest lat/lon coordinates to each CTD cast %%%%

%%% Maia Heffernan, Jul 30 2026


clear all, close all

%% load in the ADCP and casting data

% ---- from June detail ----

    % ADCP_flood = load('Echo_ADCP_flood_cleaned_corrected.mat'); % flood
    % ADCP_ebb = load('Echo_ADCP_ebb_cleaned_corrected.mat'); % ebb
    % 
    % 
    % CTD_flood = load('Echo_CTD_24Jun2026_FloodTowYo_DataAndChannelsOnly_processed_L1.mat');
    % CTD_ebb = load('Echo_CTD_24Jun2026_EbbTowYo_DataAndChannelsOnly_processed_L1.mat');


% ---- from July detail ----

% ADCP_flood = 
% ADCP_ebb = 
% 
% CTD_flood = 
% CTD_ebb = 
%% find the ADCP timestamp that is closest to each ctd cast FLOOD

% --- flood ---

% 1. Concatenate ADCP time/lat/lon across all 8 laps
nLaps = numel(ADCP_flood.lapData);

adcp_time = [];
adcp_lat  = [];
adcp_lon  = [];

for i = 1:nLaps
    % Force everything to a row vector with (:)' so orientation 
    % (1xN vs Nx1) doesn't matter across fields/laps
    adcp_time = [adcp_time, ADCP_flood.lapData(i).time(:)'];
    adcp_lat  = [adcp_lat,  ADCP_flood.lapData(i).lat(:)'];
    adcp_lon  = [adcp_lon,  ADCP_flood.lapData(i).lon(:)'];
end

% Convert ADCP time (datenum) to datetime
adcp_datetime = datetime(adcp_time, 'ConvertFrom', 'datenum');


% 2. Loop over CTD casts
nCasts = numel(CTD_flood.data);

CTD_lat  = nan(nCasts, 1);
CTD_lon  = nan(nCasts, 1);
CTD_time = NaT(nCasts, 1);

for i = 1:nCasts
    ts = CTD_flood.data(i).tstamp;

    % Convert to datetime if it's still a datenum
    if isnumeric(ts)
        ts_dt = datetime(ts, 'ConvertFrom', 'datenum');
    else
        ts_dt = ts;  % already datetime
    end

    % First non-NaT entry
    validIdx = find(~isnat(ts_dt), 1, 'first');

    if isempty(validIdx)
        continue  % whole cast is NaT, skip (stays NaN/NaT)
    end

    castTime = ts_dt(validIdx);
    CTD_time(i) = castTime;

    % Closest ADCP timestamp
    [~, idx] = min(abs(adcp_datetime - castTime));

    CTD_lat(i) = adcp_lat(idx);
    CTD_lon(i) = adcp_lon(idx);

    CTD_flood.data(i).lat = CTD_lat(i);
    CTD_flood.data(i).lon = CTD_lon(i);
end


%% clear values for the ebb

clear nLaps adcp_time adcp_lat adcp_lon adcp_datetime nCasts CTD_lat CTD_lon CTD_time ts ts_dt validIdx castTime idx i



%% find the ADCP timestamp that is closest to each ctd cast Ebb

% -- ebb --

% 1. Concatenate ADCP time/lat/lon across all 8 laps
nLaps = numel(ADCP_ebb.lapData);

adcp_time = [];
adcp_lat  = [];
adcp_lon  = [];

for i = 1:nLaps
    % Force everything to a row vector with (:)' so orientation 
    % (1xN vs Nx1) doesn't matter across fields/laps
    adcp_time = [adcp_time, ADCP_ebb.lapData(i).time(:)'];
    adcp_lat  = [adcp_lat,  ADCP_ebb.lapData(i).lat(:)'];
    adcp_lon  = [adcp_lon,  ADCP_ebb.lapData(i).lon(:)'];
end

% Convert ADCP time (datenum) to datetime
adcp_datetime = datetime(adcp_time, 'ConvertFrom', 'datenum');


% 2. Loop over CTD casts
nCasts = numel(CTD_ebb.data);

CTD_lat  = nan(nCasts, 1);
CTD_lon  = nan(nCasts, 1);
CTD_time = NaT(nCasts, 1);

for i = 1:nCasts
    ts = CTD_ebb.data(i).tstamp;

    % Convert to datetime if it's still a datenum
    if isnumeric(ts)
        ts_dt = datetime(ts, 'ConvertFrom', 'datenum');
    else
        ts_dt = ts;  % already datetime
    end

    % First non-NaT entry
    validIdx = find(~isnat(ts_dt), 1, 'first');

    if isempty(validIdx)
        continue  % whole cast is NaT, skip (stays NaN/NaT)
    end

    castTime = ts_dt(validIdx);
    CTD_time(i) = castTime;

    % Closest ADCP timestamp
    [~, idx] = min(abs(adcp_datetime - castTime));

    CTD_lat(i) = adcp_lat(idx);
    CTD_lon(i) = adcp_lon(idx);

    CTD_ebb.data(i).lat = CTD_lat(i);
    CTD_ebb.data(i).lon = CTD_lon(i);
end



%% pull out the CTD casts that are closest to the moorings


% define moorings
moorings_locs = [
    48.229776, -122.641600; % WWS
    48.241762, -122.625453; % WWN
    48.235081, -122.670354; % LoveJoyN
    48.227576, -122.669771; % LovejoyS
    48.232424, -122.703108; % InnerN
    48.224669, -122.702241; % InnerS
    ];

% Mooring names
mooring_names = {'WWS', 'WWN', 'LoveJoyN', 'LovejoyS', 'InnerN', 'InnerS'};

nMoorings = size(moorings_locs, 1);

% Pull CTD lat/lon into simple vectors for easy indexing
CTD_lat_all_flood = [CTD_flood.data.lat]';
CTD_lon_all_flood = [CTD_flood.data.lon]';

nearest_cast_idx_flood = nan(nMoorings, 1);
nearest_cast_dist_km_flood = nan(nMoorings, 1);

for m = 1:nMoorings
    m_lat = moorings_locs(m, 1);
    m_lon = moorings_locs(m, 2);

    % Distance from this mooring to every CTD cast (haversine, in km)
    dist_km = haversine_km(m_lat, m_lon, CTD_lat_all_flood, CTD_lon_all_flood);

    [minDist, idx] = min(dist_km);

    nearest_cast_idx_flood(m) = idx;
    nearest_cast_dist_km_flood(m) = minDist;
end

% Display results
for m = 1:nMoorings
    fprintf('%s: nearest cast #%d, %.3f km away (lat=%.5f, lon=%.5f)\n', ...
        mooring_names{m}, nearest_cast_idx_flood(m), nearest_cast_dist_km_flood(m), ...
        CTD_lat_all_flood(nearest_cast_idx_flood(m)), CTD_lon_all_flood(nearest_cast_idx_flood(m)));
end

%% plot distances for flood 

figure; hold on; box on;

% Plot all CTD casts (light gray, for context)
plot(CTD_lon_all_flood, CTD_lat_all_flood, '.', 'Color', [0.7 0.7 0.7], ...
    'MarkerSize', 8, 'DisplayName', 'All CTD casts');

% Plot moorings
plot(moorings_locs(:,2), moorings_locs(:,1), '^', ...
    'MarkerSize', 10, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', ...
    'DisplayName', 'Moorings');

% Plot nearest cast to each mooring
plot(CTD_lon_all_flood(nearest_cast_idx_flood), CTD_lat_all_flood(nearest_cast_idx_flood), 'o', ...
    'MarkerSize', 10, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k', ...
    'DisplayName', 'Nearest cast');

% Draw a line connecting each mooring to its nearest cast
for m = 1:nMoorings
    plot([moorings_locs(m,2), CTD_lon_all_flood(nearest_cast_idx_flood(m))], ...
         [moorings_locs(m,1), CTD_lat_all_flood(nearest_cast_idx_flood(m))], ...
         'k--', 'HandleVisibility', 'off');
end

% Label mooring names
for m = 1:nMoorings
    text(moorings_locs(m,2), moorings_locs(m,1), ['  ' mooring_names{m}], ...
        'FontSize', 9, 'FontWeight', 'bold');
end

xlabel('Longitude');
ylabel('Latitude');
title('Mooring Locations and Nearest CTD Casts from the flood on June 24');
legend('Location', 'best');
axis equal;
grid on;


%% Do the same for the ebb
% Pull CTD lat/lon into simple vectors for easy indexing
CTD_lat_all_ebb = [CTD_ebb.data.lat]';
CTD_lon_all_ebb = [CTD_ebb.data.lon]';

nearest_cast_idx_ebb = nan(nMoorings, 1);
nearest_cast_dist_km_ebb = nan(nMoorings, 1);

for m = 1:nMoorings
    m_lat = moorings_locs(m, 1);
    m_lon = moorings_locs(m, 2);

    % Distance from this mooring to every CTD cast (haversine, in km)
    dist_km = haversine_km(m_lat, m_lon, CTD_lat_all_ebb, CTD_lon_all_ebb);

    [minDist, idx] = min(dist_km);

    nearest_cast_idx_ebb(m) = idx;
    nearest_cast_dist_km_ebb(m) = minDist;
end

% Display results
for m = 1:nMoorings
    fprintf('%s: nearest cast #%d, %.3f km away (lat=%.5f, lon=%.5f)\n', ...
        mooring_names{m}, nearest_cast_idx_ebb(m), nearest_cast_dist_km_ebb(m), ...
        CTD_lat_all_ebb(nearest_cast_idx_ebb(m)), CTD_lon_all_ebb(nearest_cast_idx_ebb(m)));
end

%% plot distances for flood 

figure; hold on; box on;

% Plot all CTD casts (light gray, for context)
plot(CTD_lon_all_ebb, CTD_lat_all_ebb, '.', 'Color', [0.7 0.7 0.7], ...
    'MarkerSize', 8, 'DisplayName', 'All CTD casts');

% Plot moorings
plot(moorings_locs(:,2), moorings_locs(:,1), '^', ...
    'MarkerSize', 10, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', ...
    'DisplayName', 'Moorings');

% Plot nearest cast to each mooring
plot(CTD_lon_all_ebb(nearest_cast_idx_ebb), CTD_lat_all_ebb(nearest_cast_idx_ebb), 'o', ...
    'MarkerSize', 10, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k', ...
    'DisplayName', 'Nearest cast');

% Draw a line connecting each mooring to its nearest cast
for m = 1:nMoorings
    plot([moorings_locs(m,2), CTD_lon_all_ebb(nearest_cast_idx_ebb(m))], ...
         [moorings_locs(m,1), CTD_lat_all_ebb(nearest_cast_idx_ebb(m))], ...
         'k--', 'HandleVisibility', 'off');
end

% Label mooring names
for m = 1:nMoorings
    text(moorings_locs(m,2), moorings_locs(m,1), ['  ' mooring_names{m}], ...
        'FontSize', 9, 'FontWeight', 'bold');
end

xlabel('Longitude');
ylabel('Latitude');
title('Mooring Locations and Nearest CTD Casts from the flood on June 24');
legend('Location', 'best');
axis equal;
grid on;



%% make a TS diagram colored by DO at every mooring location for both the flood and the tide

saveDir = '/Users/heffem3/Documents/GitHub/PennCove_codes/Figures/PECS2026';




% pull out salinity and temperature

% salinity is channel 8, temp channel 2, DO mg/L is channel 14

% Column indices into data.values
col_temp = 2;
col_sal  = 8;
col_DO   = 14;
col_seapress = 6;

% Common color axis for DO across all plots
allDO = [];
for m = 1:nMoorings
    allDO = [allDO; CTD_flood.data(nearest_cast_idx_flood(m)).values(:,col_DO)];
    allDO = [allDO; CTD_ebb.data(nearest_cast_idx_ebb(m)).values(:,col_DO)];
end
DO_clim = [min(allDO, [], 'omitnan'), max(allDO, [], 'omitnan')];

% Common T/S axis limits too, so all panels are directly comparable
allT = []; allS = [];
for m = 1:nMoorings
    allT = [allT; CTD_flood.data(nearest_cast_idx_flood(m)).values(:,col_temp)];
    allT = [allT; CTD_ebb.data(nearest_cast_idx_ebb(m)).values(:,col_temp)];
    allS = [allS; CTD_flood.data(nearest_cast_idx_flood(m)).values(:,col_sal)];
    allS = [allS; CTD_ebb.data(nearest_cast_idx_ebb(m)).values(:,col_sal)];
end
T_lim = [min(allT,[],'omitnan')-0.5, max(allT,[],'omitnan')+0.5];
S_lim = [min(allS,[],'omitnan')-0.5, max(allS,[],'omitnan')+0.5];




% === Individual TS diagrams, one figure per mooring per tide ===

for m = 1:nMoorings

    % ---- flood ----
    castIdx = nearest_cast_idx_flood(m);
    T  = CTD_flood.data(castIdx).values(:,col_temp);
    SP = CTD_flood.data(castIdx).values(:,col_sal);
    p  = CTD_flood.data(castIdx).values(:,col_seapress);
    DO = CTD_flood.data(castIdx).values(:,col_DO);
    castLat = CTD_flood.data(castIdx).lat;
    castLon = CTD_flood.data(castIdx).lon;

    fig = figure('Position',[100 100 600 500]);
    plot_TS_panel(SP, T, p, castLon, castLat, DO, DO_clim, ...
        sprintf('%s -- Flood', mooring_names{m}));
    saveas(fig, fullfile(saveDir, sprintf('TS_%s_flood.png', mooring_names{m})));
saveas(fig, fullfile(saveDir, sprintf('TS_%s_flood.fig', mooring_names{m})));

    % ---- ebb ----
    castIdx = nearest_cast_idx_ebb(m);
    T  = CTD_ebb.data(castIdx).values(:,col_temp);
    SP = CTD_ebb.data(castIdx).values(:,col_sal);
    p  = CTD_ebb.data(castIdx).values(:,col_seapress);
    DO = CTD_ebb.data(castIdx).values(:,col_DO);
    castLat = CTD_ebb.data(castIdx).lat;
    castLon = CTD_ebb.data(castIdx).lon;

    fig = figure('Position',[100 100 600 500]);
    plot_TS_panel(SP, T, p, castLon, castLat, DO, DO_clim, ...
        sprintf('%s -- Ebb', mooring_names{m}));
    saveas(fig, fullfile(saveDir, sprintf('TS_%s_ebb.png', mooring_names{m})));
saveas(fig, fullfile(saveDir, sprintf('TS_%s_ebb.fig', mooring_names{m})));

end


%% haversine distance function


function d = haversine_km(lat1, lon1, lat2, lon2)
    % Haversine great-circle distance in km
    % lat1/lon1 can be scalar, lat2/lon2 can be vectors (broadcasts)
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

%% plot TS panel function -- make separate!


function plot_TS_panel(SP, t, p, castLon, castLat, DO, DO_clim, panelTitle)
    % SP = practical salinity, t = in-situ temp, p = sea pressure (dbar)
    % castLon/castLat = single lon/lat value for this cast (for GSW conversion)

    hold on; box on;

    % --- Convert to Absolute Salinity / Conservative Temperature ---
    SA = gsw_SA_from_SP(SP, p, castLon, castLat);
    CT = gsw_CT_from_t(SA, t, p);

    % --- Background isopycnals (sigma0) ---
    SA_grid = linspace(min(SA,[],'omitnan')-0.5, max(SA,[],'omitnan')+0.5, 200);
    CT_grid = linspace(min(CT,[],'omitnan')-0.5, max(CT,[],'omitnan')+0.5, 200);
    [SA_mesh, CT_mesh] = meshgrid(SA_grid, CT_grid);
    sigma_mesh = gsw_sigma0(SA_mesh, CT_mesh);

    sigma_levels = floor(min(sigma_mesh(:))):1.0:ceil(max(sigma_mesh(:)));

    [c, h] = contour(SA_mesh, CT_mesh, sigma_mesh, sigma_levels, 'k-');
    clabel(c, h, 'FontSize', 7);

    % --- Scatter colored by DO, plotted in SA/CT space to match isopycnals ---
    scatter(SA, CT, 60, DO, 'filled');
    colormap(gca, cmocean('thermal'));
    clim(DO_clim); 
    cb = colorbar;
    ylabel(cb, 'DO (mg/L)');

    xlabel('Absolute Salinity (g/kg)');
    ylabel('Conservative Temperature (\circC)');
    title(panelTitle);
    
end