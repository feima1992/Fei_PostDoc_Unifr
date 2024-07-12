function fileTable = loadDataBpodLimbVib(fileTable)
    fileTable.data = cellfun(@(X)loadDataBpodLimbVibHelper(X.SessionData), fileTable.data, 'UniformOutput', false);
end

function trialInfo = loadDataBpodLimbVibHelper(data)
    nTrials = data.nTrials;
    trialInfo = cell(nTrials, 8); % stim time, trial outcome, frequency/velocity , amplitude, stim type (1: touch, 2: vib. 3: texture)
    % get trial IDs
    trialInfo(:, 1) = num2cell(1:nTrials);
    % get stim time relative to camera trigger
    tTriggerCAMLED = cellfun(@(X)X.States.TriggerCAMLED(1, 1), data.RawEvents.Trial, 'UniformOutput', true);
    tStimOn = cellfun(@(X)X.States.StimState(1, 1), data.RawEvents.Trial, 'UniformOutput', true);
    trialInfo(:, 2) = num2cell(tStimOn - tTriggerCAMLED);
    % get trial outcomes
    trialInfo(:, 3) = num2cell(data.trialOutcomes.Outcome(1:nTrials));
    [idx, ~] = find(data.trialOutcomes.OutcomeIdx');
    trialInfo(:, 4) = num2cell(idx);
    % get stim type (1: touch, 2: vib. 3: texture)
    trialInfo(:, 5) = num2cell(cellfun(@(X)X.StimType, {data.TrialSettings.GUI}, 'UniformOutput', true));
    % get stim frequency/velocity
    try
        trialInfo(:, 6) = num2cell(cellfun(@(X)X.Stim_Fr, {data.TrialSettings.GUI}, 'UniformOutput', true));
    catch
        trialInfo(:, 6) = num2cell(data.TrialSettings(1:nTrials).GUI.Texture_Vel);
    end

    % get stim amplitude
    trialInfo(:, 7) = num2cell(cellfun(@(X)X.Stim_Amp, {data.TrialSettings.GUI}, 'UniformOutput', true));
    % get trial duration
    tFinalState = cellfun(@(X)X.States.FinalState(1, 1), data.RawEvents.Trial, 'UniformOutput', true);
    trialInfo(:, 8) = num2cell(tFinalState - tTriggerCAMLED);
    % table of output
    trialInfo = cell2table(trialInfo, 'VariableNames', {'trial', 'tStim', 'outcome', 'outcomeIdx', 'stimTypeID', 'stimFreq/Vel', 'stimAmp', 'duration'});
end
