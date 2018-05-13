function [ ] = plotUSC(point, searchRadius, nBinsAngular, nBinsRadial, radialBase )
%% plot angular bins
theta = 0:2*pi/nBinsAngular:2*pi
rho = repmat(searchRadius, 1, length(theta))
[x,y] = pol2cart(theta, rho)
for i = 1:nBinsAngular
    line([point(1) point(1)+x(i)], [point(2) point(2)+y(i)], 'color', 'red','LineWidth',1)
end
% plot radial bins
r = ((0:1/nBinsRadial:1).^radialBase).*searchRadius
for i=1:length(r)
    plot.circle(point(1), point(2), 'radius', r(i))
end

