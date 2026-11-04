clear all
close all

refdata = readmatrix("../../walkIC/p125w-Box.csv");

found = false;
i=0;
while ~found
    data = readmatrix(sprintf("pts-%i.csv",i));
    checkData = sum((data(1,:)-refdata(1,:)).^2)
    if checkData < 1e-3
        found = true;
    else
        i=i+1;
    end
end

i