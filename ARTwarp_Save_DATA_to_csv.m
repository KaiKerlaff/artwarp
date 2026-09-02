function ARTwarp_Save_DATA_to_csv(filename, outputFileName)

% DATA structure must be present in filename
load(filename, "DATA");

% remove all fields except "name", "category" and "match"
DATA = rmfield(DATA, "contour");
DATA = rmfield(DATA, "folder");
DATA = rmfield(DATA, "ctrlength");
DATA = rmfield(DATA, "length");
DATA = rmfield(DATA, "tempres");
DATA = rmfield(DATA, "id");
DATA = rmfield(DATA, "parent_ids");

% convert the DATA struct to a table so we can use writetable 
dataTable = struct2table(DATA);

% Rename the "name" field to "contour_name" to match the ARTwarp-py
% category_assignments.csv convention. Leave the category and match field
% names unchanged.
dataTable.Properties.VariableNames = ["contour_name" "category" "match"];

% write the DATA table (without the removed fields) to .csv
writetable(dataTable, outputFileName);