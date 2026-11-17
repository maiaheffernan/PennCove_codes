%% Turquoise colormap: white -> turquoise -> dark teal

% I am writing this script to show Mike the Claude/VS code/matlab workflow 


% Number of colors in the colormap
n = 300;

% Anchor colors (RGB, scaled 0-1)
white     = [1.00 1.00 1.00];
turquoise = [0.25 0.88 0.82];   % classic turquoise (64, 224, 208)
darkTeal  = [0.00 0.30 0.30];   % dark teal (0, 77, 77)

% Positions of the anchor colors along the colormap (0 = start, 1 = end)
anchorPos    = [0 0.5 1];
anchorColors = [white; turquoise; darkTeal];

% Interpolate R, G, and B separately to get n smooth steps
x = linspace(0, 1, n)';
turqMap = interp1(anchorPos, anchorColors, x);

% Preview the colormap
figure;
imagesc(peaks(200));
colormap(turqMap);
colorbar;
axis image;
title('Turquoise colormap: white \rightarrow dark teal');
