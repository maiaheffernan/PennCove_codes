%%%% Averaging the readings from the YSI 600LS bucket test %%%%
%%% Maia Heffernan, March 2026 %%%

% updated July 19 2026 for loading in sensor mooring data

close all; clear all;

%% read in the data

% == make sure you are in the Data folder for the month you are interested
% in ===

% will need to change the file names to adjust for the proper month

LJN_4m = readtable('LoveJoyNorth_MaytoJun2026/YSI600LS/LoveJoyNorth_MaytoJune2026_sn2005.txt'); %'LoveJoyNorth_MaytoJun2026/YSI600LS/LoveJoyNorth_MaytoJune2026_sn2005.txt', 'LoveJoyNorth_JunJul2026/YSI_600LS/LoveJoyNorth_JunJul2026_4m_sn2005.txt'
LJN_8m = readtable('LoveJoyNorth_MaytoJun2026/YSI600LS/LoveJoyNorth_MaytoJune2026_sn2006.txt'); % LoveJoyNorth_MaytoJun2026/YSI600LS/LoveJoyNorth_MaytoJune2026_sn2006.txt, 'LoveJoyNorth_JunJul2026/YSI_600LS/LoveJoyNorth_JunJul2026_9m_sn2006.txt'

LJS_4m = readtable('LoveJoySouth_MaytoJun2026/YSI600LS/LoveJoySouth_MaytoJune_4m_sn15M002001.txt'); % LoveJoySouth_MaytoJun2026/YSI600LS/LoveJoySouth_MaytoJune_4m_sn15M002001.txt, LoveJoySouth_JunJul2026/YSI_600LS/LoveJoySouth_JunJul2026_4m_sn2001.txt
LJS_11m = readtable('LoveJoySouth_MaytoJun2026/YSI600LS/LoveJoySouth_MaytoJune_9m_sn15M002004.txt'); % LoveJoySouth_MaytoJun2026/YSI600LS/LoveJoySouth_MaytoJune_9m_sn15M002004.txt, LoveJoySouth_JunJul2026/YSI_600LS/LoveJoySouth_JunJul2026_9m_sn2004.txt


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


%% adding a time cutoff based on start and end times for monthly sampling


startTime = datetime(2026, 5, 27, 0, 0, 0);
endTime = datetime(2026, 6, 23, 20, 40, 0);
    % for junjul
    % startTime = datetime(2026, 6, 26, 00, 0, 0);
    % endTime = datetime(2026, 7, 21, 16, 30, 0);
% 

tableNames = {'LJN_4m', 'LJN_8m', 'LJS_4m', 'LJS_11m'};

timeVarName = 'DateTime';  

tables = cellfun(@(n) evalin('base', n), tableNames, 'UniformOutput', false);

% --- Loop and apply cutoff ---
for i = 1:numel(tables)
    T = tables{i};
    
    % logical index of rows OUTSIDE the allowed window
    outOfRange = T.(timeVarName) < startTime | T.(timeVarName) > endTime;
    
    % all columns except the time column
    dataVars = setdiff(T.Properties.VariableNames, {timeVarName});
    
    for v = 1:numel(dataVars)
        col = T.(dataVars{v});
        
        if ischar(col) || iscellstr(col) || isstring(col)
            col = str2double(col);   % convert text to numeric because the data is class 'char' (ugh, why??)
        end
        
        col(outOfRange, :) = NaN;
        T.(dataVars{v}) = col;
    end
    
    assignin('base', tableNames{i}, T);
end




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

%% save the raw data 

save YSI600LSdata_MayJun2026_raw.mat LJN_4m LJN_8m LJS_11m LJS_4m
%% clean using the hampel filter


sensors = {'LJN_4m', 'LJN_8m', 'LJS_4m', 'LJS_11m'};
for i = 1:length(sensors)
    d = eval(sensors{i});
    
    temp_raw = d.Temp_C;  % Extract temperature data
    [~, isOutlier_temp] = hampel(temp_raw, 2, 3);  % window = 2 because the function grabs two data points from either side of the middle point. Since the data is taken every 10 minutes, this compares to 40 minutes of data. Threshold = 3 std devs is standard.
    temp_clean = temp_raw;
    temp_clean(isOutlier_temp) = NaN;              % NaN out flagged points
    d.Temp_C_cleaned = temp_clean;
    
    sal_raw = d.Sal_ppt;
    [~, isOutlier_sal] = hampel(sal_raw, 2, 3);
    sal_clean = sal_raw;
    sal_clean(isOutlier_sal) = NaN;
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

%% save cleaned data


save YSI600LSdata_MayJun2026_L2.mat LJN_4m LJN_8m LJS_11m LJS_4m




% Save cleaned data to .mat files for each sensor
% for i = 1:length(sensors)
%     cleanedData = eval(sensors{i});
%     save([sensors{i} 'YSI600LS_L2.mat'], 'cleanedData');
% end




