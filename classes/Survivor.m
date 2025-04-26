classdef Survivor < handle
    % SURVIVOR  Represents a rescue survivor in the environment.
    %
    % Properties:
    %   id        - Unique integer identifier
    %   position  - [x, y, z] coordinates in the environment
    %   priority  - An integer from 1 (high) to 3 (low)
    %   isRescued - Boolean indicating whether this survivor is already rescued
    
    properties
        id        (1,1) double
        position  (1,3) double
        priority  (1,1) double {mustBeInteger}
        isRescued (1,1) logical
    end
    
    methods
        function obj = Survivor(id, pos, prio)
            % Constructor: Initialize a Survivor with given ID, position, and priority.
            %
            % If priority is not specified, defaults to 2.
            if nargin < 3
                prio = 2; % default priority
            end
            
            obj.id        = id;
            obj.position  = pos;
            obj.priority  = prio;
            obj.isRescued = false;
        end
    end
end