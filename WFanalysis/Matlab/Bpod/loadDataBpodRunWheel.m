function fileTable = loadDataBpodRunWheel(fileTable)

    if ~iscell(fileTable.data)
        fileTable.data = {loadDataBpodRunWheelHelper(fileTable.data.SessionData)};
    else
        fileTable.data = cellfun(@(X)loadDataBpodRunWheelHelper(X.SessionData), fileTable.data, 'UniformOutput', false);
    end

end

function trialInfo = loadDataBpodRunWheelHelper(data)
    trialInfo = cell(data.nTrials, 3); % trialID, ropePullNum, wheelRunStartEndTimes
    % get trial IDs
    trialInfo(:, 1) = num2cell(1:data.nTrials);
    % for each trial, get the number of times the rope was pulled and the number of times each wheel ran
    for i = 1:data.nTrials
        eventList = fieldnames(data.RawEvents.Trial{i}.Events);

        if any(ismember(eventList, 'Port1In'))
            ropePull1Num = length(data.RawEvents.Trial{i}.Events.Port1In);
        else
            ropePull1Num = 0;
        end

        if any(ismember(eventList, 'Port2In'))
            ropePull2Num = length(data.RawEvents.Trial{i}.Events.Port2In);
        else
            ropePull2Num = 0;
        end

        if any(ismember(eventList, 'Port3In'))
            ropePull3Num = length(data.RawEvents.Trial{i}.Events.Port3In);
        else
            ropePull3Num = 0;
        end

        trialInfo{i, 2} = sum([ropePull1Num, ropePull2Num, ropePull3Num]);

        wheelRunStartEndTimes = [];

        % wheel 1, Wire1High
        if any(ismember(eventList, 'Wire1High'))
            wire1HighTimes = data.RawEvents.Trial{i}.Events.Wire1High;
            wire1HighTimes = reshape(wire1HighTimes, [], 1);

            if length(wire1HighTimes) > 1
                wheelRunStartEndTimes = [wheelRunStartEndTimes; wire1HighTimes(1:end - 1), wire1HighTimes(2:end)]; %#ok<*AGROW>
            end

        end

        % wheel 2, Wire2High
        if any(ismember(eventList, 'Wire2High'))
            wire2HighTimes = data.RawEvents.Trial{i}.Events.Wire2High;
            wire2HighTimes = reshape(wire2HighTimes, [], 1);

            if length(wire2HighTimes) > 1
                wheelRunStartEndTimes = [wheelRunStartEndTimes; wire2HighTimes(1:end - 1), wire2HighTimes(2:end)];
            end

        end

        % wheel 3, BNC1High
        if any(ismember(eventList, 'BNC1High'))
            BNC1HighTimes = data.RawEvents.Trial{i}.Events.BNC1High;
            BNC1HighTimes = reshape(BNC1HighTimes, [], 1);

            if length(BNC1HighTimes) > 1
                wheelRunStartEndTimes = [wheelRunStartEndTimes; BNC1HighTimes(1:end - 1), BNC1HighTimes(2:end)];
            end

        end

        % wheel 4, BNC2High
        if any(ismember(eventList, 'BNC2High'))
            BNC2HighTimes = data.RawEvents.Trial{i}.Events.BNC2High;
            BNC2HighTimes = reshape(BNC2HighTimes, [], 1);

            if length(BNC2HighTimes) > 1
                wheelRunStartEndTimes = [wheelRunStartEndTimes; BNC2HighTimes(1:end - 1), BNC2HighTimes(2:end)];
            end

        end

        trialInfo{i, 3} = wheelRunStartEndTimes;
    end

    trialInfo = cell2table(trialInfo, 'VariableNames', {'trialID', 'ropePullNum', 'wheelRunStartEndTimes'});
end
