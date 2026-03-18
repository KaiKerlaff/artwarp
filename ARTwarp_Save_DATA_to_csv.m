function ARTwarp_Save_DATA_to_csv(filename)

% DATA structure must be present in filename
load(filename, "DATA");

% remove the 'contour' field: we don't want to copy the whole contour to
% .csv
DATA = rmfield(DATA, "contour");

% write the DATA structure (without the 'contour' field) to .csv
writetable(struct2table(DATA), "DATA.csv");