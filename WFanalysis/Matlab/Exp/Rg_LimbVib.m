classdef Rg_LimbVib < Rg

    properties
        dataFilter = {'WF_V', 'TrialAll'};
        expInfo = 'WF-ClearSkullVib';
    end

    methods
        %% Constructor
        function obj = Rg_LimbVib()
            obj = obj@Rg();
            obj.LoadIMcorr();
        end

        %% Load IMcorr data
        function obj = LoadIMcorr(obj)

            if exist(fullfile(obj.resultPath, 'Rg_LimbVib_ActIMcorr.mat'), "file")
                fprintf('Loading IMcorr data from existing file...\n');
                load(fullfile(obj.resultPath, 'Rg_LimbVib_ActIMcorr.mat'), 'objFileTableActReg');
                obj.objRegIMcorr = objFileTableActReg;
                fprintf('IMcorr data loaded ...\n');
            else
                fprintf('Loading IMcorr data from raw file...\n');
                obj.objRegIMcorr = FileTable_Act_Reg_IMcorr(obj.dataPath, obj.dataFilter).AddGroupInfo(obj.expInfo);
                objFileTableActReg = obj.objRegIMcorr;
                save(fullfile(obj.resultPath, 'Rg_LimbVib_ActIMcorr.mat'), 'objFileTableActReg', '-v7.3');
                fprintf('IMcorr data loaded ...\n');
            end

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

            avgVar = {'group', 'phase'};
            obj.objRegIMcorrCopy.CalAvgIMcorr(avgVar);
            obj.objRegIMcorrCopy.CalActMap(obj.actMapThre);
            obj.figActMap = figure('color', 'w');
            tiledlayout(1, 2);
            titleStr = {'Control', 'Post-Training'};

            for i = 1:2
                nexttile(i)
                imshowFrameRefBregma(obj.objRegIMcorrCopy.fileTable.IMcorr{i, 1}(:, :, 28));
                title(titleStr{i})
            end

            figResize(1, 2); figTileFormat; figTileLabel;
            saveas(obj.figActMap, fullfile(obj.resultPath, ['Rg_LimbVib_ActMap_', num2str(obj.actMapThre), '.svg']));

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

            avgVar = {'group', 'phase'};
            obj.objRegIMcorrCopy.CalAvgIMcorr(avgVar);
            obj.objRegIMcorrCopy.CalActMap(actMapThre);
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

            avgVar = {'group', 'phase', 'mouse'};
            obj.objRegIMcorrCopy.CalAvgIMcorr(avgVar);
            obj.objRegIMcorrCopy.CalActMap(actMapThre);

            obj.objRegIMcorrCopy.CalActProps();

            centroidData = obj.objRegIMcorrCopy.fileTable;
            centroidData = centroidData((centroidData.FramePeak == 1 & centroidData.ComponentId == 1), :);

            % plot data
            % plot data
            centroidDataTrainedBaseline = centroidData((ismember(centroidData.group, 'Trained') & ismember(centroidData.phase, 'Baseline')), :);
            edgeDataTrainedBaseline = edgeData((ismember(edgeData.group, 'Trained') & ismember(edgeData.phase, 'Baseline')), :);
            centroidDataTrainedPost = centroidData((ismember(centroidData.group, 'Trained') & ismember(centroidData.phase, 'Post-Training')), :);
            edgeDataTrainedPost = edgeData((ismember(edgeData.group, 'Trained') & ismember(edgeData.phase, 'Post-Training')), :);

            pix2mm_X = 18;
            obj.figActEdge = figure('color', 'w');
            tiledlayout(1, 1);
            nexttile(1)
            plot(256, 256, 'o', 'MarkerSize', 4, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'k');

            for i = 1:height(centroidDataTrainedBaseline)
                hold on;
                plot(centroidDataTrainedBaseline.WeightedCentroid(i, 1), 512 - centroidDataTrainedBaseline.WeightedCentroid(i, 2), 'o', 'MarkerSize', 4, 'MarkerEdgeColor', [0, 160, 135] / 255);
            end

            hold on;
            plot(edgeDataTrainedBaseline.edgeX{1}, edgeDataTrainedBaseline.edgeY{1}, 'Color', [0, 160, 135] / 255, 'LineWidth', 3);

            for i = 1:height(centroidDataTrainedPost)
                hold on;
                plot(centroidDataTrainedPost.WeightedCentroid(i, 1), 512 - centroidDataTrainedPost.WeightedCentroid(i, 2), '^', 'MarkerSize', 4, 'MarkerEdgeColor', [230, 75, 53] / 255);
            end

            hold on;
            plot(edgeDataTrainedPost.edgeX{1}, edgeDataTrainedPost.edgeY{1}, 'Color', [230, 75, 53] / 255, 'LineWidth', 3);

            xlabel('ML (mm)'); ylabel('AP (mm)');
            axis square
            set(gca, ...
                'Visible', 'on', ...
                'Box', 'off', ...
                'TickDir', 'out', ...
                'XTick', 256 - (4000:-500:0) / pix2mm_X, ...
                'XTickLabel', -4:0.5:0, ...
                'YTick', 256 + (-3000:500:3000) / pix2mm_X, ...
                'YTickLabel', 3:-0.5:-3, ...
                'XLim', 256 - [4000 -500] / pix2mm_X, ...
                'YLim', 256 + [-2000 2000] / pix2mm_X, ...
                'XGrid', 'on', ...
                'YGrid', 'on')
            title('Trained')
            
            maskUeno = MaskUeno();
            hold on;
            fill(maskUeno.coordsSensory(:, 1), maskUeno.coordsSensory(:, 2), 'k', 'FaceAlpha',0.1, 'EdgeColor','none');
            hold on;
            fill(maskUeno.coordsMotor(:, 1), maskUeno.coordsMotor(:, 2), 'm', 'FaceAlpha',0.1,'EdgeColor','none');
            
            figTileFormat; figTileLabel; figResize(1, 1)
            saveas(obj.figActEdge, fullfile(obj.resultPath, ['Rg_LimbVib_ActEdge_', num2str(obj.actMapThre), '.svg']));

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

            % calculate active map properties
            ExportActProps@Rg(obj);
            writetable(obj.objRegIMcorrCopy.fileTable, fullfile(obj.resultPath, ['Rg_LimbVib_ActProps_', num2str(obj.actMapThre), '.csv']));
        end

    end

end
