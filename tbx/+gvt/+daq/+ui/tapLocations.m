function tapLocations(obj)
obj = obj.uiFig.fig.UserData;
expr = obj.Data.expr;

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

    istested = obj.testedIdx(pos);

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