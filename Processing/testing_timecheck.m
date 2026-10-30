
% ADCP
[aExit, aEnter] = findWaterEvents(adcp_flood.time, adcp_flood.depth == 0, 60);

% CTD
rsk = RSKreaddata(rsk);
rsk = RSKderiveseapressure(rsk);
tc = rsk.data.tstamp;
Ps = rsk.data.values(:, strcmpi({rsk.channels.longName}, 'Sea Pressure'));
[cExit, cEnter] = findWaterEvents(tc, Ps < 0.5, 60);

fprintf('ADCP: %d exits, %d entries | CTD: %d exits, %d entries\n', ...
    numel(aExit), numel(aEnter), numel(cExit), numel(cEnter));


%%

assert(numel(aExit)==numel(cExit) && numel(aEnter)==numel(cEnter), ...
    'Event counts differ; adjust threshold or minGap_s');

dtExit  = (cExit  - aExit )  * 86400;   % seconds, + means CTD later
dtEnter = (cEnter - aEnter)  * 86400;

% sanity check: every pair should be within about a minute or two
disp([dtExit dtEnter])

figure; hold on
plot(aExit,  dtExit,  'o', 'DisplayName', 'exit water');
plot(aEnter, dtEnter, 's', 'DisplayName', 'enter water');
datetick('x'); ylabel('CTD - ADCP (s)'); legend; grid on




%% helper function
function [tExit, tEnter] = findWaterEvents(t, outOfWater, minGap_s)
% t: datenum, outOfWater: logical (same length)
out = outOfWater(:);
d = diff([false; out; false]);
iExit  = find(d ==  1);              % first out-of-water sample
iEnter = find(d == -1);              % first in-water sample after a gap

% handle records that start or end out of water
if numel(iEnter) < numel(iExit), iEnter(end+1) = numel(t); end

% drop short gaps (waves, dropouts)
durs = (t(min(iEnter, numel(t))) - t(iExit)) * 86400;
keep = durs >= minGap_s;
tExit  = t(iExit(keep));
tEnter = t(min(iEnter(keep), numel(t)));
end

%%

