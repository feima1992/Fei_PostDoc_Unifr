classdef FileTable_Bpod_LimbVib < FileTable_Bpod

    %% Methods
    methods
        %% Constructor
        function obj = FileTable_Bpod_LimbVib(varargin)
            % Call superclass constructor
            obj = obj@FileTable_Bpod(varargin{:});
            % Filter Row by stimulus type
            obj.Filter('stimulusType','LimbTouchStimWF');
        end
        %% Load file
        function obj = LoadFile(obj)
            LoadFile@FileTable_Bpod(obj)
            obj.fileTable = loadDataBpodLimbVib(obj.fileTable);
            obj.fileTable = expendColumn(obj.fileTable, 'data');
        end
    end
end