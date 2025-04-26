function runExperiments()
% RUNEXPERIMENTS  A dedicated script to systematically test multiple 
% configurations (seeds, environment sizes, RRT vs. RRT*, nearest vs. centroid).
% It calls runRescueMission for each scenario, collects the data,
% and exports to a CSV file for further analysis.
%
% Place this in the same folder as runRescueMission.m or ensure the path 
% is set to call it. Adjust loops below to vary more parameters if desired.

    % 1) Variation Ranges
    seedList      = 1:3;                % e.g. 3 seeds for demonstration
    mapWidthList  = [300, 500];         % testing 2 environment sizes
    rrtOptions    = [false, true];      % false => RRT, true => RRT*
    approachList  = ["nearest", "centroid"];

    % Additional loops for building density, survivors, etc.
    buildingList  = [30, 60];
    survivorList  = [15, 25];

    % 2) Preallocate results cell
    resultsCell = {
        'Seed','MapWidth','MapHeight','NumBuildings','NumSurvivors','useRRTStar','Approach',...
        'TimeTaken','UAV1resc','UAV2resc','UAV3resc','UAV4resc',...
        'UAV1dist','UAV2dist','UAV3dist','UAV4dist'
    };
    rowIdx = 2;  % row 1 is headers

    % 3) Nested Loops Over All Configurations
    for seed = seedList
        rng(seed);  % fix RNG for reproducibility each run

        for mw = mapWidthList
            mh = mw;  % if you want them square

            for bCount = buildingList
                for sCount = survivorList

                    for useRRTStar = rrtOptions
                        for approach = approachList

                            % 3.1) Build config from defaults
                            cfg = config();
                            % 3.2) Override parameters
                            cfg.mapWidth     = mw;
                            cfg.mapHeight    = mh;
                            cfg.numBuildings = bCount;
                            cfg.numSurvivors = sCount;
                            
                            cfg.useRRTStar = useRRTStar;

                            cfg.centroidApproach = false;
                            cfg.kmeansApproach   = false;
                            if approach == "centroid"
                                cfg.centroidApproach = true;
                            end

                            % Optionally, bigger time limit for large maps
                            % cfg.totalSimTime = 600; 

                            % 3.3) Attempt to run the simulation
                            try
                                [timeTaken, uavRescueCounts, uavDistances] = runRescueMission(cfg);
                            catch ME
                                % If runRescueMission fails, we skip but log a warning
                                warning('Scenario failed (seed=%d, map=%dx%d, build=%d, surv=%d, RRTStar=%d, approach=%s). Error: %s',...
                                    seed, mw, mh, bCount, sCount, useRRTStar, approach, ME.message);
                                % Fill placeholders so we don't lose a row
                                timeTaken = NaN;
                                uavRescueCounts = [NaN NaN NaN NaN];
                                uavDistances    = [NaN NaN NaN NaN];
                            end

                            % 3.4) Gather results
                            u1r = uavRescueCounts(1);
                            u2r = uavRescueCounts(2);
                            u3r = uavRescueCounts(3);
                            u4r = uavRescueCounts(4);

                            if ~isempty(uavDistances)
                                u1d = uavDistances(1);
                                u2d = uavDistances(2);
                                u3d = uavDistances(3);
                                u4d = uavDistances(4);
                            else
                                [u1d,u2d,u3d,u4d] = deal(NaN);
                            end

                            % 3.5) Store in resultsCell
                            resultsCell{rowIdx,1}  = seed;
                            resultsCell{rowIdx,2}  = mw;
                            resultsCell{rowIdx,3}  = mh;
                            resultsCell{rowIdx,4}  = bCount;
                            resultsCell{rowIdx,5}  = sCount;
                            resultsCell{rowIdx,6}  = useRRTStar;
                            resultsCell{rowIdx,7}  = char(approach);
                            resultsCell{rowIdx,8}  = timeTaken;
                            resultsCell{rowIdx,9}  = u1r;
                            resultsCell{rowIdx,10} = u2r;
                            resultsCell{rowIdx,11} = u3r;
                            resultsCell{rowIdx,12} = u4r;
                            resultsCell{rowIdx,13} = u1d;
                            resultsCell{rowIdx,14} = u2d;
                            resultsCell{rowIdx,15} = u3d;
                            resultsCell{rowIdx,16} = u4d;

                            rowIdx = rowIdx + 1;

                            % Print progress
                            fprintf('Done: seed=%d, map=(%dx%d), build=%d, surv=%d, RRTStar=%d, approach=%s => time=%.2f\n',...
                                seed, mw, mh, bCount, sCount, useRRTStar, approach, timeTaken);
                        end
                    end
                end
            end
        end
    end

    % 4) Convert to Table and Save as CSV
    resultsTable = cell2table(resultsCell(2:end,:), 'VariableNames', resultsCell(1,:));
    csvFilename = 'experiment_results.csv';
    writetable(resultsTable, csvFilename);

    fprintf('\nAll experiments completed! Data saved to %s\n', csvFilename);
end