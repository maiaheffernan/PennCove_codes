%%% A script for plotting the bottom DO from all the moorings %%%

% Maia, September 7 2026

clear all, close all

%% load in the bottom DO data

% May to June

MayJun = load('TODOdata_MayJun2026_L3.mat');

% June to July

JunJul = load('TODOdata_JunJul2026_L3.mat');

% July to August

JulAug = load('TODOdata_JulAug2026_L3.mat');

%% concatenate the data in time

% LJN
LJN_alldata_time = [MayJun.TODO_data.LoveJoyNorth.data.tstamp; JunJul.TODO_data.LoveJoyNorth.data.tstamp; JulAug.TODO_data.LoveJoyNorth.data.tstamp]; 
LJN_alldata_values = [MayJun.TODO_data.LoveJoyNorth.data.values; JunJul.TODO_data.LoveJoyNorth.data.values; JulAug.TODO_data.LoveJoyNorth.data.values]; 

%LJS
LJS_alldata_time = [MayJun.TODO_data.LoveJoySouth.data.tstamp; JunJul.TODO_data.LoveJoySouth.data.tstamp; JulAug.TODO_data.LoveJoySouth.data.tstamp];
LJS_alldata_values = [MayJun.TODO_data.LoveJoySouth.data.values; JunJul.TODO_data.LoveJoySouth.data.values; JulAug.TODO_data.LoveJoySouth.data.values]; 

% Inner N
InnerN_alldata_time = [MayJun.TODO_data.InnerNorth.data.tstamp; JunJul.TODO_data.InnerNorth.data.tstamp; JulAug.TODO_data.InnerNorth.data.tstamp];
InnerN_alldata_values = [MayJun.TODO_data.InnerNorth.data.values; JunJul.TODO_data.InnerNorth.data.values; JulAug.TODO_data.InnerNorth.data.values]; 

% Inner S
InnerS_alldata_time = [MayJun.TODO_data.InnerSouth.data.tstamp; JunJul.TODO_data.InnerSouth.data.tstamp; JulAug.TODO_data.InnerSouth.data.tstamp];
InnerS_alldata_values = [MayJun.TODO_data.InnerSouth.data.values; JunJul.TODO_data.InnerSouth.data.values; JulAug.TODO_data.InnerSouth.data.values]; 


%% make the time vectors datetimes

LJN_alldata_time = datetime(LJN_alldata_time, 'ConvertFrom', 'datenum');
LJS_alldata_time = datetime(LJS_alldata_time, 'ConvertFrom', 'datenum');
InnerN_alldata_time = datetime(InnerN_alldata_time, 'ConvertFrom', 'datenum');
InnerS_alldata_time = datetime(InnerS_alldata_time, 'ConvertFrom', 'datenum');


%% Plot DO in one plot

figure(1); clf;
hold on;
plot(LJN_alldata_time, LJN_alldata_values(:,3), 'b.', 'MarkerSize', 10, 'DisplayName', 'Love Joy North');
plot(LJS_alldata_time, LJS_alldata_values(:,3), 'r.', 'MarkerSize', 10, 'DisplayName', 'Love Joy South');
plot(InnerN_alldata_time, InnerN_alldata_values(:,3), 'g.', 'MarkerSize', 10, 'DisplayName', 'Inner North');
plot(InnerS_alldata_time, InnerS_alldata_values(:,3), 'm.', 'MarkerSize', 10, 'DisplayName', 'Inner South');
% yline for hypoxic threshold
yline(2, 'LineStyle', '--', 'HandleVisibility', 'off')
hold off;
xlabel('Time');
ylabel('Bottom DO [mg/L]');
title('Bottom DO from all moorings');
legend show;
grid off;

%% Plot temperature


figure(2); clf;
hold on;
plot(LJN_alldata_time, LJN_alldata_values(:,1), 'b.', 'MarkerSize', 7, 'DisplayName', 'Love Joy North');
plot(LJS_alldata_time, LJS_alldata_values(:,1), 'r.', 'MarkerSize', 7, 'DisplayName', 'Love Joy South');
plot(InnerN_alldata_time, InnerN_alldata_values(:,1), 'g.', 'MarkerSize', 7, 'DisplayName', 'Inner North');
plot(InnerS_alldata_time, InnerS_alldata_values(:,1), 'm.', 'MarkerSize', 7, 'DisplayName', 'Inner South');
% yline for hypoxic threshold
hold off;
xlabel('Time');
ylabel('Temperature [°C]');
title('Bottom Temperature from all moorings');
legend show;
grid off;


%% Make a figure with subplots

figure(3); clf; 

s1 = subplot(2,1,1);
hold on;
plot(LJN_alldata_time, LJN_alldata_values(:,3), 'b.', 'MarkerSize', 10, 'DisplayName', 'Love Joy North');
plot(LJS_alldata_time, LJS_alldata_values(:,3), 'r.', 'MarkerSize', 10, 'DisplayName', 'Love Joy South');
plot(InnerN_alldata_time, InnerN_alldata_values(:,3), 'g.', 'MarkerSize', 10, 'DisplayName', 'Inner North');
plot(InnerS_alldata_time, InnerS_alldata_values(:,3), 'm.', 'MarkerSize', 10, 'DisplayName', 'Inner South');
% yline for hypoxic threshold
yline(2, 'LineStyle', '--', 'HandleVisibility', 'off')
hold off;
ylabel('Bottom DO [mg/L]');
title('Bottom DO from all moorings');
legend show;
hold off

s2 = subplot(2,1,2);

hold on;
plot(LJN_alldata_time, LJN_alldata_values(:,1), 'b.', 'MarkerSize', 7, 'DisplayName', 'Love Joy North');
plot(LJS_alldata_time, LJS_alldata_values(:,1), 'r.', 'MarkerSize', 7, 'DisplayName', 'Love Joy South');
plot(InnerN_alldata_time, InnerN_alldata_values(:,1), 'g.', 'MarkerSize', 7, 'DisplayName', 'Inner North');
plot(InnerS_alldata_time, InnerS_alldata_values(:,1), 'm.', 'MarkerSize', 7, 'DisplayName', 'Inner South');
% yline for hypoxic threshold
hold off;
xlabel('Time');
ylabel('Temperature [°C]');
title('Bottom temperature from all moorings');
hold off

linkaxes([s1 s2], 'x')

%% save this figure to the outdirectory in github

OutDir = '/Users/heffem3/Documents/GitHub/PennCove_codes/Figures';

% save the figures here

saveas(figure(1), fullfile(OutDir, 'BottomDO_MaytoAug.png'));

saveas(figure(2), fullfile(OutDir, 'BottomTemp_MaytoAug.png'));

saveas(figure(3), fullfile(OutDir, 'Bottom_DOandTemp_MaytoAug.png'));



