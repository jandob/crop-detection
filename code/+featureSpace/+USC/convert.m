function features = convert(points, searchRadius, nBinsAngular, nBinsRadial, radialBase, featureIdx)
%FEATURESPACE.USC.CONVERT Calculates spherical histogram for all given points.
%   FEATURES = FEATURESPACE.USC.CONVERT(points, searchRadius, nBinsAngular, nBinsRadial, radialBase)
%       Returns a matrix with nPoints rows. Each row is the feature
%       histogramm for the nth point. nBinsAngular, nBinsradial and
%       radialBase define the spatial subdivision of a spherical volume
%       with radius searchradius around each point.
%   FEATURES = FEATURESPACE.USC.CONVERT(points, searchRadius, nBinsAngular, nBinsRadial, radialBase, featureIdx)
%       Features are calculated only around points selected by points
%       selected with the indexing vector featureIdx. Note that the all
%       points are used for the individual histogram calculations.

    nPoints = size(points,1);
    dim = size(points,2);
    if ~exist('featureIdx','var')
        featureIdx = 1:nPoints;
    end
    nFeatures = numel(featureIdx);

    features = zeros(nFeatures, nBinsAngular^(dim-1)*nBinsRadial);
    dists = pdist2(points(featureIdx,:), points);

    neigborsInd = dists < searchRadius;
    for i = 1:nFeatures
        point = points(featureIdx(i),:);
        neighbors = points(neigborsInd(i,:),:);
        features(i,:) = uniqueShapeContext(neighbors, point, searchRadius, nBinsAngular, nBinsRadial, radialBase);
        % normalize
        features(i,:) = features(i,:)./max(features(i,:));
    end
    
end


