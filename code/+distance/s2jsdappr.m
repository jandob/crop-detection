function [ dists ] = s2jsdappr(point, otherPoints)
%S2JSDAPPR Summary of this function goes here
%   Detailed explanation goes here

dists = sum((point - otherPoints).^2.*(1./(point + otherPoints+realmin)),2);
dists = sqrt(dists./2);
end

