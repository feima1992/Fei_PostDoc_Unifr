classdef Wfs_LimbVib < Wfs

    methods
        %% constructor
        function obj = Wfs_LimbVib(varargin)
            obj = obj@Wfs(varargin{:})
        end

        %% Get the expended data to single cell level
        function obj = GetExpData(obj)

            if isempty(obj.fileTableExp)
                % expend trigData to single cell level
                fileTableExp = table(); %#ok<*PROP>

                for i = 1:height(obj.fileTable)
                    % get the trigData
                    trigData = obj.fileTable.trigData{i};
                    % for each cell
                    for j = 1:size(trigData.Traces, 1)
                        % create a new row
                        newRow = obj.fileTable(i, :);
                        newRow.trigData = [];
                        % add the cell index
                        newRow.cellIdx = j;
                        % add the centerXY
                        newRow.centerX = trigData.CenterXY{j}(1);
                        newRow.centerY = trigData.CenterXY{j}(2);
                        % add the maxRespAmp
                        newRow.maxRespAmp = max(trigData.Stats{j}(:, 1));
                        % add the sigRespPval
                        newRow.sigRespPval = min(trigData.Stats{j}(:, 4));
                        % add the significant response cell
                        if isempty(trigData.sigCells)
                            newRow.sigResp = 0;
                        else
                            newRow.sigResp = ismember(j, trigData.sigCells(:, 1));
                        end

                        % add the fileTableExp
                        fileTableExp = [fileTableExp; newRow];
                    end

                end

                obj.fileTableExp = fileTableExp;
                % save the fileTableExp
                obj.Save();
            end

        end

        %% Build the GUI for checking sigResp cells
        function obj = buildGUI(obj)
            % build GUI to check and correct the sigResp cells
            obj.guiH.figH = uifigure('Name', 'Check and Correct sigResp Cells', 'Position', [200, 200, 650, 650]);

            obj.guiH.gridH = uigridlayout(obj.guiH.figH, [2, 1]);
            obj.guiH.gridH.RowHeight = {40, '1x'};

            obj.guiH.gridTopH = uigridlayout(obj.guiH.gridH, [1, 5]);
            obj.guiH.gridTopH.ColumnWidth = {'1x', '1x', 75, 75, 75};

            obj.guiH.label1H = uilabel(obj.guiH.gridTopH, 'HorizontalAlignment', 'center', 'Text', 'Check and Correct sigResp Cells');
            obj.guiH.label1H.Layout.Row = 1;
            obj.guiH.label1H.Layout.Column = 1;

            obj.guiH.label2H = uilabel(obj.guiH.gridTopH, 'HorizontalAlignment', 'center', 'Text', 'Is this a sigResp cell?');
            obj.guiH.label2H.Layout.Row = 1;
            obj.guiH.label2H.Layout.Column = 2;

            obj.guiH.buttonNoH = uibutton(obj.guiH.gridTopH, 'Text', 'No', 'ButtonPushedFcn', @(btn, event) ButtonPushedCallBack(btn, event, obj));
            obj.guiH.buttonNoH.Layout.Row = 1;
            obj.guiH.buttonNoH.Layout.Column = 3;

            obj.guiH.buttonYesH = uibutton(obj.guiH.gridTopH, 'Text', 'Yes', 'ButtonPushedFcn', @(btn, event) ButtonPushedCallBack(btn, event, obj));
            obj.guiH.buttonYesH.Layout.Row = 1;
            obj.guiH.buttonYesH.Layout.Column = 4;

            obj.guiH.buttonGoodH = uibutton(obj.guiH.gridTopH, 'Text', 'Good', 'ButtonPushedFcn', @(btn, event) ButtonPushedCallBack(btn, event, obj));
            obj.guiH.buttonGoodH.Layout.Row = 1;
            obj.guiH.buttonGoodH.Layout.Column = 5;

            obj.guiH.gridBottomH = uigridlayout(obj.guiH.gridH, [1, 1]);
            obj.guiH.gridBottomH.ColumnWidth = {'1x'};

            obj.guiH.tunePanel = uipanel(obj.guiH.gridBottomH, 'Title', 'Responses', 'BackgroundColor', 'w', 'TitlePosition', 'centertop', 'FontSize', 12);
            obj.guiH.tunePanel.Layout.Row = 1;
            obj.guiH.tunePanel.Layout.Column = 1;

            % callback function for the button press
            function obj = ButtonPushedCallBack(btn, event, obj)

                switch btn.Text
                    case 'Good'
                        % export the obj.guiH.figH to a figure
                        if ~isfolder(fullfile(obj.folderPath, 'goodResp'))
                            mkdir(fullfile(obj.folderPath, 'goodResp'));
                        end

                        set(obj.guiH.buttonGoodH, 'BackgroundColor', 'green');

                        exportapp(obj.guiH.figH, fullfile(obj.folderPath, 'goodResp', ['goodResp_', num2str(obj.guiH.idx), '.png']));

                        obj.fileTableExp.sigResp(obj.guiH.idx) = 1;
                        obj.fileTableExp.goodResp(obj.guiH.idx) = 2;

                    case 'Yes'
                        % export the obj.guiH.figH to a figure
                        if ~isfolder(fullfile(obj.folderPath, 'sigResp'))
                            mkdir(fullfile(obj.folderPath, 'sigResp'));
                        end

                        set(obj.guiH.buttonYesH, 'BackgroundColor', 'blue');

                        exportapp(obj.guiH.figH, fullfile(obj.folderPath, 'sigResp', ['sigResp_', num2str(obj.guiH.idx), '.png']));

                        obj.fileTableExp.sigResp(obj.guiH.idx) = 1;
                        obj.fileTableExp.goodResp(obj.guiH.idx) = 1;

                    case 'No'
                        % export the obj.guiH.figH to a figure
                        if ~isfolder(fullfile(obj.folderPath, 'notSigResp'))
                            mkdir(fullfile(obj.folderPath, 'notSigResp'));
                        end

                        set(obj.guiH.buttonNoH, 'BackgroundColor', 'red');

                        exportapp(obj.guiH.figH, fullfile(obj.folderPath, 'notSigResp', ['notSigResp_', num2str(obj.guiH.idx), '.png']));

                        obj.fileTableExp.sigResp(obj.guiH.idx) = 0;
                end

                % reset the color of the buttons
                set(obj.guiH.buttonYesH, 'BackgroundColor', [0.94, 0.94, 0.94]);
                set(obj.guiH.buttonNoH, 'BackgroundColor', [0.94, 0.94, 0.94]);
                set(obj.guiH.buttonGoodH, 'BackgroundColor', [0.94, 0.94, 0.94]);
                % delete the plots
                delete(obj.guiH.tunePanel.Children)
                % set the flag to 1 to continue to the next cell
                obj.flagNext = 1;
                % update the checkedIdx
                obj.checkedIdx(obj.guiH.idx) = 1;
            end

        end

        %% Check the sigResp cells
        function obj = CheckSigResp(obj, checkFilterName)

            if nargin < 2
                checkFilterName = 'AllsigResp';
            end

            % build the GUI
            obj.buildGUI();
            % filter the cells to check based on sigRespPval and maxRespAmp
            switch checkFilterName
                case 'AllsigResp'
                    checkFilter = obj.fileTableExp.sigRespPval <= 0.01 & obj.fileTableExp.maxRespAmp >= 1;
            end

            if ~ismember('goodResp', obj.fileTableExp.Properties.VariableNames)
                obj.fileTableExp.goodResp = zeros(height(obj.fileTableExp), 1);
            end

            % initialize the checkedIdx and checkResult
            if isempty(obj.checkedIdx)
                obj.checkedIdx = zeros(height(obj.fileTableExp), 1);
            end

            obj.fileTableExp.sigResp(~checkFilter) = 0;
            % loop through the fileTableExp to check the sigResp cells
            numChecked = 0;
            totalNum2Check = sum(checkFilter & obj.fileTableExp.sigResp);
            
            for i = 1:height(obj.fileTableExp)

                if checkFilter(i) && obj.checkedIdx(i) == 0 && obj.fileTableExp.sigResp(i) == 1
                    % save the object every 50 sigResp cells checked
                    numChecked = numChecked + 1;

                    if mod(numChecked, 20) == 0
                        % set label text to indicate the saving
                        disp('Saving the object, please wait...')
                        % save the object
                        obj.Save();
                    end

                    % store the index of curent row
                    obj.guiH.idx = i;
                    % set the flag to 0
                    obj.flagNext = 0;
                    % mouse, session, cell index
                    mouse = obj.fileTableExp.mouse{i};
                    session = obj.fileTableExp.session{i};
                    cellIdx = obj.fileTableExp.cellIdx(i);
                    % number of cells checked
                    numberChecked = sum(obj.checkedIdx & checkFilter & obj.fileTableExp.sigResp);
                    str2disp = sprintf('%s-%s, Cell: %d (%d/%d)\n', mouse, session, cellIdx, numberChecked, totalNum2Check);
                    set(obj.guiH.label1H, 'Text', str2disp);
                    % information of the cell
                    sigRespPval = obj.fileTableExp.sigRespPval(i);
                    maxRespAmp = obj.fileTableExp.maxRespAmp(i);
                    str2disp = sprintf('P: %.3f,  Amp: %.1f', sigRespPval, maxRespAmp);
                    set(obj.guiH.label2H, 'Text', str2disp);

                    % get the trigData
                    trigData = obj.fileTable.trigData{strcmp(obj.fileTable.mouse, mouse) & strcmp(obj.fileTable.session, session)};
                    % plot the tuning curve
                    fig1 = limbVibPlotResponses(trigData, cellIdx);
                    copyobj(fig1.Children, obj.guiH.tunePanel);
                    close(fig1);
                    % wait for button press
                    waitfor(obj, 'flagNext', 1);
                end

            end

        end

        %% function to reset sigResp check
        function obj = ResetSigResp(obj)
            obj.checkedIdx = [];
            obj.fileTableExp = [];
            obj.GetExpData();
        end

        %% function to check spatial footprints
        function obj = PlotSpatialFootprints(obj, respScoreThresh)

            if nargin < 2
                respScoreThresh = 0;
            end

            % sort the fileTableExp by sigResp and sigTuning so that sigResp cells, sigTuning cells are plotted on top
            data = sortrows(obj.fileTableExp, {'goodResp','maxRespAmp'}, 'ascend');

            % filter cells with goodResp greater than respScoreThresh
            data = data(data.goodResp >= respScoreThresh, :);

            % logical sigResp
            data.sigResp = logical(data.sigResp);

            % get the plot coordinates of the cells
            x = data.centerX;
            y = data.centerY;

            % compute the color of the cells
            colorMap = zeros(height(data), 3) + 0.8; % default color is gray
            % set sigResp cells color to map to maxRespAmp
            colorMap(data.sigResp, :) = vals2colormap(data.maxRespAmp(data.sigResp), 'turbo');

            % compute the size of the cells
            sizeMap = zeros(height(data), 1) + 15; % default size is 15
            sizeMap(data.sigResp, :) = 30; % sigResp cells are 30

            % plot the cells
            figure('Color', 'w', 'Position', [340, 364, 560, 420]);
            s = scatter(x, -y, sizeMap, colorMap, 'filled', 'MarkerEdgeColor', 'none'); % flip the y because now anterior is negative

            % add colorbar
            colormap('turbo');
            c = colorbar;
            colorVals = linspace(min(data.maxRespAmp(data.sigResp)), max(data.maxRespAmp(data.sigResp)), 5);
            c.Ticks = linspace(0, 1, 5);
            c.TickLabels = arrayfun(@(x) sprintf('%.1f', x), colorVals, 'UniformOutput', false);
            c.Label.String = 'ΔF/F';

            % overlay the region of sensory and motor cortex
            coords = EdgeUeno();
            hold on
            % plot the sensory region in blue dashed line, motor region in red dashed line
            plot(coords.coordsSensory(:, 1), coords.coordsSensory(:, 2), 'b--', 'LineWidth', 1);
            plot(coords.coordsAvgMotor(:, 1), coords.coordsAvgMotor(:, 2), 'r--', 'LineWidth', 1);
            % set the axis limits
            axis equal;
            xlim([-4.5, 0.5]);
            ylim([-2.5, 2.5]);

            % set axis ticks and labels
            xticks(-4:0.5:0);
            yticks(-2.5:0.5:2.5);

            % set the axis labels
            xlabel('Medial-Lateral (mm)');
            ylabel('Anterior-Posterior (mm)');

            % show the box and grid
            box on;
            grid on;

            % select point in the plot to display the cell index
            set(s, 'ButtonDownFcn', @(src, event) ClickCallback(src, event, obj, data));

            function ClickCallback(h, e, obj, data)

                % --- Get coordinates
                x = get(h, 'XData');
                y = get(h, 'YData');

                % --- Get index of the clicked point
                [~, i] = min((e.IntersectionPoint(1) - x) .^ 2 + (e.IntersectionPoint(2) - y) .^ 2);

                % get mouse and session
                mouse = data.mouse{i};
                session = data.session{i};
                cellIdx = data.cellIdx(i);
                maxRespAmp = data.maxRespAmp(i);
                sigRespPval = data.sigRespPval(i);
                sigResp = data.sigResp(i);
                goodResp = data.goodResp(i);

                % print the cell index
                fprintf('Mouse: %s, Session: %s, Cell Index: %d\n', mouse, session, cellIdx);
                fprintf('Amp: %.2f, Pval: %.3f, sigResp: %d, goodResp: %d\n\r', maxRespAmp, sigRespPval, sigResp, goodResp);

                % find the corresponding trigData in obj.fileTable
                idx = strcmp(obj.fileTable.mouse, mouse) & strcmp(obj.fileTable.session, session);
                trigData = obj.fileTable.trigData{idx};

                % plot the tuning curve
                figure(9999);
                fig9999 = limbVibPlotResponses(trigData, cellIdx);
                set(fig9999, 'Name', sprintf('Mouse: %s, Session: %s, Cell Index: %d', mouse, session, cellIdx));
                set(fig9999, 'Position', [905, 364, 560, 420]);

            end

        end

    end

end
