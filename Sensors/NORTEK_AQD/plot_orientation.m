%%% Plotting orientatino (pitch, roll, heading) from Nortek Aquadopp 

% Maia Heffernan, November 2026

clear, close all
%% load data

%fpath = '/Users/heffem3/Library/CloudStorage/GoogleDrive-heffem3@uw.edu/Shared drives/M2O2/Penn Cove 2026/Oct2026/Data/InnerNorth_SepOct2026/AQD/';
innerNorthAQD = load('/Users/heffem3/Library/CloudStorage/GoogleDrive-heffem3@uw.edu/Shared drives/M2O2/Penn Cove 2026/Oct2026/Data/InnerNorth_AQD_SepOct2026_bottom.mat');

innerSouthAQD = load('/Users/heffem3/Library/CloudStorage/GoogleDrive-heffem3@uw.edu/Shared drives/M2O2/Penn Cove 2026/Oct2026/Data/InnerSouth_AQD_SepOct2026.mat'); 

%% cut out the time period of interest

startTime = datetime(2026, 9, 24, 19, 30, 0);
endTime = datetime(2026, 10, 20, 14, 30, 0);

startTime_dn = datenum(startTime);
endTime_dn   = datenum(endTime);

% apply ot the data

validIndices_IN = innerNorthAQD.time >= startTime_dn & innerNorthAQD.time <= endTime_dn;

validIndices_IS = innerSouthAQD.time >= startTime_dn & innerSouthAQD.time <= endTime_dn;

innerNorthAQD.time = innerNorthAQD.time(validIndices_IN);
innerNorthAQD.pitch = innerNorthAQD.pitch(validIndices_IN);
innerNorthAQD.roll = innerNorthAQD.roll(validIndices_IN);
innerNorthAQD.heading = innerNorthAQD.heading(validIndices_IN);   

innerSouthAQD.time = innerSouthAQD.time(validIndices_IS);
innerSouthAQD.pitch = innerSouthAQD.pitch(validIndices_IS);
innerSouthAQD.roll = innerSouthAQD.roll(validIndices_IS);
innerSouthAQD.heading = innerSouthAQD.heading(validIndices_IS);
%% plot orientation



figure(1); clf;

s1 = subplot(3,1,1); % pitch
plot(innerNorthAQD.time, innerNorthAQD.pitch, 'b', 'LineWidth', 1.5); hold on;
plot(innerSouthAQD.time, innerSouthAQD.pitch, 'r', 'LineWidth', 1.5);
legend('Inner North', 'Inner South');
datetick('x', 'mm/dd/yy HH:MM', 'keepticks');
ylabel('(deg)');
title('Inner moorings Aquadopps pitch, roll, and heading')
subtitle('Pitch')

s2 = subplot(3,1,2); % roll
plot(innerNorthAQD.time, innerNorthAQD.roll, 'b', 'LineWidth', 1.5); hold on;
plot(innerSouthAQD.time, innerSouthAQD.roll, 'r', 'LineWidth', 1.5);
datetick('x', 'mm/dd/yy HH:MM', 'keepticks');
ylabel('(deg)');
subtitle('Roll')

s3 = subplot(3,1,3); % heading
plot(innerNorthAQD.time, innerNorthAQD.heading, 'b', 'LineWidth', 1.5); hold on;
plot(innerSouthAQD.time, innerSouthAQD.heading, 'r', 'LineWidth', 1.5);
datetick('x', 'mm/dd/yy HH:MM', 'keepticks');
ylabel('(deg)');
subtitle('Heading')

%% plot Inner North means with orientation

validMeans_IN = innerNorthAQD.timemeans >= startTime_dn & innerNorthAQD.timemeans <= endTime_dn;
tm_IN = innerNorthAQD.timemeans(validMeans_IN);
pm_IN = innerNorthAQD.presmeans(validMeans_IN);

figure(2); clf;
clear s

    s(1)=subplot(7,1,1);
    pcolor(tm_IN,innerNorthAQD.z',innerNorthAQD.umeans(validMeans_IN,:)'), 
    caxis([-0.18 0.18]),
    shading interp,
    colormap(gca, crameri('vik', 'pivot', 0))
    hc = colorbar;
    hc.Label.String = 'u (m/s)';
    hold on,
    plot(tm_IN, pm_IN, 'k.', 'MarkerSize', 2),
    datetick,
    axis tight
    ylabel('z (m)')
    title('Inner North AQD','interpreter','none'), 

    s(2)=subplot(7,1,2);
    pcolor(tm_IN,innerNorthAQD.z',innerNorthAQD.vmeans(validMeans_IN,:)'), 
    caxis([-0.18 0.18]),
    shading interp,
    colormap(gca, crameri('vik', 'pivot', 0))
    hc = colorbar;
    hc.Label.String = 'v (m/s)';
    hold on,
    plot(tm_IN, pm_IN, 'k.', 'MarkerSize', 2),
    datetick,
    axis tight
    ylabel('z (m)')

    s(3)=subplot(7,1,3);
    pcolor(tm_IN,innerNorthAQD.z',innerNorthAQD.wmeans(validMeans_IN,:)'), 
    caxis([-0.18 0.18]),
    shading interp,
    colormap(gca, crameri('vik', 'pivot', 0))
    hc = colorbar;
    hc.Label.String = 'w (m/s)';
    hold on,
    plot(tm_IN, pm_IN, 'k.', 'MarkerSize', 2),
    datetick,
    axis tight
    ylabel('z (m)')

s(4) = subplot(7,1,4); % pitch
plot(innerNorthAQD.time, innerNorthAQD.pitch, 'b', 'LineWidth', 1.5);
datetick; axis tight; ylabel('Pitch (deg)'); colorbar('Visible','off');

s(5) = subplot(7,1,5); % roll
plot(innerNorthAQD.time, innerNorthAQD.roll, 'b', 'LineWidth', 1.5);
datetick; axis tight; ylabel('Roll (deg)'); colorbar('Visible','off');

s(6) = subplot(7,1,6); % heading
plot(innerNorthAQD.time, innerNorthAQD.heading, 'b', 'LineWidth', 1.5);
datetick; axis tight; ylabel('Heading (deg)'); colorbar('Visible','off');

s(7) = subplot(7,1,7); % amplitude
pcolor(tm_IN,innerNorthAQD.z',innerNorthAQD.ameans(validMeans_IN,:)'), hold on
shading flat
plot(tm_IN, pm_IN, 'k.', 'MarkerSize', 2),
datetick,
axis tight
ylabel('z (m)')
hc = colorbar; 
hc.Label.String = 'Amp (dB)';

linkaxes(s,'x')


%% plot Inner South means with orientation

validMeans_IS = innerSouthAQD.timemeans >= startTime_dn & innerSouthAQD.timemeans <= endTime_dn;
tm_IS = innerSouthAQD.timemeans(validMeans_IS);
pm_IS = innerSouthAQD.presmeans(validMeans_IS);

figure(3); clf;
clear s

    s(1)=subplot(7,1,1);
    pcolor(tm_IS,innerSouthAQD.z',innerSouthAQD.umeans(validMeans_IS,:)'), 
    caxis([-0.18 0.18]),
    shading interp,
    colormap(gca, crameri('vik', 'pivot', 0))
    hc = colorbar;
    hc.Label.String = 'u (m/s)';
    hold on,
    plot(tm_IS, pm_IS, 'k.', 'MarkerSize', 2),
    datetick,
    axis tight
    ylabel('z (m)')
    title('Inner South AQD','interpreter','none'), 

    s(2)=subplot(7,1,2);
    pcolor(tm_IS,innerSouthAQD.z',innerSouthAQD.vmeans(validMeans_IS,:)'), 
    caxis([-0.18 0.18]),
    shading interp,
    colormap(gca, crameri('vik', 'pivot', 0))
    hc = colorbar;
    hc.Label.String = 'v (m/s)';
    hold on,
    plot(tm_IS, pm_IS, 'k.', 'MarkerSize', 2),
    datetick,
    axis tight
    ylabel('z (m)')

    s(3)=subplot(7,1,3);
    pcolor(tm_IS,innerSouthAQD.z',innerSouthAQD.wmeans(validMeans_IS,:)'), 
    caxis([-0.18 0.18]),
    shading interp,
    colormap(gca, crameri('vik', 'pivot', 0))
    hc = colorbar;
    hc.Label.String = 'w (m/s)';
    hold on,
    plot(tm_IS, pm_IS, 'k.', 'MarkerSize', 2),
    datetick,
    axis tight
    ylabel('z (m)')

s(4) = subplot(7,1,4); % pitch
plot(innerSouthAQD.time, innerSouthAQD.pitch, 'r', 'LineWidth', 1.5);
datetick; axis tight; ylabel('Pitch (deg)'); colorbar('Visible','off');

s(5) = subplot(7,1,5); % roll
plot(innerSouthAQD.time, innerSouthAQD.roll, 'r', 'LineWidth', 1.5);
datetick; axis tight; ylabel('Roll (deg)'); colorbar('Visible','off');

s(6) = subplot(7,1,6); % heading
plot(innerSouthAQD.time, innerSouthAQD.heading, 'r', 'LineWidth', 1.5);
datetick; axis tight; ylabel('Heading (deg)'); colorbar('Visible','off');

s(7) = subplot(7,1,7); % amplitude
pcolor(tm_IS,innerSouthAQD.z',innerSouthAQD.ameans(validMeans_IS,:)'), hold on
shading flat
plot(tm_IS, pm_IS, 'k.', 'MarkerSize', 2),
datetick,
axis tight
ylabel('z (m)')
hc = colorbar; 
hc.Label.String = 'Amp (dB)';

linkaxes(s,'x')

%% save figures

figpath = '/Users/heffem3/Documents/GitHub/PennCove_codes/Figures/SepOct2026/RawData_plots/';

exportgraphics(figure(2), [figpath 'InnerNorth_AQD_means_orientation.png'], 'Resolution', 300);
exportgraphics(figure(3), [figpath 'InnerSouth_AQD_means_orientation.png'], 'Resolution', 300);
