function features = convertDis(locations, points, searchRadius, nBinsAngular, nBinsRadial, radialBase)
    dim = size(points,2);
    features = zeros(size(locations, 1), nBinsAngular^(dim-1)*nBinsRadial);
    neigborsAll = rangesearch(points, locations, searchRadius);
    for i = 1:size(features, 1)
        point = locations(i,:);
        neighbors = points(neigborsAll{i},:);
        features(i,:) = uniqueShapeContext(neighbors, point, searchRadius, nBinsAngular, nBinsRadial, radialBase);
    end
end


