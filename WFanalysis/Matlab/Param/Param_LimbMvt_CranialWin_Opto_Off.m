classdef Param_LimbMvt_CranialWin_Opto_Off < Param_LimbMvt_CranialWin_Opto
    methods
        function obj = Param_LimbMvt_CranialWin_Opto_Off(varargin)
            obj = obj@Param_LimbMvt_CranialWin_Opto(varargin{:});
            obj.select.trial.optoLazerOn = 0;
            obj.select.trial.pawHoldGood = [0,1];

        end
    end
end