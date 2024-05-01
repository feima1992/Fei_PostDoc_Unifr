classdef Param_LimbMvt_CranialWin_Opto < Param_LimbMvt_CranialWin
    methods
        function obj = Param_LimbMvt_CranialWin_Opto (varargin)
            obj = obj@Param_LimbMvt_CranialWin(varargin{:});
            obj.select.trial.pawHoldGood = 1;
        end
    end
end