classdef Param_LimbMvt < Param
    methods
        function obj = Param_LimbMvt(varargin)
            obj = obj@Param(varargin{:});
            obj.CreatDir();
            obj.select.stimId = 1;
            obj.select.trial.outcome = [3, 4, 5];
            obj.select.trial.mvtDir = [0, 1, 2, 3, 4, 5, 6, 7, 8]; % 0 for no movement when vibration stim is on
        end
       
    end
end