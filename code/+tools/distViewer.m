function [] = distViewer(points, dists, pIdx)

% points = points;
% dists = 1-squareform(sfd);
%dists = d;
%dists = pairwiseSimilarities.^2;
if exist('pIdx')
    pointIdx = pIdx;
else
    pointIdx = 1;
end
ax = plot.pc(points, dists(pointIdx,:), 'MarkerSize', 100);
if size(points,2) ==3 
    scatterHandle = ax.Children;
else
    scatterHandle = ax;
end
dcm_obj = datacursormode;
set(dcm_obj,'UpdateFcn',{@myupdatefcn,scatterHandle})
scatterHandle.XDataSource = 'points(:,1)';
scatterHandle.YDataSource = 'points(:,2)';
if size(points,2) == 3 
    scatterHandle.ZDataSource = 'points(:,3)';
end
scatterHandle.CDataSource = 'dists(pointIdx,:)';
datacursormode; % switch to cursor

%% plot distances from 1 specific point
% figure(2)
% pIdx = 1;
% scatter(points(:,2), points(:,1), 100, pairwiseSimilarities(:, pIdx), '.')
% hold on
% ang=0:0.01:2*pi; 
% scatter(points(pIdx,2)+searchRadius*cos(ang),points(pIdx,1)+searchRadius*sin(ang),1, 'r.');
% hold off


function txt = myupdatefcn(~,event_obj,refresh_obj)
    % Customizes text of data tips

    pos = get(event_obj,'Position');
    I = get(event_obj, 'DataIndex');
    pointIdx = I;
    txt = {['X: ',num2str(pos(1))],...
           ['Y: ',num2str(pos(2))],...
           ['I: ',num2str(I)]};
    % trick to make the variable names available in the 'caller' scope 
    points = points;
    dists = dists;
    refreshdata(refresh_obj, 'caller')
end
end