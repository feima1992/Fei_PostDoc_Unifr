classdef Param_LimbMvt_CranialWin_Opto_On < Param_LimbMvt_CranialWin_Opto
    methods
        function obj = Param_LimbMvt_CranialWin_Opto_On(varargin)
            obj = obj@Param_LimbMvt_CranialWin_Opto(varargin{:});
            obj.select.trial.optoLazerOn = 1;
            obj.select.trial.pawHoldGood = [0,1];
        end
    end
end