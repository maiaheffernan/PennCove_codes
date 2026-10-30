%%% Trying to fix the timestamps on the casting CTD %%%

% Maia Heffernan, October 2026

clear all, close all

%% Loading in the data

% I am going to base the correct time stamps for the CTD on the timestamps
% from the ADCP. To do this, I am gong to lead in the CTD and ADCP data. I
% will start with the September transects.

% ADCP


adcp_ebb = load('Echo_ADCP_23Sep2026_ebb_cleaned.mat');
adcp_flood = load('Echo_ADCP_23Sep2026_flood_cleaned.mat');


% casting CTDO


ctd_ebb = load("Echo_CTD_23Sep2026_ebb_L2_withlatlon.mat");
ctd_flood = load("Echo_CTD_23Sep2026_flood_L2_withlatlon.mat");

%% This is the original bad plot that I can then use to compare the correct one against



% ===== add datetimes to the files =====


adcp_ebb.datetime = datetime([adcp_ebb.time], "ConvertFrom", "datenum");
adcp_flood.datetime = datetime([adcp_flood.time], "ConvertFrom", "datenum");


ctd_ebb.CTD_ebb.datetime = datetime([ctd_ebb.CTD_ebb.data.tstamp], "ConvertFrom", "datenum");
ctd_flood.CTD_flood.datetime = datetime([ctd_flood.CTD_flood.data.tstamp], "ConvertFrom", "datenum");




% ====== make sure I am only pulling out the first CTD timestep and data
% point for each cast ===== 

% S = ctd_ebb.CTD_ebb;
% casts = S.data;
% nCasts = numel(casts);
% nSamples = size(casts(1).values, 1);

data  = ctd_ebb.CTD_ebb.data;
nCast = numel(data);
nBin  = max(arrayfun(@(d) size(d.values,1), data));   % in case casts differ in length

Z   = nan(nBin, nCast);   % depth (col 7)
Sal = nan(nBin, nCast);   % col 8
Tmp = nan(nBin, nCast);   % col 2
DO  = nan(nBin, nCast);   % col 14

for i = 1:nCast
    v = data(i).values;
    n = size(v,1);
    Z(1:n,i)   = v(:,7);
    Sal(1:n,i) = v(:,8);
    Tmp(1:n,i) = v(:,2);
    DO(1:n,i)  = v(:,14);
end

% One time per cast, as a 1x181 vector
% t = [data.tstamp];             % or use your existing ctd_ebb.CTD_ebb.datetime if it's already 1x181
% T = repmat(t(:)', nBin, 1);    % expand to 116x181 to match Z


% ===== Trying to align the time =====

D = ctd_ebb.CTD_ebb.datetime;            % 116x181 datetime

[~, idx] = max(~isnat(D), [], 1);        % row of first non-NaT in each column
t = D(sub2ind(size(D), idx, 1:size(D,2)));   % 1x181 datetime

T = repmat(t, size(Z,1), 1); % make it a 116x181 of the same time value for each timestamp so it works with pcolor. 
                                % this might seem weird, but otherwise the
                                % time values are not aligned and the ADCP
                                % bottom track is totally skewed


% ========= Check for gaps in the CTD data that are from cleaning script or
% the CTD being turned off for turning between transects ======

% from visual inspection if you run the plotting script, there should be 9
% gaps: one before the transecting and then one in between each leg of the
% transect

[ts, order] = sort(t);                 % make sure they're in time order
ds   = diff(ts);                       % duration between consecutive casts
gapIdx = find(ds > minutes(1));        % index of the cast just before each gap

fprintf('Median cast spacing: %.1f min\n', minutes(median(ds)));
for g = gapIdx(:)'
    fprintf('Gap of %.1f min between %s and %s\n', ...
        minutes(ds(g)), string(ts(g), 'HH:mm:ss'), string(ts(g+1), 'HH:mm:ss'));
end




% ===== Insert blank columns at gaps so pcolor doesn't stretch casts across
% them =====

% apply the time sort to the data matrices (your script sorted t but not these)
Z   = Z(:, order);
Sal = Sal(:, order);
Tmp = Tmp(:, order);
DO  = DO(:, order);
t   = ts;

fillSpacing = minutes(median(ds));     % ~0.6 min: how long the last cast before a gap is drawn

for g = fliplr(gapIdx(:)')             % go backward so earlier indices stay valid
    nanCol = nan(size(Z,1), 1);
    t   = [t(1:g),     t(g) + fillSpacing, t(g+1:end)];
    Z   = [Z(:,1:g),   nanCol, Z(:,g+1:end)];
    Sal = [Sal(:,1:g), nanCol, Sal(:,g+1:end)];
    Tmp = [Tmp(:,1:g), nanCol, Tmp(:,g+1:end)];
    DO  = [DO(:,1:g),  nanCol, DO(:,g+1:end)];
end

T = repmat(t, size(Z,1), 1);           % rebuild the 2-D time matrix to match


% ======= Plotting ======
    
    % channel numbers for hte CTD:
    % channel 7: depth
    % channel 8: salinity
    % channel 2: temp
    % channel 14: DO mg/L

figure(1); clf;

s3 = subplot(5,1,1); % ADCP velocity east
    hold on
    pcolor(adcp_ebb.datetime, adcp_ebb.z, adcp_ebb.east');
        shading flat
        cmap = colormap(gca, cmocean('balance'));
        cb = colorbar;
        caxis([-0.5 0.5]);
        cb.Label.String = 'East / west velocity (ms^{-1})';
        cb.Label.FontSize = 14;
    plot(adcp_ebb.datetime, adcp_ebb.depth, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    set(gca, 'YDir', 'reverse')
    ylabel('Depth (m)', 'FontSize', 14);
    title('Ebb transect data', 'FontSize', 18)
    subtitle('East/west velocity from ADCP', 'FontSize', 16)
    hold off


s4 = subplot(5,1,2); % ADCP velocity north
hold on
pcolor(adcp_ebb.datetime, adcp_ebb.z, adcp_ebb.north');
shading flat
cmap = colormap(gca, cmocean('balance'));
cb = colorbar;
caxis([-0.5 0.5]);
cb.Label.String = 'North / south velocity (ms^{-1})';
cb.Label.FontSize = 14;
plot(adcp_ebb.datetime, adcp_ebb.depth, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
set(gca, 'YDir', 'reverse')
ylabel('Depth (m)', 'FontSize', 14);
subtitle('North/south velocity from ADCP', 'FontSize', 16)
hold off

s5 = subplot(5,1,3); % CTD salinity
    hold on
    pcolor(T, Z, Sal);
        shading flat
        cmap = colormap(gca, cmocean('haline'));
        cb2 = colorbar;
        caxis([8 30]);
        cb2.Label.String = 'Salinity (PSU)';
        cb2.Label.FontSize = 14;
    plot(adcp_ebb.datetime, adcp_ebb.depth, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    set(gca, 'YDir', 'reverse')
    ylabel('Depth (m)', 'FontSize', 14);
    subtitle('Salinity', 'FontSize', 16)
    hold off

s6 = subplot(5,1,4); % CTD temperature
    hold on
    pcolor(T, Z, Tmp);
        shading flat
        cmap = colormap(gca, cmocean('thermal'));
        cb2 = colorbar;
        caxis([10 30]);
        cb2.Label.String = 'Temperature (°C)';
        cb2.Label.FontSize = 14;
    plot(adcp_ebb.datetime, adcp_ebb.depth, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    set(gca, 'YDir', 'reverse')
    ylabel('Depth (m)', 'FontSize', 14);
    subtitle('Temperature', 'FontSize', 16)
    hold off

s7 = subplot(5,1,5); % CTD DO
    hold on
    pcolor(T, Z, DO);
        shading flat
        cmap = colormap(gca, cmocean('matter'));
        cb2 = colorbar;
        caxis([0 16]);
        cb2.Label.String = 'Dissolved oxygen (mg/L)';
        cb2.Label.FontSize = 14;
    plot(adcp_ebb.datetime, adcp_ebb.depth, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    set(gca, 'YDir', 'reverse')
    ylabel('Depth (m)', 'FontSize', 14);
    subtitle('Dissolved oxygen', 'FontSize', 16)
    hold off

linkaxes([s3 s4 s5 s6 s7], 'xy')
%xlim(s3, [min(T) max(T)]);

(set(gcf, 'Position', [100 100 1400 900]))

%% let's fix the time dilation 

% 1) line up the CTD and ADCP starting times

% t_ref  : time vector of the good sensor (seconds), the ADCP
% t_bad  : time vector of the drifting sensor (seconds), the CTD
% y_bad  : data from the drifting sensor

% Matched events: start and end of the recording in each sensor
ref_start = adcp_ebb.time(1);   ref_end = adcp_ebb.time(end);
bad_start = [ctd_ebb.CTD_ebb.data(1).tstamp(5,:)];   bad_end = [ctd_ebb.CTD_ebb.data(end).tstamp(5,:)];

% Dilation factor and offset
a = (ref_end - ref_start) / (bad_end - bad_start);
b = ref_start - a * bad_start;

fprintf('Dilation factor: %.8f (%.2f ppm)\n', a, (a-1)*1e6);

% Corrected time vector
t_corrected = a * [ctd_ebb.CTD_ebb.data.tstamp] + b;




% 2) line up the CTD and ADCP ending times


% 3) there should be a coefficient in there that then I can apply to all
% the values

%% doing the gapping for hte timestamps

for g = fliplr(gapIdx(:)')             % go backward so earlier indices stay valid
    nanCol = nan(size(Z,1), 1);
    t_corrected_gaps   = [t_corrected(1:g),     t_corrected(g) + fillSpacing, t_corrected(g+1:end)];
end

T_corrected_fixed = repmat(t_corrected_gaps, size(Z,1), 1);           % rebuild the 2-D time matrix to match




%%

data = ctd_ebb.CTD_ebb.data;      % 1x181 struct
nCasts = numel(data);

%T = nan(116, nCasts);   % time
Z = nan(116, nCasts);   % depth
DO_conc = nan(116, nCasts);   % dissolved oxygen
Temperature = nan(116, nCasts);   % temperature
Salinity = nan(116, nCasts);   % salinity


for i = 1:nCasts
    %T(:,i) = t_corrected;          % 116x1
    Z(:,i) = data(i).values(:,7);     % depth column (confirm this is column 7)
    DO_conc(:,i) = data(i).values(:,14);    % DO column (confirm this is column 14)
    Temperature(:,i) = data(i).values(:,2); % temperature column
    Salinity(:,i) = data(i).values(:,8); % salinity column

end

%% trying the plotting again


% channel numbers for hte CTD:
% channel 7: depth
% channel 8: salinity
% channel 2: temp
% channel 14: DO mg/L


figure(2); clf;

s8 = subplot(5,1,1); % ADCP velocity east
hold on
pcolor(adcp_ebb.datetime, adcp_ebb.z, adcp_ebb.east');
shading flat
cmap = colormap(gca, cmocean('balance'));
cb = colorbar;
caxis([-0.5 0.5]);
cb.Label.String = 'East / west velocity (ms^{-1})';
cb.Label.FontSize = 14;
plot(adcp_ebb.datetime, adcp_ebb.depth, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
set(gca, 'YDir', 'reverse')
ylabel('Depth (m)', 'FontSize', 14);
title('Ebb transect data', 'FontSize', 18)
subtitle('East/west velocity from ADCP', 'FontSize', 16)
hold off


s9 = subplot(5,1,2); % ADCP velocity north
hold on
pcolor(adcp_ebb.datetime, adcp_ebb.z, adcp_ebb.north');
shading flat
cmap = colormap(gca, cmocean('balance'));
cb = colorbar;
caxis([-0.5 0.5]);
cb.Label.String = 'North / south velocity (ms^{-1})';
cb.Label.FontSize = 14;
plot(adcp_ebb.datetime, adcp_ebb.depth, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
set(gca, 'YDir', 'reverse')
ylabel('Depth (m)', 'FontSize', 14);
subtitle('North/south velocity from ADCP', 'FontSize', 16)
hold off

s10 = subplot(5,1,3); % CTD salinity
hold on
pcolor(t_corrected, Z, Salinity);
shading flat
cmap = colormap(gca, cmocean('haline'));
cb2 = colorbar;
caxis([8 30]);
cb2.Label.String = 'Salinity (PSU)';
cb2.Label.FontSize = 14;
plot(adcp_ebb.time, adcp_ebb.depth, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
set(gca, 'YDir', 'reverse')
ylabel('Depth (m)', 'FontSize', 14);
subtitle('Salinity', 'FontSize', 16)
hold off

s11 = subplot(5,1,4); % CTD temperature
hold on
pcolor(t_corrected,Z, Temperature);
shading flat
cmap = colormap(gca, cmocean('thermal'));
cb2 = colorbar;
caxis([10 30]);
cb2.Label.String = 'Temperature (°C)';
cb2.Label.FontSize = 14;
plot(adcp_ebb.time, adcp_ebb.depth, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
set(gca, 'YDir', 'reverse')
ylabel('Depth (m)', 'FontSize', 14);
subtitle('Temperature', 'FontSize', 16)
hold off

s12 = subplot(5,1,5); % CTD DO
hold on
pcolor(t_corrected,Z, DO_conc);
shading flat
cmap = colormap(gca, cmocean('matter'));
cb2 = colorbar;
caxis([0 16]);
cb2.Label.String = 'Dissolved oxygen (mg/L)';
cb2.Label.FontSize = 14;
plot(adcp_ebb.time, adcp_ebb.depth, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
set(gca, 'YDir', 'reverse')
ylabel('Depth (m)', 'FontSize', 14);
subtitle('Dissolved oxygen', 'FontSize', 16)
hold off

linkaxes([s8 s9 s10 s11 s12], 'xy')
%xlim(s3, [min(T) max(T)]);

(set(gcf, 'Position', [100 100 1400 900]))



% Hey this looks a lot closer!! It looks like the first part of the
% transecting time series the CTD is lagging behind but then ni the middle
% of the time series it lines up well, and then at the end it lines up
% poorly. So I think there are multiple dilations happening...