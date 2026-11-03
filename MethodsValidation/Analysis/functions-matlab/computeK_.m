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