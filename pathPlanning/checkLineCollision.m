function isColliding = checkLineCollision(p1, p2, env, mode)
% CHECKLINECOLLISION  Checks whether a line segment intersects an obstacle
% in a 3D occupancy map, optionally treating the segment as 2D if mode='2D'.
%
% Arguments:
%   p1, p2 : row vectors representing endpoints, either [x,y] or [x,y,z]
%   env    : environment struct containing env.occupancyMap3D
%   mode   : '2D' or '3D' 
%
% Returns:
%   isColliding : logical. true if the line is occupied or out-of-bounds 
%                 at any point, false otherwise.

    % Use ~1 meter increments along the segment
    stepSize = 1.0;

    if strcmp(mode, '2D')
        % For 2D mode, embed z=0
        p1 = [p1, 0];
        p2 = [p2, 0];
    end

    delta = p2 - p1;
    dist  = norm(delta);

    if dist < 1e-6
        % Start and end are nearly the same point
        isColliding = false;
        return;
    end

    direction = delta / dist;
    nSteps    = ceil(dist / stepSize);

    % Check occupancy at each incremental position along the segment
    for i = 0:nSteps
        frac = min(i / nSteps, 1.0);
        pt   = p1 + frac * delta;
        
        occVal = getOccupancy(env.occupancyMap3D, pt);
        % If occupancy > 0.65, consider it colliding
        if occVal > 0.65
            isColliding = true;
            return;
        end
    end

    isColliding = false;
end