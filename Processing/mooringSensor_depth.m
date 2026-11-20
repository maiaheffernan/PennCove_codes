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
[ysi4m_idx, ysi4m_d] = knnsearch([ysiData.LJN_4m.DateTime], datetime([SWIFT28.SWIFT.time], 'ConvertFrom', 'datenum'));
[ysi8m_idx, ysi8m_d] = knnsearch([ysiData.LJN_8m.DateTime], datetime([SWIFT28.SWIFT.time], 'ConvertFrom', 'datenum'));

%LJS
[ysi4m_idx, ysi4m_d] = knnsearch([ysiData.LJS_4m.DateTime], datetime([SWIFT27.SWIFT.time], 'ConvertFrom', 'datenum'));
[ysi8m_idx, ysi11m_d] = knnsearch([ysiData.LJS_8m.DateTime], datetime([SWIFT27.SWIFT.time], 'ConvertFrom', 'datenum'));

%InnerNorth

[duoInN_idx, duoInN_d] = knnsearch(datetime([duoData.DuoTD_data.InnerNorth_sn240149.data.tstamp], 'ConvertFrom', 'datenum'), datetime([SWIFT26.SWIFT.time], 'ConvertFrom', 'datenum'));

%inner south
[duoInS_idx, duoInS_d] = knnsearch(datetime([duoData.DuoTD_data.InnerSouth_sn240151.data.tstamp], 'ConvertFrom', 'datenum'), datetime([SWIFT29.SWIFT.time], 'ConvertFrom', 'datenum'));




%% fit a catenary function to describe the 'hang' of the line knowing the anchor location, the SWIFT's location, and the location of the duo or YSI sensor on the line


%% figure out what the maximum error is on this based on the line length from the pneumatic to the SWIFT

%% load in the other sensor data



%% assign the depths on the line to each sensor serial number


%% knowing the catenary function I fit, fit each sensor's length along the line to the new function that describes the catenary of the mooring


%% visualize the mooring catenary and the sensors' locations a couple timesteps