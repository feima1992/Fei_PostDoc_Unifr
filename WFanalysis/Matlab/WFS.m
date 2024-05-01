classdef WFS
    %% Properties
    properties
       fileTable
       dataTable
    end
    %% Methods
    methods
        %% constructor
        function obj = WFS(varargin)

            if nargin < 1
                folderPath = 'D:\Data\SingleCellData';
                varargin = {folderPath};
            end

            % get the file table of components and info
            comp = FileTable(varargin{:}, 'coordAndTrace.mat').CleanVar({'folder','namefull'}).fileTable;
            info = FileTable(varargin{:}, '.csv').CleanVar({'folder','namefull'}).fileTable;

            % join the tables by mouse and session
            obj.fileTable = innerjoin(comp, info, 'Keys', {'mouse','session'});
        end
        
        %% Load files
        function obj = Load(obj)
            dataTable = table(); %#ok<*PROP>
            for i = 1:height(obj.fileTable)
                % load the component data
                data = load(obj.fileTable.path_comp{i});
                data.good_cell_idx = data.good_cell_idx+1;
                % read the info csv file
                info = readtable(obj.fileTable.path_info{i});
                info.mouse = strrep(info.mouse, 'm','s');
                info = info(:,{'mouse','session','trial','outcome','outcomeIdx', 'mvtDir'});
                % number of frames each trial
                nFrames = size(data.dfof,2);
                nTrails = height(info);
                nComp = length(data.good_cell_idx);
                % create the table
                for k = 1:nTrails
                    thisTrialIdx = ((k-1)*nFrames/nTrails + 1 : k*nFrames/nTrails)';
                    % get the trial info
                    trialInfo = repmat(info(k,:),nComp,1);
                    % get the time info 
                    trialInfo.time = repmat({Param_LimbMvt_CranialWin_SingleCell().wfAlign.frameTime},nComp,1);
                    % get the component ids
                    trialInfo.compIds = data.good_cell_idx';
                    % get the component data
                    trialInfo.dfof = num2cell(data.dfof(data.good_cell_idx, thisTrialIdx),2);
                    % get the center data
                    trialInfo.center = data.centerXY(1, data.good_cell_idx)';
                    % get the contour data
                    trialInfo.contour = data.contourXsYs(1, data.good_cell_idx)';
                    % append to the table
                    dataTable = [dataTable; trialInfo]; %#ok<AGROW>
                end
                obj.dataTable = dataTable;
            end
            % calculate the zscore of the dfof
            obj.dataTable.zscore = cellfun(@(X)zscore(X,0,2), obj.dataTable.dfof, 'UniformOutput', false);
            % calculate the max of the zscore
            obj.dataTable.zscoreMax = cellfun(@(X)max(X,[],2), obj.dataTable.zscore);
            % calculate the max position of the zscore
            obj.dataTable.zscoreMaxPos = cellfun(@(X)find(X==max(X,[],2),1), obj.dataTable.zscore);
            % calculate the time of the max position
            obj.dataTable.zscoreMaxTime = obj.dataTable.time{1}(obj.dataTable.zscoreMaxPos)';
            
            % calculate the response type
            % if the max zscore >= 3, then it is a response
            %   if the zscoreMaxTime <0.1 then it is a supressed response
            %   if the zscoreMaxTime >=0.1 & <0.5 then it is an excitated response
            %   if the zscoreMaxTime >=0.5 then it is an excitated-delay response
            % if the max zscore < 3, then it is a no response

            obj.dataTable.responseType = cell(height(obj.dataTable),1);
            obj.dataTable{obj.dataTable.zscoreMax>=3 & obj.dataTable.zscoreMaxTime<0.1, 'responseType'} = {'supressed'};
            obj.dataTable{obj.dataTable.zscoreMax>=3 & obj.dataTable.zscoreMaxTime>=0.1 & obj.dataTable.zscoreMaxTime<0.5, 'responseType'} = {'excitated'};
            obj.dataTable{obj.dataTable.zscoreMax>=3 & obj.dataTable.zscoreMaxTime>=0.5, 'responseType'} = {'excitated-delay'};
            obj.dataTable{obj.dataTable.zscoreMax<3, 'responseType'} = {'noResponse'};
            
        end
        %% Calculate the average dfof
        function obj = CalAvgDfof(obj, groupby)
            [gIdx,gName] = findgroups(obj.dataTable(:,groupby));
            dfofAvg = splitapply(@(X){mean(cat(1,X{:}),1)},obj.dataTable.dfof,gIdx);
            dfofStd = splitapply(@(X){std(cat(1,X{:}),1)},obj.dataTable.dfof,gIdx);
            zscoreAvg = splitapply(@(X){mean(cat(1,X{:}),1)},obj.dataTable.zscore,gIdx);
            zscoreStd = splitapply(@(X){std(cat(1,X{:}),1)},obj.dataTable.zscore,gIdx);
            obj.dataTable = [gName, table(dfofAvg) , table(dfofStd), table(zscoreAvg), table(zscoreStd)];
        end

        %% Plot the heatmap
        function obj = PlotHeatmapRespondType(obj)
            % calculate the response type
            % if the max zscore >= 3, then it is a response
            %   if the zscoreMaxTime <0.1 then it is a supressed response
            %   if the zscoreMaxTime >=0.1 & <0.5 then it is an excitated response
            %   if the zscoreMaxTime >=0.5 then it is an excitated-delay response
            % if the max zscore < 3, then it is a no response

            obj.dataTable.responseType = cell(height(obj.dataTable),1);
            obj.dataTable{obj.dataTable.zscoreMax>=3 & obj.dataTable.zscoreMaxTime<0.1, 'responseType'} = {'supressed'};
            obj.dataTable{obj.dataTable.zscoreMax>=3 & obj.dataTable.zscoreMaxTime>=0.1 & obj.dataTable.zscoreMaxTime<0.5, 'responseType'} = {'excitated'};
            obj.dataTable{obj.dataTable.zscoreMax>=3 & obj.dataTable.zscoreMaxTime>=0.5, 'responseType'} = {'excitated-delay'};
            obj.dataTable{obj.dataTable.zscoreMax<3, 'responseType'} = {'noResponse'};

            % get the cbar limits
            cbarLim = [min(cellfun(@(X)min(X(:)), obj.dataTable.zscore)), max(cellfun(@(X)max(X(:)), obj.dataTable.zscore))];

            % group the table by response type
            [gIdx,gName] = findgroups(obj.dataTable(:,'responseType'));

            % plot the heatmap for each group
            figure('Name','Heatmap', 'Color','w');
            tiledlayout('flow');
            for i = 1:height(gName)
                nexttile;
                imagesc(cat(1,obj.dataTable.zscore{gIdx==i}));
                title(gName{i,1});
                clim(cbarLim);
                % set xticks and xticklabels
                xticks(1:length(obj.dataTable.time{1}));
                xticklabels(num2str(obj.dataTable.time{1}(:),'%.2f'));
                xlabel('Time (s)');
                % set ytickformat
                ylabel('Component * Trial');
                % hold on
                xline(find(obj.dataTable.time{1}==0), 'r--', 'Stimulus Onset');
            end
            % set the colorbar
            c = colorbar;
            c.Label.String = 'Zscore';
            c.Layout.Tile = 'east';

            %% Calculate the everage zscore for each session and trial
            [gIdx,gName] = findgroups(obj.dataTable(:,{'mouse','session','compIds'}));
            zscore = splitapply(@(X){mean(cat(1,X{:}),1)},obj.dataTable.zscore,gIdx);
            zscoreStd = splitapply(@(X){std(cat(1,X{:}),1)},obj.dataTable.zscore,gIdx);
            trialAvgDataTable = [gName, table(zscore), table(zscoreStd)];
            % calculate the max of the zscore
            trialAvgDataTable.zscoreMax = cellfun(@(X)max(X,[],2), trialAvgDataTable.zscore);
            % calculate the max position of the zscore
            trialAvgDataTable.zscoreMaxPos = cellfun(@(X)find(X==max(X,[],2),1), trialAvgDataTable.zscore);
            % calculate the time of the max position
            trialAvgDataTable.zscoreMaxTime = obj.dataTable.time{1}(trialAvgDataTable.zscoreMaxPos)';
            % calculate the response type
            % if the max zscore >= 3, then it is a response
            %   if the zscoreMaxTime <0.1 then it is a supressed response
            %   if the zscoreMaxTime >=0.1 & <0.5 then it is an excitated response
            %   if the zscoreMaxTime >=0.5 then it is an excitated-delay response
            % if the max zscore < 3, then it is a no response
            trialAvgDataTable.responseType = cell(height(trialAvgDataTable),1);
            trialAvgDataTable{trialAvgDataTable.zscoreMax>=1 & trialAvgDataTable.zscoreMaxTime<0.1, 'responseType'} = {'supressed'};
            trialAvgDataTable{trialAvgDataTable.zscoreMax>=1 & trialAvgDataTable.zscoreMaxTime>=0.1 & trialAvgDataTable.zscoreMaxTime<0.5, 'responseType'} = {'excitated'};
            trialAvgDataTable{trialAvgDataTable.zscoreMax>=1 & trialAvgDataTable.zscoreMaxTime>=0.5, 'responseType'} = {'excitated-delay'};
            trialAvgDataTable{trialAvgDataTable.zscoreMax<1, 'responseType'} = {'noResponse'};
            % plot the heatmap for each group
            figure('Name','Heatmap', 'Color','w');
            tiledlayout('flow');
            [gIdx,gName] = findgroups(trialAvgDataTable(:,'responseType'));
            cbarLim = [min(cellfun(@(X)min(X(:)), trialAvgDataTable.zscore)), max(cellfun(@(X)max(X(:)), trialAvgDataTable.zscore))];
            for i = 1:height(gName)
                nexttile;
                imagesc(cat(1,trialAvgDataTable.zscore{gIdx==i}));
                title(gName{i,1});
                clim(cbarLim);
                % set xticks and xticklabels
                xticks(1:length(obj.dataTable.time{1}));
                xticklabels(num2str(obj.dataTable.time{1}(:),'%.2f'));
                xlabel('Time (s)');
                % set ytickformat
                ylabel('Component');
                % hold on
                xline(find(obj.dataTable.time{1}==0), 'r--', 'Stimulus Onset');
            end
            % set the colorbar
            c = colorbar;
            c.Label.String = 'Zscore';
            c.Layout.Tile = 'east';

            % test
            
        end
    end
end