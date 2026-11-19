 % tryign to understand the lat and lon spikes in SWIFT 29
 clear, close all
 %%
 load('/Users/heffem3/Desktop/M2O2/SWIFTs/FullDatasets/SepOct2026/SWIFT29_SDcard_SepOct2026/SWIFT29_SDcard_SepOct2026_L2.mat')

figure(1); clf;
plot(SWIFT.time, SWIFT.lat, '-r')
hold on
plot(SWIFT.time, SWIFT.lon, '-b')