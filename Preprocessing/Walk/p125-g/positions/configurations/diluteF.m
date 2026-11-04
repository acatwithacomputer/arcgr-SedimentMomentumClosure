function [pts,Lx,Ly,Lz] = diluteF(eps)
    Lx = 6.0;
    Ly = 6.0;
    Lz = 6.0;
    R  = .5;
    th = [0 pi]';
    dy = (2.0*R+eps)*cos(th);
    dz = (2.0*R+eps)*sin(th);
    pts = zeros(2,4);
        pts(:,1) = Lx/2.0;
        pts(:,2) = Ly/2.0 + dy;
        pts(:,3) = Lx/2.0 + dz;
        pts(:,4) = R;
end

%% Original python code:
% th = np.linspace(0,2.0*np.pi,3)
% x = (2.0*R+eps)*np.cos(th)
% y = (2.0*R+eps)*np.sin(th)
% pts = np.zeros((3,3))
% pts[0][:] = Lx/2.0 
% pts[1][:] = Ly/2.0 + x
% pts[2][:] = Lz/2.0 + y
% return pts