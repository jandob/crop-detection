function [] = ellipse(x,y,varargin)
%% input parsing
p = inputParser;

addRequired(p,'x', @isnumeric);
addRequired(p,'y', @isnumeric);

addOptional(p,'radiusX', 1, @isnumeric);
addOptional(p,'radiusY', 1, @isnumeric);
addOptional(p,'step', 0.01, @isnumeric);
addOptional(p,'height', nan, @isnumeric)

parse(p, x, y, varargin{:});
args = p.Results;
%%


onHold = ishold;
if ~onHold; hold on; end
for i=1:size(args.x,1)
    ang=0:args.step:2*pi; 
    xp=args.radiusX(i,:)*cos(ang);
    yp=args.radiusY(i,:)*sin(ang);
    if ~isnan(args.height) 
        plot3(args.x(i,:)+xp, args.y(i,:)+yp, args.height(i,:)*ones(1,numel(xp)) ,'red', 'LineWidth', 1.5);
    else
        plot(args.x(i,:)+xp, args.y(i,:)+yp, 'red', 'LineWidth', 1.5);
    end
end
if ~onHold; hold off; end

end