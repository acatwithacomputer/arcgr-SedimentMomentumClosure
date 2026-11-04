function [Sr2I,Sr2A,test1,test2] = convergenceTestDilute(h,seq,seqNum)
    if seq == "a"
        eps = [.05 .1 .5 1.5*.5 3*.5];
        [pts,Lx,Ly,Lz] = diluteA(eps(seqNum+1));
    elseif seq == "b"
        eps = [.05 .1 .5 1.5*.5 3*.5];
        [pts,Lx,Ly,Lz] = diluteB(eps(seqNum+1));
    elseif seq == "e"
        eps = [.05 .1 .5 1.5*.5 3*.5];
        [pts,Lx,Ly,Lz] = diluteE(eps(seqNum+1));
    elseif seq == "f"
        eps = [.05 .1 .5 1.5*.5 3*.5];
        [pts,Lx,Ly,Lz] = diluteF(eps(seqNum+1));
    elseif seq == "px1"
        eps = [.05, .1, .2, .4];
        [pts,Lx,Ly,Lz] = px(eps(seqNum+1),1);
    elseif seq == "px2"
        eps = [.05, .1, .2, .4];
        [pts,Lx,Ly,Lz] = px(eps(seqNum+1),2);
    elseif seq == "pz"
        eps = [.05, .1, .2, .4];
        [pts,Lx,Ly,Lz] = pz(eps(seqNum+1));
    else
        fprintf("Not a valid sequence! /r/n")
    end
    % pts = initial sphere centers
    %[pF,ipts,dimall,N,coords] = phaseFieldOld(h,pts,Lx,Ly,Lz);
    [N,coords,sph] = phaseField(h,pts,Lx,Ly,Lz);
    Rmax = 10.0;
    lvlMax=ceil((Rmax)/h);
    % View sphere
    %scatter3(coords(:,1),coords(:,2),coords(:,3));
    % 
    R = pts(1,4);
    Vs = 4.0/3.0*pi*(R^3);
    Vbox = Lx*Ly*Lz;
    test=2*Vs/Vbox
    
    Sr2I = twoPointCorrelationIsotropic(coords,sph,N,lvlMax,h);
    Sr2A = twoPointCorrelationAnisotropic(coords,sph,N,lvlMax,h);
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