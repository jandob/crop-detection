function dists = euclid(point, otherPoints)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
dists = sum((point - otherPoints).^2,2);
end

