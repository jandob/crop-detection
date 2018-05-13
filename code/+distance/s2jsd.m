function dists = s2jsd(point, otherPoints)
%S2JSD Summary of this function goes here
%   Detailed explanation goes here

assert(size(point,2) == size(otherPoints,2)); % equal dimensions
assert(size(point,1) == 1); % pdist requires point to be a single sample

m = ((point + otherPoints)/2)+realmin;
jensen_shannon = sum(point.*log((point./m)+realmin) + otherPoints.*((otherPoints./m)+realmin),2);

dists = sqrt(jensen_shannon);
% dists = jensen_shannon;
if isnan(jensen_shannon)
    true;
end
end

