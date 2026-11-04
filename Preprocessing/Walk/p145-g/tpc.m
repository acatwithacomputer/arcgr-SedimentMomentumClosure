close all
clear all
format shorte

addpath('./configurations/')
addpath('./functions/')

seq = 1;
cv=false;

h=(.5)^3;% 
nConfig = 0; %200; %1000;
test = zeros(nConfig+1,2);
time = zeros(nConfig+1,1);


for config=0:nConfig %loop through number of configs
    fprintf('Configuration %i of %i \r\n',config+1,nConfig+1)
    tic
    %[Sr2I,Sr2A,test1, test2] = convergenceTestDenseParallel(h,seq,config);
    [Sr2I,test_] = twoPointCorrelationDenseEw("p145",config,h,1,[4 4 12]);
    testConfig = [h test_]
    test(config+1,:) = testConfig;
    tocConfig = toc
    time(config+1)=tocConfig;
    
    % Save results
    savefn = sprintf("Sr-%i.mat",config);
    save(savefn,"Sr2I")
end