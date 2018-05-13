function featureVector = uniqueShapeContext(neighbors, p, searchRadius, nBinsAngular, nBinsRadial, radialBase)
    deltas = neighbors - p;
    if size(p,2) == 3 
        % quantize to bins (azimuth,elevation,r)
        bins = zeros(nBinsAngular, nBinsAngular, nBinsRadial);
        for delta = deltas'
            [azimuth, elevation, radius] = cart2sph(delta(1), delta(2), delta(3));
            % azimuth: -2pi to +2pi
            % elevation: -pi to pi
            % radius: 0 to searchRadius
            a = ((azimuth / (2*pi)) + 1) / 2; % 0 <= x <= 1
            e = ((elevation / pi) + 1) / 2; %t 0 <= x <= 1        
            r = radius / searchRadius; % 0 <= x <= 1
            r = r.^radialBase;

            %assert(a >= 0 && a <= 1 ); 
            %assert(e >= 0 && e <= 1 );
            %assert(r >= 0 && r <= 1 );

            a = floor((nBinsAngular-1)*a) + 1; % 1 to nBins
            %assert(a >= 1 && a <= 6 ); 
            e = floor((nBinsAngular-1)*e) + 1; % 1 to nBins
            %assert(e >= 1 && e <= 6 ); 
            r = floor((nBinsRadial-1)*r) + 1; % 1 to nBins
            %assert(r >= 1 && r <= 6 ); 
            try
                bins(a,e,r) = bins(a,e,r) + 1;
            catch ME
                rethrow(ME)
            end
        end
    elseif size(p, 2) == 2
        bins = zeros(nBinsAngular, nBinsRadial);
        for delta = deltas'
            [theta, rho] = cart2pol(delta(1), delta(2));
            % theta: -pi to pi
            % rho: 0 to searchRadius
            t = ((theta / (pi)) + 1) / 2; % 0 <= x <= 1
            r = rho / searchRadius; % 0 <= x <= 1
            r = r.^radialBase;
            

            t = floor((nBinsAngular-1)*t) + 1; % 1 to nBins
            r = floor((nBinsRadial-1)*r) + 1; % 1 to nBins
            bins(t,r) = bins(t,r) + 1;
        end
    end
    % flatten to vector
    featureVector = reshape(bins, [numel(bins) 1]);
    %bar(featureVector);
    % TODO normalize to account for different densities?
    % fetureVector = featureVector/

    % similarity for histogram feature
    %similarityEuclidean = pdist([featureVector'; featureVector'], 'euclidean')
    %similarityCosine = pdist([featureVector'; featureVector'], 'cosine')

end

