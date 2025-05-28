function [HH,alp,beta]=polymax_coeff(fvec1,FRF1,order)
% calculate the coefficient of the polynomial model
% fvec1 is the frequency column vector with P elements
% FRF1 is an P-by-M-by-N array, where P is the number of frequency bins, M
%   is the number of response channels, and N is the number of excitation
%   channels.
% order is the order of the polynomial;
% alp, beta are the coefficients
% HH saves the intermediate matrices
% Reference: Peeters, B., Van der Auweraer, H., Guillaume, P. and Leuridan, J., 2004.
% The PolyMAX frequency-domain method: a new standard for modal parameter estimation?. Shock and Vibration, 11(3, 4), pp.395-409.

L=length(fvec1);
Nin=size(FRF1,3);
Nou=size(FRF1,2);
f_start=fvec1(1);
f_end=fvec1(end);

w = 2*pi*(fvec1-f_start) ;
dt = 1/(2*(f_end-f_start)) ;
for ii=1:Nou
    for jj=1:Nin
    HH(ii).FRF(:,jj)=FRF1(:,ii,jj);
    HH(ii).var(jj)=var(FRF1(:,ii,jj));
    end
end

for ii=1:Nou
HH(ii).Xo = zeros(L, order+1) ;
for kk=1:order+1
      HH(ii).Xo(:, kk) = zdomain(w, dt, kk-1) ;
end
end

for ii=1:Nou
HH(ii).Yo=zeros(L,Nin*(order+1));
for kk=1:L
    HH(ii).Yo(kk,:)=-kron(HH(ii).Xo(kk,:),HH(ii).FRF(kk,:));
end
end    
% solve normal equations
[alp, beta] = normal_equations(HH, order) ;
