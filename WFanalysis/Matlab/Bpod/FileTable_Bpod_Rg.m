classdef FileTable_Bpod_Rg < FileTable_Bpod

    %% Methods
    methods
        %% Constructor
        function obj = FileTable_Bpod_Rg(varargin)
            % Call superclass constructor
            obj = obj@FileTable_Bpod(varargin{:});
            % Filter Row by stimulus type
            obj.Filter('stimulusType','LimbReachGrasp');
        end
        %% Load file
        function LoadFile(obj)
            LoadFile@FileTable_Bpod(obj);
            obj.fileTable = loadDataBpodRg(obj.fileTable);
            obj.fileTable = expendColumn(obj.fileTable, 'data');
        end
    end
end