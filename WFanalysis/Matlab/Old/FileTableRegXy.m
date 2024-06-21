classdef FileTableRegXy < FileTable

    %% Methods
    methods
        %% Constructor
        function obj = FileTableRegXy(varargin)
            if nargin < 1
                varargin{1} = Param().dir.regXy;
            end
            % Call superclass constructor
            obj = obj@FileTable(varargin{:});
            % Filter rows to only include raw data
            obj.Filter('path', @(X)contains(X, 'XYreg.mat'));
            % Load data
            obj.LoadData();
        end

        %% Load the bregmaXy
        function obj = LoadData(obj)
            obj.fileTable = [obj.fileTable, loadDataRegXy(obj.fileTable.path)];
            obj.CleanVar({'path', 'folder', 'namefull'}, 'remove');
        end

    end

end
