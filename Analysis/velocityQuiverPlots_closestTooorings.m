%% ========================================================================
%  Mooring-averaged velocity arrows from a continuous ADCP time series
%
%  Assumes ADCP is a flat struct with:
%     ADCP.lat, ADCP.lon, ADCP.time   -> 1xN (or Nx1)
%     ADCP.east, ADCP.north, ADCP.up  -> N x M   (time x depth)
%     ADCP.z                          -> 1xM     (depth bin centers, meters)
%     ADCP.depth                      -> 1xN     (bottom depth at each ping)
%
%  Strategy:
%   1. For each mooring, compute distance from the ship track to the
%      mooring at every time step.
%   2. Each time the ship passes near the mooring, the distance curve
%      dips to a local minimum ("a pass"). Use findpeaks on -distance
%      to automatically find every pass's closest-approach index.
%   3. At each pass's closest-approach index, grab east/north velocity
%      at the depth bin nearest 2 m ("top") and nearest 15 m ("bottom").
%   4. Average those values across all passes -> one top arrow and one
%      bottom arrow per mooring.
% ========================================================================



%% --- User-tunable parameters -------------------------------------------
 
% Max distance (in degrees, roughly lat/lon-scaled) for a point to count
% as "near" a mooring at all. Points farther than this are ignored even
% if they're a local minimum. ~0.0015 deg is roughly 150 m at these
% latitudes -- adjust based on how tight/loose your passes are.
% This is the DEFAULT used for any mooring not listed in
% max_dist_deg_override below.
max_dist_deg = 0.00500; % this is 500 meters
 
% Per-mooring overrides for max_dist_deg. Add an entry here for any
% mooring that needs a different search radius than the default above.
% ~0.0015 deg ~= 150 m; 500 m ~= 0.005 deg at these latitudes.
max_dist_deg_override = struct();
max_dist_deg_override.WWN = 0.01500;  % ~10000 m -- track passes farther from this mooring
 
% Minimum separation (in number of samples) required between two
% distinct passes, so a single pass isn't accidentally split into two
% peaks by noise. Set this based on your ADCP's sampling interval and
% roughly how long one pass near a mooring lasts.
% e.g., if ADCP.time is sampled every ~2 sec, and passes are well
% separated in time (minutes to hours apart), 60 samples (~2 min) is a
% safe minimum gap between distinct passes.
min_pass_separation_samples = 60;

% Target depths for "top" and "bottom" arrows (meters)
target_depth_top    = 2;
target_depth_bottom = 12;

%% --- Mooring locations ---------------------------------------------------

mooring_names = {'WWS', 'WWN', 'LoveJoyN', 'LovejoyS', 'InnerN', 'InnerS'};
moorings = [
    48.229776, -122.641600; % WWS
    48.241762, -122.625453; % WWN
    48.235081, -122.670354; % LoveJoyN
    48.227576, -122.669771; % LovejoyS
    48.232424, -122.703108; % InnerN
    48.224669, -122.702241; % InnerS
];

%% --- Find depth bin indices nearest the target depths --------------------

[~, iz_top]    = min(abs(z - target_depth_top));
[~, iz_bottom] = min(abs(z - target_depth_bottom));

fprintf('Using z = %.2f m for "top" (target %.1f m)\n', z(iz_top), target_depth_top);
fprintf('Using z = %.2f m for "bottom" (target %.1f m)\n', z(iz_bottom), target_depth_bottom);

%% --- For each mooring: find passes, average velocity at each pass -------

mooring_vels = struct();

lat = lat(:);
lon = lon(:);
time = time(:);

for m = 1:length(mooring_names)
    mname = mooring_names{m};

    % Use a per-mooring override if one is defined, otherwise the default
    if isfield(max_dist_deg_override, mname)
        this_max_dist_deg = max_dist_deg_override.(mname);
    else
        this_max_dist_deg = max_dist_deg;
    end

    % Distance from every ADCP ping to this mooring (lon compressed by
    % cos(lat) so distances are roughly isotropic in degrees)
    dist_deg = sqrt((lat - moorings(m,1)).^2 + ...
                     ((lon - moorings(m,2)) .* cosd(moorings(m,1))).^2);

    % Find local minima of distance = closest-approach point of each pass.
    [~, pass_idx] = findpeaks(-dist_deg, ...
        'MinPeakDistance', min_pass_separation_samples, ...
        'MinPeakHeight', -this_max_dist_deg);

    n_passes = length(pass_idx);

    if n_passes == 0
        warning('No passes found near mooring %s within max_dist_deg = %.5f. Consider increasing max_dist_deg.', ...
            mname, this_max_dist_deg);
        east_top    = NaN; north_top    = NaN;
        east_bottom = NaN; north_bottom = NaN;
    else
        east_top_vals    = east(pass_idx, iz_top);
        north_top_vals   = north(pass_idx, iz_top);
        east_bottom_vals = east(pass_idx, iz_bottom);
        north_bottom_vals = north(pass_idx, iz_bottom);

        east_top    = mean(east_top_vals, 'omitnan');
        north_top   = mean(north_top_vals, 'omitnan');
        east_bottom = mean(east_bottom_vals, 'omitnan');
        north_bottom = mean(north_bottom_vals, 'omitnan');
    end

    mooring_vels.(mname).n_passes          = n_passes;
    mooring_vels.(mname).pass_idx          = pass_idx;
    mooring_vels.(mname).pass_times        = time(pass_idx);
    mooring_vels.(mname).pass_dist_deg     = dist_deg(pass_idx);
    mooring_vels.(mname).east_top_mean     = east_top;
    mooring_vels.(mname).north_top_mean    = north_top;
    mooring_vels.(mname).east_bottom_mean  = east_bottom;
    mooring_vels.(mname).north_bottom_mean = north_bottom;

    fprintf('%-10s: %d pass(es) found\n', mname, n_passes);
end

%% ========================================================================
%  The plot
% ========================================================================

scale = 0.05;

top_color    = [0.0, 1, 1];
bottom_color = [0.85, 0.33, 0.10];
top_style    = '-';
bottom_style = '--';
linewidth    = 1.8;

% Per-mooring label offsets [dlat, dlon] in degrees -- tune by eye
label_offsets = struct();
label_offsets.WWS      = [0.001,  0.002];
label_offsets.WWN      = [0.001,  0.002];
label_offsets.LoveJoyN = [0.001,  0.002];
label_offsets.LovejoyS = [0.001,  0.002];
label_offsets.InnerN   = [0.001,  0.002];
label_offsets.InnerS   = [0.001,  0.002];

figure('Name', 'Mooring-averaged velocities', 'NumberTitle', 'off');

lat_buf = 0.01;
lon_buf = 0.015;
lat_lim = [min(moorings(:,1))-lat_buf, max(moorings(:,1))+lat_buf];
lon_lim = [min(moorings(:,2))-lon_buf, max(moorings(:,2))+lon_buf];

ax = geoaxes;
geobasemap(ax, 'satellite');
geolimits(ax, lat_lim, lon_lim);
hold(ax, 'on');

for m = 1:length(mooring_names)
    mname = mooring_names{m};
    lat_m = moorings(m, 1);
    lon_m = moorings(m, 2);

    u_top = mooring_vels.(mname).east_top_mean;
    v_top = mooring_vels.(mname).north_top_mean;
    u_bot = mooring_vels.(mname).east_bottom_mean;
    v_bot = mooring_vels.(mname).north_bottom_mean;

    dlat_top = v_top * scale;
    dlon_top = u_top * scale / cosd(lat_m);
    dlat_bot = v_bot * scale;
    dlon_bot = u_bot * scale / cosd(lat_m);

    if ~isnan(u_top)
        geo_quiver(lat_m, lon_m, dlat_top, dlon_top, top_color, top_style, linewidth);
    end
    if ~isnan(u_bot)
        geo_quiver(lat_m, lon_m, dlat_bot, dlon_bot, bottom_color, bottom_style, linewidth);
    end

    geoplot(ax, lat_m, lon_m, 'w.', 'MarkerSize', 8);
    offset = label_offsets.(mname);
    text(ax, lat_m + offset(1), lon_m + offset(2), mname, ...
        'FontSize', 8, 'Color', 'white', 'FontWeight', 'bold');
end

% --- Reference arrow ---
ref_speed = 0.10;  % m/s (10 cm/s) -- smaller reference so low velocities stay visible
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
legend([h_top_leg, h_bot_leg], ...
    {sprintf('%.0f m', z(iz_top)), sprintf('%.0f m', z(iz_bottom))}, ...
    'Location', 'northeast', 'TextColor', 'white', 'Color', [0.2 0.2 0.2]);

title(ax, 'Mooring-averaged water velocity (all passes)', ...
    'FontSize', 12, 'FontWeight', 'bold');

hold(ax, 'off');

%% ========================================================================
%  Local function: draw a quiver arrow on geoaxes
% ========================================================================

function h = geo_quiver(lat, lon, dlat, dlon, color, linestyle, linewidth)
    cos_lat = cosd(lat);

    h = geoplot([lat, lat+dlat], [lon, lon+dlon], ...
        'Color', color, 'LineStyle', linestyle, 'LineWidth', linewidth);

    arrow_length = sqrt(dlat^2 + (dlon * cos_lat)^2);
    head_size = arrow_length * 0.25;
    head_angle = pi/6;
    angle = atan2(dlat, dlon * cos_lat);

    tip_lat = lat + dlat;
    tip_lon = lon + dlon;

    left_lat  = tip_lat - head_size * sin(angle - head_angle);
    left_lon  = tip_lon - (head_size * cos(angle - head_angle)) / cos_lat;
    right_lat = tip_lat - head_size * sin(angle + head_angle);
    right_lon = tip_lon - (head_size * cos(angle + head_angle)) / cos_lat;

    geoplot([tip_lat, left_lat],  [tip_lon, left_lon],  ...
        'Color', color, 'LineStyle', linestyle, 'LineWidth', linewidth);
    geoplot([tip_lat, right_lat], [tip_lon, right_lon], ...
        'Color', color, 'LineStyle', linestyle, 'LineWidth', linewidth);
end