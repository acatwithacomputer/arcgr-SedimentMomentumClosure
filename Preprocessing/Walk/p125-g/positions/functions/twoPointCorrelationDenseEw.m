function [Sr,test] = twoPointCorrelationDenseEw(code,config,h_target,r2pt_max,blocking)

    % General stuff regardless of level
    [Lx, spheresBox] = getDomainInfoDM_(code,config);
    % Make cell centered grid base
    gridBase = linspace(0,Lx,ceil(Lx/h_target)+1);
    h = gridBase(2);
    gridBase = gridBase(1:end-1);
    gridBase = gridBase + h/2;
    
    lvlMax = ceil(r2pt_max/h);
    
    % Generate periodic sphere list
    spheresPer = spheresPer_(spheresBox,Lx);

    % Make block index list
    xgridi = 1:blocking(1);
    ygridi = 1:blocking(2);
    zgridi = 1:blocking(3);

    [Xi,Yi,Zi] = meshgrid(xgridi,ygridi,zgridi);

    nblocks = prod(blocking);
    gridi = zeros(nblocks,3);
    gridi(:,1) = reshape(Xi,[nblocks 1]);
    gridi(:,2) = reshape(Yi,[nblocks 1]);
    gridi(:,3) = reshape(Zi,[nblocks 1]);
    gridi = gridi - 1;

    % Initialize things
    Sr = zeros(lvlMax+1,2);
    % Prep weights
    N  = length(gridBase)^3;
    wr = 6;
    
    for lvl=0:lvlMax
        iddBlockContrib = zeros(nblocks,1);
        r2pt = lvl*h;
        fprintf('Isotropic level %i of %i \r\n',lvl+1,lvlMax+1)
        parfor i=1:nblocks % this will be the parfor loop
            %if (mod(i,200) < 1) | (nblocks-i < 1)
            %    sprintf('Block %i of %i \r\n',i,nblocks)
            %end
            %if abs(i-120)<1
            %    m=2;
            %end
            % Get block info
            gridi_ = gridi(i,:);
            xrng  = zeros(3,2);
            blocking_ = blocking;
            for j = 1:3
                xrng(j,:) = Lx/blocking_(j)*[gridi_(j) (gridi_(j)+1)];
            end

            %ncheck(xrngi+1,yrngi+1,zrngi+1)=1;

            % Generate local phase field
            gridLocal = localPhaseField_(gridBase,xrng,spheresPer);
            %scatter3(gridLocal(:,1),gridLocal(:,2),gridLocal(:,3))
            %gridLocal = [];
            if prod(size(gridLocal))>1
                % Make local sphere list
                spheresTrim = trimSpheres_(spheresPer,xrng,r2pt);
                % Compute local idd
                iddLocal = 0;
                iddLocal = iddLocal + checkPoints_(gridLocal+[r2pt 0 0],spheresTrim);
                iddLocal = iddLocal + checkPoints_(gridLocal-[r2pt 0 0],spheresTrim);
                iddLocal = iddLocal + checkPoints_(gridLocal+[0 r2pt 0],spheresTrim);
                iddLocal = iddLocal + checkPoints_(gridLocal-[0 r2pt 0],spheresTrim);
                iddLocal = iddLocal + checkPoints_(gridLocal+[0 0 r2pt],spheresTrim);
                iddLocal = iddLocal + checkPoints_(gridLocal-[0 0 r2pt],spheresTrim);
                iddBlockContrib(i) = iddLocal;
            end
        end
        % Weigh and save info
        Sr(lvl+1,:) = [r2pt, 1/(N*wr)*sum(iddBlockContrib)];
    end
    
    Vs = sum(4/3*pi*(spheresBox(:,4).^3));
    Vbox = Lx^3;
    ew = 1-Vs/Vbox;
    test = abs(Sr(1,2)-ew)/ew*100;

end

function [Lx, spheres] = getDomainInfoDM_(code,config)
    codeDigit = str2double(erase(code,"p"));
    es = mod(codeDigit,100);
    seq = (codeDigit-es)/100;

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

    % Load the sphere centers
    sphfn = sprintf("./pts-%i.csv",config);
    spheres = readmatrix(sphfn);
end

function idd = checkPoints_(pts,spheres)
    nSph = length(spheres(:,1));
    nPts = length(pts(:,1));
    check = zeros(nPts,1);
    % Loop through the spheres
    for i=1:nSph
        sphereInfo = spheres(i,:);
        x0 = sphereInfo(1:3);
        R = sphereInfo(4);
        check = check | sum((pts-x0).^2,2) < R^2;
    end
    %idd = sum(max(not(check),[],2));
    idd = sum(not(check));
end

function spheresPer = spheresPer_(spheresBox,Lx)
    nSph = length(spheresBox(:,1));
    Ly = Lx; Lz = Lx;
    % Make periodic spheres    
    spheresPer = zeros(27*nSph,4);
    % Make base layer with just x coord displacement
    spheresPer(0*nSph+1:1*nSph,:) = spheresBox + [-Lx -Ly -Lz 0];
    spheresPer(1*nSph+1:2*nSph,:) = spheresBox + [  0 -Ly -Lz 0];
    spheresPer(2*nSph+1:3*nSph,:) = spheresBox + [ Lx -Ly -Lz 0];
    % Repeat for y coord displacement = 0
    spheresPer(3*nSph+1:6*nSph,:) = spheresPer(1:3*nSph,:) + [0 Ly 0 0];
    % Repeat for y coord displacement = Ly
    spheresPer(6*nSph+1:9*nSph,:) = spheresPer(1:3*nSph,:) + [0 2*Ly 0 0];
    % Repeat for z coord displacement = 0
    spheresPer(9*nSph+1:18*nSph,:) = spheresPer(1:9*nSph,:) + [0 0 Lz 0];
    % Repeat for z coord displacement = Lz
    spheresPer(18*nSph+1:27*nSph,:) = spheresPer(1:9*nSph,:) + [0 0 2*Lz 0]; 
end

function gridLocal = localPhaseField_(gridBase,xrng,spheresPer)
    % Trim off the extra base
    xgridLoc = gridBase((gridBase <= (xrng(1,2))) & (gridBase >= (xrng(1,1))));
    ygridLoc = gridBase((gridBase <= (xrng(2,2))) & (gridBase >= (xrng(2,1))));
    zgridLoc = gridBase((gridBase <= (xrng(3,2))) & (gridBase >= (xrng(3,1))));

    % Make grid into one giant list of points
    [x,y,z]=meshgrid(xgridLoc,ygridLoc,zgridLoc);
    dim = length(xgridLoc)*length(ygridLoc)*length(zgridLoc);
    gridLoc_ = [reshape(x,[dim 1]) reshape(y,[dim 1]) reshape(z,[dim 1])];
 
    % Initiate phase field as a sparse matrix to save space
    pF = sparse(dim,1);
    % Loop through spheres and insert them into phase field
    spheresTrim = trimSpheres_(spheresPer,xrng,0);
    ns = length(spheresTrim(:,1));
    for i=1:ns
        ci = spheresTrim(i,:);
        pF = pF | sparse(sum((gridLoc_-ci(1:3)).^2,2) < (ci(4)^2));
    end
    % Select points that are not spheres
    gridLocal = gridLoc_(not(pF),:);
    % scatter3(gridLocal(:,1),gridLocal(:,2),gridLocal(:,3))
    % hold on
    % scatter3(gridLoc_(pF,1),gridLoc_(pF,2),gridLoc_(pF,3))
    % scatter3(spheresTrim(:,1),spheresTrim(:,2),spheresTrim(:,3))
    % xlabel('x')
    % ylabel('y')
    % zlabel('z')
    % a=1;

end

function spheresTrim = trimSpheres_(spheresPer,xrng,SRmax)
    coordMin = xrng(:,1);
    coordMax = xrng(:,2);
    Rmax = max(spheresPer(:,4));

    % ID touching spheres
    check = zeros(length(spheresPer(:,1)),3);
    for i=1:3
        check(:,i) = (spheresPer(:,i) + spheresPer(:,4)) > (coordMin(i)-SRmax-Rmax);
        check(:,i) = check(:,i) & ((spheresPer(:,i) - spheresPer(:,4)) < (coordMax(i)+SRmax+Rmax));
    end
    checkFinal = check(:,1) & check(:,2) & check(:,3);

    spheresTrim = spheresPer(checkFinal,:);
end

function [centers,R] = handlePeriodic_(spheresAll,Lx,Ly,Lz)
    centers_ = spheresAll(:,1:3);
    R_ = spheresAll(:,4);

    % Pick out close to planes
    x0 = centers_(:,1) < R_;       % Pick out close to x0
    xl = centers_(:,1) > (Lx-R_);  % Pick out close to Lx
    y0 = centers_(:,2) < R_;       % Pick out close to y0
    yl = centers_(:,2) > (Ly-R_);  % Pick out close to yL
    z0 = centers_(:,3) < R_;       % Pick out close to z0
    zl = centers_(:,3) > (Lz-R_);  % Pick out close to zL

    % Pick out close the wedges
    w00x = x0 & y0; w0x0 = x0 & z0;
    w0lx = x0 & yl; w0xl = x0 & zl;
    wx00 = y0 & z0; wx0l = y0 & zl;
    wl0x = xl & y0; wlx0 = xl & z0;
    wllx = xl & yl; wlxl = xl & zl;
    wxl0 = yl & z0; wxll = yl & zl;
    
    % Pick out the corners
    c000 = x0 & y0 & z0;
    c00l = x0 & y0 & zl;
    c0l0 = x0 & yl & z0;
    c0ll = x0 & yl & zl;
    cl00 = xl & y0 & z0;
    cl0l = xl & y0 & zl;
    cll0 = xl & yl & z0;
    clll = xl & yl & zl;

    % Add up number of spheres
    % Add planes
    ns = length(R_) + sum(x0+xl+y0+yl+z0+zl);
    % Add wedges
    ns = ns + sum(w00x + w0x0 + wx00);
    ns = ns + sum(w0lx + w0xl + wx0l);
    ns = ns + sum(wl0x + wlx0 + wxl0);
    ns = ns + sum(wllx + wlxl + wxll);
    % Add corners
    ns = ns + sum(c000 + c00l + c0l0 + c0ll);
    ns = ns + sum(cl00 + cl0l + cll0 + clll);
   
    centers = zeros(ns,3);
    R = zeros(ns,1);
    en=0;
    % Copy short list
    st=1;en=length(R_);
    centers(st:en,:) = centers_;
    R(st:en) = R_;
    % Repeat planes
    [centers,R,en] = updateList_(x0,[ Lx   0   0],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(xl,[-Lx   0   0],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(y0,[  0  Ly   0],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(yl,[  0 -Ly   0],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(z0,[  0   0  Lz],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(zl,[  0   0 -Lz],en,centers,centers_,R,R_);

    % Repeat wedges
    [centers,R,en] = updateList_(w00x,[ Lx  Ly   0],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(w0lx,[ Lx -Ly   0],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(wl0x,[-Lx  Ly   0],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(wllx,[-Lx -Ly   0],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(w0x0,[ Lx   0  Lz],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(w0xl,[ Lx   0 -Lz],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(wlx0,[-Lx   0  Lz],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(wlxl,[-Lx   0 -Lz],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(wx00,[  0  Ly  Lz],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(wx0l,[  0  Ly -Lz],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(wxl0,[  0 -Ly  Lz],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(wxll,[  0 -Ly -Lz],en,centers,centers_,R,R_);

    % Repeat corners
    [centers,R,en] = updateList_(c000,[ Lx  Ly  Lz],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(c00l,[ Lx  Ly -Lz],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(c0l0,[ Lx -Ly  Lz],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(c0ll,[ Lx -Ly -Lz],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(cl00,[-Lx  Ly  Lz],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(cl0l,[-Lx  Ly -Lz],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(cll0,[-Lx -Ly  Lz],en,centers,centers_,R,R_);
    [centers,R,en] = updateList_(clll,[-Lx -Ly -Lz],en,centers,centers_,R,R_);
end

function [centersNew,RNew,enNew] = updateList_(region,vL,en,centers,centersOld,R,ROld)
        st=en+1;enNew=en+sum(region);
        % Copy accumulated quantity
        centersNew = centers;
        RNew = R;
        % Add new bit
        centersNew(st:enNew,:) = centersOld(region,:) + vL;
        RNew(st:enNew) = ROld(region);
end
