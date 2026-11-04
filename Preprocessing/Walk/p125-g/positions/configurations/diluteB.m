function [pts,Lx,Ly,Lz] = diluteB(eps)
    Lx = 4.0;
    Ly = 4.0;
    Lz = 6.0;
    R  = .5;
    xpts = Lz/2.0 + (R+eps/2.0)*[-1 1];
    pts = zeros(2,4);
        pts(1,:) = [Lx/2.0 Ly/2.0 xpts(1) R];
        pts(2,:) = [Lx/2.0 Ly/2.0 xpts(2) R];
end