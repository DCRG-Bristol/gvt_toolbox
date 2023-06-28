function daqTool(argin)

%% pre-determined tap positions.....

%tapping locations...
expr.tapLcn = [...
    %X, Y, Z
    20, 0, 0;...
    -38, 0, 0;...
    -70.5, 0, 0;...
    -86.5, 28, 0;...
    -86.5, 0, -17.5;...
    -86.5, -28, 0;...
    20, 0, 0;...
    -38, 0, 0;...
    -70.5, 0, 0;...
    -86.5, 28, 0;...
    -86.5, 0, -17.5;...
    -86.5, -28, 0];

%names for tapping locations....must have the same number of entries as
%rows in expr.tapLcn
expr.tapLcn_ID = {'C1_v', 'C2_v', 'C3_v', 'R1_v', 'V_v', 'R2_v',...
    'C1_h', 'C2_h', 'C3_h', 'R1_h', 'V_h', 'R2_h'};

%tapping directions.....must have the same number of rows as
%rows in expr.tapLcn
expr.tapDir = [...
    %I, J, K
    0, 0, 1;... % direction for location #1
    0, 0, 1;... % direction for location #2,... each row gives [i,j,k] 
    0, 0, 1;...
    0, 0, 1;...
    0, 0, 1;...
    0, 0, 1;...
    0, 1, 0;... % direction for location #1
    0, 1, 0;... % direction for location #2,... each row gives [i,j,k] 
    0, 1, 0;...
    0, 1, 0;...
    0, 1, 0;...
    0, -1, 0];


globObj.testedIdx = zeros(1,length(expr.tapLcn_ID));

%acquisition parameters...
userPrd = 15; %collection period
daqUpdateBlock = 128; %update batch size
sampRate = 2000; %[Hz]
DataSize = userPrd*sampRate; %size of collection

%sensor configurations...
inptNum = 3; %number of input signals...
inptTags = {'Hammer', 'OOP', 'IP'};
chans = {'ai0', 'ai2', 'ai3'}; %input channels..
globObj.inptPlotClr = {'k', 'b', 'r'}; %signal plot colors....

%acquisition type: trigger settings..
trig=true; %is a trigger needed?
trigType = 'Hammer';
trigThreshold = 0.002; %threshold exceed condition
trigChan_idx=1; %this channel is tested for trigger conditions: MUST BE 1 FOR POSTPROC TOOL
trigBuffer = 0.1; %collection initialised at t=trigger time - buffer

%% set up UI....
acqObjTest=findobj('uifigure','Acquisition Tool');
if isempty(acqObjTest)
    globObj.uiFig.fig = uifigure('Name', 'Acquisition Tool');

    %set up axes~~~~~~~~~~~~~~~~~~~~~~~~~~~
    globObj.uiFig.axes{1}.ax = uiaxes('Parent',globObj.uiFig.fig,...
        'Position', [50, 10, 400, 350]);
    xlabel(globObj.uiFig.axes{1}.ax, 'Time, [s]');

    %set up pseudo Data~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    for inpt=1:inptNum
        globObj.uiFig.axes{1}.Data{inpt} = plot(globObj.uiFig.axes{1}.ax,...
            NaN(DataSize,1), NaN(DataSize,1), '-','LineWidth',1,...
            'Color', globObj.inptPlotClr{inpt});
        hold(globObj.uiFig.axes{1}.ax, 'on');

        set(globObj.uiFig.axes{1}.Data{inpt}, 'buttonDownFcn',...
            @(in1,in2)(lineClickFcn(globObj,in1,in2)));
    end
    set(globObj.uiFig.axes{1}.ax, 'Xlim', [0,userPrd]);
    legend(globObj.uiFig.axes{1}.ax, inptTags,...
        'location', 'southOutside', 'orientation', 'horizontal');

    %acquisition updating triggers~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    globObj.Data.resetTime=0; %time stamp offset-initial
    globObj.Data.resetTag = false; %should the figure be re-set?
    globObj.Data.counter=1; %index to insert the next incoming block

    globObj.Data.trig = trig;
    globObj.Data.trigBuffer = trigBuffer;
    globObj.Data.trigType = trigType;
    globObj.Data.isTrigOn = false;
    globObj.Data.trig_idx = 1;
    globObj.Data.trigChan_idx = trigChan_idx;
    globObj.Data.trigThreshold = trigThreshold;
    globObj.Data.expr = expr;
    globObj.Data.inptTags = inptTags;

    if trig
        %title(globObj.uiFig.axes{1}.ax, ['Saved Data: 0 parameters, 0 locations']);
        globObj.triggerFig.fig = uifigure('Name', 'Trigger Acquisition');

        globObj.triggerFig.axes{1}.ax = uiaxes('Parent',globObj.triggerFig.fig,...
            'Position', [50, 50, 400, 300]);
        set(globObj.triggerFig.axes{1}.ax, 'Yscale', 'log');

        globObj.triggerFig.bttns{1} =uibutton('parent', globObj.triggerFig.fig,...
            'userData', globObj, 'buttonPushedFcn', @buttonCalls,...
            'text', 'Save','position',[100, 375, 60, 20]);

        globObj.triggerFig.bttns{2} =uibutton('parent', globObj.triggerFig.fig,...
            'userData', globObj, 'buttonPushedFcn', @buttonCalls,...
            'text', 'Delete','position',[200, 375, 60, 20]);

        globObj.triggerFig.rep_idx=1;
    end

    %set up user Buttons.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    globObj.uiFig.bttns{1} =uibutton('parent', globObj.uiFig.fig,...
        'userData', globObj, 'buttonPushedFcn', @buttonCalls,...
        'text', 'Start','position',[100, 375, 60, 20]);

    globObj.uiFig.bttns{2} =uibutton('parent', globObj.uiFig.fig,...
        'userData', globObj, 'buttonPushedFcn', @buttonCalls,...
        'text', 'Stop','position',[200, 375, 60, 20]);

    globObj.uiFig.bttns{3} =uibutton('parent', globObj.uiFig.fig,...
        'userData', globObj, 'buttonPushedFcn', @buttonCalls,...
        'text', 'Export','position',[300, 375, 60, 20]);

    globObj.uiFig.bttns{4} =uibutton('parent', globObj.uiFig.fig,...
        'userData', globObj, 'buttonPushedFcn', @buttonCalls,...
        'text', 'TapLcns','position',[400, 375, 60, 20]);

    %set up DAQ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    devs=daq.getDevices;
    s = daq.createSession('ni'); % create session
    for inpt=1:inptNum
        s.addAnalogInputChannel(devs(1).ID,chans{inpt},'IEPE');
        s.Channels(inpt).Name = inptTags{inpt};
    end
    s.addlistener('DataAvailable',@(src,event)(dataAvail(globObj,src,event)));
    set(s,'NotifyWhenDataAvailableExceeds', daqUpdateBlock,...
        'IsContinuous',true);
    s.Rate = sampRate;
    globObj.ni = s;

    set(globObj.uiFig.fig, 'UserData', globObj);
else
    disp('Error: Acquisition Already Running');
end

%% Button pressed actions

function buttonCalls(inpt,var)
globObj = inpt.UserData.uiFig.fig.UserData;
bttn_id = inpt.Text;
switch bttn_id

    case 'Start'
        s=globObj.ni;
        s.startBackground();

    case 'Stop'
        s=globObj.ni;
        s.stop();

        globObj.Data.resetTag = true;
        globObj.Data.counter=1;
        set(globObj.uiFig.fig, 'UserData', globObj);

    case 'TapLcns'
        tapLocations(globObj);

    case 'Save'
        s=globObj.ni;
        s.stop();
        globObj.Data.resetTag = true;
        globObj.Data.counter=1;

        clc;

        fn = globObj.Data.expr.tapLcn_ID;
        [lcn,tf] = listdlg('PromptString',{'Select case:'},...
            'SelectionMode','single','ListString',fn);

        globObj.RecData{lcn} = globObj.triggerFig.Data;
        globObj.testedIdx(lcn) = 1;

        [repN,inptN] = size(globObj.triggerFig.axes{1}.Data);
        for rep=1:repN
            for inpt=1:inptN
                delete(globObj.triggerFig.axes{1}.Data{rep,inpt});
            end
        end
        Data = {};
        globObj.triggerFig.Data = Data;
        globObj.triggerFig.rep_idx=1;

        recData = globObj.RecData;
        recDataSize = size(recData);
%         title(globObj.uiFig.axes{1}.ax,...
%             ['Saved Data: ', num2str(recDataSize(1)), ' parameters, '...
%             num2str(recDataSize(2)), ' locations']);

        set(globObj.uiFig.fig, 'UserData', globObj);
        %setTrigAvg(globObj)

    case 'Delete'
        [~,inptN] = size(globObj.triggerFig.axes{1}.Data);
        for inpt=1:inptN
            delete(globObj.triggerFig.axes{1}.Data{globObj.triggerFig.rep_idx-1,inpt});
        end

        Data = globObj.triggerFig.Data;
        DataNew = {};
        for rep=1:globObj.triggerFig.rep_idx-2
            DataNew{rep} = Data{rep};
        end
        globObj.triggerFig.Data = DataNew;
        globObj.triggerFig.rep_idx=globObj.triggerFig.rep_idx-1;
        set(globObj.uiFig.fig, 'UserData', globObj);
        %setTrigAvg(globObj)

    case 'Export'
        Data = globObj.RecData;
        dataTags = globObj.Data.inptTags;
        expr = globObj.Data.expr;
        time_now = datestr(now,'yy_mm_dd_HH_MM_SS');
        fi_id = ['NiData_',time_now,'.mat'];
        save(fi_id,'Data', 'dataTags','expr')
        set(globObj.uiFig.fig, 'UserData', globObj);
end

%%
function lineClickFcn(globObj, in1,in2)
globObj = globObj.uiFig.fig.UserData;
figure;
for inpt=1:length(globObj.uiFig.axes{1}.Data)
    tData = globObj.uiFig.axes{1}.Data{inpt}.XData;
    yData = globObj.uiFig.axes{1}.Data{inpt}.YData;

    [frq,amp] = getFFT(tData(1:end-length(find(isnan(tData)))),...
        yData(1:end-length(find(isnan(tData)))));

    plot(frq,amp, 'lineWidth', 1,...
        'color', globObj.inptPlotClr{inpt}); hold on;

end
xlim([0, 75]); grid minor; set(gca, 'yscale', 'log');

%%
function dataAvail(globObj,src,event)
globObj = globObj.uiFig.fig.UserData;

%existing Data on plot...time
T0 = globObj.uiFig.axes{1}.Data{1}.XData;
T0=T0(:);

counter = globObj.Data.counter; %row index for new datablock 
collectSize = length(event.Data(:,1)); %length of new data block
recSize = length(T0); %plot's data record size

%check if the plot needs to be reset (..to NaNs)
if globObj.Data.resetTag
    reset = event.TimeStamps(1); %offset time
    globObj.Data.resetTime = reset;
    globObj.Data.resetTag = false;
        for inpt=1:length(event.Data(1,:))
            set(globObj.uiFig.axes{1}.Data{inpt},'XData', NaN(recSize,1),...
                'YData', NaN(recSize,1));
        end
else
    reset = globObj.Data.resetTime; %existing offset time
end

tNew = event.TimeStamps-reset; %in coming time stamps..with offset..

%fool proof data block sizing...find the remaining space (NaN spaces) in the plot 
space = min([length(find(isnan(T0))), collectSize]);

%new time vector
T = [T0(1:counter-1); tNew(1:space,:); NaN(recSize-counter-space+1,1)];

%update all lines....
for inpt=1:length(event.Data(1,:))
    YNew = event.Data(:,inpt);
    Y0 = globObj.uiFig.axes{1}.Data{inpt}.YData;
    Y0 = Y0(:);
    Y = [Y0(1:counter-1); YNew(1:space,:); NaN(recSize-counter-space+1,1)];

    set(globObj.uiFig.axes{1}.Data{inpt},'XData', T, 'YData', Y);
    globObj.Data.counter=counter+space;
end

%if the plot is now filled...set the re-set tag for the next incoming block
if length(find(isnan(T0)))<=collectSize 
    globObj.Data.resetTag = true;
    globObj.Data.counter=1;
end

set(globObj.uiFig.fig, 'UserData', globObj);

%detect if any triggers are requested
if globObj.Data.trig

    trigType = globObj.Data.trigType;
    isTrigOn = globObj.Data.isTrigOn;
    trigChan_idx = globObj.Data.trigChan_idx;
    trigThreshold = globObj.Data.trigThreshold;

    thresholdTest = max(event.Data(:,trigChan_idx))>trigThreshold;

    switch trigType
        case 'Hammer'
            %if either the threshold in exceeded for the first time or is
            %being recorded....run the hammer fcn
            if thresholdTest || isTrigOn
                HammerCollect(globObj,event);
            end
    end

end


%%
function HammerCollect(globObj,event)

isTrigOn = globObj.Data.isTrigOn;
counter = globObj.Data.trig_idx;
trigChan_idx = globObj.Data.trigChan_idx;
trigBffr = globObj.Data.trigBuffer;

recSize = length(globObj.uiFig.axes{1}.Data{1}.XData);

tNew = event.TimeStamps; %incoming time stamps

if isTrigOn %trigger is already on...update the trig data block

    collectSize = length(tNew); %length of new data block
    trigT0 = globObj.Data.TriggerData.T;
    trigY0 = globObj.Data.TriggerData.Y;

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

    globObj.Data.trig_idx=counter+space;
    globObj.Data.TriggerData.Y = trigY;
    globObj.Data.TriggerData.T = trigT;

    if length(find(isnan(trigT0)))<=collectSize %if the required size is acquired...

        delete(globObj.tempInptFig); %delete temporary strike figure

        globObj.Data.isTrigOn = false; %set trigger off
        globObj.Data.trig_idx = 1; %recorde4r index to 1

        rep = globObj.triggerFig.rep_idx; %repetition index
        TT = globObj.Data.TriggerData.T; %recorded trig data - time stamps

        %input FFT...
        [frq,inAmp] = getFFT(TT,globObj.Data.TriggerData.Y(:,trigChan_idx));

        for inpt=1:length(event.Data(1,:))
            if inpt~=trigChan_idx %if not the hammer chan
                [frq,outAmp] = getFFT(TT,globObj.Data.TriggerData.Y(:,inpt));
                globObj.triggerFig.axes{1}.Data{rep,inpt} = ...
                    plot(globObj.triggerFig.axes{1}.ax,...
                    frq, abs(outAmp./inAmp), '-','LineWidth',1,...
                    'Color', globObj.inptPlotClr{inpt});
                hold(globObj.triggerFig.axes{1}.ax, 'on');               
            end
            YY(:,inpt) = globObj.Data.TriggerData.Y(:,inpt);
        end
        if rep==1
            Data{rep}.T = TT;
            Data{rep}.Y = YY;
        else
            Data = globObj.triggerFig.Data;
            Data{rep}.T = TT;
            Data{rep}.Y = YY;
        end
        globObj.triggerFig.Data = Data;
        globObj.triggerFig.rep_idx = rep+1;
        %setTrigAvg(globObj)
    end

else %just got triggered.....

    [~,trigIncid_idx] = max(event.Data(:,trigChan_idx));
    trigIncid = tNew(trigIncid_idx);
    [~,dataInit_idx] = min(abs(tNew-trigIncid+trigBffr));

    collectSize = length(tNew(dataInit_idx:end,1)); %length of new data block

    trigT =...
        [tNew(dataInit_idx:end,:); NaN(recSize-collectSize,1)];

    for inpt=1:length(event.Data(1,:))
        YNew = event.Data(dataInit_idx:end,inpt);
        trigY(:,inpt) = [YNew; NaN(recSize-collectSize,1)];
    end

    globObj.tempInptFig = figure;
    plot(tNew, event.Data(:,trigChan_idx));

    globObj.Data.trig_idx = collectSize+1;
    globObj.Data.isTrigOn = true;
    globObj.Data.TriggerData.Y = trigY;
    globObj.Data.TriggerData.T = trigT;
end
set(globObj.uiFig.fig, 'UserData', globObj);

%% trigger averaging functions....

function setTrigAvg(globObj)

trigType = globObj.Data.trigType;
trigChan_idx = globObj.Data.trigChan_idx;
inptN = length(globObj.uiFig.axes{1}.Data);

switch trigType
    case 'Hammer'

        for inpt = 1:inptN
            if globObj.triggerFig.rep_idx>1
                if inpt~=trigChan_idx %if not the hammer chan
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
                if inpt~=trigChan_idx %if not the hammer chan
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

    %% function show tap locations...

function tapLocations(globObj)
globObj = globObj.uiFig.fig.UserData;
expr = globObj.Data.expr;

tapLcn = expr.tapLcn;
tapDir = expr.tapDir;
tapId = expr.tapLcn_ID;

avail = zeros(1,length(tapLcn(:,1)));
count = 1;
for pos=1:length(tapLcn(:,1))
    if avail(1,pos)==0
        diff = sum((tapLcn(pos,:)'-tapLcn').^2, 1);
        idx=find(diff==0);

        for ii=1:length(idx)
            NomShp.X(count) = tapLcn(idx(ii),1);
            NomShp.Y(count) = tapLcn(idx(ii),2);
            NomShp.Z(count) = tapLcn(idx(ii),3);
            NomShp.lcnIdx(idx(ii)) = count;
            avail(1,idx(ii))=1;          
        end
        count=count+1;
    end
        NomShp_rep.X(pos) = tapLcn(pos,1);
        NomShp_rep.Y(pos) = tapLcn(pos,2);
        NomShp_rep.Z(pos) = tapLcn(pos,3);
end

refDim = min(sqrt((NomShp.X(2:end)-NomShp.X(1:end-1)).^2 +...
    (NomShp.Y(2:end)-NomShp.Y(1:end-1)).^2 +...
    (NomShp.Z(2:end)-NomShp.Z(1:end-1)).^2));

figure;
plot3(NomShp.X, NomShp.Y, NomShp.Z, 'k-', 'Marker','x');
hold on
for pos=1:length(tapLcn(:,1))
    disp = 0.5*refDim*tapDir(pos,:)';
    dx = NomShp_rep.X(pos)+[0,disp(1)];
    dy = NomShp_rep.Y(pos)+[0,disp(2)];
    dz = NomShp_rep.Z(pos)+[0,disp(3)];

    istested = globObj.testedIdx(pos);

    if istested==0
        plot3(dx,dy,dz, 'r-', 'marker', '.', 'lineWidth', 2);
        hold on;
    else
        plot3(dx,dy,dz, 'b-', 'marker', '.', 'lineWidth', 2);
        hold on;
    end

    text(dx(2), dy(2), dz(2),...
        tapId{pos}, 'fontweight', 'bold', 'FontSize',7);

    ax = gca; ax.DataAspectRatio = [1, 1, 1];
end

return