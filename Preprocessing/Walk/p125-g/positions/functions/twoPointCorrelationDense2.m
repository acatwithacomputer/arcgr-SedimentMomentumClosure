function [Sr,test] = twoPointCorrelationDense2(code,cv,h_target,r2pt_max)

    % General stuff regardless of level
    [Lx, spheresBox] = getDomainInfoDM_(code,cv);
    gridBase = linspace(0,Lx,ceil(Lx/h_target)+1);
    gridBase = gridBase(1:end-1);
    h = gridBase(2);
    [spheresAll,RAll] = handlePeriodic_(spheresBox,Lx,Lx,Lx);
    %gridBase = gridBase + h/2;
    lvlMax = 0; %ceil(r2pt_max/h);
    
    %generate periodic sphere list
    spheresPer = spheresPer_(spheresBox,Lx);
    
    %trim the sphere list
    
    % Initialize things
    nsb = length(spheresAll(:,1));
    Sr = zeros(lvlMax+1,2);
    % Prep weights
    N  = length(gridBase)^3;
    wr = 6;
    
    for lvl=0:0 %lvlMax
        iddSphereContrib = zeros(nsb,1);
        r2pt = lvl*h;
        sprintf('Isotropic level %i of %i \r\n',lvl+1,lvlMax+1)
        parfor i=1:nsb % this will be the parfor loop
            sprintf('Sphere %i of %i \r\n',i,nsb)
            %if abs(i-533)<1
            %m=2
            %end
            % Get local sphere info
            ci = [spheresAll(i,:) RAll(i)]; %spheresBox(i,:);
            % Generate local phase field
            gridLocal = localPhaseField_(ci,gridBase,0.0);
            if prod(size(gridLocal))>1
                % Make local sphere list
                spheresTrim = trimSpheres_(spheresPer,gridLocal,r2pt);
                %spheresTrim = spheresPer;
                % Compute local idd
                iddLocal = 0;
                iddLocal = iddLocal + checkPoints_(gridLocal+[r2pt 0 0],spheresTrim);
                iddLocal = iddLocal + checkPoints_(gridLocal-[r2pt 0 0],spheresTrim);
                iddLocal = iddLocal + checkPoints_(gridLocal+[0 r2pt 0],spheresTrim);
                iddLocal = iddLocal + checkPoints_(gridLocal-[0 r2pt 0],spheresTrim);
                iddLocal = iddLocal + checkPoints_(gridLocal+[0 0 r2pt],spheresTrim);
                iddLocal = iddLocal + checkPoints_(gridLocal-[0 0 r2pt],spheresTrim);
                iddSphereContrib(i) = iddLocal;
            end
        end
        % Weigh and save info
        Sr(lvl+1,:) = [r2pt, 1/(N*wr)*sum(iddSphereContrib)];
    end
    
    Vs = sum(4/3*pi*(spheresBox(:,4).^3));
    Vbox = Lx^3;
    es = Vs/Vbox
    test = abs(Sr(1,2)-es)/es*100;

end

function [Lx, spheres] = getDomainInfoDM_(code,cv)
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
    if cv
        sphfn = sprintf("./configurations/poly%i-%iBox-cv.csv",seq,es);
    else
        sphfn = sprintf("./configurations/poly%i-%iBox.csv",seq,es);
    end
    spheres = readmatrix(sphfn);
end

function idd = checkPoints_(pts,spheres)
    nSph = length(spheres(:,1));
    nPts = length(pts(:,1));
    check = zeros(nPts,nSph);
    % Loop through the spheres
    for i=1:nSph
        sphereInfo = spheres(i,:);
        x0 = sphereInfo(1:3);
        R = sphereInfo(4);
        check(:,i) = sum((pts-x0).^2,2) < R^2;
    end
    idd = sum(max(check,[],2));
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

function gridLocal = localPhaseField_(ci,gridBase,h)
    % Trim off the extra base
    xgridLoc = gridBase((gridBase <= (ci(1)+ci(4)+h)) & (gridBase >= (ci(1)-ci(4)-h)));
    ygridLoc = gridBase((gridBase <= (ci(2)+ci(4)+h)) & (gridBase >= (ci(2)-ci(4)-h)));
    zgridLoc = gridBase((gridBase <= (ci(3)+ci(4)+h)) & (gridBase >= (ci(3)-ci(4)-h)));

    % Make into one giant list of points
    [x,y,z]=meshgrid(xgridLoc,ygridLoc,zgridLoc);
    dim = length(xgridLoc)*length(ygridLoc)*length(zgridLoc);
    gridLoc_ = [reshape(x,[dim 1]) reshape(y,[dim 1]) reshape(z,[dim 1])];

    % Initiate phase field as a sparse matrix to save space
    pF = sparse(sum((gridLoc_-ci(1:3)).^2,2) < (ci(4)^2));
    gridLocal = gridLoc_(pF,:);
end

function spheresTrim = trimSpheres_(spheresPer,gridLocal,Rmax)
    coordMax = max(gridLocal,[],1);
    coordMin = min(gridLocal,[],1);

    % ID touching spheres
    check = zeros(length(spheresPer(:,1)),3);
    for i=1:3
        check(:,i) = (spheresPer(:,i) + spheresPer(:,4)) > (coordMin(i)-Rmax);
        check(:,i) = check(:,i) & ((spheresPer(:,i) - spheresPer(:,4)) < (coordMax(i)+Rmax));
    end
    checkFinal = check(:,1) | check(:,2) | check(:,3);

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
