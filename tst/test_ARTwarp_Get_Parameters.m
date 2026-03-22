% Define global variables for testing (needed to display default values for
% uimenu objects, but cleared at the end of this script)
global warpFactorLevel vigilance bias learningRate maxNumCategories maxNumIterations sampleInterval resample

% Set warpFactorLevel to 3 by default
warpFactorLevel = 3;

% Load the rest of the default values from 'Default.mat'
load('../Default.mat')

% Run ARTwarp_Get_Parameters.m
ARTwarp_Get_Parameters

% Close the window
close(gcf)

% Clear all variables from workspace
clear