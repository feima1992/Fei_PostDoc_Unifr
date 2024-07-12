classdef Param_LimbMvt_CranialWin_SingleCell < Param_LimbMvt_CranialWin

    methods

        function obj = Param_LimbMvt_CranialWin_SingleCell(varargin)

            obj = obj@Param_LimbMvt_CranialWin(varargin{:});

            %% overwerite frame rate and time
            obj.wfAlign.reUseMask = false;
            obj.wfAlign.alignWin = [-1, 1.5]; % window for alignment, relative to the trigger onset
            obj.wfAlign.frameRate = 15; % frame rate of the WF video
            obj.wfAlign.frameTime = obj.wfAlign.alignWin(1):1 / obj.wfAlign.frameRate:obj.wfAlign.alignWin(2); % time line of the aligned WF video

            %% overwrite pawhold for trial selection
            obj.select.trial.pawHoldGood = [0, 1];
        end

    end

end
