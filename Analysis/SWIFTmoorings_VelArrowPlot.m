%%% Tidal flow at all the SWIFT moorings %%%

%%% Maia Heffernan, July 29, 2026 

% This script takes the velocites from all SWIFT signature data (once
% uploaded and cleaned) and plots velocity arrows at a surface and bottom
% bin at different tidal stages. 

clear all, close all

%% load in the SWIFT sig data from May to Jun

% this is coming from the MayJun 2026 period

SWIFT09_WWS = load('SWIFT09_SDcard_MayJun2026_SIG.mat');

SWIFT18_WWN = load('SWIFT18_SDcard_MayJun2026_SIG.mat');

SWIFT26_InN = load('SWIFT26_SDcard_MayJun2026_SIG.mat');

SWIFT27_LJS = load('SWIFT27_SDcard_MayJun2026_SIG.mat');

SWIFT28_LJN = load('SWIFT28_SDcard_MayJun2026_SIG.mat');

SWIFT29_InS = load('SWIFT29_SDcard_MayJun2026_SIG.mat');


% load in the tides data from May to June
MayJun_tide = load('DuoTD_data_InnerNorth_MaytoJun2026_240150_cleaned_L2.mat');
    % give it a datetime variable
    MayJun_tide.d_clean.Datetime = datetime(MayJun_tide.d_clean.tstamp, 'ConvertFrom', 'datenum');



%% Add datetimes to the structures

sigs = {SWIFT09_WWS, SWIFT18_WWN, SWIFT26_InN, SWIFT27_LJS, SWIFT28_LJN, SWIFT29_InS};

for i = 1:length(sigs)
    ThisSig = sigs{i};
    t_all_sig = [ThisSig.SIG.time]';
    dt_all_sig = datetime(t_all_sig, 'ConvertFrom', 'datenum');

    for j = 1:length(ThisSig.SIG)
        ThisSig.SIG(j).Datetime = dt_all_sig(j);
    end
    sigs{i} = ThisSig;   % write the modified struct back into the cell array
end

% push the modified structs back into their original variable names
SWIFT09_WWS = sigs{1};
SWIFT18_WWN = sigs{2};
SWIFT26_InN = sigs{3};
SWIFT27_LJS = sigs{4};
SWIFT28_LJN = sigs{5};
SWIFT29_InS = sigs{6};

clear dt_all_sig t_all_sig


%% Setting up variables for plotting

% removing the bad data point from SWIFT 29
allDT = [sigs{6}.SIG.Datetime]';   % concatenate into a proper array
badIdxs = find(allDT < datetime(2020,1,1));
disp(badIdxs)
disp(allDT(badIdxs))
disp([sigs{6}.SIG(badIdxs).time]) %241 shows 28-Jan-1931 04:16:17, or 7.0531e+05


badIdx = 241;
sigs{6}.SIG(badIdx) = [];

    % verify it's good:
    
    allDT = [sigs{6}.SIG.Datetime]';
    fprintf('SWIFT29 InS: %s to %s\n', min(allDT), max(allDT));

% make eta the true tidal height
MayJun_tide.d_clean.eta = [MayJun_tide.d_clean.values(:,2)] - mean([MayJun_tide.d_clean.values(:,2)], 'omitnan');
sigNames = {'SWIFT09 WWS', 'SWIFT18 WWN', 'SWIFT26 InN', 'SWIFT27 LJS', 'SWIFT28 LJN', 'SWIFT29 InS'};

%% timeseries plot

figure(1); clf;
nTiles = length(sigs) + 1; 
t = tiledlayout(nTiles, 1, 'TileSpacing','compact', 'Padding','compact');

s1 = nexttile;
    plot(MayJun_tide.d_clean.Datetime, MayJun_tide.d_clean.eta, 'k.', 'MarkerSize', 5);
    ylabel('SSH (m)')

s = gobjects(1, nTiles); 
s(1) = s1;

for ii = 1:length(sigs)
    ThisSig = sigs{ii};
    SIG =  ThisSig.SIG;
    plotTime = [SIG.Datetime]';
    plotZ = SIG(1).profile.z(:);
    u_cells = arrayfun(@(row) row.profile.u(:)', SIG, 'UniformOutput', false);
    u_mat = vertcat(u_cells{:});

    s(ii+1) = nexttile;
        pcolor(plotTime, plotZ, u_mat');
        shading flat
        set(gca, 'YDir', 'reverse')
        colormap(cmocean('balance'))
        clim([-0.5 0.5])
        ylabel('Depth (m)')
        xlabel('Time')
        subtitle(sprintf('%s', sigNames{ii}))
        set(gca, 'Color', [0.7 0.7 0.7]);
end

% --- single colorbar attached to the whole layout, not one axes ---
c = colorbar(s(end));
c.Label.String = 'East/west velocity (m/s)';
c.Layout.Tile = 'east';   % spans the full height of the tiledlayout

linkaxes(s, 'x')
linkaxes(s(2:6+1), 'y')


xticks_common = datetime(2026,5,27):days(7):datetime(2026,6,23);
set(s, 'XTick', xticks_common)



%% choose a top and bottom bin and flood/ebb timestep to plot for the arrows

% datetimes where all the data is good:06 June 2026 at 01:00:06 to 06 June 2026 at 15:00:06

% Define the time range for plotting arrows
startTime = datetime(2026, 6, 6, 1, 0, 6);
endTime = datetime(2026, 6, 6, 15, 0, 6);

% Extract the relevant data for the specified time range
    % validIdx = find([sigs{6}.SIG.Datetime] >= startTime & [sigs{6}.SIG.Datetime] <= endTime);
    % validData = sigs{6}.SIG(validIdx);

% plot the data only at that time block to see it 

figure(2); clf;

nTiles = length(sigs) + 1; 
t = tiledlayout(nTiles, 1, 'TileSpacing','compact', 'Padding','compact');

s1 = nexttile;
    plot(MayJun_tide.d_clean.Datetime, MayJun_tide.d_clean.eta, 'k.', 'MarkerSize', 5);
    ylabel('SSH (m)')

s = gobjects(1, nTiles); 
s(1) = s1;

for ii = 1:length(sigs)
    ThisSig = sigs{ii};
    SIG =  ThisSig.SIG;
    plotTime = [SIG.Datetime]';
    plotZ = SIG(1).profile.z(:);
    u_cells = arrayfun(@(row) row.profile.u(:)', SIG, 'UniformOutput', false);
    u_mat = vertcat(u_cells{:});

    s(ii+1) = nexttile;
        pcolor(plotTime, plotZ, u_mat');
        shading flat
        set(gca, 'YDir', 'reverse')
        colormap(cmocean('balance'))
        clim([-0.5 0.5])
        ylabel('Depth (m)')
        xlabel('Time')
        subtitle(sprintf('%s', sigNames{ii}))
        set(gca, 'Color', [0.7 0.7 0.7]);
end

% --- single colorbar attached to the whole layout, not one axes ---
c = colorbar(s(end));
c.Label.String = 'East/west velocity (m/s)';
c.Layout.Tile = 'east';   % spans the full height of the tiledlayout

linkaxes(s, 'x')
linkaxes(s(2:6+1), 'y')

xlim(s,[startTime endTime])


% I want to pull from 06 June 2026 at 01:00:06 to 06 June 2026 at 09:00:06
% because this is where there is good data at all SWIFTs and is close to the
% peak flood and peak ebb. This is during a neap tidal cycle, though.

%% pulling out the data subset
% pull out the Datetimes and their indices from each SWIFT that are closest to 06 June 2026 
% at 01:00:06 and 06 June 2026 at 09:00:06

% preallocate storage
idxStart_all = zeros(length(sigs),1);
idxEnd_all   = zeros(length(sigs),1);
validData_all = cell(length(sigs),1);

for iv = 1:length(sigs)
    allDT = [sigs{iv}.SIG.Datetime]';   % concatenate into a proper array
    
    [~, idxStart] = min(abs(allDT - startTime));
    [~, idxEnd]   = min(abs(allDT - endTime));
    
    idxStart_all(iv) = idxStart;
    idxEnd_all(iv)   = idxEnd;
    
    validIdx = idxStart:idxEnd;
    validData_all{iv} = sigs{iv}.SIG(validIdx);
    
    fprintf('%s: rows %d to %d (%s to %s)\n', sigNames{iv}, idxStart, idxEnd, ...
        allDT(idxStart), allDT(idxEnd));
end



%% get the bins for those timestamps

% I want the bins at 2.3 and 19.3 m depths. These are in the z matrix at 4
% and 38

% Define the depth bins for the specified depths
depthBins = [2.3, 19.3]; 
depthIndices = [4, 38];  % Indices corresponding to the depth bins in the z matrix



%% load in the shape file that Kate sent for the Penn Cove


%% plot the arrows on the shape file


% Mooring coordinates and names
mooring_names = {'WWS', 'WWN', 'LoveJoyN', 'LovejoyS', 'InnerN', 'InnerS'};
moorings = [
    48.229776, -122.641600;
    48.241762, -122.625453;
    48.235081, -122.670354;
    48.227576, -122.669771;
    48.232424, -122.703108;
    48.224669, -122.702241;
];

% --- Explicit mapping from sigs/sigNames order to mooring_names ---

sig2mooring = containers.Map(...
    {'SWIFT09 WWS','SWIFT18 WWN','SWIFT26 InN','SWIFT27 LJS','SWIFT28 LJN','SWIFT29 InS'}, ...
    {'WWS','WWN','InnerN','LovejoyS','LoveJoyN','InnerS'});

% --- Depth bins for top/bottom ---
depthIndices = [4, 38];     % [top, bottom] bin indices into profile.z
% depthBins = [2.3, 19.3];  % corresponding depths (m), for reference/labeling

% --- Extract top/bottom u,v at startTime and endTime for each SWIFT ---
times = {'startTime', 'endTime'};
timeLabels = {'Flood', 'Ebb'};

vel_data = struct();
for iv = 1:length(sigs)
    mname = sig2mooring(sigNames{iv});

    startStruct = validData_all{iv}(1);     % first row = closest to startTime
    endStruct   = validData_all{iv}(end);   % last row = closest to endTime

    vel_data.startTime.(mname).u_top    = startStruct.profile.u(depthIndices(1));
    vel_data.startTime.(mname).v_top    = startStruct.profile.v(depthIndices(1));
    vel_data.startTime.(mname).u_bottom = startStruct.profile.u(depthIndices(2));
    vel_data.startTime.(mname).v_bottom = startStruct.profile.v(depthIndices(2));

    vel_data.endTime.(mname).u_top    = endStruct.profile.u(depthIndices(1));
    vel_data.endTime.(mname).v_top    = endStruct.profile.v(depthIndices(1));
    vel_data.endTime.(mname).u_bottom = endStruct.profile.u(depthIndices(2));
    vel_data.endTime.(mname).v_bottom = endStruct.profile.v(depthIndices(2));
end

% --- Quiver scale factor ---
scale = 0.05;
top_color    = [0.18, 0.49, 0.80];
bottom_color = [0.85, 0.33, 0.10];
top_style    = '-';
bottom_style = '--';
linewidth    = 1.8;

% Per-mooring label offsets [dlat, dlon] in degrees 
label_offsets = struct();
label_offsets.WWS      = [0.001,  0.002];
label_offsets.WWN      = [0.001,  0.002];
label_offsets.LoveJoyN = [0.001,  0.002];
label_offsets.LovejoyS = [0.001,  0.002];
label_offsets.InnerN   = [0.001,  0.002];
label_offsets.InnerS   = [0.001,  0.002];

for i = 1:length(times)
    figure('Name', timeLabels{i}, 'NumberTitle', 'off');

    lat_buf = 0.01;
    lon_buf = 0.015;
    lat_lim = [min(moorings(:,1))-lat_buf, max(moorings(:,1))+lat_buf];
    lon_lim = [min(moorings(:,2))-lon_buf, max(moorings(:,2))+lon_buf];

    ax = geoaxes;
    geobasemap(ax, 'topographic');  
    geolimits(ax, lat_lim, lon_lim);
    hold(ax, 'on');

    for m = 1:length(mooring_names)
        mname = mooring_names{m};
        lat_m = moorings(m, 1);
        lon_m = moorings(m, 2);

        u_top = vel_data.(times{i}).(mname).u_top;
        v_top = vel_data.(times{i}).(mname).v_top;
        u_bot = vel_data.(times{i}).(mname).u_bottom;
        v_bot = vel_data.(times{i}).(mname).v_bottom;

        dlat_top = v_top * scale;
        dlon_top = u_top * scale / cosd(lat_m);
        dlat_bot = v_bot * scale;
        dlon_bot = u_bot * scale / cosd(lat_m);

        geo_quiver(lat_m, lon_m, dlat_top, dlon_top, top_color,    top_style,    linewidth);
        geo_quiver(lat_m, lon_m, dlat_bot, dlon_bot, bottom_color, bottom_style, linewidth);
        geoplot(ax, lat_m, lon_m, 'w.', 'MarkerSize', 8);

        offset = label_offsets.(mname);
        text(ax, lat_m + offset(1), lon_m + offset(2), mname, ...
            'FontSize', 8, 'Color', 'white', 'FontWeight', 'bold');
    end

    % --- Reference arrow ---
    ref_speed = 0.5;
    ref_lat = lat_lim(1) + 0.003;
    ref_lon = lon_lim(1) + 0.003;
    geo_quiver(ref_lat, ref_lon, 0, ref_speed * scale / cosd(ref_lat), ...
        'white', '-', 2);
    text(ax, ref_lat, ref_lon + ref_speed * scale / cosd(ref_lat) * 1.3, ...
        sprintf('%.1f m/s', ref_speed), ...
        'Color', 'white', 'FontSize', 8, 'FontWeight', 'bold');

    % --- Legend ---
    h_top_leg = geoplot(ax, NaN, NaN, 'Color', top_color, ...
        'LineStyle', top_style, 'LineWidth', linewidth);
    h_bot_leg = geoplot(ax, NaN, NaN, 'Color', bottom_color, ...
        'LineStyle', bottom_style, 'LineWidth', linewidth);
    legend([h_top_leg, h_bot_leg], {'2m depth', '19m depth'}, ...
        'Location', 'northeast', 'TextColor', 'white', 'Color', [0.2 0.2 0.2]);

    title(ax, sprintf('Water Velocity — %s', timeLabels{i}), ...
        'FontSize', 12, 'FontWeight', 'bold');

    hold(ax, 'off');
end

%% Using the .fig I have for Penn Cove

fig = openfig('PennCove_UTM_Map.fig');
ax = gca;   
disp(class(ax))



%% plotting...

% convert mooring coordinates from lat/lon to UTM

utmstruct = defaultm('utm');
utmstruct.zone = '10N';
utmstruct.geoid = wgs84Ellipsoid;
utmstruct = defaultm(utmstruct);

[mooring_easting, mooring_northing] = projfwd(utmstruct, moorings(:,1), moorings(:,2));

% --- Quiver scale factor: tune ---
scale = 2000;
top_color    = '#72e1e1';
bottom_color = '#dd4124';
top_style    = '-';
bottom_style = '-';
linewidth    = 2.5;

% Per-mooring label offsets [dEasting, dNorthing] in METERS — tune by eye
label_offsets = struct();
label_offsets.WWS      = [100, 100];
label_offsets.WWN      = [100, 100];
label_offsets.LoveJoyN = [100, 100];
label_offsets.LovejoyS = [100, 100];
label_offsets.InnerN   = [100, 100];
label_offsets.InnerS   = [100, 100];

for i = 1:length(times)
    fig = openfig('PennCove_UTM_Map.fig');   
    set(fig, 'Name', timeLabels{i}, 'NumberTitle', 'off');
    ax = gca;
    hold(ax, 'on');

    for m = 1:length(mooring_names)
        mname = mooring_names{m};
        e_m = mooring_easting(m);
        n_m = mooring_northing(m);

        u_top = vel_data.(times{i}).(mname).u_top;
        v_top = vel_data.(times{i}).(mname).v_top;
        u_bot = vel_data.(times{i}).(mname).u_bottom;
        v_bot = vel_data.(times{i}).(mname).v_bottom;

        quiver(ax, e_m, n_m, u_top*scale, v_top*scale, 0, ...
            'Color', top_color, 'LineWidth', linewidth, 'LineStyle', top_style);
        quiver(ax, e_m, n_m, u_bot*scale, v_bot*scale, 0, ...
            'Color', bottom_color, 'LineWidth', linewidth, 'LineStyle', bottom_style);

        plot(ax, e_m, n_m, 'w.', 'MarkerSize', 8);

        offset = label_offsets.(mname);
        text(ax, e_m + offset(1), n_m + offset(2), mname, ...
            'FontSize', 8, 'Color', 'white', 'FontWeight', 'bold');
    end

    % --- Reference arrow ---
    ref_speed = 0.5;
    ref_e = max(ax.XLim) - 5000;   % adjust padding in meters as needed
    ref_n = max(ax.YLim) - 500;
    quiver(ax, ref_e, ref_n, 0, ref_speed*scale, 0, 'Color', 'white', 'LineWidth', 2);
    text(ax, ref_e + 100, ref_n + ref_speed*scale*0.3, sprintf('%.1f m/s', ref_speed), ...
        'Color', 'white', 'FontSize', 8, 'FontWeight', 'bold');

    % --- Legend ---
    h_top_leg = plot(ax, NaN, NaN, 'Color', top_color, 'LineStyle', top_style, 'LineWidth', linewidth);
    h_bot_leg = plot(ax, NaN, NaN, 'Color', bottom_color, 'LineStyle', bottom_style, 'LineWidth', linewidth);
    legend([h_top_leg, h_bot_leg], {'Top (2.3 m)', 'Bottom (19.3 m)'}, ...
        'Location', 'northeast', 'TextColor', 'white', 'Color', [0.2 0.2 0.2]);

    title(ax, sprintf('Water Velocity — %s', timeLabels{i}), 'FontSize', 12, 'FontWeight', 'bold');

    hold(ax, 'off');
end
%% Helper function to draw a quiver arrow on geoaxes


function h = geo_quiver(lat, lon, dlat, dlon, color, linestyle, linewidth)
    % Correct for lon compression at this latitude so arrowhead looks symmetric
    cos_lat = cosd(lat);

    % Shaft
    h = geoplot([lat, lat+dlat], [lon, lon+dlon], ...
        'Color', color, 'LineStyle', linestyle, 'LineWidth', linewidth);

    % Arrow length in aspect-corrected space
    arrow_length = sqrt(dlat^2 + (dlon * cos_lat)^2);

    % Compute arrow direction in aspect-corrected space
    head_size = arrow_length * 0.25;  % 25% of shaft length
    head_angle = pi/6;   % 30 degree spread
    angle = atan2(dlat, dlon * cos_lat);

    tip_lat = lat + dlat;
    tip_lon = lon + dlon;

    % Back-convert arrowhead legs from corrected space to lat/lon
    left_lat  = tip_lat - head_size * sin(angle - head_angle);
    left_lon  = tip_lon - (head_size * cos(angle - head_angle)) / cos_lat;
    right_lat = tip_lat - head_size * sin(angle + head_angle);
    right_lon = tip_lon - (head_size * cos(angle + head_angle)) / cos_lat;

    geoplot([tip_lat, left_lat],  [tip_lon, left_lon],  ...
        'Color', color, 'LineStyle', linestyle, 'LineWidth', linewidth);
    geoplot([tip_lat, right_lat], [tip_lon, right_lon], ...
        'Color', color, 'LineStyle', linestyle, 'LineWidth', linewidth);
end