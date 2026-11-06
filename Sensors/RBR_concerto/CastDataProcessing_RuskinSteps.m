%%%% Post-processing from Ruskin steps %%%%

%%% RBR plotting profiles ONLY DOWNCASTS %%%

clear all, close all

%% read with RSKtools

rsk = RSKopen( [ 'WWS_concerto_SepOct2026_sn211170.rsk' ]);
% print a list of all the channels in the rsk file
RSKprintchannels(rsk)
% read all the profiles 
rsk = RSKreadprofiles(rsk, 'direction', 'both'); 


% how many Nans are there?
reportNaN(rsk, 'after read profiles')
%% Renaming the temperature channel
% --------------------
% Choosing which temperature variable to use
% --------------------------
% Find index of Temperature1
idx = find(strcmp({rsk.channels.longName}, 'Temperature1'));

% Rename it to Temperature
rsk.channels(idx).longName = 'Temperature';


%% Plot all profiles

RSKplotprofiles(rsk, ...
 'channel',{'Temperature','Conductivity','Dissolved O2'}); % 'Dissolved O21 for casting CTD'


% plot a few profiles of temperature, conductivity, and chlorophyll
% RSKplotprofiles(rsk,'profile',[1 10 20],...
%  'channel',{'Temperature1','conductivity','Dissolved O2'});
%% Saving a copy of the raw data to compare with the processed data

raw = rsk;

%% Read only the downcast/upcast from profiles 
rsk = RSKreadprofiles(rsk, 'direction', 'up'); % !!! USE 'up' for the wire walkers !!!

%% Correct for A2D zero-order hold

% --------------------------------
% Ruskin description of reasoning
% --------------------------------

% The analog-to-digital (A2D) converter on RBR instruments must recalibrate periodically. In the time it takes for
% the calibration to finish, one or more samples are missed. The instrument firmware fills the missed sample with the
% same data measured during the previous sample, a technique called a zero-order hold.
% RSKcorrecthold identifies zero-hold points by finding where consecutive differences of each channel are equal
% to zero, and then replaces these samples with a NaN or an interpolated value. 



channel_name_list = {'Conductivity', 'Temperature', 'Pressure', 'Chlorophyll a', 'Temperature2', 'Dissolved O2'}; % for the casting CTD {'Conductivity', 'Temperature', 'Pressure', 'Temperature2', 'Dissolved O21', 'Sea Pressure', 'Depth', 'Salinity', 'Dissolved O22'};

% Optional manual override: channels to always skip for this instrument
skip_channels = {'Chlorophyll a'};   % edit per deployment, or set to {} for other CTDs

% Keep only channels that exist in this file and aren't on the skip list
available = {rsk.channels.longName};
channel_name_list = channel_name_list(ismember(channel_name_list, available) & ...
    ~ismember(channel_name_list, skip_channels));

for i = 1:length(channel_name_list)
    [rsk, holdpts] = RSKcorrecthold(rsk, 'channel', channel_name_list{i}, 'action', 'interp');
    fprintf('Max depth after step X: %.2f\n', max(rsk.data(i).values(:,3))); % change this to column 7 for the casting ctd
end

% how many NaNs are there?

reportNaN(rsk, 'after correct hold')

%% De-spiking the data

% removing data outside of 2 standard deviations away from the median of 11 points for all
% channels. Here is the Ruskin description:

  % 
  % Identifies and treats spikes using a median filtering algorithm.  A
  % reference time series is created by filtering the input channel with
  % a median filter of length 'windowLength'. A residual ("high-pass")
  % series is formed by subtracting the reference series from the
  % original signal.  Data in the reference series lying outside of
  % 'threshold' standard deviations are defined as spikes.  Spikes are
  % then treated by one of three methods (nan (makes it a nan value), interp (linear interpolation from nearby values),
  % or replace(replace the value with the corresponding reference value)).


% === NOTE: for WW concertos the windowLength must be 3. For Pete's
% concerto the window length must be 11 !! =======

for i = 1:length(channel_name_list)
    [rsk, spike] = RSKdespike(rsk,'channel',channel_name_list{i},'threshold',2,'windowLength',3,'action','nan', 'visualize', 10); % the value of 10 at the being proflie 10, which is what will get visualized in the plot
    fprintf('Max depth after step X: %.2f\n', max(rsk.data(i).values(:,3)));
end

% How many NANs are there

reportNaN(rsk, 'after despike')


%% Low-pass filtering

% --------------------------------
% Rusking description of reasoning
% --------------------------------

% Low-pass filtering is commonly used to reduce noise and to match sensor time constants, typically for temperature
% and conductivity. Users may also wish to filter other channels to simply reduce noise (e.g., optical channels such as
% chlorophyll-a or turbidity).
% Most RBR instruments designed for profiling are equipped with thermistors that have a time constant of 100 ms,
% which is "slower" than the conductivity cell. When the time constants are different, salinity will contain spikes at
% strong gradients. 

samplingperiod = readsamplingperiod(rsk); %determine logger sampling, in seconds.
% So sampled at ~15.9 Hz. We'll use 15 Hz for simplicity.
% Given delta(time) = 1/15Hz = 0.0667 s = 66.67 ms, each data point represents ~66.67 ms of time
% Choosing smoothing window: window timesensor time constant ==> N =~ tau/delta(t) where tau is the thermistor time constant.
% So in this case, number of samples per time constant:N_tau= 0.1/0.0630  1.59 samples. Thermistor responds over about 1.6 samples.
% Based on this, with a moving average low-pass filter, window time =~ 25 * tau so 0.2 to 0.5 s.
% N= 0.2 to 0.5 / 0.063 =~ 3-8 samples.
% 3 samples ==> minimal smoothing, 5 samples ==> good balance, 7-8 samples ==> stronger smoothing

% smoothing conductivity and temperature
rsk = RSKsmooth(rsk,'channel',{'temperature','conductivity',},... % 'salinity'
 'windowLength', 5, 'visualize', 10); % the value of 10 at the being proflie 10, which is what will get visualized in the plot

% how many NaNs are there

reportNaN(rsk, 'after smooth')

%% Alignment of conductivity and temperature

% --------------------
% Ruskin explanation
% ---------------------

% Conductivity and temperature often need to be aligned in time to account for the fact these sensors are not
% always co-located on the logger. The implication is that, under dynamic conditions (e.g., profiling), the sensors are
% measuring a slightly different parcel of water at any instant.
% Furthermore, sensors with long time constants introduce a time lag to the data. For example, dissolved oxygen
% sensors often have a long time constant, and this delays the measurement relative to the true value. This can be fixed
% to some degree by advancing the sensor data in time.
% When temperature and conductivity are misaligned, salinity will contain spikes at sharp interfaces and a bias in
% continuously stratified environments. Properly aligning the sensors, together with matching the time response, will
% minimize salinity spiking and bias.
% A common approach to determine the optimal lag is to compute and plot salinity for a range of lags, and choose the
% lag (often by eye) with the smallest salinity spikes at sharp temperature interfaces.
% As an alternative approach, RSKtools includes a function called RSKcalculateCTlag that estimates the optimal lag between 
% conductivity and temperature by minimizing salinity spiking. We currently suggest using both approaches to check for consistency. 
% See the RSKcalculateCTlag help page for more information.
% As a rough gui, temperature from a CTD equipped with the red combined CT cell and a fast thermistor typically
% requires only a very small time advance (perhaps tens of milliseconds). Temperature from a CTD equipped with a
% cylindrical black conductivity cell (with the thermistor on the sensor endcap) typically requires a temperature lag
% correction of about 0.1 s to 0.3 s (1 or 2 samples at 6 Hz).


% required shift of C relative to T for each profile
lag = RSKcalculateCTlag(rsk); % lag = RSKcalculateCTlag(rsk,'seapressurerange',[0, max('Sea Pressure')]);
lag = -lag; % to advance temperature
lag = median(lag); % select best lag for consistency among profiles
rsk = RSKalignchannel(rsk,'channel','Temperature','lag',lag);


%% Remove loops

% --------------------
% Ruskin explanation
% ---------------------

% Working in rough seas can cause the CTD profiling rate to vary, and even change sign (i.e., the CTD momentarily
% changes direction). When this happens, the CTD effectively samples its own wake, degrading the quality of the
% profile in regions of strong gradients. The measurements taken when the instrument is profiling too slowly or during
% a pressure reversal should not be used for further analysis. We recommend using RSKremoveloops to flag and
% treat the data when the instrument 1) falls below a threshold speed and 2) when the pressure reverses (the CTD
% "loops"). Before using RSKremoveloops, use RSKderivedepth to calculate depth from sea pressure, and then
% use RSKderivevelocity to calculate profiling rate.


removeLoops = false;   % false for wire walkers; true for ship-deployed CTDs

% Apply the algorithm:  Outputs: RSK - Structure with data filtered by threshold profiling speed and removal of loops.
%                                flagidx - Index of the samples that are filtered.

if removeLoops
    rsk = RSKderivedepth(rsk);
    rsk = RSKderivevelocity(rsk);
    [rsk, flagidx] = RSKremoveloops(rsk, 'direction', 'up', 'threshold', 0.1, 'visualize', 50);  % 0.25 value for casting concerto: minimum speed at which profile must be taken (units: m/s). This is the default rate from Ruskin. 
end


% how many NaNs are there
reportNaN(rsk, 'after removeloops')
%% Derived variables

rsk = RSKderivesalinity(rsk);
rsk = RSKderiveseapressure(rsk);
rsk = RSKderivesigma(rsk);
% rsk = RSKderivedepth(rsk);

raw = RSKderivesalinity(raw);
raw = RSKderiveseapressure(raw);
raw = RSKderivesigma(raw);
raw = RSKderivedepth(raw);



% print a list of channels in the rsk file
RSKprintchannels(rsk)


%% Bin average all channels by sea pressure

% -----------------------------
% Ruskin explanation
% -------------------------
% 
% Bin averaging reduces sensor noise and ensures that each profile is referenced to a common grid. The latter is often
% an advantage for plotting data as "heatmaps." RSKbinaverage allows users to bin channels according to any
% reference, but the most common choices are time, depth, and sea pressure. It also can handle grids with a variable
% bin size. In the following, the data are averaged into 0.25 dbar bins.
% 

% 
% 
% [rsk, samplesinbin] = RSKbinaverage(rsk, 'binBy', 'Sea Pressure', 'binSize', 1,...
%     'boundary', [],'direction', 'up',... % !!!! WAS 'up' !!!
%     'visualize', 10);  %Outputs: RSK - Structure with binned data, samplesinbin - Amount of samples in each bin.
% h = findobj(gcf,'type','line');
% set(h(1:2:end),'marker','o','markerfacecolor','c')
% 
% % how many NaNs are there
% 
% reportNaN(rsk, 'after biaverage')
%% Compare raw and processed data

figure();
channel = {'Temperature', 'Salinity', 'Dissolved O2'}; % 'Dissolved O21' for the WWs 
profile = [3 10 20];
[h1, ax] = RSKplotprofiles(raw, 'profile', profile, 'channel', channel);
h2 = RSKplotprofiles(rsk, 'profile', profile, 'channel', channel);
set(h2, 'LineWidth', 3, 'Marker', 'o', 'MarkerFaceColor', 'w');
set(ax(1), 'xlim', [7 15])
set(ax(2), 'xlim', [15 35])
set(ax(3), 'xlim', [15 350])
set(ax, 'ylim', [0 24])

%% Add a channel of DO concentration as mg/L in additional umol/L

% does it make sense to do their deivation or just calculate it by
% converting the umol/l value
    % could do both just to see what is different ...


% Calculate dissolved oxygen concentration in mg/L
% rsk = RSKderiveO2(rsk, 'toDerive', 'concentration', 'unit', 'mg/l');


%% Manual conversion to mg/L for O2 since there is no saturation value from this optode

iO2 = strcmp({rsk.channels.longName}, 'Dissolved O2');
for k = 1:numel(rsk.data)
    mgL(k).values = rsk.data(k).values(:,iO2) * 31.998/1000;
end
rsk = RSKaddchannel(rsk, 'data', mgL, 'channel', 'Dissolved O2 mg/L', 'unit', 'mg/L');

%% 2D plot visualization

% figure(); 
% 
% [im_hdl ax_hdl] = RSKimages(rsk, 'channel', {'Temperature', 'Salinity', 'Dissolved O2'}, 'direction', 'up'); % !! WAS 'up' !!!
% clim(ax_hdl(1), [10, 18]);   % Temperature
% clim(ax_hdl(2), [10, 30]);    % Salinity
% clim(ax_hdl(3), [2, 12]);    % Dissolved O2
% 
% saveas(gcf, "pcolor_quicklook_SalTempDO_24Sep2026.png") % pcolor_quicklook_SalTempDO_21Jul2026_and22Jul2026_ebb.png

%% Quicklook without binning (run in place of the binaverage + RSKimages sections)

names = {rsk.channels.longName};
units = {rsk.channels.units};
iP = find(strcmp(names,'Sea Pressure'));

% Stack all profiles once
T = []; P = [];
for k = 1:numel(rsk.data)
    T = [T; rsk.data(k).tstamp(:)];
    P = [P; rsk.data(k).values(:,iP)];
end

% Per-variable settings: name, color limits, Crameri colormap
plotVars = {'Temperature',  'Salinity',  'Dissolved O2 mg/L'};
climits  = {[12 15],        [25 30],     [0 4]};     % O2 in umol/L: [55 400]
cmaps    = {'batlow',       'imola',     'tokyo'};

figure('Position',[100 100 1100 900]);

for v = 1:numel(plotVars)
    iV = find(strcmp(names, plotVars{v}));
    if isempty(iV), warning('Channel %s not found, skipping', plotVars{v}); continue, end

    V = [];
    for k = 1:numel(rsk.data), V = [V; rsk.data(k).values(:,iV)]; end

    ax = subplot(3,1,v);

    scatter(T, P, 4, V, 'filled');
    axis ij; datetick('x','mm/dd','keeplimits');
    clim(ax, climits{v});
    colormap(ax, crameri(cmaps{v}));          % use crameri('-lipari') to reverse

    cb = colorbar(ax);
    cb.Label.String = sprintf('%s (%s)', plotVars{v}, units{iV});   % e.g. "Temperature (°C)"

    ylabel('Sea Pressure (dbar)');
    %subtitle(plotVars{v});
end

sgtitle('WWN September to October upcasts', 'FontWeight', 'bold');  
%% Plotting only dissolved oxygen (for check that WWS worked correctly)

names = {rsk.channels.longName};
units = {rsk.channels.units};
iP = find(strcmp(names,'Sea Pressure'));
iV = find(strcmp(names,'Dissolved O2 mg/L'));
if isempty(iV), error('Channel Dissolved O2 mg/L not found'); end

% Stack all profiles once
T = []; P = []; V = [];
for k = 1:numel(rsk.data)
    T = [T; rsk.data(k).tstamp(:)];
    P = [P; rsk.data(k).values(:,iP)];
    V = [V; rsk.data(k).values(:,iV)];
end

figure('Position',[100 100 1100 400]);
ax = axes;
scatter(T, P, 4, V, 'filled');
axis ij; datetick('x','mm/dd','keeplimits');
clim(ax, [2 6]);                      % O2 in umol/L: [55 400]
colormap(ax, crameri('tokyo'));       % use crameri('-tokyo') to reverse
cb = colorbar(ax);
cb.Label.String = sprintf('Dissolved O2 (mg/L)', units{iV});
ylabel('Sea Pressure (dbar)');
title('WWN September to October upcasts', 'FontWeight', 'bold');
%% saving

save('WWN_CTD_SepOct2026_processed_L1.mat','rsk') % Echo_CTD_22Jul2026_flood_TowYo_RSKdata_processed_L1.mat

data = rsk.data;
channels = rsk.channels;

save('WWN_CTD_SepOct2026_processed_DataAndChannelsOnly_L1.mat','data', 'channels') % Echo_CTD_22Jul2026_flood_TowYo_DataAndChannelsOnly_processed_L1.mat

save('WWN_CTD_SepOct2026_processed_raw_L0.mat', 'raw') % Echo_CTD_22Jul2026_flood_TowYo_RSKdata_raw_L0.mat


%% helper functions


function reportNaN(rsk, label)
vals  = cat(1, rsk.data.values);
names = {rsk.channels.longName};
fprintf('\n--- %s: %d profiles, %d samples ---\n', label, numel(rsk.data), size(vals,1));
for k = 1:numel(names)
    fprintf('  %-22s %5.1f%% NaN\n', names{k}, 100*mean(isnan(vals(:,k))));
end
end