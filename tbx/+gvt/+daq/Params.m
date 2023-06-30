classdef Params < handle
    %PARAMS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TapLoc (:,3) double 
        TapLocID string
        TapDir (:,3) double

        testedIdx double
    end

    properties
        CollectionPeriod = 15; %collection period
        daqUpdateBlock = 128; %update batch size
        SampleRate = 2000; %[Hz]
    end

    properties
        Trig gvt.dag.Trig
    end

    properties
        inptNum
        inptTags
        inptChans
        inptPlotClr
    end

    %UI
    properties
        uiFig
        triggerFig
        tempInptFig
        Data = struct();
        ni
        RecData
    end

    properties(Dependent)
        DataSize
    end
    methods
        function val = get.DataSize(obj)
            val = obj.CollectionPeriod*obj.SampleRate;
        end
    end
    
    methods
        function obj = Params(TapLoc,TapLocID,TapDir)
            %PARAMS Construct an instance of this class
            %   Detailed explanation goes here
            obj.TapLoc = TapLoc;
            obj.TapLocID = TapLocID;
            obj.TapDir = TapDir;
            obj.testedIdx = zeros(1,length(TapLocID));
        end
        
        function outputArg = StartUI(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            acqObjTest=findobj('uifigure','Acquisition Tool');
            if ~isempty(acqObjTest)
                disp('Error: Acquisition Already Running');
            end
            obj.uiFig.fig = uifigure('Name', 'Acquisition Tool');
            %set up axes~~~~~~~~~~~~~~~~~~~~~~~~~~~
            obj.uiFig.axes{1}.ax = uiaxes('Parent',obj.uiFig.fig,...
                'Position', [50, 10, 400, 350]);
            xlabel(obj.uiFig.axes{1}.ax, 'Time, [s]');
            %set up pseudo Data~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            for inpt=1:obj.inptNum
                obj.uiFig.axes{1}.Data{inpt} = plot(obj.uiFig.axes{1}.ax,...
                    NaN(DataSize,1), NaN(DataSize,1), '-','LineWidth',1,...
                    'Color', obj.inptPlotClr{inpt});
                hold(obj.uiFig.axes{1}.ax, 'on');
                set(obj.uiFig.axes{1}.Data{inpt}, 'buttonDownFcn',...
                    @(in1,in2)(lineClickFcn(obj,in1,in2)));
            end
            set(obj.uiFig.axes{1}.ax, 'Xlim', [0,obj.CollectionPeriod]);
            legend(obj.uiFig.axes{1}.ax, obj.inptTags,...
                'location', 'southOutside', 'orientation', 'horizontal');
            %acquisition updating triggers~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            obj.Data.resetTime=0; %time stamp offset-initial
            obj.Data.resetTag = false; %should the figure be re-set?
            obj.Data.counter=1; %index to insert the next incoming block
        
            obj.Trig.isActive = false;
            obj.Data.expr = struct('tapLcn',obj.TapLoc,'tapLcn_ID',obj.TapLocID,'tapDir',obj.TapDir);
            obj.Data.inptTags = obj.inptTags;
            if obj.Trig.Enabled
                %title(globObj.uiFig.axes{1}.ax, ['Saved Data: 0 parameters, 0 locations']);
                obj.triggerFig.fig = uifigure('Name', 'Trigger Acquisition');
        
                obj.triggerFig.axes{1}.ax = uiaxes('Parent',obj.triggerFig.fig,...
                    'Position', [50, 50, 400, 300]);
                set(obj.triggerFig.axes{1}.ax, 'Yscale', 'log');
        
                obj.triggerFig.bttns{1} =uibutton('parent', obj.triggerFig.fig,...
                    'userData', obj, 'buttonPushedFcn', @gvt.daq.ui.OnButtonClick,...
                    'text', 'Save','position',[100, 375, 60, 20]);
        
                obj.triggerFig.bttns{2} =uibutton('parent', obj.triggerFig.fig,...
                    'userData', obj, 'buttonPushedFcn', @gvt.daq.ui.OnButtonClick,...
                    'text', 'Delete','position',[200, 375, 60, 20]);
        
                obj.triggerFig.rep_idx=1;
            end
            %set up user Buttons.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            obj.uiFig.bttns{1} =uibutton('parent', obj.uiFig.fig,...
                'userData', obj, 'buttonPushedFcn', @gvt.daq.ui.OnButtonClick,...
                'text', 'Start','position',[100, 375, 60, 20]);
        
            obj.uiFig.bttns{2} =uibutton('parent', obj.uiFig.fig,...
                'userData', obj, 'buttonPushedFcn', @gvt.daq.ui.OnButtonClick,...
                'text', 'Stop','position',[200, 375, 60, 20]);
        
            obj.uiFig.bttns{3} =uibutton('parent', obj.uiFig.fig,...
                'userData', obj, 'buttonPushedFcn', @gvt.daq.ui.OnButtonClick,...
                'text', 'Export','position',[300, 375, 60, 20]);
        
            obj.uiFig.bttns{4} =uibutton('parent', obj.uiFig.fig,...
                'userData', obj, 'buttonPushedFcn', @gvt.daq.ui.OnButtonClick,...
                'text', 'TapLcns','position',[400, 375, 60, 20]);
            %set up DAQ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            devs=daqlist;
            s = daq('ni'); % create session
            for inpt=1:obj.inptNum
                s.addAnalogInputChannel(devs(1).ID,obj.inptChans{inpt},'IEPE');
                s.Channels(inpt).Name = obj.inptTags{inpt};
            end
            s.addlistener('DataAvailable',@(src,event)(OnDataAvailable(obj,src,event)));
            set(s,'NotifyWhenDataAvailableExceeds', obj.daqUpdateBlock,...
                'IsContinuous',true);
            s.Rate = obj.SampleRate;
            obj.ni = s;
            set(obj.uiFig.fig, 'UserData', obj);
        end

        function lineClickFcn(obj, in1,in2)
            figure;
            for inpt=1:length(obj.uiFig.axes{1}.Data)
                tData = obj.uiFig.axes{1}.Data{inpt}.XData;
                yData = obj.uiFig.axes{1}.Data{inpt}.YData;
            
                [frq,amp] = getFFT(tData(1:end-length(find(isnan(tData)))),...
                    yData(1:end-length(find(isnan(tData)))));
            
                plot(frq,amp, 'lineWidth', 1,...
                    'color', obj.inptPlotClr{inpt}); hold on;
            
            end
            xlim([0, 75]); grid minor; set(gca, 'yscale', 'log');
        end
    end
end

