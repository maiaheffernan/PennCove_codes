%%%%% Timeseries plot of tide, stratification, DO, and velocity

%%% Originally created for a figure for PECS 2026
% Maia H. July 28, 2026


clear all, close all


%% font sizes for plotting later


set(0, 'DefaultAxesFontSize', 14);
set(0, 'DefaultTextFontSize', 14);
set(0, 'DefaultLegendFontSize', 12);

%% load in the data


% tide data from LJS pressure sensor

MayJun_tide = load('DuoTD_data_InnerNorth_MaytoJun2026_240150_cleaned_L2.mat');
JunJul_tide = load('DuoTD_data_InnerNorth_JunJul2026_240150_cleaned_L2.mat');

% salinity top-bottom data from LJN, SWIFT 28

MayJun_bottomSal = load('mooredConcertoData_MayJun2026_L2.mat');
JunJul_bottomSal = load('mooredConcertoData_JunJul2026.mat');

MayJun_SWIFT28 = load("SWIFT28_SDcard_MayJun2026_L3.mat");
JunJul_SWIFT28 = load("SWIFT28_SDcard_JunJul2026_L3.mat");


% bottom DO data from LJN and LJS

MayJun_bottomDO = load('TODOdata_MayJun2026_L3.mat');
JunJul_bottomDO = load('TODOdata_JunJul2026_L3.mat');

% velocity east/west from LJN, SWIFT28

MayJun_LJNsig = load("SWIFT28_SDcard_MayJun2026_SIG.mat");
JunJul_LJNsig = load("SWIFT28_SDcard_JunJul2026_SIG.mat");


% velocity east/west from LJS, SWIFT 27

MayJun_LJSsig = load("SWIFT27_SDcard_MayJun2026_SIG.mat");
JunJul_LJSsig = load("SWIFT27_SDcard_JunJul2026_SIG.mat");

%% concatenate variables

months = {'MayJun', 'JunJul'};
moorings = {'LoveJoyNorth', 'LoveJoySouth', 'InnerNorth', 'InnerSouth'};

% === Bottom DO ===

% wrap structs in a container to index by name
allMonths.MayJun = MayJun_bottomDO;
allMonths.JunJul = JunJul_bottomDO;

% initialize output struct: one field per mooring
bottomDO_MayJul = struct();
for ii = 1:length(moorings)
    bottomDO_MayJul.(moorings{ii}).time  = [];
    bottomDO_MayJul.(moorings{ii}).DO    = [];
    bottomDO_MayJul.(moorings{ii}).Temp  = [];
end

for i = 1:length(months)
    monthName   = months{i};
    monthStruct = allMonths.(monthName);
    monthData   = monthStruct.TODO_data;   

    for ii = 1:length(moorings)
        mooringName = moorings{ii};
        rskStruct = monthData.(mooringName);

        t   = rskStruct.data.tstamp;
        DO  = rskStruct.data.values(:,3);
        Tmp = rskStruct.data.values(:,1);

        % vertically concatenate onto the running arrays
        bottomDO_MayJul.(mooringName).time = [bottomDO_MayJul.(mooringName).time; t];
        bottomDO_MayJul.(mooringName).DO   = [bottomDO_MayJul.(mooringName).DO;   DO];
        bottomDO_MayJul.(mooringName).Temp = [bottomDO_MayJul.(mooringName).Temp; Tmp];
    end
end


% === Bottom Sal ===

% wrap structs in a container to index by name
allMonths2.MayJun = MayJun_bottomSal;
allMonths2.JunJul = JunJul_bottomSal;

% initialize output struct: one field per mooring
bottomCTD_MayJul = struct();

    bottomCTD_MayJul.LoveJoyNorth.time  = [];
    bottomCTD_MayJul.LoveJoyNorth.Sal    = [];
    bottomCTD_MayJul.LoveJoyNorth.Temp  = [];
    bottomCTD_MayJul.LoveJoyNorth.Pres  = [];
    bottomCTD_MayJul.LoveJoyNorth.Depth  = [];  


for i = 1:length(months)
    monthName   = months{i};
    monthStruct = allMonths2.(monthName);
    monthData   = monthStruct.concerto_data;   


        rskStruct = monthData.LoveJoyNorth;

        t   = rskStruct.data.tstamp;
        Sal  = rskStruct.data.values(:,9);
        Tmp = rskStruct.data.values(:,2);
        Pres = rskStruct.data.values(:,3);
        Depth = rskStruct.data.values(:,8);

        % vertically concatenate onto the running arrays
        bottomCTD_MayJul.LoveJoyNorth.time = [bottomCTD_MayJul.LoveJoyNorth.time; t];
        bottomCTD_MayJul.LoveJoyNorth.Sal   = [bottomCTD_MayJul.LoveJoyNorth.Sal;   Sal];
        bottomCTD_MayJul.LoveJoyNorth.Temp = [bottomCTD_MayJul.LoveJoyNorth.Temp; Tmp];
        bottomCTD_MayJul.LoveJoyNorth.Pres = [bottomCTD_MayJul.LoveJoyNorth.Pres; Pres];
        bottomCTD_MayJul.LoveJoyNorth.Depth = [bottomCTD_MayJul.LoveJoyNorth.Depth; Depth];
    
end

% === Tide ===

% wrap structs in a container to index by name
allMonths3.MayJun = MayJun_tide;
allMonths3.JunJul = JunJul_tide;

% initialize output struct: one field per mooring
tide_MayJul = struct();

    tide_MayJul.time  = [];
    tide_MayJul.Pres    = [];
    tide_MayJul.Temp  = [];
    tide_MayJul.SeaPres  = [];
    tide_MayJul.Depth  = [];

for i = 1:length(months)
    monthName   = months{i};
    monthStruct = allMonths3.(monthName);
    monthData   = monthStruct.d_clean;   


        t   = monthData.tstamp;
        SeaPres  = monthData.values(:,3);
        Tmp = monthData.values(:,1);
        Pres = monthData.values(:,2);
        Depth = monthData.values(:,4);

        % vertically concatenate onto the running arrays
        tide_MayJul.time = [tide_MayJul.time; t];
        tide_MayJul.SeaPres   = [tide_MayJul.SeaPres;   SeaPres];
        tide_MayJul.Temp = [tide_MayJul.Temp; Tmp];
        tide_MayJul.Pres = [tide_MayJul.Pres; Pres];
        tide_MayJul.Depth = [tide_MayJul.Depth; Depth];
    
end



% === Signature ===

% SWIFT 28

allMonths4.MayJun = MayJun_LJNsig;
allMonths4.JunJul = JunJul_LJNsig;

% Initialize output arrays
LJNsig.time = [];
LJNsig.u    = [];
LJNsig.v    = [];
LJNsig.z    = [];   % filled once, since z is constant across time

for i = 1:length(months)
    monthName   = months{i};
    SIG = allMonths4.(monthName).SIG;   % 1x1022 struct array

    % --- time: one scalar per struct element -> 1022x1 vector ---
    t = [SIG.time]';   % [SIG.time] gives 1x1022 row, transpose to column

    % --- u and v: one 40x1 profile per element -> build 1022x40 matrix ---
    u_cells = arrayfun(@(s) s.profile.u(:)', SIG, 'UniformOutput', false); % each 1x40
    v_cells = arrayfun(@(s) s.profile.v(:)', SIG, 'UniformOutput', false);
    u_mat = vertcat(u_cells{:});  % 1022 x 40
    v_mat = vertcat(v_cells{:});  % 1022 x 40

    % Concatenate onto the running arrays (growing the time/row dimension)
    LJNsig.time = [LJNsig.time; t];
    LJNsig.u    = [LJNsig.u;    u_mat];
    LJNsig.v    = [LJNsig.v;    v_mat];

    % z is the same every time step and every month, so just grab it once
    if isempty(LJNsig.z)
        LJNsig.z = SIG(1).profile.z(:);   % 40x1
    end
end


% SWIFT 27

allMonths5.MayJun = MayJun_LJSsig;
allMonths5.JunJul = JunJul_LJSsig;

% Initialize output arrays
LJSsig.time = [];
LJSsig.u    = [];
LJSsig.v    = [];
LJSsig.z    = [];   % filled once, since z is constant across time

for i = 1:length(months)
    monthName   = months{i};
    SIG = allMonths5.(monthName).SIG;   % 1x1022 struct array

    % --- time: one scalar per struct element -> 1022x1 vector ---
    t = [SIG.time]';   % [SIG.time] gives 1x1022 row, transpose to column

    % --- u and v: one 40x1 profile per element -> build 1022x40 matrix ---
    u_cells = arrayfun(@(s) s.profile.u(:)', SIG, 'UniformOutput', false); % each 1x40
    v_cells = arrayfun(@(s) s.profile.v(:)', SIG, 'UniformOutput', false);
    u_mat = vertcat(u_cells{:});  % 1022 x 40
    v_mat = vertcat(v_cells{:});  % 1022 x 40

    % Concatenate onto the running arrays (growing the time/row dimension)
    LJSsig.time = [LJSsig.time; t];
    LJSsig.u    = [LJSsig.u;    u_mat];
    LJSsig.v    = [LJSsig.v;    v_mat];

    % z is the same every time step and every month, so just grab it once
    if isempty(LJSsig.z)
        LJSsig.z = SIG(1).profile.z(:);   % 40x1
    end
end



% === SWIFT data ===

allMonths6.MayJun = MayJun_SWIFT28;
allMonths6.JunJul = JunJul_SWIFT28;

% Initialize output arrays
LJNSWIFT.time = [];
LJNSWIFT.DO    = [];
LJNSWIFT.Sal    = [];
LJNSWIFT.Temp    = [];   

for i = 1:length(months)
    monthName   = months{i};
    SWIFT = allMonths6.(monthName).SWIFT;   % 1x262 struct array for MAyJun

    % --- one scalar per struct element -> 262x1 vector for MayJun ---
    t = [SWIFT.time]';   % transpose to column
    DO = [SWIFT.O2conc]';   
    sal = [SWIFT.salinity]';
    tmp = [SWIFT.watertemp]';

    % Concatenate onto the running arrays (growing the time/row dimension)
    LJNSWIFT.time = [LJNSWIFT.time; t];
    LJNSWIFT.DO    = [LJNSWIFT.DO;    DO];
    LJNSWIFT.Sal    = [LJNSWIFT.Sal;    sal];
    LJNSWIFT.Temp    = [LJNSWIFT.Temp;    tmp];

end

%% give everything a datetime

LJNSWIFT.Datetime = datetime(LJNSWIFT.time, 'ConvertFrom', 'datenum');

bottomCTD_MayJul.LoveJoyNorth.Datetime = datetime(bottomCTD_MayJul.LoveJoyNorth.time, 'ConvertFrom', 'datenum');


bottomDO_MayJul.LoveJoyNorth.Datetime = datetime(bottomDO_MayJul.LoveJoyNorth.time, 'ConvertFrom', 'datenum');
bottomDO_MayJul.LoveJoySouth.Datetime = datetime(bottomDO_MayJul.LoveJoySouth.time, 'ConvertFrom', 'datenum');


tide_MayJul.Datetime = datetime(tide_MayJul.time, 'ConvertFrom', 'datenum');

LJNsig.Datetime = datetime(LJNsig.time, 'ConvertFrom', 'datenum');

LJSsig.Datetime = datetime(LJSsig.time, 'ConvertFrom', 'datenum');
%% get the data ready to plot


% 1. convert the DO from the SWIFTs to mg/L and add it to the structure ==


LJNSWIFT.DO_mgL = LJNSWIFT.DO * 0.032;


% 2. make eta the true tidal height

tide_MayJul.eta = [tide_MayJul.Pres] - mean([tide_MayJul.Pres], 'omitnan');



% 3. stratification from delta S at LJN 

    
% pull out only the timestamps from the concerto data that match hte
% timestamps from the SWIFT data

    % Helper: round a datetime array to the nearest minute
    roundToNearestMinute = @(t) dateshift(t, 'start', 'minute') + minutes(second(t) >= 30);
    
    bottomTime_rounded = roundToNearestMinute(bottomCTD_MayJul.LoveJoyNorth.Datetime);
    swiftTime_rounded  = roundToNearestMinute(LJNSWIFT.Datetime);
    
    % Find matches using the rounded values
    [isMatch, idxInSWIFT] = ismember(bottomTime_rounded, swiftTime_rounded);
    
    % Pull matching data
    bottomSal_matched = bottomCTD_MayJul.LoveJoyNorth.Sal(isMatch);
    topSal_matched    = LJNSWIFT.Sal(idxInSWIFT(isMatch));
    matchedTime        = bottomCTD_MayJul.LoveJoyNorth.Datetime(isMatch);
    
    % Compute delta salinity
    deltaSal = bottomSal_matched - topSal_matched;

%% make the timeseries plot


figure(1); clf;
t = tiledlayout(5,1, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- Tile 1: tidal timeseries ---
s1 = nexttile;
    p1 = plot(tide_MayJul.Datetime, tide_MayJul.eta, 'k.', 'MarkerSize', 5);
    ylabel('SSH (m)')

% --- Tile 2: delta S timeseries at LJN ---
s2 = nexttile;
    p2 = plot(matchedTime, deltaSal, 'm*', 'MarkerSize', 4);
    ylim([0 15])
    ylabel('\delta S (PSU)')

% --- Tile 3: bottom DO timeseries ---
s3 = nexttile;
    p4 = plot(bottomDO_MayJul.LoveJoyNorth.Datetime, bottomDO_MayJul.LoveJoyNorth.DO, 'c-', 'LineWidth', 2);
    hold on
    p5 = plot(bottomDO_MayJul.LoveJoySouth.Datetime, bottomDO_MayJul.LoveJoySouth.DO, 'b-', 'LineWidth', 2);
    ylabel('Dissolved oxygen concentration (mg/L)');
    yline(2, 'k--', 'LineWidth', 1.5)
    hold off
    legend([p4 p5], 'LoveJoy north', 'LoveJoy south', 'Location', 'Southwest');

% --- Tile 4: pcolor of velocity at LJN ---

% getting rid of the smearing in time from previous plot

                % dt = diff(LJNsig.Datetime);    % time should be a datetime or duration vector
                % nominal_dt = median(dt);      % typical sampling interval
                % gap_thresh = 10 * nominal_dt;   
                % 
                % gap_idx = find(dt > gap_thresh); % indices where a gap starts
                % 
                % % Build segment index ranges
                % starts = [1; gap_idx + 1];
                % ends   = [gap_idx; length(LJNsig.Datetime)];
                % segments = arrayfun(@(s,e) s:e, starts, ends, 'UniformOutput', false);

segments = {30:179, 193:1201};

s4 = nexttile; % plotting the pcolor segments separately but on the same subplot to get rid of the smearing
hold on
clim_vals = [-0.5 0.5];  

for s = 1:numel(segments)
    idx = segments{s};
    pcolor(LJNsig.Datetime(idx), LJNsig.z, LJNsig.u(idx, :)');
end

shading flat
colormap(cmocean('balance'))  
caxis(clim_vals)
c = colorbar;
c.Label.String = 'East/west velocity (m/s)';
xlim([LJNsig.Datetime(1) LJNsig.Datetime(end)])   % lock x-axis to full record so gaps show as blank/grey
ylim([0 25])
set(gca,'YDir','reverse')   
xlabel('Time')
ylabel('Depth (m)')
subtitle('LoveJoy north')
set(gca, 'Color', [0.8 0.8 0.8]);

% previous plotting code
    % p6 = pcolor(LJNsig.Datetime, LJNsig.z, LJNsig.u');
    % shading flat
    % set(gca, 'YDir', 'reverse')
    % colormap(cmocean('balance'))
    % c = colorbar;
    % c.Label.String = 'East/west velocity (m/s)';
    % clim([-1 1])
    % ylabel('Depth (m)')
    % xlabel('Time')
    % set(gca, 'Color', [0.7 0.7 0.7]);

s4plus1 = nexttile;

p6 = pcolor(LJSsig.Datetime, LJSsig.z, LJSsig.u');
shading flat
set(gca, 'YDir', 'reverse')
colormap(cmocean('balance'))
c = colorbar;
c.Label.String = 'East/west velocity (m/s)';
clim([-0.5 0.5])
ylabel('Depth (m)')
xlabel('Time')
subtitle('LoveJoy south ')
set(gca, 'Color', [0.7 0.7 0.7]);








linkaxes([s1 s2 s3 s4 s4plus1], 'x')

xticks_common = datetime(2026,5,27):days(7):datetime(2026,7,22);
set([s1 s2 s3 s4 s4plus1], 'XTick', xticks_common)

% fig = gca;
% 
% set(findall(fig, '-property', 'FontSize'), 'FontSize', 18)
% set(findall(fig, '-property', 'LineWidth'), 'LineWidth', 1.5)
% 
% exportgraphics(fig, fullfile(outdir, 'poster_figure.png'), 'Resolution', 600)






%% add datetimes to junjul files 

% SWIFT 
t_all = [JunJul_SWIFT28.SWIFT.time]';
dt_all = datetime(t_all, 'ConvertFrom', 'datenum');

for k = 1:length(JunJul_SWIFT28.SWIFT)
    JunJul_SWIFT28.SWIFT(k).Datetime = dt_all(k);
end

% bottom sal
JunJul_bottomSal.concerto_data.LoveJoyNorth.data.Datetime = datetime(JunJul_bottomSal.concerto_data.LoveJoyNorth.data.tstamp, 'ConvertFrom', 'datenum');

% bottom DO
JunJul_bottomDO.TODO_data.LoveJoyNorth.data.Datetime = datetime(JunJul_bottomDO.TODO_data.LoveJoyNorth.data.tstamp, 'ConvertFrom', 'datenum');
JunJul_bottomDO.TODO_data.LoveJoySouth.data.Datetime = datetime(JunJul_bottomDO.TODO_data.LoveJoySouth.data.tstamp, 'ConvertFrom', 'datenum');

% tide
JunJul_tide.d_clean.Datetime = datetime(JunJul_tide.d_clean.tstamp, 'ConvertFrom', 'datenum');

% sig

    % swift 28
t_all_sig = [JunJul_LJNsig.SIG.time]';
dt_all_sig = datetime(t_all_sig, 'ConvertFrom', 'datenum');

for j = 1:length(JunJul_LJNsig.SIG)
    JunJul_LJNsig.SIG(j).Datetime = dt_all_sig(j);
end

    % swift 27
t_all_sigS = [JunJul_LJSsig.SIG.time]';
dt_all_sigS = datetime(t_all_sigS, 'ConvertFrom', 'datenum');

for j = 1:length(JunJul_LJSsig.SIG)
    JunJul_LJSsig.SIG(j).Datetime = dt_all_sigS(j);
end


%% get the data ready to plot


% 1. convert the DO from the SWIFTs to mg/L and add it to the structure ==

for k = 1:length(JunJul_SWIFT28.SWIFT)
    JunJul_SWIFT28.SWIFT(k).DO_mgL = [JunJul_SWIFT28.SWIFT.O2conc]' .* 0.032;
end



% 2. make eta the true tidal height

JunJul_tide.d_clean.eta = [JunJul_tide.d_clean.values(:,2)] - mean([JunJul_tide.d_clean.values(:,2)], 'omitnan');



% 3. stratification from delta S at LJN 

    
% pull out only the timestamps from the concerto data that match hte
% timestamps from the SWIFT data

  
    bottomTime_rounded_junjul = roundToNearestMinute(JunJul_bottomSal.concerto_data.LoveJoyNorth.data.Datetime);
    swiftTime_rounded_junjul  = roundToNearestMinute([JunJul_SWIFT28.SWIFT.Datetime]);
    
    % Find matches using the rounded values
    [isMatch, idxInSWIFT] = ismember(bottomTime_rounded_junjul, swiftTime_rounded_junjul);
    
    % pull swift data into oine vector
    swiftSal_all = [JunJul_SWIFT28.SWIFT.salinity]';

    % Pull matching data
    bottomSal_matchedjunjul = JunJul_bottomSal.concerto_data.LoveJoyNorth.data.values(isMatch);
    topSal_matchedjunjul    = swiftSal_all(idxInSWIFT(isMatch));
    matchedTimejunjul        = JunJul_bottomSal.concerto_data.LoveJoyNorth.data.Datetime(isMatch);


    % Compute delta salinity
    deltaSal_junjul = bottomSal_matchedjunjul - topSal_matchedjunjul;




%% figure 2, just june to july

figure(2); clf;
t = tiledlayout(5,1, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- Tile 1: tidal timeseries ---
s5 = nexttile;
    p7 = plot(JunJul_tide.d_clean.Datetime, JunJul_tide.d_clean.eta, 'k.', 'MarkerSize', 5);
    ylabel('SSH (m)')

% --- Tile 2: delta S timeseries at LJN ---
s6 = nexttile;
    p8 = plot(matchedTimejunjul, deltaSal_junjul, 'm*', 'MarkerSize', 4);
    ylim([0 15])
    ylabel('\delta S (PSU)')

% --- Tile 3: bottom DO timeseries ---
s7 = nexttile;
    p9 = plot(JunJul_bottomDO.TODO_data.LoveJoyNorth.data.Datetime, ...
               JunJul_bottomDO.TODO_data.LoveJoyNorth.data.values(:,3), 'c-', 'LineWidth', 2);
    hold on
    p10 = plot(JunJul_bottomDO.TODO_data.LoveJoySouth.data.Datetime, ...
               JunJul_bottomDO.TODO_data.LoveJoySouth.data.values(:,3), 'b-', 'LineWidth', 2);
    ylabel('Dissolved oxygen concentration (mg/L)');
    yline(2, 'k--', 'LineWidth', 1.5)
    hold off
    legend([p9 p10], 'LoveJoy north', 'LoveJoy south', 'Location', 'Southwest')



% === organizing things for signature plotting ===
        SIG = JunJul_LJNsig.SIG;
        plotTime = [SIG.Datetime]';
        plotZ = SIG(1).profile.z(:);
        u_cells = arrayfun(@(s) s.profile.u(:)', SIG, 'UniformOutput', false);
        u_mat = vertcat(u_cells{:});



% --- Tile 4: pcolor of velocity at LJN ---
s8 = nexttile;
    p11 = pcolor(plotTime, plotZ, u_mat');
    shading flat
    set(gca, 'YDir', 'reverse')
    colormap(cmocean('balance'))
    c = colorbar;
    c.Label.String = 'East/west velocity (m/s)';
    clim([-0.5 0.5])
    ylabel('Depth (m)')
    xlabel('Time')
    subtitle('LoveJoy north')
    set(gca, 'Color', [0.7 0.7 0.7]);


% === organizing things for signature plotting ===
        SIG2 = JunJul_LJSsig.SIG;
        plotTime2 = [SIG2.Datetime]';
        plotZ2 = SIG2(1).profile.z(:);
        u_cells2 = arrayfun(@(s) s.profile.u(:)', SIG2, 'UniformOutput', false);
        u_mat2 = vertcat(u_cells2{:});

% --- Tile 5: pcolor of velocity at LJS ---
s8plus1 = nexttile;
    pcolor(plotTime2, plotZ2, u_mat2');
    shading flat
    set(gca, 'YDir', 'reverse')
    colormap(cmocean('balance'))
    c = colorbar;
    c.Label.String = 'East/west velocity (m/s)';
    clim([-0.5 0.5])
    ylabel('Depth (m)')
    xlabel('Time')
    subtitle('LoveJoy south')
    set(gca, 'Color', [0.7 0.7 0.7]);




linkaxes([s5 s6 s7 s8 s8plus1], 'x')

xticks_common = datetime(2026,6,2):days(7):datetime(2026,7,22);
set([s5 s6 s7 s8 s8plus1], 'XTick', xticks_common)


%% zooming in on choice times 

% Zoom in from June 27 16:51 to June 29 at 00:27

figure(3); clf;
t = tiledlayout(5,1, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- Tile 1: tidal timeseries ---
s5 = nexttile;
    p7 = plot(JunJul_tide.d_clean.Datetime, JunJul_tide.d_clean.eta, 'k.', 'MarkerSize', 5);
    % Zoom in on the specified time range
    xlim([datetime('2026-06-27 16:50'), datetime('2026-06-29 17:45')]); % 00:27
    ylabel('SSH (m)')

% --- Tile 2: delta S timeseries at LJN ---
s6 = nexttile;
    p8 = plot(matchedTimejunjul, deltaSal_junjul, 'm*', 'MarkerSize', 4);
    ylim([0 15])
    xlim([datetime('2026-06-27 16:50'), datetime('2026-06-29 17:45')]);
    ylabel('\delta S (PSU)')

% --- Tile 3: bottom DO timeseries ---
s7 = nexttile;
    p9 = plot(JunJul_bottomDO.TODO_data.LoveJoyNorth.data.Datetime, ...
               JunJul_bottomDO.TODO_data.LoveJoyNorth.data.values(:,3), 'c-', 'LineWidth', 2);
    % Zoom in on the specified time range
    xlim([datetime('2026-06-27 16:50'), datetime('2026-06-29 17:45')]);
    hold on
    p10 = plot(JunJul_bottomDO.TODO_data.LoveJoySouth.data.Datetime, ...
               JunJul_bottomDO.TODO_data.LoveJoySouth.data.values(:,3), 'b-', 'LineWidth', 2);
    % Zoom in on the specified time range
    xlim([datetime('2026-06-27 16:50'), datetime('2026-06-29 17:45')]);
    ylabel('Dissolved oxygen concentration (mg/L)');
    yline(2, 'k--', 'LineWidth', 1.5)
    hold off
    legend([p9 p10], 'LoveJoy north', 'LoveJoy south', 'Location', 'Northwest')



% === organizing things for signature plotting ===
        SIG = JunJul_LJNsig.SIG;
        plotTime = [SIG.Datetime]';
        plotZ = SIG(1).profile.z(:);
        u_cells = arrayfun(@(s) s.profile.u(:)', SIG, 'UniformOutput', false);
        u_mat = vertcat(u_cells{:});

% --- Tile 4: pcolor of velocity at LJN ---
s8 = nexttile;
    p11 = pcolor(plotTime, plotZ, u_mat');
    shading flat
    set(gca, 'YDir', 'reverse')
    colormap(cmocean('balance'))
    c = colorbar;
    c.Label.String = 'East/west velocity (m/s)';
    clim([-0.5 0.5])
    % Zoom in on the specified time range
    xlim([datetime('2026-06-27 16:50'), datetime('2026-06-29 17:45')]);
    ylabel('Depth (m)')
    xlabel('Time')
    subtitle('LoveJoy north')
    set(gca, 'Color', [0.7 0.7 0.7]);




% --- Tile 5: pcolor of velocity at LJN ---
s8plus1 = nexttile;
    p11 = pcolor(plotTime2, plotZ2, u_mat2');
    shading flat
    set(gca, 'YDir', 'reverse')
    colormap(cmocean('balance'))
    c = colorbar;
    c.Label.String = 'East/west velocity (m/s)';
    clim([-0.5 0.5])
    % Zoom in on the specified time range
    xlim([datetime('2026-06-27 16:50'), datetime('2026-06-29 17:45')]);
    ylabel('Depth (m)')
    xlabel('Time')
    subtitle('LoveJoy south')
    set(gca, 'Color', [0.7 0.7 0.7]);

linkaxes([s5 s6 s7 s8 s8plus1], 'x')


xticks_common = datetime(2026,6,27):hours(6):datetime(2026,6,29);
set([s5 s6 s7 s8 s8plus1], 'XTick', xticks_common)









%%
% figure(2); clf;
% 
% s5 = subplot(4,1,1); % tidal timeseries
% 
%     p7 = plot(JunJul_tide.d_clean.Datetime, JunJul_tide.d_clean.eta, 'k-', 'LineWidth', 2);
%     ylabel('SSH (m)')
% 
% s6 = subplot(4,1,2); % delta s timeseries at LJn
% 
%     p8 = plot(matchedTimejunjul, deltaSal_junjul, 'm.-', 'LineWidth', 2);
%     ylabel('\delta S (PSU)')
%     hold on
%     p9 = yline(0, 'k--', 'LineWidth', 1.5);
%     hold off
% 
% s7 = subplot(4,1,3); % bottom DO timeseries
% 
%     p10 = plot(JunJul_bottomDO.TODO_data.LoveJoyNorth.data.Datetime, JunJul_bottomDO.TODO_data.LoveJoyNorth.data.values(:,3), 'c-', 'Linewidth', 2);
%     hold on
% 
%     p11 = plot(JunJul_bottomDO.TODO_data.LoveJoySouth.data.Datetime, JunJul_bottomDO.TODO_data.LoveJoySouth.data.values(:,3), 'b-', 'Linewidth', 2);
%     ylabel('Dissolved oxygen concentration (mg/L)');
% 
%     yline(2, 'k--', 'LineWidth', 1.5)
% 
%     hold off
%     legend([p4 p5], 'LoveJoy north', 'LoveJoy south')
% 
% 
% 
% % === getting some things orgaznised for signature plotting=== 
% 
%         SIG = JunJul_LJNsig.SIG;   % 1x1022 struct array
% 
%         % Collect Datetime into one vector (fixes CSL issue for time)
%         plotTime = [SIG.Datetime]';
% 
%         % Collect z (constant across time, just grab once)
%         plotZ = SIG(1).profile.z(:);
% 
%         % Build u as a proper (time x depth) matrix
%         u_cells = arrayfun(@(s) s.profile.u(:)', SIG, 'UniformOutput', false);  % each 1x40
%         u_mat = vertcat(u_cells{:});   % 1022 x 40
% 
% s8 = subplot(4,1,4);   % pcolor of velocity at LJN
%     p12 = pcolor(plotTime, plotZ, u_mat');   % transpose so it's depth x time
%     shading flat
%     set(gca, 'YDir', 'reverse')
%     colormap(cmocean('balance'))
%     c = colorbar;
%     c.Label.String = 'East/west velocity (m/s)';
%     ylabel('Depth (m)')
%     xlabel('Time')
% 
% 
% 
% linkaxes([s5 s6 s7 s8], 'x')