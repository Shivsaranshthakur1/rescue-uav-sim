function cfg = config()
% CONFIG  Returns a struct of adjustable simulation parameters.
% This function centralizes all simulation constants and tunable values.

    %% Simulation Timing
    cfg.timeStep        = 0.1;   % (s) Time step per iteration
    cfg.totalSimTime    = 300;   % (s) Maximum allowed simulation time

    %% Environment Dimensions
    cfg.mapWidth  = 300;  % (m) Horizontal X-extent
    cfg.mapHeight = 300;  % (m) Horizontal Y-extent
    cfg.mapDepth  = 100;  % (m) Vertical Z-extent for aerial flight

    %% Vehicle Settings
    cfg.numAerial   = 2;   % Number of aerial UAVs
    cfg.numGround   = 2;   % Number of ground vehicles
    cfg.aerialSpeed = 15;  % (m/s) Aerial UAV speed
    cfg.groundSpeed = 5;   % (m/s) Ground vehicle speed

    %% Survivors
    cfg.numSurvivors = 5;  % How many survivors to place randomly

    %% Path Planning Parameters (RRT)
    cfg.rrtPlannerType   = 'rrt';   % 'rrt' or 'rrtstar'
    cfg.rrtMaxIterations = 10000;   % Max number of RRT expansions
    cfg.rrtStepSize      = 5;       % (m) Step size for expansions
    cfg.rrtGoalBias      = 0.3;     % Probability of sampling goal directly

    %% Visualization and Debug
    cfg.show3D       = true;   % Whether to plot a 3D figure
    cfg.show2D       = false;  % Whether to plot a 2D overhead figure
    cfg.debug        = false;  % Enable/disable debug prints
    cfg.plotInterval = 0.1;    % (s) How often to refresh plots

    %% Survivor Assignment Approaches
    cfg.centroidApproach = false;
    cfg.kmeansApproach   = false;
end