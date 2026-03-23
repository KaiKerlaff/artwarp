% Define global variable NET for testing (needed to format the figure in
% ARTwarp_Create_Figure.m
global NET

% Populate NET.maxNumCategories with some small value (the only field
% used by ARTwarp_Create_Figure.m)
maxNumCategories = 10;
NET = struct('maxNumCategories', {maxNumCategories});

% GENERATE 'dummy' FIGURE with 'ARTwarp' tag as in ARTwarp_csv.m
% Kept other properties the same as in ARTwarp_csv.m, but likely some of
% these do not need to be defined here for testing
h0 = figure('Units','normalized', ...
    'CloseRequestFcn','callback1', ...
    'Color',[0.752941176470588 0.752941176470588 0.752941176470588], ...
    'MenuBar','none', ...
    'Name','ART2 Neural Network', ...
    'NumberTitle','off', ...
    'PaperPosition',[18 180 576 432], ...
    'PaperUnits','points', ...
    'Position',[0 0.04036458333333333 1 0.8671875], ...
    'Tag','ARTwarp');

% Run ARTwarp_Create_Figure.m
ARTwarp_Create_Figure

% Close the window
close(gcf)

% Clear all variables from workspace
clear

