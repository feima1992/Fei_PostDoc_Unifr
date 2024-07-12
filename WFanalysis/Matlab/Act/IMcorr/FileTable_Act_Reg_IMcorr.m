classdef FileTable_Act_Reg_IMcorr < FileTable_Act_Reg
    %% Methods
    methods
        %% Construcctor
        function obj = FileTable_Act_Reg_IMcorr(varargin)
            % Call superclass constructor
            obj = obj@FileTable_Act_Reg(varargin{:});
        end

        %% Function load IMcorr
        function obj = LoadIMcorr(obj)
            % Notify the user that files are being loaded
            fprintf('   Loading IMcorr from %d files\n', height(obj.fileTable))
            tic;
            % Load deltaFoverF
            obj.fileTable = loadDataIMcorr(obj.fileTable, 'loadIMcorrType', 'IMcorrREG', 'imMaskSource', 'internal');
            % Notify the user that loading is done and how long it took
            fprintf('   Loading IMcorr from %d files took %.2f seconds\n', height(obj.fileTable), toc)
        end

        %% Calculate Act map
        function obj = CalActMap(obj, threValue)

            if nargin < 2
                threValue = 0.5;
                fprintf('   Using default threshold value %.2f\n', threValue)
            end

            if ~ismember('IMcorr', obj.fileTable.Properties.VariableNames)
                obj.LoadIMcorr();
            end

            for i = 1:height(obj.fileTable)
                obj.fileTable.IMcorr{i} = Frames_IMcorr(obj.fileTable.IMcorr{i}).CalActMap(threValue).frameData;
            end

        end

        %% Group average Act map
        function obj = CalAvgIMcorr(obj, groupby)

            if ~ismember('IMcorr', obj.fileTable.Properties.VariableNames)
                obj.CalActMap();
            end

            [gIdx, gName] = findgroups(obj.fileTable(:, groupby));
            IMcorr = splitapply(@(X){mean(cat(4, X{:}), 4)}, obj.fileTable.IMcorr, gIdx);
            obj.fileTable = [gName, table(IMcorr)];
        end

        %% Calculate IMcorr properties
        function obj = CalActProps(obj)

            if ~ismember('IMcorr', obj.fileTable.Properties.VariableNames)
                obj.LoadIMcorr();
                obj.CalActMap();
            end

            uenoMask = MaskUeno();

            for i = 1:height(obj.fileTable)
                obj.fileTable.IMcorr{i} = Frames_IMcorr(obj.fileTable.IMcorr{i}, Param().wfAlign.frameTime, uenoMask).CalRegionProps().frameProps;
            end

            obj.fileTable = expendColumn(obj.fileTable, 'IMcorr');
        end

    end

end
