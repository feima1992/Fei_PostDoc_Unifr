classdef FileTable_Bpod < FileTable

    %% Methods
    methods
        %% Constructor
        function obj = FileTable_Bpod(topDir, varargin)
            if nargin < 1
                topDisk = mfilename('fullpath');
                userDir = regexp(topDisk, '.*Fei', 'match', 'once');
                topDir = fullfile(userDir, 'Bpod');
            end
            % Call superclass constructor
            obj = obj@FileTable(topDir,varargin{:});
            % Filter the table to keep only the bpod files
            obj.Filter('path', @(X)contains(X, 'Bpod') & contains(X, '.mat'));
            obj.Remove('path', @(X)contains(X, 'DefaultSettings') | contains(X, 'FakeSubject')| contains(X, 'Protocols'));
            % Add the stimulus type to the table
            AddStimulusType(obj);
            % Remove unsuccessful session files from the table
            RemoveUnsuccessfulSessions(obj);
        end

        %% Add the stimulus type to the table
        function AddStimulusType(obj)
            % Extract the stimulus type from the file name
            obj.fileTable.stimulusType = findStimulusType(obj.fileTable.namefull);
        end

        %% Remove unsuccessful session files from the table
        function RemoveUnsuccessfulSessions(obj)
            % Anonymous function to find the record time
            findRecTimeFun = @(X)str2double(regexp(X, '(?<=_)\d{6}(?=\.mat)', 'match', 'once'));
            if ~iscell(obj.fileTable.namefull)
                obj.fileTable.namefull = {obj.fileTable.namefull};
            end
            obj.fileTable.recTime = cellfun(findRecTimeFun, obj.fileTable.namefull);
            % Group the table by mouse, session and stimulus type and keep only the latest record time for each group
            obj.fileTable = groupfilter(obj.fileTable, {'mouse', 'session', 'stimulusType'}, @(X) X == max(X), 'recTime');
            % Clean column, remove the 'recTime' column
            obj.fileTable = cleanVar(obj.fileTable, 'recTime');
        end

        %% Load files
        function LoadFile(obj)
            % Notify the user that the files are being loaded
            fprintf('   Loading bpod data from %d files\n', height(obj.fileTable));
            tic;
            % Load the files in the fileTable
            if ~iscell(obj.fileTable.path)
                obj.fileTable.data = load(obj.fileTable.path);
            else
                obj.fileTable.data = cellfun(@load, obj.fileTable.path, 'UniformOutput', false);
            end
            % Notify the user that the files have been loaded
            fprintf('   Loading bpod data from %d files took %.1f seconds\n', height(obj.fileTable), toc);
        end

    end

end
