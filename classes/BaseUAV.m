classdef (Abstract) BaseUAV < handle
    % BASEUAV  Abstract parent class for UAVs or vehicles in the rescue simulation.
    %
    % Common Properties:
    %   id                 - Unique integer identifier
    %   type               - 'aerial' or 'ground'
    %   position           - [x, y, z] current location in the environment
    %   speed              - Travel speed (m/s)
    %   path               - Nx3 array of waypoints
    %   pathIdx            - Index of the next waypoint
    %   assignedSurvivorID - Tracks which survivor is currently assigned to this UAV
    %
    % New property:
    %   totalDistanceTraveled - Accumulates how far the UAV has moved (for analysis)
    %
    % Methods:
    %   moveStep(dt)   - Move the UAV for one time step
    %   planPath(...)  - Abstract; implemented by subclasses for specific path planning

    properties
        id        (1,1) double
        type      (1,:) char
        position  (1,3) double
        speed     (1,1) double
        path      (:,3) double
        pathIdx   (1,1) double
        assignedSurvivorID
        % New property to track distance traveled in the environment
        totalDistanceTraveled (1,1) double = 0
    end

    methods
        function obj = BaseUAV(id, typeStr, startPos, spd)
            % Constructor for BaseUAV. This class is abstract and not directly instantiated.
            obj.id       = id;
            obj.type     = typeStr;
            obj.position = startPos;
            obj.speed    = spd;
            obj.path     = [];
            obj.pathIdx  = 1;
            obj.totalDistanceTraveled = 0;
        end

        function moveStep(obj, dt)
            % moveStep  Moves the UAV along its path based on speed*dt.
            %
            % If the UAV is already at the end of the path or no path exists, it does nothing.

            if isempty(obj.path) || obj.pathIdx > size(obj.path,1)
                return;  % No valid path or end of path
            end

            nextWP   = obj.path(obj.pathIdx, :);
            dVec     = nextWP - obj.position;
            distToWP = norm(dVec);
            moveDist = obj.speed * dt;

            if moveDist >= distToWP
                % Advance to the next waypoint
                obj.position = nextWP;
                % Accumulate distance traveled
                obj.totalDistanceTraveled = obj.totalDistanceTraveled + distToWP;
                obj.pathIdx  = obj.pathIdx + 1;
            else
                % Move incrementally toward the waypoint
                obj.position = obj.position + (moveDist/distToWP)*dVec;
                % Accumulate partial movement
                obj.totalDistanceTraveled = obj.totalDistanceTraveled + moveDist;
            end
        end
    end

    methods (Abstract)
        % Subclasses must implement planPath for their specific navigation approach.
        planPath(obj, goal, env, cfg);
    end
end