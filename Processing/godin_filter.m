function [t_out, y] = godin_filter(t, x, min_coverage)
% GODIN_FILTER  Applies the classic Godin filter (A24*A24*A25)
%   [t_out, y] = godin_filter(t, x, min_coverage)
%
%   t : vector of timestamps (datetime, or datenum as double)
%   x : data matrix, rows = time steps, columns = separate variables/series
%   min_coverage : (optional, default 0.5) minimum fraction of valid,
%                  present data required within the effective window for
%                  a point to be kept; otherwise output is NaN. Guards
%                  against long gaps producing a spurious "average" from
%                  just a few nearby points.
%
%   Uses time-based (not sample-count-based) moving windows via
%   movmean's 'SamplePoints' option, so it works correctly for
%   irregular sampling and gaps, not just uniform hourly data.

if nargin < 3 || isempty(min_coverage)
    min_coverage = 0.5;
end

t = t(:);
if size(x,1) ~= length(t)
    error('Number of rows in x must match length of t.');
end

% Accept datenum (numeric) or datetime
if isnumeric(t)
    t = datetime(t, 'ConvertFrom', 'datenum');
end

% Make sure time is sorted ascending (gaps are fine, out-of-order isn't)
[t, sortIdx] = sort(t);
x = x(sortIdx, :);

w1 = hours(24);
w2 = hours(24);
w3 = hours(25);

y = movmean(x, w1, 1, 'omitnan', 'SamplePoints', t);
y = movmean(y, w2, 1, 'omitnan', 'SamplePoints', t);
y = movmean(y, w3, 1, 'omitnan', 'SamplePoints', t);

% --- Coverage check: how much real data actually fed each output point ---
valid = double(~isnan(x));
cov = movmean(valid, w1, 1, 'omitnan', 'SamplePoints', t);
cov = movmean(cov,   w2, 1, 'omitnan', 'SamplePoints', t);
cov = movmean(cov,   w3, 1, 'omitnan', 'SamplePoints', t);
y(cov < min_coverage) = NaN;

% --- Edge masking (same ~36.5 hr half-width as before, now time-based) ---
edge_dur = hours(36.5);
edgeMask = (t - t(1) < edge_dur) | (t(end) - t < edge_dur);
y(edgeMask, :) = NaN;

t_out = t;
end