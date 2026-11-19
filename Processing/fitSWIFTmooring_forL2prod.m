function fitSWIFTmooring_forL2prod(data_dir)

% This function was originally created by Malcolm LeClair to fit the watch circle of each SWIFT mooring
% for its final deployment period using the telemetry data. This original version is on the SASLabGroup Github site.
% Here, Maia Heffernan has modified it to be used with the L2 SWIFt data products.
%
%
% Fit watch circle of each SWIFT mooring over its final deployment period.
% Mask to t >= start of final deployment (set per buoy in header), project to
% local ENU about the median, Kasa circle fit, plot points + circle + center
% with a position table; print positions to the command window.
%
%   fitSWIFTmooring('/tmp/SWIFT_22_23_24_20261001T000001_now')
%
% data_dir holds SWIFTxx_telemetry.mat files (see pullfitSWIFTmooring.m)

% --- edit for each deployment ---
% first fix of final deployment (UTC)
% Trim off anything before the actual deployment. 
%
% In Maia's version, this uses the same starttime value that is used for
% the sensors on the mooring each month.
% Each entry is [start end] (UTC datenum); the end time uses the same
% endtime value that is used for the sensors on the mooring each month.
deploy_start = containers.Map( ...
    {'SWIFT26', 'SWIFT27', 'SWIFT28', 'SWIFT29'}, ...
    {[datenum(2026, 9, 24, 19, 30, 0), datenum(2026, 10, 20, 14, 30, 0)], ...
     [datenum(2026, 9, 24, 19, 30, 0), datenum(2026, 10, 20, 14, 30, 0)], ...
     [datenum(2026, 9, 24, 19, 30, 0), datenum(2026, 10, 20, 14, 30, 0)], ...
     [datenum(2026, 9, 24, 19, 30, 0), datenum(2026, 10, 20, 14, 30, 0)]});

% define a "bounding box" that limits the lat and lon positions for each SWIFT-- this is a Maia add.
% The lat and lon values are based on the initial anchor positions in the instrumentation spreadsheet. 
% The third value in each key in the container is the radius for the mooring. This is based on the largest
% watch circle based on the line length and also has a 20m additional allowance to account for slight deivations in
% the true deployment lat lon each month. Our deployments were almost right on top of each other, but there were 
% slight differences, so this is hopefully enough of a buffer for that. This can be checked in the final plot from the 
% function. If it looks liek the watch circles get cut off then these radius values need to be extended.  

anchor_pos = containers.Map( ...
    {'SWIFT26', 'SWIFT27', 'SWIFT28', 'SWIFT29'}, ...
    {[48.232424 -122.703108 88], [48.227576 -122.669771 96], [48.235082 -122.670354 120], [48.224669 -122.702241 80]});



% --------------------------------
%%%%%% REMOVE THIS BEFORE RUNNING FUNCTION %%%%%%%
%data_dir = '/Users/heffem3/Desktop/M2O2/SWIFTs/FullDatasets/SepOct2026/'
%%%%%%%%%%%%%
mat_files = dir(fullfile(data_dir, '**', 'SWIFT*_SDcard_*_L2.mat'));
% only buoys with a deploy start above (e.g. drops SWIFT26, not moored)
mat_files = mat_files(isKey(deploy_start, extractBefore({mat_files.name}, '_'))); % now matches the key in deploy_start
wgs84 = wgs84Ellipsoid('meter');

figure('Color', 'w');
map_ax = geoaxes;
geobasemap(map_ax, 'satellite');
hold(map_ax, 'on');
colors = lines(numel(mat_files));

n_swift = numel(mat_files);
swift_id = strings(n_swift, 1);
center_lat = nan(n_swift, 1); center_lon = center_lat; radius_m = center_lat;
rms_residual = center_lat; n_used = center_lat; n_total = center_lat; start_time = center_lat;
%
for i = 1:n_swift
    swift_id(i) = extractBefore(mat_files(i).name, '_'); % this now matches the key in deploy_start
    telem = load(fullfile(mat_files(i).folder, mat_files(i).name));
    lat = [telem.SWIFT.lat]'; lon = [telem.SWIFT.lon]'; time = [telem.SWIFT.time]';
    valid = isfinite(lat) & isfinite(lon);
    n_total(i) = sum(valid);

    deploy_window = deploy_start(char(swift_id(i)));
    start_time(i) = deploy_window(1);
    in_window = valid & time >= deploy_window(1) & time <= deploy_window(2);

    % keep only points within the allowed radius of the known anchor position-- Maia addition, 11/18
    anchor = anchor_pos(char(swift_id(i)));
    [east_anchor, north_anchor] = geodetic2enu(lat, lon, 0, anchor(1), anchor(2), 0, wgs84);
    in_box = hypot(east_anchor, north_anchor) <= anchor(3);

    in_deploy = in_window & in_box;
    lat = lat(in_deploy); lon = lon(in_deploy); time = time(in_deploy);
    n_used(i) = sum(in_deploy);

    ref_lat = median(lat); ref_lon = median(lon);
    [east, north] = geodetic2enu(lat, lon, 0, ref_lat, ref_lon, 0, wgs84);
    % Fit the center of the circle, it this is noisy you could do ransac, or if dragging break up the records  
    circle = fit_circle_kasa(east, north);
    radius_m(i) = circle(3);
    rms_residual(i) = sqrt(mean((hypot(east - circle(1), north - circle(2)) - circle(3)).^2));

    [center_lat(i), center_lon(i)] = enu2geodetic(circle(1), circle(2), 0, ref_lat, ref_lon, 0, wgs84);
    theta = linspace(0, 2*pi, 361);
    [circle_lat, circle_lon] = enu2geodetic(circle(1) + circle(3)*cos(theta), circle(2) + circle(3)*sin(theta), 0, ref_lat, ref_lon, 0, wgs84);

    geoscatter(map_ax, lat, lon, 8, colors(i,:), 'filled', 'MarkerFaceAlpha', 0.2, 'HandleVisibility', 'off');
    geoplot(map_ax, circle_lat, circle_lon, '-', 'Color', colors(i,:), 'LineWidth', 1.5, 'HandleVisibility', 'off');
    geoscatter(map_ax, center_lat(i), center_lon(i), 80, colors(i,:), 'o', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    [~, last] = max(time);
    last_str = "last fix " + string(datestr(time(last), 'yyyy-mm-dd HH:MM')) + " UTC";
    if is_stale(time(last))
        geoscatter(map_ax, lat(last), lon(last), 40, colors(i,:), 'o', 'filled', 'MarkerEdgeColor', 'w', ...
            'DisplayName', swift_id(i) + "  \color{red}" + last_str);
    else
        geoscatter(map_ax, lat(last), lon(last), 400, colors(i,:), 'p', 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 1.5, ...
            'DisplayName', swift_id(i) + "  " + last_str);
    end
    text(map_ax, center_lat(i), center_lon(i), "  " + swift_id(i), 'Color', 'w', 'FontWeight', 'bold');
end

legend(map_ax, 'Location', 'northeast');
title(map_ax, 'SWIFT mooring watch circles');
% pad the extent below the moorings so the table box sits in open water
[lat_lim, lon_lim] = geolimits(map_ax);
geolimits(map_ax, [lat_lim(1) - 0.6*diff(lat_lim), lat_lim(2)], lon_lim);

center_lat_dm = strings(n_swift, 1); center_lon_dm = center_lat_dm;
for i = 1:n_swift
    center_lat_dm(i) = deg_decmin(center_lat(i), 'N', 'S');
    center_lon_dm(i) = deg_decmin(center_lon(i), 'E', 'W');
end
start_str = string(datestr(start_time, 'yyyy-mm-dd HH:MM'));

table_text = sprintf('%-8s %-13s %-14s %5s', 'SWIFT', 'center lat', 'center lon', 'r (m)');
table_text = ['Watch circle centers (o)' newline table_text];
for i = 1:n_swift
    table_text = [table_text ...
     newline sprintf('%-8s %-13s %-14s %5.1f', swift_id(i), center_lat_dm(i), center_lon_dm(i), radius_m(i))];
end
annotation('textbox', [0.14 0.12 0.4 0.12], 'String', table_text, 'FontName', 'Courier', 'FontSize', 9, 'BackgroundColor', 'w', 'FitBoxToText', 'on', 'Interpreter', 'none');

% save the watch circle centers and radii to a CSV in data_dir
centers_table = table(swift_id, center_lat, center_lon, center_lat_dm, center_lon_dm, radius_m, ...
    'VariableNames', {'SWIFT', 'center_lat', 'center_lon', 'center_lat_dm', 'center_lon_dm', 'radius_m'});
writetable(centers_table, fullfile(data_dir, 'mooring_watchcircle_centers.csv'));
% exportgraphics(gcf, fullfile(data_dir, 'mooring_centroids.png'), 'Resolution', 150);

fprintf('%-8s %11s %12s %8s %8s %-17s %6s %6s\n', 'SWIFT', 'lat', 'lon', 'r_m', 'rms_m', 'start_utc', 'used', 'total');
for i = 1:n_swift
    fprintf('%-8s %11.6f %12.6f %8.1f %8.1f %-17s %6d %6d\n', swift_id(i), center_lat(i), center_lon(i), radius_m(i), rms_residual(i), start_str(i), n_used(i), n_total(i));
end
end

function tf = is_stale(fix_time)
% last fix more than 2 hr before now (telemetry times are UTC datenum)
tf = datenum(datetime('now', 'TimeZone', 'UTC')) - fix_time > 2/24;
end

function m = fit_circle_kasa(x, y)
% x^2 + y^2 + D x + E y + F = 0  ->  [xc yc r]
coef = [x y ones(size(x))] \ -(x.^2 + y.^2);
xc = -coef(1)/2; yc = -coef(2)/2;
m = [xc yc sqrt(xc^2 + yc^2 - coef(3))];
end

function s = deg_decmin(deg, pos, neg)
hemi = pos; if deg < 0, hemi = neg; end
abs_deg = abs(deg);
s = sprintf('%d %06.3f %s', floor(abs_deg), 60*(abs_deg - floor(abs_deg)), hemi);
end
