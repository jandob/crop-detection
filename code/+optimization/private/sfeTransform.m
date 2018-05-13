function [ sfe sfd dist] = sfeTransform(pairwiseSimilarities, t, locality, percentile)
M = 1-pairwiseSimilarities; % to distance

M = exp(-(M.^2)./locality); % gauss kernel, similarity again
M(M<0.01) = 0;
M = sparse(M);
% normalize
% M = (M - min(M)) ./ ( max(M) - min(M));
M = M./sum(M,2); % row normalization
% M = inv(diag(sum(M,2)))*M;

% make sure the similarity matrix symmetric
% M = (M+M')./2;
[Vsfe,e] = eigs(M,100); % returns 10 largest eigenvalues 

Esfe = diag(e);

% Vsfe = Vsfe(:,2:end);
% Esfe = Esfe(2:end);

n = size(Vsfe,1);

sfe = repmat(Esfe.^t,1,n)'.*Vsfe;
sfd = squareform(pdist(real(sfe)));
p = prctile(sfd(:),percentile);
sfd(sfd>p) = p;
sfd = (sfd - min(sfd)) ./ ( max(sfd) - min(sfd));

dist = 1-full(M);
dist = (dist - min(dist)) ./ ( max(dist) - min(dist));

end

