function [f1, frf1] = select_frf(f0, frf0, range)
% [f1, frf1] = select_frf(f0, frf0, range)
% selects FRF between in the frequency range
%
% f0       natural frequency vector in Hz
% frf0     complex frequency response function vector
% range   frequency range to be selected
%
% f1       natural frequency vector in Hz in the selected range
% frf1     complex frequency response function vector in the selected range


f_start=range(1);
f_end=range(2);
[~, i_start] = min(abs(f0-f_start)) ;
[~, i_end] = min(abs(f0-f_end)) ;
f1 = f0(i_start:i_end) ;
frf1 = frf0(i_start:i_end,:,:) ;
