%%% Funciton to calculate the depth of each sensor on the mooring line
%
%
% Necessary variables to do this:
% 1) SWIFT watch circles each month on each mooring / location of center of the watch circle
% 2) Mooring line length
% 3) Measured sensor location on the mooring line (from the top of the mooring line down)
% 4) Ground-truth depth data from the Duos and YSIs that were on the line 
% 5) Sensor data structure so that I can get the time of each sensor measurement
    % this will need to be done on the SWIFT measurement interval, so I will need to average the sensor depth onto the same time step for this 

% My steps:
% 1) Get the SWIFT watch circle data for each mooring and each month using Malcolm's function
% 2) Read in the Duo data and see if the YSI data has depths
%
%
%

clear all; close all; clc

%% load in the Duo data and the YSI data

duoData = load('/Users/heffem3/Library/CloudStorage/GoogleDrive-heffem3@uw.edu/Shared drives/M2O2/Penn Cove 2026/ConcatenatedData/DuoTDdata_MayOct2026_concatenated_L1.mat');
ysiData = load('/Users/heffem3/Library/CloudStorage/GoogleDrive-heffem3@uw.edu/Shared drives/M2O2/Penn Cove 2026/ConcatenatedData/YSI600LSdata_MayOct2026_concatenated_L1.mat');



%% get the watch circle data for each mooring and each month using Malcolm's function

% change the month that this uses with the data_dir input

data_dir = '/Users/heffem3/Desktop/M2O2/SWIFTs/FullDatasets/SepOct2026/';
fitSWIFTmooring_forL2prod(data_dir) % runs the function

% pull the output .csv with the center information for each SWIFT

mooring_centers_SepOct2026 = readtable('/Users/heffem3/Desktop/M2O2/SWIFTs/FullDatasets/SepOct2026/mooring_watchcircle_centers.csv');

%% load in the monthly SWIFT data

SWIFT26 = load('/Users/heffem3/Desktop/M2O2/SWIFTs/FullDatasets/SepOct2026/SWIFT26_SDcard_SepOct2026/SWIFT26_SDcard_SepOct2026_L2.mat');

SWIFT27 = load('/Users/heffem3/Desktop/M2O2/SWIFTs/FullDatasets/SepOct2026/SWIFT27_SDcard_SepOct2026/SWIFT27_SDcard_SepOct2026_L2.mat');

SWIFT28 = load('/Users/heffem3/Desktop/M2O2/SWIFTs/FullDatasets/SepOct2026/SWIFT28_SDcard_SepOct2026/SWIFT28_SDcard_SepOct2026_L2.mat');

SWIFT29 = load('/Users/heffem3/Desktop/M2O2/SWIFTs/FullDatasets/SepOct2026/SWIFT29_SDcard_SepOct2026/SWIFT29_SDcard_SepOct2026_L2.mat');
%% for each timstep of the SWIFT, calculate the distance from hte SWIFT's location to the center determined by Malcolm's function

swifts = {'SWIFT26', 'SWIFT27', 'SWIFT28', 'SWIFT29'};

% put the four loaded SWIFT files in one struct so the loop can reach them by name
swiftData = struct('SWIFT26', SWIFT26, 'SWIFT27', SWIFT27, 'SWIFT28', SWIFT28, 'SWIFT29', SWIFT29);

wgs84 = wgs84Ellipsoid('meter');
swiftRadius = struct();   % results, one field per SWIFT

% deployment window for each SWIFT, [start end] (UTC datenum)
% same values as deploy_start in fitSWIFTmooring_forL2prod.m -- change these for each month
deploy_window = containers.Map( ...
    {'SWIFT26', 'SWIFT27', 'SWIFT28', 'SWIFT29'}, ...
    {[datenum(2026, 9, 24, 19, 30, 0), datenum(2026, 10, 20, 14, 30, 0)], ...
     [datenum(2026, 9, 24, 19, 30, 0), datenum(2026, 10, 20, 14, 30, 0)], ...
     [datenum(2026, 9, 24, 19, 30, 0), datenum(2026, 10, 20, 14, 30, 0)], ...
     [datenum(2026, 9, 24, 19, 30, 0), datenum(2026, 10, 20, 14, 30, 0)]});

for i = 1:length(swifts)

    % pull this SWIFT's watch circle center from the centers table
    row  = strcmp(string(mooring_centers_SepOct2026.SWIFT), swifts{i});
    cLat = mooring_centers_SepOct2026.center_lat(row);
    cLon = mooring_centers_SepOct2026.center_lon(row);

    % SWIFT position and time at each time step
    S    = swiftData.(swifts{i}).SWIFT;
    lat  = [S.lat]';
    lon  = [S.lon]';
    time = [S.time]';

    % east/north distance (m) of each position, with the watch circle center as the origin
    [east, north] = geodetic2enu(lat, lon, 0, cLat, cLon, 0, wgs84);

    % Euclidean distance (radius) from the center at each time step
    r = hypot(east, north);   % = sqrt(east.^2 + north.^2)

    % set positions outside the deployment window to NaN (kept as NaN, not removed, so these
    % arrays stay the same length as the SWIFT time vector used for waterDepth and the fit)
    win      = deploy_window(swifts{i});
    inWindow = time >= win(1) & time <= win(2);
    lat(~inWindow) = NaN; lon(~inWindow) = NaN;
    east(~inWindow) = NaN; north(~inWindow) = NaN; r(~inWindow) = NaN;

    swiftRadius.(swifts{i}).inWindow = inWindow;   % true = time step is inside the deployment window
    swiftRadius.(swifts{i}).time  = time;
    swiftRadius.(swifts{i}).lat   = lat;
    swiftRadius.(swifts{i}).lon   = lon;
    swiftRadius.(swifts{i}).east  = east;
    swiftRadius.(swifts{i}).north = north;
    swiftRadius.(swifts{i}).r_m   = r;
end



%% match the duos and YSIs to the closest timesteps as the SWIFTs

% so when the SWIFT reads at time x, what is the pressure value from the YSIs and Duos at their recorded time that is closest to x?

% LJN
[ysi_N_4m_idx, ysi_N_4m_d] = knnsearch(datenum([ysiData.LJN_4m.DateTime]), [SWIFT28.SWIFT.time]'); 
[ysi8m_idx, ysi8m_d] = knnsearch(datenum([ysiData.LJN_8m.DateTime]), [SWIFT28.SWIFT.time]');

%LJS
[ysi_S_4m_idx, ysi_S_4m_d] = knnsearch(datenum([ysiData.LJS_4m.DateTime]), [SWIFT27.SWIFT.time]');
[ysi11m_idx, ysi11m_d] = knnsearch(datenum([ysiData.LJS_11m.DateTime]), [SWIFT27.SWIFT.time]');

%InnerNorth

[duoInN_idx, duoInN_d] = knnsearch([duoData.DuoTD_data.InnerNorth_sn240149.data.tstamp], [SWIFT26.SWIFT.time]');

% pull out only the times from the tide gage when the SWIFT was also reading to make the end processing easier
[duoInN_tide_idx, duoInN_tide_d] = knnsearch([duoData.DuoTD_data.InnerNorth_sn240150.data.tstamp], [SWIFT26.SWIFT.time]');
duoTide.tstamp = duoData.DuoTD_data.InnerNorth_sn240150.data.tstamp(duoInN_tide_idx);
duoTide.values = duoData.DuoTD_data.InnerNorth_sn240150.data.values(duoInN_tide_idx, :);


%inner south
[duoInS_idx, duoInS_d] = knnsearch([duoData.DuoTD_data.InnerSouth_sn240151.data.tstamp], [SWIFT29.SWIFT.time]');

%% setting up the variables for the catenary fit 

% get the tide level over the whole tide gauge record

mean_for_tide = mean([duoData.DuoTD_data.InnerNorth_sn240150.data.values(:,3)], 'omitnan');
for i = 1:length(duoData.DuoTD_data.InnerNorth_sn240150.data.values)
    eta(i) = duoData.DuoTD_data.InnerNorth_sn240150.data.values(i,3) - mean_for_tide;
end

% ----- water depth at each mooring = mooring depth + tide, at each of that mooring's SWIFT time steps ------

% mooring depths from your document (m) -- fill these in
moorings      = {'LJN', 'LJS', 'InnerNorth', 'InnerSouth'};
mooringSWIFTs = {'SWIFT28', 'SWIFT27', 'SWIFT26', 'SWIFT29'};   % SWIFT on each mooring

% Mooring depth values (below) for LJN, LJS, and Inner South come from the measured ADCP survey depths found in the instrumentation spreadsheet. 
% Value for Inner North comes from the average pressure measured by our pressure senso at the bottom.
mooringDepths = [28, 23, 20, 17];  %  units: m

tideTime = duoData.DuoTD_data.InnerNorth_sn240150.data.tstamp(:);

waterDepth = struct();
for i = 1:length(moorings)
    swiftTime = [swiftData.(mooringSWIFTs{i}).SWIFT.time]';

    % closest tide gauge sample to each of this SWIFT's time steps
    [tide_idx, tide_d] = knnsearch(tideTime, swiftTime);

    waterDepth.(mooringSWIFTs{i}).time      = swiftTime;
    waterDepth.(mooringSWIFTs{i}).tideTime  = tideTime(tide_idx);
    waterDepth.(mooringSWIFTs{i}).tide_dt   = tide_d * 86400;                      % time difference to the matched tide sample (seconds)
    waterDepth.(mooringSWIFTs{i}).baseDepth = mooringDepths(i);
    waterDepth.(mooringSWIFTs{i}).tide      = eta(tide_idx)';
    waterDepth.(mooringSWIFTs{i}).H         = mooringDepths(i) + eta(tide_idx)';   % total water depth at each SWIFT time step
end

% ----- line length ------

mooring_lengths = {50, 38, 34, 30}; % units: m , match the order of moorings (LJN, LJS, InnerNorth, InnerSouth)

lineLength = struct();
for ii = 1:length(moorings)
    lineLength.(mooringSWIFTs{ii}).mooringLineLen = mooring_lengths{ii}
end



% ------ just for information -------
  %%% X = swiftRadius.[SWIFT].r_m


%% fit a catenary function to describe the 'hang' of the line knowing the anchor location, the SWIFT's location, and the location of the duo or YSI sensor on the line

% ----- catenary fit at each SWIFT time step -----
%
% Coordinates used for the fit (at one time step):
%   origin = the anchor, on the seabed
%   x = horizontal distance from the anchor toward the SWIFT (m)
%   z = height above the seabed (m)  -> this is meters above bottom (mab)
%   s = distance along the line, measured from the anchor (m); the top of the line is at s = L
%
% The fitted line is described by two numbers at each time step:
%   a  = horizontal tension / line weight per meter (m). Larger a = tauter line.
%   x0 = touchdown point (m). x0 > 0: the first x0 meters of line lie on the seabed.
%                             x0 <= 0: the whole line is lifted off the bottom.

% --- Step 1: geometry ---
% X = swiftRadius.(SWIFT).r_m             horizontal distance, watch circle center to SWIFT
% H = waterDepth.(SWIFT).H                water depth at each SWIFT time step
% L = lineLength.(SWIFT).mooringLineLen   line length

% Measured sensors on each line -- fill these in.
%   name:        a label for the sensor
%   distFromTop: distance down the line from the SWIFT (m)
%   depth:       measured depth (m) at each of that SWIFT's time steps
%                (column vector, same length as swiftRadius.(SWIFT).time)
% Each line makes a struct array with one element per sensor, e.g. measSensors.SWIFT28(2) is the 2nd sensor on LJN.
% depths at each SWIFT time step: the knnsearch indices (_idx) pick the closest sensor sample to each SWIFT time
%   YSI: Depth_m column (m)
%   Duo: column 3 of values = sea pressure (dbar, ~ m of seawater)
measSensors.SWIFT28 = struct('name', {'YSI_4m', 'YSI_8m'},  'distFromTop', {4.11, 7.99}, ...
    'depth', {ysiData.LJN_4m.Depth_m(ysi_N_4m_idx), ysiData.LJN_8m.Depth_m(ysi8m_idx)});   % LJN
measSensors.SWIFT27 = struct('name', {'YSI_4m', 'YSI_11m'}, 'distFromTop', {3.5, 10.5}, ...
    'depth', {ysiData.LJS_4m.Depth_m(ysi_S_4m_idx), ysiData.LJS_11m.Depth_m(ysi11m_idx)});  % LJS
measSensors.SWIFT26 = struct('name', {'Duo_240149'},        'distFromTop', {20}, ...
    'depth', {duoData.DuoTD_data.InnerNorth_sn240149.data.values(duoInN_idx, 3)});          % InnerNorth
measSensors.SWIFT29 = struct('name', {'Duo_240151'},        'distFromTop', {18}, ...
    'depth', {duoData.DuoTD_data.InnerSouth_sn240151.data.values(duoInS_idx, 3)});          % InnerSouth

% ---- Uncertainty on X ----
% NOTE: the mooring line is attached to a pneumatic float, and the float is attached to the SWIFT by a 6 m
% pennant line. The SWIFT records the lat/lon, not the float, so the radius from the SWIFT's position
% (swiftRadius.(SWIFT).r_m) can differ from the radius of the actual top of the mooring line by up to 6 m.
% The fit lets the top of the line land anywhere within +/- maxX_err of the SWIFT's radius.
% TO DO: test how much this 6 m changes the fitted sensor depths (e.g. refit with X - 6, X, X + 6 and compare).
maxX_err = 6;   % m, pennant line length = maximum error on X

% H (water depth with tides taken into account) and the measured sensor depths are treated as exact, so they have no uncertainty.

% Turn off lsqnonlin's printed output (otherwise it prints at every time step)
opts   = optimoptions('lsqnonlin', 'Display', 'off');

% Results go here, one field per SWIFT
catFit = struct();

% ---- loop over the four moorings ----
for i = 1:length(mooringSWIFTs)

    % pull this mooring's inputs
    sw   = mooringSWIFTs{i};                    % e.g. 'SWIFT28'
    X    = swiftRadius.(sw).r_m;                % horizontal distance at each time step (m)
    H    = waterDepth.(sw).H;                   % water depth at each time step (m)
    L    = lineLength.(sw).mooringLineLen;      % line length (m)
    sens = measSensors.(sw);                    % the measured sensors on this line
    nT   = length(X);                           % number of SWIFT time steps

    % make empty (NaN) outputs to fill in during the time loop
    a_fit = nan(nT,1); x0_fit = a_fit; Lcrit = a_fit; resnorm = a_fit; exitflag = a_fit; xTop_fit = a_fit;
    sensorModelDepth = nan(nT, numel(sens));    % modeled depth below surface: rows = time steps, columns = sensors
    sensorMAB        = nan(nT, numel(sens));    % modeled meters above bottom: same layout

    % ---- loop over every SWIFT time step ----
    for t = 1:nT

        % skip time steps with no position or no water depth
        if ~isfinite(X(t)) || ~isfinite(H(t)), continue; end

        % skip impossible radii: the top of the line can't be farther from the anchor than the
        % line length plus the pennant (maxX_err), so the SWIFT can't be on the mooring at this time step
        if X(t) > L + maxX_err, continue; end

        % --- Step 2: Test 1 ---
        % Find the line length (Lcrit) that would exactly reach the SWIFT with the line just touching
        % down at the anchor. If the real line is longer than Lcrit (L > Lcrit), the extra is on the seabed.
        if X(t) < 1
            % SWIFT almost directly over the anchor: the line hangs nearly straight down,
            % so the length needed is just the water depth
            aCrit    = 1;
            Lcrit(t) = H(t);
        else
            % equation for the catenary that starts flat at the anchor and passes through (X, H);
            % its root is the value of 'a' for that boundary case
            f        = @(a) a.*(cosh(X(t)./a) - 1) - H(t);
            % solve for a; the bracket [X/700, 1e5] always contains the root, and X/700
            % keeps cosh(X/a) from overflowing to Inf
            aCrit    = fzero(f, [X(t)/700, 1e5]);
            % length of that boundary catenary
            Lcrit(t) = sqrt(H(t)^2 + 2*aCrit*H(t));
        end

        % collect the measured sensors that have a valid depth at this time step
        s_meas = []; d_meas = [];
        for k = 1:numel(sens)
            if ~isempty(sens(k).depth) && isfinite(sens(k).distFromTop) && isfinite(sens(k).depth(t))
                s_meas(end+1) = L - sens(k).distFromTop;   % convert to distance along the line from the anchor
                d_meas(end+1) = sens(k).depth(t);          % measured depth at this time step
            end
        end

        % --- Step 3: fit a and x0 ---
        % resFun returns the depth misfits in meters (see catResiduals at the end of the file);
        % lsqnonlin finds the [a, x0] that makes the sum of their squares as small as possible
        resFun = @(p) catResiduals(p, L, H(t), s_meas, d_meas);

        % conFun keeps the top of the fitted line within maxX_err of the SWIFT's radius, and puts the
        % top of the line exactly at the surface (see catConstraint)
        conFun = @(p) catConstraint(p, L, X(t), H(t), maxX_err);

        p0 = [aCrit, 0];     % starting guess: the Test 1 boundary catenary
        lb = [0.1, -L];      % lower limits: a > 0; x0 no more than one line length behind the anchor
        ub = [1e5,  L];      % upper limits: very taut line; touchdown no farther out than the line length

        % the four [] are for linear constraints, which aren't used here
        [p, rn, ~, ef] = lsqnonlin(resFun, p0, lb, ub, [], [], [], [], conFun, opts);

        % save the fit for this time step
        a_fit(t)    = p(1);   % fitted a
        x0_fit(t)   = p(2);   % fitted touchdown point
        resnorm(t)  = rn;     % sum of squared sensor depth misfits (m^2): 0 = matches all sensors exactly
        exitflag(t) = ef;     % lsqnonlin exit flag: > 0 means it converged; < 0 can mean the line can't reach the surface within the X limits

        % where the top of the fitted line (the pneumatic float) ended up
        xTop_fit(t) = catPoint(L, p(1), p(2));   % fitted radius of the line top (m)

        % --- Step 4: place each sensor on the fitted line ---
        for k = 1:numel(sens)
            if ~isfinite(sens(k).distFromTop), continue; end               % skip sensors with no line position
            [~, zk] = catPoint(L - sens(k).distFromTop, p(1), p(2));       % height above bottom on the fitted line
            sensorMAB(t,k)        = zk;          % meters above bottom
            sensorModelDepth(t,k) = H(t) - zk;   % depth below the surface
        end
    end

    % store this mooring's results
    catFit.(sw).time             = swiftRadius.(sw).time;   % SWIFT time steps (datenum)
    catFit.(sw).L                = L;                       % line length used (m)
    catFit.(sw).H                = H;                       % water depth used at each time step (m)
    catFit.(sw).a                = a_fit;                   % fitted a at each time step
    catFit.(sw).x0               = x0_fit;                  % fitted touchdown point at each time step
    catFit.(sw).Lcrit            = Lcrit;                   % Test 1 boundary length at each time step
    catFit.(sw).onBottom_test1   = L > Lcrit;               % true = Test 1 says line is on the bottom
    catFit.(sw).onBottom_fit     = x0_fit > 0;              % true = the fit put line on the bottom
    catFit.(sw).resnorm          = resnorm;                 % fit misfit at each time step
    catFit.(sw).exitflag         = exitflag;                % fit convergence flag at each time step
    catFit.(sw).xTop             = xTop_fit;                % fitted radius of the line top / pneumatic float (m)
    catFit.(sw).dX               = xTop_fit - X;            % fitted minus SWIFT-measured radius (m), within +/- maxX_err
    catFit.(sw).sensorNames      = {sens.name};             % column labels for the two sensor arrays below
    catFit.(sw).sensorModelDepth = sensorModelDepth;        % modeled sensor depth below surface (m)
    catFit.(sw).sensorMAB        = sensorMAB;               % modeled sensor meters above bottom (m)
end

%% visualize the fitted catenary and the sensors' locations at a few time steps

sw   = 'SWIFT26';                 % which mooring to plot
fit  = catFit.(sw);
sens = measSensors.(sw);

% pick a few time steps where the fit worked, spread evenly through the record
good   = find(isfinite(fit.a));
tPlot  = good(round(linspace(1, numel(good), 4)));   % 4 time steps

figure('Color', 'w');
for j = 1:numel(tPlot)
    t = tPlot(j);
    subplot(2, 2, j); hold on; box on

    % the fitted line: points from the anchor (s = 0) to the top (s = L)
    s = linspace(0, fit.L, 300);
    [x, z] = catPoint(s, fit.a(t), fit.x0(t));
    plot(x, z, 'k-', 'LineWidth', 1.5, 'DisplayName', 'fitted line')

    % water surface and seabed
    yline(fit.H(t), 'b-', 'DisplayName', 'surface')
    yline(0, '-', 'Color', [0.5 0.35 0.2], 'LineWidth', 2, 'DisplayName', 'seabed')

    % SWIFT's measured radius and the +/- maxX_err range where the top of the line can be
    Xt = swiftRadius.(sw).r_m(t);
    xline(Xt, 'r--', 'DisplayName', 'SWIFT radius')
    patch([Xt - maxX_err, Xt + maxX_err, Xt + maxX_err, Xt - maxX_err], ...
          [0 0 fit.H(t) fit.H(t)], 'r', 'FaceAlpha', 0.08, 'EdgeColor', 'none', 'DisplayName', '\pm pennant')

    % measured sensors: o = where the fit puts them, x = their measured depth
    for k = 1:numel(sens)
        if ~isfinite(sens(k).distFromTop), continue; end
        [xs, zs] = catPoint(fit.L - sens(k).distFromTop, fit.a(t), fit.x0(t));
        plot(xs, zs, 'o', 'MarkerSize', 7, 'LineWidth', 1.5, 'DisplayName', [sens(k).name ' (fit)'])
        if ~isempty(sens(k).depth) && isfinite(sens(k).depth(t))
            plot(xs, fit.H(t) - sens(k).depth(t), 'x', 'MarkerSize', 9, 'LineWidth', 1.5, ...
                 'DisplayName', [sens(k).name ' (measured)'])
        end
    end

    axis equal
    xlabel('horizontal distance from anchor (m)')
    ylabel('height above bottom (m)')
    title(sprintf('%s  %s', sw, datestr(fit.time(t), 'dd-mmm HH:MM')))
end
legend('Location', 'bestoutside')

%% ---- time series of each sensor's fitted height above bottom (sensorMAB) ----

tPlotTime = datetime(fit.time, 'ConvertFrom', 'datenum');   % SWIFT times as datetime for the x axis

figure('Color', 'w'); hold on; box on

% water depth, for reference (the top of the line is at the surface)
plot(tPlotTime, fit.H, '-', 'Color', [0.6 0.6 0.6], 'DisplayName', 'water depth H')

for k = 1:numel(sens)
    % fitted height above bottom of this sensor
    plot(tPlotTime, fit.sensorMAB(:,k), '-', 'LineWidth', 1, 'DisplayName', [sens(k).name ' (fit)'])

    % measured height above bottom (H - measured depth), where there is a measured depth
    if ~isempty(sens(k).depth)
        plot(tPlotTime, fit.H - sens(k).depth, '.', 'MarkerSize', 6, 'DisplayName', [sens(k).name ' (measured)'])
    end
end

xlabel('time (UTC)')
ylabel('height above bottom (m)')
title([sw ' sensor height above bottom'])
legend('Location', 'bestoutside')



% %% catenary fit (version 2): line fully off the bottom, anchor angle is the only fitted parameter
% %
% % Knowns at each SWIFT time step:
% %   anchor at (0, 0): the watch circle center, on the seabed
% %   top of the line at (X, H): X = swiftRadius.(SWIFT).r_m, H = waterDepth.(SWIFT).H
% %   measured sensors: distance down the line from the top (distFromTop) and measured depth (from measSensors above)
% %
% % Fitted line: a catenary that starts at the anchor and passes exactly through the top.
% %   theta0 = angle of the line above horizontal at the anchor  <- the one parameter that is fit
% %   a      = tension / weight per meter; set by theta0 so the line passes through (X, H)
% %   Lmodel = length of the fitted line from anchor to top (output; compare with the real line length)
% %
% % Equation of the line (s = distance along the line from the anchor, m0 = tan(theta0)):
% %   q = s/a + m0,   x = a*[asinh(q) - asinh(m0)],   z = a*[sqrt(1 + q^2) - sqrt(1 + m0^2)]
% % A sensor d meters down from the top is at s = Lmodel - d:  [x, z] = lineXZ(Lmodel(t) - d, a(t), theta0(t))

% % Sensitivity test: the SWIFT can be up to pennantLen from the top of the mooring line, so the true radius can be
% % anywhere in X +/- pennantLen. Each time step is also refit with X - pennantLen and X + pennantLen, and the spread
% % in Lmodel and in the sensor heights across the three fits shows how much the pennant alone can change them.

% pennantLen = 6;   % m, pennant between the pneumatic float and the SWIFT (used to skip impossible radii and for the sensitivity test)
% Xoffsets   = [-pennantLen, pennantLen];   % offsets added to X for the sensitivity test (m)

% catFit2 = struct();   % results, one field per SWIFT

% % ---- loop over the four moorings ----
% for i = 1:length(mooringSWIFTs)

%     % pull this mooring's inputs
%     sw   = mooringSWIFTs{i};                    % e.g. 'SWIFT28'
%     X    = swiftRadius.(sw).r_m;                % horizontal distance from the anchor at each time step (m)
%     H    = waterDepth.(sw).H;                   % water depth at each time step (m)
%     L    = lineLength.(sw).mooringLineLen;      % real line length (m), only used for the sanity check
%     sens = measSensors.(sw);                    % the measured sensors on this line
%     nT   = length(X);                           % number of SWIFT time steps

%     % make empty (NaN) outputs to fill in during the time loop
%     theta0 = nan(nT,1); a_fit = theta0; Lmodel = theta0; rmsMisfit = theta0;
%     sensorX          = nan(nT, numel(sens));    % fitted horizontal distance of each sensor from the anchor (m)
%     sensorMAB        = nan(nT, numel(sens));    % fitted meters above bottom of each sensor
%     sensorModelDepth = nan(nT, numel(sens));    % fitted depth below surface of each sensor (m)

%     % sensitivity test outputs: column / page 1 = X - pennantLen, 2 = X + pennantLen
%     Lmodel_sens    = nan(nT, 2);                % fitted line length with the shifted X (m)
%     sensorMAB_sens = nan(nT, numel(sens), 2);   % fitted sensor meters above bottom with the shifted X

%     % ---- loop over every SWIFT time step ----
%     for t = 1:nT

%         % skip time steps with no position, no water depth, or the SWIFT almost directly over the anchor
%         if ~isfinite(X(t)) || ~isfinite(H(t)) || X(t) < 1, continue; end

%         % skip impossible radii: the top can't be farther than the line + pennant can reach
%         if hypot(X(t), H(t)) > L + pennantLen, continue; end

%         % collect the measured sensors with a valid depth at this time step
%         dTop = []; dMeas = [];
%         for k = 1:numel(sens)
%             if ~isempty(sens(k).depth) && isfinite(sens(k).distFromTop) && isfinite(sens(k).depth(t))
%                 dTop(end+1)  = sens(k).distFromTop;   % distance down the line from the top (m)
%                 dMeas(end+1) = sens(k).depth(t);      % measured depth (m)
%             end
%         end
%         if isempty(dTop), continue; end   % no measured sensor at this time step: nothing to fit theta0 to

%         % --- fit theta0 ---
%         % the line curves upward, so its angle at the anchor must be less than the straight-line angle to the top
%         thetaMax  = atand(H(t) / X(t));
%         % misfit (sum of squared depth differences, m^2) for any theta0 -- see sensorMisfit at the end of the file
%         misfitFun = @(th) sensorMisfit(th, X(t), H(t), dTop, dMeas);
%         % find the theta0 between 0 and thetaMax with the smallest misfit
%         [th, sse] = fminbnd(misfitFun, 0, 0.999*thetaMax);

%         % rebuild the line for the best theta0
%         [a, Ltop] = solveA(th, X(t), H(t));

%         % save the fit for this time step
%         theta0(t)    = th;                          % anchor angle (degrees above horizontal)
%         a_fit(t)     = a;                           % tension / weight (m)
%         Lmodel(t)    = Ltop;                        % fitted line length, anchor to top (m)
%         rmsMisfit(t) = sqrt(sse / numel(dTop));     % rms depth misfit at the measured sensors (m); ~0 with one sensor

%         % --- place each sensor on the fitted line ---
%         for k = 1:numel(sens)
%             if ~isfinite(sens(k).distFromTop), continue; end            % skip sensors with no line position
%             [xk, zk] = lineXZ(Ltop - sens(k).distFromTop, a, th);       % position on the fitted line
%             sensorX(t,k)          = xk;          % horizontal distance from the anchor (m)
%             sensorMAB(t,k)        = zk;          % meters above bottom
%             sensorModelDepth(t,k) = H(t) - zk;   % depth below the surface (m)
%         end

%         % --- sensitivity test: refit with X - pennantLen and X + pennantLen ---
%         for j = 1:2
%             Xs = X(t) + Xoffsets(j);                              % shifted radius (m)
%             if Xs < 1, continue; end                              % shifted SWIFT almost directly over the anchor: skip

%             % same fit as above, with the shifted radius
%             thetaMaxS  = atand(H(t) / Xs);                        % straight-line angle to the shifted top
%             misfitFunS = @(th) sensorMisfit(th, Xs, H(t), dTop, dMeas);
%             thS        = fminbnd(misfitFunS, 0, 0.999*thetaMaxS); % best anchor angle with the shifted radius
%             [aS, LtopS] = solveA(thS, Xs, H(t));                  % line through the shifted top

%             Lmodel_sens(t,j) = LtopS;                             % fitted line length with the shifted radius

%             % place each sensor on the shifted-radius line
%             for k = 1:numel(sens)
%                 if ~isfinite(sens(k).distFromTop), continue; end
%                 [~, zkS] = lineXZ(LtopS - sens(k).distFromTop, aS, thS);
%                 sensorMAB_sens(t,k,j) = zkS;                      % meters above bottom with the shifted radius
%             end
%         end
%     end

%     % sensitivity test summary: spread across the three fits (X - pennantLen, X, X + pennantLen)
%     Lall          = [Lmodel, Lmodel_sens];                             % nT x 3: Lmodel from each of the three fits
%     Lmodel_spread = max(Lall, [], 2) - min(Lall, [], 2);               % how much the pennant alone can change Lmodel (m)
%     Lreal_inRange = L >= min(Lall, [], 2) & L <= max(Lall, [], 2);     % true = the real length is within that range
%     MABall        = cat(3, sensorMAB, sensorMAB_sens);                 % nT x sensors x 3: sensor heights from the three fits
%     MAB_spread    = max(MABall, [], 3) - min(MABall, [], 3);           % how much the pennant alone can change each sensor's height (m)

%     % store this mooring's results
%     catFit2.(sw).time             = swiftRadius.(sw).time;   % SWIFT time steps (datenum)
%     catFit2.(sw).X                = X;                       % radius used at each time step (m)
%     catFit2.(sw).H                = H;                       % water depth used at each time step (m)
%     catFit2.(sw).theta0           = theta0;                  % fitted anchor angle (degrees)
%     catFit2.(sw).a                = a_fit;                   % fitted tension / weight (m)
%     catFit2.(sw).Lmodel           = Lmodel;                  % fitted line length (m)
%     catFit2.(sw).Lreal            = L;                       % real line length (m), to compare with Lmodel
%     catFit2.(sw).rmsMisfit        = rmsMisfit;               % rms depth misfit at the measured sensors (m)
%     catFit2.(sw).sensorNames      = {sens.name};             % column labels for the sensor arrays below
%     catFit2.(sw).sensorX          = sensorX;                 % fitted sensor horizontal distance from anchor (m)
%     catFit2.(sw).sensorMAB        = sensorMAB;               % fitted sensor meters above bottom (m)
%     catFit2.(sw).sensorModelDepth = sensorModelDepth;        % fitted sensor depth below surface (m)

%     % sensitivity test (X - pennantLen and X + pennantLen)
%     catFit2.(sw).Lmodel_Xminus    = Lmodel_sens(:,1);        % fitted line length with X - pennantLen (m)
%     catFit2.(sw).Lmodel_Xplus     = Lmodel_sens(:,2);        % fitted line length with X + pennantLen (m)
%     catFit2.(sw).Lmodel_spread    = Lmodel_spread;           % max - min of Lmodel across the three fits (m)
%     catFit2.(sw).Lreal_inRange    = Lreal_inRange;           % true = real length within the range of the three Lmodels
%     catFit2.(sw).sensorMAB_Xminus = sensorMAB_sens(:,:,1);   % sensor meters above bottom with X - pennantLen
%     catFit2.(sw).sensorMAB_Xplus  = sensorMAB_sens(:,:,2);   % sensor meters above bottom with X + pennantLen
%     catFit2.(sw).sensorMAB_spread = MAB_spread;              % max - min of each sensor's height across the three fits (m)
% end



% %% visualize the version 2 fit: fitted line and sensors at a few time steps

% sw   = 'SWIFT26';                 % which mooring to plot
% fit2 = catFit2.(sw);
% sens = measSensors.(sw);

% % pick a few time steps where the fit worked, spread evenly through the record
% good2  = find(isfinite(fit2.theta0));
% tPlot2 = good2(round(linspace(1, numel(good2), 4)));   % 4 time steps

% figure('Color', 'w');
% for j = 1:numel(tPlot2)
%     t = tPlot2(j);
%     subplot(2, 2, j); hold on; box on

%     % the fitted line: points from the anchor (s = 0) to the top (s = Lmodel)
%     s = linspace(0, fit2.Lmodel(t), 300);
%     [x, z] = lineXZ(s, fit2.a(t), fit2.theta0(t));
%     plot(x, z, 'k-', 'LineWidth', 1.5, 'DisplayName', 'fitted line (v2)')

%     % water surface and seabed
%     yline(fit2.H(t), 'b-', 'DisplayName', 'surface')
%     yline(0, '-', 'Color', [0.5 0.35 0.2], 'LineWidth', 2, 'DisplayName', 'seabed')

%     % SWIFT's measured radius (the top of the fitted line is at this radius)
%     xline(fit2.X(t), 'r--', 'DisplayName', 'SWIFT radius')

%     % measured sensors: o = where the fit puts them, x = their measured depth
%     for k = 1:numel(sens)
%         if ~isfinite(sens(k).distFromTop), continue; end
%         [xs, zs] = lineXZ(fit2.Lmodel(t) - sens(k).distFromTop, fit2.a(t), fit2.theta0(t));
%         plot(xs, zs, 'o', 'MarkerSize', 7, 'LineWidth', 1.5, 'DisplayName', [sens(k).name ' (fit)'])
%         if ~isempty(sens(k).depth) && isfinite(sens(k).depth(t))
%             plot(xs, fit2.H(t) - sens(k).depth(t), 'x', 'MarkerSize', 9, 'LineWidth', 1.5, ...
%                  'DisplayName', [sens(k).name ' (measured)'])
%         end
%     end

%     axis equal
%     xlabel('horizontal distance from anchor (m)')
%     ylabel('height above bottom (m)')
%     title(sprintf('%s  %s  (v2, L_{model} = %.1f m)', sw, datestr(fit2.time(t), 'dd-mmm HH:MM'), fit2.Lmodel(t)))
% end
% legend('Location', 'bestoutside')

% % ---- time series of each sensor's fitted height above bottom (version 2) ----

% tPlotTime2 = datetime(fit2.time, 'ConvertFrom', 'datenum');   % SWIFT times as datetime for the x axis

% figure('Color', 'w'); hold on; box on

% % water depth, for reference (the top of the line is at the surface)
% plot(tPlotTime2, fit2.H, '-', 'Color', [0.6 0.6 0.6], 'DisplayName', 'water depth H')

% for k = 1:numel(sens)
%     % fitted height above bottom of this sensor
%     plot(tPlotTime2, fit2.sensorMAB(:,k), '-', 'LineWidth', 1, 'DisplayName', [sens(k).name ' (fit v2)'])

%     % measured height above bottom (H - measured depth), where there is a measured depth
%     if ~isempty(sens(k).depth)
%         plot(tPlotTime2, fit2.H - sens(k).depth, '.', 'MarkerSize', 6, 'DisplayName', [sens(k).name ' (measured)'])
%     end
% end

% xlabel('time (UTC)')
% ylabel('height above bottom (m)')
% title([sw ' sensor height above bottom (v2)'])
% legend('Location', 'bestoutside')



%% load in the other sensor data

% test-- soloT data from Sep to Oct

soloT = load('/Users/heffem3/Library/CloudStorage/GoogleDrive-heffem3@uw.edu/Shared drives/M2O2/Penn Cove 2026/Oct2026/Data/SoloTdata_SepOct2026_raw.mat');


%% assign the depths on the line to each sensor serial number-- starting from the top of the line to the bottom

%%% Solo T sensors %%%
% LoveJoy North
    % sn212861, 5.46
    % sn212862, 10.43
    % sn212863, 13.28
    % sn212864, 15.33
    % sn212865, 19.34
    % sn212866, 22.42
    % sn212867, 25.42

% LoveJoy South
    % sn212832, 6.0
    % sn212833, 12.0
    % sn212834, 15.0
    % sn212857, 17.0
    % sn212858, 21.0
    % sn212859, 24.0
    % sn212860, 27.0

% Inner North
    % sn212868, 4.00
    % sn212869, 8.00
    % sn212870, 12.00
    % sn212871, 16.00
    % sn212872, 24.00
    % sn212873, 28.00
    % sn212874, 32.00

% Inner South
    % sn212875, 2.00
    % sn212876, 6.00
    % sn212877, 10.00
    % sn212878, 14.00
    % sn212879, 22.00
    % sn212880, 26.00
    % sn212881, 30.00


%% knowing the catenary function I fit, fit each sensor's length along the line to the new function that describes the catenary of the mooring

% ----- how many catFit time steps converged -----
% fitted:        time steps where the fit ran (not skipped for NaN position/depth or an impossible radius)
% converged:     exitflag > 0
% not converged: exitflag <= 0 (with the surface constraint, this can mean the line couldn't reach the surface within the X limits)
fprintf('\n%-8s %8s %8s %10s %14s\n', 'SWIFT', 'total', 'fitted', 'converged', 'not converged');
for i = 1:length(mooringSWIFTs)
    sw     = mooringSWIFTs{i};
    fitted = isfinite(catFit.(sw).exitflag);                    % time steps where lsqnonlin ran
    conv   = fitted & catFit.(sw).exitflag > 0;                 % converged
    fprintf('%-8s %8d %8d %10d %14d\n', sw, numel(fitted), sum(fitted), sum(conv), sum(fitted & ~conv));
end

% ----- SoloT positions on each line -----
% SWIFT:       the SWIFT on that mooring (LJN = SWIFT28, LJS = SWIFT27, InnerNorth = SWIFT26, InnerSouth = SWIFT29)
% sn:          SoloT serial number
% distFromTop: distance down the line from the top (m), from the list above
soloPos = table( ...
    ["SWIFT28"; "SWIFT28"; "SWIFT28"; "SWIFT28"; "SWIFT28"; "SWIFT28"; "SWIFT28"; ...   % LoveJoy North
     "SWIFT27"; "SWIFT27"; "SWIFT27"; "SWIFT27"; "SWIFT27"; "SWIFT27"; "SWIFT27"; ...   % LoveJoy South
     "SWIFT26"; "SWIFT26"; "SWIFT26"; "SWIFT26"; "SWIFT26"; "SWIFT26"; "SWIFT26"; ...   % Inner North
     "SWIFT29"; "SWIFT29"; "SWIFT29"; "SWIFT29"; "SWIFT29"; "SWIFT29"; "SWIFT29"], ...  % Inner South
    ["sn212861"; "sn212862"; "sn212863"; "sn212864"; "sn212865"; "sn212866"; "sn212867"; ...
     "sn212832"; "sn212833"; "sn212834"; "sn212857"; "sn212858"; "sn212859"; "sn212860"; ...
     "sn212868"; "sn212869"; "sn212870"; "sn212871"; "sn212872"; "sn212873"; "sn212874"; ...
     "sn212875"; "sn212876"; "sn212877"; "sn212878"; "sn212879"; "sn212880"; "sn212881"], ...
    [5.46; 10.43; 13.28; 15.33; 19.34; 22.42; 25.42; ...
     6.00; 12.00; 15.00; 17.00; 21.00; 24.00; 27.00; ...
     4.00;  8.00; 12.00; 16.00; 24.00; 28.00; 32.00; ...
     2.00;  6.00; 10.00; 14.00; 22.00; 26.00; 30.00], ...
    'VariableNames', {'SWIFT', 'sn', 'distFromTop'});

% ----- place each SoloT on the fitted line at every SWIFT time step -----
soloOnLine = struct();   % results, one field per serial number

for j = 1:height(soloPos)

    sw  = char(soloPos.SWIFT(j));        % this SoloT's mooring
    sn  = char(soloPos.sn(j));           % serial number, used as the field name
    d   = soloPos.distFromTop(j);        % distance down the line from the top (m)
    fit = catFit.(sw);                   % the fitted line for this mooring
    nT  = numel(fit.time);               % number of SWIFT time steps

    % the sensor must be on the line: 0 <= d <= L
    if d > fit.L
        fprintf('%s (%s): distFromTop = %.2f m is longer than the line (L = %.0f m), skipped\n', sn, sw, d, fit.L);
        continue
    end

    s = fit.L - d;                        % distance along the line from the anchor (m)

    mab = nan(nT, 1);                     % height above bottom at each SWIFT time step
    for t = 1:nT
        % use every time step where the fit ran, including ones that did not converge (exitflag <= 0);
        % check fit.exitflag to see which time steps those are
        if isfinite(fit.a(t))
            [~, mab(t)] = catPoint(s, fit.a(t), fit.x0(t));   % height above bottom on the fitted line
        end
    end

    % store the results
    soloOnLine.(sn).SWIFT       = sw;             % mooring's SWIFT
    soloOnLine.(sn).distFromTop = d;              % distance down the line from the top (m)
    soloOnLine.(sn).time        = fit.time;       % SWIFT time steps (datenum)
    soloOnLine.(sn).mab         = mab;            % fitted meters above bottom
    soloOnLine.(sn).depth       = fit.H - mab;    % fitted depth below the surface (m)
end


%% visualize the mooring catenary and the sensors' locations a couple timesteps

% ----- SoloT fitted depths over time, one panel per mooring -----
mooringNames = {'LoveJoy North', 'LoveJoy South', 'Inner North', 'Inner South'};   % same order as mooringSWIFTs

figure('Color', 'w');
tiledlayout(2, 2, 'TileSpacing', 'compact');

for i = 1:length(mooringSWIFTs)
    sw  = mooringSWIFTs{i};
    fit = catFit.(sw);
    tDT = datetime(fit.time, 'ConvertFrom', 'datenum');   % SWIFT times as datetime for the x axis

    nexttile; hold on; box on

    % water depth (the seabed, seen from the surface)
    plot(tDT, fit.H, '-', 'Color', [0.5 0.35 0.2], 'LineWidth', 1.5, 'DisplayName', 'seabed (H)')

    % each SoloT on this mooring
    rows = find(soloPos.SWIFT == sw);
    for j = rows'
        sn = char(soloPos.sn(j));
        if ~isfield(soloOnLine, sn), continue; end      % skipped (longer than the line)
        plot(tDT, soloOnLine.(sn).depth, '-', 'LineWidth', 1, ...
            'DisplayName', sprintf('%s (%.1f m)', sn, soloPos.distFromTop(j)))
    end

    % mark the time steps where the fit did not converge
    notConv = isfinite(fit.exitflag) & fit.exitflag <= 0;
    if any(notConv)
        xline(tDT(notConv), '-', 'Color', [1 0.85 0.85], 'HandleVisibility', 'off')
    end

    set(gca, 'YDir', 'reverse')   % depth increases downward
    ylabel('depth below surface (m)')
    title(sprintf('%s (%s): SoloT fitted depths', mooringNames{i}, sw))
    legend('Location', 'eastoutside')
end



%% ----- local functions (must stay at the end of the script) -----

function [x, z] = catPoint(s, a, x0)
% The equation of the fitted line.
% Input:  s  = distance along the line from the anchor (m); can be one value or a vector
%         a  = fitted tension/weight (m)
%         x0 = fitted touchdown point (m)
% Output: x  = horizontal distance from the anchor (m)
%         z  = height above the bottom (m)

if x0 > 0
    % --- part of the line lies on the seabed, from the anchor out to x0 ---
    x = s;                       % on the seabed, horizontal distance = distance along the line
    z = zeros(size(s));          % on the seabed, height above bottom = 0
    up = (s - x0) > 0;           % points past the touchdown point (hanging, not on the bottom)
    sp = s(up) - x0;             % distance along the line measured from the touchdown point
    x(up) = x0 + a*asinh(sp/a);              % catenary: horizontal position of the hanging points
    z(up) = a*(sqrt(1 + (sp/a).^2) - 1);     % catenary: height of the hanging points
else
    % --- whole line is lifted off the bottom; the catenary's low point (vertex) is at x0 <= 0 ---
    q = s/a + sinh(-x0/a);                   % slope of the line at each point, from its length along the line
    x = x0 + a*asinh(q);                     % horizontal position
    z = a*(sqrt(1 + q.^2) - cosh(x0/a));     % height above bottom (shifted so the anchor is at z = 0)
end
end

function res = catResiduals(p, L, H, s_meas, d_meas)
% Sensor depth misfits (m) between the fitted line and what was measured. lsqnonlin minimizes the sum of their squares.
% (The top of the line being at the surface is an exact constraint in catConstraint, not a misfit here.)

a = p(1); x0 = p(2);                          % the two parameters being fit

if ~isempty(s_meas)                           % measured sensors at this time step
    [~, zS] = catPoint(s_meas(:), a, x0);     % fitted height above bottom at each measured sensor
    res = (H - zS) - d_meas(:);               % fitted depth minus measured depth, one per sensor
else
    res = 0;                                  % no measured sensors: nothing to match, only the constraints shape the line
end
end

function [c, ceq] = catConstraint(p, L, X, H, maxX_err)
% Constraints for lsqnonlin:
%   c   (inequality, kept <= 0): the top of the fitted line must be within maxX_err of the SWIFT's radius X
%   ceq (equality, kept  = 0):   the top of the fitted line must be exactly at the surface (z = H)

[xTop, zTop] = catPoint(L, p(1), p(2));       % position of the top of the fitted line (s = L)
c    = [ xTop - X - maxX_err;                 % xTop can be at most X + maxX_err
        -xTop + X - maxX_err];                % xTop must be at least X - maxX_err
ceq  = zTop - H;                              % top of the line exactly at the surface
end

% ----- local functions for the version 2 fit -----

function [x, z] = lineXZ(s, a, theta0)
% The equation of the fitted line (version 2).
% Input:  s      = distance along the line from the anchor (m); one value or a vector
%         a      = tension / weight (m)
%         theta0 = angle of the line at the anchor (degrees above horizontal)
% Output: x = horizontal distance from the anchor (m), z = height above the bottom (m)
m0 = tand(theta0);                            % slope of the line at the anchor
q  = s./a + m0;                               % slope of the line at distance s along it
x  = a.*(asinh(q) - asinh(m0));               % horizontal distance from the anchor
z  = a.*(sqrt(1 + q.^2) - sqrt(1 + m0.^2));   % height above bottom (0 at the anchor)
end

function [a, Ltop] = solveA(theta0, X, H)
% For a given anchor angle, find the a that makes the line pass exactly through the top (X, H),
% and the length of line from the anchor to the top.
m0 = tand(theta0);                            % slope at the anchor
u0 = asinh(m0);                               % the same slope, in the form the catenary uses
f  = @(a) a.*(cosh(X./a + u0) - cosh(u0)) - H;   % height of the line at X minus the water depth (0 = passes through the top)
a  = fzero(f, [X/600, 1e6]);                  % solve for a; X/600 keeps cosh from overflowing
Ltop = a*(sinh(X/a + u0) - m0);               % arc length from the anchor to the top (m)
end

function sse = sensorMisfit(theta0, X, H, dTop, dMeas)
% Sum of squared depth misfits (m^2) at the measured sensors for a given anchor angle.
[a, Ltop] = solveA(theta0, X, H);             % the line through the top for this anchor angle
[~, z]    = lineXZ(Ltop - dTop, a, theta0);   % height above bottom of each measured sensor on that line
sse       = sum(((H - z) - dMeas).^2);        % fitted depth minus measured depth, squared and summed
end