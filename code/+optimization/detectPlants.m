function [landmarks, landmarkscores] = detectPlants(pointsIn, varargin)
%DETECTPLANTS2 Finds landmarks
%Pointcloud
%   [LANDMARKS, VARS, LANDMARKSCORES] = 
%           detectPlants2(POINTSIN, VARARGIN)
%   LANDMARKS are the detected centers of plants. VARS are the variances
%   of the distances for each segmented plant to its center. LANDMARKSCORES
%   are the mean densities of all pairs (in tranformation space) that 
%   belong to a detected plant.
% 
%   Optional Name-value pairs for the different steps of the detection
%   algorithm:
%     Parameter         Value
%     'searchRadius'    Scalar. Radius of the spherical feature histogram.
%                       Default: max(vecnorm(minmax(pointsIn')'))/10
%     'alpha'           Scalar. Locality parameter for the sfe diffusion.
%                       Default: 0.02
%     't'               Integer. Time parameter for the sfe diffusion.
%                       Default: 10
%     'sfeSearchRadius' Scalar. Similarity threshold for pairs that are 
%                       considered.
%                       Default: 0.15
%     'distanceMetric'  Scalar. Distancemetric for the calculation of 
%                       similarity between two points in feature space.
%                       Default 'correlation'
%                       (Can be anything that PDIST() accepts)
%     'minTFDist'       Scalar. Spatial distance threshold for pairs. Also 
%                       used as bandwith parameter to meanshift clustering.
%                       Default: searchRadius
%     'nSample'         Integer. Use a uniform sample of nSample points.
%                       Default: 3000
p = inputParser;

addRequired(p,'pointsIn');

addParameter(p,'searchRadius', max(vecnorm(minmax(pointsIn')'))/10, ...
    @(x) isscalar(x));
addParameter(p,'minTFDist', max(vecnorm(minmax(pointsIn')'))/10, ...
    @(x) isscalar(x)); 

addParameter(p,'alpha',             0.02,   @(x) isscalar(x)); 
addParameter(p,'sfeSearchRadius',   0.15,   @(x) isscalar(x)); 

addParameter(p,'t',       10,   @(x) floor(x)==x); 
addParameter(p,'nSample', 3000, @(x) floor(x)==x); 

addParameter(p,'distanceMetric', 'correlation'); 

parse(p, pointsIn, varargin{:});
args = p.Results;

rng(42);

tic;
if size(pointsIn,1) > args.nSample 
    sampleIdx = randperm(size(pointsIn,1), args.nSample)';
    features = featureSpace.USC.convert(pointsIn, args.searchRadius, 8, 8, 2, sampleIdx);
    points = pointsIn(sampleIdx,:);
else 
    points = pointsIn;
    features = featureSpace.USC.convert(points, args.searchRadius, 8, 8, 2);
end
fprintf("feature space (%d points, %d samples): %.2fs\n", size(pointsIn,1), args.nSample, toc);

tic;
pairwiseSimilarities = 1 - squareform(pdist(features,args.distanceMetric)); % n x n
fprintf("similarity (%d features): %.2fs\n", size(features,1) , toc);
pairwiseSimilarities = (pairwiseSimilarities - min(pairwiseSimilarities)) ./ ( max(pairwiseSimilarities) - min(pairwiseSimilarities));

tic;
[sfe sfd M] = sfeTransform(pairwiseSimilarities, args.t, args.alpha, 10);
fprintf("sfe %.2fs\n", toc);


spatialConstraint = squareform(pdist(points)) > args.minTFDist;
simConstraint = (sfd) < args.sfeSearchRadius;
pairsInd = simConstraint & spatialConstraint;
[row, col] = find(pairsInd);
pairs = [row col];
if size(pairs,1) > 2*10e4
    warning('> 200000 pairs, could take a while')
end
tic
pairTransforms = transformationSpace.translationOnly.convert(points, pairs);

[centers,clusters,~] = clustering.meanshift(pairTransforms',args.minTFDist);

pairTfDensity = zeros(size(pairs,1),1);
nearestCentersIdx = knnsearch(centers,pairTransforms);
distToNearestCenter = distance.euclid(centers(nearestCentersIdx,:),pairTransforms);
distToNearestCenter = vector.normalize(distToNearestCenter);

centerneighborstf = rangesearch(pairTransforms, centers, args.minTFDist/2);
f = cellfun('length',centerneighborstf);
f = vector.normalize(f);
pairTfDensity = ((1-distToNearestCenter).^2).*f(nearestCentersIdx);
fprintf("transformation space with density (%d pairs): %.2fs\n", size(pairs,1), toc);

%% landmarks
tic;
[centers,~,clustersCell] = clustering.meanshift(pointsIn',args.minTFDist);
fprintf("MSC %.2fs\n", toc);

tic
lmpairs = nchoosek(1:size(centers,1),2);
lmTransforms = transformationSpace.translationOnly.convert(centers, lmpairs);

% find density in transformation space
kdTreeTf = KDTreeSearcher(pairTransforms);
nextTf = knnsearch(kdTreeTf, lmTransforms);
lmpairsTfDensity = pairTfDensity(nextTf);

% find similarity (todo could be vectorized for speed up)
kdTreePoints = KDTreeSearcher(points);
lmpairsSim = zeros(size(lmpairs,1),1);
for i = 1:size(lmpairs,1)
    % find similarity
    nextPoints = knnsearch(kdTreePoints, centers(lmpairs(i,:),:));
    lmpairsSim(i) = 1-sfd(nextPoints(1), nextPoints(2));
end
lmpairsSim = vector.normalize(lmpairsSim);
landmarkscoresSim = [];
landmarkscoresDensity = [];
landmarkscores = [];
for i = 1:size(centers,1) % for each landmark
    % integrate score over other landmarks
    otherLMs = (lmpairs(:,1) == i | lmpairs(:,2) == i);
    landmarkscores(i,:) = mean(lmpairsSim(otherLMs) .* lmpairsTfDensity(otherLMs));
    landmarkscoresSim(i,:) = mean(lmpairsSim(otherLMs));
    landmarkscoresDensity(i,:) = mean(lmpairsTfDensity(otherLMs));
end
landmarkscoresSim = vector.normalize(landmarkscoresSim);
landmarkscores = landmarkscoresSim + landmarkscoresDensity;
landmarkscores = vector.normalize(landmarkscores);
landmarks = centers;
fprintf("scores %.2fs\n", toc);


