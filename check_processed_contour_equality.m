for i = 1:50
    MATcont = readmatrix('MATcontour' + string(i) + '.txt');
    PYcont = readmatrix('C:\00-git-repos\artwarp-py\PYcontour' + string(i) + '.txt');
    if isequal(MATcont, PYcont)
        disp("contours " + string(i) + " are equal!" + " Length: " + string(length(MATcont)));
    else
        disp("contours " + string(i) + " differ and are different in length by " + string(length(PYcont)-length(MATcont)) + " points. Length MATcontour: " + string(length(MATcont)));
    end
end