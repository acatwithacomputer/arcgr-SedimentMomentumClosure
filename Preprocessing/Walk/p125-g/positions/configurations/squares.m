function [pts,Lx,Ly,Lz] = hcp()
    Lx = 6.0;
    Ly = 4.0;
    Lz = 4.0;
    R  = .5;
    xpts = Lx/2.0 + (R+eps/2.0)*[-1 1];
    %pts = zeros(2,4);
    %    pts(1,:) = [xpts(1) Ly/2.0 Lz/2.0 R];
    %    pts(2,:) = [xpts(2) Ly/2.0 Lz/2.0 R];


    imax=2; jmax = 3; kmax=4;
    pts_ = zeros(imax*jmax*kmax,3);
    for i=1:imax
        for j = 1:jmax
            for k = 1:kmax
                ind = (i-1)*jmax*kmax +(j-1)*kmax + k;
                pts_(ind,1) = 2*i + mod(j+k,2);
                pts_(ind,2) = sqrt(3)*(j+1/3*mod(k,2));
                pts_(ind,3) = 2/3*sqrt(6)*k;
            end
        end
    end
    pts = pts_*R;

end