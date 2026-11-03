close all
clear all

% Parameters
R=.5;           % Particle radius
Lx = 24.0;      % Domain dimensions
Ly = 4.0;
nu = .01;       % Dynamic viscosity
riw= 1.0;       % Density of water
mu = nu*riw;    % Kinematic viscosity
D  = 2.0*R;     % Particle diameter

% Compute Areas
Vbox = Lx*Ly;
Vs   = pi*R^2;
Vw   = Vbox-Vs;

% Pick function location
addpath("./functions-octave")

% Load data and compute Reynolds numbers
[ieTsf,vawsf] = getSimpleData_(mu,Vw,Vbox);

ibapts=2;
ibcpts=3;
ibgpts=4;
coarsepts = ibapts + ibcpts + ibgpts;
% Get iba (high delta(p))
for i=1:ibapts
    [Tib1a_,vrib1a_,ti1a_] = getIB_(Vbox,i);
    np(i) = length(ti1a_);
    Tib(1:np(i),:,i) = Tib1a_;
    vrib(1:np(i),:,i) = vrib1a_;
    tib(1:np(i),:,i) = ti1a_;
    TibSum(i,:) = Tib1a_(end,1:2);
end

% Get ibc (low delta(p))
for i=1:ibcpts
    [Tib1a_,vrib1a_,ti1a_] = getIBc_(Vbox,i);
    j = ibapts + i;
    np(j) = length(ti1a_);
    Tib(1:np(j),:,j) = Tib1a_;
    vrib(1:np(j),:,j) = vrib1a_;
    tib(1:np(j),:,j) = ti1a_;
    TibSum(j,:) = Tib1a_(end,1:2);
end

% Get ibg (mid delta(p))
for i=1:ibgpts
    [Tib1a_,vrib1a_,ti1a_] = getIBg_(Vbox,i);
    j = ibapts + ibcpts + i;
    np(j) = length(ti1a_);
    Tib(1:np(j),:,j) = Tib1a_;
    vrib(1:np(j),:,j) = vrib1a_;
    tib(1:np(j),:,j) = ti1a_;
    TibSum(j,:) = Tib1a_(end,1:2);
end

% Compute Reynolds numbers
[Resf,vResf] = computeRe_(D,nu,vawsf);
for i=1:coarsepts
    [Reib1a_,vReib1a_] = computeRe_(D,nu,vrib(:,:,i));
    Reib(:,i) = Reib1a_;
    vReib(:,:,i) = vReib1a_;
    ReibSum(i,:) = Reib1a_(np(i));
    vReibSum(i,:) = vReib1a_(np(i),:);
end

% Plot the Re vs ieT
lw = 3;
tscale = D^3*riw/(mu^2);    % Scaling for ieT

%%
dotsz = 25;
scatter(ReibSum,tscale*TibSum(:,1),dotsz,"blue","filled")
hold on
scatter(Resf,tscale*ieTsf(:,1),dotsz,"red","filled")
legend('ibamr','simpleFoam')
xlabel('Re')
ylabel('ieT*_x')
%axis([0 max(max(Resf,Reib)) 0 12])

%% Plot ieT_x
lw = 3;
figure
semilogy(tib(:,:,1),tscale*Tib(:,1,1),'LineWidth',lw)
hold on
for i=2:coarsepts
    semilogy(tib(1:np(i),:,i),tscale*Tib(1:np(i),1,i),'LineWidth',lw)
end
%axis([240 540 0 max(max(ieTsf*tscale))])
xlabel('Time(s)')
ylabel('ieT*_x')

%% Plot Re
lw = 3;
figure
plot(tib(:,:,1),Reib(:,1),'LineWidth',lw)
hold on
for i=2:coarsepts
    plot(tib(1:np(i),:,i),Reib(1:np(i),i),'LineWidth',lw)
end
axis([240 540 0 max(max(Resf))])
xlabel('Time(s)')
ylabel('Re')

%% Compute K, pimpleFoam
fprintf('Fit for simpleFoam    \r')
Ksf=computeK_(vResf,Resf,ieTsf,1:length(Resf),D,riw,mu)
fprintf('Fit for IBAMR, coarse    \r')
Kib=computeK_(vReibSum,ReibSum,TibSum,1:length(ReibSum),D,riw,mu)

reGen = linspace(0,10,100)';
re=[reGen reGen.^2];
sfp = re*Ksf;
ibp = re*Kib;
relErrL1 = sum(abs(sfp-ibp))/length(reGen)*100
relErrL2 = sqrt(sum((sfp-ibp).^2))/length(reGen)*100

reGen = linspace(0,14,100)';
re=[reGen reGen.^2];
sfp = re*Ksf;
ibp = re*Kib;

dotsz = 30;
lw = 2;
labelsz = 20;
figure
scatter(ReibSum,tscale*TibSum(:,1),dotsz,"blue","filled")
hold on
scatter(Resf,tscale*ieTsf(:,1),dotsz,"red","filled")
%axis([0 max(max(Resf,Reib)) 0 12])
hold on
plot(re(:,1),ibp,'b-','LineWidth',lw)
plot(re(:,1),sfp,'r-','LineWidth',lw)
legend('IBAMR data point','OpenFOAM data points','IBAMR fit','OpenFOAM fit')
xlabel('$|\vec{Re}|$',Interpreter='latex',FontSize=labelsz-5)
ylabel('$\acute{{{w \rightarrow s} \atop \vec{T}}}_x$',Interpreter='latex',FontSize=labelsz)

relErrL1 = sum(abs(sfp-ibp))/length(reGen)*100
relErrL2 = sqrt(sum((sfp-ibp).^2))/length(reGen)*100


function K2=computeK_(vRe,sRe,ieT,t,D,riw,mu)
    ts = length(t);
    % Scale and reshape quantities to do fit
    tscale = D^3*riw/(mu^2);    % Scaling for ieT
    ieTs = reshape((tscale*ieT)',[2*ts 1]); % Scale and arrange T*

    % Compute Re powers
    re1 = reshape(vRe',[2*ts 1]);
    re2 = reshape((sRe.*vRe)',[2*ts 1]);
    re3 = reshape(((sRe.^2).*vRe)',[2*ts 1]);
    tol = 1e-12;

    % Alt
    % ieTs = tscale*ieTpf(:,1);
    % re1 = vRe;    %reshape(vRe',[3*ts 1]);
    % re2 = vRe.^2; %reshape((sRe.*vRe)',[3*ts 1]);
    % re3 = vRe.^3; %reshape(((sRe.^2).*vRe)',[3*ts 1]);

    % Perform fit of K
    maxit = 20;
    [K1,flag1,res1,it1,vr1] = lsqr(re1,ieTs,tol,maxit); % Linear
    mRe = [re1 re2];
    [K2,flag2,res2,it2,vr2] = lsqr(mRe,ieTs,tol,maxit); % Quadratic
    mRe = [re1 re2 re3];
    [K3,flag3,res3,it3,vr3] = lsqr(mRe,ieTs,tol,maxit); % Cubic

    fprintf('K Fit  |     K1    |     K2     | Rel. Res. | \r')
    fprintf('Linear | %0.3e | ---------- | %0.3e | \r', K1, res1)
    fprintf('Quadr. | %0.3e |  %0.3e | %0.3e | \r', K2, res2)
    %fprintf('Cubic  | %0.3e | %0.3e | %0.3e | %0.3e | \r', K3, res3)

end

function [sRe, vRe] = computeRe_(D,nu,vr)
    rscale = D/nu;               % Scaling for Re
    nvr = sqrt(sum(vr.^2,2));     % |vaw-vas|
    vRe = rscale*vr;
    sRe = rscale*nvr;             % Scalar Re using |vr|
end

function [ieT,vr,t] = getIB_(Vbox,i)
    % Get velocity, pressure, and volume fraction
    data_ = readmatrix(sprintf('./ib%i.txt',i));
    t = data_(:,1);
    paw = data_(:,2);
    vaw = data_(:,3:4);
    ew  = data_(:,5);

    % Get ieT
    data_ = readmatrix(sprintf('./dump%i/Sphere_Drag_force_struct_no_0',i));
    np = length(t)-1;
    ieT = -data_(end-np:end,5:6)/Vbox;

    % Get position
    pos = dlmread(sprintf('./dump%i/Sphere_COM_coordinates_struct_no_0',i));
    posx = pos(:,2);
    dt = pos(end,1)-pos(end-1,1);
    vsnum = (diff(posx))/dt;

    % Weigh terms
    vs = vsnum(end)
    vr=vaw-[vs 0];

end

function [ieT,vr,t] = getIBc_(Vbox,i)
    % Get velocity, pressure, and volume fraction
    data_ = readmatrix(sprintf('./ib%ic.txt',i));
    t = data_(:,1);
    paw = data_(:,2);
    vaw = data_(:,3:4);
    ew  = data_(:,5);

    % Get ieT
    data_ = readmatrix(sprintf('./dump%ic/Sphere_Drag_force_struct_no_0',i));
    np = length(t)-1;
    ieT = -data_(end-np:end,5:6)/Vbox;

    % Get position
    pos = dlmread(sprintf('./dump%ic/Sphere_COM_coordinates_struct_no_0',i));
    posx = pos(:,2);
    dt = pos(end,1)-pos(end-1,1);
    vsnum = (diff(posx))/dt;

    % Weigh terms
    vs = vsnum(end)
    vr=vaw-[vs 0];

end

function [ieT,vr,t] = getIBg_(Vbox,i)
    % Get velocity, pressure, and volume fraction
    data_ = readmatrix(sprintf('./ib%ig.txt',i));
    t = data_(:,1);
    paw = data_(:,2);
    vaw = data_(:,3:4);
    ew  = data_(:,5);

    % Get ieT
    data_ = readmatrix(sprintf('./dump%ig/Sphere_Drag_force_struct_no_0',i));
    np = length(t)-1;
    ieT = -data_(end-np:end,5:6)/Vbox;

    % Get position
    pos = dlmread(sprintf('./dump%ig/Sphere_COM_coordinates_struct_no_0',i));
    posx = pos(:,2);
    dt = pos(end,1)-pos(end-1,1);
    vsnum = (diff(posx))/dt;

    % Weigh terms
    vs = vsnum(end)
    vr=vaw-[vs 0];

end

function testDeriv_
dt = 0.005;
t = 303.95:dt:304.035;
ux = [1.09208795e-01 1.09208791e-01 1.09208787e-01 1.09208783e-01...
      1.09208780e-01 1.09208776e-01 1.09208772e-01 1.09208768e-01...
      1.09208764e-01 1.09208761e-01 1.09208757e-01 1.09208753e-01...
      1.09208749e-01 1.09208745e-01 1.09208742e-01 1.09208738e-01...
      1.09208734e-01 1.09208730e-01];

diff1O2 = (ux(1:end-1) - ux(2:end))/(2*dt);
C1 = -1/12; C2 = 2/3; C3 = -2/3; C4 = 1/12;
diff1O4 = (C1*ux(1:end-4) + C2*ux(2:end-3) + C3*ux(4:end-1) + C4*ux(5:end))/dt;
C1 = 1/60; C2 = -3/20; C3 = 3/4; C4 = -3/4; C5 = 3/20; C6 = -1/60;
diff1O6 = (C1*ux(1:end-6) + C2*ux(2:end-5) + C3*ux(3:end-4) + C4*ux(5:end-2) + C5*ux(6:end-1) + C6*ux(7:end))/dt;

% plot(-diff1O2)
% hold on
% plot(-diff1O4)
% plot(-diff1O6)

end
