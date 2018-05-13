function [pointsOut, center, V] = normalizePointCloud(points) 
    center = max(points) - (max(points) - min(points))/2;
    pointsOut = points - center; % center pointCloud at (0,0,0)
    
    % find direction of maximum variance in x-y plane
    [U,S,V] = svd(pointsOut(:,1:2), 0);
    % rotation around z to align at x axis
    V = [[V,[0;0]];[0 0 1]];
    pointsOut = pointsOut * V;
end