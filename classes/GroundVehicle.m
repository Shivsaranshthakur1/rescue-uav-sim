classdef GroundVehicle < BaseUAV
    % GROUNDVEHICLE  A UAV subclass that drives in 2D space on the ground.
    %
    % This vehicle uses a 2D RRT-based planner in SE(2) for path planning.

    methods
        function obj = GroundVehicle(id, startPos, spd)
            % Constructor for a ground vehicle with a unique ID, starting position, and speed.
            obj@BaseUAV(id, 'ground', startPos, spd);
        end

        function planPath(obj, goal, env, cfg)
            % planPath  Implements 2D (SE2) RRT planning for ground navigation.
            %
            % Steps:
            %   1) Defines stateSpaceSE2 with [x, y, theta] and bounds [0..mapWidth, 0..mapHeight].
            %   2) Attaches a validatorOccupancyMap referencing env.groundMap.
            %   3) Creates and runs plannerRRT to find a path from (obj.position) to "goal".
            %   4) Converts the resulting states to [x, y, z=0] in obj.path.

            import nav.algs.checkIfGoalIsReached

            % 1) Define SE2 state space for [x, y, theta].
            ss = stateSpaceSE2([0 cfg.mapWidth; 0 cfg.mapHeight; -pi pi]);

            % 2) Occupancy-based validator referencing the ground map
            sv = validatorOccupancyMap(ss, Map=env.groundMap);

            % 3) Set up an RRT planner with a max iteration and connection distance
            planner = plannerRRT(ss, sv, ...
                MaxIterations = cfg.rrtMaxIterations, ...
                MaxConnectionDistance = 10);

            % 4) Prepare start/goal states in [x, y, theta]
            startSE2 = [obj.position(1), obj.position(2), 0];
            goalSE2  = [goal(1),         goal(2),         0];

            [pthObj, solnInfo] = plan(planner, startSE2, goalSE2);

            if solnInfo.IsPathFound
                % pthObj.States => Nx3 => [x, y, theta]
                xy = pthObj.States(:, 1:2);
                obj.path = [xy, zeros(size(xy,1),1)];  % embed z=0
                obj.pathIdx = 1;
                if cfg.debug
                    fprintf('[GroundVehicle %d] Found path with %d waypoints.\n', ...
                        obj.id, size(obj.path,1));
                end
            else
                warning('[GroundVehicle %d] No path found to (%.2f, %.2f).', ...
                    obj.id, goal(1), goal(2));
                obj.path = [];
            end
        end
    end
end