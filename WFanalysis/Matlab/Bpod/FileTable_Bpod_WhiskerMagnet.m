classdef FileTable_Bpod_WhiskerMagnet < FileTable_Bpod

    %% Methods
    methods
        %% Constructor
        function obj = FileTable_Bpod_WhiskerMagnet(varargin)
            % Call superclass constructor
            obj = obj@FileTable_Bpod(varargin{:});
            % Filter Row by stimulus type
            obj.Filter('stimulusType','WhiskerMagnetWF');
        end
        %% Load file
        function LoadFile(obj)
            LoadFile@FileTable_Bpod(obj)
            obj.fileTable = loadDataBpodWhiskerMagnet(obj.fileTable);
            obj.fileTable = expendColumn(obj.fileTable, 'data');
        end
    end
end