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



%% 