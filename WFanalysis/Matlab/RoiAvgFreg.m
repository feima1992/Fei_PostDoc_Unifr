classdef RoiAvgFreg < handle
    %% Properties
    properties
        fileTableActReg
        maskReg
    end

    %% Methods
    methods
        % Constructor
        function obj = RoiAvgFreg(varargin)
            % parse inputs
            p = inputParser;
            addOptional(p, 'fileTableActReg', FileTableActReg());
            addOptional(p, 'maskReg', MaskReg(26));
            parse(p, varargin{:});

            obj.fileTableActReg = p.Results.fileTableActReg;
            obj.maskReg = p.Results.maskReg;
        end

        % Calculate average deltaF/F for ROI
        function CalAvgF(obj)

            if ~ismember('avgF', obj.fileTableActReg.fileTable.Properties.VariableNames)

                if ~ismember('deltaFoverF', obj.fileTableActReg.fileTable.Properties.VariableNames)
                    obj.fileTableActReg.loadDeltaFoverF();
                end

                obj.fileTableActReg.fileTable = hCombineTable(obj.fileTableActReg.fileTable, obj.maskReg.maskTable);
                RowFunMean = @(X, Y)nanmean(X{1}(Y{1}));
                avgF = rowfun(RowFunMean, obj.fileTableActReg.fileTable, 'InputVariables', {'deltaFoverF', 'maskTable'}, 'OutputVariableName', {'avgF'});
                obj.fileTableActReg.fileTable = [obj.fileTableActReg.fileTable, avgF];
            else 
                fprintf('   Roi averaged deltaF/F already calculated.\n');
            end

        end

    end

end
