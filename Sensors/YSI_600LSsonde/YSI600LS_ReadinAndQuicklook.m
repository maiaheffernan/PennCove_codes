%%%% Averaging the readings from the YSI 600LS bucket test %%%%
%%% Maia Heffernan, March 2026 %%%

% updated July 19 2026 for loading in sensor mooring data

close all; clear all;

%% read in the data

% == make sure you are in the Data folder for the month you are interested
% in ===

% will need to change the file names to adjust for the proper month

LJN_4m = readtable('LoveJoyNorth_MaytoJun2026/YSI600LS/LoveJoyNorth_MaytoJune2026_sn2005.txt');
LJN_8m = readtable('LoveJoyNorth_MaytoJun2026/YSI600LS/LoveJoyNorth_MaytoJune2026_sn2006.txt');

LJS_4m = readtable('LoveJoySouth_MaytoJun2026/YSI600LS/LoveJoySouth_MaytoJune_4m_sn15M002001.txt');
LJS_11m = readtable('LoveJoySouth_MaytoJun2026/YSI600LS/LoveJoySouth_MaytoJune_9m_sn15M002004.txt');


%% ----------------------------
% changing the variable names
% ----------------------------

    Varnames = {'Date', 'Time','Temp_C', 'SpCond_mSpercm', 'Cond_uSpercm','Resistance_Ohm*cm','TDS_gperL','Sal_ppt', 'Press_psia', 'Depth_m', 'Battery_V'};

LJS_4m.Properties.VariableNames= Varnames;
LJS_11m.Properties.VariableNames= Varnames;
LJN_4m.Properties.VariableNames= Varnames;
LJN_8m.Properties.VariableNames= Varnames;

%% making the date and time columns one datetime column
 
% make hte date column a datetime and add it to the time column (which is
% alreay a duration)

dateCol_LJN4m = datetime(LJN_4m.Date, 'InputFormat', 'yyyy/MM/dd'); 
LJN_4m.DateTime = dateCol_LJN4m + LJN_4m.Time;

dateCol_LJN8m = datetime(LJN_8m.Date, 'InputFormat', 'yyyy/MM/dd'); 
LJN_8m.DateTime = dateCol_LJN8m + LJN_8m.Time;

dateCol_LJS4m = datetime(LJS_4m.Date, 'InputFormat', 'yyyy/MM/dd'); 
LJS_4m.DateTime = dateCol_LJS4m + LJS_4m.Time;

dateCol_LJS11m = datetime(LJS_11m.Date, 'InputFormat', 'yyyy/MM/dd'); 
LJS_11m.DateTime = dateCol_LJS11m + LJS_11m.Time;

%% plot raw data

% Plot temperature data from each site
figure;
hold on;
plot(LJN_4m.DateTime, LJN_4m.Temp_C, 'DisplayName', 'LJN 4m');
plot(LJN_8m.DateTime, LJN_8m.Temp_C, 'DisplayName', 'LJN 8m');
plot(LJS_4m.DateTime, LJS_4m.Temp_C, 'DisplayName', 'LJS 4m');
plot(LJS_11m.DateTime, LJS_11m.Temp_C, 'DisplayName', 'LJS 11m');
hold off;
xlabel('Date and Time');
ylabel('Temperature (°C)');
title('Temperature Readings from YSI 600LS');
legend show;
grid on;

% Plot salinity data from each site
figure;
hold on;
plot(LJN_4m.DateTime, LJN_4m.Sal_ppt, 'DisplayName', 'LJN 4m');
plot(LJN_8m.DateTime, LJN_8m.Sal_ppt, 'DisplayName', 'LJN 8m');
plot(LJS_4m.DateTime, LJS_4m.Sal_ppt, 'DisplayName', 'LJS 4m');
plot(LJS_11m.DateTime, LJS_11m.Sal_ppt, 'DisplayName', 'LJS 11m');
hold off;
xlabel('Date and Time');
ylabel('Salinity (ppt)');
title('Salinity Readings from YSI 600LS');
legend show;
grid on;

%% clean using the hampel filter


sensors = {'LJN_4m', 'LJN_8m', 'LJS_4m', 'LJS_11m'};

for i = 1:length(sensors)
    d = eval(sensors{i});
    temp_raw = d.Temp_C;  % Extract temperature data
    temp_clean = hampel(temp_raw, 5, 3);  % Apply Hampel filter: window = 5, threshold = 3 std devs
    d.Temp_C_cleaned = temp_clean;  % Store cleaned data back

    sal_raw = d.Sal_ppt;
    sal_clean = hampel(sal_raw, 5, 3);
    d.Sal_ppt_cleaned = sal_clean;


    assignin('base', sensors{i}, d);  % Store cleaned data back to the base workspace
    clear d
end

%% plot clearned data

% Plot temperature data from each site
figure;
hold on;
plot(LJN_4m.DateTime, LJN_4m.Temp_C_cleaned, 'DisplayName', 'LJN 4m');
plot(LJN_8m.DateTime, LJN_8m.Temp_C_cleaned, 'DisplayName', 'LJN 8m');
plot(LJS_4m.DateTime, LJS_4m.Temp_C_cleaned, 'DisplayName', 'LJS 4m');
plot(LJS_11m.DateTime, LJS_11m.Temp_C_cleaned, 'DisplayName', 'LJS 11m');
hold off;
xlabel('Date and Time');
ylabel('Temperature (°C)');
title('Cleaned temperature Readings from YSI 600LS');
legend show;


% Plot salinity data from each site
figure;
hold on;
plot(LJN_4m.DateTime, LJN_4m.Sal_ppt_cleaned, 'DisplayName', 'LJN 4m');
plot(LJN_8m.DateTime, LJN_8m.Sal_ppt_cleaned, 'DisplayName', 'LJN 8m');
plot(LJS_4m.DateTime, LJS_4m.Sal_ppt_cleaned, 'DisplayName', 'LJS 4m');
plot(LJS_11m.DateTime, LJS_11m.Sal_ppt_cleaned, 'DisplayName', 'LJS 11m');
hold off;
xlabel('Date and Time');
ylabel('Salinity (ppt)');
title('Cleaned salinity Readings from YSI 600LS');
legend show;





