% make_chp4_figs.m
% ------------------------------------------------------------
% Generates:
%   figures/env_pipeline.png      – 4-stage environment pipeline
%   figures/seq_planPath.png      – planPath sequence diagram
%
% 2025-04-26

clear;  close all;  clc
outDir = fullfile(pwd,'figures');
if ~exist(outDir,'dir'), mkdir(outDir), end

%% -----------------------------------------------------------------------
%  1) PIPELINE DIAGRAM  (≈ 6 cm wide, 4 labelled blocks)
% ------------------------------------------------------------------------
f1 = figure('Units','centimeters','Position',[2 2 6 1.8], ...
            'Color','w','Visible','off');
axes('Position',[0 0 1 1]);  axis off; hold on
stages = {'initialise maps','place buildings','extrude 3-D cells','spawn survivors'};
n = numel(stages);
boxW = 1/n;             % equal width in axes coords
txtY = 0.55;            % vertical text position
col  = [235 241 251]/255;      % light blue fill
for i = 1:n
    x = (i-1)*boxW;
    rectangle('Position',[x 0 boxW 1], ...
              'FaceColor',col,'EdgeColor','k','LineWidth',1.2);
    text(x+boxW/2, txtY, stages{i}, ...
        'Horizontal','center','FontSize',9,'Interpreter','none')
    % arrow except after last box
    if i < n
        annotation('arrow',[x+boxW-0.01 x+boxW+0.01],[0.5 0.5],'LineWidth',1.2);
        % micro-label on arrow
        switch i
            case 1, aLbl = '→B loops';
            case 2, aLbl = '→extrude';
            case 3, aLbl = '→S loop';
        end
        text(x+boxW-0.005,0.32,aLbl,'FontSize',7,'Horizontal','right');
    end
end
exportgraphics(f1,fullfile(outDir,'env_pipeline.png'),'Resolution',300);

%% -----------------------------------------------------------------------
%  2) SEQUENCE DIAGRAM  (simple hand-coded plot)
% ------------------------------------------------------------------------
actors = {'Controller','UAV','Planner','Env','Collision\nCheck'};
m      = numel(actors);
lifex  = linspace(0.05,0.95,m);         % equally spaced x positions
lifey  = [0.87 0.13];                   % top & bottom of lifelines
f2 = figure('Units','centimeters','Position',[2 2 14 5], ...
            'Color','w','Visible','off');
axes('Position',[0 0 1 1]); axis off; hold on
set(gca,'XLim',[0 1],'YLim',[0 1]);

% lifelines + names
for i = 1:m
    plot([lifex(i) lifex(i)], lifey,'k:','LineWidth',0.7);
    text(lifex(i)-0.02, lifey(1)+0.05, actors{i}, ...
         'FontWeight','bold','FontSize',10,'Interpreter','none')
end

% helper for arrows
arrow = @(x0,y0,x1,y1,varargin) ...
    annotation('arrow',interp1([0 1],[x0 x1], [0 1]), ...
                       interp1([0 1],[y0 y1], [0 1]), varargin{:});

y0 = 0.78; dy = 0.10;  % vertical spacing of messages

% 1) Controller → UAV (planPath)
arrow(lifex(1),y0,lifex(2),y0,'LineWidth',1.2);
text(mean(lifex(1:2)), y0+0.03, '\texttt{planPath()}', ...
     'Interpreter','latex','FontSize',9,'Horizontal','center');

% 2) UAV → Planner  (internally)
y1 = y0-dy;
arrow(lifex(2),y1,lifex(3),y1,'LineWidth',1.2);
text(mean(lifex(2:3)), y1+0.03,'\texttt{computeRoute()}','Interpreter','latex','FontSize',9);

% 3) Planner → Env (query map)
y2 = y1-dy;
arrow(lifex(3),y2,lifex(4),y2,'LineWidth',1.2);
text(mean(lifex(3:4)), y2+0.03,'\texttt{queryEnv()}','Interpreter','latex','FontSize',9);

% 4) Env → CollisionChecker (isFree)
y3 = y2-dy;
arrow(lifex(4),y3,lifex(5),y3,'LineWidth',1.2);
text(mean(lifex(4:5)), y3+0.03,'\texttt{isFree()}', ...
     'Interpreter','latex','FontSize',9);

% 5) return Planner → UAV (dashed)
y4 = y3-dy;
arrow(lifex(3),y4,lifex(2),y4,'LineWidth',1.2,'LineStyle','--');
text(mean(lifex(2:3)), y4+0.03,'path','FontSize',9);

exportgraphics(f2, fullfile(outDir,'seq_planPath.png'),'Resolution',300);

fprintf('✓  Two updated figures written to %s\n', outDir); 