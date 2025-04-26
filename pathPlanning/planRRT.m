function path = planRRT(startPos, goalPos, env, cfg, mode)
% PLANRRT  Implements a basic RRT in 2D or 3D with optional debug visuals.
%
%   path = planRRT(startPos, goalPos, env, cfg, mode)
%   - startPos, goalPos: [x,y] or [x,y,z] based on mode ('2D' or '3D')
%   - env: environment struct (occupancyMap3D for collision checks)
%   - cfg: struct with RRT parameters (max iterations, step size, etc.)
%   - mode: '2D' or '3D'
%
% Returns an Nx3 path (or Nx2 embedded in Nx3 if 2D) from startPos to goalPos,
% or empty if no solution is found.

    % RRT parameters
    maxIters        = cfg.rrtMaxIterations;
    stepSize        = cfg.rrtStepSize;
    goalBias        = cfg.rrtGoalBias;
    reachThreshold  = 5.0;  % distance considered "close enough" to goal

    % Determine dimension (2D or 3D)
    if strcmp(mode, '2D')
        dim = 2;
    else
        dim = 3;
    end

    % Initialize tree with a start node
    startNode.pos    = startPos(1:dim);
    startNode.parent = 0;
    treeNodes        = startNode;

    goalReached = false;
    goalIdx     = -1;

    % Track the node closest to goal for partial-path updates
    bestDistToGoal = inf;
    bestNodeIdx    = 1;

    % Optional debug plotting
    if cfg.debug
        figure(999); clf; hold on; grid on;
        if dim == 2
            xlabel('X'); ylabel('Y');
            title('RRT Debug (2D)');
        else
            xlabel('X'); ylabel('Y'); zlabel('Z');
            title('RRT Debug (3D)');
            view(3);
        end
    end
    showPartialPathEvery = 100;  % show partial path every 100 expansions

    % Main RRT loop
    for iIter = 1:maxIters
        % (A) Sample a random point or goal (goalBias chance)
        if rand() < goalBias
            sample = goalPos(1:dim);
        else
            sample = sampleRandom(dim, cfg);
        end

        % (B) Find nearest node in the tree
        [nearestIdx, ~] = findNearest(treeNodes, sample);

        % (C) Extend from that node
        newPos = extend(treeNodes(nearestIdx).pos, sample, stepSize);

        % (D) Collision check along the new segment
        if ~checkLineCollision(treeNodes(nearestIdx).pos, newPos, env, mode)
            % Accept this new node
            newNode.pos    = newPos;
            newNode.parent = nearestIdx;
            treeNodes(end+1) = newNode; %#ok<AGROW>

            % Debug: draw new edge
            if cfg.debug
                oldPos = treeNodes(nearestIdx).pos;
                figure(999);
                if dim == 2
                    plot([oldPos(1), newPos(1)], [oldPos(2), newPos(2)], 'g-');
                else
                    plot3([oldPos(1), newPos(1)], ...
                          [oldPos(2), newPos(2)], ...
                          [oldPos(3), newPos(3)], 'g-');
                end
                drawnow limitrate;
            end

            % (E) Update best-so-far if closer to goal
            dGoal = norm(newPos - goalPos(1:dim));
            if dGoal < bestDistToGoal
                bestDistToGoal = dGoal;
                bestNodeIdx    = numel(treeNodes);
            end

            % (F) Check if goal is reached
            if dGoal < reachThreshold
                goalReached = true;
                goalIdx     = numel(treeNodes);
                break;
            end
        end

        % Periodic partial-path visualization
        if cfg.debug && mod(iIter, showPartialPathEvery) == 0
            partialPath = reconstructPath(treeNodes, bestNodeIdx);
            figure(999);
            if dim == 2
                plot(partialPath(:,1), partialPath(:,2), 'r-', 'LineWidth',2);
            else
                plot3(partialPath(:,1), partialPath(:,2), partialPath(:,3), 'r-', 'LineWidth',2);
            end
            drawnow limitrate;
            fprintf('Iter %d: bestDist=%.2f, treeSize=%d\n', ...
                    iIter, bestDistToGoal, numel(treeNodes));
        end
    end

    % If we never reached goal
    if ~goalReached
        fprintf('RRT: No path after %d iterations. ClosestDist=%.2f\n', ...
                maxIters, bestDistToGoal);
        path = [];
        return;
    end

    % Attempt final link to exact goal if not colliding
    finalPos = treeNodes(goalIdx).pos;
    if ~checkLineCollision(finalPos, goalPos(1:dim), env, mode)
        treeNodes(end+1).pos    = goalPos(1:dim);
        treeNodes(end).parent   = goalIdx;
        goalIdx = numel(treeNodes);
    end

    % Reconstruct final path
    pathNodes = reconstructPath(treeNodes, goalIdx);

    % If 2D, embed z=0
    if dim == 2
        path = [pathNodes, zeros(size(pathNodes,1),1)];
    else
        path = pathNodes;
    end

    fprintf('RRT succeeded with %d waypoints, dist=%.2f.\n', ...
            size(path,1), bestDistToGoal);
end

%% ---------- HELPER FUNCTIONS ----------

function s = sampleRandom(dim, cfg)
    if dim == 2
        sx = rand() * cfg.mapWidth;
        sy = rand() * cfg.mapHeight;
        s  = [sx, sy];
    else
        sx = rand() * cfg.mapWidth;
        sy = rand() * cfg.mapHeight;
        sz = rand() * cfg.mapDepth;
        s  = [sx, sy, sz];
    end
end

function [idx, distMin] = findNearest(tree, sample)
    distMin = inf;
    idx     = 1;
    for i = 1:numel(tree)
        d = norm(tree(i).pos - sample);
        if d < distMin
            distMin = d;
            idx     = i;
        end
    end
end

function newPos = extend(p1, p2, stepSize)
    dir  = p2 - p1;
    dist = norm(dir);
    if dist < stepSize
        newPos = p2;
    else
        newPos = p1 + (stepSize/dist)*dir;
    end
end

function pathNodes = reconstructPath(treeNodes, nodeIdx)
    pathNodes = [];
    curr = nodeIdx;
    while curr > 0
        pathNodes = [treeNodes(curr).pos; pathNodes]; %#ok<AGROW>
        curr = treeNodes(curr).parent;
    end
end