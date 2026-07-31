%%% TS plot from cleaned RBR data %%%

% Maia, March 2026

clear all

%% load data -- fixed to clean data

load Echo_CTD_24Jun2026_FloodTowYo_DataAndChannelsOnly_processed_L1.mat

%% pull out salinity and temperature

% salinity is channel 8, temp channel 2, DO mg/L is channel 14

nCasts  = length(data);
nLevels = size(data(1).values, 1);

% pre-allocate variables
sal = NaN(nLevels, nCasts);
temp  = NaN(nLevels, nCasts);
DO_mgl = NaN(nLevels, nCasts); 
depth = NaN(nLevels, nCasts); 
seaPressure = NaN(nLevels, nCasts);

for i = 1:nCasts
    V = data(i).values;   % 132 x 11
    T = data(i).tstamp; %132x1
    
    sal(:,i) = V(:,8); % units of PSU
    temp(:,i)  = V(:,2); % units of °C
    DO_mgl (:,i) = V(:,14); % units of µmol/L
    depth(:,i) = V(:, 7); % units of meters
    seaPressure(:,i) = V(:,6); % units of dbar
    time(:,i) = T;
end


% ------------------
% put oxygen in mg/L and time as a datetime
% ------------------
% DO_mgl = DO .*0.03199;
% datetime_casts = datetime(time, 'ConvertFrom', 'datenum');


%% TS plot overall

figure(1)
scatter(temp, sal, 'filled', 'blue')
xlabel("Temperature (°C)")
ylabel("Salinity (PSU)")



%% For december data

load CTDprofilesEachLap.mat %  profiles at and around the mooring locations
    
%% TS plots of just the individual profiles


mooringNames = {'WWS', 'WWN', 'LoveJoyN', 'LoveJoyS', 'InnerN', 'InnerS'};
lapNames = {'lap1', 'lap2', 'lap3'};

% for the thermal color scheme
cmap_4=cmocean('thermal');

% Loop through each mooring and lap to extract and plot data
for j = 1:length(lapNames)
    lap = lapNames{j};
    for k = 1:length(mooringNames)
        moor = mooringNames{k};
        % Extract data for the current mooring and lap
        temp_lap = eval(['temp_' lap '_' moor]); %(:, (j-1)*length(mooringNames) + k)
        sal_lap = eval(['sal_' lap '_' moor]);
        do_lap = eval(['do_' lap '_' moor]);
        seapress_lap = eval(['seaPress_' lap '_' moor]);
        castTime = eval(['castTime_single_' lap '_' moor]);
        castLat = eval(['castLat_' lap '_' moor]);
        castLon = eval(['castLon_' lap '_' moor]);

            % % Build T-S grid
            % T_grid = linspace(min(temp_lap)-1, max(temp_lap)+1, 200);
            % S_grid = linspace(min(sal_lap)-0.5, max(sal_lap)+0.5, 200);
            % [S_mesh, T_mesh] = meshgrid(S_grid, T_grid);
        % convert to abosolute salinity and conservative temperature
        % for the isopycnals
        SA = gsw_SA_from_SP(sal_lap, seapress_lap, castLon, castLat);
        CT = gsw_CT_from_t(SA, temp_lap, seapress_lap);

        SA_grid = linspace(min(SA)-0.5, max(SA)+0.5, 200);
        CT_grid = linspace(min(CT)-0.5, max(CT)+0.5, 200);

        [SA_mesh, CT_mesh] = meshgrid(SA_grid, CT_grid);
        sigma_mesh = gsw_sigma0(SA_mesh, CT_mesh);
        sigma_levels = floor(min(sigma_mesh(:))):1.0:ceil(max(sigma_mesh(:))); % creates the evenly spaced isopycnals. sigma_mesh(:) flattens out the mesh into a vector. floor() rounds down values to nearest integer, ciel() rounds up to nearest integer. Step size can be changed upon visual inspection.

        figure(j*10 + k)
        [C, h] = contour(SA_mesh, CT_mesh, sigma_mesh, sigma_levels, 'k-');
        clabel(C, h, 'FontSize', 7);
        hold on

        scatter(sal_lap, temp_lap, 20, do_lap, 'filled');
        colormap(gca, cmap_4);
        c = colorbar;
        c.Label.String = 'DO concentration (mgL^{-1})';
        xlabel('Salinity (PSU)');
        ylabel('Temperature (°C)');
        title(sprintf('%s - %s - %s', moor, lap, datestr(castTime)));
        saveas(gcf, sprintf('%s_%s_TSplot.png', moor, lap));
        hold off
    end
end

%% for the hypoxic color scheme

% for the thermal color scheme
cmap_5=cmocean('oxy');

% Loop through each mooring and lap to extract and plot data
for j = 1:length(lapNames)
    lap = lapNames{j};
    for k = 1:length(mooringNames)
        moor = mooringNames{k};
        % Extract data for the current mooring and lap
        temp_lap = eval(['temp_' lap '_' moor]); %(:, (j-1)*length(mooringNames) + k)
        sal_lap = eval(['sal_' lap '_' moor]);
        do_lap = eval(['do_' lap '_' moor]);
        castTime = eval(['castTime_single_' lap '_' moor]);

        % Build T-S grid
        T_grid = linspace(min(temp_lap)-1, max(temp_lap)+1, 200);
        S_grid = linspace(min(sal_lap)-0.5, max(sal_lap)+0.5, 200);
        [S_mesh, T_mesh] = meshgrid(S_grid, T_grid);
        sigma_mesh = gsw_sigma0(S_mesh, T_mesh);
        sigma_levels = floor(min(sigma_mesh(:))):1.0:ceil(max(sigma_mesh(:))); % creates the evenly spaced isopycnals. sigma_mesh(:) flattens out the mesh into a vector. floor() rounds down values to nearest integer, ciel() rounds up to nearest integer. Step size can be changed upon visual inspection.

        figure(j*10 + k)
        [C, h] = contour(S_mesh, T_mesh, sigma_mesh, sigma_levels, 'k-');
        clabel(C, h, 'FontSize', 7);
        hold on

        scatter(sal_lap, temp_lap, 20, do_lap, 'filled');
        colormap(gca, cmap_5);
        c = colorbar;
        c.Label.String = 'DO concentration (mgL^{-1})';
        xlabel('Salinity (PSU)');
        ylabel('Temperature (°C)');
        title(sprintf('%s - %s - %s', moor, lap, datestr(castTime)));
        saveas(gcf, sprintf('%s_%s_TSplot_hypoxiaColors.png', moor, lap));
        hold off
    end
end

