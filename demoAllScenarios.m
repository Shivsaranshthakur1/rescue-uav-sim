function demoAllScenarios()
% DEMOALLSCENARIOS  Runs four rescue scenarios in sequence:
%   1) RRT + Nearest
%   2) RRT + Centroid
%   3) RRT* + Nearest
%   4) RRT* + Centroid
%
% Each scenario constructs an environment, runs the mission, and logs results.

    addpath(genpath(pwd));  % Ensure all subfolders are on the MATLAB path

    % Define the four scenario configurations
    scenarios = {
       struct('useRRTStar', false, 'centroidApproach', false),  % RRT + Nearest
       struct('useRRTStar', false, 'centroidApproach', true ),  % RRT + Centroid
       struct('useRRTStar', true,  'centroidApproach', false),  % RRT* + Nearest
       struct('useRRTStar', true,  'centroidApproach', true )   % RRT* + Centroid
    };

    % Store final results for output
    finalResults = struct('scenario', {}, 'planner', {}, 'approach', {}, ...
                          'time', {}, 'UAV1res', {}, 'UAV2res', {}, ...
                          'UAV3res', {}, 'UAV4res', {});

    % Iterate over each scenario
    for i = 1:numel(scenarios)
        % 1) Configure parameters
        cfg = config();
        cfg.debug = true;

        cfg.mapWidth   = 1000;
        cfg.mapHeight  = 800;
        cfg.mapDepth   = 120;
        cfg.numRoadSeeds = 30;      % used in environment generation
        cfg.numSurvivors = 25;

        cfg.useRRTStar       = scenarios{i}.useRRTStar;
        cfg.centroidApproach = scenarios{i}.centroidApproach;
        cfg.kmeansApproach   = false;  % not used in this driver

        % Planner / approach strings
        plannerStr = "RRT";
        if cfg.useRRTStar
            plannerStr = "RRT*";
        end
        approachStr = "Nearest";
        if cfg.centroidApproach
            approachStr = "Centroid";
        end

        fprintf("\n===== Starting scenario %d: %s + %s =====\n", ...
            i, plannerStr, approachStr);

        % 2) Run the scenario
        [timeTaken, rescueCounts] = runRescueMission(cfg);

        fprintf("===== Scenario %d finished: %s + %s => time=%.1f =====\n\n", ...
            i, plannerStr, approachStr, timeTaken);

        % 3) Log results
        finalResults(i).scenario = i;
        finalResults(i).planner  = plannerStr;
        finalResults(i).approach = approachStr;
        finalResults(i).time     = timeTaken;
        finalResults(i).UAV1res  = rescueCounts(1);
        finalResults(i).UAV2res  = rescueCounts(2);
        finalResults(i).UAV3res  = rescueCounts(3);
        finalResults(i).UAV4res  = rescueCounts(4);

        % Pause before moving to the next scenario
        if i < numel(scenarios)
            disp("Press any key to continue to the next scenario...");
            pause;
            close all;
        end
    end

    % 4) Print final summary
    disp("All four scenarios completed successfully!");
    disp("Final Results:");
    for i = 1:numel(finalResults)
        fr = finalResults(i);
        fprintf("Scenario %d => %s + %s: time=%.1f, UAV rescues=[%d, %d, %d, %d]\n", ...
            fr.scenario, fr.planner, fr.approach, fr.time, ...
            fr.UAV1res, fr.UAV2res, fr.UAV3res, fr.UAV4res);
    end
end