%%% Transecting ADCP heading correction %%%

% maia heffernan, updated july 14 2026, with some help from Claude

% this coordinate transformation is done on data from a Teledyne RDI
% Workhorse Sentinel 1200kHz ADCP that we use for transecting through PEnn
% Cove 

clear all, close all

%% Step 1. load in the ADCP data from June transecting

%load Echo_ADCP_24Jun2026_ebb_cleaned.mat

load Echo_ADCP_24Jun2026_flood_cleaned.mat

%% find the different transects and locations

figure(1); clf;
h= scatter(lon, lat, 15, time, 'filled'); 
colormap(jet);  % or parula, turbo, viridis
cb = colorbar;
ylabel(cb, 'Time');
xlabel('Longitude');
ylabel('Latitude');
title('Transect Path Colored by Time');
%axis equal; 
grid on;


% built-in datatip function which shows the timestamp and index value of a 
% colored dot in the figure


n = numel(time);
timeStrings = cellstr(datestr(time, 'yyyy-mm-dd HH:MM:SS.FFF'));
 
h.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Datenum', time, '%.8f');
h.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Time', timeStrings);
h.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Index', 1:n);
 
datacursormode(gcf, 'on');

%% Pull out the lines

% one row per transect line: [startIdx endIdx]

% == ebb bounds ==
% lineBounds = [ ...
%     17,   34;
%     47, 125;
%     143, 162;
%     182, 258;
%     281, 301;
%     304, 324;
%     340, 420;
%     422, 497];   

% == flood bounds ==

lineBounds = [ ...
    1, 80;
    102, 121;
    150, 237;
    262, 282;
    305, 368;
    402, 417;
    446, 528;
    550, 569];

nLines = size(lineBounds, 1);
transectLines = struct('lat', {}, 'lon', {}, 'time', {}, 'lineNum', {});

for k = 1:nLines
    idxRange = lineBounds(k,1):lineBounds(k,2);
    transectLines(k).lat     = lat(idxRange);
    transectLines(k).lon     = lon(idxRange);
    transectLines(k).time    = time(idxRange);
    transectLines(k).lineNum = k;
end

%% Step 2. determine course over ground (COG) from the Lat + Lon values for each transect line
%
% Adapted from the SWIFT drift-velocity method: uses gradient() of lat/lon
% w.r.t. time within EACH transect line separately (so a turn between lines
% doesn't get treated as a velocity spike).
%
% Assumes transectLines(k).lat, .lon, .time already exist (time = datenum).
% Adds per-point fields cogSpeed/cogDir, and per-line summary fields
% cog_mean/speed_mean.

haveMapping = exist('worldmap', 'file') ~= 0;  % deg2km needs Mapping Toolbox

for k = 1:length(transectLines)
    lat_cog  = transectLines(k).lat;
    lon_cog  = transectLines(k).lon;
    time_cog = transectLines(k).time;

    n = length(lat_cog);

    if n > 3 && haveMapping
        dlondt = gradient(lon_cog, time_cog);   % deg longitude / day
        dxdt = deg2km(dlondt, 6371*cosd(mean(lat_cog, 'omitnan'))) .* 1000 ./ (24*3600); % m/s east

        dlatdt = gradient(lat_cog, time_cog);   % deg latitude / day
        dydt = deg2km(dlatdt) .* 1000 ./ (24*3600); % m/s north

        dxdt(isinf(dxdt)) = NaN;
        dydt(isinf(dydt)) = NaN;

        speed = sqrt(dxdt.^2 + dydt.^2);        % m/s
        direction = atan2d(dxdt, dydt);          % deg true, 0 = north, clockwise
        direction(direction < 0) = direction(direction < 0) + 360;

        % discard the two endpoints of the LINE (one-sided gradient, less reliable)
        speed([1 end]) = NaN;
        direction([1 end]) = NaN;

        transectLines(k).cogSpeed = speed;       % m/s, one value per point
        transectLines(k).cogDir   = direction;    % deg true, one value per point

        % single representative COG/speed for the whole line
        validDir = direction(~isnan(direction));
        if ~isempty(validDir)
            transectLines(k).cog_mean = mod( ...
                atan2d(mean(sind(validDir)), mean(cosd(validDir))), 360); % circular mean using arctangent
        else
            transectLines(k).cog_mean = NaN;
        end
        transectLines(k).speed_mean = mean(speed, 'omitnan');

    else
        transectLines(k).cogSpeed   = NaN(size(lat_cog));
        transectLines(k).cogDir     = NaN(size(lat_cog));
        transectLines(k).cog_mean   = NaN;
        transectLines(k).speed_mean = NaN;
    end
end
    

%% check per-point COG noise within one transect line
%
% Usage: set lineNum to the line you want to inspect, then run.
% Requires transectLines already populated with cogDir/cogSpeed/cog_mean
% (i.e. run compute_cog_per_line.m first).

% The data should be good if the circular standard deviation is within 1-5°

% If large spikes in circ std correspond to dips in speed, then it's a 
    %  speed-normalization artifact rather than the boat's course actually changing

clear dir_pts speed_pts cogMean valid R circStd % clear the values made in each iteration for a differen line

lineNum = 8;  % <-- change to inspect a different line

dir_pts   = transectLines(lineNum).cogDir;
speed_pts = transectLines(lineNum).cogSpeed;
cogMean   = transectLines(lineNum).cog_mean;

valid = ~isnan(dir_pts);

% circular standard deviation (deg) -- handles 0/360 wraparound correctly
R = sqrt(mean(cosd(dir_pts(valid)))^2 + mean(sind(dir_pts(valid)))^2);
circStd = sqrt(-2*log(R)) * (180/pi);
fprintf('Line %d: circular std of cogDir = %.2f deg (mean COG = %.2f deg)\n', ...
    lineNum, circStd, cogMean);

figure;
subplot(2,1,1);
plot(find(valid), dir_pts(valid), 'o-');
yline(cogMean, 'r--', 'mean COG');
ylabel('Direction (deg true)');
title(sprintf('Line %d: per-point COG (circ. std = %.1f deg)', lineNum, circStd));
grid on;

subplot(2,1,2);
plot(find(valid), speed_pts(valid), 'o-');
ylabel('Speed (m/s)');
xlabel('Point index within line');
grid on;
title('Speed over ground -- compare low-speed points against direction jitter above');


% === Book Keeping ===

% Ebb tide
% Line 1: circular std of cogDir = 4.67 deg (mean COG = 186.96 deg)

% Line 2: circular std of cogDir = 3.29 deg (mean COG = 84.33 deg)

% Line 3: circular std of cogDir = 6.00 deg (mean COG = 172.51 deg)

% Line 4: circular std of cogDir = 1.23 deg (mean COG = 85.39 deg)

% Line 5: circular std of cogDir = 7.14 deg (mean COG = 358.36 deg)

% Line 6: circular std of cogDir = 6.37 deg (mean COG = 173.60 deg)

% Line 7: circular std of cogDir = 3.11 deg (mean COG = 83.47 deg)

% Line 8: circular std of cogDir = 2.76 deg (mean COG = 262.89 deg)


% Flood tide
% Line 1: circular std of cogDir = 3.61 deg (mean COG = 263.39 deg)

% Line 2: circular std of cogDir = 10.29 deg (mean COG = 168.39 deg)

% Line 3: circular std of cogDir = 2.81 deg (mean COG = 84.07 deg)

% Line 4: circular std of cogDir = 4.36 deg (mean COG = 353.23 deg)

% Line 5: circular std of cogDir = 9.11 deg (mean COG = 264.52 deg)

% Line 6: circular std of cogDir = 3.23 deg (mean COG = 169.19 deg)

% Line 7: circular std of cogDir = 2.51 deg (mean COG = 83.44 deg)

% Line 8: circular std of cogDir = 3.56 deg (mean COG = 351.40 deg)

%% Line 5 diagnosis

% for the ebb tide, line 5 has a HUGE circular std. When I look at the original plot
% (figure 1) and zoom in on the north/south line, there are two things that
% are aparent here. First, the line is really wavy, so it would make sense
% that the std in COG direction is large here. Whoever was driving mus
% thave been feeling the 3am wakeup at this point... Alex HD also noted to me
% that the transect lines were not totally straight all the time so this
% tracks in my mind. Second, this transect is heading north along the
% LoveJoy line, so the average COG of 356 deg actually really makes sense
% here. This code below just does a quick diagnosis, though. I want to make
% sure I didn't accidentally pull out a turn in the transect, which would
% hugley throw off the direction.

% For the flood tide,. both lines 2 and 5 have huge circular standard
% deviations. This is obvious for line 5 given how curvy it is which you
% can seein figure 1, but let's also focus in on line 2 to see its path.


% Pinpoint a turn/kink hiding inside a manually-defined transect line
lineNum = 8;  % <-- the suspect line

lat_l  = transectLines(lineNum).lat;
lon_l  = transectLines(lineNum).lon;
dir_l  = transectLines(lineNum).cogDir;
idxAll = 1:length(lat_l);

figure;

% left: spatial path colored by point index, so you can see WHERE it kinks
subplot(1,2,1);
scatter(lon_l, lat_l, 30, idxAll, 'filled');
colormap(jet); colorbar;
xlabel('Longitude'); ylabel('Latitude');
title(sprintf('Line %d path, colored by point index', lineNum));
axis equal; grid on;

% right: direction vs index -- UNWRAPPED so a heading near 0/360 doesn't
% show a fake jump. unwrap() expects radians and assumes points are close
% together, which is valid within one transect line.
dir_unwrapped = rad2deg(unwrap(deg2rad(dir_l)));

subplot(1,2,2);
plot(idxAll, dir_unwrapped, 'o-');
xlabel('Point index within line');
ylabel('Direction (deg true, unwrapped)');
title('Look for the index where direction jumps sharply');
grid on;

% Ebb notes
% July 12, 2026 @ 12:26 --> Ah, okay from the plot it looks like I picked out a turn in this line
% mistakenly. I will go back and fix it in the indices.

% July 12, 2026 @ 12:37 --> Okay this is fixed now. I removed the loop and
% the diagnostic plot and values show a straight line with about an 18 deg
% bow in the transect line. This is congruent with the comment Alex made
% and is expected. Though the circ std is high I still trust this
% measurement because of the consistently larger circ std from other lines
% that run North/South. The boat must have been fighting the wind or the
% tidal current on these lines (which makes sense because this was during
% the ebb tide which is a primarily east/west movement)! I will accept this
% an move on. 


% Flood notes
% July 13, 2026 @ 14:25 --> OKay both lines 2 and 5 wander a lot, which
% describes the large circular standard deviation. This is kind of
% inescapable here, but at least I did not get a loop in either of these,
% they just have wobbly transect lines.
%% compare COG to ensemble heading in the exported matlab files 

load Echo_ADCP_24Jun2026_flood.mat AnH100thDeg % heading information from the ADCP 


% the difference is the rotation correction


% Compare ADCP-reported heading to GPS-derived COG, per transect line


% Requires:
%   - transectLines(k).time, .cog_mean already populated (from earlier steps)
%   - Raw ADCP .mat variables loaded in the workspace:
%       AnH100thDeg

% === Convert ADCP heading: hundredths of a degree -> degrees ===
headingDeg = mod(AnH100thDeg / 100, 360);

adcpTime = time;

% === Loop over lines: circular mean ADCP heading within each line's time
% window ===
nLines = length(transectLines);

for k = 1:nLines
    tStart = min(transectLines(k).time);
    tEnd   = max(transectLines(k).time);

    inLine = adcpTime >= tStart & adcpTime <= tEnd;
    hdgLine = headingDeg(inLine);

    if ~isempty(hdgLine)
        adcp_mean = mod(atan2d(mean(sind(hdgLine)), mean(cosd(hdgLine))), 360);
        R = sqrt(mean(cosd(hdgLine), 'omitnan')^2 + mean(sind(hdgLine), 'omitnan')^2);
        adcp_std = sqrt(-2*log(R)) * (180/pi);
    else
        adcp_mean = NaN;
        adcp_std  = NaN;
    end

    transectLines(k).adcp_heading_mean = adcp_mean;
    transectLines(k).adcp_heading_std  = adcp_std;

    % circular difference (COG - ADCP heading), wrapped to [-180, 180]
    transectLines(k).heading_bias_mean = ...
        mod(transectLines(k).cog_mean - adcp_mean + 180, 360) - 180;
    % transectLines(k).heading_bias = transectLines(k).cogDir - hdgLine(k);
end

%% Summary table
lineNum  = (1:nLines)';
cogMean  = [transectLines.cog_mean]';
adcpMean = [transectLines.adcp_heading_mean]';
adcpStd  = [transectLines.adcp_heading_std]';
meanbias     = [transectLines.heading_bias_mean]';

summaryTable = table(lineNum, cogMean, adcpMean, adcpStd, meanbias, ...
    'VariableNames', {'Line','GPS_COG','ADCP_Heading','ADCP_std','Mean_bias_deg'});
disp(summaryTable);

%% Correct reported ENU velocity components for the rotation biases

% Rotates each line's ADCP-reported (east, north) velocity by that line's
% heading_bias_mean (GPS COG - ADCP heading), so the corrected velocities
% are referenced to true heading instead of the ADCP's biased compass.
%
% Assumes:
%   - transectLines(k).heading_bias_mean already computed
%   - adcpTime already computed (ADCP ensemble timestamps, as datenum)
%   - ADCP velocity variables in the workspace. Substitute the actual
%     variable names below if these don't match the .mat file
%     (commonly SerEmmpersec / SerNmmpersec in RDI's convention, one row
%     per ensemble and one column per depth bin, mm/s).



east_corrected  = nan(size(east));
north_corrected = nan(size(north));
 
nLines = length(transectLines);
 
for k = 1:nLines
    % same shared indices as heading_bias calculation, since lat/lon/time/
    % heading/velocity all come from the same ADCP ensemble stream
    idxRange = find(ismember(time, transectLines(k).time));
 
    theta = transectLines(k).heading_bias_mean;  % deg to add to ADCP heading
 
    e = east(idxRange, :);
    n = north(idxRange, :);
 
    % rotate by +theta in compass sense 
    east_corrected(idxRange, :)  =  e .* cosd(theta) + n .* sind(theta);
    north_corrected(idxRange, :) = -e .* sind(theta) + n .* cosd(theta);
end
 
% ensembles not falling inside any line's index range stay NaN --
% e.g. turns/transits between transect lines, which is expected

%% Build a per-lap (per transect line) structure of corrected velocities
%
% Requires: transectLines (with .time), eastVel_corrected, northVel_corrected,
% time, lat, lon already in the workspace (from earlier steps).
%
 
nLines = length(transectLines);
 
lapData = struct('lap', {}, 'lat', {}, 'lon', {}, 'time', {}, 'upVel', {}, ...
                  'eastVel_corrected', {}, 'northVel_corrected', {}, 'alongDist', {}, 'binDepth', {}, 'bottomTrack', {});
 
for k = 1:nLines
    idxRange = find(ismember(time, transectLines(k).time));
 
    lapData(k).lap      = k;
    lapData(k).lat       = lat(idxRange);
    lapData(k).lon       = lon(idxRange);
    lapData(k).time      = time(idxRange);
    lapData(k).upVel       = up(idxRange);
    lapData(k).eastVel_corrected   = east_corrected(idxRange, :);   
    lapData(k).northVel_corrected  = north_corrected(idxRange, :);  
    lapData(k).binDepth     = z(:)';   
    lapData(k).bottomTrack  = depth(:, idxRange)'; % this is from teh cleaned .mat file loaded in at the beginning
 
    % cumulative along-track distance (meters) from this lap's own start point
    d = haversineDistance(lapData(k).lat(1:end-1), lapData(k).lon(1:end-1), ...
                           lapData(k).lat(2:end),   lapData(k).lon(2:end));
    lapData(k).alongDist = [0; cumsum(d(:))];
end
 


%% Pcolor plots of corrected east/north velocity, per lap
%
% Requires lapData (from build_lap_velocity_struct.m) and cmocean

nLines = length(lapData);
 
% SAME color limit for east AND north, across ALL laps -- this 
% makes the east-west dominance visually obvious rather than each panel
% auto-scaling to its own range
allVel = [];
for k = 1:nLines
    allVel = [allVel; lapData(k).eastVel_corrected(:); lapData(k).northVel_corrected(:)]; 
end
climMax = max(abs(allVel), [], 'omitnan');
 
for k = 1:nLines
    figure('Position', [100 100 900 700]);
 
    subplot(2,1,1);
    pcolor(lapData(k).time, lapData(k).binDepth, lapData(k).eastVel_corrected');
    shading flat;
    colormap(cmocean('balance'));
    caxis([-climMax climMax]);
    colorbar;
    set(gca, 'YDir', 'reverse');
    hold on;
    plot(lapData(k).time, lapData(k).bottomTrack, 'k-', 'LineWidth', 2);
    datetick;
    ylabel('Depth (m)');
    title(sprintf('Lap %d: East velocity (m/s)', k));
 
    subplot(2,1,2);
    pcolor(lapData(k).time, lapData(k).binDepth, lapData(k).northVel_corrected');
    shading flat;
    colormap(cmocean('balance'));
    caxis([-climMax climMax]);
    colorbar;
    set(gca, 'YDir', 'reverse');
    hold on;
    plot(lapData(k).time, lapData(k).bottomTrack, 'k-', 'LineWidth', 2);
    datetick;
    xlabel('Along-track distance (m)');
    ylabel('Depth (m)');
    title(sprintf('Lap %d: North velocity (m/s)', k));
end

%% Plot entire time series

allTime   = [];
allEast   = [];
allNorth  = [];
allBottom = [];

for k = 1:nLines
    allTime   = [allTime;   lapData(k).time];
    allEast   = [allEast;   lapData(k).eastVel_corrected];
    allNorth  = [allNorth;  lapData(k).northVel_corrected];
    allBottom = [allBottom; lapData(k).bottomTrack(:)];

    if k < nLines
        % insert a one-row NaN gap at the midpoint of the turn between laps
        gapTime = mean([lapData(k).time(end), lapData(k+1).time(1)]);
        allTime   = [allTime;   gapTime];
        allEast   = [allEast;   nan(1, size(allEast, 2))];
        allNorth  = [allNorth;  nan(1, size(allNorth, 2))];
        allBottom = [allBottom; NaN];
    end
end

depth = lapData(1).binDepth;  % assumes same depth bins across all laps

climMax = max(abs([allEast(:); allNorth(:)]), [], 'omitnan');

figure('Position', [100 100 1200 700]);

subplot(2,1,1);
pcolor(allTime, depth, allEast');
shading flat;
colormap(cmocean('balance'));
caxis([-climMax climMax]);
colorbar;
set(gca, 'YDir', 'reverse');
hold on;
plot(allTime, allBottom, 'k-', 'LineWidth', 2);
datetick('x', 'keeplimits');
ylabel('Depth (m)');
title('Full survey: East velocity (m/s)');

subplot(2,1,2);
pcolor(allTime, depth, allNorth');
shading flat;
colormap(cmocean('balance'));
caxis([-climMax climMax]);
colorbar;
set(gca, 'YDir', 'reverse');
hold on;
plot(allTime, allBottom, 'k-', 'LineWidth', 2);
datetick('x', 'keeplimits');
xlabel('Time');
ylabel('Depth (m)');
title('Full survey: North velocity (m/s)');




%% Identify candidate reciprocal transect line pairs
%
% Two lines are "reciprocal" if their mean COG directions are roughly
% 180 degrees apart (i.e. same physical track, opposite travel direction).
% Requires transectLines(k).cog_mean already computed.
%
% NOTE: this only checks DIRECTION -- always sanity-check that candidate
% pairs actually overlap spatially (e.g. by eye on position plot)
% before treating them as a true reciprocal pair.

nLines = length(transectLines);
cogMeans = [transectLines.cog_mean];

tol = 30;  % degrees tolerance around 180 to call a pair "reciprocal"
pairs = [];

for i = 1:nLines
    for j = i+1:nLines
        diffAngle = abs(mod(cogMeans(i) - cogMeans(j) + 180, 360) - 180); % in [0,180]
        if abs(diffAngle - 180) < tol
            pairs = [pairs; i, j]; 
        end
    end
end

disp('Candidate reciprocal pairs (line i, line j):');
disp(pairs);






%% make sure PCA of tidal flow that are mostly east/west that agree with the tidal ellipses from the moorings



%% save out these new velocities and other.mat components for the ebb and flood separately 


%save Echo_ADCP_flood_cleaned_corrected.mat lapData

save Echo_ADCP_ebb_cleaned_corrected.mat lapData


%% === Functions === %%

%% HaversineDistance function
function d = haversineDistance(lat1, lon1, lat2, lon2)
% Great-circle distance in meters between two lat/lon points (vectorized).
R = 6371000; % Earth radius, meters
phi1 = deg2rad(lat1); phi2 = deg2rad(lat2);
dphi = deg2rad(lat2 - lat1);
dlambda = deg2rad(lon2 - lon1);
a = sin(dphi/2).^2 + cos(phi1).*cos(phi2).*sin(dlambda/2).^2;
d = 2*R*asin(sqrt(a));
end
%% Bin average

function [binned, centers] = binAverage(coord, val, edges)
% Average val into bins defined by edges, using coord as the bin variable.
nBins = length(edges) - 1;
binned = nan(nBins, 1);
centers = nan(nBins, 1);
for i = 1:nBins
    inBin = coord >= edges(i) & coord < edges(i+1);
    binned(i) = mean(val(inBin), 'omitnan');
    centers(i) = (edges(i) + edges(i+1)) / 2;
end
end

%% compare reciprcal lines fuction
 function compareReciprocalLines(lapData, lineA, lineB, nBins)
% Compare depth-averaged east/north velocity between two reciprocal lines,
% binned by whichever spatial coordinate (lat or lon) varies more --
% so both passes land in the same physical bins regardless of which
% direction each was actually driven.
%
% Usage: compareReciprocalLines(lapData, 2, 8, 20)

if nargin < 4
    nBins = 20;
end

lonRange = range([lapData(lineA).lon; lapData(lineB).lon]);
latRange = range([lapData(lineA).lat; lapData(lineB).lat]);

if lonRange > latRange
    coordA = lapData(lineA).lon; coordB = lapData(lineB).lon;
    coordLabel = 'Longitude';
else
    coordA = lapData(lineA).lat; coordB = lapData(lineB).lat;
    coordLabel = 'Latitude';
end

edges = linspace(min([coordA; coordB]), max([coordA; coordB]), nBins + 1);

% depth-averaged velocity per point (collapse across bins/depth)
eA = mean(lapData(lineA).eastVel, 2, 'omitnan');
nA = mean(lapData(lineA).northVel, 2, 'omitnan');
eB = mean(lapData(lineB).eastVel, 2, 'omitnan');
nB = mean(lapData(lineB).northVel, 2, 'omitnan');

[eA_binned, binCenters] = binAverage(coordA, eA, edges);
[nA_binned, ~]          = binAverage(coordA, nA, edges);
[eB_binned, ~]          = binAverage(coordB, eB, edges);
[nB_binned, ~]          = binAverage(coordB, nB, edges);

figure('Position', [100 100 800 700]);

subplot(2,1,1);
plot(binCenters, eA_binned, 'o-', 'DisplayName', sprintf('Lap %d', lineA)); hold on;
plot(binCenters, eB_binned, 's-', 'DisplayName', sprintf('Lap %d', lineB));
ylabel('East velocity (m/s)'); legend; grid on;
title(sprintf('Reciprocal comparison: Lap %d vs Lap %d', lineA, lineB));

subplot(2,1,2);
plot(binCenters, nA_binned, 'o-', 'DisplayName', sprintf('Lap %d', lineA)); hold on;
plot(binCenters, nB_binned, 's-', 'DisplayName', sprintf('Lap %d', lineB));
xlabel(coordLabel); ylabel('North velocity (m/s)'); legend; grid on;

% quantitative agreement metrics, for reporting
validE = ~isnan(eA_binned) & ~isnan(eB_binned);
rmsE  = sqrt(mean((eA_binned(validE) - eB_binned(validE)).^2));
corrE = corr(eA_binned(validE), eB_binned(validE));
fprintf('East velocity agreement (Lap %d vs %d): RMS diff = %.3f m/s, corr = %.2f\n', ...
    lineA, lineB, rmsE, corrE);

validN = ~isnan(nA_binned) & ~isnan(nB_binned);
rmsN  = sqrt(mean((nA_binned(validN) - nB_binned(validN)).^2));
corrN = corr(nA_binned(validN), nB_binned(validN));
fprintf('North velocity agreement (Lap %d vs %d): RMS diff = %.3f m/s, corr = %.2f\n', ...
    lineA, lineB, rmsN, corrN);
end
 






%% exta code for later maybe

% For removing sidelobe interference from the bottom:
% 
% guardBand = 0.06 * lapData(k).bottomDepth;  % ~6% of range, adjust if you use a different beam angle
% cutoff = lapData(k).bottomDepth - guardBand;
% 
% depthMat = repmat(lapData(k).depth, length(cutoff), 1);      % [nPings x nBins]
% cutoffMat = repmat(cutoff(:), 1, length(lapData(k).depth));  % [nPings x nBins]
% 
% eastMasked = lapData(k).eastVel;
% eastMasked(depthMat > cutoffMat) = NaN;