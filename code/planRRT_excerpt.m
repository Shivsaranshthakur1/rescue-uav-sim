% planRRT_excerpt.m  – Lines 12-46 of the full planRRT.m (trimmed)
% ---------------------------------------------------------------
% NOTE: this is *only* the key planning loop that illustrates how
% samples are generated, extended, and collision-checked. Helper
% functions and the final path-reconstruction are omitted here.
%
% See full implementation in pathPlanning/planRRT.m.

% ----- core parameters pulled from cfg --------------------------
maxIters       = cfg.rrtMaxIterations;
stepSize       = cfg.rrtStepSize;
goalBias       = cfg.rrtGoalBias;
reachThresh    = 5.0;          % (m) “close-enough” to goal

% ----- initialise tree with a single start node -----------------
startNode.pos    = startPos(1:dim);
startNode.parent = 0;
treeNodes        = startNode;

bestDist = inf;   bestIdx = 1;
goalIdx  = -1;    goalReached = false;

% ----------------- main incremental expansion loop --------------
for k = 1:maxIters
    % (A) random sample (goalBias chance of sampling the goal)
    if rand < goalBias
        qRand = goalPos(1:dim);
    else
        qRand = sampleRandom(dim, cfg);
    end

    % (B) nearest node in existing tree
    [qNearIdx, ~] = findNearest(treeNodes, qRand);
    qNear = treeNodes(qNearIdx).pos;

    % (C) extend towards sample by fixed step size
    qNew  = extend(qNear, qRand, stepSize);

    % (D) reject if segment collides
    if checkLineCollision(qNear, qNew, env, mode)
        continue;                             % skip this sample
    end

    % (E) accept new node
    newNode.pos    = qNew;
    newNode.parent = qNearIdx;
    treeNodes(end+1) = newNode;               %#ok<AGROW>

    % (F) bookkeeping: is this nearer the goal?
    dGoal = norm(qNew - goalPos(1:dim));
    if dGoal < bestDist
        bestDist = dGoal;   bestIdx = numel(treeNodes);
    end
    if dGoal < reachThresh
        goalReached = true; goalIdx = numel(treeNodes);
        break
    end
end
% ------------- rest of algorithm reconstructs path (…snip) ------