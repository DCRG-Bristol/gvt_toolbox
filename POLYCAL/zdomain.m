function [z] = zdomain(w, dt, k)
% [z] = zdomain(w, dt, k)
% returns the discrete-time z-domain transformation z = exp(j*k*dt*w)
%
% w    natural frequency in rad/s
% dt   sampling period
% k    at power k
%
% z    z-domain variable

z = exp(j*w*k*dt) ;
