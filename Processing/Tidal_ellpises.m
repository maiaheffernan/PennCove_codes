%%%% Making tidal ellipses of flow at the SWIFT buoy locations %%%%

%%% Maia H. Jul 31 2026

clear all, close all

%% load in the SWIFT sig data

% this is coming from the MayJun 2026 period

SWIFT09_WWS = load('SWIFT09_SDcard_MayJun2026_SIG.mat');

SWIFT18_WWN = load('SWIFT18_SDcard_MayJun2026_SIG.mat');

SWIFT26_InN = load('SWIFT26_SDcard_MayJun2026_SIG.mat');

SWIFT27_LJS = load('SWIFT27_SDcard_MayJun2026_SIG.mat');

SWIFT28_LJN = load('SWIFT28_SDcard_MayJun2026_SIG.mat');

SWIFT29_InS = load('SWIFT29_SDcard_MayJun2026_SIG.mat');


%% Run all through Utide to get the tidal velocity component

% % Extract velocity data from each SWIFT structure
% lat = 48.23;
% structs = {SWIFT09_WWS, SWIFT18_WWN, SWIFT26_InN, SWIFT27_LJS, SWIFT28_LJN, SWIFT29_InS};
% 
% for i = 1:length(structs)
%     ThisStruct = structs{i};
% 
%     u_raw = [ThisStruct.SIG.profile.u]; % Extract velocity data for the current structure
%     v_raw = [ThisStruct.SIG.profile.v]; 
%     t_raw = [ThisStruct.SIG.time]; 
% 
% 
% % calculate uTide
% 	coef = UT_SOLV ( t_raw, u_raw, v_raw, lat, 'auto' ); 
%   [ u_tide, v_tide ] = UR_RECONSTR ( t_raw, coef);
% 
% 
% % put the new values back into the structures


%% ========================================================================
%  Tidal ellipse analysis for SWIFT SIG (Signature ADCP) moorings
%  1) Extract u,v at two specific depth bins from each structure
%  2) Run UTide (ut_solv) per depth bin to get harmonic constants + ellipses
%  3) Store results back into structures
%  4) Plot M2 ellipses for each mooring, both depths
%  ========================================================================

lat = 48.23; % for PEnn Cove
 
% Same two depth bins for every mooring
depthBins    = [2, 15];   % actual depth (m), for labeling
depthIndices = [4, 30];       % index into profile(k).u / profile(k).v
nDepths      = numel(depthIndices);
 
names   = {'InnerN', 'LJN', 'WWN', ...
           'InnerS','LJS', 'WWS'};
structs = {SWIFT26_InN, SWIFT28_LJN,  SWIFT18_WWN, ...
           SWIFT29_InS, SWIFT27_LJS, ...
           SWIFT09_WWS};
 
results = struct(); % store coef, ellipse params, etc. per mooring
 
for i = 1:length(structs)
 
    ThisStruct = structs{i};
    N          = numel(ThisStruct.SIG);           % SIG is the 1xN struct array over time
    t_raw      = [ThisStruct.SIG.time];            % concatenate N scalar times
    t_raw      = reshape(t_raw, 1, []);             % guarantee row orientation
 
    % ---- Pull out only the two depth bins we care about, for all timesteps ----
    u_mat = NaN(nDepths, N);
    v_mat = NaN(nDepths, N);
    for k = 1:N
        uk = ThisStruct.SIG(k).profile.u(:);
        vk = ThisStruct.SIG(k).profile.v(:);
        for d = 1:nDepths
            idx = depthIndices(d);
            if idx <= numel(uk)
                u_mat(d, k) = uk(idx);
                v_mat(d, k) = vk(idx);
            end
        end
    end

    % ---- Despike: remove obvious outliers before tidal fitting ----
velThresh = 2;  % m/s — anything beyond this is not a real tidal current in Penn Cove
for d = 1:nDepths
    badPts = abs(u_mat(d,:)) > velThresh | abs(v_mat(d,:)) > velThresh;
    if any(badPts)
        fprintf('%s: removing %d outlier point(s) at %.1f m (|vel| > %.1f m/s)\n', ...
            names{i}, sum(badPts), depthBins(d), velThresh);
        u_mat(d, badPts) = NaN;
        v_mat(d, badPts) = NaN;
    end
end
 
    % ---- Enforce strictly monotonic time by removing bad points, not inventing times ----
    % A forward scan: keep a point only if it's strictly greater than the
    % last KEPT point. This guarantees a strictly increasing result in one
    % pass, with no risk of a fix at index k creating a new violation
    % between k and k+1
    keepIdx  = true(1, N);
    lastGood = t_raw(1);
    nBad     = 0;
    for k = 2:N
        if t_raw(k) <= lastGood
            keepIdx(k) = false;
            nBad = nBad + 1;
        else
            lastGood = t_raw(k);
        end
    end
 
    if nBad > 0
        fprintf('%s: removed %d non-monotonic/duplicate time point(s) out of %d\n', ...
            names{i}, nBad, N);
    end
 
    % Apply the same mask to time and both velocity matrices so everything
    % stays aligned, then update N to the cleaned length.
    t_raw = t_raw(keepIdx);
    u_mat = u_mat(:, keepIdx);
    v_mat = v_mat(:, keepIdx);
    N     = numel(t_raw);
 
    fprintf('%s: %d time steps (after cleaning), depths = [%.1f, %.1f] m\n', ...
        names{i}, N, depthBins(1), depthBins(2));
 
    % ---- Run UTide once per depth bin (2 calls per mooring) ----
    coef_cell   = cell(nDepths, 1);
    u_tide_mat  = NaN(nDepths, N);
    v_tide_mat  = NaN(nDepths, N);
 
    for d = 1:nDepths
        u_d = u_mat(d, :);
        v_d = v_mat(d, :);
 
        if all(isnan(u_d)) || all(isnan(v_d))
            warning('%s: depth %.1f m is all NaN, skipping', names{i}, depthBins(d));
            continue
        end
 
        coef_cell{d} = ut_solv(t_raw, u_d, v_d, lat, 'auto', 'OLS');
 
        % reconstr only needed if you want the fitted time series itself
        % (not required just to get the ellipse parameters)
        [u_tide_mat(d, :), v_tide_mat(d, :)] = ut_reconstr(t_raw, coef_cell{d});
    end
 
    % ---- Store everything back ----
    results.(names{i}).t          = t_raw;
    results.(names{i}).depthBins  = depthBins;
    results.(names{i}).u_raw      = u_mat;
    results.(names{i}).v_raw      = v_mat;
    results.(names{i}).u_tide     = u_tide_mat;
    results.(names{i}).v_tide     = v_tide_mat;
    results.(names{i}).coef       = coef_cell;
 
    % ---- Pull out M2 ellipse parameters for each of the two depths ----
    % coef.Lsmaj, coef.Lsmin, coef.theta, coef.g come straight out of ut_solv
    Lsmaj_M2  = NaN(nDepths, 1);
    Lsmin_M2  = NaN(nDepths, 1);
    theta_M2  = NaN(nDepths, 1);
    g_M2      = NaN(nDepths, 1);
 
    for d = 1:nDepths
        if isempty(coef_cell{d})
            continue
        end
        idx = find(strcmp(coef_cell{d}.name, 'M2'));
        if isempty(idx)
            continue % M2 not resolved for this bin (e.g., record too short)
        end
        Lsmaj_M2(d) = coef_cell{d}.Lsmaj(idx);
        Lsmin_M2(d) = coef_cell{d}.Lsmin(idx);
        theta_M2(d) = coef_cell{d}.theta(idx);
        g_M2(d)     = coef_cell{d}.g(idx);
    end
 
    results.(names{i}).M2.Lsmaj = Lsmaj_M2;
    results.(names{i}).M2.Lsmin = Lsmin_M2;
    results.(names{i}).M2.theta = theta_M2;
    results.(names{i}).M2.g     = g_M2;
end
 

%% ========================================================================
%  Plot M2 tidal ellipses for each mooring
%  (shallow depth vs. deep depth, overlaid in the same axes per mooring)
%  ========================================================================

depthColors = [0.85 0.33 0.10;    % shallow bin -> orange
               0.00 1 1];   % deep bin    -> blue  0.00 0.45 0.74]; 

figure('Color', 'w', 'Position', [100 100 1200 700]);

for i = 1:length(names)
    subplot(2, 3, i); hold on; axis equal; grid on;

    Lsmaj = results.(names{i}).M2.Lsmaj;
    Lsmin = results.(names{i}).M2.Lsmin;
    theta = results.(names{i}).M2.theta;

    %legendEntries = {};
    for d = 1:nDepths
        if isnan(Lsmaj(d))
            continue
        end
        [ex, ey] = tidal_ellipse_xy(Lsmaj(d), Lsmin(d), theta(d));
        plot(ex, ey, '-', 'Color', depthColors(d, :), 'LineWidth', 3);
        grid off;
        axis off;
        xlim([-0.065 0.065])
        ylim([-0.06 0.06])
        xticks([])
        yticks([])
        %legendEntries{end+1} = sprintf('%.1f m', depthBins(d)); 
    end

    %title(strrep(names{i}, '_', '\_'));
    %xlabel('East vel (cm/s)'); ylabel('North vel (cm/s)');
    % if ~isempty(legendEntries)
    %     legend(legendEntries, 'Location', 'best');
    % end
end
sgtitle('M2 Tidal Current Ellipses by Mooring');

%% ========================================================================
%  Helper function: generate ellipse x,y points from UTide ellipse params
%  ========================================================================
function [ex, ey] = tidal_ellipse_xy(Lsmaj, Lsmin, theta)
    % Lsmaj, Lsmin : semi-major / semi-minor axis (speed units)
    % theta        : inclination of major axis (deg, math convention from UTide)
    phi = linspace(0, 2*pi, 100);
    x0  = Lsmaj * cos(phi);
    y0  = Lsmin * sin(phi);

    th  = deg2rad(theta);
    R   = [cos(th) -sin(th); sin(th) cos(th)];
    xy  = R * [x0; y0];

    ex = xy(1, :);
    ey = xy(2, :);
end
