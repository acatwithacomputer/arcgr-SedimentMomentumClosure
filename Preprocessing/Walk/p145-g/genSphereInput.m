close all
clear all

data = readmatrix('p145.csv');
grid = data(:,1:3);
r = data(:,4);
n = length(r);
atomIndex=1:n;
v = 10.0*(rand(n,3)-.5);

fileID = fopen('./DEM/in.poly1','w');
fprintf(fileID,'create_atoms 1 single %2.6f %2.6f %2.6f units box \r\n',grid');
fprintf(fileID,'set atom %i diameter %2.6f density ${rhos} vx %2.6f vy %2.6f vz %2.6f \r\n',[atomIndex' 2*r v]');
fclose(fileID);

fprintf('Sphere generation done. \r\n')