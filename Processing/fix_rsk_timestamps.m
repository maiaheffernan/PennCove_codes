function out = fix_rsk_timestamps(rskFile, opts)
% FIX_RSK_TIMESTAMPS  Rescale the time axis of an RBR .rsk file whose logger
% was set to 32 Hz but whose sensors (here the Coda optode) really ran slower.
%
%
% Created by Claude, guided and edited by Maia Heffernan, Oct. 31, 2026
%
%   out = fix_rsk_timestamps('Echo_CTD_23Sep2026_ebb.rsk', opts)
%
%   Example call: out = fix_rsk_timestamps('Echo_CTD_23Sep2026_flood.rsk', struct('adcpRawFile','Echo_ADCP_23Sep2026_flood.mat'));
%
%
% BACKGROUND
%   The .rsk timestamps are NOMINAL: tstamp(n) = t0 + n/fs_nominal, with
%   fs_nominal = 32 Hz. The file contains no independent clock, so the true
%   sampling rate cannot be read from the file; it has to come from outside.
%   Because the real sample spacing was longer than 1/32 s, the whole record
%   really lasted longer than the nominal timestamps say, and the time axis
%   must be STRETCHED about the first sample:
%
%       t_corr = t0 + (t_rec - t0) * x + lag,      x = fs_nominal / fs_true
%
%   (x ~ 1.54 for fs_true ~ 20.8 Hz). Only the time axis changes; the sample
%   VALUES are untouched. t0 is the first sample and does not move, because
%   the logger start time was set from the real-time clock.
%
% HOW THE TRUE RATE IS DETERMINED (first one found in this list is used)
%   opts.fsTrue    true rate in Hz (e.g. 20.8 from RBR)
%   opts.realEnd   real UTC time (datetime) of the LAST sample; the rate is
%                  then (N-1) / (realEnd - t0)
%   opts.adcpRawFile  path to the RAW WinADCP .mat export (preferred), or
%   opts.adcpFile     path to the cleaned ADCP .mat (time/depth/east/north...).
%                  The rate is estimated by matching each CTD profile's maximum
%                  depth to the ADCP bottom-track depth under the vessel at the
%                  same moment. Whichever method is used, if an ADCP file is
%                  given the script also reports how well the result matches.
%                  If both are given the raw file is used.
%
% OTHER OPTIONS (all optional)
%   opts.adcpTimeVar / opts.adcpDepthVar   names of the variables in the CLEANED
%                  ADCP file (defaults 'time' = datenum UTC, 'depth' = bottom depth m)
%   opts.adcpAddTransducerDepth  raw file only: add the ADCP transducer depth
%                  (AnDepthmm, ~0.75-1.35 m) to the bottom range so the ADCP depth
%                  is measured from the surface like the CTD depth (default true)
%   opts.xRange    [min max] scale factors searched (default [1.3 1.8])
%   opts.xStep     search step for x (default 0.0005)
%   opts.fitLag    true = also fit a constant clock offset in seconds (default false)
%   opts.lagRange  +/- seconds searched when fitLag is true (default 120)
%   opts.minProfileSamples  ignore profiles shorter than this (default 20)
%   opts.makePlots, opts.saveOutput   true/false (default true)
%
% REQUIRES: a way to read SQLite files from MATLAB - ONE of:
%   (a) Database Toolbox (the 'sqlite' function; R2022a or newer is best), or
%   (b) mksqlite, a free MEX reader. It is bundled with RBR's free RSKtools,
%       so add RSKtools to the path first: addpath(genpath('C:\path\to\RSKtools'))
%   The script uses (a) if it is installed, otherwise (b).
% The .rsk file itself is never modified. Output files written next to it:
%   <name>_timefixed.mat   and   <name>_casts.csv

%% ======================================================================
%% 0. DEFAULT OPTIONS
%% ======================================================================
% opts is optional; if the caller passed nothing, start with an empty struct
% so the isfield tests below do not fail.
if nargin < 2, opts = struct(); end

% Fill in every option the caller did not set, so the rest of the code can
% simply read opts.<name> without checking again.
if ~isfield(opts,'makePlots'),         opts.makePlots = true;          end
if ~isfield(opts,'saveOutput'),        opts.saveOutput = true;         end
if ~isfield(opts,'adcpTimeVar'),       opts.adcpTimeVar = 'time';      end
if ~isfield(opts,'adcpDepthVar'),      opts.adcpDepthVar = 'depth';    end
if ~isfield(opts,'adcpAddTransducerDepth'), opts.adcpAddTransducerDepth = true; end
if ~isfield(opts,'xRange'),            opts.xRange = [1.3 1.8];        end
if ~isfield(opts,'xStep'),             opts.xStep = 0.0005;            end
if ~isfield(opts,'fitLag'),            opts.fitLag = false;            end
if ~isfield(opts,'lagRange'),          opts.lagRange = 120;            end
if ~isfield(opts,'minProfileSamples'), opts.minProfileSamples = 20;    end

%% ======================================================================
%% 1. READ THE RSK FILE 
%% ======================================================================
% ---- make sure the .rsk file can actually be found ---------------------
% SQLite reports a missing file as the vague "unable to open database file",
% so check first and give a clear message. Also expand a leading '~' (macOS /
% Linux home folder) and turn relative names into full paths, because the
% database reader does not search the MATLAB path the way load() does.
rskFile = char(rskFile);
if startsWith(rskFile,'~')
    rskFile = fullfile(getenv('HOME'), rskFile(2:end));
end
[fileFound, fileInfo] = fileattrib(rskFile);
if ~fileFound
    error(['Cannot find the .rsk file "%s".\nCurrent folder: %s\n' ...
           'Either cd to the folder containing it or give the full path.'], ...
           rskFile, pwd);
end
rskFile = fileInfo.Name;            % full absolute path
fprintf('Reading %s\n', rskFile);

% Open read-only so there is no chance of damaging the original file.
% dbOpen (local helper, bottom of this file) picks the Database Toolbox or
% mksqlite automatically, so the rest of the script does not care which.
conn = dbOpen(rskFile);
% onCleanup closes the database when the function ends, even after an error.
cleanup = onCleanup(@() dbClose(conn));

% Channel dictionary: which short name (e.g. 'pres24', 'doxy33') and units
% belong to which channel number.
ch = dbFetch(conn,'SELECT channelID, shortName, units FROM channels ORDER BY channelID');
ch = toTable(ch,{'channelID','shortName','units'});

% The main time series. Columns are tstamp, channel01, channel02, ...
% tstamp is milliseconds since 1970-01-01 00:00:00 UTC.
raw    = dbFetch(conn,'SELECT * FROM data ORDER BY tstamp');
nCols  = size(raw,2);
raw    = toTable(raw, ['tstamp', compose('channel%02d',1:nCols-1)]);

% Pull the time column out as a plain double vector (milliseconds).
tRec_ms = double(raw.tstamp);
N       = numel(tRec_ms);      % number of samples
nCh     = width(raw) - 1;      % number of data channels actually stored

% Build readable variable names such as 'pres24_dbar' or 'doxy33_molL' from
% the channel dictionary. Row k of the channel table is channelNN with NN=k.
varNames = cell(1,nCh);
for k = 1:nCh
    varNames{k} = sprintf('%s_%s', char(string(ch.shortName(k))), ...
                          cleanUnits(char(string(ch.units(k)))));
end

% The instrument's own cast detection: one row per DOWN or UP cast, with
% start/stop times in (nominal) milliseconds.
casts = dbFetch(conn,['SELECT r.regionID, c.type, r.tstamp1, r.tstamp2 ' ...
    'FROM region r JOIN regionCast c ON r.regionID = c.regionID ' ...
    'WHERE r.type = ''CAST'' ORDER BY r.tstamp1']);
casts = toTable(casts,{'regionID','direction','t1_ms','t2_ms'});

% The instrument's PROFILE regions (one DOWN+UP pair each). These are what
% the ADCP matching uses, because each profile has one clear deepest point.
prof = dbFetch(conn,['SELECT tstamp1, tstamp2 FROM region ' ...
                   'WHERE type = ''PROFILE'' ORDER BY tstamp1']);
prof = toTable(prof,{'t1_ms','t2_ms'});

%% ======================================================================
%% 2. NOMINAL SAMPLING RATE (what the file claims)
%% ======================================================================
t0_ms     = tRec_ms(1);                          % first sample, ms
dur_nom_s = (tRec_ms(end) - t0_ms)/1000;         % nominal duration, s
fsNom     = (N-1)/dur_nom_s;                     % should come out ~32 Hz
fsNom     = round(fsNom*100)/100;                % snap away ms rounding noise

fprintf('File: %s\n', rskFile);
fprintf('  samples: %d   nominal rate: %.3f Hz   nominal duration: %.1f s\n', ...
        N, fsNom, dur_nom_s);

%% ======================================================================
%% 3. DEPTH SERIES USED FOR ADCP MATCHING
%% ======================================================================
% Prefer the CTD's own depth channel (dpth01, metres). If a file has none,
% fall back to pressure minus 10.1325 dbar atmosphere (1 dbar ~ 1 m).
zCTD = getVar(raw,varNames,'dpth',false);
if isempty(zCTD)
    zCTD = getVar(raw,varNames,'pres',true) - 10.1325;
end

% For every profile find the deepest sample and its (recorded) time. These
% two vectors (time of max, value of max) are all the ADCP match needs.
tPk_ms = nan(height(prof),1);    % recorded time of the deepest point
zPk    = nan(height(prof),1);    % depth of the deepest point
for k = 1:height(prof)
    % samples whose recorded time lies inside profile k
    idx = find(tRec_ms >= prof.t1_ms(k) & tRec_ms <= prof.t2_ms(k));
    % skip tiny profiles (instrument blips) - they give unreliable maxima
    if numel(idx) < opts.minProfileSamples, continue; end
    [zPk(k), j] = max(zCTD(idx));
    tPk_ms(k)   = tRec_ms(idx(j));
end
okPk   = ~isnan(zPk);            % keep only profiles that passed the length test
tPk_ms = tPk_ms(okPk);
zPk    = zPk(okPk);

%% ======================================================================
%% 4. READ THE ADCP FILE (optional but recommended)
%% ======================================================================
% Two ADCP inputs are understood:
%   adcpRawFile : the raw WinADCP export (variables SerYear, AnBTDepthcmB1...)
%   adcpFile    : the cleaned file (variables time, depth, east, north, ...)
% If both are supplied the raw file wins because it has centisecond times and
% the transducer depth, which the cleaned file has lost.
haveRaw     = isfield(opts,'adcpRawFile') && ~isempty(opts.adcpRawFile);
haveCleaned = isfield(opts,'adcpFile')    && ~isempty(opts.adcpFile);
haveADCP    = haveRaw || haveCleaned;

if haveRaw
    A = load(opts.adcpRawFile);                   % structure of the raw .mat contents

    % ---- ensemble times -------------------------------------------------
    % WinADCP stores the ensemble time as separate year/month/day/hour/
    % minute/second/hundredth fields. Year is 2-digit (26 -> 2026). The
    % clock is UTC (checked: matches the cleaned file's datenum times).
    % Build the whole-second time first, then add seconds + hundredths so a
    % hundredths value of 100 simply rolls over instead of making an
    % invalid datetime.
    adcpDT = datetime(2000+double(A.SerYear(:)), double(A.SerMon(:)),  ...
                      double(A.SerDay(:)),       double(A.SerHour(:)), ...
                      double(A.SerMin(:)), 0, 'TimeZone','UTC') ...
             + seconds(double(A.SerSec(:)) + double(A.SerHund(:))/100);
    adcpMs = posixtime(adcpDT)*1000;              % ms since 1970, like the CTD

    % ---- bottom depth ---------------------------------------------------
    % Bottom tracking gives one VERTICAL range per beam (cm) from the
    % transducer to the seabed. Combine the 4 beams into one number: their
    % mean. A beam range of 0 means "no bottom lock"; if any beam failed the
    % ensemble is marked bad (NaN), which reproduces the cleaned file exactly.
    BT  = double([A.AnBTDepthcmB1(:) A.AnBTDepthcmB2(:) ...
                  A.AnBTDepthcmB3(:) A.AnBTDepthcmB4(:)])/100;   % -> metres
    adcpZ = mean(BT,2);
    adcpZ(any(BT <= 0, 2)) = NaN;
    % The ranges are measured from the transducer, which sits roughly 0.75-
    % 1.35 m below the surface. The CTD depth is measured from the surface,
    % so add the transducer depth to put both on the same footing. This
    % shifts all ADCP depths by about +1.1 m but does not change the
    % correlation or the best x.
    if opts.adcpAddTransducerDepth
        adcpZ = adcpZ + double(A.AnDepthmm(:))/1000;
    end
    % Within-ensemble spread between beams: a rough indicator of how sloped
    % or rough the seabed was under the 4 beam footprints.
    beamSpread = max(BT,[],2) - min(BT,[],2);
    beamSpread(any(BT <= 0, 2)) = NaN;
    fprintf('  ADCP (raw WinADCP): bottom depth = mean of 4 beams%s; median beam spread %.2f m\n', ...
        ternary(opts.adcpAddTransducerDepth,' + transducer depth',''), median(beamSpread,'omitnan'));

elseif haveCleaned
    A = load(opts.adcpFile);                      % structure of the cleaned .mat contents
    % Cleaned ADCP time is a MATLAB datenum in UTC (whole seconds only);
    % convert to milliseconds since 1970 so it is comparable with the CTD.
    adcpDT = datetime(A.(opts.adcpTimeVar)(:),'ConvertFrom','datenum','TimeZone','UTC');
    adcpMs = posixtime(adcpDT)*1000;
    % Bottom-track depth under the vessel, in metres, measured from the
    % transducer (the cleaned file has no transducer depth to add).
    adcpZ  = double(A.(opts.adcpDepthVar)(:));
end

if haveADCP
    % The ADCP writes 0 (or tiny values) when bottom tracking failed; those
    % are not real depths, so mask them out of the comparison.
    adcpGood = adcpZ > 1 & ~isnan(adcpZ);
    fprintf('  ADCP: %d ensembles, %s -> %s, %.0f%% with valid bottom depth\n', ...
        numel(adcpMs), string(adcpDT(1),'HH:mm:ss'), string(adcpDT(end),'HH:mm:ss'), ...
        100*mean(adcpGood));
end

%% ======================================================================
%% 5. DECIDE THE TRUE SAMPLING RATE
%% ======================================================================
lag_s = 0;                 % constant clock offset in seconds (0 unless fitted)
rCurve = []; xGrid = [];   % filled in when the ADCP search runs (used for plots)

if isfield(opts,'fsTrue')
    % ---- method A: you tell it the rate --------------------------------
    fsTrue = opts.fsTrue;
    how    = 'user-supplied rate';
    x      = fsNom/fsTrue;

elseif isfield(opts,'realEnd')
    % ---- method B: you tell it when the last sample REALLY happened ----
    % The first sample is at the real start time t0, the last at realEnd,
    % and there are N-1 sample intervals in between.
    t0dt   = datetime(t0_ms/1000,'ConvertFrom','posixtime','TimeZone','UTC');
    realEnd = datetime(opts.realEnd,'TimeZone','UTC');
    fsTrue = (N-1)/seconds(realEnd - t0dt);
    how    = 'from real end time';
    x      = fsNom/fsTrue;

elseif haveADCP
    % ---- method C: estimate x by matching to the ADCP ------------------
    % Search many trial values of x. For each, move every profile's deepest
    % point to its corrected time, look up the ADCP bottom depth at that
    % time, and measure how well "deepest CTD depth" tracks "bottom depth".
    xGrid = opts.xRange(1):opts.xStep:opts.xRange(2);
    if opts.fitLag, lagGrid = -opts.lagRange:5:opts.lagRange; else, lagGrid = 0; end
    [rMat, nUsed] = adcpMatchScore(t0_ms,tPk_ms,zPk,adcpMs(adcpGood),adcpZ(adcpGood),xGrid,lagGrid); %#ok<ASGLU>
    % Pick the (x,lag) pair with the highest correlation.
    [~,iMax]       = max(rMat(:));
    [ix,il]        = ind2sub(size(rMat),iMax);
    x              = xGrid(ix);
    lag_s          = lagGrid(il);
    rCurve         = rMat(:,il);                  % correlation vs x at the best lag
    fsTrue         = fsNom/x;
    how            = 'from ADCP match';
else
    error(['No way to determine the true rate. Give opts.fsTrue, ' ...
           'opts.realEnd or opts.adcpFile.']);
end

fprintf('  true rate: %.4f Hz (%s)   x = fsNominal/fsTrue = %.5f', fsTrue, how, x);
if lag_s ~= 0, fprintf('   fitted clock offset = %+g s', lag_s); end
fprintf('\n');

% If the ADCP is available, report how good the match is for the x we
% ended up with (this is the sanity check for methods A and B), and how
% wide the peak is, which tells you the uncertainty of the rate.
if haveADCP
    r_here = adcpMatchScore(t0_ms,tPk_ms,zPk,adcpMs(adcpGood),adcpZ(adcpGood),x,lag_s);
    fprintf('  ADCP match at this x: r = %.3f\n', r_here);
    if ~isempty(rCurve)
        % x values whose correlation is within 5%% of the best: a rough
        % "plausible range" for the scale factor, converted to Hz.
        inPeak = rCurve >= 0.95*max(rCurve);
        fprintf('  x within 5%% of best correlation: %.4f - %.4f  (rate %.2f - %.2f Hz)\n', ...
            xGrid(find(inPeak,1,'first')), xGrid(find(inPeak,1,'last')), ...
            fsNom/xGrid(find(inPeak,1,'last')), fsNom/xGrid(find(inPeak,1,'first')));
    end
end

%% ======================================================================
%% 6. APPLY THE CORRECTION
%% ======================================================================
% Stretch elapsed time about the first sample, then add any fitted offset.
% (Multiplying the raw epoch time itself would be wrong: it would shift the
% whole record by years. Only the time elapsed since t0 is scaled.)
fixMs = @(t) t0_ms + (t - t0_ms)*x + lag_s*1000;

% Helper: milliseconds since 1970 -> MATLAB datetime in UTC.
toDT = @(ms) datetime(ms/1000,'ConvertFrom','posixtime','TimeZone','UTC');

tRec  = toDT(tRec_ms);          % times exactly as recorded (wrong)
tCorr = toDT(fixMs(tRec_ms));   % corrected times

% Correct the cast boundaries the same way, keeping the old ones for reference.
casts.start         = toDT(fixMs(casts.t1_ms));
casts.stop          = toDT(fixMs(casts.t2_ms));
casts.duration      = casts.stop - casts.start;
casts.start_nominal = toDT(casts.t1_ms);
casts.stop_nominal  = toDT(casts.t2_ms);
casts.castNum       = (1:height(casts))';

% Deepest point of each cast (looked up with the ORIGINAL recorded times,
% since the data are still indexed by those).
casts.maxDepth_m = nan(height(casts),1);
for k = 1:height(casts)
    idx = tRec_ms >= casts.t1_ms(k) & tRec_ms <= casts.t2_ms(k);
    if any(idx), casts.maxDepth_m(k) = max(zCTD(idx)); end
end
casts = casts(:,{'castNum','regionID','direction','start','stop','duration', ...
                 'maxDepth_m','start_nominal','stop_nominal'});

% Package the data as a table whose first column is the corrected time.
data = raw(:,2:end);
data.Properties.VariableNames = varNames;
data.time = tCorr;
data = movevars(data,'time','Before',1);

%% ======================================================================
%% 7. REPORT START / END TIMES
%% ======================================================================
fmt = 'yyyy-MM-dd HH:mm:ss.SSS';
fprintf('\nLogging (corrected, UTC): %s  ->  %s\n', string(tCorr(1),fmt), string(tCorr(end),fmt));
fprintf('Logging (as recorded)   : %s  ->  %s\n', string(tRec(1),fmt),  string(tRec(end),fmt));
fprintf('\n%d casts (%d down, %d up). First 10 and last 3, corrected UTC times:\n', ...
        height(casts), sum(string(casts.direction)=="DOWN"), sum(string(casts.direction)=="UP"));
disp(casts([1:min(10,end), max(11,end-2):end], 1:7));

% Sanity check: the corrected record should lie inside the ADCP record.
if haveADCP
    if tCorr(1) < adcpDT(1) || tCorr(end) > adcpDT(end)
        warning('Corrected CTD record extends beyond the ADCP record - check x.');
    end
end

%% ======================================================================
%% 8. PLOTS
%% ======================================================================
if opts.makePlots
    p = getVar(raw,varNames,'pres',true);        % CTD pressure for the plots

    % ---- Figure 1: before/after time axis and the main variables -------
    fig1 = figure('Name','Time correction','Color','w');          % <-- CHANGED 11/6
    tl = tiledlayout(3,1,'TileSpacing','compact');

    nexttile; hold on
    plot(tRec,  p, 'Color',[.7 .7 .7]);          % as recorded (grey)
    plot(tCorr, p, 'b');                         % corrected (blue)
    set(gca,'YDir','reverse'); ylabel('Pressure (dbar)'); grid on
    legend('as recorded','corrected','Location','best');
    title(sprintf('x = %.4f   (%.2f Hz true vs %.0f Hz nominal)',x,fsTrue,fsNom));

    nexttile; hold on
    plot(tCorr, getVar(raw,varNames,'temp14',true),'r');
    ylabel('Temperature (\circC)'); grid on

    nexttile; hold on
    plot(tCorr, getVar(raw,varNames,'doxy33',true),'k');
    ylabel('O_2 (\mumol/L)'); grid on; xlabel('Time (UTC, corrected)');
    linkaxes(tl.Children,'x');                   % zoom all three together

    % ---- Figure 2: individual casts coloured by direction --------------
    fig2 = figure('Name','Casts','Color','w'); hold on            % <-- CHANGED 11/6
    plot(tCorr, p, 'Color',[.8 .8 .8]);          % whole record in light grey
    for k = 1:height(casts)
        m = tCorr >= casts.start(k) & tCorr <= casts.stop(k);
        if string(casts.direction(k)) == "DOWN", c = 'b'; else, c = 'r'; end
        plot(tCorr(m), p(m), 'Color', c);
    end
    set(gca,'YDir','reverse'); grid on; ylabel('Pressure (dbar)');
    title('Corrected casts (blue = down, red = up)');

    % ---- Figure 3: ADCP validation -------------------------------------
    if haveADCP
        fig3 = figure('Name','ADCP validation','Color','w');      % <-- CHANGED 11/6
        tl3 = tiledlayout(3,1,'TileSpacing','compact');

        nexttile;
        if ~isempty(rCurve)
            plot(xGrid, rCurve,'k'); hold on
            xline(x,'r','LineWidth',1.5);
            xlabel('scale factor x'); ylabel('correlation r'); grid on
            title('Cast max depth vs ADCP bottom depth');
        else
            xg = opts.xRange(1):opts.xStep:opts.xRange(2);
            rr = adcpMatchScore(t0_ms,tPk_ms,zPk,adcpMs(adcpGood),adcpZ(adcpGood),xg,0);
            plot(xg, rr,'k'); hold on; xline(x,'r','LineWidth',1.5);
            xlabel('scale factor x'); ylabel('correlation r'); grid on
            title('Match quality vs x (red = value used)');
        end

        nexttile; hold on
        plot(adcpDT(adcpGood), adcpZ(adcpGood),'k.-');
        plot(tCorr, zCTD,'b');
        tPk_corr = toDT(fixMs(tPk_ms));
        plot(tPk_corr, zPk,'ro');
        set(gca,'YDir','reverse'); ylabel('Depth (m)'); grid on
        legend('ADCP bottom depth','CTD depth','profile max depth','Location','best');
        xlabel('Time (UTC, corrected)');

        nexttile;
        zBot = interp1(adcpMs(adcpGood), adcpZ(adcpGood), fixMs(tPk_ms), 'linear');
        plot(zBot, zPk, 'ko'); hold on
        lims = [0 max([zBot; zPk])*1.05];
        plot(lims, lims, 'r--');
        xlim(lims); ylim(lims); axis square; grid on
        xlabel('ADCP bottom depth (m)'); ylabel('CTD profile max depth (m)');
    end   % end of "if haveADCP"

    % ---- Save the figures, named by figure title + date + tide stage ---- % <-- NEW 11/6
    if opts.saveOutput                                                       % <-- NEW 11/6
        [d,n] = fileparts(rskFile);                                          % <-- NEW 11/6 
        % Pull "23Sep2026_flood" out of e.g. "Echo_CTD_23Sep2026_flood"
        tok = regexp(n,'(\d{1,2}[A-Za-z]{3}\d{4})_([A-Za-z]+)$','tokens','once'); % <-- NEW 11/6
        if isempty(tok), tag = n; else, tag = [tok{1} '_' tok{2}]; end       % <-- NEW 11/6

        figList = [fig1, fig2];                                              % <-- NEW 11/6
        if haveADCP, figList(end+1) = fig3; end                              % <-- NEW 11/6
        for f = figList                                                      % <-- NEW 11/6
            figTitle = strrep(f.Name,' ','_');                               % <-- NEW 11/6
            exportgraphics(f, fullfile(d, sprintf('%s_%s.png', figTitle, tag)), ... % <-- NEW 11/6
                           'Resolution', 300);                               % <-- NEW 11/6
        end                                                                  % <-- NEW 11/6
        fprintf('Saved %d figures with tag %s\n', numel(figList), tag);      % <-- NEW 11/6
    end                                                                      % <-- NEW 11/6
end   % end of "if opts.makePlots"

%% ======================================================================
%% 9. OUTPUT
%% ======================================================================
out = struct('data',data,'casts',casts,'x',x,'fsTrue',fsTrue, ...
             'fsNominal',fsNom,'lag_s',lag_s);
if haveADCP
    % Keep the ADCP (with real datetimes) so the corrected CTD and the
    % ADCP can be used together straight away.
    out.adcp = A;
    out.adcp.dt = adcpDT;           % real datetimes (UTC)
    out.adcp.bottomDepth = adcpZ;   % depth used for the match (m, NaN = no lock)
end
if opts.saveOutput
    [d,n] = fileparts(rskFile);
    save(fullfile(d,[n '_timefixed.mat']),'-struct','out');
    writetable(casts,fullfile(d,[n '_casts.csv']));
    fprintf('\nSaved %s_timefixed.mat and %s_casts.csv\n', n, n);
end
end

%% ======================================================================
%% LOCAL HELPER FUNCTIONS
%% ======================================================================

function T = toTable(c,names)
% Make sqlite/fetch output a table with the given column names, whether
% fetch returned a cell array (older MATLAB) or a table (R2022a and newer).
if istable(c)
    T = c;
    T.Properties.VariableNames = names;
else
    T = cell2table(c,'VariableNames',names);
end
end

function s = cleanUnits(u)
% Turn units such as 'µmol/L' or 'mS/cm' into text valid inside a variable
% name by stripping everything that is not a letter or digit.
s = regexprep(u,'[^A-Za-z0-9]','');
if isempty(s), s = 'NA'; end
end

function v = getVar(raw,varNames,prefix,required)
% Return the first data channel whose name starts with PREFIX as a double
% vector (e.g. prefix 'pres' -> pres24, the CTD pressure). If none exists:
% error when REQUIRED is true, otherwise return [].
i = find(startsWith(varNames,prefix),1);
if isempty(i)
    if required, error('No channel starting with "%s" in this file.',prefix); end
    v = [];
    return
end
v = double(raw{:,i+1});     % +1 because column 1 of raw is tstamp
end

function [r, nUsed] = adcpMatchScore(t0_ms,tPk_ms,zPk,aMs,aZ,xGrid,lagGrid)
% Score how well CTD cast depths agree with the ADCP bottom depth for each
% trial (x, lag).
%   t0_ms  first CTD sample time           tPk_ms  recorded time of each profile's deepest point
%   zPk    depth of that point (m)         aMs,aZ  ADCP time (ms) and bottom depth (m), valid only
%   xGrid  trial scale factors             lagGrid trial clock offsets (s)
% Returns r(i,j) = correlation coefficient for xGrid(i), lagGrid(j), and
% nUsed(i,j) = number of profiles that fell inside the ADCP record.
r     = nan(numel(xGrid),numel(lagGrid));
nUsed = zeros(numel(xGrid),numel(lagGrid));
for i = 1:numel(xGrid)
    for j = 1:numel(lagGrid)
        % where the deepest points would sit in real time for this x, lag
        tc = t0_ms + (tPk_ms - t0_ms)*xGrid(i) + lagGrid(j)*1000;
        % bottom depth under the vessel at those moments (NaN outside ADCP record)
        zb = interp1(aMs,aZ,tc,'linear');
        ok = ~isnan(zb) & ~isnan(zPk);
        nUsed(i,j) = nnz(ok);
        if nnz(ok) >= 20                       % need enough points for a fair score
            cc = corrcoef(zb(ok),zPk(ok));
            r(i,j) = cc(1,2);
        end
    end
end
end

function v = ternary(cond,a,b)
% Tiny inline if/else used to build the printed message above.
if cond, v = a; else, v = b; end
end

function db = dbOpen(file)
% Open an SQLite file read-only with whichever reader is available.
db = struct('kind','','h',[]);
if ~isempty(which('sqlite'))
    % Database Toolbox
    db.kind = 'dbtoolbox';
    db.h    = sqlite(file,'readonly');
elseif exist('mksqlite','file') == 3
    % mksqlite MEX (comes with RSKtools). Newer versions accept an access
    % flag 'RO'; older ones only take the file name, hence the try/catch.
    db.kind = 'mksqlite';
    try
        mksqlite('open',file,'RO');
    catch
        mksqlite('open',file);
    end
else
    error(['No SQLite reader found. Install the Database Toolbox, or add ' ...
           'RBR''s RSKtools (which includes mksqlite) to the MATLAB path: ' ...
           'addpath(genpath(''<folder of RSKtools>''))']);
end
end

function dbClose(db)
% Close whichever connection dbOpen made.
try
    if strcmp(db.kind,'mksqlite'), mksqlite('close'); else, close(db.h); end
catch
end
end

function T = dbFetch(db,sql)
% Run an SQL query and return the result as a table (or a cell array from
% very old Database Toolbox versions, which toTable also accepts).
if strcmp(db.kind,'dbtoolbox')
    T = fetch(db.h,sql);
    return
end
% ---- mksqlite ----
% The big time-series query would become a huge array of structs (one per
% sample). Ask mksqlite for column vectors instead when it supports it.
isBig = strncmp(sql,'SELECT * FROM data',18);
if isBig
    try, mksqlite('result_type',1); catch, end
end
r = mksqlite(sql);
if isBig
    try, mksqlite('result_type',0); catch, end
end
if iscell(r)
    T = cell2table(r);                    % column names are assigned by toTable
else
    if isscalar(r)                        % struct of arrays: make columns vertical
        f = fieldnames(r);
        for i = 1:numel(f), r.(f{i}) = r.(f{i})(:); end
    end
    T = struct2table(r);
end
end