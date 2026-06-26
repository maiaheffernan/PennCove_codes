%%%% Averaging the readings from the YSI 600LS bucket test %%%%
%%% Maia Heffernan, March 2026 %%%

% On Saturday, March 21, I did a bucket test to compare the conductivity
% readings from the RBR Concerto, Alex's YSI 600LS sensors, and Emily's YSI
% ExoSonde2 sensors. 
% I programmed Alex's YSIs to read every second as there was not a convenient way to
% write down those values in live time during the bucket test. So, this
% script takes the values from each bucket test round and averages them to
% get a value for each instrument to compart them. The comparison between
% all the instruments occures in teh YSI_bucketTest.gsheet document in the
% M2O2 Drive. Path is Penn Cove
% 2026/Instrumentation/TestingAndCalibration/BucketTest



close all; clear all;

%% read in the data


LS2001_bt = readtable("BucketTest_15M002001_march212026.txt");
LS2002_bt = readtable("BucketTest_15M002002_march212026.txt");
LS2004_bt = readtable("BucketTest_15M002004_march212026.txt");
LS2005_bt = readtable("BucketTest_15M002005_march212026.txt");
LS2006_bt = readtable("BucketTest_15M002006_march212026.txt");

% ----------------------------
% changing the variable names
% ----------------------------

% the sensor with the SN that ends in 2005 does not have TDS, so it only
% has 9 variables
    Varnames9 = {'Date', 'Time','Temp_C', 'SpCond_mSpercm', 'Cond_uSpercm', 'Sal_ppt', 'Press_psia', 'Depth_m', 'Battery_V'};

    Varnames10 = {'Date', 'Time','Temp_C', 'SpCond_mSpercm', 'Cond_uSpercm','TDS_gperL','Sal_ppt', 'Press_psia', 'Depth_m', 'Battery_V'};

LS2001_bt.Properties.VariableNames= Varnames10;
LS2002_bt.Properties.VariableNames= Varnames10;
LS2004_bt.Properties.VariableNames= Varnames10;
LS2005_bt.Properties.VariableNames= Varnames9;
LS2006_bt.Properties.VariableNames= Varnames10;

