classdef AlignLimbMvtSingleCell < handle
    %% Properties
    properties
        param % parameters for the analysis
        wfTable % table of wf images
        bpodTable % table of bpod data
        wfBpodTable % table of wf and bpod data combined
        saveFolder = "D:\Data\SingleCellData" % folder to save aligned and combined tif of a session
    end

    %% Methods
    methods
        %% Constructor
        function obj = AlignLimbMvtSingleCell(param, wfTable, bpodTable)
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
            % select trials
            obj.SelectTrial();
            obj.AlignWfBpod();
        end

        function obj = AlignWfBpod(obj)
            % group the data by mouse and session
            groupIdx = findgroups(obj.wfBpodTable(:, {'mouse', 'session'}));
            % align the data for each session
            for i = 1:max(groupIdx)

                % get the data for the current session
                thisSession = obj.wfBpodTable(groupIdx == i, :);
                % target csv file for saving the session information
                csvFile = fullfile(obj.saveFolder, [thisSession.mouse{1}, '_', thisSession.session{1}, '.csv']);

                if ~exist(csvFile, 'file')
                    % save the session information to the csv file
                    thisSession = sortrows(thisSession, 'trial');
                    writetable(thisSession, csvFile);
                end

                % target combined tiff file
                tiffCombined = fullfile(obj.saveFolder, [thisSession.mouse{1}, '_', thisSession.session{1}, '.tif']);

                if exist(tiffCombined, 'file')
                    continue;
                end

                % create a Tiff object to write the combined tiff file
                tiffObj = Fast_BigTiff_Write(tiffCombined, 1, 0);

                % loop through each trial in the session
                for j = progress(1:height(thisSession), 'Title', ['Align ', thisSession.mouse{1}, ' ', thisSession.session{1}])

                    % get the data for the current trial
                    thisTrial = thisSession(j, :);

                    % load the times for the imaging data of current trial
                    tifTimesAbs = loadTifTime(thisTrial.path{1});
                    % Bpod times start from state "trigerCAMLED"
                    % Tif frame times start from the state "startTrial"
                    % Need to align the times of the imaging data with the Bpod data at the state "trigerCAMLED"
                    tifTimesAbs = tifTimesAbs - tifTimesAbs(1);

                    [~, stimOnFrameIdx] = min(abs(tifTimesAbs - thisTrial.t1stMvt));
                    tifTimesRel = tifTimesAbs - tifTimesAbs(stimOnFrameIdx);

                    % index of the imaging data for the current trial that is within the time window
                    tfFrameKeep = tifTimesRel >= obj.param.wfAlign.alignWin(1) & tifTimesRel <= obj.param.wfAlign.alignWin(2);

                    if sum(tfFrameKeep) ~= numel(obj.param.wfAlign.frameTime)
                        fprintf('Error: number of frames does not match the frame time')
                        % enter debug mode
                        continue
                    end

                    % load the imaging data for the current trial
                    thisTrialTif = tiffreadVolume(thisTrial.path{1});
                    thisTrialTifKeep = thisTrialTif(:, :, tfFrameKeep);

                    for k = 1:size(thisTrialTifKeep, 3)
                        tiffObj.WriteIMG(thisTrialTifKeep(:, :, k));
                    end

                end

                % close the tiff object
                tiffObj.close();
            end

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

        %% Function SelectTrial
        function SelectTrial(obj)
            % select the mouse
            if isfield(obj.param.select, 'mouse') && ~isempty(obj.param.select.mouse)
                obj.wfBpodTable = filterRow(obj.wfBpodTable, 'mouse', obj.param.select.mouse);
            end

            % select the session
            if isfield(obj.param.select, 'session') && ~isempty(obj.param.select.session)
                obj.wfBpodTable = filterRow(obj.wfBpodTable, 'session', obj.param.select.session);
            end

            % select the trial by outcome
            if isfield(obj.param.select, 'trial') && isfield(obj.param.select.trial, 'outcome') && ~isempty(obj.param.select.trial.outcome)
                obj.wfBpodTable = filterRow(obj.wfBpodTable, 'outcomeIdx', obj.param.select.trial.outcome);
            end

            % select the trial by mvtDir
            if isfield(obj.param.select, 'trial') && isfield(obj.param.select.trial, 'mvtDir') && ~isempty(obj.param.select.trial.mvtDir)
                obj.wfBpodTable = filterRow(obj.wfBpodTable, 'mvtDir', obj.param.select.trial.mvtDir);
            end

            % select trial by pawHoldGood
            if isfield(obj.param.select, 'trial') && isfield(obj.param.select.trial, 'pawHoldGood') && ~isempty(obj.param.select.trial.pawHoldGood)
                obj.wfBpodTable = filterRow(obj.wfBpodTable, 'pawHoldGood', obj.param.select.trial.pawHoldGood);
            end

        end

    end

end
