%%% Extracting the data that David needs from the SWIFTs %%%

% Maia Heffernan, September 3 2026


% I wrote this script orignially for pulling wind data from the SWIFT
% structure for David Shull. 
% Here are the datum he wants/needs now:
    % wind speed
    % surface DO
    % air temp
    % surface water temp
    % significant wave height
    % wave speed

% This script uses the L2 SWIFT products. 




clear all, close all


%% load in the SWIFT data-- level 3

% ---- MayJun ----

% WWN 

% WWS

% LJN

% LJS

% InnerN

% InnerS






% ---- JunJul ----

% WWN 

% WWS

% LJN

% LJS

% InnerN

% InnerS


% ---- JulAug ----

% WWN 

WWN = load('/Users/heffem3/Desktop/M2O2/SWIFTs/JulAug2026/SWIFT18_SDcard_JulAug2026/SWIFT18_SDcard_JulAug2026_L2.mat');

% WWS

WWS = load('/Users/heffem3/Desktop/M2O2/SWIFTs/JulAug2026/SWIFT09_SDcard_JulAug2026/SWIFT09_SDcard_JulAug2026_L2.mat');


% LJN

LJN = load('/Users/heffem3/Desktop/M2O2/SWIFTs/JulAug2026/SWIFT28_SDcard_JulAug2026/SWIFT28_SDcard_JulAug2026_L2.mat');


% LJS

LJS = load('/Users/heffem3/Desktop/M2O2/SWIFTs/JulAug2026/SWIFT27_SDcard_JulAug2026/SWIFT27_SDcard_JulAug2026_L2.mat');


% InnerN

InnerN = load('/Users/heffem3/Desktop/M2O2/SWIFTs/JulAug2026/SWIFT26_SDcard_JulAug2026/SWIFT26_SDcard_JulAug2026_L2.mat');


% InnerS

InnerS = load('/Users/heffem3/Desktop/M2O2/SWIFTs/JulAug2026/SWIFT29_SDcard_JulAug2026/SWIFT29_SDcard_JulAug2026_L2.mat');



%% concatenate the data into one long time series for each SWIFT

% and example of how to use the catSWIFT function

% Load each month's data
% A = load('SWIFT_June.mat');   % assume variable inside is called SWIFT
% B = load('SWIFT_July.mat');
% C = load('SWIFT_August.mat');
% 
% SWIFT_all = [A.SWIFT, B.SWIFT, C.SWIFT];  % concatenate struct arrays end-to-end
% 
% % Optional: sort by time in case files aren't in order or overlap
% [~, isort] = sort([SWIFT_all.time]);
% SWIFT_all = SWIFT_all(isort);
% 
% % Now run through catSWIFT once
% swift = catSWIFT(SWIFT_all);


%% pull out the necessary data from the structure

% Here is the data David wants/needs:
    % wind speed
    % surface DO
    % air temp
    % surface water temp
    % significant wave height
    % wave speed



% WWN    

for i = 1:length(WWN.SWIFT)
    WWN_data(i).time = datetime(WWN.SWIFT(i).time, 'ConvertFrom', 'datenum');
    WWN_data(i).airTemp_degC  = WWN.SWIFT(i).airtemp;
    WWN_data(i).airPres_bar  = WWN.SWIFT(i).airpres;
    WWN_data(i).waterTemp_degC = WWN.SWIFT(i).watertemp;
    WWN_data(i).salinity_PSU = WWN.SWIFT(i).salinity;
    WWN_data(i).windSpeed_mPers = WWN.SWIFT(i).windspd;
    WWN_data(i).windDir_degfromNorth = WWN.SWIFT(i).winddirT;
    WWN_data(i).sigWaveHeight_m = WWN.SWIFT(i).sigwaveheight;
    WWN_data(i).peakWavePeriod_s = WWN.SWIFT(i).peakwaveperiod;
    WWN_data(i).peakWaveDirection_degfromNorth = WWN.SWIFT(i).peakwavedirT;
    WWN_data(i).metStationHeight_m = WWN.SWIFT(i).metheight;
end


% WWS

for ii = 1:length(WWS.SWIFT)
    WWS_data(ii).time = datetime(WWS.SWIFT(ii).time, 'ConvertFrom', 'datenum');
    WWS_data(ii).airTemp_degC  = WWS.SWIFT(ii).airtemp;
    WWS_data(ii).airPres_bar  = WWS.SWIFT(ii).airpres;
    WWS_data(ii).waterTemp_degC = WWS.SWIFT(ii).watertemp;
    WWS_data(ii).salinity_PSU = WWS.SWIFT(ii).salinity;
    WWS_data(ii).windSpeed_mPers = WWS.SWIFT(ii).windspd;
    WWS_data(ii).windDir_degfromNorth = WWS.SWIFT(ii).winddirT;
    WWS_data(ii).sigWaveHeight_m = WWS.SWIFT(ii).sigwaveheight;
    WWS_data(ii).peakWavePeriod_s = WWS.SWIFT(ii).peakwaveperiod;
    WWS_data(ii).peakWaveDirection_degfromNorth = WWS.SWIFT(ii).peakwavedirT;
    WWS_data(ii).metStationHeight_m = WWS.SWIFT(ii).metheight;
end


% LoveJoy N

for iii = 1:length(LJN.SWIFT)
    LJN_data(iii).time = datetime(LJN.SWIFT(iii).time, 'ConvertFrom', 'datenum');
    LJN_data(iii).airTemp_degC  = LJN.SWIFT(iii).airtemp;
    LJN_data(iii).airPres_bar  = LJN.SWIFT(iii).airpres;
    LJN_data(iii).waterTemp_degC = LJN.SWIFT(iii).watertemp;
    LJN_data(iii).salinity_PSU = LJN.SWIFT(iii).salinity;
    LJN_data(iii).windSpeed_mPers = LJN.SWIFT(iii).windspd;
    LJN_data(iii).windDir_degfromNorth = LJN.SWIFT(iii).winddirT;
    LJN_data(iii).sigWaveHeight_m = LJN.SWIFT(iii).sigwaveheight;
    LJN_data(iii).peakWavePeriod_s = LJN.SWIFT(iii).peakwaveperiod;
    LJN_data(iii).peakWaveDirection_degfromNorth = LJN.SWIFT(iii).peakwavedirT;
    LJN_data(iii).metStationHeight_m = LJN.SWIFT(iii).metheight;
    LJN_data(iii).surfaceDO_umolPerL = LJN.SWIFT(iii).O2conc;
end


% LoveJoy S

for iv = 1:length(LJS.SWIFT)
    LJS_data(iv).time = datetime(LJS.SWIFT(iv).time, 'ConvertFrom', 'datenum');
    LJS_data(iv).airTemp_degC  = LJS.SWIFT(iv).airtemp;
    LJS_data(iv).airPres_bar  = LJS.SWIFT(iv).airpres;
    LJS_data(iv).waterTemp_degC = LJS.SWIFT(iv).watertemp;
    LJS_data(iv).salinity_PSU = LJS.SWIFT(iv).salinity;
    LJS_data(iv).windSpeed_mPers = LJS.SWIFT(iv).windspd;
    LJS_data(iv).windDir_degfromNorth = LJS.SWIFT(iv).winddirT;
    LJS_data(iv).sigWaveHeight_m = LJS.SWIFT(iv).sigwaveheight;
    LJS_data(iv).peakWavePeriod_s = LJS.SWIFT(iv).peakwaveperiod;
    LJS_data(iv).peakWaveDirection_degfromNorth = LJS.SWIFT(iv).peakwavedirT;
    LJS_data(iv).metStationHeight_m = LJS.SWIFT(iv).metheight;
    LJS_data(iv).surfaceDO_umolPerL = LJS.SWIFT(iv).O2conc;
end


% Inner N

for v = 1:length(InnerN.SWIFT)
    InnerN_data(v).time = datetime(InnerN.SWIFT(v).time, 'ConvertFrom', 'datenum');
    % InnerN_data(v).airTemp_degC  = InnerN.SWIFT(v).airtemp;
    % InnerN_data(v).airPres_bar  = InnerN.SWIFT(v).airpres;
    InnerN_data(v).waterTemp_degC = InnerN.SWIFT(v).watertemp;
    InnerN_data(v).salinity_PSU = InnerN.SWIFT(v).salinity;
    % InnerN_data(v).windSpeed_mPers = InnerN.SWIFT(v).windspd;
    % InnerN_data(v).windDir_degfromNorth = InnerN.SWIFT(v).winddirT;
    InnerN_data(v).sigWaveHeight_m = InnerN.SWIFT(v).sigwaveheight;
    InnerN_data(v).peakWavePeriod_s = InnerN.SWIFT(v).peakwaveperiod;
    InnerN_data(v).peakWaveDirection_degfromNorth = InnerN.SWIFT(v).peakwavedirT;
    % InnerN_data(v).metStationHeight_m = InnerN.SWIFT(v).metheight;
    InnerN_data(v).surfaceDO_umolPerL = InnerN.SWIFT(v).O2conc;
    InnerN_data(v).FDOM_ppbQSDE = InnerN.SWIFT(v).FDOM;
end

% Inner S

for vi = 1:length(InnerS.SWIFT)
    InnerS_data(vi).time = datetime(InnerS.SWIFT(vi).time, 'ConvertFrom', 'datenum');
    InnerS_data(vi).airTemp_degC  = InnerS.SWIFT(vi).airtemp;
    InnerS_data(vi).airPres_bar  = InnerS.SWIFT(vi).airpres;
    InnerS_data(vi).waterTemp_degC = InnerS.SWIFT(vi).watertemp;
    InnerS_data(vi).salinity_PSU = InnerS.SWIFT(vi).salinity;
    InnerS_data(vi).windSpeed_mPers = InnerS.SWIFT(vi).windspd;
    InnerS_data(vi).windDir_degfromNorth = InnerS.SWIFT(vi).winddirT;
    InnerS_data(vi).sigWaveHeight_m = InnerS.SWIFT(vi).sigwaveheight;
    InnerS_data(vi).peakWavePeriod_s = InnerS.SWIFT(vi).peakwaveperiod;
    InnerS_data(vi).peakWaveDirection_degfromNorth = InnerS.SWIFT(vi).peakwavedirT;
    InnerS_data(vi).metStationHeight_m = InnerS.SWIFT(vi).metheight;
    InnerS_data(vi).surfaceDO_umolPerL = InnerS.SWIFT(vi).O2conc;
end





%% put that data into a .csv

% WWN

WWN_table = struct2table(WWN_data);
writetable(WWN_table, 'WireWalkerNorth_data.csv');


% WWS

WWS_table = struct2table(WWS_data);
writetable(WWS_table, 'WireWalkerSouth_data.csv');


% LoveJoy North

LJN_table = struct2table(LJN_data);
writetable(LJN_table, 'LoveJoyNorth_data.csv');

% LoveJoy South

LJS_table = struct2table(LJS_data);
writetable(LJS_table, 'LoveJoySouth_data.csv');

% Inner North

InnerN_table = struct2table(InnerN_data);
writetable(InnerN_table, 'InnerNorth_data.csv');


% Inner South

InnerS_table = struct2table(InnerS_data);
writetable(InnerS_table, 'InnerSouth_data.csv');



