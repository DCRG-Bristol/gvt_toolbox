function [mod_FRQ, mod_Damp, FRF_orig, FRF_out, FRQ_orig, FRQ_out] = fitModel(inpt)

select_FRF=3;% 1 for receptance;2 for mobility; 3 for accelerance

for rpt = 1:length(inpt)
    data = inpt{1};
    for ii=1:size(data,2)
        tt=data{1,ii}(:,1);
        x=data{1,ii}(:,2);%force
        y=data{1,ii}(:,3);%acceleration
        Fs=1/(tt(2)-tt(1));
        winlen=size(x,1);
        [Txy,Wx] = modalfrf(x,y,Fs,winlen,'Estimator','hv','Sensor','acc');%calculate acc FRF
        %Ff=fft(x);Acc=fft(y);Hxy=Acc./Ff;Txy=Hxy(1:end/2);Wx1=linspace(0,Fs,length(tt));Wx=Wx1(1:end/2);% raw acc FRF
        switch select_FRF
            case 1
                Txy=Txy./(-((2*pi)*Wx).^2);%%transform to receptance
            case 2
                Txy=Txy./(j*((2*pi)*Wx));%%transform to mobility
            case 3
        end
        if rpt==1, FRF_temp(:,1,ii)=Txy; else
            FRF_temp(:,1,ii)=FRF_temp(:,1,ii)+Txy;
        end
    end
end

for ii=1:size(data,2)
    FRF(:,1,ii) = FRF_temp(:,1,ii)./length(inpt);
end

    num=1;
    fre_rang=[5,100];
    fvec=Wx(2:end);
    frf=FRF(2:end,:,num);
    max_order=80;
    min_order=20;%max_order-30;

    %% polyMAX
    [fvec1, FRF1] = select_frf(fvec, frf, fre_rang);
    [fn,dr,Pfrf]=polymax_frf(FRF1,fvec1,max_order);

    order_rang=[min_order,max_order];
    [fn1,dr1,FST, hand]=stabe_poles(fvec1,FRF1(:,1,1),order_rang);

    % % auto select the stable poles
    %[fst, dst] = auto_select_stabchart(FST, 0.01, 25) ;

    [fst, dst] = manual_select_stabchart(FST,FRF1,order_rang);
    close(hand);

    % calcul of residues and modal frf using selected poles
    [ms, frfm] = lsfd(fvec1*2*pi, Pfrf, fst, dst) ;

    FRF_out = Pfrf(:,1); FRF_orig = FRF(2:end,1,num);
    FRQ_out = fvec1; FRQ_orig = Wx(2:end);
    mod_FRQ = fst; mod_Damp = dst;


end
