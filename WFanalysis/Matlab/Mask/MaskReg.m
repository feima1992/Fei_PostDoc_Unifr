classdef MaskReg < handle
    %% Properties
    properties
        selectRoi
        abmModuleMap
        abmModuleLabel
        maskTable = table(); % maskTable table
    end

    %% Methods
    methods
        %% Constructor
        function obj = MaskReg(selectRoi)
            % Set properties
            [obj.abmModuleMap, obj.abmModuleLabel] = loadAbmModule();
            obj.selectRoi = selectRoi;
            % Update
            obj.Update();
        end

        %% Update maskTable
        function Update(obj)
            % Get maskTable
            % convert selectRoi to string
            selectRoiTable = table(cellfun(@(X)strrep(num2str(X), '  ', ','), obj.selectRoi, 'UniformOutput', false)', 'VariableNames', {'id'});
            % join with abmModuleLabel, left join and keep the order of left table
            moduleIdNameTable = leftJoin(selectRoiTable, obj.abmModuleLabel, 'Keys', 'id');
            % display selected roi that are not in abmModuleLabel
            if ~isempty(setdiff(selectRoiTable.id, moduleIdNameTable.id))
                warning('The following selected roi are not in abmModuleLabel: %s', strjoin(setdiff(selectRoiTable.id, moduleIdNameTable.id), ', '));
            end

            maskIdx = cellfun(@(X)ismember(obj.abmModuleMap, X), obj.selectRoi, 'UniformOutput', false)';
            obj.maskTable = [moduleIdNameTable, table(maskIdx, 'VariableNames', {'maskTable'})];
        end

        %% Setter
        function set.selectRoi(obj, value)
            % Check input
            if ~iscell(value)
                value = {value};
            end

            if ~all(cellfun(@(x) isnumeric(x) && isvector(x), value))
                error('selectRoi must be a numeric vector or a cell array of numeric vectors');
            end

            % Set property
            obj.selectRoi = value;
            % Update maskTable
            obj.Update();
        end

        %% Plot
        function PlotAbmModule(obj, varargin)
            % parse input
            P = inputParser;
            addRequired(P, 'obj', @(x) isa(x, 'MaskReg'));
            addOptional(P, 'ax', gca, @(x) isgraphics(x, 'axes'));
            parse(P, obj, varargin{:});
            ax = P.Results.ax;
            % plot
            imagesc(ax, obj.abmModuleMap); axis image; axis off;
            % remap the color map
            cColor = colormap;
            cColor = repmat([0.9, 0.9, 0.9], size(cColor, 1), 1);
            cColor(1, :) = [0, 0, 0]; % black edge color
            cColor(3, :) = [1, 1, 1]; % white background
            colormap(cColor);
            % add module label
            moudleId = sort(unique(obj.abmModuleMap));

            for i = 6:length(moudleId)
                [y, x] = find(obj.abmModuleMap == moudleId(i));
                cLabel = obj.abmModuleLabel{ismember(obj.abmModuleLabel.id, num2str(moudleId(i))), 'moduleNameAbb'};

                if (length(x)) > 50 && (~isempty(cLabel))
                    text(mean(x), mean(y), cLabel{1}, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 8, 'Color', 'k');
                end

            end

        end

        function PlotSelectRoi(obj, varargin)
            % parse input
            P = inputParser;
            addRequired(P, 'obj', @(x) isa(x, 'MaskReg'));
            addOptional(P, 'ax', gca, @(x) isgraphics(x, 'axes'));
            addOptional(P, 'whichRoi', 1, @(x) isnumeric(x) && isscalar(x));
            parse(P, obj, varargin{:});
            ax = P.Results.ax;
            % plot
            abmModuleMapPlot = zeros(size(obj.abmModuleMap));
            abmModuleMapPlot(obj.abmModuleMap == 0) = 0; % outline
            abmModuleMapPlot(obj.abmModuleMap == 1) = 1; % background
            abmModuleMapPlot(obj.abmModuleMap > 1) = 2; % modules

            selectRoiPlot = obj.selectRoi{P.Results.whichRoi};

            for i = 1:length(selectRoiPlot)
                abmModuleMapPlot(ismember(obj.abmModuleMap, selectRoiPlot(i))) = i + 2;
            end

            imagesc(ax, abmModuleMapPlot); axis image; axis off; colormap(colorcube(length(selectRoiPlot) + 3));
            
            % remap the color map
            cColor = colormap;
            cColor(1, :) = [0, 0, 0]; % black edge color
            cColor(2, :) = [1, 1, 1]; % white background
            cColor(3, :) = [0.9, 0.9, 0.9]; % gray unselected modules
            cColor(4:end, :) = lines(length(selectRoiPlot)); % color selected modules
            colormap(cColor);

            % add module label
            moudleId = sort(unique(obj.abmModuleMap));

            for i = 6:length(moudleId)
                [y, x] = find(obj.abmModuleMap == moudleId(i));
                cLabel = obj.abmModuleLabel{ismember(obj.abmModuleLabel.id, num2str(moudleId(i))), 'moduleNameAbb'};

                if (length(x)) > 50 && (~isempty(cLabel))
                    text(mean(x), mean(y), cLabel{1}, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 8, 'Color', 'k');
                end

            end

        end

    end

end
