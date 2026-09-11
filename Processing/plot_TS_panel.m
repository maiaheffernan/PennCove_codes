%% plot TS panel function 


function plot_TS_panel(SP, t, p, castLon, castLat, DO, DO_clim, panelTitle)
% SP = practical salinity, t = in-situ temp, p = sea pressure (dbar)
% castLon/castLat = single lon/lat value for this cast (for GSW conversion)

hold on; box on;

% --- Convert to Absolute Salinity / Conservative Temperature ---
SA = gsw_SA_from_SP(SP, p, castLon, castLat);
CT = gsw_CT_from_t(SA, t, p);

% --- Background isopycnals (sigma0) ---
SA_grid = linspace(min(SA,[],'omitnan')-0.5, max(SA,[],'omitnan')+0.5, 200);
CT_grid = linspace(min(CT,[],'omitnan')-0.5, max(CT,[],'omitnan')+0.5, 200);
[SA_mesh, CT_mesh] = meshgrid(SA_grid, CT_grid);
sigma_mesh = gsw_sigma0(SA_mesh, CT_mesh);

sigma_levels = floor(min(sigma_mesh(:))):1.0:ceil(max(sigma_mesh(:)));

[c, h] = contour(SA_mesh, CT_mesh, sigma_mesh, sigma_levels, 'k-');
clabel(c, h, 'FontSize', 7);

% --- Scatter colored by DO, plotted in SA/CT space to match isopycnals ---
scatter(SA, CT, 60, DO, 'filled');
colormap(gca, cmocean('thermal'));
clim(DO_clim); 
cb = colorbar;
ylabel(cb, 'DO (mg/L)');

xlabel('Absolute Salinity (g/kg)');
ylabel('Conservative Temperature (\circC)');
title(panelTitle);

end