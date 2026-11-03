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
%addpath("./functions-octave")
addpath('./functions-matlab')

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
xlabel('$|\vec{Re}|$','Interpreter','latex','FontSize',labelsz-5)
ylabel('$\acute{{{w \rightarrow s} \atop \vec{T}}}_x$','Interpreter','latex','FontSize',labelsz)

relErrL1 = sum(abs(sfp-ibp))/length(reGen)*100
relErrL2 = sqrt(sum((sfp-ibp).^2))/length(reGen)*100
