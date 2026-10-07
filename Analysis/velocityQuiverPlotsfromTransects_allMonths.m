%% ========================================================================
%  Mooring-averaged velocity arrows from a CONCATENATED multi-month ADCP
%  time series, with per-pass statistics.
%
%  This is a standalone version of the original single-month script. It:
%    0. Loads every monthly .mat file and concatenates them
%    1. Runs the original pass-finding / averaging logic (unchanged)
%    2. Adds per-pass statistics (std, SE, constancy, 95% ellipses)
%    3. Makes the original plot, plus optional uncertainty ellipses
%
%  Each monthly .mat file contains:
%     time   (Nx1)   lat, lon, depth (1xN)
%     east, north, up, error  (N x M, time x depth)
%     z      (1xM)   depth bin centers, meters
%     readme (char)
%
%  Strategy:
%   1. For each mooring, compute distance from the ship track to the
%      mooring at every time step.
%   2. Each time the ship passes near the mooring, the distance curve
%      dips to a local minimum ("a pass"). Use findpeaks on -distance
%      to automatically find every pass's closest-approach index.
%   3. At each pass's closest-approach index, grab east/north velocity
%      at the depth bin nearest 2 m ("top") and nearest 12 m ("bottom").
%   4. Average those values across all passes -> one top arrow and one
%      bottom arrow per mooring, and report the spread of the passes.
%
%  Requires: Signal Processing Toolbox (findpeaks), Mapping Toolbox (geoaxes)
% ========================================================================
clear;

%% ========================================================================
%  0. LOAD AND CONCATENATE THE MONTHLY FILES
% ========================================================================
data_dir     = '/Users/heffem3/Library/CloudStorage/GoogleDrive-heffem3@uw.edu/Shared drives/M2O2/Penn Cove 2026';    % <-- EDIT: folder holding the monthly .mat files
file_pattern = 'Echo_ADCP_*_flood_cleaned.mat';             % do ebb and flood seperately


files = dir(fullfile(data_dir, '**', file_pattern));
files = files(~[files.isdir]); 

if isempty(files)
    error('No files matching %s found in %s', file_pattern, data_dir);
end

time = []; lat = []; lon = []; depth = [];
east = []; north = []; up = []; err = [];
z_ref = [];
file_id = [];   % which file each ping came from (useful for monthly checks)

for k = 1:numel(files)
    S = load(fullfile(files(k).folder, files(k).name));

    % Sanity check: depth bins must be identical across months
    zk = S.z(:).';
    if isempty(z_ref)
        z_ref = zk;
    elseif ~isequal(size(zk), size(z_ref)) || max(abs(zk - z_ref)) > 1e-6
        error('Depth bins differ in %s -- need to interpolate onto a common grid.', ...
            files(k).name);
    end

    % Force time-like variables to columns, stack matrices along time (rows)
    time    = [time;    S.time(:)];    %#ok<AGROW>
    lat     = [lat;     S.lat(:)];     %#ok<AGROW>
    lon     = [lon;     S.lon(:)];     %#ok<AGROW>
    depth   = [depth;   S.depth(:)];   %#ok<AGROW>
    east    = [east;    S.east];       %#ok<AGROW>
    north   = [north;   S.north];      %#ok<AGROW>
    up      = [up;      S.up];         %#ok<AGROW>
    err     = [err;     S.error];      %#ok<AGROW>
    file_id = [file_id; k*ones(numel(S.time),1)]; %#ok<AGROW>

    fprintf('%-30s: %d pings\n', files(k).name, numel(S.time));
end
z = z_ref;

% Sort chronologically, then drop duplicate timestamps (file overlap)
[time, order] = sort(time);
lat = lat(order); lon = lon(order); depth = depth(order); file_id = file_id(order);
east = east(order,:); north = north(order,:); up = up(order,:); err = err(order,:);

[time, ia] = unique(time, 'stable');
lat = lat(ia); lon = lon(ia); depth = depth(ia); file_id = file_id(ia);
east = east(ia,:); north = north(ia,:); up = up(ia,:); err = err(ia,:);

fprintf('\nTotal: %d pings from %d files (%s to %s)\n\n', numel(time), numel(files), ...
    datestr(time(1)), datestr(time(end)));   % assumes time is MATLAB datenum

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
    48.242725, -122.64063; % WWN
    48.235082, -122.670354; % LoveJoyN
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
    end

    % Per-pass velocities (empty if n_passes == 0)
    u_top = east(pass_idx, iz_top);     v_top = north(pass_idx, iz_top);
    u_bot = east(pass_idx, iz_bottom);  v_bot = north(pass_idx, iz_bottom);

    % Per-pass statistics
    stats_top = vel_stats(u_top, v_top);
    stats_bot = vel_stats(u_bot, v_bot);

    mooring_vels.(mname).n_passes          = n_passes;
    mooring_vels.(mname).pass_idx          = pass_idx;
    mooring_vels.(mname).pass_times        = time(pass_idx);
    mooring_vels.(mname).pass_dist_deg     = dist_deg(pass_idx);
    mooring_vels.(mname).top               = stats_top;
    mooring_vels.(mname).bottom            = stats_bot;

    % Original field names, so the plotting code below is unchanged
    mooring_vels.(mname).east_top_mean     = stats_top.u_mean;
    mooring_vels.(mname).north_top_mean    = stats_top.v_mean;
    mooring_vels.(mname).east_bottom_mean  = stats_bot.u_mean;
    mooring_vels.(mname).north_bottom_mean = stats_bot.v_mean;

    % Per-pass table for inspecting individual passes (dist in approx. meters)
    mooring_vels.(mname).pass_table = table(time(pass_idx), file_id(pass_idx), ...
        dist_deg(pass_idx) * 111e3, u_top, v_top, u_bot, v_bot, ...
        'VariableNames', {'time','file','dist_m','u_top','v_top','u_bot','v_bot'});

    fprintf('%-10s: %d pass(es) found\n', mname, n_passes);
end

%% ========================================================================
%  Summary table of per-pass statistics
% ========================================================================
rows = {};
for m = 1:numel(mooring_names)
    mn = mooring_names{m};
    for d = {'top','bottom'}
        s = mooring_vels.(mn).(d{1});
        if strcmp(d{1}, 'top'), zz = z(iz_top); else, zz = z(iz_bottom); end
        rows(end+1,:) = {mn, zz, s.n, s.u_mean, s.v_mean, s.u_std, s.v_std, ...
                         s.u_se, s.v_se, hypot(s.u_mean, s.v_mean), ...
                         s.speed_mean, s.constancy}; %#ok<SAGROW>
    end
end
stats_table = cell2table(rows, 'VariableNames', {'mooring','z_m','N', ...
    'u_mean','v_mean','u_std','v_std','u_se','v_se', ...
    'vec_mean_speed','mean_speed','constancy'});
disp(stats_table)

% Optional: save results
writetable(stats_table, 'mooring_pass_stats_flood.csv');
save('mooring_vels_allmonths_flood.mat', 'mooring_vels', 'stats_table');

%% ========================================================================
%  The plot
% ========================================================================
scale = 0.05;
top_color    = [0.0, 1, 1];
bottom_color = [0.85, 0.33, 0.10];
top_style    = '-';
bottom_style = '--';
linewidth    = 1.8;

show_ellipses = true;   % 95% confidence ellipse of the mean at each arrow tip

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

    % Uncertainty ellipses (covariance of the MEAN = cov / n)
    if show_ellipses
        St = mooring_vels.(mname).top;
        Sb = mooring_vels.(mname).bottom;
        if St.n > 2
            draw_se_ellipse(ax, lat_m + dlat_top, lon_m + dlon_top, St.cov/St.n, scale, top_color);
        end
        if Sb.n > 2
            draw_se_ellipse(ax, lat_m + dlat_bot, lon_m + dlon_bot, Sb.cov/Sb.n, scale, bottom_color);
        end
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

title(ax, 'Mooring-averaged water velocity (all passes, all months)', ...
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

%% ========================================================================
%  Local function: per-pass velocity statistics
% ========================================================================
function s = vel_stats(u, v)
    ok = isfinite(u) & isfinite(v);
    u = u(ok); v = v(ok);
    n = numel(u);

    s = struct('n',n, 'u_mean',NaN, 'v_mean',NaN, 'u_std',NaN, 'v_std',NaN, ...
               'u_se',NaN, 'v_se',NaN, 'speed_mean',NaN, 'constancy',NaN, ...
               'cov',nan(2));
    if n == 0, return; end

    s.u_mean     = mean(u);
    s.v_mean     = mean(v);
    s.speed_mean = mean(hypot(u, v));                          % mean of individual speeds
    s.constancy  = hypot(s.u_mean, s.v_mean) / s.speed_mean;   % 1 = steady, ~0 = reversing

    if n > 1
        s.u_std = std(u);   s.v_std = std(v);
        s.u_se  = s.u_std / sqrt(n);
        s.v_se  = s.v_std / sqrt(n);
        s.cov   = cov([u v]);
    end
end

%% ========================================================================
%  Local function: 95% confidence ellipse for the mean velocity
% ========================================================================
function draw_se_ellipse(ax, lat0, lon0, C, scale, color)
    % Centered on the arrow tip. C should be cov/n (covariance of the mean).
    if any(isnan(C(:))), return; end
    k = sqrt(-2*log(0.05));                 % 95% for a 2-D Gaussian (~2.45)
    [V, D] = eig(C);
    th = linspace(0, 2*pi, 60);
    xy = k * V * sqrt(max(D,0)) * [cos(th); sin(th)];   % row 1 = u, row 2 = v (m/s)
    geoplot(ax, lat0 + xy(2,:)*scale, lon0 + xy(1,:)*scale/cosd(lat0), ...
        'Color', color, 'LineWidth', 1);
end