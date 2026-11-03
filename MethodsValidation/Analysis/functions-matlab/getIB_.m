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