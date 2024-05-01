classdef Param_WhiskerMagnet < Param
    methods
        function obj = Param_WhiskerMagnet(varargin)
            obj = obj@Param(varargin{:});
            obj.CreatDir();
            obj.wfAlign.alignWin = [-1, 1]; % window for alignment, relative to the trigger onset
            obj.wfAlign.frameTime = obj.wfAlign.alignWin(1):1 / obj.wfAlign.frameRate:obj.wfAlign.alignWin(2); % time line of the aligned WF video
        end
       
    end
end