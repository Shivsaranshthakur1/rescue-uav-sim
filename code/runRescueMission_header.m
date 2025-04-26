% runRescueMission_header.m  – first ~25 lines of runRescueMission.m
% -----------------------------------------------------------------
function [timeTaken,uavRescueCounts,uavDistances] = runRescueMission(cfg)
% RUNRESCUEMISSION  Execute one multi-UAV rescue scenario and return
% summary metrics.
%
% Arguments
%   cfg – struct produced by config() with all simulation settings
%
% Returns
%   timeTaken        – total simulated seconds until all rescued
%   uavRescueCounts  – 1×N array of survivors rescued by each UAV
%   uavDistances     – 1×N array of distance travelled by each UAV
%
% The routine:
%   1. Creates an environment (createEnvironment)
%   2. Instantiates 2 ground + 2 aerial vehicles
%   3. Runs a discrete-time loop (dt = cfg.timeStep)
%   4. Assigns survivors, calls planPath / moveStep
%   5. Stops when all survivors rescued or time exceeds limit

if nargin < 1
    cfg = config();            % fallback to defaults
end
addpath(genpath(pwd));          % ensure subfolders on path

env         = createEnvironment(cfg);  % build maps + survivors
[g1,g2,d1,d2] = spawnDefaultUAVs(cfg); % helper not shown here
uavs        = {g1,g2,d1,d2};           % cell array of handles
survivors   = env.survivors;

simTime   = 0;                  dt = cfg.timeStep;
maxTime   = cfg.totalSimTime;   done = false;
uavRescueCounts = zeros(1,numel(uavs));

% ----------- main simulation loop starts below (…snip) ----------