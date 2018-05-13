function [centers, clusterIdx, pointIdx] = meanshift(points, bandWidth)
%MEANSHIFT Calculates clusters based on meanshift.  
%
% POINTS           - input data, (nPoints x nDim)
% BANDWITH         - is bandwidth parameter (scalar)
% CENTERS          - cluster centers (nClusters x nDim)
% CLUSTERIDX       - for every point which cluster it belongs to (nPoints)
% POINTSIDX        - for every cluster which points are in it (nClusters x cellArray)
%
% Originaly published by:
% Bryan Feldman 02/24/06
% MeanShift first appears in
% K. Funkunaga and L.D. Hosteler, "The Estimation of the Gradient of a
% Density Function, with Applications in Pattern Recognition"
%
% Modified by:
% Janosch Dobler

[nDim, nPoints] = size(points);
numClust        = 0;
bandSq          = bandWidth^2;
initPtInds      = 1:nPoints;
stopThresh      = 1e-3*bandWidth;                     %when mean has converged
centers       = [];                                   %center of clust
beenVisitedFlag = zeros(1,nPoints,'uint8');           %track if a points been seen already
numInitPts      = nPoints;                            %number of points to posibaly use as initilization points
clusterVotes    = zeros(1,nPoints,'uint16');          %used to resolve conflicts on cluster membership

while numInitPts
    tempInd         = ceil( (numInitPts-1e-6)*rand);        %pick a random seed point
    stInd           = initPtInds(tempInd);                  %use this point as start of mean
    myMean          = points(:,stInd);                      % intilize mean to this points location
    myMembers       = [];                                   % points that will get added to this cluster                          
    thisClusterVotes    = zeros(1,nPoints,'uint16');        %used to resolve conflicts on cluster membership
    while 1     %loop untill convergence
        sqDistToAll = sum((repmat(myMean,1,nPoints) - points).^2);    %dist squared from mean to all points still active
        inInds      = find(sqDistToAll < bandSq);               %points within bandWidth
        thisClusterVotes(inInds) = thisClusterVotes(inInds)+1;  %add a vote for all the in points belonging to this cluster
        
        
        myOldMean   = myMean;                                   %save the old mean
        myMean      = mean(points(:,inInds),2);                %compute the new mean
        myMembers   = [myMembers inInds];                       %add any point within bandWidth to the cluster
        beenVisitedFlag(myMembers) = 1;                         %mark that these points have been visited


        %**** if mean doesn't move much stop this cluster ***
        if norm(myMean-myOldMean) < stopThresh
            
            %check for merge posibilities
            mergeWith = 0;
            for cN = 1:numClust
                distToOther = norm(myMean-centers(:,cN));     %distance from posible new clust max to old clust max
                if distToOther < bandWidth/2                    %if its within bandwidth/2 merge new and old
                    mergeWith = cN;
                    break;
                end
            end
            
            
            if mergeWith > 0    % something to merge
                centers(:,mergeWith)       = 0.5*(myMean+centers(:,mergeWith));             %record the max as the mean of the two merged (I know biased twoards new ones)
                %clustMembsCell{mergeWith}    = unique([clustMembsCell{mergeWith} myMembers]);   %record which points inside 
                clusterVotes(mergeWith,:)    = clusterVotes(mergeWith,:) + thisClusterVotes;    %add these votes to the merged cluster
            else    %its a new cluster
                numClust                    = numClust+1;                   %increment clusters
                centers(:,numClust)       = myMean;                       %record the mean  
                %clustMembsCell{numClust}    = myMembers;                    %store my members
                clusterVotes(numClust,:)    = thisClusterVotes;
            end

            break;
        end

    end
    
    
    initPtInds      = find(beenVisitedFlag == 0);           %we can initialize with any of the points not yet visited
    numInitPts      = length(initPtInds);                   %number of active points in set

end

[~,clusterIdx] = max(clusterVotes,[],1);                % a point belongs to the cluster with the most votes

% if requested, find points belonging to cluster 
if nargout > 2
    pointIdx = cell(numClust,1);
    for cN = 1:numClust
        myMembers = find(clusterIdx == cN);
        pointIdx{cN} = myMembers;
    end
end

centers = centers';
clusterIdx = clusterIdx';