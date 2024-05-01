classdef FileTable_BpodWF < matlab.mixin.Copyable

    %% Properties
    properties
        objBpod
        objWf
        fileTable
    end
    
    %% Methods
    methods
        %% Constructor
        function obj = FileTable_BpodWF(objBpod, objWf)
            % Check if the input is a FileTable
            if ~isa(objBpod, 'FileTable_Bpod')
                error('Input objBpod must be a FileTable_Bpod object');
            end
            if ~isa(objWf, 'FileTable_Tif_Wf_SingleCell')
                error('Input objWf must be a FileTable_WF object');
            end

            % Set the properties
            obj.objBpod = objBpod;
            obj.objWf = objWf;

            % Join the two tables based on mouse session and trial number
            obj.fileTable = outerjoin(objWf.fileTable, objBpod.fileTable, 'Keys', {'mouse', 'session', 'trial'}, 'MergeKeys', true, 'Type', 'left');

            % Rename the column names
            

        end
    end

    
end