close all
clear all

load("p125ew-4.mat")
Sr_ref = Sr2I;

smd = smd_;

nframes = 499;

x7 = zeros(nframes+1,1);

for i=0:nframes
    load(sprintf("Sr-%i.mat",i))
    plot(Sr2I(:,1),Sr2I(:,2))
    hold on
    plot(Sr_ref(:,1),Sr_ref(:,2))
    axis([0 8 .5 .75])

    pause(.1)
    hold off
    
    ri = Sr2I(:,1) < smd;
    nSr = normSr_(Sr2I);
    x7(i+1) = trapz(Sr2I(ri,1),nSr(ri))/smd;

end

ri = Sr_ref(:,1) < smd;
nSr = normSr_(Sr_ref);
x7_ref = trapz(Sr_ref(ri,1),nSr(ri))/smd;

figure
plot(x7)
hold on
plot([0 nframes],[x7_ref x7_ref])

save('x7nm.mat',"x7")

viewx7

function viewx7

load("../positions/x7cv.mat")
x7cv = x7;
load("../positions2/x7nm.mat")
x7nm = x7;

figure
plot(x7nm)
hold on
plot(x7cv)

xlabel("Time step")
ylabel("x_7")
legend("nm IC","cv IC")

end

function smd = smd_
data = readmatrix("./pts-0.csv");
r = data(:,4);
A = sum(4*pi*r.^2);
V = sum(4/3*pi*r.^3);
smd = 6*V/A;

end

function nSr = normSr_(Sr)
ew = Sr(1,2);
es = 1-ew;

nSr = Sr(:,2)-ew^2;
nSr = nSr/(ew*es);

end