classdef FileTable < matlab.mixin.Copyable
    % FileTable - A table of files and their properties
    % FileTable is a superclass whose subclasses are:
    %   - FileTable_Bpod: A table of Bpod files and their properties
    %   - FileTable_Tif: A table of Tif files and their properties
    
    %% Properties
    properties
        topDir % The top directory to search for files
        fileTable % A table of files and their properties
    end

    %% Method
    methods

        %% Constructor
        function obj = FileTable(topDir, varargin)

            % Set the top directory
            obj.topDir = topDir;
            % Create the file table
            obj.fileTable = findFile(obj.topDir, varargin{:});
            % Filter the file table
            obj.Remove('path', @(X)contains(X, 'Archive') | contains(X, '$RECYCLE'));
            % Clean column, remove the {name, ext, sizeMB} columns
            obj.CleanVar({'name', 'ext', 'sizeMB'}, 'remove');
            % Add the mouse and session names
            AddMouse(obj); AddSession(obj);
        end

        %% Add the mouse name to the fileTable
        function AddMouse(obj)
            % Extract the mouse name from the fileTable.fullName
            obj.fileTable.mouse = findMouse(obj.fileTable.namefull);
        end

        %% Add the session name to the fileTable
        function AddSession(obj)
            % Extract the session name from the fileTable.fullName
            obj.fileTable.session = findSession(obj.fileTable.namefull);
        end

        %% Filter rows of the fileTable
        function obj = Filter(obj, varargin)
            % Filter the fileTable
            obj.fileTable = filterRow(obj.fileTable, varargin{:});
        end

        %% Remove rows of the fileTable
        function obj = Remove(obj, varargin)
            % Remove the rows of the fileTable
            obj.fileTable = removeRow(obj.fileTable, varargin{:});
        end

        %% Remove column of the fileTable
        function obj = CleanVar(obj, varargin)
            % Clean the columns of the fileTable
            obj.fileTable = cleanVar(obj.fileTable, varargin{:});
        end

        %% Export the fileTable to a csv file
        function obj = ExportCsv(obj, csvFile)

            if nargin < 2
                csvFile = fullfile(pwd, 'fileTable.csv');
            end

            % Export the fileTable to a csv file
            writetable(obj.fileTable, csvFile);
        end

    end

end
