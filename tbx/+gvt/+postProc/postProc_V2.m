function postProc_V2(filepath)
arguments
    filepath = ''
end
close all;
clc;
if isfile(filepath)
    file = open(filepath);
else
    [file,path] = uigetfile('*.mat'); 
    file = open(fullfile(path,file));
end
Data = file.Data;
expr = file.expr;

globObj.recType = 'All';
globObj.noMode = 5;
globObj.FR = [1,75];
globObj.decifac = 1;
globObj.windowWidth = 0.005;
globObj.stabDiagRange = [1, 75];
globObj.fftMeth = 'rawFFT'; %'modalfrf'
globObj.Tspan = 7.5;

tapLcn = expr.tapLcn;
globObj.tapDir = expr.tapDir;
globObj.Id = expr.tapLcn_ID;

%get a count of the input chan #
dBlock = Data{1};
globObj.inptNum = dBlock{1}.Y(1,:);

avail = zeros(1,length(Data));
count = 1;
for pos=1:length(Data)
    dblock = Data{pos};
    globObj.Data{pos} = dblock;
    globObj.userSel{pos} = 1:1:length(dblock);

    if avail(1,pos)==0

        diff = sum((tapLcn(pos,:)'-tapLcn').^2, 1);
        idx=find(diff==0);

        for ii=1:length(idx)
            globObj.NomShp.X(count) = tapLcn(idx(ii),1);
            globObj.NomShp.Y(count) = tapLcn(idx(ii),2);
            globObj.NomShp.Z(count) = tapLcn(idx(ii),3);
            globObj.NomShp.lcnIdx(idx(ii)) = count;
            globObj.NomShp.lcnIdent{count}{ii} =...
                globObj.Id{idx(ii)};
            avail(1,idx(ii))=1;          
        end
        count=count+1;
    end
        globObj.NomShp_rep.X(pos) = tapLcn(pos,1);
        globObj.NomShp_rep.Y(pos) = tapLcn(pos,2);
        globObj.NomShp_rep.Z(pos) = tapLcn(pos,3);
end
globObj.uniqPosNum = count-1;

%estimate ref dim for scaling...
globObj.refDim = min(sqrt((globObj.NomShp.X(2:end)-globObj.NomShp.X(1:end-1)).^2 +...
    (globObj.NomShp.Y(2:end)-globObj.NomShp.Y(1:end-1)).^2 +...
    (globObj.NomShp.Z(2:end)-globObj.NomShp.Z(1:end-1)).^2));

%dummy variable for to save modal data....
globObj.procData.modes = {};

%start making th ui figure...
globObj.uiFig.fig = uifigure('Name', 'Post-proc tool');
globObj.uiFig.axes{1}.ax = uiaxes('Parent',globObj.uiFig.fig,...
    'Position', [50, 10, 400, 350]);

plot3(globObj.uiFig.axes{1}.ax,...
    globObj.NomShp.X, globObj.NomShp.Y, globObj.NomShp.Z, 'k-',...
    'Marker','o','linewidth',1);
hold(globObj.uiFig.axes{1}.ax, 'on');

tapDir = globObj.tapDir;
for pos=1:length(Data)

    disp = 0.5*globObj.refDim*tapDir(pos,:)';
    dx = globObj.NomShp_rep.X(pos)+[0,disp(1)];
    dy = globObj.NomShp_rep.Y(pos)+[0,disp(2)];
    dz = globObj.NomShp_rep.Z(pos)+[0,disp(3)];

    globObj.uiFig.axes{1}.Data{pos} = plot3(globObj.uiFig.axes{1}.ax,...
        dx,dy,dz, 'r-', 'marker', '.', 'lineWidth', 2);
    hold(globObj.uiFig.axes{1}.ax, 'on');

    text(globObj.uiFig.axes{1}.ax, dx(2), dy(2), dz(2),...
        globObj.Id{pos}, 'fontweight', 'bold', 'FontSize',10);

    globObj.uiFig.axes{1}.ax.DataAspectRatio = [1, 1, 1];

    set(globObj.uiFig.axes{1}.Data{pos}, 'buttonDownFcn',...
        @(in1,in2)(lineClickFcn(globObj,in1,in2,pos,true)));
end

%set up user Buttons.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
globObj.uiFig.bttns{1} =uibutton('parent', globObj.uiFig.fig,...
    'userData', globObj, 'buttonPushedFcn', @buttonCalls,...
    'text', 'Chan','position',[100, 375, 60, 20]);

globObj.uiFig.bttns{2} =uibutton('parent', globObj.uiFig.fig,...
    'userData', globObj, 'buttonPushedFcn', @buttonCalls,...
    'text', 'Config','position',[200, 375, 60, 20]);

globObj.uiFig.bttns{3} =uibutton('parent', globObj.uiFig.fig,...
    'userData', globObj, 'buttonPushedFcn', @buttonCalls,...
    'text', 'Run','position',[300, 375, 60, 20]);

globObj.uiFig.bttns{4} =uibutton('parent', globObj.uiFig.fig,...
    'userData', globObj, 'buttonPushedFcn', @buttonCalls,...
    'text', 'Export','position',[400, 375, 60, 20]);

set(globObj.uiFig.fig, 'UserData', globObj);
runIdent(globObj, false);

%%
function buttonCalls(inpt,var)
globObj = inpt.UserData.uiFig.fig.UserData;
bttn_id = inpt.Text;
switch bttn_id
    case 'Run'
        runIdent(globObj, true);

    case 'Config'
        prompt = {'MODALFIT frequency range [Hz]:',...
            'MODALFIT order:',...
            'Time span:',...
            'Decimation factor:'};
        dlgtitle = 'Input';
        dims = [1 35];
        definput = {num2str(globObj.FR),num2str(globObj.noMode),...
            num2str(globObj.Tspan),num2str(globObj.decifac)};
        answer = inputdlg(prompt,dlgtitle,dims,definput);

        if isempty(answer)
        else
            globObj.FR = str2num(answer{1,1});
            globObj.noMode = str2num(answer{2,1});
            globObj.Tspan = str2num(answer{3,1});
            globObj.decifac = str2num(answer{4,1});
            set(globObj.uiFig.fig, 'UserData', globObj);
            runIdent(globObj, false);
        end
    case 'Export'

        userData = globObj.procData.modes;

        if isempty(userData)
            warndlg('Error: No modes were selected')
        else
            uisave({'userData'},'procResults')
        end

    case 'Chan'
        inptNum = globObj.inptNum;       
        SelOpt{1} = 'All';
        for ii=1:length(inptNum)-1
            SelOpt{ii+1} = ['CHAN_',num2str(ii+1)];
        end

%         [lcn,tf] = listdlg('PromptString',{'Select cases to use:'},...
%             'SelectionMode','single','ListString',{'both', 'OOP', 'IP'});

        [lcn,tf] = listdlg('PromptString',{'Select cases to use:'},...
            'SelectionMode','single','ListString',SelOpt);
        if isempty(lcn)
        else
            globObj.recType = SelOpt{lcn};
%             switch lcn
%                 case 1
%                     globObj.recType = 'both';
%                 case 2
%                     globObj.recType = 'OOP';
%                 case 3
%                     globObj.recType = 'IP';
%             end
            set(globObj.uiFig.fig, 'UserData', globObj);
            runIdent(globObj, false)
        end

end

%%
function lineClickFcn(globObj,in1,in2,pos,runFlg)
globObj = globObj.uiFig.fig.UserData;
tempFig = figure('Name', globObj.Id{pos});

[tempinpt_nonWin,tempoutpt_nonWin,Fs] = odrData(globObj,pos,false);
[tempinpt,tempoutpt,Fs] = odrData(globObj,pos,true);

dim_range = round(Fs); win_flat = ones(dim_range,1);
selIdx = globObj.userSel{pos};

FRF = globObj.modalInfo.avFRF;
avFrq = globObj.modalInfo.avFRQ;
recon = globObj.modalInfo.fitFRF;

for rep=1:length(tempinpt(1,:))

    meth = globObj.fftMeth;
    switch meth
        case 'modalfrf'
            [FrF_temp,Frq] = modalfrf(tempinpt(:,rep),tempoutpt(:,rep),Fs,...
                win_flat,1,'Estimator','H1','Measurement','rovinginput','Sensor','dis');

        case 'rawFFT'
            t = 0:1/Fs:(length(tempinpt(:,rep))-1)/Fs;
            [frq,f_in] = getFFT(t,tempinpt(:,rep));
            [Frq,f_out] = getFFT(t,tempoutpt(:,rep));
            FrF_temp(:,1,1) = f_out./f_in;
    end
    t = 0:1/Fs:(length(tempinpt_nonWin(:,rep))-1)/Fs;

    test = find(selIdx==rep);
    if isempty(test)
        subplot(1,2,1)
        plot(Frq, abs(FrF_temp(:,1,1)), '--'); hold on;

        subplot(1,2,2)
        plot(t, tempinpt_nonWin(:,rep), '--'); hold on;

        leg{1,rep} = ['repeat ',num2str(rep), ' (discarded)'];
    else
        subplot(1,2,1)
        plot(Frq, abs(FrF_temp(:,1,1)), '-'); hold on;
        subplot(1,2,2)
        plot(t, tempinpt_nonWin(:,rep), '-'); hold on;

        leg{1,rep} = ['repeat ',num2str(rep)];
    end    
    fn{rep} = ['repeat ', num2str(rep)];

    subplot(1,2,1);
    set(gca, 'yscale', 'log');
    %drawnow;
end

subplot(1,2,1)
plot(avFrq, abs(FRF(:,1,pos)),'k-','lineWidth', 1.5); hold on;
plot(avFrq, abs(recon(:,1,pos)),'r-','lineWidth', 1.5); hold on;
leg{1,rep+1} = 'Average';
leg{1,rep+2} = 'Fitted Model';
set(gca, 'yscale', 'log');
xlim([0, 100])
legend(leg);
xlabel('Frequency, [Hz]'); ylabel('|Response/Input|, [V/V]')

subplot(1,2,2)
xlim([0, 0.5]);
ylabel('Hammer input, [V]'); xlabel('Time');
legend(leg{1:end-2});

if runFlg
    [lcn,tf] = listdlg('PromptString',{'Select cases to use:'},...
        'SelectionMode','multiple','ListString',fn);
    if isempty(lcn)
    else
        globObj.userSel{pos} = lcn;
        set(globObj.uiFig.fig, 'UserData', globObj);
        runIdent(globObj, false);
        close(tempFig)
        lineClickFcn(globObj,in1,in2,pos,false)
    end   
end



%%
function runIdent(globObj, idFlag)

globObj = globObj.uiFig.fig.UserData;
f = waitbar(0,'Please wait...updating fitting...');

for pos=1:length(globObj.Data)

    [tempinpt,tempoutpt,Fs] = odrData(globObj,pos,true);
    dim_range = round(Fs); win_flat = ones(dim_range,1);

    meth = globObj.fftMeth;
    switch meth
        case 'modalfrf'
            [FrF_temp,Frq] = modalfrf(tempinpt,tempoutpt,Fs,...
                win_flat,1,'Estimator','H1','Measurement','rovinginput','Sensor','dis');

        case 'rawFFT'
            for rep=1:length(tempinpt(1,:))
                t = 0:1/Fs:length(tempinpt(:,rep))/Fs;
                [frq,f_in] = getFFT(t,tempinpt(:,rep));
                [Frq,f_out] = getFFT(t,tempoutpt(:,rep));
                FrF_temp(:,1,rep) = f_out./f_in;
            end
    end

%average FRF...
    selIdx = globObj.userSel{pos};
    NetFrF = FrF_temp(:,1,selIdx(1));
    for j=2:length(selIdx), NetFrF = NetFrF + FrF_temp(:,1,selIdx(j)); end
    FrF(:,1,pos) = NetFrF./length(selIdx);

    f = waitbar(pos./length(globObj.Data),f);
end

globObj.modalInfo.avFRF = FrF;
globObj.modalInfo.avFRQ = Frq;
set(globObj.uiFig.fig, 'UserData', globObj);

[modFrq, modDamp, modShp, recon] =...
    modalfit(FrF,Frq,Fs,globObj.noMode,'FitMethod','lsce','FreqRange',globObj.FR);

globObj.modalInfo.frq = modFrq;
globObj.modalInfo.damp = modDamp;
globObj.modalInfo.shp = modShp;
globObj.modalInfo.fitFRF = recon;
set(globObj.uiFig.fig, 'UserData', globObj);

if idFlag

    stabDiag = figure;
    modalsd(FrF,Frq,Fs, 'FreqRange',globObj.stabDiagRange,...
        'FitMethod','lsce'); %stabalisation diagram
    aa = gca; set(aa.Legend,'AutoUpdate', 'off');

    hold on;
    validRecFrqs = modFrq; validRecFrqs(isnan(validRecFrqs))=0;
    recObj = xline(validRecFrqs, 'k-', 'lineWidth',2);
    title('Stabalisation diagram: Click on a line to display mode')

    %ident clickable pts as object
%     ob_allstab = findobj(stabDiag,'Marker','+'); ob_fstab = findobj(stabDiag,'Marker','o');

    %set button function for mode visualisation
%     set(ob_allstab, 'buttondownFcn', @(in1,in2)(showMode(in1,in2,globObj)));
%     set(ob_fstab, 'buttondownFcn', @(in1,in2)(showMode(in1,in2,globObj)));
    set(recObj, 'buttondownFcn', @(in1,in2)(showMode(in1,in2,globObj)));

    close(f);
else
    close(f);
end

%%
function [tempinpt,tempoutpt,Fs] = odrData(globObj,pos,winFlg)

globObj = globObj.uiFig.fig.UserData;

dBlock = globObj.Data{pos};
selIdx = globObj.userSel{pos};
type = globObj.recType;
Tspan = globObj.Tspan;

deciFac = globObj.decifac;
filDT = globObj.windowWidth;

for rpt=1:length(dBlock)
    idx = rpt; %selIdx(rpt);
    tempT = dBlock{idx}.T(1:deciFac:end);
    tempT = tempT-tempT(1);

    [~,t_idx] = min(abs(Tspan-tempT));
    tempT = tempT(1:t_idx);
        Fs = 1./(tempT(2)-tempT(1));
        
    tempinpt(:,rpt) = dBlock{idx}.Y(1:deciFac:t_idx,1);
    [~,cutIdx] = min(abs(tempT-(tempT(end)-2)));
    tempinpt(:,rpt) = tempinpt(:,rpt)-mean(tempinpt(cutIdx:end,rpt));

    if winFlg
        [~,imId] = max(abs(tempinpt(:,rpt))); impT = tempT(imId);
        filtr =...
            heaviside(tempT-impT+filDT).*heaviside(-tempT+impT+filDT);
        tempinpt(:,rpt) = tempinpt(:,rpt).*filtr;
    end

    senId = (regexp(type,'\d*','Match'));
    if isempty(senId) %if type='All'
        tempoutpt(:,rpt) =  sum(dBlock{idx}.Y(1:deciFac:t_idx,2:end),2);
    else %if a chanel is selected
        senId = str2num(senId{1});
        tempoutpt(:,rpt) = dBlock{idx}.Y(1:deciFac:t_idx,senId);
    end

end

%%
function showMode(in1,in2,globObj)

globObj = globObj.uiFig.fig.UserData;

modFrq = globObj.modalInfo.frq;
modDamp = globObj.modalInfo.damp;
modShp = globObj.modalInfo.shp;

clc;
%find selected frequency...
Fclick = in2.IntersectionPoint(1);

%identify position of selected mode
[~,idx] = min(abs(Fclick-modFrq));

mc_r=real(modShp(:,idx));
mc_i=imag(modShp(:,idx));
[uu,ss,vv]=svd([mc_r,mc_i]');
shp=uu(:,1).'*[mc_r.';mc_i.'];   % real mode
shp = shp(:)/max(abs(shp)); %scaling mode shapes..

figure;
plot3(globObj.NomShp.X, globObj.NomShp.Y, globObj.NomShp.Z, 'k-', 'Marker','x');
hold on;

tapDir = globObj.tapDir;
uniqCount = globObj.uniqPosNum;
disps = zeros(3,uniqCount);
for pos=1:length(globObj.Data)
    disps(:,globObj.NomShp.lcnIdx(pos)) =...
        disps(:,globObj.NomShp.lcnIdx(pos))+...
        0.5*globObj.refDim*tapDir(pos,:)'*shp(pos);
end
plot3(globObj.NomShp.X+disps(1,:),...
    globObj.NomShp.Y+disps(2,:),...
    globObj.NomShp.Z+disps(3,:), 'bx', 'LineWidth', 2);
title(['\omega:',num2str(modFrq(idx),3), ' [Hz] \zeta: ',num2str(modDamp(idx),3),' [-]']);
ax = gca; ax.DataAspectRatio = [1, 1, 1];

answer = questdlg('Save selected mode?',...
	'Processed mode', {'yes', 'no'});

switch answer
    case 'Yes'
        prompt = {'Enter mode identifier'};
        dlgtitle = 'Processed mode';
        dims = [1 35];
        definput = {['mode_',num2str(length(globObj.procData.modes)+1)]};

        id = inputdlg(prompt,dlgtitle,dims,definput);

        if isempty(id)
        else
            modalData = globObj.procData.modes;
            setIdx = length(modalData)+1;

            modalInfo.name = id;
            modalInfo.shape = disps;
            modalInfo.frequency = modFrq(idx);
            modalInfo.damping = modDamp(idx);
            modalInfo.excitCases = globObj.NomShp.lcnIdent;

            modalInfo.nomShp =...
                [globObj.NomShp.X;globObj.NomShp.Y;globObj.NomShp.Z];

            modalInfo.FRF.fit = globObj.modalInfo.fitFRF;
            modalInfo.FRF.avFRFs = globObj.modalInfo.avFRF;
            modalInfo.FRF.frqVec = globObj.modalInfo.avFRQ;

            modalData{setIdx} = modalInfo;
            globObj.procData.modes = modalData;

            set(globObj.uiFig.fig, 'UserData', globObj);
        end

end

%%
function [frq,P1] = getFFT(t,q)
    dt = t(2)-t(1);
    Fs = 1/dt;                 %Sampling frequency
    L_sig = (t(end)-t(1))/dt;  % Length of signal
    t = (0:L_sig-1)*dt;        % Time vector

    Y = fft(q);   %Fourier transform
    P2 = (Y/L_sig);
    P1 = P2(1:L_sig/2+1);
    P1(2:end-1) = 2*P1(2:end-1);

    frq = Fs*(0:(L_sig/2))/L_sig; %amp = abs(P1);

    clc;

return

