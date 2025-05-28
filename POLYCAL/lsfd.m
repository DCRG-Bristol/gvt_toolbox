function [MS, frfm] = lsfd(w, frf, fn, dr)
% [MS, frfm] = lsfd(w, frf, fn, dr)
% Least-Squares Frequency-Domain (LSFD) estimator for the residues
%
% w   natural frequency vector in rad/s
% frf is an P-by-M-by-N array, where P is the number of frequency bins, M
%   is the number of response channels, and N is the number of excitation
%   channels
% fn    natural frequency in Hz stable in both frequency and damping ratio
% dr    the corresponding damping ratio
%
% MS         mode shape
% frfm        identified FRF in modal model
% Reference: Nestorovi?, T., Trajkov, M. and Patalong, M., 2016. 
% Identification of modal parameters for complex structures by experimental modal analysis approach. Advances in Mechanical Engineering, 8(5), p.1687814016649110.

s = j*w ;
wn = 2*pi*fn ;
nwn = length(wn) ;
L = length(w) ;

Nin=size(frf,3);
Nou=size(frf,2);

% linear square modal constant estimation
Cls = zeros(L, nwn+2) ;
for ic=1:nwn+2
    if ic <= nwn
        Cls(:, ic) = 1./(s.^2+2*s*wn(ic)*dr(ic)+wn(ic)^2) ;
        
    elseif ic == nwn+1
        Cls(:, ic) = 1./(s.^2) ;
        
    elseif ic == nwn+2
        Cls(:, ic) = 1 ;
        
    end
end
frfm=zeros(L,Nou,Nin);
MS=zeros(nwn,Nou,Nin);
for ii=1:Nou
    for jj=1:Nin
        FRF=frf(:,ii,jj);
rntot(:,ii,jj) = (Cls'*Cls) \ (Cls'*FRF) ;
% residue
ms = rntot(1:nwn,ii, jj);
MS(:,ii,jj)=ms;
% lower residual term
LR = rntot(nwn+1,ii, jj);
% upper residual term
UR = rntot(nwn+2,ii, jj);
% identified modal FRF in s-domain
frf_mid = zeros(L, nwn);
for ic=1:nwn
    frf_mid(:, ic) = ms(ic)./(s.^2+2*s*wn(ic)*dr(ic)+wn(ic)^2) ;
end
frfm(:,ii,jj) = sum(frf_mid, 2)+LR./(s'.^2)+UR ;
    end
end



