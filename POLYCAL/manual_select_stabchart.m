function [fst_sel, dst_sel] = manual_select_stabchart(FST,FRF,order_rang)
% [fst_sel, dst_sel] = manual_select_stabchart(FST,FRF,order_rang)
% manually select the poles that are stable in both frequency and damping
%
% FST     cell with frequency and damping of stable poles in frequency and damping 
%         at each order
% FRF    frequency response function
% order_rang the range of the order


fst_sel=[];dst_sel=[];
n_min=order_rang(1);
n_max=order_rang(2);
order_seq=[n_min:1:n_max];
yfrf=20*log10(abs(FRF(:,1,1)));%choose the FRF from 1st input to 1st output
istab = (max(yfrf)-min(yfrf))/(n_max-n_min+1) ;
scrsz = get(0,'ScreenSize');
     %set(gcf,'Position',scrsz);
     hold on
hque=questdlg('Pick stable pole?','pick point','yes','no','yes');
while strcmp(hque,'yes')
        hque1='no';
    while strcmp(hque1,'no')
[fre_pick,FRF_pick]=ginput(1);
order_pick=(FRF_pick-min(yfrf))/istab+n_min;
[order_pick1,order_loca]=min(abs(order_pick-order_seq));
order_p=order_seq(order_loca);
[fre_pick1,fre_loca]=min(abs(FST{order_p}.fn-fre_pick));
h2=scatter(FST{order_p}.fn(fre_loca),min(yfrf)+istab*(order_p-n_min),'r');

h3=line(FST{order_p}.fn(fre_loca)*[1 1],[min(yfrf),max(yfrf)],'Color','k');
hque1=questdlg(['The point you are looking for£¿'],['Verification'],'yes','no','yes');
if strcmp(hque1,'no')
    delete(h2)
    delete(h3)
else 
fst_sel=[fst_sel,FST{order_p}.fn(fre_loca)];
dst_sel=[dst_sel,FST{order_p}.dr(fre_loca)];
end

    end
    hque=questdlg('Pick another stable pole?','pick point','yes','no','yes');
end  
[fst_sel,seq]=sort(fst_sel);
dst_sel=dst_sel(seq);
