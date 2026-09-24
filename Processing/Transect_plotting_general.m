%%% Plotting transect data %%%


% Maia H., September 9, 2026

% A general transect plotting script for the monthly transects. There are
% many different plots that are generated in this script, all related to
% the transects.

% Before working in this script, make sure you have passed the cleaned and
% corrected CTD and ADCP data through the matchCTDtoADCP.m function (in
% Processing in the GitHub) to add lat and lon values to the CTD casts that
% match up to the nearest ADCP reading in time.


clear all, close all

%% load in the data you are interested in working with 


% ADCP

    % August
    
    adcp_ebb = load('Echo_ADCP_26Aug2026_ebb_cleaned.mat');
    adcp_flood = load('Echo_ADCP_26Aug2026_flood_cleaned.mat');


% casting CTDO

    % August

    ctd_ebb = load("Echo_CTD_26Aug2026_ebb_L2_withlatlon.mat");
    ctd_flood = load("Echo_CTD_26Aug2026_flood_L2_withlatlon.mat");

%% Plot the transect paths


figure(1); clf; 

s1 = subplot(2,1,1);
hold on

for ii = 1:numel(ctd_ebb.CTD_ebb.data)
    ce(ii) = [ctd_ebb.CTD_ebb.data(ii).tstamp(10,:)];
    scatter([ctd_ebb.CTD_ebb.data(ii).lon], [ctd_ebb.CTD_ebb.data(ii).lat], 10, ce(ii), 'filled');
end

colormap('parula');
cb = colorbar;
cb.TickLabels = datestr(cb.Ticks, 'mm/dd HH:MM'); 
ylabel(cb, 'Time (UTC)');
ylabel('Latitude')
xlabel('Longitude')
title('August 26, 2026 CTD tracks')
subtitle('Ebb')



s2 = subplot(2,1,2);
hold on

for iii = 1:numel(ctd_flood.CTD_flood.data)
    cf(iii) = [ctd_flood.CTD_flood.data(iii).tstamp(10,:)];
    scatter([ctd_flood.CTD_flood.data(iii).lon], [ctd_flood.CTD_flood.data(iii).lat], 10, cf(iii), 'filled');
end
colormap('parula');
cb = colorbar;
cb.TickLabels = datestr(cb.Ticks, 'mm/dd HH:MM'); 
ylabel(cb, 'Time (UTC)');
ylabel('Latitude')
subtitle('Flood')


% save figure

targetFolder = '/Users/heffem3/Documents/GitHub/PennCove_codes/Figures/TransectSurveys'; 
fileName = 'Echo_surveyTracks_26Aug2026.png';
fullPath = fullfile(targetFolder, fileName);

saveas(gcf, fullPath);


%% add datetimes to the files


adcp_ebb.datetime = datetime([adcp_ebb.time], "ConvertFrom", "datenum");
adcp_flood.datetime = datetime([adcp_flood.time], "ConvertFrom", "datenum");


ctd_ebb.CTD_ebb.datetime = datetime([ctd_ebb.CTD_ebb.data.tstamp], "ConvertFrom", "datenum");
ctd_flood.CTD_flood.datetime = datetime([ctd_flood.CTD_flood.data.tstamp], "ConvertFrom", "datenum");


%% Plot pcolors of the CTD and the velocity from the ADCP for the whole timeseries


% channel numbers for hte CTD:
    % channel 7: depth
    % channel 8: salinity
    % channel 2: temp
    % channel 14: DO mg/L

%% Build CTD matrices from the cast struct array 
S = ctd_ebb.CTD_ebb;
casts = S.data;                        % 303x1 struct array, one per cast
nCasts = numel(casts);
nSamples = size(casts(1).values, 1);   % 128, confirmed uniform across all casts

depthMat = nan(nSamples, nCasts);
salMat   = nan(nSamples, nCasts);
tempMat  = nan(nSamples, nCasts);
doMat    = nan(nSamples, nCasts);
timeMat  = NaT(nSamples, nCasts);

for i = 1:nCasts
    v = casts(i).values;
    depthMat(:,i) = v(:,7);    % Depth (m)
    salMat(:,i)   = v(:,8);    % Salinity (PSU)
    tempMat(:,i)  = v(:,2);    % Temperature (°C)
    doMat(:,i)    = v(:,14);   % Dissolved oxygen (mg/L)
    timeMat(:,i)  = datetime(casts(i).tstamp, 'ConvertFrom', 'datenum');
end

%% ---- Plotting ----
figure(2); clf;

s3 = subplot(4,1,1); % ADCP velocity
    hold on
    pcolor(adcp_ebb.datetime, adcp_ebb.z, adcp_ebb.east');
        shading flat
        cmap = cmocean('balance');
        cb = colorbar;
        caxis([-0.5 0.5]);
        cb.Label.String = 'East / west velocity (ms^{-1})';
        cb.Label.FontSize = 14;
    plot(adcp_ebb.datetime, adcp_ebb.depth, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    set(gca, 'YDir', 'reverse')
    ylabel('Depth (m)', 'FontSize', 14);
    title('Ebb transect data', 'FontSize', 18)
    subtitle('Velocity from ADCP', 'FontSize', 16)
    hold off

s4 = subplot(4,1,2); % CTD salinity
    hold on
    pcolor(timeMat, depthMat, salMat);
        shading flat
        cmap = cmocean('haline');
        cb2 = colorbar;
        caxis([8 30]);
        cb2.Label.String = 'Salinity (PSU)';
        cb2.Label.FontSize = 14;
    plot(adcp_ebb.datetime, adcp_ebb.depth, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    set(gca, 'YDir', 'reverse')
    ylabel('Depth (m)', 'FontSize', 14);
    subtitle('Salinity', 'FontSize', 16)
    hold off

s5 = subplot(4,1,3); % CTD temperature
    hold on
    pcolor(timeMat, depthMat, tempMat);
        shading flat
        cmap = cmocean('thermal');
        cb2 = colorbar;
        caxis([10 30]);
        cb2.Label.String = 'Temperature (°C)';
        cb2.Label.FontSize = 14;
    plot(adcp_ebb.datetime, adcp_ebb.depth, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    set(gca, 'YDir', 'reverse')
    ylabel('Depth (m)', 'FontSize', 14);
    subtitle('Temperature', 'FontSize', 16)
    hold off

s6 = subplot(4,1,4); % CTD DO
    hold on
    pcolor(timeMat, depthMat, doMat);
        shading flat
        cmap = cmocean('matter');
        cb2 = colorbar;
        caxis([0 16]);
        cb2.Label.String = 'Dissolved oxygen (mg/L)';
        cb2.Label.FontSize = 14;
    plot(adcp_ebb.datetime, adcp_ebb.depth, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    set(gca, 'YDir', 'reverse')
    ylabel('Depth (m)', 'FontSize', 14);
    subtitle('Dissolved oxygen', 'FontSize', 16)
    hold off

linkaxes([s3 s4 s5 s6], 'xy')

%% Plot pcolors of the CTD and velocity data from the ADCP for each lap leg

% add bottom track!

%% Plot average bottom and surface DO concentrations from the CTDs at each lat/lon value



%% Plot waterfall plots of CTD properties for each leg

% add bottom track!
