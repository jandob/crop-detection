function dists = cosine(point, otherPoints)
% Calculates the cosine distance (1 - cosine similarity) 
% point is 1 x n
% otherPoints is m x n 
% should return m x 1 vector of distances

% dot products between point and all rows of otherPoints
numerators = otherPoints * point'; % m x 1

normPoint = sqrt(sum(point .^ 2, 2));
normsOtherPoints = sqrt(sum(otherPoints .^ 2, 2));

denominators = normPoint * normsOtherPoints; % m x 1

dists = 1 - numerators ./ denominators;

end


