classdef AerialDrone < BaseUAV
    % AERIALDRONE  A UAV that performs path planning and flight in 3D space.
    
    methods
        function obj = AerialDrone(id, startPos, spd)
            % Constructor for aerial drone with unique ID, start position, and speed.
            obj@BaseUAV(id, 'aerial', startPos, spd);
        end

        function planPath(obj, goal, env, cfg)
            % planPath  Uses 3D RRT-based planning (SE3) for an aerial drone.
            %
            %   1) Creates a stateSpaceSE3 with x,y,z bounds from cfg.
            %   2) Uses validatorOccupancyMap3D referencing env.occupancyMap3D.
            %   3) Runs plannerRRT (or RRT*) in 3D to find a path from
            %      the drone's current position to 'goal'.
            %   4) Stores the resulting waypoints in obj.path if a path is found.

            % 1) Create the 3D SE(3) state space with bounding box
            ss3D = stateSpaceSE3([0 cfg.mapWidth; ...
                                  0 cfg.mapHeight; ...
                                  0 cfg.mapDepth; ...
                                  inf inf; inf inf; inf inf; inf inf]);
            
            % 2) Associate an occupancy map validator in 3D
            sv3D = validatorOccupancyMap3D(ss3D, Map=env.occupancyMap3D);
            
            % 3) Configure a 3D RRT planner
            planner3D = plannerRRT(ss3D, sv3D, ...
                MaxIterations = cfg.rrtMaxIterations, ...
                MaxConnectionDistance = 10);
            
            % 4) Prepare start and goal states in [x, y, z, qw, qx, qy, qz]
            startSE3 = [obj.position(1), obj.position(2), obj.position(3), 1, 0, 0, 0];
            goalSE3  = [goal(1),         goal(2),         goal(3),         1, 0, 0, 0];

            % Run planning
            [pthObj, solnInfo] = plan(planner3D, startSE3, goalSE3);
            
            if solnInfo.IsPathFound
                % pthObj.States => Nx7 => [x, y, z, qw, qx, qy, qz]
                obj.path = pthObj.States(:,1:3);  % store only x,y,z
                obj.pathIdx = 1;
                
                if cfg.debug
                    fprintf('[AerialDrone %d] Found path with %d waypoints.\n',...
                            obj.id, size(obj.path,1));
                end
            else
                warning('[AerialDrone %d] No path found to (%.2f, %.2f, %.2f).',...
                        obj.id, goal(1), goal(2), goal(3));
                obj.path = [];
            end
        end
    end
end