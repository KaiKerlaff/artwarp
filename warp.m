function X = warp(u1, u2)

% DECLARE GLOBAL VARIABLES
global warpFactorLevel; % warpFactorLevel defines the maximum local compression factor allowed when warping u2 to match u1

% TEST FOR DIFFERENCES IN LENGTH GREATER THAN 3
m = length(u1); 
n = length(u2);
if max([m n])/(min([m n])-1) >= 3 % If the length of the contours differs by a factor of 3 or more:
    X = {0, []}; return; % return the similarity as 0 and the warping function as an empty array []
end

% DEFINE MATRICES
M = zeros(m, n); % point-wise similarity matrix, with dimensions (length(u1))x(length(u2))
N = NaN*zeros(m, n); % cumulative similarity matrix, with dimensions (length(u1))x(length(u2))
r1 = [0 1 0]; % This matrix is never used, but may have been included to represent the possible 'steps' to the previous index of u2 on the optimal warping path, when at the first index of u2
r2 = [-1 0 -2 -3]; % possible 'steps' to previous index of u2 on optimal warping path, when at 2nd or greater index of u2. -1 represents a diagonal step, 0 a vertical step, -2 a horizontal step of 2 and -3 a horizontal step of 3
p = zeros(m, n); % path matrix, storing the 'steps' to previous index of u2 on optimal warping path (chosen from matrix r2), with dimensions (length(u1))x(length(u2))
k = ones(m, n); % matrix storing 1 + the number of consecutive vertical steps taken on the optimal warping path, when at 2nd or greater index of u2. This represents the 'local compression factor' of u2 (i.e. how many indexes of u1 have already consecutively mapped to the same index of u2, in order to reach index (i,j) on the warping path). Note that k(i,j) is always greater than or equal to 1, and is moderated by the DTW constraint warpFactorLevel. k has dimensions (length(u1))x(length(u2))


% POPULATE POINT-WISE SIMILARITY MATRIX M
parfor i = 1:m % for each index in u1
    e1 = u1(i);
    for j = 1:n % and each index in u2
        e2 = u2(j);
        M(i,j) = min(e1,e2)/max(e1,e2)*100; % Calculate the point-wise similarity score as a percentage and store it at the corresponding index in M
    end
end



% PERFORM EARLY-STAGE ALIGNMENT
N(1,1) = M(1,1); % The first points in each contour are force-aligned to each other, and so the cumulative similarity at the first point on the warping path is just set equal to the point-wise similarity between the first points in each contour
k(1,1) = 1; % And, as the first points are by default linearly aligned, the local compression factor at the first point on the warping path is set to 1

for i = 2:min([11 m]) % i here represents the index of the reference contour u1. So, working forwards from the 2nd index of u1 to the 11th (or the last if u1 contains less than 12 indexes): 

    if round(i/3) <=1; % if the index of u1 is 4 or less (i.e we are allowed to consider the 1st index of u2, given a DTW constraint of warpFactorLevel = 3)
        j = 1; % j here represents the index of the active contour u2. So here, consider the 1st index of u2
        if k(i-1,j) > warpFactorLevel % if the local compression factor, at the index directly above the current index, is greater than warpFactorLevel (i.e we have already locally 'compressed' u2 by a factor of warpFactorLevel or more):
            y = NaN; % Then the warping constraints have been broken on this path and so the path should end. Signify this by assigning NaN to the value to add to the cumulative similarity matrix N at position N(i,j), as this will set N(i,j) to NaN. POTENTIAL TO BE SOURCE OF ISSUE #67 (where warpFactorLevel = 2) GIVEN THAT WE ARE STILL ALLOWED TO CONSIDER THE 1st INDEX EVEN WHEN i = 4, so k(i-1,j) COULD BE 3 AFTER TWO CONSECUTIVE VERTICAL STEPS?
        else % if the local compression factor, at the index directly above the current index, is less than or equal to warpFactorLevel (i.e we are still within the local compression factor limit of warpFactorLevel):
            y = N(i-1,j); % Then the maximum cumulative similarity score at this index, y, can only be obtained by a vertical step from the previous index on the path - as a diagonal or horizontal step would imply mapping an index of u2 to a non-existent index of u1 (i.e an index of u1 before the 1st index)
        end
        k(i,j) = 1+k(i-1,j); % update the k matrix to show that the local compression factor at this index has increased by 1 from the previous index on the path (as we have either ended the path, or taken a vertical step)
        N(i,j) = M(i,j)+y; % update the cumulative similarity matrix to show the cumulative similarity at (i,j) (i.e the chosen maximum previous cumulative similarity y + the existing similarity score at (i,j))
        p(i,j) = 0; % update the path matrix to show the step from (i,j) to the chosen previous index, along the optimal warping path for (i,j). Here this step is 0, signifying a vertical step
    end
    if round(i/3) <=2; % if the index of u1 is 7 or less (i.e we are allowed to consider the 2nd index of u2, given a DTW constraint of warpFactorLevel = 3)
        j = 2; % consider the 2nd index of u2
        if k(i-1,j) >= warpFactorLevel % if the local compression factor, at the index directly above the current index, is greater than or equal to warpFactorLevel (i.e we have already locally 'compressed' u2 by a factor of warpFactorLevel or more):
            y = N(i-1,j-1); % then the maximum cumulative similarity score at this index, y, can only be obtained by a diagonal step (as a further vertical step would imply breaking the maximum local compression limit warpFactorLevel, and a horizontal step would imply mapping an index of u2 to a non-existent index of u1 (i.e an index of u1 before the 1st index)
            x = 1; % so set x = 1, to later assign the value r2(1) = -1 to the path matrix p, to represent a diagonal step
        else % if the local compression factor, at the index directly above the current index, is less than warpFactorLevel (i.e we are still within the local compression factor limit of warpFactorLevel):
            [y x] = max([N(i-1,j-1) N(i-1,j)]); % then the maximum cumulative similarity score, y, can be obtained from either a diagonal or a vertical step (as again, a horizontal step would imply mapping an index of u2 to a non-existent index of u1). So, obtain the maximum cumulative similarity score from these two possible previous steps. Also note the direction of the step with the maximum score, using the variable x. This determines the value later assigned to the path matrix p (-1 for a diagonal step or 0 for a vertical step)
        end
        ks = [1 1+k(i-1,j)]; % the local compression factor at this index will now be set to either 1 (a linear alignment, corresponding to a diagonal step) or 1+the local compression factor at the index directly above (a local compression factor increase of 1, corresponding to a vertical step)
        k(i,j) = ks(x); % update the local compression matrix to show the local compression factor at index (i,j), by choosing from the options in the ks matrix
        N(i,j) = M(i,j)+y; % update the cumulative similarity matrix to show the cumulative similarity at (i,j) (i.e the chosen maximum previous cumulative similarity y + the existing similarity score at (i,j))
        p(i,j) = r2(x); % update the path matrix to show the step from (i,j) to the chosen previous index, along the optimal warping path for (i,j)
    end
    if round(i/3) <=3; % if the index of u1 is 10 or less (i.e we are allowed to consider the 3rd index of u2, given a DTW constraint of warpFactorLevel = 3)
        j = 3; % consider the 3rd index of u2
        if k(i-1,j) >= warpFactorLevel % if the local compression factor, at the index directly above the current index, is greater than or equal to warpFactorLevel (i.e we have already locally 'compressed' u2 by a factor of warpFactorLevel or more):
            [y x] = max([N(i-1,j-1) NaN N(i-1, j-2)]); % then the maximum cumulative similarity score at this index, y, can only be obtained by a diagonal step or a horizontal step of 2 (as a further vertical step would imply breaking the maximum local compression limit warpFactorLevel, and a horizontal step of 3 would imply mapping an index of u2 to a non-existent index of u1 (i.e an index of u1 before the 1st index)
        else % if the local compression factor, at the index directly above the current index, is less than warpFactorLevel (i.e we are still within the local compression factor limit of warpFactorLevel):
            [y x] = max([N(i-1,j-1) N(i-1,j) N(i-1, j-2)]); % then the maximum cumulative similarity score, y, can be obtained from either a diagonal, a vertical step or a horizontal step of 2 (as again, a horizontal step of 3 would imply mapping an index of u2 to a non-existent index of u1). So, obtain the maximum cumulative similarity score from these three possible previous steps. Also note the direction of the step with the maximum score, using the variable x. This determines the value later assigned to the path matrix p (-1 for a diagonal step, 0 for a vertical step or -2 for a horizontal step of 2)
        end
        ks = [1 1+k(i-1,j) 1]; % the local compression factor at this index will now be set to either 1 (a linear alignment, corresponding to a diagonal step or a horizontal step) or 1+the local compression factor at the index directly above (a local compression factor increase of 1, corresponding to a vertical step)
        k(i,j) = ks(x); % update the local compression matrix to show the local compression factor at index (i,j), by choosing from the options in the ks matrix
        N(i,j) = M(i,j)+y; % update the cumulative similarity matrix to show the cumulative similarity at (i,j) (i.e the chosen maximum previous cumulative similarity y + the existing similarity score at (i,j))
        p(i,j) = r2(x); % update the path matrix to show the step from (i,j) to the chosen previous index, along the optimal warping path for (i,j)
    end
    for j = 4:min([3*i round((i-m)/3+n)]) % For the rest of the indexes of u2, from 4 (as this is always allowed to be considered for a range of i indexes between 1 and 12 (as 12/4=3)) to the maximum value determined by the maximum sides of the itakura parallelogram DTW band (bound by the lines i = j/3 and i = 3j - 3n + m):
        if k(i-1,j) >= warpFactorLevel % if the local compression factor, at the index directly above the current index, is greater than or equal to warpFactorLevel (i.e we have already locally 'compressed' u2 by a factor of warpFactorLevel or more):
            [y x] = max([N(i-1,j-1) NaN N(i-1, j-2) N(i-1, j-3)]); % then the maximum cumulative similarity score at this index, y, can only be obtained by a diagonal step, a horizontal step of 2, or a horizontal step of 3 (as a further vertical step would imply breaking the maximum local compression limit warpFactorLevel
        else % if the local compression factor, at the index directly above the current index, is less than warpFactorLevel (i.e we are still within the local compression factor limit of warpFactorLevel):
            [y x] = max([N(i-1,j-1) N(i-1,j) N(i-1, j-2) N(i-1, j-3)]); % then the maximum cumulative similarity score, y, can be obtained from either a diagonal step, a vertical step, a horizontal step of 2 or a horizontal step of 3 (i.e the full range of choices allowed using a DTW constraint of warpFactorLevel=3). So, obtain the maximum cumulative similarity score from these four possible previous steps. Also note the direction of the step with the maximum score, using the variable x. This determines the value later assigned to the path matrix p (-1 for a diagonal step, 0 for a vertical step, -2 for a horizontal step of 2 or -3 for a horizontal step of 3)
        end
        ks = [1 1+k(i-1,j) 1 1]; % the local compression factor at this index will now be set to either 1 (a linear alignment, corresponding to a diagonal step or a horizontal step) or 1+the local compression factor at the index directly above (a local compression factor increase of 1, corresponding to a vertical step)
        k(i,j) = ks(x); % update the local compression matrix to show the local compression factor at index (i,j), by choosing from the options in the ks matrix
        N(i,j) = M(i,j)+y; % update the cumulative similarity matrix to show the cumulative similarity at (i,j) (i.e the chosen maximum previous cumulative similarity y + the existing similarity score at (i,j))
        p(i,j) = r2(x); % update the path matrix to show the step from (i,j) to the chosen previous index, along the optimal warping path for (i,j)
    end    
end

% PERFORM GENERAL-STAGE ALIGNMENT
for i = 12:1:m % i here represents the index of the reference contour u1. So, working forwards from the 12th index of u1 to the last:

    for j = max([round(i/3) (i-m)*3+n]):min([3*i round((i-m)/3+n)]) % j here represents the index of the active contour u2. The range of j is constrained to the Itakura parallelogram-shaped DTW 'band'. Note that this band consists of the locus of points bound by the lines i = 3j, i = j/3 - n/3 + m, i = j/3, and i = 3j - 3n + m. The first two equations represent the starting values to consider for j, and the second two equations represent the ending values to consider for j. This ensures a releatively regular warping path, with greater possibilites for warping in the centres of the contours, and always ending with the final points of each contour being aligned to each other

        if k(i-1,j) >= warpFactorLevel % if the local compression factor, at the index directly above the current index, is greater than or equal to warpFactorLevel (i.e we have already locally 'compressed' u2 by a factor of warpFactorLevel or more):

            y = max(max(N(i-1,j-1), NaN), max(N(i-1, j-2), N(i-1, j-3))); % then the only possible 'steps' to the previous index on the optimal warping path are diagonal (to the (i-1, j-1) position) or 'horizontal' (to the (i-1, j-2) or (i-1, j-3) positions) - as a further vertical step would break the maximum local compression limit of warpFactorLevel. Note here that we denote a vertical 'step' as a 'step' between rows in the same column of the N matrix, as this corresponds to a 'compression' warping of the u2 active contour (i.e mapping the same index of u2 to multiple indexes of u1). So find the maximum cumulative similarity score, y, choosing from these possible previous indexes

            ks = 1; % also, if we have reached the maximum local compression limit (and hence the next step cannot be vertical), then the local compression factor at the current index should be reset to 1

            % find which previous index has the maximum cumulative similarity along its optimal warping path
            if y == N(i-1,j-1) % check the diagonal step first, corresponding to a linear warping (no local compression or expansion)
                x = 1; % If the index at this step gives the maximum cumulative similarity, assign the value r2(1) = -1 to the path matrix p, to represent a diagonal step
            elseif isnan(y) % otherwise, check the vertical step, corresponding to a compression warping. Note that this condition should never be met (as NaN will never be assigned to y in this loop), but is likely present for safety reasons.
                x = 2; % if the index at this step gives the maximum cumulative similarity, assign the value r2(2) = 0 to the path matrix p, to represent a vertical step
                ks = 1 + k(i-1,j); % and update the k matrix to show that the local compression factor at this index has increased by 1 from the previous index on the path
            elseif y == N(i-1, j - 2) % otherwise, check the 'horizontal' step of 2, corresponding to an expansion warping of factor 2
                x = 3; % If the index at this step gives the maximum cumulative similarity, assign the value r2(3) = -2 to the path matrix p, to represent a horizontal step of 2
            elseif y == N(i-1, j -3) % otherwise, check the 'horizontal' step of 3, corresponding to an expansion warping of factor 3
                x = 4; % If the index at this step gives the maximum cumulative similarity, assign the value r2(4) = -3 to the path matrix p, to represent a horizontal step of 3 
            end

        else % if the local compression factor, at the index directly above the current index, is less than warpFactorLevel (i.e we are still within the local compression factor limit of warpFactorLevel:
            y = max(max(N(i-1,j-1), N(i-1,j)), max(N(i-1, j-2), N(i-1, j-3))); % then the possible 'steps' to the previous index on the optimal warping path include the diagonal (to the (i-1, j-1) position), vertical (to the (i-1, j) position) or 'horizontal' (to the (i-1, j-2) or (i-1, j-3) positions). So find the maximum cumulative similarity score, y, choosing from these possible previous indexes

            ks = 1; % initialise the local compression factor at this index as 1 - this saves repeating code, as the local compression factor will be 1 if any step other than a vertical step is taken.

            if y == N(i-1,j-1) % check the diagonal step first, corresponding to a linear warping (no local compression or expansion)
                x = 1; % If the index at this step gives the maximum cumulative similarity, assign the value r2(1) = -1 to the path matrix p, to represent a diagonal step
            elseif y == N(i-1,j) % otherwise, check the vertical step, corresponding to a compression warping
                x = 2; % if the index at this step gives the maximum cumulative similarity, assign the value r2(2) = 0 to the path matrix p, to represent a vertical step
                ks = 1 + k(i-1,j); % and update the k matrix to show that the local compression factor at this index has increased by 1 from the previous index on the path
            elseif y == N(i-1, j - 2) % otherwise, check the 'horizontal' step of 2, corresponding to an expansion warping of factor 2
                x = 3; % If the index at this step gives the maximum cumulative similarity, assign the value r2(3) = -2 to the path matrix p, to represent a horizontal step of 2
            elseif y == N(i-1, j -3) % otherwise, check the 'horizontal' step of 3, corresponding to an expansion warping of factor 3
                x = 4; % If the index at this step gives the maximum cumulative similarity, assign the value r2(4) = -3 to the path matrix p, to represent a horizontal step of 3 
            end
        end

        % update matrices with the warping path information for index (i,j)
        k(i,j) = ks; % update the local compression matrix to show the local compression factor at index (i,j)
        N(i,j) = M(i,j)+y; % update the cumulative similarity matrix to show the cumulative similarity at (i,j) (i.e the chosen maximum previous cumulative similarity + the existing similarity score at (i,j))
        p(i,j) = r2(x); % update the path matrix to show the step from (i,j) to the chosen previous index, along the optimal warping path for (i,j)
    end
end

% RETRACE PATH TO GET WARPING FUNCTION
j = n; % j here represents the index of u2 whose value most closely matches the value at the i'th index of u1, within DTW constraints. Since we will be working backwards through the indexes of u1 (by decreasing i), we note that the value at the final index of u1 will be most closely matched by the value at the final index of u2; and the final index of u2 is n. So j is initially set to n.  
for i = m:-1:1 % i here represents the index of the reference contour u1. So, working backwards from the last index of u1 to the first:
    warpfun(i)=j; % set the i'th index of the warpfunction to j. This represents that the j'th index of u2 should be used to most closely match the value at the i'th index of u1, within DTW constraints (remembering that u2(warpfun) gives the warped active contour to most closely match the reference contour u1)
    dj = p(i,j); % from the path matrix p, obtain the 'step', dj, to the previous index of u2 on the optimal warping path
    j = j+dj; % 'step' to this previous index, so that j now represents the index of u2 whose value most closely matches the value at the (i-1)'th index of u1... before i is decremented when the 'for' loop repeats.
end

% PLOT OUTPUT - THESE LINES APPEAR TO BE FOR TESTING PURPOSES ONLY
% plot(u1, 'b');
% hold on
% plot(u2, 'g');
% plot(u2(warpfun), 'r');
drawnow

% CALCULATE AVERAGE POINT-WISE SIMILARITY ALONG OPTIMAL WARPING PATH
D = N(m, n)/length(warpfun); % Obtain the normalised similarity by dividing the total similarity along the optimal warping path, by the length of the warping function

% RETURN RESULTS
X = {D, warpfun}; % Return a 1x2 cell array, containing the normalised point-wise similarity in cell {1,1} and the warping function in cell {1,2}

% CLEAR VARIABLES FROM WORKSPACE
clear N M p; % this line is not entirely necessary as these variables are local to the function, so will be cleared automatically when the function ends. 

end