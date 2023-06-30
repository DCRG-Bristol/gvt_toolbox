classdef Trig
    %TRIG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Enabled logical = true; %is a trigger needed?
        Type string
        Threshold = 0.002; %threshold exceed condition
        Chan_idx = 1; %this channel is tested for trigger conditions: MUST BE 1 FOR POSTPROC TOOL
        Buffer = 0.1; %collection initialised at t=trigger time - buffer
        idx = 1; % counter for triggers
        isActive logical = false % helps code identify when to has been triggered
    end
    
    methods
        function obj = Trig(Type)
            arguments
                Type string = Hammer
            end
            obj.Type = Type;
        end
    end
end

