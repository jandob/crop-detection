function axOut = pc(points, varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

nDim = size(points,2);
nPoints = size(points,1);

%% input parsing
p = inputParser;

addRequired(p,'points', @isnumeric);

addOptional(p,'color', nan, @isnumeric);
addParameter(p,'extraMarkers',nan, @isnumeric);
addParameter(p,'extraMarkerSize',nan, @isnumeric);
addParameter(p,'extraMarkerColor', nan, @isnumeric); 

addParameter(p,'MarkerSize', 6^(4 - nDim), @(x) isscalar(x) && x > 0);

parse(p, points, varargin{:});

args = p.Results;
%%
onHold = ishold;

if isnan(args.extraMarkerSize)
    if nDim == 2
        args.extraMarkerSize = args.MarkerSize;
    elseif nDim == 3
        args.extraMarkerSize = args.MarkerSize*10;
    end
else
    if (size(args.extraMarkerSize,1) ~= size(args.extraMarkers,1))
        args.extraMarkerSize = args.extraMarkerSize * ones(size(args.extraMarkers,1),1);
    end
end

if ~isnan(args.extraMarkerColor)
    if (size(args.extraMarkerColor,1) ~= size(args.extraMarkers,1))
        args.extraMarkerColor = args.extraMarkerColor * ones(size(args.extraMarkers,1),1);
    end
    cm = colormap;
    number_of_colors = size(cm,1);
    values_min = min(args.extraMarkerColor); % range of the colorbar
    values_max = max(args.extraMarkerColor);  
    range = values_max - values_min;
    if (range == 0) % only one value, interprete as value between 0 and 1
        values_min = 0; 
        values_max = 1;
    end
    idx_in_colorbar = floor(1+ (args.extraMarkerColor - values_min) / (values_max - values_min) * (number_of_colors-1));
    args.extraMarkerColor = cm(idx_in_colorbar,:);
end
%% 


%% 
ax = nan;
if nDim == 3
    if ~isnan(args.color)
        ax = pcshow(points, args.color, 'MarkerSize', args.MarkerSize);
    else
        ax = pcshow(points, 'MarkerSize', args.MarkerSize);
    end
    if ~isnan(args.extraMarkers)
        p = args.extraMarkers;
        if ~onHold; hold on; end
%         scatter3(p(:,1), p(:,2), p(:,3),args.extraMarkerSize,'red','LineWidth',1.5)
          plot.circle(p(:,1), p(:,2), 'radius', args.extraMarkerSize, 'height', p(:,3), 'color', args.extraMarkerColor)
        if ~onHold; hold off; end
    end
    zlabel('z')
end
if nDim == 2
    if ~isnan(args.color)
        ax = scatter(points(:,1), points(:,2), args.MarkerSize, args.color, '.');
    else
        ax = scatter(points(:,1), points(:,2), args.MarkerSize, '.');
    end
    if ~isnan(args.extraMarkers)
        p = args.extraMarkers;
        if ~onHold; hold on; end
        plot.circle(p(:,1), p(:,2),args.extraMarkerSize, 'color', args.extraMarkerColor)
        if ~onHold; hold off; end
    end
end
xlabel('x in m')
ylabel('y in m')
daspect([1 1 1])

if nargout > 0
    axOut = ax;
end
end

