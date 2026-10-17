close all
clear all

parpool('dogwood-debug',88)

pos = [1.5 2 2];
R = .5;
timeSteps = 2796;

niv1=18;

pInt = zeros(timeSteps+1,1);
wInt = zeros(timeSteps+1,1);
uInt = zeros(timeSteps+1,3);

parfor i=0:timeSteps
    % How many niv2 blocks
    [vtmFn,baseFn] = vtmName_(i);
    niv2 = findNiv2_(vtmFn);
    
    [pInt_, wInt_, uInt_] = integrateWhole_(baseFn,niv1,niv2,pos,R);
    pInt(i+1) = pInt_;
    wInt(i+1) = wInt_;
    uInt(i+1,:) = uInt_;
end

save('test.mat',"uInt","wInt","pInt")

function [vtmFn,vtrFn] = vtmName_(i)
    if i<10
        vtmFn = sprintf('file000%i.vtm',i);
        vtrFn = sprintf('file000%i/file000%i',i,i);
    elseif i<100
        vtmFn = sprintf('file00%i.vtm',i);
        vtrFn = sprintf('file00%i/file00%i',i,i);
    elseif i<1000
        vtmFn = sprintf('file0%i.vtm',i);
        vtrFn = sprintf('file0%i/file0%i',i,i);
    else
        vtmFn = sprintf('file%i.vtm',i);
        vtrFn = sprintf('file%i/file%i',i,i);
    end
end

function niv2 = findNiv2_(vtmName)
    fid = fopen(vtmName, 'rb');
    %# Get file size.
    fseek(fid, 0, 'eof');
    fileSize = ftell(fid);
    frewind(fid);
    %# Read the whole file.
    data = fread(fid, fileSize, 'uint8');
    %# Count number of line-feeds and increase by one.
    numLines = sum(data == 10);
    fclose(fid);
    % Do the thing
    niv2 = numLines-7-1;
end

function [pInt, wInt, uInt] = integrateWhole_(baseFn,niv1,niv2,pos,R)
    pInt = 0;
    wInt = 0;
    uInt = [0 0 0];
    %test = zeros(niv2-niv1,1);
    test = 0;
    bndS = zeros(niv2-niv2,6);
    for i=niv1:niv2
        % Load data for block
        filename=sprintf('%s.%i.vtr',baseFn,i);
        data = readVtr_(filename);
        % Create phase field
        data.water = [];
        water = sqrt(sum((data.pts-pos).^2,2)) > R;
        data.water = water;
        data.p = water.*data.p;
        data.u = water.*data.u;
        % Integrate
        [pInt_, uInt_, wInt_, test_] = integrate_(data);
        pInt = pInt + pInt_;
        wInt = wInt + wInt_;
        uInt = uInt + uInt_;
        test = test + test_;
        %test(i-niv1+1) = test_;
        bndS(i-niv1+1,:) = [min(data.gridx) max(data.gridx)...
                     min(data.gridy) max(data.gridy)...
                     min(data.gridz) max(data.gridz)];
    end
    
    for i=1:niv1
        filename=sprintf('%s.%i.vtr',baseFn,i-1);
        data = readVtr_(filename);
        %% Check for intersections
        bndB = [min(data.gridx) max(data.gridx)...
                  min(data.gridy) max(data.gridy)...
                  min(data.gridz) max(data.gridz)];
        ep=1e-6;
        xCheck = checkIntersectDim_(1,2,bndS,bndB,ep);
        yCheck = checkIntersectDim_(3,4,bndS,bndB,ep);
        zCheck = checkIntersectDim_(5,6,bndS,bndB,ep);
        intersect = xCheck & yCheck & zCheck;
        bndList = bndS(intersect,:);
        
        %% Sort out cells
        % Compute cell centers
        % Long way, just to test the faster way
        nCells = length(data.cells(:,1));
        centers = zeros(nCells,3);
        for j=1:nCells
            cell_ = data.cells(j,:);
            ptid_ = data.ptID(cell_,:);
            centers(j,1) = (max(data.gridx(ptid_(:,1)))-min(data.gridx(ptid_(:,1))))/2 + min(data.gridx(ptid_(:,1))); 
            centers(j,2) = (max(data.gridy(ptid_(:,2)))-min(data.gridy(ptid_(:,2))))/2 + min(data.gridy(ptid_(:,2))); 
            centers(j,3) = (max(data.gridz(ptid_(:,3)))-min(data.gridz(ptid_(:,3))))/2 + min(data.gridz(ptid_(:,3))); 
        end
        % Check whether cell centers lie in small block
        cellCheck = zeros(nCells,1);
        for j=1:length(bndList(:,1))
            bnds_ = bndList(j,:);
            xCheck = (centers(:,1) < bnds_(2)) & (bnds_(1) < centers(:,1));
            yCheck = (centers(:,2) < bnds_(4)) & (bnds_(3) < centers(:,2));
            zCheck = (centers(:,3) < bnds_(6)) & (bnds_(5) < centers(:,3));
            check_ = xCheck & yCheck & zCheck;
            cellCheck = cellCheck | check_;
        end
        %i
        cellCheck = ~cellCheck;
        % Create phase field
        data.water = [];
        water = sqrt(sum((data.pts-pos).^2,2)) > R;
        data.water = water;
        data.p = water.*data.p;
        data.u = water.*data.u;
        if sum(cellCheck) > 0
            cellList = data.cells(cellCheck,:); % Pick out cells outside the small blocks
            dataReduced = data;
            dataReduced.cells = cellList;
        else
            dataReduced = data;
        end
        [pInt_,uInt_, wInt_, test_] = integrate_(dataReduced);
        %[pInt_,uInt_,test_] = integrate_(data);
        %test_
        pInt = pInt + pInt_;
        wInt = wInt + wInt_;
        uInt = uInt + uInt_;
        test = test + test_;
    
    end
end

function check = checkIntersectDim_(minInd,maxInd,bndS,bndB,ep)
    minS = bndS(:,minInd); maxS = bndS(:,maxInd);
    minB = bndB(minInd);   maxB = bndB(maxInd);

    case1 = (minS < minB) & (minB < maxS);
    case2 = abs(minB-minS)<ep;
    case3 = (minB < minS) & (maxS < maxB);
    case4 = abs(maxB-maxS)<ep;
    case5 = (minB < minS) & (maxB < maxS) & (minS < maxB);
    check = case1 | case2 | case3 | case4 | case5;
end

function [pInt, uInt, wInt, test2] = integrate_(data)
numCells = length(data.cells(:,1));
check = 0; %zeros(numCells,1);
pInt = 0;
wInt = 0;
uInt = [0 0 0];
for i=1:numCells
    cell_ = data.cells(i,:);
    ptID_ = data.ptID(cell_,:);
    dx = max(data.gridx(ptID_(:,1)))-min(data.gridx(ptID_(:,1)));
    dy = max(data.gridy(ptID_(:,2)))-min(data.gridy(ptID_(:,2)));
    dz = max(data.gridz(ptID_(:,3)))-min(data.gridz(ptID_(:,3)));
    vol = dx*dy*dz;
    check = check + vol;
    % Integrate p
    pInt_ = sum(data.p(cell_))/8;
    pInt = pInt + pInt_*vol;
    % Integrate u
    uInt_ = sum(data.u(cell_,:),1)/8;
    uInt = uInt + uInt_*vol;
    % Integrate water volume
    wInt_ = sum(data.water(cell_))/8;
    wInt = wInt + wInt_*vol;
end

checka = (max(data.gridx)-min(data.gridx))*(max(data.gridy)-min(data.gridy))*(max(data.gridz)-min(data.gridz));
test1 = abs(checka-check);
test2 = check;
end

function vtkData = readVtr_(filename)

vtkData.gridx=[];
vtkData.gridy=[];
vtkData.gridz=[];
vtkData.extent=[];
vtkData.p = [];
vtkData.u = [];
vtkData.ptID = [];
vtkData.cells = [];
vtkData.pts = [];

fid = fopen(filename);

%% Extent information
% Loop to extent information
for i=1:3
    str = fgets(fid);
end
% Get extent information
lengthCheck=1;
j=0;
while lengthCheck % How many characters are numbers?
    j=j+1;
    extentTmp = str2num(str(33:33+j));
    lengthCheck = length(extentTmp)>0;
end
vtkData.extent = str2num(str(33:(33+j-1)))+1;

%% Collect p
numPts = prod(vtkData.extent([2 4 6]));
extP = 25+ceil(numPts/6);

% Get past the info
for i=4:25
    str = fgets(fid);
end

% start collecting p
p=zeros(numPts,1);
for i=26:extP
    str = fgets(fid);
    pTmp = str2num(str);
    lpTmp = length(pTmp);
    st=(i-26)*6+1;
    p(st:(st+lpTmp-1))=pTmp;
end
vtkData.p = p;

% Move through the next two
for i=(extP+1):(extP+2)
    str=fgets(fid);
end

extU = extP+2+ceil(numPts/2);

% start collecting u
u=zeros(numPts,3);
for i=(extP+3):extU
    str = fgets(fid);
    uTmp = str2num(str);
    lpTmp = length(uTmp)/3;
    lpTmp2 = lpTmp > 1;
    st = (i-extP-3)*2+1;
    u(st,:)=uTmp(1:3);
    u(st+lpTmp2,:)=uTmp((1:3)+lpTmp2*3);
end

vtkData.u = u;

% Skip next bits
numCells=prod(vtkData.extent([2 4 6])-1);
ghostZoneExt = extU+4+ceil(numCells/6);
for i=(extU+1):(ghostZoneExt+4)
    str=fgets(fid);
    
end

%% Collect grid info
extX = ghostZoneExt+4+ceil(vtkData.extent(2)/6);
gridX = zeros(vtkData.extent(2),1);
for i=(ghostZoneExt+5):extX
    str=fgets(fid);
    gridTmp = str2num(str);
    st = (i-ghostZoneExt-5)*6+1;
    lg = length(gridTmp)-1;
    gridX(st:(st+lg)) = gridTmp;
end

for i=1:2
    str=fgets(fid);
end

extY = extX + 2 + ceil(vtkData.extent(4)/6);
gridY = zeros(vtkData.extent(4),1);
for i=(extX+3):extY
    str=fgets(fid);
    gridTmp = str2num(str);
    st = (i-extX-3)*6+1;
    lg = length(gridTmp)-1;
    gridY(st:(st+lg)) = gridTmp;
end

for i=1:2
    str=fgets(fid);
end


extZ = extY + 2 + ceil(vtkData.extent(6)/6);
gridZ = zeros(vtkData.extent(6),1);
for i=(extY+3):extZ
    str=fgets(fid);                 % Get string data
    gridTmp = str2num(str);         % Convert to num
    st = (i-extY-3)*6+1;
    lg = length(gridTmp)-1;
    gridZ(st:(st+lg)) = gridTmp;
end

ptsIndex = makeGridIndex_(vtkData.extent,numPts);
cells = makeCells_(vtkData.extent);

vtkData.gridx = gridX;
vtkData.gridy = gridY;
vtkData.gridz = gridZ;
vtkData.ptID  = ptsIndex;
vtkData.cells = cells;
vtkData.pts   = ptsIndex;
    vtkData.pts(:,1) = gridX(ptsIndex(:,1));
    vtkData.pts(:,2) = gridY(ptsIndex(:,2));
    vtkData.pts(:,3) = gridZ(ptsIndex(:,3));
    

% % View data
% for i=1:length(cells(:,1))
%     cell_ = cells(i,:);
%     X_ = ptsIndex(cell_,:);
%     x = gridX(X_(:,1));
%     y = gridY(X_(:,2));
%     z = gridZ(X_(:,3));
%     scatter3(x,y,z,500,p(cell_),'filled');
%     hold on
%     pause(.01)
% end

end

function cells = makeCells_(extent)
    extX = extent(2);
    extY = extent(4);
    extZ = extent(6);

    % Make row of cells in x direction as base
    cellX = zeros(extX-1,8);
    for i = 1:(extX-1)
        cellX(i,:) = [i i+1 i+extX i+extX+1 ...
                        i+extX*extY i+extX*extY+1 ...
                        i+extX*(extY+1) i+extX*(extY+1)+1];
    end

    % Extend the row of cells into the y direction
    cellY = zeros((extX-1)*(extY-1),8);
    for i = 1:(extY-1)
        st = (i-1)*(extX-1) + 1;
        en = st + (extX-1) - 1;
        cellY(st:en,:) = cellX + extX*(i-1);
    end

    % Extend the plane of cells into the z direction
    cells = zeros((extX-1)*(extY-1)*(extZ-1),8);
    for i = 1:(extZ-1)
        st = (i-1)*(extX-1)*(extY-1) + 1;
        en = st + (extX-1)*(extY-1) - 1;
        cells(st:en,:) = cellY + extY*extX*(i-1);
    end
end

function ptsIndex = makeGridIndex_(extent,numPts)
    ptsIndex = zeros(numPts,3);
    extX = extent(2);
    extY = extent(4);
    extZ = extent(6);
    for i = 1:(extY*extZ)
        st = (i-1)*extX + 1;
        en = st + extX - 1;
        ptsIndex(st:en,1) = 1:extent(2);
    end

    yInd_=zeros(extX*extY,1);
    for i = 1:extY
        st = (i-1)*extX + 1;
        en = st + extX - 1;
        yInd_(st:en,:) = i;
    end

    for i=1:extZ
        st = (i-1)*(extY*extX)+1;
        en = st + extY*extX - 1;
        ptsIndex(st:en,2) = yInd_;
        ptsIndex(st:en,3) = i;
    end
    
end