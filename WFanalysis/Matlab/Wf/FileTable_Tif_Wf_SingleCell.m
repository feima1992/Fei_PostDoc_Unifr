classdef FileTable_Tif_Wf_SingleCell < FileTable_Tif_Wf
    %% Methods
    methods
        %% Constructor
        function obj = FileTable_Tif_Wf_SingleCell(varargin)
            obj = obj@FileTable_Tif_Wf(varargin{:});
        end

        %% GetRefImage
        function GetRefImage(obj)
            % Get the reference image for each mouse and session (the earliest trial)
            [~, fileTableRefIdx] = findgroups(obj.fileTable(:, {'mouse', 'session'}));
            [~, fileTableRefIdx] = ismember(fileTableRefIdx, obj.fileTable(:, {'mouse', 'session'}));
            fileTableRef = obj.fileTable(fileTableRefIdx, :);
            % Get the reference image path for each mouse and session
            funcRefPath = @(X, Y)fullfile(Param().dir.coorTransformImage, [X, '_', Y, '_REF.tif']);
            fileTableRef.refPath = rowfun(funcRefPath, fileTableRef, 'InputVariables', {'mouse', 'session'}, 'OutputVariableNames', 'refPath', 'ExtractCellContents', true, 'OutputFormat', 'cell');
            fileTableRef.refPathExist = cellfun(@(X)exist(X, 'file'), fileTableRef.refPath);
            % Filter out the sessions without reference image or violet reference image
            fileTableRef = fileTableRef(~fileTableRef.refPathExist, :);
            % Extract the reference image for each mouse and session
            for i = 1:height(fileTableRef)
                % Extract the reference image
                refImage = imread(fileTableRef.path{i}, 1);
                % Save the reference image
                imwrite(refImage, fileTableRef.refPath{i});
                % Show notification
                fprintf('   Reference image for %s %s extracted\n', fileTableRef.mouse{i}, fileTableRef.session{i});
            end

        end

        %% AddFrameTime
        function AddFrameTime(obj)
            % add frameIdx and frameTime to the fileTable
            for i = 1:height(obj.fileTable)
                % Get the frameIdx and frameTime
                [frameTime, frameIdx] = loadTifTime(obj.fileTable.path{i});
                % Add the frameIdx and frameTime to the fileTable
                obj.fileTable.frameIdx{i} = frameIdx;
                obj.fileTable.frameTime{i} = frameTime;
            end

            obj.fileTable.frameInfo = cellfun(@(X, Y)table(X, Y, 'VariableNames', {'frameIdx', 'frameTime'}), obj.fileTable.frameIdx, obj.fileTable.frameTime, 'UniformOutput', false);
            obj.fileTable.frameIdx = [];
            obj.fileTable.frameTime = [];
            obj.fileTable = expendColumn(obj.fileTable, 'frameInfo');
        end

    end

end
