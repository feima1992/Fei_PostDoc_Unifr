function fileTable = loadDataBpodWhiskerMagnet(fileTable)
    fileTable.data = cellfun(@(X)loadDataBpodWhiskerMagnetHelper(X.SessionData),fileTable.data,'UniformOutput',false);
end

function trialInfo = loadDataBpodWhiskerMagnetHelper(data)
    trialInfo = cell(data.nTrials, 3); % magnet on time, duration
    % get trial IDs
    trialInfo(:, 1) = num2cell(1:data.nTrials);
    % get tMagnetOn
    tMagnetOn = cellfun(@(X)X.States.MagnetOn(1, 1), data.RawEvents.Trial, 'UniformOutput', true);
    trialInfo(:, 2) = num2cell(tMagnetOn);
    % get duration
    tRewardBeep = cellfun(@(X)X.States.RewardBeep(1, 1), data.RawEvents.Trial, 'UniformOutput', true);
    trialInfo(:, 3) = num2cell(tRewardBeep);
    % table of output
    trialInfo = cell2table(trialInfo, 'VariableNames', {'trial', 'tMagnetOn', 'duration'});
end
