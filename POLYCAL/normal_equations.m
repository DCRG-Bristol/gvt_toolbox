function [alp, beta] = normal_equations(HH,order)
% [alp, beta] = normal_equations(HH,order)
% solves normal equations of the least-squares problem
%
% HH    stores Xo,Yo
% order  maximum order of the polynomials 
%
% alp    coefficient of the denominator
% beat(ii).cof    coefficients of the numerator for ii output
% Reference: Peeters, B., Van der Auweraer, H., Guillaume, P. and Leuridan, J., 2004.
% The PolyMAX frequency-domain method: a new standard for modal parameter estimation?. Shock and Vibration, 11(3, 4), pp.395-409.

% normal equations
Nin=size(HH(1).FRF,2);
Nou=length(HH);
M=zeros((order+1)*Nin,(order+1)*Nin);

for ii=1:Nou
HH(ii).Ro= real(HH(ii).Xo'*HH(ii).Xo);
HH(ii).So=real(HH(ii).Xo'*HH(ii).Yo);
HH(ii).To= real(HH(ii).Yo'*HH(ii).Yo) ;

%  normal equations
M = M+2*(HH(ii).To-HH(ii).So.'*HH(ii).Ro^(-1)*HH(ii).So);
end

A=M(1:order*Nin,1:order*Nin);
B=-M(1:order*Nin,order*Nin+1:(order+1)*Nin);
alp1= A\B ;
alp=[alp1;eye(Nin)];
for ii=1:Nou
beta(ii).cof=-HH(ii).Ro\(HH(ii).So*alp);
end

