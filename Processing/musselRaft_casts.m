%%% plotting for the mussel raft CTD casts with the concerto %%%

% Maia Heffernan, Sep. 8 2026

clear all, close all

%% load in the data

% load 'musselrafts_27Aug2026_processed_L1_DataAndChannelsOnly_L1.mat'

load Echo_CTD_21Jul2026_and_22Jul2026ebb_TowYo_DataAndChannelsOnly_processed_L1.mat

%% pulling out just the mussel rafts


% in August, casts 5 and 6 were the mussel raft casts

musselRaftCasts = data(:, 34:35);

%% plot the two casts as lines with temperature, salinity, adn oxygen


figure(1); clf;
s1 = subplot(2,3,1); % first cast, salinity
    plot(musselRaftCasts(1).values(:,8), musselRaftCasts(1).values(:,7).*3.28, 'b-', 'LineWidth', 2);
    ylabel(s1, 'Depth (ft)');
    xlabel(s1, 'Salinity (PSU)');
    subtitle('Salinity');
    set(gca, 'YDir', 'reverse')
    ylim(s1, [1.5 46])

s2 = subplot(2,3,2); % first cast, temp
    plot(musselRaftCasts(1).values(:,2), musselRaftCasts(1).values(:,7).*3.28, 'g-', 'LineWidth', 2);
    ylabel(s2, 'Depth (ft)');
    xlabel(s2, 'Temperature (°C)');
    subtitle('Temperature');
    title('Cast 1 July 21')
    set(gca, 'YDir', 'reverse')
    ylim(s2, [1.5 48])

s3 = subplot(2,3,3); % first cast, DO
    plot(musselRaftCasts(1).values(:,14), musselRaftCasts(1).values(:,7).*3.28, 'm-', 'LineWidth', 2);
    hold on
    xline(2, 'k--', 'LineWidth', 1)
    ylabel(s3, 'Depth (ft)');
    xlabel(s3, 'Dissolved oxygen (mg/L)');
    subtitle('Dissolved oxygen');
    hold off
    set(gca, 'YDir', 'reverse')
    ylim(s3, [1.5 48])

s4 = subplot(2,3,4); % second cast, salinity
    plot(musselRaftCasts(2).values(:,8), musselRaftCasts(2).values(:,7).*3.28, 'b-', 'LineWidth', 2);
    ylabel(s4, 'Depth (ft)');
    xlabel(s4, 'Salinity (PSU)');
    subtitle('Salinity');
    set(gca, 'YDir', 'reverse')
    ylim(s4, [1.5 48])

s5 = subplot(2,3,5); % second cast, temp
    plot(musselRaftCasts(2).values(:,2), musselRaftCasts(2).values(:,7).*3.28, 'g-', 'LineWidth', 2);
    ylabel(s5, 'Depth (ft)');
    xlabel(s5, 'Temperature (°C)');
    subtitle('Temperature');
    title('Cast 2 July 21')
    set(gca, 'YDir', 'reverse')
    ylim(s5, [1.5 48])

s6 = subplot(2,3,6); % second cast, DO
    plot(musselRaftCasts(2).values(:,14), musselRaftCasts(2).values(:,7).*3.28, 'm-', 'LineWidth', 2);
    hold on
    xline(2, 'k--', 'LineWidth', 1)
    ylabel(s6, 'Depth (ft)');
    xlabel(s6, 'Dissolved oxygen (mg/L)');
    subtitle('Dissolved oxygen');
    hold off
    set(gca, 'YDir', 'reverse')
    ylim(s6, [1.5 48])



 linkaxes([s1 s2 s3 s4 s5 s6], 'y')

 linkaxes([s1 s4], 'x')

 linkaxes([s2 s5], 'x')

 linkaxes([s3 s6], 'x')


 set(findall(gcf, '-property', 'FontSize'), 'FontSize', 14)
 