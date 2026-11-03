function [ieT,vaw] = getSimpleData_(mu,Vw,Vbox)
    % Load volume data
    data_ = readmatrix('./volOF.dat');
    vaw = data_(:,1:2)/Vw/.01;
    paw = data_(:,4)/Vw/.01;
    % Load surface data
    data_ = readmatrix('./surfOF.dat');
    mugradUn = mu*data_(:,1:2)/.01;
    pn     = data_(:,4:5)/.01;
    % Compute ieT
    ieT = (pn-mugradUn)/Vbox;
end
