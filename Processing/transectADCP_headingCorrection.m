%%% Transecting ADCP heading correction %%%

% maia heffernan, july 10 2026

% this coordinate transformation is done on data from a Teledyne RDI
% Workhorse Sentinel 1200kHz ADCP that we use for transecting through PEnn
% Cove 

clear all, close all

%% Step 1. load in the ADCP data from June transecting

load Echo_ADCP_24Jun2026_ebb_cleaned.mat

%load Echo_ADCP_24Jun2026_flood_cleaned.mat

%% find the different transects and locations

figure(1)
scatter(lon, lat, 15, time, 'filled'); 
colormap(jet);  % or parula, turbo, viridis
cb = colorbar;
ylabel(cb, 'Time');
xlabel('Longitude');
ylabel('Latitude');
title('Transect Path Colored by Time');
%axis equal; 
grid on;


%% Step 2. determine course over ground (COG) from the Lat + Lon values


%% compare COG to ensemble heading in the exported matlab files 

% the difference is the rotation correction


%% compare reciprocal transects for consistency




%% make sure PCA of tidal flow that are mostly east/west that agree with the tidal ellipses from the moorings