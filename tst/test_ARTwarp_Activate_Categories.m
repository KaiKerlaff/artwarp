% Define a global variable warpFactorLevel for testing (needed for the
% warp.m function to run, but cleared at the end of this script)
global warpFactorLevel;
warpFactorLevel = 3;

% Define an input contour and a weights matrix (containing 2 reference
% contours) for testing. The first ref contour is [1,2,3,4,5]'=input and
% the second is [1,0,0,0,0]
input = [1;2;3;4;5];
weight = [1,1;2,0;3,0;4,0;5,0];
bias = 0.000001;

% Try providing ARTwarp_Activate_Categories.m only 2 parameters, and check
% an error is thrown.
try
    categoryAct = ARTwarp_Activate_Categories(input);
    error("ARTwarp_Activate_Categories accepted incorrect number of input parameters")
% If the error is correctly thrown, then run ARTwarp_Activate_Categories on
% input, weight and bias.
catch
    categoryAct = ARTwarp_Activate_Categories(input, weight, bias);

    % assert that the first reference contour reults in an activation value
    % of 100% * bias, and a warping function of [1,2,3,4,5] (linear warping)
    assert(categoryAct{1,1}(1,1) == 100*(1-bias))
    assert(sum(categoryAct{2,1} == [1,2,3,4,5]) == 5)

    % assert that the second reference contour reults in an activation value
    % of 0, and a warping function of [] (indicating warping was not possible)
    % due to lengths differing by a factor >= 3.
    assert(categoryAct{1,1}(1,2) == 0)
    assert(isempty(categoryAct{2,2}))
end

% Clear global variable warpFactorLevel and all local variables
clear;