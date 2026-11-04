function [pts,Lx,Ly,Lz] = diluteA(eps)
    Lx = 6.0;
    Ly = 4.0;
    Lz = 4.0;
    R  = .5;
    xpts = Lx/2.0 + (R+eps/2.0)*[-1 1];
    pts = zeros(2,4);
        pts(1,:) = [xpts(1) Ly/2.0 Lz/2.0 R];
        pts(2,:) = [xpts(2) Ly/2.0 Lz/2.0 R];
end