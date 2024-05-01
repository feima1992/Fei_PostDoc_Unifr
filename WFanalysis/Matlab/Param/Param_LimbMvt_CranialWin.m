classdef Param_LimbMvt_CranialWin < Param_LimbMvt
    methods
        function obj = Param_LimbMvt_CranialWin(varargin)
            obj = obj@Param_LimbMvt(varargin{:});
            obj.select.trial.pawHoldGood = 1;
        end
    end
end