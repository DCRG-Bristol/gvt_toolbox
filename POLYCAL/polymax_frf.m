function [fn,dr,Pfrf]=polymax_frf(FRF1,fvec1,order)

% FRF1 is an P-by-M-by-N array, where P is the number of frequency bins, M
%   is the number of response channels, and N is the number of excitation
%   channels.
% fvec1 is a column vector with P elements
% order is the order of the polynomial;

% fn is the natural frequency
% dr is the damping ratio
% Pfrf is the FRF of the polynomial model (P-by-M-by-N)
% Reference: Peeters, B., Van der Auweraer, H., Guillaume, P. and Leuridan, J., 2004.
% The PolyMAX frequency-domain method: a new standard for modal parameter estimation?. Shock and Vibration, 11(3, 4), pp.395-409.

L=length(fvec1);
Nin=size(FRF1,3);
Nou=size(FRF1,2);
f_start=fvec1(1);
f_end=fvec1(end);
w = 2*pi*(fvec1-f_start) ;
dt = 1/(2*(f_end-f_start)) ;
[HH,alp,beta]=polymax_coeff(fvec1,FRF1,order);

% construct polynomial FRF
for kk=1:Nou
for jj=1:L
A=zeros(Nin,Nin);
Bo=zeros(1,Nin);
for ii=1:order+1
A=A+zdomain(w(jj), dt, ii-1)*alp((ii-1)*Nin+1:ii*Nin,1:Nin);%denominator matrix polynomial
Bo=Bo+zdomain(w(jj), dt, ii-1)*beta(kk).cof(ii,:);%numerator matrix polynomial
frf_mid=Bo*A^(-1);
Pfrf(jj,kk,:)=frf_mid;
end
end
end

% solve eigenvalue problem using companion matrix
[poles,eig_vec] = companion2poles(alp, order, dt) ;
% modal parameters
wn = abs(poles+j*2*pi*f_start);
dr = -real(poles)./wn ;
% sort modal parameters
[wn, iwn] = sort(wn) ;
dr = dr(iwn)' ;
fn = wn/(2*pi) ;


