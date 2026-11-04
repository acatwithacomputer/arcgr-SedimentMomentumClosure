function [Sr2I,Sr2A,test1,test2] = convergenceTestDenseParallel(h,seq,config)
    % Get domain size info
    if seq == 0
        Lx = 31.510819;
    elseif seq == 1
        Lx = 33.49318;
    elseif seq == 2
        Lx = 35.189766;
    elseif seq == 3
        Lx = 36.913605;
    else
        fprintf("Not a valid sequence! /r/n")
    end
    Ly = Lx; Lz = Lx;

    % Load the sphere centers
    sphfn = sprintf("./pts-%i.csv",config);
    pts = readmatrix(sphfn);

    % pts = initial sphere centers
    %[pF,ipts,dimall,N,coords] = phaseFieldOld(h,pts,Lx,Ly,Lz);
    [N,coords,sph] = phaseField(h,pts,Lx,Ly,Lz);
    Rmax = 10.0;
    lvlMax=ceil((Rmax)/h);
    % View sphere
    %scatter3(coords(:,1),coords(:,2),coords(:,3));
    % 
    % Volume fraction recovery test
    % The initial isotropic case should recover the solid volume fraction
    R = pts(:,4);
    Vs = sum(4.0/3.0*pi*(R.^3));
    Vbox = Lx*Ly*Lz;
    test=Vs/Vbox;
    
    Sr2I = twoPointCorrelationIsotropicParallelDense(coords,sph,N,lvlMax,h);
    Sr2A = Sr2I; % Placeholder just to pass something
    %Sr2A = twoPointCorrelationAnisotropicParallelDense(coords,sph,N,lvlMax,h);
    %Nold = prod(N);
    %Sr2old = computeTwoPointCorrelation(coords,sph,Nold,lvlMax,h);
    %plot(Sr2(:,1),Sr2(:,2))
    %xlabel("R")
    %ylabel("Sr2")
    %axis([0 Rmax+1 0 1.5*(max(Sr2(:,2)))])
    %pause(.1)
    
    test1=abs(test-Sr2I(1,2))/test*100;
    test2=trapz(Sr2I(:,1),Sr2I(:,2));
end