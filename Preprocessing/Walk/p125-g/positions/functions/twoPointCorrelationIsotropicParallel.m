%% Compute the isotropic two point correlation
%
% This function takes a grid and a list of spheres in 3D space and computes
% the two point correlation. 
%
% ASSUMPTIONS AND SIMPLIFICATIONS:
% 1) The shape is spheres
% 2) Isotropic system
% 3) Since the indicator outside of the spheres evaluate to zero, it is 
% assumed that the grid only includes points that lie inside of the 
% spheres.
%
% INPUTS:
% grid - the grid of points that lies inside of a sphere
% spheres - the list of spheres and radii
% N - the total number of grid points in each direction, both in and out of
%     the sphere
% lvlMax - how many levels away from the center do we want to go 
%    NOTE: you need to live inside the domain
% h - the grid spacing of the full grid
%
% OUTPUTS:
% Sr(:,1) - the "radius" of the two pt correlation
% Sr(:,2) - evaluation of the two pt corrlation

function Sr = twoPointCorrelationIsotropic(grid,spheres,Nv,lvlMax,h)
    Sr = zeros(lvlMax+1,2);
    wr = 6;
    N = prod(Nv);
    % Loop through R level
    parfor lvl=0:lvlMax
        idd=0;          % Initialize indicator
        dx = h*lvl;
        % Compute idd
        idd = idd + checkPoints_(grid+[dx 0 0],spheres);
        idd = idd + checkPoints_(grid-[dx 0 0],spheres);
        idd = idd + checkPoints_(grid+[0 dx 0],spheres);
        idd = idd + checkPoints_(grid-[0 dx 0],spheres);
        idd = idd + checkPoints_(grid+[0 0 dx],spheres);
        idd = idd + checkPoints_(grid-[0 0 dx],spheres);
        % Weigh and save info
        Sr(lvl+1,:) = [dx 1/(N*wr)*idd];
        %[wr srInd Sr2(srInd)]
    end
end

function idd = checkPoints_(pts,spheres)
    nSph = length(spheres(:,1));
    nPts = length(pts(:,1));
    check = zeros(nPts,1);
    % Loop through the spheres
    for i=1:nSph
        R = spheres(i,4);
        check = check | (sum((pts-spheres(i,1:3)).^2,2) < R^2);
    end
    idd = sum(check);
end

