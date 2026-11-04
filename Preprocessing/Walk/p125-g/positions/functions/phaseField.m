%% Function that creates the phase field %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ASSUMPTIONS:
% - Fully periodic domain
% - Spheres
%
% INPUTS:
% h          : desired spacing
% sphereList : list of spheres
% Lx, Ly, Lz : size of the simulation domain
%
% OUTPUTS:
% N             : number of grid points in each direction of the domain
% coords        : points of the grid that lie in the spheres
% perSphereList : periodic extension of the sphere list
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [N,coords,perSphereList] = phaseField(h,sphereList,Lx,Ly,Lz)
    % Create coordinate box containing spheres
    % Find bounds of the box containing the spheres but still in the domain
    maxcoords = min([Lx Ly Lz], max(sphereList(:,1:3)+sphereList(:,4)));
    mincoords = max([ 0  0  0], min(sphereList(:,1:3)-sphereList(:,4)));
    % Create the base grid
    xbase=mincoords(1):h:maxcoords(1); %-15.5:15.5;
    ybase=mincoords(2):h:maxcoords(2);
    zbase=mincoords(3):h:maxcoords(3);
    [x,y,z]=meshgrid(xbase,ybase,zbase);
    % Make into one giant list of points
    dim = length(xbase)*length(ybase)*length(zbase);
    coords_ = [reshape(x,[dim 1]) reshape(y,[dim 1]) reshape(z,[dim 1])];

    % Create phase field from spheres
    % Find number of spheres
    nSph = length(sphereList(:,1));
    % Initiate phase field as a sparse matrix to save space
    pF = sparse(length(coords_(:,1)),1);
    for i=1:nSph
        R = sphereList(i,4);
        ppt = sphereList(i,1:3);
        pF = pF | sparse(sum((coords_-ppt).^2,2) < (R^2));
    end
    % Get the points in the solid phase
    coords = coords_(pF,:);

    % Make periodic spheres    
    perSphereList = zeros(27*nSph,4);
    % Make base layer with just x coord displacement
    perSphereList(0*nSph+1:1*nSph,:) = sphereList + [-Lx -Ly -Lz 0];
    perSphereList(1*nSph+1:2*nSph,:) = sphereList + [  0 -Ly -Lz 0];
    perSphereList(2*nSph+1:3*nSph,:) = sphereList + [ Lx -Ly -Lz 0];
    % Repeat for y coord displacement = 0
    perSphereList(3*nSph+1:6*nSph,:) = perSphereList(1:3*nSph,:) + [0 Ly 0 0];
    % Repeat for y coord displacement = Ly
    perSphereList(6*nSph+1:9*nSph,:) = perSphereList(1:3*nSph,:) + [0 2*Ly 0 0];
    % Repeat for z coord displacement = 0
    perSphereList(9*nSph+1:18*nSph,:) = perSphereList(1:9*nSph,:) + [0 0 Lz 0];
    % Repeat for z coord displacement = Lz
    perSphereList(18*nSph+1:27*nSph,:) = perSphereList(1:9*nSph,:) + [0 0 2*Lz 0]; 
    
    % Calculate the total number of points in the full domain
    N = [length(0:h:Lx) length(0:h:Ly) length(0:h:Lz)];
    
    %scatter3(coords(pF,1),coords(pF,2),coords(pF,3))
    %hold on
    %scatter3(coords(ipts,1),coords(ipts,2),coords(ipts,3))
    %axis([-Lx 2*Lx -Ly 2*Ly -Lz 2*Lz])
    %xlabel('x');ylabel('y');zlabel('z')
end