function ARTwarp_Run_and_Save_Category_Assignments(inputFolder, warpFactorLevel, vigilance, maxNumCategories, maxNumIterations, outputFolder)

% Load ccontours and run categorisation using the specified parameters
ARTwarp_cli_mode(inputFolder, warpFactorLevel, vigilance, maxNumCategories, maxNumIterations, 'randomiseSortOrder', 0, 'outputFolder', outputFolder)

% Find the final (converged) output file using the format used in
% ARTwarp_Run_Categorisation.m
formatSpec = 'ARTwarp%02.0fFINAL';
endname = sprintf(formatSpec,vigilance);
outputFile = fullfile(outputFolder, endname);

% Save contour names, categories and matches to .csv in the same folder as
% the output file
ARTwarp_Save_DATA_to_csv(outputFile, fullfile(outputFolder, "MATLAB_category_assignments.csv"))