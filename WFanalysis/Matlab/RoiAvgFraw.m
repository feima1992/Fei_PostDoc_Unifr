classdef RoiAvgFraw < handle
    %% Properties
    properties
        actFile
        rawMask
    end

    %% Methods
    methods
        % Constructor
        function obj = RoiAvgFraw(varargin)
            % parse inputs
            p = inputParser;
            addOptional(p, 'actFile', {});
            addOptional(p, 'rawMask',[]);
            parse(p, varargin{:});

            actFileParam = p.Results.actFile;
            rawMaskParam = p.Results.rawMask;

            obj.actFile = FileTableActRaw(actFileParam{:});
            if isempty(rawMaskParam)
                obj.rawMask = MaskRaw();
            else
                obj.rawMask = MaskRaw(rawMaskParam);
            end
        end

        % Calculate average deltaF/F for ROI
        function CalAvgF(obj)

            if ~ismember('avgF', obj.actFile.fileTable.Properties.VariableNames)

                if ~ismember('deltaFoverF', obj.actFile.fileTable.Properties.VariableNames)
                    obj.actFile.loadDeltaFoverF();
                end

                obj.actFile.fileTable = innerjoin(obj.actFile.fileTable,obj.rawMask.maskTable,  'Keys', {'mouse', 'session'});
                RowFunMean = @(X, Y)nanmean(X{1}(Y{1}));
                avgF = rowfun(RowFunMean, obj.actFile.fileTable, 'InputVariables', {'deltaFoverF', 'maskTable'}, 'OutputVariableName', {'avgF'});
                obj.actFile.fileTable = [obj.actFile.fileTable, avgF];
            else 
                fprintf('   Roi averaged deltaF/F already calculated.\n');
            end

        end

    end

end