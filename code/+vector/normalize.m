function [vNormalized] = normalize(v)

vNormalized = (v - min(v))/(max(v)-min(v));

end

