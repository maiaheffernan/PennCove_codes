%%% PME miniDOT readin and quicklook %%%

%%% Maia, April 2026

clear all; close all;


%% load in the data


% Define base paths
scriptDir   = fileparts(mfilename('fullpath'));
miniDOTDir  = fullfile(scriptDir, 'BucketTest2_23Apr2026', 'miniDOTs');
bucketDir   = fullfile(scriptDir, 'BucketTest2_23Apr2026');


% Load in the data
SN279558     = readtable(fullfile(miniDOTDir, '7450-279558',  '279558_Cat_BT2.TXT'));
SN305219     = readtable(fullfile(miniDOTDir, '7450-305219',  '305219_Cat_BT2.TXT'));
SN372740     = readtable(fullfile(miniDOTDir, '7450-372740',  '372740_Cat_BT2.TXT'));
SN419387     = readtable(fullfile(miniDOTDir, '7450-419387',  '419387_Cat_BT2.TXT'));
SN445289     = readtable(fullfile(miniDOTDir, '7450-445289',  '445289_Cat_BT2.TXT'));
SN454936     = readtable(fullfile(miniDOTDir, '7450-454936',  '454936_Cat_BT2.TXT'));
RBRTodo_comp = RSKreaddata(RSKopen(fullfile(bucketDir, '241791_20260423_1406.rsk')));





        % old readins that do not work with everything in different
        % directories
        % SN279558 = readtable("279558_Cat_BT2.TXT");
        % 
        % SN305219 = readtable("7450-305219/305219_Cat_BT2.TXT");
        % 
        % SN372740 = readtable("7450-372740/372740_Cat_BT2.TXT");
        % 
        % SN419387 = readtable("7450-419387/419387_Cat_BT2.TXT");
        % 
        % SN445289 = readtable("7450-445289/445289_Cat_BT2.TXT");
        % 
        % SN454936 = readtable("7450-454936/454936_Cat_BT2.TXT");
        % 
        % RBRTodo_comp = RSKreaddata(RSKopen('241791_20260423_1406.rsk'));

%% pull out the RBR data

RBRtemp = RBRTodo_comp.data.values(:,1);
RBRdo_umolperL = RBRTodo_comp.data.values(:,2);
RBR_time = datetime(RBRTodo_comp.data.tstamp(:,:), "ConvertFrom", "datenum", "Format",'uuuu-MM-dd HH:mm:ss');

%% break up the time segments

startTime = datetime('2026-04-23 17:23:00', 'Format','uuuu-MM-dd HH:mm:ss');
endTime = datetime('2026-04-23 20:50:00', 'Format','uuuu-MM-dd HH:mm:ss');

% Filter the RBR data based on the specified time range
timeMask = (RBR_time >= startTime) & (RBR_time <= endTime);
filteredRBRtemp = RBRtemp(timeMask);
filteredRBRdo_umolperL = RBRdo_umolperL(timeMask);
filteredRBR_time = RBR_time(timeMask);

% do this for the times and data for the miniDOTS

timeMaskmini_1 = (SN279558.UTC_Date___Time >= startTime) & (SN279558.UTC_Date___Time <= endTime);
filtered279558 = SN279558(timeMaskmini_1, :);

timeMaskmini_2 = (SN305219.UTC_Date___Time >= startTime) & (SN305219.UTC_Date___Time <= endTime);
filtered305219 = SN305219(timeMaskmini_2, :);

timeMaskmini_3 = (SN372740.UTC_Date___Time >= startTime) & (SN372740.UTC_Date___Time <= endTime);
filtered372740 = SN372740(timeMaskmini_3, :);

timeMaskmini_4 = (SN419387.UTC_Date___Time >= startTime) & (SN419387.UTC_Date___Time <= endTime);
filtered419387 = SN419387(timeMaskmini_4, :);

timeMaskmini_5 = (SN445289.UTC_Date___Time >= startTime) & (SN445289.UTC_Date___Time <= endTime);
filtered445289 = SN445289(timeMaskmini_5, :);

timeMaskmini_6 = (SN454936.UTC_Date___Time >= startTime) & (SN454936.UTC_Date___Time <= endTime);
filtered454936 = SN454936(timeMaskmini_6, :);


% using the function O2_umol_to_sat.m 
    % RBRdo_sat = O2_umolL_to_sat(RBRdo_umolperL, RBRtemp, salinity);

% convert µmol/L to mg/L

% Convert filtered RBR data from µmol/L to mg/L
RBRdo_mgperL = filteredRBRdo_umolperL * 32 / 1000; % Assuming O2 molar mass is 32 g/mol

%% plotting to DO

figure(1);

p1 = plot(filteredRBR_time, RBRdo_mgperL, 'b-', 'LineWidth', 2.0);
hold on;

p2 = plot(filtered279558.UTC_Date___Time, filtered279558.DissolvedOxygen, 'LineWidth', 1.5);

hold on;

p3 = plot(filtered305219.UTC_Date___Time, filtered305219.DissolvedOxygen, 'LineWidth', 1.5);

hold on;

p4 = plot(filtered372740.UTC_Date___Time, filtered372740.DissolvedOxygen, 'LineWidth', 1.5);

hold on;

p5 = plot(filtered419387.UTC_Date___Time, filtered419387.DissolvedOxygen, 'LineWidth', 1.5);

hold on;

p6 = plot(filtered445289.UTC_Date___Time, filtered445289.DissolvedOxygen, 'LineWidth', 1.5);
hold on;

p7 = plot(filtered454936.UTC_Date___Time, filtered454936.DissolvedOxygen, 'LineWidth', 1.5);

hold on;

xl = xline(filtered454936.UTC_Date___Time(23, :), '-', 'Stirred bucket','DisplayName','Stirred');
xl.LabelVerticalAlignment = 'middle';
xl.LabelHorizontalAlignment = 'center';

xl2 = xline(filtered454936.UTC_Date___Time(39, :), '-', 'Ice added','DisplayName','Ice added');
xl2.LabelVerticalAlignment = 'middle';
xl2.LabelHorizontalAlignment = 'center';



xlabel("Time")
ylabel("DO concentration (mg/L)")
title("miniDOT comparison")

legend([p1 p2 p3 p4 p5 p6 p7 xl xl2], "RBR T.ODO", "SN279558", "SN305219", "SN372740", "SN419387", "SN445289", "SN454936");

%% plotting the temperature

figure(2);

p8 = plot(filteredRBR_time, filteredRBRtemp, 'b-', 'LineWidth', 2.0);
hold on;

p9 = plot(filtered279558.UTC_Date___Time, filtered279558.Temperature, 'LineWidth', 1.5);

hold on;

p10 = plot(filtered305219.UTC_Date___Time, filtered305219.Temperature, 'LineWidth', 1.5);

hold on;

p11 = plot(filtered372740.UTC_Date___Time, filtered372740.Temperature, 'LineWidth', 1.5);

hold on;

p12 = plot(filtered419387.UTC_Date___Time, filtered419387.Temperature, 'LineWidth', 1.5);

hold on;

p13 = plot(filtered445289.UTC_Date___Time, filtered445289.Temperature, 'LineWidth', 1.5);
hold on;

p14 = plot(filtered454936.UTC_Date___Time, filtered454936.Temperature, 'LineWidth', 1.5);


hold on;

xl3 = xline(filtered454936.UTC_Date___Time(23, :), '-', 'Stirred bucket','DisplayName','Stirred');
xl3.LabelVerticalAlignment = 'middle';
xl3.LabelHorizontalAlignment = 'center';

xl4 = xline(filtered454936.UTC_Date___Time(39, :), '-', 'Ice added','DisplayName','Ice added');
xl4.LabelVerticalAlignment = 'middle';
xl4.LabelHorizontalAlignment = 'center';



xlabel("Time")
ylabel("Temperature (°C)")
title("miniDOT temperature comparison")

legend([p8 p9 p10 p11 p12 p13 p14 xl3 xl4], "RBR T.ODO", "SN279558", "SN305219", "SN372740", "SN419387", "SN445289", "SN454936");
