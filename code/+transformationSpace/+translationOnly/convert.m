function pairTransforms = convert(points, pairs)
%CONVERT Calculate transformations between pairs of points. 
%   TRANSFORMS = CONVERT(POINTS, PAIRS) 
%   POINTS is a N x M matrix containing N M-dimensional points. PAIRS is a 
%   K x 2 matrix containing K pairs of points (indices for POINTS)
%   FEATURES is ignored and just in the signature for compatability with
%   other transformation space functions.
% 
%   Returns TRANSFORMS, a K x M matrix containing the translation vectors
%   between all given pairs of points.

p1 = points(pairs(:,1),:);
p2 = points(pairs(:,2),:);
pairTransforms = p2 - p1;

% pairTransforms = [];
% for pair = pairs'
%     p1 = points(pair(1),:)';
%     p2 = points(pair(2),:)';
%     %trafo = [p2(1) - p1(1); p2(2) - p1(2)]; 
%     trafo = p2 - p1;
% 
%     % make sure same trafos have same direction
% %         trafo = [abs(points(idx2, 2) - points(idx1, 2));
% %                  abs(points(idx2, 1) - points(idx1, 1))];
%     %pairTransforms(idx1*k-j+1,:) = [trafo'];
%     pairTransforms = [pairTransforms; trafo'];
% end

end

