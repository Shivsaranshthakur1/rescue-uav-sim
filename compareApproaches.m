function compareApproaches()
% COMPAREAPPROACHES  Runs multiple rescue scenarios to compare 
% RRT vs. RRT* and nearest-based vs. centroid-based survivor assignment.
%
% This function loops over each combination, calls runRescueMission(cfg), 
% measures the total rescue time, and prints final results.

    approaches = ["nearest","centroid"];  % Skips kmeans for simplicity
    rrtOptions = [false,true];            % false => RRT, true => RRT*

    allResults = [];

    for useRRTStar = rrtOptions
        for approach = approaches
            % Build config
            cfg = config();
            cfg.debug = false;
            cfg.useRRTStar = useRRTStar;
            cfg.centroidApproach = false;
            cfg.kmeansApproach   = false;

            if approach == "centroid"
                cfg.centroidApproach = true;
            end

            fprintf('Running approach=%s, RRTStar=%d...\n', approach, useRRTStar);

            timeTaken = runRescueMission(cfg);

            entry.planner  = "RRT";
            if useRRTStar
                entry.planner = "RRT*";
            end
            entry.approach = approach;
            entry.time     = timeTaken;

            allResults = [allResults; entry]; %#ok<AGROW>
        end
    end

    disp('====== Final Comparison Results ======');
    for i = 1:numel(allResults)
        fprintf('%s + %s => time=%.1f\n', ...
            allResults(i).planner, ...
            allResults(i).approach, ...
            allResults(i).time);
    end
end