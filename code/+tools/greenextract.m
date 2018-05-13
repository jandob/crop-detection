function [segmentation, polyHS, polyHV] = greenextract(points, color, polygonHS, polygonHV)

colorInfo = double(color)./255; % n x 3 rgb (0.0 - 1.0)
hsv = rgb2hsv(colorInfo);

if nargin > 2
    clusterIdx1 = inpolygon(hsv(:,1), hsv(:,2), ...
        polygonHS(:,1), polygonHS(:,2));
    clusterIdx2 = inpolygon(hsv(:,1), hsv(:,3), ...
        polygonHV(:,1), polygonHV(:,2));
    segmentation = clusterIdx1 & clusterIdx2;
    polyHS = polygonHS;
    polyHV = polygonHV;
    return
end

shared = containers.Map({'clusterIdxHS', 'clusterIdxHV'}, {ones(size(points, 1),1), ones(size(points, 1),1)});

% create linked figures
hlink = linkprop([],{'CameraPosition','CameraUpVector', 'CameraViewAngle', 'PlotBoxAspectRatio'});

figure(2888);
ax = pcshow(points, color);
addtarget(hlink,ax);

figure(3888);
ax = pcshow(points, color);
addtarget(hlink,ax);

ax.Children.XDataSource = 'points(clusterIdx,1)';
ax.Children.YDataSource = 'points(clusterIdx,2)';
ax.Children.ZDataSource = 'points(clusterIdx,3)';
ax.Children.CDataSource = 'color(clusterIdx,:)';

tic %start redrawtimer

figure(1888); subplot(1,2,1);
scatter(hsv(:,1), hsv(:,2), 5, color, '.')
title('h-s');
subplot(1,2,2);
scatter(hsv(:,1), hsv(:,3), 5, color, '.')
title('h-v');

figure(1888); subplot(1,2,1);
disp('select green cluster h-s')
polyHandleHS = impoly();
id1 = addNewPositionCallback(polyHandleHS, @(poly) handlePolygonChangeHS(poly, points, color, hsv, shared, ax.Children));
handlePolygonChangeHS(getPosition(polyHandleHS), points, color, hsv, shared, ax.Children)

figure(1888); subplot(1,2,2);
disp('select green cluster h-v')
polyHandleHV = impoly();
id2 = addNewPositionCallback(polyHandleHV, @(poly) handlePolygonChangeHV(poly, points, color, hsv, shared, ax.Children));
handlePolygonChangeHV(getPosition(polyHandleHV), points, color, hsv, shared, ax.Children)

dialog = msgbox('Click ok when finished adjusting the polygons!');
waitfor(dialog);

% return values
segmentation = shared('clusterIdxHS') & shared('clusterIdxHV');
polyHS = polyHandleHS.getPosition();
polyHV = polyHandleHV.getPosition();

removeNewPositionCallback(polyHandleHS, id1)
removeNewPositionCallback(polyHandleHV, id2)
close 1888 2888 3888
end
function handlePolygonChangeHS(polygon, points, color, hsv, shared, obj_handle) 
    shared('clusterIdxHS') = inpolygon(hsv(:,1), hsv(:,2), ...
        polygon(:,1), polygon(:,2));
    if toc < 1
        return; 
    end
    clusterIdx = shared('clusterIdxHS') & shared('clusterIdxHV');
    figure(3888);
    title(sprintf('%d Points', sum(clusterIdx)));
    refreshdata(obj_handle, 'caller')
end
function handlePolygonChangeHV(polygon, points, color, hsv, shared, obj_handle) 
    shared('clusterIdxHV') = inpolygon(hsv(:,1), hsv(:,3), ...
        polygon(:,1), polygon(:,2));
    if toc < 1
        return; 
    end
    clusterIdx = shared('clusterIdxHS') & shared('clusterIdxHV');
    figure(3888);
    title(sprintf('%d Points', sum(clusterIdx)));
    refreshdata(obj_handle, 'caller')
end



