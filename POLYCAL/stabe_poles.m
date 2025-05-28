function [fst,dst,FST, hand]=stabe_poles(fvec,FRF,order_rang)
% plot stabilisation diagram
% FRF is an P-by-M-by-N array, where P is the number of frequency bins, M
%   is the number of response channels, and N is the number of excitation
%   channels.
% fvec is a column vector with P elements
% order_rang is the order range of the stabilisation diagram;
% fst is the natural frequency stable in both frequency and damping ratio
% dst is the corresponding damping ratio
% FST saves the stable natural frequency in every order
% Reference: Van der Auweraer, H. and Peeters, B., 2004, May. 
% Discriminating physical poles from mathematical poles in high order systems:
% use and automation of the stabilization diagram. In Proceedings of the 21st IEEE Instrumentation and Measurement Technology Conference

yfrf=20*log10(abs(FRF(:,1,1)));%choose the FRF from 1st input to 1st output

for inpt=1:length(FRF(1,:,1))
    if inpt==1
        tempFRF = FRF(:,inpt,1);
    else
        tempFRF = tempFRF+FRF(:,inpt,1);
    end
end
yfrf = 20*log10(abs(tempFRF));
n_min=order_rang(1);
n_max=order_rang(2);
disp('-----------------------------------------')
disp(['Identification between order ', num2str(n_min),' and ', num2str(n_max)])
disp('-----------------------------------------')
istab = (max(yfrf)-min(yfrf))/(n_max-n_min+1) ;
ip=0;
FST=[];
L=length(fvec);
Nin=size(FRF,3);
Nou=size(FRF,2);
f_start=fvec(1);
f_end=fvec(end);
dt = 1/(2*(f_end-f_start)) ;
[HH,alp,beta]=polymax_coeff(fvec,FRF,n_max);

for ii=n_min:n_max
     fst = [] ;
     dst = [] ;
      ff = [] ;
      fdr = [] ;
      mathp = [] ;
HH1=[];
for jj=1:Nou
HH1(jj).FRF=HH(jj).FRF;
HH1(jj).Xo = zeros(L, ii+1) ;
HH1(jj).Yo=zeros(L,Nin*(ii+1));
HH1(jj).Xo(:, 1:ii+1) = HH(jj).Xo(:,1:ii+1) ;
HH1(jj).Yo(:,1:Nin*(ii+1))=HH(jj).Yo(:,1:Nin*(ii+1));
end
% solve normal equations
[alp, beta] = normal_equations(HH1, ii) ;
% solve eigenvalue problem using companion matrix
[poles,eig_vec] = companion2poles(alp, ii, dt) ;
% modal parameters
wn = abs(poles+j*2*pi*f_start);
dr = -real(poles)./wn ;
% sort modal parameters
[wn, iwn] = sort(wn) ;
dr = dr(iwn)' ;
fn = wn/(2*pi) ;

    if ii==n_min
        fnmin1=fn;
        drmin1=dr;
hand = figure;
plot(fvec(2:end),20*log10(abs(FRF(2:end,1,1))))
xlim([f_start,f_end])
xlabel('Frequency (Hz)')
ylabel('FRF (dB)')
hold on
    else
       [fst, dst] = stabchart(fn, dr, fnmin1, drmin1, yfrf, ip, fvec, fst, dst, ff, fdr, mathp, istab, ii); 
        fnmin1=fn;
        drmin1=dr;
        FST{ii}.fn = fst ;
        FST{ii}.dr=dst;
        end
    ip=ip+1;
end

