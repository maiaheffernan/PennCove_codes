%%%% Post-processing from Ruskin steps %%%%

%%% RBR plotting profiles ONLY DOWNCASTS %%%

clear all, close all

%% read with RSKtools

rsk = RSKopen( [ 'Echo_CTD_21Jul2026.rsk' ]);
% print a list of all the channels in the rsk file
RSKprintchannels(rsk)
% read the downcast from profiles 
rsk = RSKreadprofiles(rsk, 'direction', 'down');

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
 'channel',{'Temperature','Conductivity','Dissolved O21'});


% plot a few profiles of temperature, conductivity, and chlorophyll
% RSKplotprofiles(rsk,'profile',[1 10 20],...
%  'channel',{'Temperature1','conductivity','Dissolved O2'});
%% Saving a copy of the raw data to compare with the processed data

raw = rsk;


%% Correct for A2D zero-order hold

% --------------------------------
% Rusking description of reasoning
% --------------------------------

% The analog-to-digital (A2D) converter on RBR instruments must recalibrate periodically. In the time it takes for
% the calibration to finish, one or more samples are missed. The instrument firmware fills the missed sample with the
% same data measured during the previous sample, a technique called a zero-order hold.
% RSKcorrecthold identifies zero-hold points by finding where consecutive differences of each channel are equal
% to zero, and then replaces these samples with a NaN or an interpolated value. 

channel_name_list = {'Conductivity', 'Temperature', 'Pressure', 'Temperature2', 'Dissolved O21', 'Sea Pressure', 'Depth', 'Salinity', 'Dissolved O22'};

for i = 1:length(channel_name_list)
    [rsk, holdpts] = RSKcorrecthold(rsk,'channel', channel_name_list(i) ,'action', 'interp');
end


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


for i = 1:length(channel_name_list)
    [rsk, spike] = RSKdespike(rsk,'channel',channel_name_list{i},'threshold',1,'windowLength',11,'action','nan', 'visualize', 10); % the value of 10 at the being proflie 10, which is what will get visualized in the plot
end


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
rsk = RSKsmooth(rsk,'channel',{'temperature','conductivity', 'salinity'},...
 'windowLength', 11, 'visualize', 10); % the value of 10 at the being proflie 10, which is what will get visualized in the plot



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
lag = RSKcalculateCTlag(rsk,'seapressurerange',[0, max('Sea Pressure')]);
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


rsk = RSKderivedepth(rsk);
rsk = RSKderivevelocity(rsk);

% Apply the algorithm:  Outputs: RSK - Structure with data filtered by threshold profiling speed and removal of loops.
%                                flagidx - Index of the samples that are filtered.

[rsk, flagidx] = RSKremoveloops(rsk,'threshold',0.25,'visualize',7); % 0.25 value: minimum speed at which profile must be taken (units: m/s). This is the default rate from Ruskin. 



%% Derived variables

rsk = RSKderivesalinity(rsk);
rsk = RSKderivesigma(rsk);
rsk = RSKderiveseapressure(rsk);

raw = RSKderivesalinity(raw);
raw = RSKderivesigma(raw);
raw = RSKderiveseapressure(raw);



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



[rsk, samplesinbin] = RSKbinaverage(rsk, 'binBy', 'Sea Pressure', 'binSize', 0.25,...
    'boundary', [],'direction', 'down',...
    'visualize', 10);  %Outputs: RSK - Structure with binned data, samplesinbin - Amount of samples in each bin.
h = findobj(gcf,'type','line');
set(h(1:2:end),'marker','o','markerfacecolor','c')


%% Compare raw and processed data

figure();
channel = {'Temperature', 'Salinity', 'Dissolved O21'};
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
rsk = RSKderiveO2(rsk, 'toDerive', 'concentration', 'unit', 'mg/l');


%% 2D plot visualization

figure(); 

[im_hdl ax_hdl] = RSKimages(rsk, 'channel', {'Temperature', 'Salinity', 'Dissolved O23'}, 'direction', 'down');
clim(ax_hdl(1), [10, 18]);   % Temperature
clim(ax_hdl(2), [10, 30]);    % Salinity
clim(ax_hdl(3), [2, 12]);    % Dissolved O2

saveas(gcf, "pcolor_quicklook_SalTempDO.png")

%% saving

save('Echo_CTD_MayAnd23Jun2026_TowYo_RSKdata_processed_L1.mat','rsk')

data = rsk.data;
channels = rsk.channels;

save('Echo_CTD_MayAnd23Jun2026_TowYo_DataAndChannelsOnly_processed_L1.mat','data', 'channels')

save('Echo_CTD_MayAnd23Jun2026_TowYo_RSKdata_raw_L0.mat', 'raw')

