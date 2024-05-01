classdef Param_LimbVib < Param
    methods
        function obj = Param_LimbVib(varargin)
            obj = obj@Param(varargin{:});
            obj.CreatDir();
            obj.select.trial.outcome = 3;
        end
       
    end
end