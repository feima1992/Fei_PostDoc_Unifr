classdef FileTableActRegDeltaFoverF < FileTableActReg
    %% Methods
    methods
        %% Construcctor
        function obj = FileTableActRegDeltaFoverF(varargin)
            % Call superclass constructor
            obj = obj@FileTableActReg(varargin{:});
        end

        %% Plot activation map for each mouse and session (deltaFoverF)
        function obj = PlotMapDeltaFoverF(obj)

            % If the deltaFoverF is not loaded, load it
            if ~ismember('deltaFoverF', obj.fileTable.Properties.VariableNames)
                obj.LoadDeltaFoverF();
            end

            % Calculate a common clim
            clim = cell2mat(cellfun(@(X)[min(X(:)), max(X(:))], obj.fileTable.deltaFoverF, 'UniformOutput', false));
            clim = max(abs(clim(:))) * [-1, 1];

            % Plot deltaFoverF for each mouse
            G = findgroups(obj.fileTable(:, {'mouse'}));

            for i = 1:length(unique(G))
                thisMouseTable = obj.fileTable(G == i, :);
                % Create a figure
                figure('Name', 'mapAvg', 'Position', [100, 100, 1000, 1000], 'Color', 'w');
                % Create titleStr and sgtitleStr
                sgtitleStr = [thisMouseTable.mouse{1}, ' (', thisMouseTable.group{1}, ')'];
                titleStr = cellfun(@(X, Y)[X, ' (', Y, ')'], thisMouseTable.phase, thisMouseTable.session, 'UniformOutput', false);
                % Plot thisMouseTable.deltaFoverF
                imagescMultiFrames(thisMouseTable.deltaFoverF, 'title', titleStr, 'sgtitle', sgtitleStr, 'clim', clim);
                % format the figure

                nPost = sum(~strcmp(thisMouseTable.phase, 'Baseline'));
                axesH = findobj(gcf, 'Type', 'ax');

                for j = 1:nPost
                    axesH(j).Title.Color = 'r';
                end

                for k = nPost + 1:length(axesH)
                    axesH(k).Title.Color = 'b';
                end

                switch length(axesH)
                    case {11, 12}
                        set(gcf, 'Position', [0, 400, 2000, 600]);
                    case {13, 14, 15, 16, 17, 18}
                        set(gcf, 'Position', [0, 400, 2000, 900]);
                end

                if strcmp(thisMouseTable.group{1}, 'Untrained')
                    prefix = 'con';
                else
                    prefix = 'exp';
                end

                saveas(gcf, [prefix, '_', thisMouseTable.mouse{1}, '_deltaFoverF.fig']);
                exportgraphics(gcf, [prefix, '_', thisMouseTable.mouse{1}, '_deltaFoverF.png'], 'Resolution', 300);
                close(gcf);
            end

        end

        %% Plot average activation map for each mouse (deltaFoverF)
        function obj = PlotAvgMapDeltaFoverF(obj)
            % If the deltaFoverF is not loaded, load it
            if ~ismember('deltaFoverF', obj.fileTable.Properties.VariableNames)
                obj.LoadDeltaFoverF();
            end

            % Calculate average deltaFoverF for each mouse and phase
            [G, mosueGroupPhase] = findgroups(obj.fileTable(:, {'mouse', 'group', 'phase'}));
            meanMap = splitapply(@(X){mean(cat(3, X{1}), 3, 'omitnan')}, obj.fileTable.deltaFoverF, G);
            meanMap = [mosueGroupPhase, table(meanMap)];

            % Calculate difference map for each mouse
            baselineIdx = strcmp(meanMap.phase, 'Baseline');
            meanMapPaired = innerjoin(meanMap(baselineIdx, :), meanMap(~baselineIdx, :), 'Keys', 'mouse');
            meanMapPaired.diffMap = cellfun(@(X, Y)X - Y, meanMapPaired.meanMap_right, meanMapPaired.meanMap_left, 'UniformOutput', false);

            % Plot meanMapPaired for each mouse
            for i = 1:height(meanMapPaired)
                % Create a figure
                figure('Name', 'mapAvg', 'Position', [100, 100, 1000, 1000], 'Color', 'w');
                % Create frameData to be plotted
                frameData = {meanMapPaired.meanMap_left{i}, meanMapPaired.meanMap_right{i}, meanMapPaired.diffMap{i}};
                titleStr = {meanMapPaired.phase_left{i}, meanMapPaired.phase_right{i}, 'Diff'};
                imagescMultiFrames(frameData, 'title', titleStr, 'sgtitle', [meanMapPaired.mouse{i}, ' (', meanMapPaired.group_left{i}, ')']);
                set(gcf, 'Position', [0, 400, 1000, 300]);
                axesH = findobj(gcf, 'Type', 'ax');
                axesH(3).Title.Color = 'b'; axesH(2).Title.Color = 'r';

                if strcmp(meanMapPaired.group_left{i}, 'Untrained')
                    prefix = 'con';
                else
                    prefix = 'exp';
                end

                saveas(gcf, [prefix, '_', meanMapPaired.mouse{i}, '_deltaFoverF_avg.fig']);
                exportgraphics(gcf, [prefix, '_', meanMapPaired.mouse{i}, '_deltaFoverF_avg.png'], 'Resolution', 300);
                close(gcf);
            end

        end

    end

end
