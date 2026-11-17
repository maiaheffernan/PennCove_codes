%%% Filtering the data from the deployment. Several different methods are used to filter the data and the user will decide which is the best method
%%% based on the plots that are made.

%%% Created by Maia Heffernan, Nov. 16, 2026

clear, close all

%% read in the concatenated data from the deployment

% testing this with the soloT data

soloT = load('/Users/heffem3/Library/CloudStorage/GoogleDrive-heffem3@uw.edu/Shared drives/M2O2/Penn Cove 2026/ConcatenatedData/SoloTdata_MayOct2026_concatenated_L1.mat');


%% try the Hampel filter



%% try a butterworth filter


%% try a moving average filter


%% plot up all the different methods and compare them to the original data