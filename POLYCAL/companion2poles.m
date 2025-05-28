function [poles,eig_vec] = companion2poles(alp, order, dt)
% poles = companion2poles(alp, order, dt) solves eigenvalue problem
% using companion matrix
%
% alp       denominator coefficient
% order      the maximum order of polynomials 
% dt      sampling period
%
% poles   complex poles
% eig_vec  eigenvector corresponding to the poles
% Reference: Peeters, B., Van der Auweraer, H., Leuridan, J. and Vasel, T., 2004. 
% PolyMAX modal parameter estimation: Challenging automotive and aerospace applications. VDI Berichte, (1825).

Nin=size(alp,2);
% discrete poles
MC = [zeros((order-1)*Nin, Nin), eye((order-1)*Nin); -alp(1:Nin*order,:)'] ;
[eigve,eigva] = eig(MC);

% poles
poles1 = (log(diag(eigva))/dt).' ;

% stable poles with negative real part
eig_sel=find(real(poles1)<0 & imag(poles1)>0);
poles=poles1(eig_sel);
eig_vec=eigve(:,eig_sel);


