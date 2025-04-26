function env = createEnvironment(cfg)
% CREATEENVIRONMENT  Creates a 2D + 3D occupancy map environment 
% with randomly placed rectangular buildings and survivors.
%
%   If cfg.numBuildings is unspecified, defaults to 30.
%   If cfg.numSurvivors is unspecified, defaults to 15.
%
% Steps:
%   1) Initialize a 2D occupancyMap and fill it with free cells.
%   2) Initialize a 3D occupancyMap3D and fill it with free cells.
%   3) Place a specified number of buildings at random footprints, extrude them to random heights.
%   4) Spawn survivors in free locations on the ground.

    % Set default number of buildings and survivors if not specified
    if ~isfield(cfg, 'numBuildings')
        cfg.numBuildings = 30;  
    end
    if ~isfield(cfg, 'numSurvivors')
        cfg.numSurvivors = 15; 
    end

    % Fix the RNG seed for reproducibility
    rng(12345);

    env = struct();

    %% 1) Create 2D occupancy map and fill with free cells
    env.groundMap = occupancyMap(cfg.mapWidth, cfg.mapHeight, 1);
    [colIdx, rowIdx] = meshgrid(0:cfg.mapWidth-1, 0:cfg.mapHeight-1);
    rowColPairs      = [rowIdx(:), colIdx(:)];
    freeVals         = zeros(numel(rowIdx),1);
    setOccupancy(env.groundMap, rowColPairs, freeVals, 'grid');

    %% 2) Create 3D occupancyMap3D and fill with free cells
    env.occupancyMap3D = occupancyMap3D(1);
    [X3, Y3, Z3] = ndgrid(0:cfg.mapWidth-1, 0:cfg.mapHeight-1, 0:cfg.mapDepth-1);
    allPoints3D  = [X3(:), Y3(:), Z3(:)];
    setOccupancy(env.occupancyMap3D, allPoints3D, 0);

    %% 3) Place random buildings and extrude in 3D
    for bIdx = 1:cfg.numBuildings
        xStart = randi([0, max(0, cfg.mapWidth - 40)]);
        yStart = randi([0, max(0, cfg.mapHeight - 40)]);
        bWidth  = randi([20, 40]); 
        bLength = randi([20, 40]);

        xEnd = min(xStart + bWidth,  cfg.mapWidth  - 1);
        yEnd = min(yStart + bLength, cfg.mapHeight - 1);

        % Mark building footprint in 2D
        for x = xStart:xEnd
            for y = yStart:yEnd
                setOccupancy(env.groundMap, [y, x], 1, 'grid');
            end
        end

        % Extrude building in 3D
        buildingHeight = randi([30, 80]);
        bxRange        = xStart:xEnd;
        byRange        = yStart:yEnd;
        bzRange        = 0:buildingHeight;
        setCuboidOccupied(env.occupancyMap3D, bxRange, byRange, bzRange);
    end

    %% 4) Spawn survivors in free cells on the ground
    env.survivors = struct('id', {}, 'position', {}, 'priority', {}, ...
                           'isRescued', {}, 'assignedVehicle', {});
    for sID = 1:cfg.numSurvivors
        placed = false;
        while ~placed
            sx = 1 + (cfg.mapWidth  - 2)*rand();
            sy = 1 + (cfg.mapHeight - 2)*rand();

            colI = floor(sx);
            rowI = floor(sy);

            if colI<0 || colI>=cfg.mapWidth || rowI<0 || rowI>=cfg.mapHeight
                continue;
            end

            occVal = getOccupancy(env.groundMap, [rowI, colI], 'grid');
            if occVal < 0.5
                placed = true;
                env.survivors(sID).id             = sID;
                env.survivors(sID).position       = [sx, sy, 0];
                env.survivors(sID).priority       = randi([1 3]);
                env.survivors(sID).isRescued      = false;
                env.survivors(sID).assignedVehicle= [];
            end
        end
    end
end

function setCuboidOccupied(occMap3D, xRange, yRange, zRange)
% setCuboidOccupied  Marks a rectangular cuboid region as occupied in the 3D map.
    [X, Y, Z] = ndgrid(xRange, yRange, zRange);
    points    = [X(:), Y(:), Z(:)];
    setOccupancy(occMap3D, points, 1);
end