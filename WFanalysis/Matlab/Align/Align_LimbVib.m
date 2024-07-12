classdef Align_LimbVib < Align
    %% Methods
    methods
        %% Constructor
        function obj = Align_LimbVib(param, wfTable, bpodTable)
            obj = obj@Align(param, wfTable, bpodTable);
            obj.SelectTrial();
            obj.AlignWfBpod();
        end

        %% Function SelectTrial
        function SelectTrial(obj)
            % select the mouse
            if isfield(obj.param.select, 'mouse') && ~isempty(obj.param.select.mouse)
                obj.wfBpodTable = filterRow(obj.wfBpodTable, 'mouse', obj.param.select.mouse);
            end

            % select the session
            if isfield(obj.param.select, 'session') && ~isempty(obj.param.select.session)
                obj.wfBpodTable = filterRow(obj.wfBpodTable, 'session', obj.param.select.session);
            end

            % select the trial by outcome
            if isfield(obj.param.select, 'trial') && isfield(obj.param.select.trial, 'outcome') && ~isempty(obj.param.select.trial.outcome)
                obj.wfBpodTable = filterRow(obj.wfBpodTable, 'outcomeIdx', obj.param.select.trial.outcome);
            end

        end

    end

end
