classdef Align_LimbMvt < Align
    %% Methods
    methods
        %% Constructor
        function obj = Align_LimbMvt(param, wfTable, bpodTable)
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

            % select the trial by mvtDir
            if isfield(obj.param.select, 'trial') && isfield(obj.param.select.trial, 'mvtDir') && ~isempty(obj.param.select.trial.mvtDir)
                obj.wfBpodTable = filterRow(obj.wfBpodTable, 'mvtDir', obj.param.select.trial.mvtDir);
            end

            % select trial by pawHoldGood
            if isfield(obj.param.select, 'trial') && isfield(obj.param.select.trial, 'pawHoldGood') && ~isempty(obj.param.select.trial.pawHoldGood)
                obj.wfBpodTable = filterRow(obj.wfBpodTable, 'pawHoldGood', obj.param.select.trial.pawHoldGood);
            end

            % select trial by optogenetics lazer on or off
            if isfield(obj.param.select, 'trial') && isfield(obj.param.select.trial, 'optoLazerOn') && ~isempty(obj.param.select.trial.optoLazerOn)
                obj.wfBpodTable = filterRow(obj.wfBpodTable, 'lazerOn', obj.param.select.trial.optoLazerOn);
            end

        end

    end

end
