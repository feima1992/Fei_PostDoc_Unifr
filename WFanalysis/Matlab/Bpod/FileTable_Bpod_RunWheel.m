classdef FileTable_Bpod_RunWheel < FileTable_Bpod
    properties
    
    end
    methods
        function obj = FileTable_Bpod_RunWheel()
            obj = obj@FileTable_Bpod('F:\users\Fei\Bpod\', 'm237X');
            
        end
        
        function LoadFile(obj)
            LoadFile@FileTable_Bpod(obj)
            obj.fileTable = loadDataBpodRunWheel(obj.fileTable);
            obj.fileTable = expendColumn(obj.fileTable, 'data');
        end

        function FilterWheelRun(obj)
            wheelRunSatrtEndTimes = cell2mat(obj.fileTable.wheelRunStartEndTimes);
            wheelRunSatrtEndTimes = wheelRunSatrtEndTimes(~isnan(wheelRunSatrtEndTimes(:, 1)), :);
            wheelRunDuration = wheelRunSatrtEndTimes(:, 2) - wheelRunSatrtEndTimes(:, 1);
            % remove outliers of wheelRunDuration with 3 std
            wheelRunDuration = rmoutliers(wheelRunDuration);

        end
    end
end