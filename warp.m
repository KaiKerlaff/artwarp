function X = warp(u1, u2)

% This algorithm determines a warping function to maximise the similarity score 
% of two frequency contours. The algorithm is similar to that of Itakura (1975).
% The maximum number of consecutive vertical steps (2 in Itakura 1975) is 
% 'warpFactorLevel' in this version (determined by variable 'warpFactorLevel'). 
% The function also allows horizontal jumps of 'warpFactorLevel' rather than 2. 
% The function yields an array that contains the normalised cumulative 
% similarity score between the original and the warped contour in cell {1,1}, 
% as well as the warping function in cell {1,2}.


% DECLARE GLOBAL VARIABLES
global warpFactorLevel; % maximum local warping factor


% TEST FOR DIFFERENCES IN LENGTH GREATER THAN WARPFACTORLEVEL
m = length(u1); % the number of data points in the reference contour
n = length(u2); % the number of data points in the comparison contour
if max([m n])/(min([m n])-1) >= warpFactorLevel
    %disp('The length of the two contours differs by more than a factor of warpFactorLevel');
    X = {0, []}; return; 
end


% DEFINE MATRICES
% POINT-WISE SIMILARITY MATRIX: dimensions mxn, initially populated with all
% zeroes. Stores the direct point-wise similarity between u1 and u2
M = zeros(m, n);

% CUMULATIVE SIMILARITY MATRIX: dimensions mxn, initially populated with all 
% NaN. Stores cumulative similarity along the optimal warping path (calculated
% from M)
N = NaN*zeros(m, n);

% Legacy array, superceded by r2. TODO: remove this array?
r1 = [0 1 0];

% POSSIBLE HORIZONTAL STEPS MATRIX: dimensions 1x(warpFactorLevel + 1), kept
% constant throughout the program and populated with values of 0 to 
% -warpFactorLevel. Stores possible steps in the j-direction
r2 = 0:-1:-warpFactorLevel;

% PATH MATRIX: dimensions mxn, initially populated with all zeroes. Stores the
% horizontal step to the previous index on the optimal warping path
p = zeros(m, n);

% LOCAL EXPANSION FACTOR MATRIX: dimensions mxn, initially populated with all
% ones to indicate no initial expansion. Stores the local expansion factor at 
% each index
k = ones(m, n);


% POPULATE POINT-WISE SIMILARITY MATRIX M
% For every index in u1 and u2, calculate the point-wise similarity score as a
% percentage and store it at the corresponding index in M
parfor i = 1:m
    e1 = u1(i);
    for j = 1:n
        e2 = u2(j);
        M(i,j) = min(e1,e2)/max(e1,e2)*100;
    end
end


% CALCULATE CUMULATIVE SIMILARITY MATRIX N
% The cumulative similarity at (1,1) will always just be the point-wise
% similarity between the first points of each contour
N(1,1) = M(1,1);

% The local expansion at (1,1) is linear, i.e. an expansion of factor 1
k(1,1) = 1;

% PERFORM EARLY STAGE ALIGNMENT
% For the indexes in u1 where if maximum local compression was applied, there
% is a possibility that the warping path would include a step to a non-existent
% (<1) index of u2:
for i = 2:min([(warpFactorLevel*(warpFactorLevel + 1) - 1) m])
    % For each possible early-stage maximum local compression from 1 to
    % warpFactorLevel:
    for z = 1:warpFactorLevel
        % If we are allowed to consider the z'th index of u2 without 
        % breaking the dynamic time warping limit:
        if round(i/warpFactorLevel) <= z
            % Consider the z'th index of u2
            j = z;

            % If we are considering the 1st index of u2, we are allowed to
            % make a (warpFactorLevel + 1)'th consecutive vertical step.
            % So, the condition to disqualify a further vertical step is
            % given as below. This is from legacy code. TODO - check
            % that this is still correct logic
            if z == 1
                condition = (k(i-1,j) > warpFactorLevel);
            
            % Otherwise, the condition to disqualify a further vertical
            % step is given as below (i.e. the number of vertical steps
            % taken at the index directly above is >= warpFactorLevel)
            else
                condition = (k(i-1,j) >= warpFactorLevel);
            end

            % If the condition is met:
            if condition
                % Disqualify the vertical step (i.e. choose the maximum 
                % previous value for the path from only a diagonal or horizontal 
                % step)
                [y, x] = max([N(i-1,j+(r2(2:z))) NaN]);
                % Update the path matrix to show the horizontal component of
                % the step taken (i.e. -1, -2, ..., -warpFactorLevel)
                p(i,j) = r2(x+1);
                % Reset the number of consecutive vertical steps to 1
                k(i,j) = 1;
            
            % Otherwise, if the condition is not met:
            else
                % Choose the maximum previous value from any
                % previous possible step (including the vertical)
                [y, x] = max(N(i-1,j+(r2(1:z))));
                % If the maximum previous value came from a vertical step:
                if x == 1
                    % increment the number of consecutive vertical steps taken
                    % at k(i,j) from k(i-1,j)
                    k(i,j) = 1+k(i-1,j);
                
                % Otherwise, if the maximum previous value came from a vertical
                % or horizontal step:
                else
                    % Reset the number of consecutive vertical steps to 1
                    k(i,j) = 1;
                end
                % Update the path matrix to show the horizontal component of
                % the step taken (i.e. 0, -1, ..., -warpFactorLevel)
                p(i,j) = r2(x);
            end
            % Adjust the value of N(i,j) to equal M(i,j) plus the chosen
            % maximum previous cumulative similarity
            N(i,j) = M(i,j)+y;
        end
    end

    % For the rest of the indexes in u2, for which maximum local compression
    % can now safely be applied, instead contrain the allowed compression
    % steps (i.e. steps in the j direction) to within the bounds of the 
    % Itakura parallelogram with sides of gradient warpFactorLevel and 
    % 1/warpFactorLevel:
    for j = (warpFactorLevel + 1):min([warpFactorLevel*i round((i-m)/warpFactorLevel+n)])
        % If the value at k(i-1,j) is greater than or equal to
        % warpFactorLevel:
        if k(i-1,j) >= warpFactorLevel
            % Disqualify the vertical step
            [y, x] = max([N(i-1,j+(r2(2:warpFactorLevel+1))) NaN]);
            % Update the path matrix to show the horizontal component of the
            % step taken (i.e. -1, -2, ..., -warpFactorLevel)
            p(i,j) = r2(x+1);
            % Reset the number of consecutive vertical steps to 1
            k(i,j) = 1;

        % Otherwise, if we have not yet reached the maximum consecutive
        % vertical steps:
        else
            % Choose the maximum previous value from any previous
            % possible step (including the vertical)
            [y, x] = max(N(i-1,j+r2));
            % If the maximum previous value came from a vertical step:
            if x == 1
                % Increment the number of consecutive vertical steps taken at
                % k(i,j) from k(i-1,j)
                k(i,j) = 1+k(i-1,j);
            
            % Otherwise, if the maximum previous value came from a horizontal
            % or diagonal step:
            else
                % Reset the number of consecutive vertical steps to 1
                k(i,j) = 1;
            end
            % Update the path matrix to show the horizontal component of the
            % step taken (i.e. 0, -1, ..., -warpFactorLevel)
            p(i,j) = r2(x);
        end
        % Adjust the value of N(i,j) to equal M(i,j) plus the chosen maximum
        % previous cumulative similarity
        N(i,j) = M(i,j)+y;
    end    
end


% PERFORM GENERAL STAGE ALIGNMENT
% For the rest of the indexes in u1 (where there is no possibility of warping
% to a non-existent index of u2):
for i = warpFactorLevel*(warpFactorLevel+1):1:m
    % For the indexes of u2 within the Itakura parallelogram bounds for this
    % index i of u1:
    for j = max([round(i/warpFactorLevel) (i-m)*warpFactorLevel+n]):min([warpFactorLevel*i round((i-m)/warpFactorLevel+n)])

        % If the value at k(i-1,j) is greater than or equal to
        % warpFactorLevel:
        if k(i-1,j) >= warpFactorLevel
            % Disqualify the vertical step
            [y, x] = max([N(i-1,j+(r2(2:warpFactorLevel+1))) NaN]);
            % Update the path matrix to show the horizontal component of the
            % step taken (i.e. -1, -2, ..., -warpFactorLevel)
            p(i,j) = r2(x+1);
            % Reset the number of consecutive vertical steps to 1
            k(i,j) = 1;
        
        % Otherwise, if we have not yet reached the maximum consecutive
        % vertical steps:
        else
            %choose the maximum previous value from any previous
            % possible step (including the vertical)
            [y, x] = max(N(i-1,j+r2));
            % If the maximum previous value came from a vertical step:
            if x == 1
                % Increment the number of consecutive vertical steps taken at
                % k(i,j) from k(i-1,j)
                k(i,j) = 1+k(i-1,j);
            
            % Otherwise, if the maximum previous value came from a horizontal
            % or diagonal step:
            else
                % Reset the number of consecutive vertical steps to 1
                k(i,j) = 1;
            end
            % Update the path matrix to show the horizontal component of the
            % step taken (i.e. 0, -1, ..., -warpFactorLevel)
            p(i,j) = r2(x);
        end
        % Adjust the value of N(i,j) to equal M(i,j) plus the chosen maximum
        % previous cumulative similarity
        N(i,j) = M(i,j)+y;
    end
end

% RETRACE PATH TO GET WARPING FUNCTION
% j here represents the index of u2 whose value most closely matches the value
% at the i'th index of u1, within DTW constraints. Since we will be working
% backwards through the indexes of u1 (by decreasing i), we note that the
% value at the final index of u1 will be most closely matched by the value at
% the final index of u2; and the final index of u2 is n. So j is initially
% set to n.
j = n;

% i here represents the index of the reference contour u1. So, working
% backwards from the last index of u1 to the first:
for i = m:-1:1
    % Set the i'th index of the warpfunction to j. This represents that the
    % j'th index of u2 should be used to most closely match the value at the
    % i'th index of u1, within DTW constraints (remembering that u2(warpfun)
    % gives the warped active contour to most closely match the reference
    % contour u1)
    warpfun(i)=j;
    % From the path matrix p, obtain the 'step', dj, to the previous index of
    % u2 on the optimal warping path
    dj = p(i,j);
    % 'Step' to this previous index, so that j now represents the index of u2
    % whose value most closely matches the value at the (i-1)'th index of u1,
    % before i is decremented when the 'for' loop repeats.
    j = j+dj;
end

% PLOT OUTPUT - THESE LINES APPEAR TO BE FOR TESTING PURPOSES ONLY
% plot(u1, 'b');
% hold on
% plot(u2, 'g');
% plot(u2(warpfun), 'r');
drawnow

% CALCULATE AVERAGE POINT-WISE SIMILARITY ALONG OPTIMAL WARPING PATH
% Obtain the normalised similarity by dividing the total similarity along the
% optimal warping path, by the length of the warping function
D = N(m, n)/length(warpfun);

% RETURN RESULTS
% Return a 1x2 cell array, containing the normalised point-wise similarity in
% cell {1,1} and the warping function in cell {1,2}
X = {D, warpfun};

% CLEAR VARIABLES FROM WORKSPACE
% This line is not entirely necessary as these variables are local to the
% function, so will be cleared automatically when the function ends.
clear N M p;

end