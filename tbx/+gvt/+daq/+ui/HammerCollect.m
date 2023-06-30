function HammerCollect(obj,event)

counter = obj.Trig.idx;

recSize = length(obj.uiFig.axes{1}.Data{1}.XData);

tNew = event.TimeStamps; %incoming time stamps

if obj.Trig.isActive %trigger is already on...update the trig data block

    collectSize = length(tNew); %length of new data block
    trigT0 = obj.Data.TriggerData.T;
    trigY0 = obj.Data.TriggerData.Y;

    space = min([length(find(isnan(trigT0))), collectSize]);

    %new time vector
    trigT =...
        [trigT0(1:counter-1); tNew(1:space,:); NaN(recSize-counter-space+1,1)];

    trigY = zeros(size(trigY0));

    %update all lines....
    for inpt=1:length(event.Data(1,:))
        YNew = event.Data(:,inpt);
        Y0 = trigY0(:,inpt);
        Y0 = Y0(:);
        trigY(:,inpt) = [Y0(1:counter-1); YNew(1:space,:); NaN(recSize-counter-space+1,1)];        
    end

    obj.Trig.idx=counter+space;
    obj.Data.TriggerData.Y = trigY;
    obj.Data.TriggerData.T = trigT;

    if length(find(isnan(trigT0)))<=collectSize %if the required size is acquired...

        delete(obj.tempInptFig); %delete temporary strike figure

        obj.Trig.isActive = false; %set trigger off
        obj.Trig.idx = 1; %recorde4r index to 1

        rep = obj.triggerFig.rep_idx; %repetition index
        TT = obj.Data.TriggerData.T; %recorded trig data - time stamps

        %input FFT...
        [frq,inAmp] = getFFT(TT,obj.Data.TriggerData.Y(:,obj.Trig.Chan_idx));

        for inpt=1:length(event.Data(1,:))
            if inpt~=obj.Trig.Chan_idx %if not the hammer chan
                [frq,outAmp] = getFFT(TT,obj.Data.TriggerData.Y(:,inpt));
                obj.triggerFig.axes{1}.Data{rep,inpt} = ...
                    plot(obj.triggerFig.axes{1}.ax,...
                    frq, abs(outAmp./inAmp), '-','LineWidth',1,...
                    'Color', obj.inptPlotClr{inpt});
                hold(obj.triggerFig.axes{1}.ax, 'on');               
            end
            YY(:,inpt) = obj.Data.TriggerData.Y(:,inpt);
        end
        if rep==1
            Data{rep}.T = TT;
            Data{rep}.Y = YY;
        else
            Data = obj.triggerFig.Data;
            Data{rep}.T = TT;
            Data{rep}.Y = YY;
        end
        obj.triggerFig.Data = Data;
        obj.triggerFig.rep_idx = rep+1;
        %setTrigAvg(globObj)
    end

else %just got triggered.....

    [~,trigIncid_idx] = max(event.Data(:,obj.Trig.Chan_idx));
    trigIncid = tNew(trigIncid_idx);
    [~,dataInit_idx] = min(abs(tNew-trigIncid+obj.Trig.Buffer));

    collectSize = length(tNew(dataInit_idx:end,1)); %length of new data block

    trigT =...
        [tNew(dataInit_idx:end,:); NaN(recSize-collectSize,1)];

    for inpt=1:length(event.Data(1,:))
        YNew = event.Data(dataInit_idx:end,inpt);
        trigY(:,inpt) = [YNew; NaN(recSize-collectSize,1)];
    end

    obj.tempInptFig = figure;
    plot(tNew, event.Data(:,obj.Trig.Chan_idx));

    obj.Trig.idx = collectSize+1;
    obj.Trig.isActive = true;
    obj.Data.TriggerData.Y = trigY;
    obj.Data.TriggerData.T = trigT;
end
set(obj.uiFig.fig, 'UserData', obj);

%% trigger averaging functions....

function setTrigAvg(globObj)
inptN = length(globObj.uiFig.axes{1}.Data);

switch globObj.Trig.Type
    case 'Hammer'
        for inpt = 1:inptN
            if globObj.triggerFig.rep_idx>1
                if inpt~=globObj.Trig.Chan_idx %if not the hammer chan
                    for rep=1:globObj.triggerFig.rep_idx-1
                        frq(:,rep) = globObj.triggerFig.axes{1}.Data{rep,inpt}.XData;
                        amp(:,rep) = globObj.triggerFig.axes{1}.Data{rep,inpt}.YData;
                    end
                    amp_avg = sum(amp,2)./(globObj.triggerFig.rep_idx-1);

                    if globObj.triggerFig.rep_idx==2
                        globObj.triggerFig.axes{1}.avgData{inpt} =...
                            plot(globObj.triggerFig.axes{1}.ax,...
                            frq(:,end), amp_avg, 'k-');
                        hold(globObj.triggerFig.axes{1}.ax, 'on');
                    else
                        set(globObj.triggerFig.axes{1}.avgData{inpt},...
                            'YData', amp_avg);
                    end
                end

            else
                if inpt~=globObj.Trig.Chan_idx %if not the hammer chan
                    delete(globObj.triggerFig.axes{1}.avgData{inpt});
                end
            end
        end
end
set(globObj.uiFig.fig, 'UserData', globObj);



%%
function [frq,amp] = getFFT(t,q)
    dt = t(2)-t(1);
    Fs = 1/dt;                 %Sampling frequency
    L_sig = (t(end)-t(1))/dt;  % Length of signal
    t = (0:L_sig-1)*dt;        % Time vector

    Y = fft(q);   %Fourier transform
    P2 = abs(Y/L_sig);
    P1 = P2(1:L_sig/2+1);
    P1(2:end-1) = 2*P1(2:end-1);

    frq = Fs*(0:(L_sig/2))/L_sig; amp = abs(P1);

