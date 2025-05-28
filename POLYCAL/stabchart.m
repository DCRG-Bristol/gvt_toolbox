function [fst, drst] = stabchart(fn, dr, fnmin1, drmin1, yfrf, ip, ...
fvec, fst, drst, ff, fdr, mathp, istab, p)
% [fst, drst] = stabchart(fn, dr, fnmin1, drmin1, yfrf, ip, ...
% fvec, fst, drst, ff, fdr, mathp, istab, p)
% Stabilization chart to extract stable poles in frequency and damping
%
% fn and dr        frequency and damping identified before poles selection
%                   at iteration p
% fnmin1 and drmin1  frequency and damping identified at iteration p-1
% yfrf              amplitude in dB, yfrf = 20*log10(abs(frf))
% ip                iteration index
% fvec              frequency vector in Hz
% fst               frequency of stables poles in frequency and damping (s)
% drst              damping of stable poles in frequency and damping (s)
% ff                frequency of stable poles in frequency (f)
% fdr              frequency of stable poles in damping (d)
% mathp             frequency of mathematical poles (o)
% p                 identification order
%
% fst and drst      frequency in Hz and modal damping factor of stable poles in
%                   frequency and damping
% Reference: Van der Auweraer, H. and Peeters, B., 2004, May. 
% Discriminating physical poles from mathematical poles in high order systems:
% use and automation of the stabilization diagram. In Proceedings of the 21st IEEE Instrumentation and Measurement Technology Conference


tolf = 0.01 ;
told = 0.05 ;

fmax = max(fvec) ;
fmin = min(fvec) ;
nfn = length(fn) ;
if length(fnmin1) > 0
    for ifp = 1:nfn
        if (fn(ifp) < fmax) && (fn(ifp) > fmin)
            [diff_fp, idiff_fp] = min(abs(fn(ifp)-fnmin1) / fn(ifp)) ;
            diff_xip = abs(dr(ifp)-drmin1) / dr(ifp) ;
            
            if (diff_fp <= tolf) && (diff_xip(idiff_fp) <= told)
                fst = [fst; fn(ifp)] ;
                drst = [drst dr(ifp)] ;
                
            elseif (diff_fp <= tolf) && (diff_xip(idiff_fp) > told)
                ff = [ff; fn(ifp)] ;
                
            elseif (diff_fp > tolf) && (diff_xip(idiff_fp) <= told)
                fdr = [fdr; fn(ifp)] ;
                
            elseif (diff_fp > tolf) && (diff_xip(idiff_fp) > told)
                mathp = [mathp; fn(ifp)] ;
            end
        end
    end
end

if length(fst) > 0
    text(fst, (min(yfrf)+istab*ip)*ones(length(fst), 1), 's', 'Color', 'b')
end  
if length(ff) > 0
    text(ff, (min(yfrf)+istab*ip)*ones(length(ff), 1), 'f', 'Color', 'g')
end    
if length(fdr) > 0
    text(fdr, (min(yfrf)+istab*ip)*ones(length(fdr), 1), 'd', 'Color', 'r')
end   
if length(mathp) > 0
    text(mathp, (min(yfrf)+istab*ip)*ones(length(mathp), 1), 'm', 'Color', 'c')
end

% add horizontal line at each order
line([fmin, fmax], (min(yfrf)+istab*ip)*[1, 1], ...
'Color', [0.8, 0.8, 0.8],'HandleVisibility','off')
% add order on the right
text(fmax, min(yfrf)+istab*ip, num2str(p))
title('Stabilization diagram')
    

