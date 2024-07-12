classdef FovCorrector < matlab.mixin.Copyable
    %% Properties
    properties
        workingDir = 'D:\Data\SingleCellData';
        fileTable
        gui
        selectedTemplateIdx
        selectedToBeCorrectedIdx
    end

    %% Methods
    methods

        %% Constructor
        function obj = FovCorrector()
            obj.LoadFileTable();
            obj.UpdateFileTable();
            obj.SelectTemplate();
        end

        %% Initialization
        function obj = UpdateFileTable(obj)
            % scan all the tif files in the directory
            newFileTable = findFile(obj.workingDir, 'tif');
            % add the mouse and session names
            findMouseFun = @(X)regexp(X, '[a-zA-Z]\d{4}(?=_)', 'match', 'once');
            newFileTable.mouse = findMouseFun(newFileTable.path);
            findSessionFun = @(X)regexp(X, '(?<=[a-zA-Z]\d{4}_)(20){0,1}2[3-9][0-1][0-9][0-3][0-9](?=.tif)', 'match', 'once');
            newFileTable.session = findSessionFun(newFileTable.path);
            % sort file table by mouse and session
            newFileTable = sortrows(newFileTable, {'mouse', 'session'});
            % remove row without session info
            newFileTable = newFileTable(~cellfun(@isempty, newFileTable.session), :);
            % add the isTemplate column
            newFileTable.isTemplate = false(height(newFileTable), 1);
            % add the control points column
            newFileTable.controlPoints = repmat({[512, 512]}, height(newFileTable), 1);
            % add the isCorrected column
            newFileTable.isCorrected = false(height(newFileTable), 1);

            % add to obj.fileTable
            if height(obj.fileTable) == 0
                obj.fileTable = newFileTable;
            else
                existIdx = ismember(newFileTable.path, obj.fileTable.path);
                obj.fileTable = [obj.fileTable; newFileTable(~existIdx, :)];
            end

        end

        %% Load the file table
        function obj = LoadFileTable(obj)

            try
                % load the file table
                loadResult = load(fullfile(obj.workingDir, 'FovCorrector.mat'), 'fovInfo');
                obj.fileTable = loadResult.fovInfo;
            catch
                obj.fileTable = table();
            end

        end

        %% Select the template file
        function obj = SelectTemplate(obj)
            % create the gui and layout
            obj.gui.figH = uifigure('Name', 'FOV correction', 'Position', [600, 100, 1000, 800]);
            obj.gui.tbl = uigridlayout(obj.gui.figH, [3, 2]);
            obj.gui.tbl.ColumnWidth = {'1x', '1x'};
            obj.gui.tbl.RowHeight = {20, 20, '1x'};
            obj.gui.tbl.Padding = [10, 10, 10, 10];
            obj.gui.tbl.BackgroundColor = [0.94, 0.94, 0.94];

            % button to do the and save the correction
            obj.gui.button = uibutton(obj.gui.tbl, 'Text', 'Correct', 'ButtonPushedFcn', @(src, event) obj.Correct(), 'HorizontalAlignment', 'center');
            obj.gui.button.Layout.Row = 1;
            obj.gui.button.Layout.Column = [1, 2];
            obj.gui.button.FontWeight = 'bold';
            obj.gui.button.FontColor = 'red';
            obj.gui.button.Enable = 'on';

            % label to instruct the user select the template file
            obj.gui.label = uilabel(obj.gui.tbl, 'Text', 'Select the template file', 'HorizontalAlignment', 'center');
            obj.gui.label.Layout.Row = 2;
            obj.gui.label.Layout.Column = 1;
            obj.gui.label.FontWeight = 'bold';
            obj.gui.label.FontColor = [0.2, 0.2, 0.2];

            % table to show the file table
            obj.gui.tempTable = uitable(obj.gui.tbl, 'Data', obj.fileTable(:, {'mouse', 'session', 'isTemplate', 'isCorrected'}));
            obj.gui.tempTable.Layout.Row = 3;
            obj.gui.tempTable.Layout.Column = 1;
            obj.gui.tempTable.ColumnWidth = 'fit';
            obj.gui.tempTable.SelectionType = 'row';
            obj.gui.tempTable.Multiselect = 'off';
            obj.gui.tempTable.SelectionChangedFcn = @(src, event) obj.SelectTemplateCallback(src, event);

            % label to instruct the user select the to be corrected file
            obj.gui.label = uilabel(obj.gui.tbl, 'Text', 'Select the to be corrected file', 'HorizontalAlignment', 'center');
            obj.gui.label.Layout.Row = 2;
            obj.gui.label.Layout.Column = 2;
            obj.gui.label.FontWeight = 'bold';
            obj.gui.label.FontColor = [0.2, 0.2, 0.2];

            % table to show the file table
            obj.gui.correctTable = uitable(obj.gui.tbl, 'Data', obj.fileTable(:, {'mouse', 'session', 'isTemplate', 'isCorrected'}));
            obj.gui.correctTable.Layout.Row = 3;
            obj.gui.correctTable.Layout.Column = 2;
            obj.gui.correctTable.ColumnWidth = 'fit';
            obj.gui.correctTable.SelectionType = 'row';
            obj.gui.correctTable.Multiselect = 'on';
            obj.gui.correctTable.SelectionChangedFcn = @(src, event) obj.SelectToBeCorrectedCallback(src, event);

        end

        function obj = SelectTemplateCallback(obj, src, event)
            selectedRowIdx = event.Selection;

            if isempty(selectedRowIdx)
                return;
            end

            obj.selectedTemplateIdx = selectedRowIdx;
        end

        function obj = SelectToBeCorrectedCallback(obj, src, event)
            selectedRowIdx = event.Selection;

            if isempty(selectedRowIdx)
                return;
            end

            obj.selectedToBeCorrectedIdx = selectedRowIdx;
        end

        %% Correct the fov of the files
        function obj = Correct(obj)
            % disable the button
            obj.gui.button.Enable = 'off';

            % check if the template and to be corrected files are selected
            if isempty(obj.selectedTemplateIdx) || isempty(obj.selectedToBeCorrectedIdx)
                dialog('Title', 'Error', 'String', 'Please select the template and to be corrected files', 'OK');
            end

            % get the template info
            templateFile = obj.fileTable.path{obj.selectedTemplateIdx};
            templateMouse = obj.fileTable.mouse{obj.selectedTemplateIdx};
            templateSession = obj.fileTable.session{obj.selectedTemplateIdx};
            templateControlPoints = obj.fileTable.controlPoints{obj.selectedTemplateIdx};

            % update the isTemplate column
            obj.fileTable.isTemplate(obj.selectedTemplateIdx) = true;

            % perform the correction
            for i = 1:length(obj.selectedToBeCorrectedIdx)
                thisFileIdx = obj.selectedToBeCorrectedIdx(i);
                thisFile = obj.fileTable.path{thisFileIdx};
                thisMouse = obj.fileTable.mouse{thisFileIdx};
                thisSession = obj.fileTable.session{thisFileIdx};
                thisIsCorrected = obj.fileTable.isCorrected(thisFileIdx);
                thisControlPoints = obj.fileTable.controlPoints{thisFileIdx};

                % skip the already corrected files
                if thisIsCorrected == 1
                    overdo = questdlg('The file has already been corrected, do you want to correct it again?', 'Overdo', 'Yes', 'No', 'No');

                    if strcmp(overdo, 'No')
                        continue;
                    end

                end

                % check if the mouse and session are the same
                if ~strcmp(thisMouse, templateMouse)
                    dialog('Title', 'Error', 'String', 'The mouse names are different', 'OK');
                    return;
                end

                if strcmp(thisSession, templateSession)
                    continue;
                end

                % print the info
                obj.gui.button.Text = sprintf('Correcting %s: %s with reference to %s', thisMouse, thisSession, templateSession);
                fprintf('Correcting %s: %s with reference to %s \n', thisMouse, thisSession, templateSession);
                titleStr = sprintf('%s-%s', obj.fileTable.name{thisFileIdx}, obj.fileTable.name{obj.selectedTemplateIdx});
                filePathMontage = fullfile(obj.workingDir, [titleStr, '_Montage.tif']);
                filePathPair = fullfile(obj.workingDir, [titleStr, '_Pair.tif']);
                % load the template and this file
                templateTifs = tiffreadVolume(templateFile);
                thisTifs = tiffreadVolume(thisFile);
                % extract the first frame for control points selection
                templateTif = imadjust(templateTifs(:, :, 1));
                thisTif = imadjust(thisTifs(:, :, 1));
                % select control points
                if size(thisControlPoints, 1) == 1
                    thisControlPoints = templateControlPoints;
                end

                [controlPointsThis, controlPointsTemplate] = cpselect(thisTif, templateTif, thisControlPoints, templateControlPoints, 'Wait', true);
                % calculate the transformation
                transformer = fitgeotform2d(controlPointsThis, controlPointsTemplate, 'similarity');
                thisTifsCorrected = imwarp(thisTifs, transformer, 'OutputView', imref2d(size(templateTifs)));
                % inspect the result
                figMontage = figure('Name', titleStr);
                montage({templateTif, thisTif, imadjust(thisTifsCorrected(:, :, 1))}, 'Size', [1, 3]);
                % inspect the max projection overlay
                figPair = figure('Name', titleStr);
                imshowpair(imadjust(max(templateTifs, [], 3)), imadjust(max(thisTifsCorrected, [], 3)), 'falsecolor');

                % ask for confirmation with a dialog button
                choice = questdlg('Save the corrected tif?', 'Save', 'Yes', 'No', 'No');

                if strcmp(choice, 'Yes')
                    % update the control points
                    obj.fileTable.controlPoints{obj.selectedTemplateIdx} = controlPointsTemplate;
                    obj.fileTable.controlPoints{thisFileIdx} = controlPointsThis;
                    % save the figMontage and figPair
                    saveas(figMontage, filePathMontage);
                    saveas(figPair, filePathPair);
                    % save the corrected tif back to the file
                    tifWriter = Fast_BigTiff_Write(thisFile);

                    for k = 1:size(thisTifsCorrected, 3)
                        tifWriter.WriteIMG(thisTifsCorrected(:, :, k));
                    end

                    tifWriter.close();
                    % mark the file as corrected
                    obj.fileTable.isCorrected(thisFileIdx) = 1;
                    % save the file table
                    obj.SaveFileTable();
                    % update the gui
                    obj.gui.tempTable.Data = obj.fileTable(:, {'mouse', 'session', 'isTemplate', 'isCorrected'});
                    obj.gui.correctTable.Data = obj.fileTable(:, {'mouse', 'session', 'isTemplate', 'isCorrected'});
                    % close the figures
                    close(figMontage);
                    close(figPair);
                    % show the success dialog
                    fprintf('Finished %s: %s with reference to %s \n', thisMouse, thisSession, templateSession);
                end

                % enable the button
                obj.gui.button.Enable = 'on';
                obj.gui.button.Text = 'Correct';

            end

        end

        %% Save and Load
        function obj = SaveFileTable(obj)
            fovInfo = obj.fileTable;
            % save the file table
            save(fullfile(obj.workingDir, 'FovCorrector.mat'), 'fovInfo');
        end

    end

end
