function [sRe, vRe] = computeRe_(D,nu,vr)
    rscale = D/nu;               % Scaling for Re
    nvr = sqrt(sum(vr.^2,2));     % |vaw-vas|
    vRe = rscale*vr;
    sRe = rscale*nvr;             % Scalar Re using |vr|
end