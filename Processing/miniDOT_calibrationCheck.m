%%% Comparing the minDOT and TODO data to see how poorly the miniDOTs read
%%% 

% Maia H, Sept. 2026

% In July I did a bucket test with the miniDOTs and a TODO. I just put them
% all in the same large pelican case, closed the lid, and then had them
% read for a while. This is by NO means the recommended calibration, but it
% is worth a shot ot look at the plot

clear, close

%% load in the data

% the TODO

    % NOTE: we used the TODO from inner north for this

% load TODOdata_JunJul2026_raw.mat

% hte miniDOTs

load miniDOT_JunJul2026_mooringdata_raw.mat
load miniDOT_JunJul2026_raftdata_raw.mat

%% plot the Q scores

figure;
hold on;
plot(raft_3m.Q, 'DisplayName', 'Raft miniDOT 3m');
plot(raft_1m.Q, 'DisplayName', 'Raft miniDOT 1m');
xlabel('Sample');
ylabel('Q score');
legend('Location', 'best');
grid on;

%% pull out the times when the 3m raft oxygen data was below 0.4 mg/L

lowOxygenIdx = raft_3m.DissolvedOxygen < 0.4;
% lowOxygenTimes = raft_3m.DateTime(lowOxygenIdx);
% lowOxygenValues = raft_3m.O2(lowOxygenIdx);

lowO2filterd_3m= raft_3m(lowOxygenIdx, :);

%% plot the low-oxygen observations and hte q score

figure;
yyaxis left
plot(lowO2filterd_3m.UTC_Date___Time, lowO2filterd_3m.DissolvedOxygen, 'o');
ylabel('Dissolved oxygen (mg/L)');
yyaxis right
plot(lowO2filterd_3m.UTC_Date___Time, lowO2filterd_3m.Q, 'x');
ylabel('Q score');
xlabel('Date and time');
grid on;

%% what is the minimum Q score from the filtered data?

min_Q_filtered = min(lowO2filterd_3m.Q); %0.911