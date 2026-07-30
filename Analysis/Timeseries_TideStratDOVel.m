%%%%% Timeseries plot of tide, stratification, DO, and velocity

%%% Originally created for a figure for PECS 2026
% Maia H. July 28, 2026


clear all, close all

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





% === SWIFT data ===

allMonths5.MayJun = MayJun_SWIFT28;
allMonths5.JunJul = JunJul_SWIFT28;

% Initialize output arrays
LJNSWIFT.time = [];
LJNSWIFT.DO    = [];
LJNSWIFT.Sal    = [];
LJNSWIFT.Temp    = [];   

for i = 1:length(months)
    monthName   = months{i};
    SWIFT = allMonths5.(monthName).SWIFT;   % 1x262 struct array for MAyJun

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
t = tiledlayout(4,1, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- Tile 1: tidal timeseries ---
s1 = nexttile;
    p1 = plot(tide_MayJul.Datetime, tide_MayJul.eta, 'k-', 'LineWidth', 2);
    ylabel('SSH (m)')

% --- Tile 2: delta S timeseries at LJN ---
s2 = nexttile;
    p2 = plot(matchedTime, deltaSal, 'm*-', 'LineWidth', 2);
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
s4 = nexttile;
    p6 = pcolor(LJNsig.Datetime, LJNsig.z, LJNsig.u');
    shading flat
    set(gca, 'YDir', 'reverse')
    colormap(cmocean('balance'))
    c = colorbar;
    c.Label.String = 'East/west velocity (m/s)';
    clim([-1 1])
    ylabel('Depth (m)')
    xlabel('Time')

linkaxes([s1 s2 s3 s4], 'x')







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

t_all_sig = [JunJul_LJNsig.SIG.time]';
dt_all_sig = datetime(t_all_sig, 'ConvertFrom', 'datenum');

for j = 1:length(JunJul_LJNsig.SIG)
    JunJul_LJNsig.SIG(j).Datetime = dt_all_sig(j);
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
t = tiledlayout(4,1, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- Tile 1: tidal timeseries ---
s5 = nexttile;
    p7 = plot(JunJul_tide.d_clean.Datetime, JunJul_tide.d_clean.eta, 'k-', 'LineWidth', 2);
    ylabel('SSH (m)')

% --- Tile 2: delta S timeseries at LJN ---
s6 = nexttile;
    p8 = plot(matchedTimejunjul, deltaSal_junjul, 'm*-', 'LineWidth', 2);
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
    clim([-1 1])
    ylabel('Depth (m)')
    xlabel('Time')

linkaxes([s5 s6 s7 s8], 'x')



%% zooming in on choice times 

% Zoom in from June 27 16:51 to June 29 at 00:27

figure(3); clf;
t = tiledlayout(4,1, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- Tile 1: tidal timeseries ---
s5 = nexttile;
    p7 = plot(JunJul_tide.d_clean.Datetime, JunJul_tide.d_clean.eta, 'k-', 'LineWidth', 2);
    % Zoom in on the specified time range
    xlim([datetime('2026-06-27 16:50'), datetime('2026-06-29 17:45')]); % 00:27
    ylabel('SSH (m)')

% --- Tile 2: delta S timeseries at LJN ---
s6 = nexttile;
    p8 = plot(matchedTimejunjul, deltaSal_junjul, 'm*-', 'LineWidth', 2);
    % Zoom in on the specified time range
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
    clim([-1 1])
    % Zoom in on the specified time range
    xlim([datetime('2026-06-27 16:50'), datetime('2026-06-29 17:45')]);
    ylabel('Depth (m)')
    xlabel('Time')

linkaxes([s5 s6 s7 s8], 'x')









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