classdef FileTable_Bpod_LimbMvt < FileTable_Bpod

    %% Methods
    methods
        %% Constructor
        function obj = FileTable_Bpod_LimbMvt(varargin)
            % Call superclass constructor
            obj = obj@FileTable_Bpod(varargin{:});
            % Filter Row by stimulus type
            obj.Filter('stimulusType','LimbMvtTriggerWF');
        end
        %% Load file
        function LoadFile(obj)
            LoadFile@FileTable_Bpod(obj)
            obj.fileTable = loadDataBpodLimbMvt(obj.fileTable);
            obj.fileTable = expendColumn(obj.fileTable, 'data');
        end
    end
end