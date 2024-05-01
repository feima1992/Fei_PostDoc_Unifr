classdef FileTable_Bpod_LimbMvtOpto < FileTable_Bpod

    %% Methods
    methods
        %% Constructor
        function obj = FileTable_Bpod_LimbMvtOpto(varargin)
            % Call superclass constructor
            obj = obj@FileTable_Bpod(varargin{:});
            % Filter Row by stimulus type
            obj.Filter('stimulusType','LimbMvtTriggerWFopto');
        end
        %% Load file
        function obj = LoadFile(obj)
            LoadFile@FileTable_Bpod(obj)
            obj.fileTable = loadDataBpodLimbMvtOpto(obj.fileTable);
            obj.fileTable = expendColumn(obj.fileTable, 'data');
        end
        
        %% Export csv
        function obj = ExportCsv(obj)
        
        % Load file if not already done
        if ~isfield(obj.fileTable, 'lazerOn')
            obj.LoadFile();
        end
        % Get current date as postfix
        datePostfix = datestr(now,'yyyymmdd');
        fileName = ['Bpod_LimbMvtOpto_' datePostfix '.csv'];
        filePath = fullfile(Param().folderFigure, fileName);
        % Save to csv by calling superclass method
        ExportCsv@FileTable_Bpod(obj, filePath);
        % Display message
        disp(['File saved as ' filePath]);
        end
    end
end