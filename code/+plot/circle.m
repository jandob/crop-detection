function [] = circle(x,y,varargin)
%% input parsing
p = inputParser;

addRequired(p,'x', @isnumeric);
addRequired(p,'y', @isnumeric);

addOptional(p,'radius', 1, @isnumeric);
addOptional(p,'step', 0.01, @isnumeric);
addOptional(p,'height', nan, @isnumeric);
addOptional(p,'color', nan, @isnumeric); %default red

parse(p, x, y, varargin{:});
args = p.Results;
%%
if isnan(args.color)
    args.color = repmat([1 0 0], size(args.x,1),1);
end
if numel(args.radius) ~= size(args.x,1)
    args.radius = args.radius * ones(size(args.x,1),1);
end
onHold = ishold;
if ~onHold; hold on; end
for i=1:size(args.x,1)
    ang=0:args.step:2*pi; 
    xp=args.radius(i,:)*cos(ang);
    yp=args.radius(i,:)*sin(ang);
    if ~isnan(args.height) 
        plot3(args.x(i,:)+xp, args.y(i,:)+yp, args.height(i,:)*ones(1,numel(xp)), 'color', args.color(i,:), 'LineWidth', 1.5);
    else
        plot(args.x(i,:)+xp, args.y(i,:)+yp, 'color', args.color(i,:), 'LineWidth', 1.5);
    end
end
if ~onHold; hold off; end

end