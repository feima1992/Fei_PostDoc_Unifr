function fileTable = loadDataBpodLimbMvtOpto(fileTable)
    fileTable.data = cellfun(@(X)loadDataBpodLimbMvtHelperOpto(X.SessionData),fileTable.data,'UniformOutput',false);
end

function trialInfo = loadDataBpodLimbMvtHelperOpto(data)
    trialInfo = cell(data.nTrials, 8); % 1st mvt time, 2nd mvt time, trial outcome, trial outcome idx, mvt direction, lazerOn, pawHoldGood
    % get trial IDs
    trialInfo(:, 1) = num2cell(1:data.nTrials);
    % get 1st and 2nd movement times relative to camera trigger
    tTriggerCAMLED = cellfun(@(X)X.States.TriggerCAMLED(1, 1), data.RawEvents.Trial, 'UniformOutput', true);
    tMoveHomeTarget = cellfun(@(X)X.States.MoveOut(1, 1), data.RawEvents.Trial, 'UniformOutput', true);
    tMoveTargetHome = cellfun(@(X)X.States.MoveHome(1, 1), data.RawEvents.Trial, 'UniformOutput', true);
    trialInfo(:, 2) = num2cell(tMoveHomeTarget - tTriggerCAMLED);
    trialInfo(:, 3) = num2cell(tMoveTargetHome - tTriggerCAMLED);
    % get trial outcomes
    trialInfo(:, 4) = data.trialOutcomes.Outcome(1:data.nTrials);
    [idx, ~] = find(data.trialOutcomes.OutcomeIdx');
    trialInfo(:, 5) = num2cell(idx);
    % get movement direction
    trialInfo(:, 6) = num2cell(data.PosTrigTrialHist(1:data.nTrials, 1));
    % get trial duration
    tFinalState = cellfun(@(X)X.States.FinalState(1, 1), data.RawEvents.Trial, 'UniformOutput', true);
    trialInfo(:, 7) = num2cell(tFinalState - tTriggerCAMLED);
    % lazer status
    lazerOn = cellfun(@(X)X.OptoStimCurrentTrial, {data.TrialSettings.GUI}, 'UniformOutput', true);
    trialInfo(:, 8) = num2cell(lazerOn);
    % pre assign pawHoldGood with NaN
    trialInfo(:, 9) = num2cell(zeros(data.nTrials, 1));
    % table of output
    trialInfo = cell2table(trialInfo, 'VariableNames', {'trial', 't1stMvt', 't2ndMvt', 'outcome', 'outcomeIdx', 'mvtDir', 'duration', 'lazerOn', 'pawHoldGood'});
    % add pawJitter detection results
    try % if hold signal is recorded
        goodTrials = detectPawJitter(trialInfo(trialInfo.outcomeIdx>=3,:).trial,data);
        trialInfo.pawHoldGood(goodTrials) = 1;
    catch % if hold signal is not recorded
        trialInfo.pawHoldGood = NaN(data.nTrials, 1);
    end
end