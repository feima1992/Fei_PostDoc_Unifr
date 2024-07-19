classdef Wfs_LimbMvt < Wfs

    methods
        %% constructor
        function obj = Wfs_LimbMvt(varargin)
            obj = obj@Wfs(varargin{:})
        end

        %% get the tuning properties
        function obj = GetTuningProp(obj)
            % loop through the file table to get the tuning properties
            for i = 1:height(obj.fileTable)
                trigData = obj.fileTable.trigData{i};
                % remove the tuning properties if they already exist
                trigData.sigCells(:, 2:end) = [];
                % get the gaussian fit of the tuning curve
                fitResult = zeros(size(trigData.sigCells, 1), 6);

                for j = 1:size(trigData.sigCells, 1)
                    fitResult(j, :) = limbMvtFitGaussOut(trigData, trigData.sigCells(j));
                end

                trigData.sigCells = [trigData.sigCells, fitResult]; % sigCellIdx, mu, sigma, r2, badFit, PDround, pTuning
                obj.fileTable.trigData{i} = trigData;
            end

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
                        newRow.sigResp = ismember(j, trigData.sigCells(:, 1));
                        % add the sigTunePval
                        if newRow.sigResp
                            newRow.sigTunePval = trigData.sigCells(trigData.sigCells(:, 1) == j, 7);
                        else
                            newRow.sigTunePval = NaN;
                        end

                        % add the significant tuning cell
                        try
                            newRow.sigTuning = ismember(j, trigData.sigCells(trigData.sigCells(:, 7) < 0.05, 1));
                        catch
                            newRow.sigTuning = false;
                        end

                        % add the badFit
                        if newRow.sigResp
                            newRow.badFit = trigData.sigCells(trigData.sigCells(:, 1) == j, 5);
                        else
                            newRow.badFit = NaN;
                        end

                        % add the preferred direction if it is a significant tuning cell
                        if newRow.sigTuning || (~isnan(newRow.badFit) && newRow.badFit == 0)
                            newRow.gaussianPD = trigData.sigCells(trigData.sigCells(:, 1) == j, 2);
                            newRow.eightDirPD = trigData.sigCells(trigData.sigCells(:, 1) == j, 6);
                        else
                            newRow.gaussianPD = NaN;
                            newRow.eightDirPD = NaN;
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
            obj.guiH.figH = uifigure('Name', 'Check and Correct sigResp Cells', 'Position', [200, 200, 1250, 650]);

            obj.guiH.gridH = uigridlayout(obj.guiH.figH, [2, 1]);
            obj.guiH.gridH.RowHeight = {40, '1x'};

            obj.guiH.gridTopH = uigridlayout(obj.guiH.gridH, [1, 5]);
            obj.guiH.gridTopH.ColumnWidth = {'0.5x', '1x', 200, 200, 200};

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

            obj.guiH.gridBottomH = uigridlayout(obj.guiH.gridH, [1, 2]);
            obj.guiH.gridBottomH.ColumnWidth = {'1x', '1x'};

            obj.guiH.tunePanel = uipanel(obj.guiH.gridBottomH, 'Title', 'Direction Tuning', 'BackgroundColor', 'w');
            obj.guiH.tunePanel.Layout.Row = 1;
            obj.guiH.tunePanel.Layout.Column = 1;

            obj.guiH.gaussPanel = uipanel(obj.guiH.gridBottomH, 'Title', 'Gaussian Fit', 'BackgroundColor', 'w');
            obj.guiH.gaussPanel.Layout.Row = 1;
            obj.guiH.gaussPanel.Layout.Column = 2;

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
                        obj.fileTableExp.sigTuning(obj.guiH.idx) = 0;
                        obj.fileTableExp.gaussianPD(obj.guiH.idx) = NaN;
                        obj.fileTableExp.eightDirPD(obj.guiH.idx) = NaN;
                end

                % reset the color of the buttons
                set(obj.guiH.buttonYesH, 'BackgroundColor', [0.94, 0.94, 0.94]);
                set(obj.guiH.buttonNoH, 'BackgroundColor', [0.94, 0.94, 0.94]);
                set(obj.guiH.buttonGoodH, 'BackgroundColor', [0.94, 0.94, 0.94]);
                % delete the plots
                delete(obj.guiH.tunePanel.Children)

                if obj.guiH.gaussPanel.Title == "Gaussian Fit"
                    delete(obj.guiH.gaussPanel.Children)
                end

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
            % checkFilter = obj.fileTableExp.maxRespAmp >= 4;
            switch checkFilterName
                case 'AllsigResp'
                    checkFilter = obj.fileTableExp.sigRespPval <= 0.01 & obj.fileTableExp.maxRespAmp >= 3;
                case 'sigTuning'
                    checkFilter = obj.fileTableExp.sigTunePval <= 0.05;
                case 'badFit'
                    checkFilter = obj.fileTableExp.badFit == 1;
                case 'goodResp'
                    checkFilter = obj.fileTableExp.goodResp == 2;
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

            for i = 1:height(obj.fileTableExp)

                if checkFilter(i) && obj.checkedIdx(i) == 0 && obj.fileTableExp.sigResp(i) == 1
                    % save the object every 50 sigResp cells checked
                    numChecked = numChecked + 1;

                    if mod(numChecked, 50) == 0
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
                    totalNum2Check = sum(checkFilter & obj.fileTableExp.sigResp);
                    numberChecked = sum(obj.checkedIdx & checkFilter & obj.fileTableExp.sigResp);
                    str2disp = sprintf('%s-%s, Cell: %d (%d/%d)\n', mouse, session, cellIdx, numberChecked, totalNum2Check);
                    set(obj.guiH.label1H, 'Text', str2disp);
                    % information of the cell
                    sigRespPval = obj.fileTableExp.sigRespPval(i);
                    maxRespAmp = obj.fileTableExp.maxRespAmp(i);
                    sigTunePval = obj.fileTableExp.sigTunePval(i);
                    badFit = obj.fileTableExp.badFit(i);
                    gaussianPD = obj.fileTableExp.gaussianPD(i);
                    str2disp = sprintf('P: %.3f,  Amp: %.1f,  Ptune: %.3f,  BadFit: %d,  PD: %.0f', sigRespPval, maxRespAmp, sigTunePval, badFit, gaussianPD);
                    set(obj.guiH.label2H, 'Text', str2disp);

                    % get the trigData
                    trigData = obj.fileTable.trigData{strcmp(obj.fileTable.mouse, mouse) & strcmp(obj.fileTable.session, session)};
                    % plot the tuning curve
                    fig1 = limbMvtPlotDirTune(trigData, cellIdx);
                    copyobj(fig1.Children, obj.guiH.tunePanel);
                    close(fig1);
                    % plot the gaussian fit
                    [~, fig2] = fitGaussOut(trigData, cellIdx, 1);
                    copyobj(fig2.Children, obj.guiH.gaussPanel);
                    close(fig2);
                    % wait for button press
                    waitfor(obj, 'flagNext', 1);
                end

            end

        end

        %% function to check spatial footprints
        function obj = CheckSpatialFootprints(obj, options)

            arguments
                obj;
                options.respScoreThresh (1, 1) double = 2;
                options.mouseFilter = 'All';
                options.plotNoResp (1, 1) logical = false;
            end

            % sort the fileTableExp by sigResp and sigTuning so that sigResp cells, sigTuning cells are plotted on top
            data = sortrows(obj.fileTableExp, {'goodResp', 'sigTuning'}, 'ascend');

            % filter cells with goodResp greater than respScoreThresh
            data.sigResp(data.goodResp < options.respScoreThresh) = 0;
            data.sigTuning(data.goodResp < options.respScoreThresh) = 0;
            data.gaussianPD(data.goodResp < options.respScoreThresh) = NaN;
            data.eightDirPD(data.goodResp < options.respScoreThresh) = NaN;

            if ~options.plotNoResp
                data = data(data.goodResp >= respScoreThresh, :);
            end

            if ~strcmp(options.mouseFilter, 'All')
                data = data(ismember(data.mouse, options.mouseFilter), :);
            end

            % correct gaussianPD and eightDirPD
            data.gaussianPD(data.gaussianPD < 0) = data.gaussianPD(data.gaussianPD < 0) + 360;
            data.gaussianPD(data.gaussianPD > 360) = data.gaussianPD(data.gaussianPD > 360) - 360;
            eightDirPD = 0:45:360;
            [~, idx] = min(abs(data.gaussianPD - eightDirPD), [], 2);
            data.eightDirPD = eightDirPD(idx)';
            data.eightDirPD(data.eightDirPD == 360) = 0;
            data.eightDirPD(isnan(data.gaussianPD)) = NaN;

            % get the plot coordinates of the cells
            x = data.centerX;
            y = data.centerY;

            % compute the color of the cells
            colorMap = zeros(height(data), 3) + 0.8; % default color is gray
            colorMap(data.sigResp, :) = 0; % sigResp cells are black
            eightDirPDsigTuning = data.eightDirPD(~isnan(data.eightDirPD)) ./ 360;
            eightDirPDsigTuning(:, 2) = 1;
            eightDirPDsigTuning(:, 3) = 1;
            colorMap(~isnan(data.eightDirPD), :) = hsv2rgb(eightDirPDsigTuning); % sigTuning cells are colored by eightDirPD
            mvtDir = [0, 45, 90, 135, 180, 225, 270, 315];
            mvtDirColor = zeros(length(mvtDir), 3);
            mvtDirColor(:, 1) = mvtDir ./ 360;
            mvtDirColor(:, 2) = 1;
            mvtDirColor(:, 3) = 1;
            mvtDirColor = hsv2rgb(mvtDirColor);
            % compute the alpha of the cells
            alphaMap = zeros(height(data), 1) + 1; % default alpha is 0.5
            alphaMap(data.sigResp, :) = 1; % sigResp cells are 1
            % compute the size of the cells
            sizeMap = zeros(height(data), 1) + 15; % default size is 15
            sizeMap(data.sigResp, :) = 30; % sigResp cells are 30

            % plot the cells in the gui panel
            if isempty(obj.guiH) || ~isvalid(obj.guiH.figH)
                obj.buildGUI();
            else
                % reset the button color to default
                set(obj.guiH.buttonYesH, 'BackgroundColor', [0.94, 0.94, 0.94]);
                set(obj.guiH.buttonNoH, 'BackgroundColor', [0.94, 0.94, 0.94]);
                set(obj.guiH.buttonGoodH, 'BackgroundColor', [0.94, 0.94, 0.94]);
            end

            % rename the gaussPanel to spatial footprints
            set(obj.guiH.gaussPanel, 'Title', 'Spatial Footprints');

            % fullscreen size of figH
            set(obj.guiH.figH, 'Position', [50, 200, 1600, 750]);
            axH = uiaxes(obj.guiH.gaussPanel, 'Position', [10, 10, 600, 600]);
            s = scatter(axH, x, -y, sizeMap, colorMap, 'filled', 'MarkerEdgeColor', 'none'); % flip the y because now anterior is negative
            s.AlphaData = alphaMap;
            s.MarkerFaceAlpha = 'flat';
            % plot arrow legends to indicate the preferred direction of sigTuning cells
            hold(axH, 'on')

            for j = 1:length(mvtDir)
                quiver(axH, 0, 0, 0.5 * cosd(mvtDir(j)), 0.5 * sind(mvtDir(j)), 'Color', mvtDirColor(j, :), 'LineWidth', 1);
            end

            % overlay the region of sensory and motor cortex
            googleSheetId = '1-XTF4-4M5bmvE0f--Af_9g4OFYRJFnMmkXPPNAn1L6c';
            googleSheetBook = 'Coord';
            coords = readGoogleSheet(googleSheetId, googleSheetBook);
            % group data and calculate mask for each region
            [gIdx, coordsTable] = findgroups(coords(:, {'Region', 'Innervation'}));

            for n = 1:length(unique(gIdx))
                coordsNow = coords(gIdx == n, :);
                coordsNowXy = [coordsNow.CoordX, coordsNow.CoordY];
                coordsNowXy(end + 1, :) = coordsNowXy(1, :); %#ok<AGROW>
                coordsTable.Coords{n} = coordsNowXy;
            end

            % mask of sensory region
            coordsTableSensory = coordsTable(strcmp(coordsTable.Region, 'Sensory'), :);
            coordsSensory = coordsTableSensory.Coords{1};
            % mask of motor region
            coordsTableMotor = coordsTable(strcmp(coordsTable.Region, 'Motor'), :);
            maxVertices = max(cellfun(@(x) size(x, 1), coordsTableMotor.Coords));
            % interpolate coordinates to have same number of vertices
            coordsTableMotor.Coords = cellfun(@(x) interp1(1:size(x, 1), x, linspace(1, size(x, 1), maxVertices)), coordsTableMotor.Coords, 'UniformOutput', false);
            % calculate mean coordinates of motor region
            coordsMotor = cat(3, coordsTableMotor.Coords{:});
            coordsAvgMotor = mean(coordsMotor, 3);

            % plot the sensory region in blue dashed line, motor region in red dashed line
            plot(axH, coordsSensory(:, 1), coordsSensory(:, 2), 'b--', 'LineWidth', 1);
            plot(axH, coordsAvgMotor(:, 1), coordsAvgMotor(:, 2), 'r--', 'LineWidth', 1);

            % set the axis limits
            xlim([-4.5, 0.5]);
            ylim([-2.5, 2.5]);
            axis equal;

            % set the axis labels
            xlabel(axH, 'Medial-Lateral (mm)');
            ylabel(axH, 'Anterior-Posterior (mm)');

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

                sigRespPval = data.sigRespPval(i);
                maxRespAmp = data.maxRespAmp(i);
                sigTunePval = data.sigTunePval(i);
                badFit = data.badFit(i);
                gaussianPD = data.gaussianPD(i);

                % print the cell index
                fprintf('Mouse: %s, Session: %s, Cell Index: %d\n', mouse, session, cellIdx);
                str2disp1 = sprintf('Mouse: %s, Session: %s, Cell Index: %d', mouse, session, cellIdx);
                str2disp2 = sprintf('P: %.3f,  Amp: %.1f,  Ptune: %.3f, BadFit: %d,  PD: %.0f', sigRespPval, maxRespAmp, sigTunePval, badFit, gaussianPD);

                % find the corresponding trigData in obj.fileTable
                idx = strcmp(obj.fileTable.mouse, mouse) & strcmp(obj.fileTable.session, session);
                trigData = obj.fileTable.trigData{idx};

                % buildGUI if obj.guiH does not exist
                if ~isvalid(obj.guiH.figH)
                    obj.buildGUI();
                else
                    % change button color to default
                    set(obj.guiH.buttonYesH, 'BackgroundColor', [0.94, 0.94, 0.94]);
                    set(obj.guiH.buttonNoH, 'BackgroundColor', [0.94, 0.94, 0.94]);
                    set(obj.guiH.buttonGoodH, 'BackgroundColor', [0.94, 0.94, 0.94]);
                end

                set(obj.guiH.label1H, 'Text', str2disp1);
                set(obj.guiH.label2H, 'Text', str2disp2);
                delete(obj.guiH.tunePanel.Children)
                fig1 = limbMvtPlotDirTune(trigData, cellIdx);
                copyobj(fig1.Children, obj.guiH.tunePanel);
                close(fig1);

                % change button color according to the goodResp value
                if data.goodResp(i) == 2
                    set(obj.guiH.buttonGoodH, 'BackgroundColor', 'green');
                elseif data.sigResp(i) == 1
                    set(obj.guiH.buttonYesH, 'BackgroundColor', 'blue');
                elseif data.sigResp(i) == 0
                    set(obj.guiH.buttonNoH, 'BackgroundColor', 'red');
                end

            end

        end

        %% plot the spatial footprints
        function PlotSpatialFootprints(obj, options)

            arguments
                obj;
                options.respScoreThresh (1, 1) double = 2;
                options.mouseFilter = 'All';
                options.plotNoResp (1, 1) logical = false;
            end

            % sort the fileTableExp by sigResp and sigTuning so that sigResp cells, sigTuning cells are plotted on top
            data = sortrows(obj.fileTableExp, {'goodResp', 'sigTuning'}, 'ascend');

            % filter cells with goodResp greater than respScoreThresh
            data.sigResp(data.goodResp < options.respScoreThresh) = 0;
            data.sigTuning(data.goodResp < options.respScoreThresh) = 0;
            data.gaussianPD(data.goodResp < options.respScoreThresh) = NaN;
            data.eightDirPD(data.goodResp < options.respScoreThresh) = NaN;

            if ~options.plotNoResp
                data = data(data.goodResp >= options.respScoreThresh, :);
            end

            if ~strcmp(options.mouseFilter, 'All')
                data = data(ismember(data.mouse, options.mouseFilter), :);
            end

            % correct gaussianPD and eightDirPD
            data.gaussianPD(data.gaussianPD < 0) = data.gaussianPD(data.gaussianPD < 0) + 360;
            data.gaussianPD(data.gaussianPD > 360) = data.gaussianPD(data.gaussianPD > 360) - 360;
            eightDirPD = 0:45:360;
            [~, idx] = min(abs(data.gaussianPD - eightDirPD), [], 2);
            data.eightDirPD = eightDirPD(idx)';
            data.eightDirPD(data.eightDirPD == 360) = 0;
            data.eightDirPD(isnan(data.gaussianPD)) = NaN;

            % get the plot coordinates of the cells
            x = data.centerX;
            y = data.centerY;

            % compute the color of the cells
            colorMap = zeros(height(data), 3) + 0.8; % default color is gray
            colorMap(data.sigResp, :) = 0; % sigResp cells are black
            eightDirPDsigTuning = data.eightDirPD(~isnan(data.eightDirPD)) ./ 360;
            eightDirPDsigTuning(:, 2) = 1;
            eightDirPDsigTuning(:, 3) = 1;
            colorMap(~isnan(data.eightDirPD), :) = hsv2rgb(eightDirPDsigTuning); % sigTuning cells are colored by eightDirPD
            mvtDir = [0, 45, 90, 135, 180, 225, 270, 315];
            mvtDirColor = zeros(length(mvtDir), 3);
            mvtDirColor(:, 1) = mvtDir ./ 360;
            mvtDirColor(:, 2) = 1;
            mvtDirColor(:, 3) = 1;
            mvtDirColor = hsv2rgb(mvtDirColor);
            % compute the alpha of the cells
            alphaMap = zeros(height(data), 1) + 1; % default alpha is 0.5
            alphaMap(data.sigResp, :) = 1; % sigResp cells are 1
            % compute the size of the cells
            sizeMap = zeros(height(data), 1) + 15; % default size is 15
            sizeMap(data.sigResp, :) = 30; % sigResp cells are 30

            % plot the cells in a new figure
            figure('Name', 'Spatial Footprints', 'Position', [50, 200, 1600, 750]);
            axH = axes;
            s = scatter(axH, x, -y, sizeMap, colorMap, 'filled', 'MarkerEdgeColor', 'none'); % flip the y because now anterior is negative
            s.AlphaData = alphaMap;
            s.MarkerFaceAlpha = 'flat';
            % plot arrow legends to indicate the preferred direction of sigTuning cells
            hold(axH, 'on')

            for j = 1:length(mvtDir)
                quiver(axH, 0, 0, 0.5 * cosd(mvtDir(j)), 0.5 * sind(mvtDir(j)), 'Color', mvtDirColor(j, :), 'LineWidth', 1);
            end

            % overlay the region of sensory and motor cortex
            googleSheetId = '1-XTF4-4M5bmvE0f--Af_9g4OFYRJFnMmkXPPNAn1L6c';
            googleSheetBook = 'Coord';
            coords = readGoogleSheet(googleSheetId, googleSheetBook);
            % group data and calculate mask for each region
            [gIdx, coordsTable] = findgroups(coords(:, {'Region', 'Innervation'}));

            for n = 1:length(unique(gIdx))
                coordsNow = coords(gIdx == n, :);
                coordsNowXy = [coordsNow.CoordX, coordsNow.CoordY];
                coordsNowXy(end + 1, :) = coordsNowXy(1, :); %#ok<AGROW>
                coordsTable.Coords{n} = coordsNowXy;
            end

            % mask of sensory region
            coordsTableSensory = coordsTable(strcmp(coordsTable.Region, 'Sensory'), :);
            coordsSensory = coordsTableSensory.Coords{1};
            % mask of motor region
            coordsTableMotor = coordsTable(strcmp(coordsTable.Region, 'Motor'), :);
            maxVertices = max(cellfun(@(x) size(x, 1), coordsTableMotor.Coords));
            % interpolate coordinates to have same number of vertices
            coordsTableMotor.Coords = cellfun(@(x) interp1(1:size(x, 1), x, linspace(1, size(x, 1), maxVertices)), coordsTableMotor.Coords, 'UniformOutput', false);
            % calculate mean coordinates of motor region
            coordsMotor = cat(3, coordsTableMotor.Coords{:});
            coordsAvgMotor = mean(coordsMotor, 3);

            % plot the sensory region in blue dashed line, motor region in red dashed line
            plot(axH, coordsSensory(:, 1), coordsSensory(:, 2), 'b--', 'LineWidth', 1);
            plot(axH, coordsAvgMotor(:, 1), coordsAvgMotor(:, 2), 'r--', 'LineWidth', 1);

            % set the axis limits
            xlim([-4.5, 0.5]);
            ylim([-2.5, 2.5]);
            axis equal;

            % set the axis labels
            xlabel(axH, 'Medial-Lateral (mm)');
            ylabel(axH, 'Anterior-Posterior (mm)');

        end

    end

end
