function [timeTaken, uavRescueCounts, uavDistances] = runRescueMission(cfg)
% RUNRESCUEMISSION  Runs a multi-UAV rescue scenario based on a given config.
% 
% Returns:
%   timeTaken       - Total simulation time (seconds) until all survivors are rescued
%   uavRescueCounts - 1×(number of UAVs) vector counting how many survivors each UAV rescued
%   uavDistances    - 1×(number of UAVs) vector of total distance traveled by each UAV (optional)
%
% We also have a small try/catch around planPath(...) to skip invalid goals and keep the simulation alive.

    % Optionally add subfolders to path if needed:
    addpath(genpath(pwd));

    if nargin < 1
        cfg = config();
    end

    clc; clearvars -except cfg timeTaken uavRescueCounts;

    % Build environment from config
    env = createEnvironment(cfg);

    % Create four UAVs (2 ground, 2 aerial), or based on cfg.numAerial/numGround
    g1 = GroundVehicle(1, [10,10,0], 2);
    g2 = GroundVehicle(2, [20,20,0], 2);
    d1 = AerialDrone(3, [10,10,50], 4);
    d2 = AerialDrone(4, [30,30,60], 4);
    uavs = {g1, g2, d1, d2};

    % Initialize assignedSurvivorID
    for i = 1:numel(uavs)
        uavs{i}.assignedSurvivorID = [];
    end

    survivors   = env.survivors;
    simTime     = 0;
    dt          = 1.0;
    % You can use cfg.totalSimTime if you prefer, else default to 600
    maxSimTime  = 600;  
    done        = false;

    % Track how many survivors each UAV rescues
    uavRescueCounts = zeros(1, numel(uavs));

    % (Optional) Set up a 3D figure
    fig3D = figure('Name','3D Multi-UAV Mission');
    show(env.occupancyMap3D);
    axis equal; view(45,30);
    title('3D Environment: Multi-UAV Rescue');
    hold on;
    xlim([0 cfg.mapWidth]); 
    ylim([0 cfg.mapHeight]); 
    zlim([0 cfg.mapDepth]);

    while ~done && simTime < maxSimTime
        simTime = simTime + dt;

        %% (1) Move UAVs
        for i = 1:numel(uavs)
            uavs{i}.moveStep(dt);
        end

        %% (2) Check if any UAV rescued its assigned survivor
        for i = 1:numel(uavs)
            sid = uavs{i}.assignedSurvivorID;
            if ~isempty(sid) && ~survivors(sid).isRescued
                distToSurv = norm(uavs{i}.position(1:2) - survivors(sid).position(1:2));
                if distToSurv < 5
                    survivors(sid).isRescued      = true;
                    survivors(sid).assignedVehicle = [];
                    uavs{i}.assignedSurvivorID    = [];

                    % Increment UAV's rescue count
                    uID = uavs{i}.id;
                    uavRescueCounts(uID) = uavRescueCounts(uID) + 1;

                    if cfg.debug
                        fprintf('UAV %d rescued Survivor %d at time=%.1f\n',...
                            uavs{i}.id, sid, simTime);
                    end
                end
            end
        end

        %% (3) Assign survivors to idle UAVs
        for i = 1:numel(uavs)
            if isempty(uavs{i}.assignedSurvivorID)
                sid = pickSurvivor(uavs{i}, survivors, cfg);
                if ~isempty(sid)
                    survivors(sid).assignedVehicle = uavs{i}.id;
                    uavs{i}.assignedSurvivorID     = sid;
                    goalPos                         = survivors(sid).position;

                    % Clamp goal within map boundaries
                    goalPos(1) = max(0, min(goalPos(1), cfg.mapWidth  - 1));
                    goalPos(2) = max(0, min(goalPos(2), cfg.mapHeight - 1));

                    % Ground vehicles => z=0; aerial => clamp z
                    if contains(class(uavs{i}), 'GroundVehicle')
                        goalPos(3) = 0;
                    else
                        goalPos(3) = max(0, min(goalPos(3), cfg.mapDepth - 1));
                    end

                    if cfg.debug
                        fprintf('[DEBUG] UAV %d planning to Surv %d => [%.2f, %.2f, %.2f]\n',...
                            uavs{i}.id, sid, goalPos(1), goalPos(2), goalPos(3));
                    end

                    % Check occupancy at the goal cell in 2D
                    rowI  = floor(goalPos(2));
                    colI  = floor(goalPos(1));
                    occVal= getOccupancy(env.groundMap, [rowI, colI], 'grid');
                    if occVal > 0.5
                        % The goal is within an obstacle => skip
                        if cfg.debug
                            fprintf('[DEBUG] Goal cell occupied => skip Surv %d\n', sid);
                        end
                        uavs{i}.assignedSurvivorID     = [];
                        survivors(sid).assignedVehicle = [];
                        continue;
                    end

                    % Plan path with a try/catch to handle invalid starts/goals
                    try
                        uavs{i}.planPath(goalPos, env, cfg);
                    catch ME
                        warning('PlanPath failed for UAV %d to Surv %d: %s. Marking as skipped.',...
                            uavs{i}.id, sid, ME.message);
                        % Unassign this survivor so we don't get stuck
                        uavs{i}.assignedSurvivorID     = [];
                        survivors(sid).assignedVehicle = [];
                        continue;
                    end

                    if cfg.debug
                        fprintf('UAV %d assigned Surv %d\n', uavs{i}.id, sid);
                    end
                end
            end
        end

        %% (4) Check if all survivors are rescued
        allDone = all(arrayfun(@(s) s.isRescued, survivors));
        if allDone
            done = true;
        end

        %% (5) Update 3D visualization
        update3DPlot(fig3D, uavs, survivors);
        drawnow limitrate;
        pause(0.05);
    end

    timeTaken = simTime;

    if cfg.debug
        fprintf('All survivors rescued or time limit reached at time=%.1f\n', timeTaken);
        for i = 1:numel(uavs)
            fprintf('UAV %d rescued %d survivors.\n',...
                uavs{i}.id, uavRescueCounts(uavs{i}.id));
        end
    end

    % If you want to return total distance traveled for each UAV:
    if nargout > 2
        uavDistances = zeros(1, numel(uavs));
        for i = 1:numel(uavs)
            uavDistances(i) = uavs{i}.totalDistanceTraveled;
        end
    end
end

function update3DPlot(fig3D, uavs, survivors)
% Update 3D figure markers for UAVs and non-rescued survivors
    if ~ishandle(fig3D), return; end
    figure(fig3D); hold on;

    oldUAVs   = findall(gca,'Tag','UAVMarker');
    oldSurv   = findall(gca,'Tag','SurvivorMarker');
    delete(oldUAVs);
    delete(oldSurv);

    % Plot UAVs
    for i = 1:numel(uavs)
        pos = uavs{i}.position;
        if contains(class(uavs{i}), 'GroundVehicle')
            cVal = 'b'; 
        else
            cVal = 'r'; 
        end
        scatter3(pos(1), pos(2), pos(3), 80, cVal, 'filled',...
            'MarkerEdgeColor','k','LineWidth',1.2,'Tag','UAVMarker');
    end

    % Plot survivors
    for s = 1:numel(survivors)
        if ~survivors(s).isRescued
            sx = survivors(s).position(1);
            sy = survivors(s).position(2);
            sz = survivors(s).position(3);
            scatter3(sx, sy, sz, 50, 'g', 'filled',...
                'MarkerEdgeColor','k','Tag','SurvivorMarker');
        end
    end
end

%% pickSurvivor => choose a survivor not already rescued/assigned
function sid = pickSurvivor(uav, survivors, cfg)
    unrescIdx = find(~[survivors.isRescued]);

    % Exclude survivors already assigned
    candidateIdx = [];
    for sID = unrescIdx
        if ~isfield(survivors(sID), 'assignedVehicle') || isempty(survivors(sID).assignedVehicle)
            candidateIdx(end+1) = sID; %#ok<AGROW>
        end
    end
    if isempty(candidateIdx)
        sid = [];
        return;
    end

    % Decide selection approach
    if cfg.kmeansApproach
        sid = pickKMeansSurvivor(uav, survivors, candidateIdx);
    elseif cfg.centroidApproach
        sid = pickCentroidSurvivor(uav, survivors, candidateIdx);
    else
        sid = pickNearestSurvivor(uav, survivors, candidateIdx);
    end
end

function sid = pickNearestSurvivor(uav, survivors, candidateIdx)
    dMin = inf;
    sid  = [];
    for sID = candidateIdx
        d = norm(uav.position(1:2) - survivors(sID).position(1:2));
        if d < dMin
            dMin = d;
            sid  = sID;
        end
    end
end

function sid = pickCentroidSurvivor(~, survivors, candidateIdx)
    if isempty(candidateIdx)
        sid = [];
        return;
    end
    positions = reshape([survivors(candidateIdx).position],3,[])';
    cx = mean(positions(:,1));
    cy = mean(positions(:,2));

    dMin = inf;
    sid  = [];
    for sID = candidateIdx
        dx = survivors(sID).position(1) - cx;
        dy = survivors(sID).position(2) - cy;
        dist2 = dx^2 + dy^2;
        if dist2 < dMin
            dMin = dist2;
            sid  = sID;
        end
    end
end

function sid = pickKMeansSurvivor(uav, survivors, candidateIdx)
    if isempty(candidateIdx)
        sid = [];
        return;
    end

    positions = reshape([survivors(candidateIdx).position],3,[])';
    XY = positions(:,1:2);

    K = 4; 
    if size(XY,1) < K
        sid = pickNearestSurvivor(uav, survivors, candidateIdx);
        return;
    end

    [idx, C] = kmeans(XY, K, 'MaxIter',100, 'Replicates',1);

    UAVxy       = uav.position(1:2);
    distCenters = sum((C - UAVxy).^2, 2);
    [~, bestC]  = min(distCenters);

    clusterSurvs = candidateIdx(idx == bestC);
    if isempty(clusterSurvs)
        sid = pickNearestSurvivor(uav, survivors, candidateIdx);
        return;
    end

    cxy = C(bestC,:);
    dMin = inf;
    sid  = [];
    for s = clusterSurvs'
        xy = survivors(s).position(1:2);
        d2 = norm(xy - cxy);
        if d2 < dMin
            dMin = d2;
            sid  = s;
        end
    end
end