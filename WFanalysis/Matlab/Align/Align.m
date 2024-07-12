classdef Align < handle
    %% Properties
    properties
        param % parameters for the analysis
        wfTable % table of wf images
        bpodTable % table of bpod data
        wfBpodTable; % table of wf and bpod data combined
    end

    %% Methods
    methods
        %% Constructor
        function obj = Align(param, wfTable, bpodTable)
            % validate the input
            arguments
                param (1, 1) Param
                wfTable (1, 1) FileTable_Tif_Wf
                bpodTable (1, 1) FileTable_Bpod
            end

            % assign values
            obj.param = param; % parameters for the analysis
            obj.wfTable = wfTable; % table of wf images
            obj.bpodTable = bpodTable; % table of bpod data

            % load bpod data if not loaded
            if ~ismember('trial', obj.bpodTable.fileTable.Properties.VariableNames)
                obj.bpodTable.LoadFile(); % load the bpod data file
                obj.bpodTable.CleanVar({'path', 'folder', 'fileTable', 'namefull'}, 'remove'); % remove the unused variables
            end

            % combine the wf and bpod table
            obj.wfBpodTable = innerjoin(obj.wfTable.fileTable, obj.bpodTable.fileTable, 'Keys', {'mouse', 'session', 'trial'});
            % remove the trials with unmatched duration
            obj.RemoveUnmatchedDurationTrials();
            % get the path of actRaw
            obj.wfBpodTable.pathActRawMat = cellfun(@(X, Y)fullfile(param.dir.actMap.raw, [X, '_', Y, '_ACT.mat']), obj.wfBpodTable.mouse, obj.wfBpodTable.session, 'UniformOutput', false);
            obj.wfBpodTable.pathActRawTif = cellfun(@(X, Y)fullfile(param.dir.actMap.raw, [X, '_', Y, '_ACT.tif']), obj.wfBpodTable.mouse, obj.wfBpodTable.session, 'UniformOutput', false);
        end

        function obj = AlignWfBpod(obj)
            % group the data by mouse and session
            groupIdx = findgroups(obj.wfBpodTable(:, {'mouse', 'session'}));
            % align the data for each group
            for i = 1:max(groupIdx)
                % get the data for the current group
                currGroup = obj.wfBpodTable(groupIdx == i, :);
                % save trial info for currGroup
                writetable(currGroup, strrep(currGroup{1, "pathActRawMat"}{1}, '.mat', '.csv'))
                % align the data
                alignWfBpod(currGroup, obj.param);
            end

        end

        %% Function register with alle brain atlas
        function Reg(obj, windowType)
            % validate the input
            if nargin < 2
                windowType = 'clearSkull';
            end

            % construct path to corresponding output REG files
            funcRegActName = @(x) strrep(strrep(x, 'ACT', 'REG'), 'Raw', 'Reg');
            obj.wfBpodTable.pathReg = cellfun(funcRegActName, obj.wfBpodTable.pathActRawMat, 'UniformOutput', false);
            obj.wfBpodTable.pathRegExist = cellfun(@(x) isfile(x), obj.wfBpodTable.pathReg);
            % construct path to corresponding refrerence images
            funcRefActName = @(x, y) fullfile(Param().dir.refImage, [x, '_', y, '_REF.tif']);
            obj.wfBpodTable.pathRef = cellfun(funcRefActName, obj.wfBpodTable.mouse, obj.wfBpodTable.session, 'UniformOutput', false);
            % filter out files that already have a REG file
            obj.wfBpodTable = obj.wfBpodTable(~obj.wfBpodTable.pathRegExist, :);
            % wfBpodTableForReg
            wfBpodTableForReg = unique(cleanVar(obj.wfBpodTable, {'pathActRawMat', 'pathActRawTif', 'pathRef'}, 'keep'));

            % for each file in filesActPath register coordinates with allen atlas
            screenSize = get(0, 'Screensize');
            guiPosition = [screenSize(1) + 100, screenSize(2) + 100, screenSize(3) - 200, screenSize(4) - 200];

            for i = 1:height(wfBpodTableForReg)

                close all
                fprintf('  Registration for \n    %s\n', wfBpodTableForReg.pathActRawMat{i})

                switch windowType
                    case 'clearSkull'
                        objReg = regActRawClearSkull(wfBpodTableForReg.pathRef{i}, wfBpodTableForReg.pathActRawTif{i}, Param());
                    case 'cranialWindow'
                        objReg = regActRawCranialWindow(wfBpodTableForReg.pathRef{i}, wfBpodTableForReg.pathActRawTif{i}, Param());
                    case 'cranialWindowVesselPattern'
                        regActRawCranialWindowVesselPattern(wfBpodTableForReg.pathRef{i}, wfBpodTableForReg.pathActRawTif{i}, Param());
                end

                try
                    set(findobj('Name', 'WF registration'), 'Position', guiPosition);
                    waitfor(objReg, 'objButtonRegFlag', 1);
                catch
                    continue
                end

            end

            % close all and notify user
            close all
            fprintf('   Registration complete\n')
        end

    end

    methods (Access = private)
        %% Function remove umatched duration trials
        function obj = RemoveUnmatchedDurationTrials(obj)
            % filter out trials with duration_left and duration_right that are not matched (difference > 0.1)
            unMatchTrials = filterRow(obj.wfBpodTable, {'duration_left', 'duration_right'}, @(X, Y)abs(X - Y) > 0.2).path;

            % display the unMatchTrials if greater than 20 trials
            if length(unMatchTrials) > 40
                fprintf('   %d trials with unmatched duration\n', length(unMatchTrials))
                % raise dialog to ask user if want to continue moving the unMatchTrials to the backup folder
                choice = questdlg('Do you want to move the unMatchTrials to the backup folder?', 'Unmatched duration trials', 'Yes', 'No', 'No');
                % Handle response
                switch choice
                    case 'Yes'
                        % continue
                    case 'No'
                        % debug here
                        keyboard
                end

            end

            % move the unMatchTrials to the backup folder
            for i = 1:length(unMatchTrials)

                backupTarget = insertAfter(unMatchTrials{i}, 'WFrecordings\', 'unMatchTrials\');
                backupFolder = fileparts(backupTarget);

                if ~exist(backupFolder, 'dir')
                    mkdir(backupFolder)
                end

                try
                    movefile(unMatchTrials{i}, backupTarget);
                catch
                    continue;
                end

            end

            % remove the unMatchTrials from the table
            obj.wfBpodTable = filterRow(obj.wfBpodTable, {'path'}, @(X) ~ismember(X, unMatchTrials));

        end

    end

end
