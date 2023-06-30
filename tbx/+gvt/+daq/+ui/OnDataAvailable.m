function OnDataAvailable(obj,src,event)
%ONDATAAVAILIBLE Summary of this function goes here
%   Detailed explanation goes here
obj = obj.uiFig.fig.UserData;

%existing Data on plot...time
T0 = obj.uiFig.axes{1}.Data{1}.XData;
T0=T0(:);

counter = obj.Data.counter; %row index for new datablock 
collectSize = length(event.Data(:,1)); %length of new data block
recSize = length(T0); %plot's data record size

%check if the plot needs to be reset (..to NaNs)
if obj.Data.resetTag
    reset = event.TimeStamps(1); %offset time
    obj.Data.resetTime = reset;
    obj.Data.resetTag = false;
        for inpt=1:length(event.Data(1,:))
            set(obj.uiFig.axes{1}.Data{inpt},'XData', NaN(recSize,1),...
                'YData', NaN(recSize,1));
        end
else
    reset = obj.Data.resetTime; %existing offset time
end

tNew = event.TimeStamps-reset; %in coming time stamps..with offset..

%fool proof data block sizing...find the remaining space (NaN spaces) in the plot 
space = min([length(find(isnan(T0))), collectSize]);

%new time vector
T = [T0(1:counter-1); tNew(1:space,:); NaN(recSize-counter-space+1,1)];

%update all lines....
for inpt=1:length(event.Data(1,:))
    YNew = event.Data(:,inpt);
    Y0 = obj.uiFig.axes{1}.Data{inpt}.YData;
    Y0 = Y0(:);
    Y = [Y0(1:counter-1); YNew(1:space,:); NaN(recSize-counter-space+1,1)];

    set(obj.uiFig.axes{1}.Data{inpt},'XData', T, 'YData', Y);
    obj.Data.counter=counter+space;
end

%if the plot is now filled...set the re-set tag for the next incoming block
if length(find(isnan(T0)))<=collectSize 
    obj.Data.resetTag = true;
    obj.Data.counter=1;
end

set(obj.uiFig.fig, 'UserData', obj);

%detect if any triggers are requested
if obj.Trig.Enabled

    thresholdTest = max(event.Data(:,obj.Trig.Chan_idx))>obj.Trig.Threshold;
    switch obj.Trig.Type
        case 'Hammer'
            %if either the threshold in exceeded for the first time or is
            %being recorded....run the hammer fcn
            if thresholdTest || obj.Trig.isActive
                gvt.daq.ui.HammerCollect(obj,event);
            end
    end
end


