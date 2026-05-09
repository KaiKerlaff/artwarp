% Define global variables NET and DATA for testing (needed to provide some
% 'dummy' data to plot
global NET DATA

% Populate required fields of NET and DATA with some 'dummy' data (only
% fields used by ARTwarp_Plot_Net2.m)

% reference contours [1,2,3,4,5]' and [1,0,0,0,0]'
weight = [1,1;2,0;3,0;4,0;5,0];
% number of categories = 2
numCategories = 2;
% number of datapoints of longest ref contour = 5
numFeatures = 5;
% initialise NET struct with the above field values
NET = struct('weight', {weight}, 'numCategories', {numCategories},...
    'numFeatures', {numFeatures});

% dummy contour names
name = {'ctr1','ctr2','ctr3','ctr4'};
% dummy contours
contour = {[1,2,3,4,5], [1,2,3,4,5], [1,2,3,4,5], [1,0,0,0,0]};
% categories these contours would have been placed in
category = {1, 1, 1, 2};
% and matches to these categories (all match=100 as these are just copies
% of the reference contours in NET.weight)
match = {100, 100, 100, 100};
% initialise DATA struct with the above field values
DATA = struct('category', category, 'name', name, 'match', match, 'contour',...
    contour);

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

% Run ARTwarp_Plot_Net2.m
ARTwarp_Plot_Net2

% Close the window
close(gcf)

% Clear all variables from workspace
clear