function dists = chisquare(point, otherPoints)
dists = sum((point - otherPoints).^2.*(1./(point + otherPoints+realmin)),2);
end
