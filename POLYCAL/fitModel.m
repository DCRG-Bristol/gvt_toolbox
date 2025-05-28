function [mod_FRQ, mod_Damp, FRF_orig, FRF_out, FRQ_orig, FRQ_out, ms] = fitModel(inpt)

select_FRF=3;% 1 for receptance;2 for mobility; 3 for accelerance

for rpt = 1:length(inpt)
    data = inpt{rpt};
    for ii=1:size(data,2)
        tt=data{1,ii}(:,1);
        x=data{1,ii}(:,2);%force
        inptNum = length(data{1,ii}(1,:))-2;
        for idx=1:length(data{1,ii}(1,:))-2
            y(:,idx)=data{1,ii}(:,2+idx);%acceleration
        end
        Fs=1/(tt(2)-tt(1));
        winlen=size(x,1);

        [frq,P_in,amp] = getFFT(tt,x);
        for idx=1:length(y(1,:))
            [frq,P_o,amp] = getFFT(tt,y(:,idx));
            Txy(:,idx) = P_o./P_in;
        end
        Wx = frq(:);
        switch select_FRF
            case 1
                Txy=Txy./(-((2*pi)*Wx).^2);%%transform to receptance
            case 2
                Txy=Txy./(j*((2*pi)*Wx));%%transform to mobility
            case 3
        end
        for idx=1:inptNum
            if rpt==1
                FRF_temp(:,idx,ii)=Txy(:,idx);
            else
                FRF_temp(:,idx,ii)=FRF_temp(:,idx,ii)+Txy(:,idx);
            end
        end
    end
end

for idx=1:inptNum
    for ii=1:size(data,2)
        FRF(:,idx,ii) = FRF_temp(:,idx,ii)./length(inpt);
    end
end

    num=1;
    fre_rang=[0.5,50];
    fvec=Wx(2:end);
    frf=FRF(2:end,:,1);
    max_order=65;
    min_order=15; %max_order-30;

    %% polyMAX
    [fvec1, FRF1] = select_frf(fvec, frf, fre_rang);
    [fn,dr,Pfrf]=polymax_frf(FRF1,fvec1,max_order);

    order_rang=[min_order,max_order];
    for idx=1:inptNum
        if idx==1
            totFRF(:,1,1) = FRF1(:,idx,1);
        else
            totFRF(:,1,1) = totFRF(:,1,1)+FRF1(:,idx,1);
        end
    end
    [fn1,dr1,FST, hand]=stabe_poles(fvec1,FRF1,order_rang);

    % % auto select the stable poles
    %[fst, dst] = auto_select_stabchart(FST, 0.01, 5) ;

    [fst, dst] = manual_select_stabchart(FST,totFRF,order_rang);
    close(hand);

    %delete(tempF)

    % calcul of residues and modal frf using selected poles
    [ms, frfm] = lsfd(fvec1*2*pi, Pfrf, fst, dst) ;

    if length(fst)<2
        for jj=length(fst)+1:2
            ms(jj,:,1)=NaN(2,1);
            fst(jj) = NaN;
            dst(jj) = NaN;
        end
    end

    FRF_out = Pfrf(:,1); FRF_orig = FRF(2:end,1,num);
    FRQ_out = fvec1; FRQ_orig = Wx(2:end);
    mod_FRQ = fst; mod_Damp = dst;


    function [frq,P1,amp] = getFFT(t,q)
    dt = t(2)-t(1);
    Fs = 1/dt;                 %Sampling frequency
    L_sig = (t(end)-t(1))/dt;  % Length of signal
    t = (0:L_sig-1)*dt;        % Time vector

    Y = fft(q);   %Fourier transform
    P2 = Y/L_sig;
    P1 = P2(1:L_sig/2+1);
    P1(2:end-1) = 2*P1(2:end-1);

    frq = Fs*(0:(L_sig/2))/L_sig; amp = abs(P1);
end

end
