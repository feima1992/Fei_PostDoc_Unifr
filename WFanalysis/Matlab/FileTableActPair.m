classdef FileTableActPair < handle
    %% Properties
    properties
        fileTableAct
        pairMethod = 'training-baseline';
        filePair
        diffMapAvg
    end
    
    
    
    %% Methods
    methods
        %% Constructor
        function obj = FileTableActPair(pairMethod, fileTableAct)
            % Parse input
            if nargin == 0
                obj.fileTableAct = FileTableAct();
            elseif nargin == 1
                obj.pairMethod = pairMethod;
                obj.fileTableAct = FileTableAct();
            else
                obj.pairMethod = pairMethod;
                obj.fileTableAct = fileTableAct;
            end
            
            % Add filePair to object
            switch obj.pairMethod
                case {'training-baseline', 'all-random'}
                    obj.filePair = pairActFile(obj.fileTableAct.fileTable, 'pairMethod', obj.pairMethod);
                case {'allMthods', 'all', 'allMethod'}
                    obj.filePair = [pairActFile(obj.fileTableAct.fileTable, 'pairMethod', 'training-baseline'); ...
                        pairActFile(obj.fileTableAct.fileTable, 'pairMethod', 'all-random')];
            end
        end
        
        %% Function CalDiffMap
        function obj = CalPairDiffMap(obj)
            % If the deltaFoverF is not loaded, load it
            if ~ismember('deltaFoverF', obj.fileTableAct.fileTable.Properties.VariableNames)
                obj.fileTableAct.LoadDeltaFoverF();
            end
            
            % Calculate the diffDeltaFoverF as diffMap
            funcDiffMap = @(X,Y)X-Y;
            obj.filePair.diffMap = rowfun(funcDiffMap, obj.filePair, 'InputVariables', {'deltaFoverF2', 'deltaFoverF1'}, 'OutputVariableNames', 'diffMap', 'ExtractCellContents', true, 'OutputFormat', 'cell');
            
            % Calculate diffMapAvg
            [G, mosuePairType] = findgroups(obj.filePair(:, {'mouse', 'pairType'}));
            diffMap = splitapply(@(X){mean(cat(3, X{1}), 3,'omitnan')}, obj.filePair.diffMap, G);
            obj.diffMapAvg = [mosuePairType, table(diffMap)];
            
            % Plot diffMapAvg for each mouse and pairType
            clim = cell2mat(cellfun(@(X)[min(X(:)), max(X(:))], obj.diffMapAvg.diffMap, 'UniformOutput', false));
            % Determine the number of rows and columns of the plot, best be a square
            nPlot = height(obj.diffMapAvg); nRow = ceil(sqrt(nPlot)); nCol = ceil(nPlot/nRow);
            % Create a figure
            figure('Name', 'diffMapAvg', 'Position', [100, 100, 1000, 1000], 'Color', 'w');
            
            for i = 1:height(obj.diffMapAvg)
                params = struct();
                params.clim = max(abs(clim(:)))*[-1, 1];
                params.title = [obj.diffMapAvg.mouse{i}, ' ', obj.diffMapAvg.pairType{i}];
                params = namedargs2cell(params);
                plotFrame(obj.diffMapAvg.diffMap{i},subplot(nRow, nCol, i), params{:});
            end
        end
    end
    
end
