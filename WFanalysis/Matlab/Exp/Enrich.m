classdef Enrich < handle
    properties
        dataPath = 'D:\WF';
        resultPath = fullfile(Param().folderFigure, 'EnrichedCage')
        objRegIMcorr;
        objRegIMcorrCopy;      
        actMapThre = 0.5;     
        figActMap;
        figActEdge;
    end
    methods
        %% Constructor
        function obj = Enrich()
        end
        
        
        %% Plot active map
        function obj = PlotActMap(obj, actMapThre)
            
            obj.objRegIMcorrCopy = copy(obj.objRegIMcorr);
            
            if nargin == 2
                
                if isscalar(actMapThre) && actMapThre >= 0 && actMapThre <= 1
                    obj.actMapThre = actMapThre;
                else
                    error('actMapThre should be a numeric value between 0 and 1');
                end
                
            end
            
            fprintf('Plotting active map with threshold %.1f...\n', obj.actMapThre);
            
            avgVar = {'group'};
            obj.objRegIMcorrCopy.CalAvgIMcorr(avgVar);
            obj.objRegIMcorrCopy.CalActMap(obj.actMapThre);
            obj.figActMap = figure('color', 'w');
            tiledlayout(2, 2);
            tiledlayout(1,2);
            titleStr = {'Control','Enriched'};
            for i = 1:2
                nexttile(i)
                imshowFrameRefBregma(obj.objRegIMcorrCopy.fileTable.IMcorr{i,1}(:,:,28));
                title(titleStr{i})
            end
            figResize(1,2);figTileFormat;figTileLabel;
            
            
        end
        
        %% Plot active edge
        function obj = PlotActEdge(obj, actMapThre)
            
            % set threshold for active map calculation
            
            if nargin == 2
                
                if isscalar(actMapThre) && actMapThre >= 0 && actMapThre <= 1
                    obj.actMapThre = actMapThre;
                else
                    error('actMapThre should be a numeric value between 0 and 1');
                end
                
            end
            
            fprintf('Plotting active edge with threshold %.1f...\n', obj.actMapThre);
            
            
            % get edge of active map (avg across mice)
            obj.objRegIMcorrCopy = copy(obj.objRegIMcorr);
            obj.objRegIMcorrCopy.fileTable(ismember(obj.objRegIMcorrCopy.fileTable.mouse,'m2371'),:) = [];
            avgVar = {'group'};
            obj.objRegIMcorrCopy.CalAvgIMcorr(avgVar);
            obj.objRegIMcorrCopy.CalActMap(obj.actMapThre);
            edgeData = obj.objRegIMcorrCopy.fileTable;
            for i = 1:2
                actEdge = bwboundaries(flipud(edgeData.IMcorr{i}(:, :, 28)));
                actEdge = actEdge{1};
                actEdgeX = actEdge(:, 2);
                actEdgeY = actEdge(:, 1);
                edgeData.edgeX{i} = actEdgeX;
                edgeData.edgeY{i} = actEdgeY;
            end
            
            % get centroid of active map
            obj.objRegIMcorrCopy = copy(obj.objRegIMcorr);
            obj.objRegIMcorrCopy.fileTable(ismember(obj.objRegIMcorrCopy.fileTable.mouse,'m2371'),:) = [];
            avgVar = {'group', 'mouse'};
            obj.objRegIMcorrCopy.CalAvgIMcorr(avgVar);
            obj.objRegIMcorrCopy.CalActMap(obj.actMapThre);
            
            obj.objRegIMcorrCopy.CalActProps();
            
            centroidData = obj.objRegIMcorrCopy.fileTable;
            centroidData = centroidData((centroidData.FramePeak == 1 & centroidData.ComponentId == 1), :);
            
            % plot data
            centroidDataTrainedBaseline = centroidData(ismember(centroidData.group,'Control'), :);
            edgeDataTrainedBaseline = edgeData(ismember(edgeData.group,'Control'), :);
            centroidDataTrainedPost = centroidData(ismember(centroidData.group,'Enriched'), :);
            edgeDataTrainedPost = edgeData(ismember(edgeData.group,'Enriched'), :);
            
            
            pix2mm_X = 18;
            obj.figActEdge = figure('color','w');
            tiledlayout(1,1);
            nexttile(1)
            plot(256,256, 'o', 'MarkerSize', 4, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'k');
            
            for i = 1:height(centroidDataTrainedBaseline)
                hold on;
                plot(centroidDataTrainedBaseline.WeightedCentroid(i,1), 512 - centroidDataTrainedBaseline.WeightedCentroid(i,2), 'o', 'MarkerSize', 4, 'MarkerEdgeColor', [0,160,135]/255);
            end
            
            hold on;
            plot(edgeDataTrainedBaseline.edgeX{1}, edgeDataTrainedBaseline.edgeY{1}, 'Color', [0,160,135]/255, 'LineWidth', 3);
            
            for i = 1:height(centroidDataTrainedPost)
                hold on;
                plot(centroidDataTrainedPost.WeightedCentroid(i,1), 512-centroidDataTrainedPost.WeightedCentroid(i,2), '^', 'MarkerSize', 4, 'MarkerEdgeColor', [230,75,53]/255);
            end
            
            hold on;
            plot(edgeDataTrainedPost.edgeX{1}, edgeDataTrainedPost.edgeY{1}, 'Color', [230,75,53]/255, 'LineWidth', 3);
            
            xlabel('ML (mm)'); ylabel('AP (mm)');
            axis square
            set(gca,...
                'Visible', 'on',...
                'Box', 'off',...
                'TickDir', 'out',...
                'XTick', 256 - (4000:-500:0) / pix2mm_X,...
                'XTickLabel', -4:0.5:0, ...
                'YTick', 256 + (-3000:500:3000) / pix2mm_X,...
                'YTickLabel', 3:-0.5:-3,...
                'XLim', 256 - [4000 -500] / pix2mm_X,...
                'YLim', 256 + [-2000 2000] / pix2mm_X,...
                'XGrid', 'on',...
                'YGrid', 'on')
            
            maskUeno = MaskUeno();
            hold on;
            fill(maskUeno.coordsSensory(:, 1), maskUeno.coordsSensory(:, 2), 'k', 'FaceAlpha',0.1, 'EdgeColor','none');
            hold on;
            fill(maskUeno.coordsMotor(:, 1), maskUeno.coordsMotor(:, 2), 'm', 'FaceAlpha',0.1,'EdgeColor','none');
            
            figTileFormat;figTileLabel;figResize(1,1)
        end
        
        %% Export active map properties
        function obj = ExportActProps(obj, actMapThre)
            if nargin == 2
                
                if isscalar(actMapThre) && actMapThre >= 0 && actMapThre <= 1
                    obj.actMapThre = actMapThre;
                else
                    error('actMapThre should be a numeric value between 0 and 1');
                end
            end
            
            fprintf('Exporting active map properties with threshold %.1f...\n', obj.actMapThre);
            
            % calculate active map properties
            obj.objRegIMcorrCopy = copy(obj.objRegIMcorr);
            obj.objRegIMcorrCopy.CalActMap(obj.actMapThre);
            obj.objRegIMcorrCopy.CalActProps();
            obj.objRegIMcorrCopy.CleanVar({'Edge','Component','Extrema','PixelIdxList','PixelList','PixelValues'});
            
        end
    end
end