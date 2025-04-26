function tests = testCreateEnvironment
% Simple CI unit-test for createEnvironment.m
tests = functiontests(localfunctions);
end

function basicMapTest(~)
    cfg = config();
    env = createEnvironment(cfg);

    % 1) map dimensions correct
    assert(isequal(env.groundMap.GridSize, [cfg.mapHeight cfg.mapWidth]));

    % 2) no survivor spawned inside an obstacle
    S = vertcat(env.survivors.position);            % Nx3
    occ = getOccupancy(env.groundMap, S(:,[2 1]), "world");
    assert(all(occ < 0.5), ...
        'At least one survivor overlaps an occupied cell.');
end