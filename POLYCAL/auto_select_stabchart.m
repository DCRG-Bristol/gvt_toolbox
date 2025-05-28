function [fst, dst] = auto_select_stabchart(FST, tolf, nbit)
% [fst, dst] = auto_select_stabchart(fn, dr, FST, tolf, nbit)
% Automated interpretation of Stability chart based on the last iteration
% of the stabilization chart. Returns poles reapeated nbit times in the
% tolerance interval defined by tolf.

% FST     cell with frequency and damping of stable poles in frequency and damping 
%         at each order
% tolf    frequency tolerance
% nbit    number of iteration respecting the frequency tolerance

nbl = length(FST) ;
for ii=1:nbl
    if length(FST{ii})~=0
len(ii)=length(FST{ii}.fn);
    end
end
nbc=max(len);

% from cell to matrix
FSTm = zeros(nbl, nbc) ;
for ii=1:nbl
    if len(ii)~=0
    FSTm(ii, 1:len(ii)) = FST{ii}.fn.' ;
    end
end

% number of frequency in the interval
imode = [] ;
for i=1:nbc
    if FSTm(nbl, i) ~= 0
        nbp = length(FSTm(abs(FSTm-FSTm(nbl, i))/FSTm(nbl, i) < tolf)) ;
        if nbp >= nbit
            imode = [imode i] ;
        end
    end
end

fst = FST{nbl}.fn(imode) ;
dst = FST{nbl}.dr(imode) ;
