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
% N - the total number of grid points, both in and out of the sphere
% lvlMax - how many levels away from the center do we want to go 
%    NOTE: you need to live inside the domain
% h - the grid spacing of the full grid
%
% OUTPUTS:
% Sr(:,1) - the "radius" of the two pt correlation
% Sr(:,2) - evaluation of the two pt corrlation

function Sr = twoPointCorrelationAnisotropicParallel(grid,spheres,N,lvlMax,h)
    Sr = zeros(lvlMax+1,4);
    wr = 2;     % Number of pts in stencil
    SrWeight = 1./(N*wr);
    % Loop through R level
    parfor lvl=0:lvlMax
        iddx=0; iddy=0; iddz=0;    % Initialize indicator
        dx = h*lvl;
        % Compute idd
        iddx = iddx + checkPoints_(grid+[dx 0 0],spheres);
        iddx = iddx + checkPoints_(grid-[dx 0 0],spheres);
        iddy = iddy + checkPoints_(grid+[0 dx 0],spheres);
        iddy = iddy + checkPoints_(grid-[0 dx 0],spheres);
        iddz = iddz + checkPoints_(grid+[0 0 dx],spheres);
        iddz = iddz + checkPoints_(grid-[0 0 dx],spheres);
        % Weigh and save info
        Sr_ = [dx 0 0 0];
        Sr_(2:4) = SrWeight.*[iddx iddy iddz];
        Sr(lvl+1,:) = Sr_;
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

