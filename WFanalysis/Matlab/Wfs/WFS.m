classdef WFS < handle
    %% Properties
    properties
       folderPath;
       fileTable;
       fileTableExp;
    end
    %% Methods
    methods
        %% constructor
        function obj = WFS(varargin)

            if nargin < 1
                obj.folderPath = 'D:\Data\SingleCellData';
                varargin = {obj.folderPath};
            else
                obj.folderPath = varargin{1};
            end
            % try to load the object
            try
                obj = obj.Load();
                fprintf('Loaded WFS object from %s\n', obj.folderPath);
                obj.folderPath = varargin{1};
            catch
                % if failed, get the file table
                comp = FileTable(varargin{:}, 'coordAndTrace.mat').CleanVar({'folder','namefull'}).fileTable;
                info = FileTable(varargin{:}, '.csv').CleanVar({'folder','namefull'}).fileTable;

                % join the tables by mouse and session
                obj.fileTable = innerjoin(comp, info, 'Keys', {'mouse','session'});
                
                % get the trig data
                obj.GetTrigData();

                % save the object
                obj.Save();
            end
        end
        
        %% compute the trig data
        function obj = GetTrigData(obj, redo)
            if nargin < 2
                redo = false;
            end
            %% Bootstrap to find significant cells
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
                info.mouse = strrep(info.mouse, 'm','s');
                
                % total number of cells of this session
                nCells = length(data.good_cell_idx);
                % total number of frames of this session
                nFrames = size(data.dfof,2);
                % number of trials of this session
                nTrails = height(info);
                % number of frames per trial
                framesPerTrial = nFrames/nTrails;
                % trial start index
                startTrialIdx = (0:nTrails-1)*framesPerTrial+1;
                % trial end index
                endTrialIdx = startTrialIdx + framesPerTrial - 1;
                % trial trigger index
                trialTriggerIdx = find(Param_LimbMvt_CranialWin_SingleCell().wfAlign.frameTime == 0) + startTrialIdx - 1 ;
                
                % time interval for frame sampling
                timeStep = 1/Param_LimbMvt_CranialWin_SingleCell().wfAlign.frameRate;
                
                % time stamps for frames
                timeData = 0:timeStep:timeStep*(nFrames-1);
                
                % TrigTimes for trigData
                TrigTimes = timeData(trialTriggerIdx);

                Info = zeros(length(TrigTimes),3);
                Info(:,1) = 1:nTrails; % trial ID
                Info(:,2) = 1; % stim ID, 1 out, 2 in
                Info(:,3) = info.outcomeIdx; % outcome
                Info(:,4) = info.mvtDir; % mvtDir
                
                % Traces for trigData
                Traces = cell(nCells,1);
                for j = 1:nCells
                    for k = 1:nTrails
                        Traces{j,1}(k,:) = data.zscore(j,startTrialIdx(k):endTrialIdx(k));
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
                anaSamps = round(0.1/(1/frameRate));

                idxBase = frameTime < 0 & frameTime >= - baseT;
                idxAna = frameTime > 0 & frameTime <= anaT;
                
                mvtDirs = sort(unique(Info(:,4)));

                Stats = cell(nCells,1);

                % loop cell
                parfor j = 1:nCells

                    Stats{j,1} = zeros(length(mvtDirs),4);
                    
                    % loop mvtdir
                    for k = 1:length(mvtDirs)
                        idx = Info(:,4) == mvtDirs(k); %#ok<*PFBNS> 
                        
                        tt = Traces{j,1}(idx, idxAna) - mean(Traces{j,1}(idx, idxBase),2);
                        [~,idxMaxMean] = max(abs(mean(tt,1)),[],2);
                        idxMaxMean = idxMaxMean + sum(frameTime <= 0);
                        
                        if (idxMaxMean - anaSamps) > 0 && (idxMaxMean + anaSamps) < size(Traces{j,1},2)
                            tt = Traces{j,1}(idx, idxMaxMean-anaSamps:idxMaxMean+anaSamps) - mean(Traces{j,1}(idx, idxBase),2);
                            vals = mean(tt,2);
                        else
                            tt = Traces{j,1}(idx, idxMaxMean) - mean(Traces{j,1}(idx, idxBase),2);
                            vals = tt;
                        end


                        Stats{j,1}(k,1) = mean(vals); % mean
                        Stats{j,1}(k,2) = std(vals); % std
                        Stats{j,1}(k,3) = numel(vals); % n
                        Stats{j,1}(k,5) = frameTime(idxMaxMean); % t peak


                        nVals = length(vals);
                        a  = find(timeData > abs(alignWin(1)),1) +10;
                        b  = find(timeData > timeData(end) - alignWin(2),1) -10;
                        dff = data.zscore(j,:);

                        bootMeanVals = zeros(nReps,1);

                        for l = 1:nReps
                            bootInds = randi(b-a, nVals, 1) + a;
                            tracesBoot = zeros(nVals, numel(frameTime));
                            for m = 1:nVals
                                tracesBoot(m,:) = dff(1, bootInds(m)-nPre:bootInds(m)+nPost);
                            end
                            tt = tracesBoot(:, idxAna) - mean(tracesBoot(:, idxBase),2);
                            [~,idxMaxMean] = max(abs(mean(tt,1)),[],2);
                            idxMaxMean = idxMaxMean + sum(frameTime <= 0);
                            if (idxMaxMean - anaSamps) > 0 && (idxMaxMean + anaSamps) < size(tracesBoot,2)
                                tt = tracesBoot(:, idxMaxMean-anaSamps:idxMaxMean+anaSamps) - mean(tracesBoot(:, idxBase),2);
                                valsBoot = mean(tt,2);
                            else
                                tt = tracesBoot(:, idxMaxMean) - mean(tracesBoot(:, idxBase),2);
                                valsBoot = tt;
                            end
                            bootMeanVals(l) = mean(valsBoot);
                        end

                        repDiff = Stats{j,1}(k,1) - bootMeanVals;
                        pBoot = 2*min([sum(repDiff > 0), sum(repDiff < 0)])/nReps;
                        Stats{j,1}(k,4) = pBoot;

                    end

                    if any((Stats{j,1}(:,4) < pVal) & (Stats{j,1}(:,5)>0 & Stats{j,1}(:,5)<=0.8))
                        sigCells = [sigCells; j];
                    end
                end

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

        %% get the tuning properties
        function obj = GetTuningProp(obj)
            for i = 1:height(obj.fileTable)
                trigData = obj.fileTable.trigData{i};
                trigData.sigCells(:,2:end) = [];
                % get the gaussian fit of the tuning curve
                fitResult = zeros(size(trigData.sigCells,1),8);
                for j = 1:size(trigData.sigCells,1)
                    fitResult(j,:) = fitGaussOut(trigData, trigData.sigCells(j));
                end
                trigData.sigCells = [trigData.sigCells, fitResult]; % sigCellIdx, mu, sigma, r2, badFit, PDround, circMean, circVar, pSelect
                obj.fileTable.trigData{i} = trigData;
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
                    CT = CoorTransform().Load({[mouse, '_', session],'.mat'});
                    fprintf('Loaded CoorTransform object for %s-%s\n', mouse, session);
                catch 
                    try % if failed, try to load the mouse specific object
                        CT = CoorTransform().Load([mouse, '.mat']).Init([mouse,'.jpg'], [mouse, '_', session, '_REF.tif']);
                        fprintf('Loaded CoorTransform object for %s\n', mouse);
                    catch   % if failed, create a new CoorTransformer object
                        CT = CoorTransform().Init([mouse,'.jpg'], [mouse, '_', session, '_REF.tif']);
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
        
        
        %% plot spatial footprints
        function PlotSpatialFootprints(obj)
            if isempty(obj.fileTableExp)
                % expend trigData to single cell level
                fileTableExp = table();
                for i = 1:height(obj.fileTable)
                    % get the trigData
                    trigData = obj.fileTable.trigData{i};
                    % for each cell
                    for j = 1:size(trigData.Traces,1)
                        % create a new row
                        newRow = obj.fileTable(i,:);
                        newRow.trigData = [];
                        % add the cell index
                        newRow.cellIdx = j;
                        % add the centerXY
                        newRow.centerX = trigData.CenterXY{j}(1);
                        newRow.centerY = trigData.CenterXY{j}(2);
                        % add the significant response cell
                        newRow.sigResp = ismember(j, trigData.sigCells(:,1));
                        % add the significant tuning cell
                        newRow.sigTuning = ismember(j, trigData.sigCells(trigData.sigCells(:,9) < 0.05,1));
                        % add the preferred direction if it is a significant tuning cell
                        if newRow.sigTuning
                            newRow.gaussianPD = trigData.sigCells(trigData.sigCells(:,1) == j, 2);
                            newRow.eightDirPD = trigData.sigCells(trigData.sigCells(:,1) == j, 6);
                        else
                            newRow.gaussianPD = NaN;
                            newRow.eightDirPD = NaN;
                        end
                        % add the fileTableExp
                        fileTableExp = [fileTableExp; newRow];
                    end
                end
                % sort the fileTableExp by sigResp and sigTuning
                fileTableExp = sortrows(fileTableExp, {'sigResp','sigTuning'}, 'descend');
                % save the fileTableExp
                obj.fileTableExp = fileTableExp;
                obj.Save();
            end

            % plot the spatial footprints (centerXY) of cells
            % no sigResp cells: gray circle, no edge, size 15, transparency 0.5
            % sigResp cells: black circle, no edge, size 30, transparency 1
            % sigTuning cells, color by eightDirPD, no edge, size 30, transparency 1
            
            % sort the fileTableExp by sigResp and sigTuning so that sigResp cells, sigTuning cells are plotted on top
            obj.fileTableExp = sortrows(obj.fileTableExp, {'sigResp','sigTuning'}, 'ascend');
            % get the plot coordinates of the cells
            x = obj.fileTableExp.centerX;
            y = obj.fileTableExp.centerY;

            % compute the color of the cells
            colorMap = zeros(height(obj.fileTableExp),3)+0.8; % default color is gray
            colorMap(obj.fileTableExp.sigResp, :) = 0; % sigResp cells are black
            eightDirPDsigTuning = obj.fileTableExp.eightDirPD(obj.fileTableExp.sigTuning)./360;
            eightDirPDsigTuning(:,2) = 1;
            eightDirPDsigTuning(:,3) = 1;
            colorMap(obj.fileTableExp.sigTuning, :) = hsv2rgb(eightDirPDsigTuning); % sigTuning cells are colored by eightDirPD
            mvtDir = [0, 45, 90, 135, 180, 225, 270, 315];
            mvtDirColor = zeros(length(mvtDir),3);
            mvtDirColor(:,1) = mvtDir./360;
            mvtDirColor(:,2) = 1;
            mvtDirColor(:,3) = 1;
            mvtDirColor = hsv2rgb(mvtDirColor);
            % compute the alpha of the cells
            alphaMap = zeros(height(obj.fileTableExp),1)+1; % default alpha is 0.5
            alphaMap(obj.fileTableExp.sigResp, :) = 1; % sigResp cells are 1
            % compute the size of the cells
            sizeMap = zeros(height(obj.fileTableExp),1)+15; % default size is 15
            sizeMap(obj.fileTableExp.sigResp, :) = 30; % sigResp cells are 30

            % plot the cells
            figure;
            s = scatter(x, -y, sizeMap, colorMap, 'filled', 'MarkerEdgeColor', 'none'); % flip the y because now anterior is negative
            s.AlphaData = alphaMap;
            s.MarkerFaceAlpha = 'flat';            
            % plot arrow legends to indicate the preferred direction of sigTuning cells
            hold on;
            for i = 1:length(mvtDir)
                quiver(0, 0, 0.5*cosd(mvtDir(i)), 0.5*sind(mvtDir(i)), 'Color', mvtDirColor(i,:), 'LineWidth', 1);
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
            plot(coordsSensory(:,1), coordsSensory(:,2), 'b--', 'LineWidth', 1);
            plot(coordsAvgMotor(:,1), coordsAvgMotor(:,2), 'r--', 'LineWidth', 1);

            % set the axis limits
            xlim([-4.5, 0.5]);
            ylim([-2.5, 2.5]);
            axis equal;

            % set the axis labels
            xlabel('Medial-Lateral (mm)');
            ylabel('Anterior-Posterior (mm)');

            % select point in the plot to display the cell index
            set(s, 'ButtonDownFcn', @(src, event) ClickCallback(src, event, obj));
            
            function ClickCallback(h, e, obj)

                % --- Get coordinates
                x = get(h, 'XData');
                y = get(h, 'YData');
                
                % --- Get index of the clicked point
                [~, i] = min((e.IntersectionPoint(1)-x).^2 + (e.IntersectionPoint(2)-y).^2);
                
                % get mouse and session
                mouse = obj.fileTableExp.mouse{i};
                session = obj.fileTableExp.session{i};
                cellIdx = obj.fileTableExp.cellIdx(i);

                % print the cell index
                fprintf('Mouse: %s, Session: %s, Cell Index: %d\n', mouse, session, cellIdx);
                
                % find the corresponding trigData in obj.fileTable
                idx = find(strcmp(obj.fileTable.mouse, mouse) & strcmp(obj.fileTable.session, session));
                trigData = obj.fileTable.trigData{idx};
                plotDirTune(trigData, cellIdx);
                fitGaussOut(trigData, cellIdx, 1);
            end                
            
        end

        %% save the object
        function Save(obj)
            save(fullfile(obj.folderPath, 'TrigData.mat'), 'obj');
            fprintf('Saved WFS object to %s\n', obj.folderPath);
        end

        %% load the object
        function obj = Load(obj)
            result = load(fullfile(obj.folderPath, 'TrigData.mat'));
            obj = result.obj;
        end
    end
end