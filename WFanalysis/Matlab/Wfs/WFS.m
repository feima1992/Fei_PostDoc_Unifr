classdef Wfs < matlab.mixin.Copyable % Handle class with copy functionality

    %% Properties
    properties
        folderPath; % folder path to save the object
        fileTable; % fileTable of the trig data
        fileTableExp; % expended fileTable to single cell level
        guiH; % GUI handles for checking sigResp cells
        flagNext; % flag for waiting for button press
        checkedIdx; % index of the checked sigResp cells
    end

    %% Methods
    methods

        %% constructor
        function obj = Wfs(varargin)

            % set the folder path to save the object
            if nargin < 1

                obj.folderPath = 'D:\Data\SingleCellData';
                varargin = {obj.folderPath};

            else

                obj.folderPath = varargin{1};

            end

                        % try to load the object from the folder
                        try
            
                            obj.Load();
                            fprintf('Loaded Wfs object from %s\n', obj.folderPath);
                            obj.folderPath = varargin{1};
            
                        catch
            
                            % if failed, get the file table
                            comp = FileTable(varargin{:}, 'coordAndTrace.mat').CleanVar({'folder', 'namefull'}).fileTable; % calcium data
                            info = FileTable(varargin{:}, '.csv').CleanVar({'folder', 'namefull'}).fileTable; % trial info
                            % join the tables by mouse and session
                            obj.fileTable = innerjoin(comp, info, 'Keys', {'mouse', 'session'});
                            % get the trig data
                            obj.GetTrigData().ConvertCoordToMM()
                        end

        end

        %% compute the trig data
        function obj = GetTrigData(obj, redo)

            % set redo to false if not provided
            if nargin < 2
                redo = false;
            end

            % Bootstrap to find significant cells
            for i = 1:height(obj.fileTable)

                % skip if the trigData is already computed
                if ismember('trigData', obj.fileTable.Properties.VariableNames) && ~isempty(obj.fileTable.trigData{i}) && ~redo
                    fprintf('TrigData already computed for %s-%s\n', obj.fileTable.mouse{i}, obj.fileTable.session{i});
                    continue;
                end

                % display the progress
                fprintf('Loading %d of %d: %s-%s\n', i, height(obj.fileTable), obj.fileTable.mouse{i}, obj.fileTable.session{i});
                % load the calcium data of this session
                data = load(obj.fileTable.path_comp{i});
                % load the trial data of this session
                info = readtable(obj.fileTable.path_info{i});
                info.mouse = strrep(info.mouse, 'm', 's');
                % total number of cells of this session
                nCells = length(data.good_cell_idx);
                % total number of frames of this session
                nFrames = size(data.dfof, 2);
                % number of trials of this session
                nTrails = height(info);
                % number of frames per trial
                framesPerTrial = nFrames / nTrails;
                % trial start index
                startTrialIdx = (0:nTrails - 1) * framesPerTrial + 1;
                % trial end index
                endTrialIdx = startTrialIdx + framesPerTrial - 1;
                % trial trigger index
                trialTriggerIdx = find(Param_LimbMvt_CranialWin_SingleCell().wfAlign.frameTime == 0) + startTrialIdx - 1;
                % time interval for frame sampling
                timeStep = 1 / Param_LimbMvt_CranialWin_SingleCell().wfAlign.frameRate;
                % time stamps for frames
                timeData = 0:timeStep:timeStep * (nFrames - 1);
                % TrigTimes for trigData
                TrigTimes = timeData(trialTriggerIdx);

                % Info for trigData
                Info = zeros(length(TrigTimes), 3);
                Info(:, 1) = 1:nTrails; % trial ID
                Info(:, 2) = 1; % stim ID, 1 out, 2 in
                Info(:, 3) = info.outcomeIdx; % outcome
                Info(:, 4) = info.mvtDir; % mvtDir
                % Traces for trigData
                Traces = cell(nCells, 1);

                for j = 1:nCells

                    for k = 1:nTrails
                        Traces{j, 1}(k, :) = data.zscore(j, startTrialIdx(k):endTrialIdx(k));
                    end

                end

                % bootstrap
                pVal = 0.01;
                nReps = 1999;
                sigCells = [];

                frameTime = Param_LimbMvt_CranialWin_SingleCell().wfAlign.frameTime;
                nPre = sum(frameTime < 0);
                nPost = sum(frameTime > 0);
                frameRate = Param_LimbMvt_CranialWin_SingleCell().wfAlign.frameRate;
                alignWin = Param_LimbMvt_CranialWin_SingleCell().wfAlign.alignWin;

                baseT = 0.75;
                anaT = 1.5;
                anaSamps = round(0.1 / (1 / frameRate));

                idxBase = frameTime < 0 & frameTime >= - baseT;
                idxAna = frameTime > 0 & frameTime <= anaT;

                mvtDirs = sort(unique(Info(:, 4)));

                Stats = cell(nCells, 1);

                % loop cell
                parfor j = 1:nCells

                    Stats{j, 1} = zeros(length(mvtDirs), 4);

                    % loop mvtdir
                    for k = 1:length(mvtDirs)
                        idx = Info(:, 4) == mvtDirs(k); %#ok<*PFBNS>

                        tt = Traces{j, 1}(idx, idxAna) - mean(Traces{j, 1}(idx, idxBase), 2);
                        [~, idxMaxMean] = max(abs(mean(tt, 1)), [], 2);
                        idxMaxMean = idxMaxMean + sum(frameTime <= 0);

                        if (idxMaxMean - anaSamps) > 0 && (idxMaxMean + anaSamps) < size(Traces{j, 1}, 2)
                            tt = Traces{j, 1}(idx, idxMaxMean - anaSamps:idxMaxMean + anaSamps) - mean(Traces{j, 1}(idx, idxBase), 2);
                            vals = mean(tt, 2);
                        else
                            tt = Traces{j, 1}(idx, idxMaxMean) - mean(Traces{j, 1}(idx, idxBase), 2);
                            vals = tt;
                        end

                        Stats{j, 1}(k, 1) = mean(vals); % mean
                        Stats{j, 1}(k, 2) = std(vals); % std
                        Stats{j, 1}(k, 3) = numel(vals); % n
                        Stats{j, 1}(k, 5) = frameTime(idxMaxMean); % t peak

                        nVals = length(vals);
                        a = find(timeData > abs(alignWin(1)), 1) +10;
                        b = find(timeData > timeData(end) - alignWin(2), 1) -10;
                        dff = data.zscore(j, :);

                        bootMeanVals = zeros(nReps, 1);

                        for l = 1:nReps
                            bootInds = randi(b - a, nVals, 1) + a;
                            tracesBoot = zeros(nVals, numel(frameTime));

                            for m = 1:nVals
                                tracesBoot(m, :) = dff(1, bootInds(m) - nPre:bootInds(m) + nPost);
                            end

                            tt = tracesBoot(:, idxAna) - mean(tracesBoot(:, idxBase), 2);
                            [~, idxMaxMean] = max(abs(mean(tt, 1)), [], 2);
                            idxMaxMean = idxMaxMean + sum(frameTime <= 0);

                            if (idxMaxMean - anaSamps) > 0 && (idxMaxMean + anaSamps) < size(tracesBoot, 2)
                                tt = tracesBoot(:, idxMaxMean - anaSamps:idxMaxMean + anaSamps) - mean(tracesBoot(:, idxBase), 2);
                                valsBoot = mean(tt, 2);
                            else
                                tt = tracesBoot(:, idxMaxMean) - mean(tracesBoot(:, idxBase), 2);
                                valsBoot = tt;
                            end

                            bootMeanVals(l) = mean(valsBoot);
                        end

                        repDiff = Stats{j, 1}(k, 1) - bootMeanVals;
                        pBoot = 2 * min([sum(repDiff > 0), sum(repDiff < 0)]) / nReps;
                        Stats{j, 1}(k, 4) = pBoot;

                    end

                    if any(Stats{j, 1}(:, 4) < pVal)
                        sigCells = [sigCells; j];
                    end

                end

                % create the trigData
                trigData = struct;
                trigData.Info = Info;
                trigData.TrigTimes = TrigTimes;
                trigData.Traces = Traces;
                trigData.CenterXY = data.centerXY';
                trigData.ContourXsYs = data.contourXsYs';
                trigData.Stats = Stats;
                trigData.sigCells = sigCells;
                trigData.periTime = frameTime;
                trigData.Tpre = abs(alignWin(1));
                trigData.Tpost = alignWin(2);

                % add data back to file table
                obj.fileTable.trigData{i} = trigData;

                % save the object
                obj.Save();
            end

        end

        %% function to convert coordinates to mm
        function obj = ConvertCoordToMM(obj)

            for i = 1:height(obj.fileTable)
                trigData = obj.fileTable.trigData{i};

                % if the trigData is empty or the unit is already mm, skip
                if isempty(trigData) || (isfield(trigData, 'unit') && strcmp(trigData.unit, 'mm'))
                    fprintf('TrigData already converted to mm for %s-%s\n', obj.fileTable.mouse{i}, obj.fileTable.session{i});
                    continue;
                end

                mouse = obj.fileTable.mouse{i};
                session = obj.fileTable.session{i};

                % try to load the CoorTransformer object
                try % first try to load the mouse and session specific object
                    CT = CoorTransform().Load({[mouse, '_', session], '.mat'});
                    fprintf('Loaded CoorTransform object for %s-%s\n', mouse, session);
                catch

                    try % if failed, try to load the mouse specific object
                        CT = CoorTransform().Load([mouse, '.mat']).Init([mouse, '.jpg'], [mouse, '_', session, '_REF.tif']);
                        fprintf('Loaded CoorTransform object for %s\n', mouse);
                    catch % if failed, create a new CoorTransformer object
                        CT = CoorTransform().Init([mouse, '.jpg'], [mouse, '_', session, '_REF.tif']);
                        fprintf('Created CoorTransform object for %s-%s\n', mouse, session);
                    end

                end

                % perform the transformation
                for j = 1:length(trigData.CenterXY)
                    trigData.CenterXY{j} = CT.Apply(trigData.CenterXY{j});
                    trigData.ContourXsYs{j} = CT.Apply(trigData.ContourXsYs{j});
                end

                % indicate the unit of the coordinates
                trigData.unit = 'mm';

                % save the transformed data back to the file table
                obj.fileTable.trigData{i} = trigData;
            end

        end
        %% save the object without the gui handles
        function obj = Save(obj)
            guiHCopy = obj.guiH;
            obj.guiH = [];
            saveObjToStruct(obj, fullfile(obj.folderPath, 'TrigData.mat'));
            fprintf('Saved WFS object to %s\n', obj.folderPath);
            obj.guiH = guiHCopy;
        end

        %% load from struct
        function Load(obj)
            S = load(fullfile(obj.folderPath, 'TrigData.mat')).obj;
            restoreObjFromStruct(obj, S);
        end
        
    end

end
