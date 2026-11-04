function [pts,Lx,Ly,Lz] = px(eps,seq)
    Lx = 6.0;
    Ly = 4.0;
    Lz = 4.0;

    if abs(seq-1) < 1
        R1 = .25;
        R2 = .5;
    elseif abs(seq-2) < 1
        R1 = .5;
        R2 = .25;
    end

    xpts = Lx/2.0 + 0.5*[-(R1+eps) (R2+eps)];
    pts = zeros(2,4);
        pts(1,:) = [xpts(1) Ly/2.0 Lz/2.0 R1];
        pts(2,:) = [xpts(2) Ly/2.0 Lz/2.0 R2];
end