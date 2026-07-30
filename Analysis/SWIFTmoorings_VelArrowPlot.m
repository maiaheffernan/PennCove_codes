%%% Tidal flow at all the SWIFT moorings %%%

%%% Maia Heffernan, July 29, 2026 

% This script takes the velocites from all SWIFT signature data (once
% uploaded and cleaned) and plots velocity arrows at a surface and bottom
% bin at different tidal stages. 

clear all, close all

%% load in the SWIFT sig data

% this is coming from the JunJul 2026 period

SWIFT09_WWS = load('SWIFT09_SDcard_JunJul2026_SIG.mat');

SWIFT18_WWN = load('SWIFT18_SDcard_JunJul2026_SIG.mat');

% SWIFT 26 (inner north) is giving me grief in the cleaning

SWIFT27_LJS = load('SWIFT27_SDcard_JunJul2026_SIG.mat');

SWIFT28_LJN = load('SWIFT28_SDcard_JunJul2026_SIG.mat');


% SWIFT 29 (inner south) is giving me grief in the cleaning
