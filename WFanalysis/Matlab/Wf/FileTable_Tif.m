classdef FileTable_Tif < FileTable
    %% Methods
    methods
        %% Constructor
        function obj = FileTable_Tif(topDir, varargin)

            if nargin < 1
                topDir = 'D:\';
            end

            obj = obj@FileTable(topDir, varargin{:});
            obj.Filter('path', @(X)contains(X, '.tif'));
            obj.Remove('path', @(X)contains(X, 'FakeSubject'));
            obj.Remove('path', @(X)contains(X, 'unMatchTrials'));
            obj.AddTrial();
            obj.Remove('trial', @(X)isnan(X))
            obj.MoveToSessionFolder();
            obj.fileTable.path = obj.fileTable.targetPath;
            obj.CleanVar('targetPath');
        end

        %% AddTrial
        function AddTrial(obj)
            % Add trial number to fileTable
            obj.fileTable.trial = findTrial(obj.fileTable.namefull);
        end

    end

    methods (Access = private)
        %% MoveToSessionFolder
        function MoveToSessionFolder(obj)
            fprintf('   Moving tifs to their session folder...\n');
            % Find files that are not in the session folder
            idxNotInSessionFolder = cellfun(@(X, Y) ~contains(X, Y), obj.fileTable.folder, obj.fileTable.session);
            % Generate new folder and target path
            obj.fileTable.folder(idxNotInSessionFolder) = fullfile(obj.fileTable.folder(idxNotInSessionFolder), obj.fileTable.session(idxNotInSessionFolder));
            obj.fileTable.targetPath = fullfile(obj.fileTable.folder, obj.fileTable.namefull);
            % Move files if path is not target path
            idxNotExist = ~cellfun(@(X)exist(X, 'dir'), obj.fileTable.folder);
            folderNotExist = unique(obj.fileTable.folder(idxNotExist));
            cellfun(@(X)mkdir(X), folderNotExist);
            idxNotTargetPath = ~strcmp(obj.fileTable.path, obj.fileTable.targetPath);

            if any(idxNotTargetPath)
                cellfun(@(X, Y)movefile(X, Y), obj.fileTable.path(idxNotTargetPath), obj.fileTable.targetPath(idxNotTargetPath));
            end

        end

    end

end
