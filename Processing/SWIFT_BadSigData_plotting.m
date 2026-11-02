%%%% Plot Signature ADCP east/north velocity (pcolor) from SWIFT L1 files


%%% Code is gnerated by Claude, edited and maintained by Maia H. October
%%% 2026



clear; close all
%%
% ---- edit these: full path to each file (folders can differ) ----
files = {'/Users/heffem3/Desktop/M2O2/SWIFTs/FullDatasets/JunJul2026/SWIFT27_SDcard_JunJul2026/SWIFT27_SDcard_JunJul2026_L1.mat'
         '/Users/heffem3/Desktop/M2O2/SWIFTs/FullDatasets/AugSep2026_updated/SWIFT26_SDcard_AugSep2026/SWIFT26_SDcard_AugSep2026_L1.mat'
         '/Users/heffem3/Desktop/M2O2/SWIFTs/FullDatasets/AugSep2026_updated/SWIFT27_SDcard_AugSep2026/SWIFT27_SDcard_AugSep2026_L1.mat'
         '/Users/heffem3/Desktop/M2O2/SWIFTs/FullDatasets/SepOct2026/SWIFT27_SDcard_SepOct2026/SWIFT27_SDcard_SepOct2026_L1.mat'
         '/Users/heffem3/Desktop/M2O2/SWIFTs/FullDatasets/SepOct2026/SWIFT29_SDcard_SepOct2026/SWIFT29_SDcard_SepOct2026_L1.mat'};
clim_ms   = 0.5;    % color scale is -clim_ms to +clim_ms (m/s), same for all plots
gapFactor = 1.5;     % leave a blank gap where time spacing > gapFactor * median spacing
% ------------------------------------------------------------------

% colormap (Crameri package)
if exist('crameri','file')
    cmap = crameri('vik');
elseif exist('vik','file')
    cmap = vik;
else
    error('Could not find the crameri/vik colormap on your MATLAB path.');
end

comps  = {'east','north'};
labels = {'East velocity (m/s)','North velocity (m/s)'};
nc = numel(comps);

for f = 1:numel(files)
    if ~isfile(files{f})
        error('File not found: %s', files{f});
    end
    L = load(files{f}, 'SWIFT');
    S = L.SWIFT;
    N = numel(S);

    % sort by time
    [t, order] = sort([S.time]);
    S = S(order);

    % depth vector (median across profiles)
    nz = numel(S(1).signature.profile.z);
    Z = nan(nz, N);
    for k = 1:N
        Z(:,k) = S(k).signature.profile.z(:);
    end
    z = median(Z, 2, 'omitnan');

    % build velocity matrices (depth x time)
    V = cell(1,nc);
    for c = 1:nc
        M = nan(nz, N);
        for k = 1:N
            M(:,k) = S(k).signature.profile.(comps{c})(:);
        end
        V{c} = M;
    end

    % insert NaN columns at time gaps so pcolor does not stretch across them
    tp = t(:)';
    dtMed = median(diff(t));
    gaps = find(diff(t) > gapFactor*dtMed);
    for g = fliplr(gaps)
        tp = [tp(1:g), t(g)+dtMed, tp(g+1:end)];
        for c = 1:nc
            V{c} = [V{c}(:,1:g), nan(nz,1), V{c}(:,g+1:end)];
        end
    end
    tdt = datetime(tp, 'ConvertFrom', 'datenum');   % assumes SWIFT time is UTC datenum

    % figure title: "SWIFT <ID>: <months> <year>", parsed from the file name
    [~, fname, ext] = fileparts(files{f});
    id = S(1).ID;  if isnumeric(id), id = num2str(id); end
    tok = regexp([fname ext], '^SWIFT\d+_SDcard_([A-Za-z]+)(\d{4})_', 'tokens', 'once');
    if isempty(tok)
        warning('Could not parse months from "%s"; using the file name as the title.', fname);
        ttl = sprintf('SWIFT %s: %s', id, fname);
    else
        months = regexprep(tok{1}, '([a-z])([A-Z])', '$1-$2');   % AugSep -> Aug-Sep
        ttl = sprintf('SWIFT %s: %s %s', id, months, tok{2});
    end

    % plot
    fig = figure('Position',[100 100 1100 600], 'Name', ttl);
    tl = tiledlayout(fig, nc, 1, 'TileSpacing', 'compact');
    title(tl, ttl, 'FontWeight', 'bold');
    ax = gobjects(1,nc);
    for c = 1:nc
        ax(c) = nexttile(tl);
        h = pcolor(ax(c), tdt, z, V{c});
        set(h, 'EdgeColor', 'none');
        set(ax(c), 'YDir', 'reverse');            % surface at top
        colormap(ax(c), cmap);
        set(ax(c), 'CLim', [-clim_ms clim_ms]);   % fixed color scale for all plots

        cb = colorbar(ax(c));
        cb.Label.String = labels{c};
        ylabel(ax(c), 'Depth (m)');
    end
    linkaxes(ax, 'x');                            % zoom/pan both panels together
    xlim(ax(1), [tdt(1) tdt(end)]);
    xlabel(ax(nc), 'Date');

    % exportgraphics(fig, [ttl '.png'], 'Resolution', 200);   % uncomment to save
end