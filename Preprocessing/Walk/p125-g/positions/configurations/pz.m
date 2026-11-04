function [pts,Lx,Ly,Lz] = pz(eps)
    Lx = 4.0;
    Ly = 4.0;
    Lz = 6.0;

    R1 = .25;
    R2 = .5;

    xpts = Lx/2.0 + 0.5*[-(R1+eps) (R2+eps)];
    pts = zeros(2,4);
        pts(1,:) = [Lx/2.0 Ly/2.0 xpts(1) R];
        pts(2,:) = [Lx/2.0 Ly/2.0 xpts(2) R];
end