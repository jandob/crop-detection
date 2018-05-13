function dists = hellinger( point, otherPoints )

dists = sum((sqrt(point) - sqrt(otherPoints)).^2,2);

end

