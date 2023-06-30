function buttonCalls(inpt,var)
%BUTTONCALLS button pressed actions
%   Detailed explanation goes here
obj = inpt.UserData.uiFig.fig.UserData;
bttn_id = inpt.Text;
switch bttn_id

    case 'Start'
        s=obj.ni;
        s.startBackground();

    case 'Stop'
        s=obj.ni;
        s.stop();

        obj.Data.resetTag = true;
        obj.Data.counter=1;
        set(obj.uiFig.fig, 'UserData', obj);

    case 'TapLcns'
        gvt.daq.ui.tapLocations(obj);

    case 'Save'
        s=obj.ni;
        s.stop();
        obj.Data.resetTag = true;
        obj.Data.counter=1;

        clc;

        fn = obj.Data.expr.tapLcn_ID;
        [lcn,tf] = listdlg('PromptString',{'Select case:'},...
            'SelectionMode','single','ListString',fn);

        obj.RecData{lcn} = obj.triggerFig.Data;
        obj.testedIdx(lcn) = 1;

        [repN,inptN] = size(obj.triggerFig.axes{1}.Data);
        for rep=1:repN
            for inpt=1:inptN
                delete(obj.triggerFig.axes{1}.Data{rep,inpt});
            end
        end
        Data = {};
        obj.triggerFig.Data = Data;
        obj.triggerFig.rep_idx=1;

        recData = obj.RecData;
        recDataSize = size(recData);
%         title(globObj.uiFig.axes{1}.ax,...
%             ['Saved Data: ', num2str(recDataSize(1)), ' parameters, '...
%             num2str(recDataSize(2)), ' locations']);

        set(obj.uiFig.fig, 'UserData', obj);
        %setTrigAvg(globObj)

    case 'Delete'
        [~,inptN] = size(obj.triggerFig.axes{1}.Data);
        for inpt=1:inptN
            delete(obj.triggerFig.axes{1}.Data{obj.triggerFig.rep_idx-1,inpt});
        end

        Data = obj.triggerFig.Data;
        DataNew = {};
        for rep=1:obj.triggerFig.rep_idx-2
            DataNew{rep} = Data{rep};
        end
        obj.triggerFig.Data = DataNew;
        obj.triggerFig.rep_idx=obj.triggerFig.rep_idx-1;
        set(obj.uiFig.fig, 'UserData', obj);
        %setTrigAvg(globObj)

    case 'Export'
        Data = obj.RecData;
        dataTags = obj.Data.inptTags;
        expr = obj.Data.expr;
        time_now = datestr(now,'yy_mm_dd_HH_MM_SS');
        fi_id = ['NiData_',time_now,'.mat'];
        save(fi_id,'Data', 'dataTags','expr')
        set(obj.uiFig.fig, 'UserData', obj);
end

