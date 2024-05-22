function fileTable = loadDataBpodRunWheel(fileTable)
    if ~iscell(fileTable.data)
        fileTable.data = {loadDataBpodRunWheelHelper(fileTable.data.SessionData)};
    else
        fileTable.data = cellfun(@(X)loadDataBpodRunWheelHelper(X.SessionData),fileTable.data,'UniformOutput',false);
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

        if any(ismember(eventList, 'Wire1High')) && any(ismember(eventList, 'Wire1Low'))
            wire1LowTimes = data.RawEvents.Trial{i}.Events.Wire1Low;
            wire1LowTimes = reshape(wire1LowTimes, length(wire1LowTimes), 1);
            wire1HighTimes = data.RawEvents.Trial{i}.Events.Wire1High;
            wire1HighTimes = reshape(wire1HighTimes, length(wire1HighTimes), 1);

            % pair the high and low times together
            if (wire1HighTimes(1) < wire1LowTimes(1)) && (wire1HighTimes(end) > wire1LowTimes(end)) % high starts and high ends
                wire1StartEndTimes = [wire1LowTimes, wire1HighTimes(2:end)];
            elseif (wire1HighTimes(1) > wire1LowTimes(1)) && (wire1HighTimes(end) > wire1LowTimes(end)) % low starts and high ends
                wire1StartEndTimes = [wire1LowTimes, wire1HighTimes];
            elseif (wire1HighTimes(1) < wire1LowTimes(1)) && (wire1HighTimes(end) < wire1LowTimes(end)) % high starts and low ends
                wire1StartEndTimes = [wire1LowTimes(1:end-1), wire1HighTimes(2:end)];
            elseif (wire1HighTimes(1) > wire1LowTimes(1)) && (wire1HighTimes(end) < wire1LowTimes(end)) % low starts and low ends
                wire1StartEndTimes = [wire1LowTimes(1:end-1), wire1HighTimes];
            else
                error('Wire1High and Wire1Low times are not paired correctly')
            end
        else
            wire1StartEndTimes = [nan nan];
        end

        if any(ismember(eventList, 'Wire2High')) && any(ismember(eventList, 'Wire2Low'))
            wire2LowTimes = data.RawEvents.Trial{i}.Events.Wire2Low;
            wire2LowTimes = reshape(wire2LowTimes, length(wire2LowTimes), 1);
            wire2HighTimes = data.RawEvents.Trial{i}.Events.Wire2High;
            wire2HighTimes = reshape(wire2HighTimes, length(wire2HighTimes), 1);

            % pair the high and low times together
            if (wire2HighTimes(1) < wire2LowTimes(1)) && (wire2HighTimes(end) > wire2LowTimes(end)) % high starts and high ends
                wire2StartEndTimes = [wire2LowTimes, wire2HighTimes(2:end)];
            elseif (wire2HighTimes(1) > wire2LowTimes(1)) && (wire2HighTimes(end) > wire2LowTimes(end)) % low starts and high ends
                wire2StartEndTimes = [wire2LowTimes, wire2HighTimes];
            elseif (wire2HighTimes(1) < wire2LowTimes(1)) && (wire2HighTimes(end) < wire2LowTimes(end)) % high starts and low ends
                wire2StartEndTimes = [wire2LowTimes(1:end-1), wire2HighTimes(2:end)];
            elseif (wire2HighTimes(1) > wire2LowTimes(1)) && (wire2HighTimes(end) < wire2LowTimes(end)) % low starts and low ends
                wire2StartEndTimes = [wire2LowTimes(1:end-1), wire2HighTimes];
            else
                error('Wire2High and Wire2Low times are not paired correctly')
            end
        else
            wire2StartEndTimes = [nan nan];
        end

        if any(ismember(eventList, 'BNC1High')) && any(ismember(eventList, 'BNC1Low'))
            bnc1LowTimes = data.RawEvents.Trial{i}.Events.BNC1Low;
            bnc1LowTimes = reshape(bnc1LowTimes, length(bnc1LowTimes), 1);
            bnc1HighTimes = data.RawEvents.Trial{i}.Events.BNC1High;
            bnc1HighTimes = reshape(bnc1HighTimes, length(bnc1HighTimes), 1);

            % pair the high and low times together
            if (bnc1HighTimes(1) < bnc1LowTimes(1)) && (bnc1HighTimes(end) > bnc1LowTimes(end)) % high starts and high ends
                bnc1StartEndTimes = [bnc1LowTimes, bnc1HighTimes(2:end)];
            elseif (bnc1HighTimes(1) > bnc1LowTimes(1)) && (bnc1HighTimes(end) > bnc1LowTimes(end)) % low starts and high ends
                bnc1StartEndTimes = [bnc1LowTimes, bnc1HighTimes];
            elseif (bnc1HighTimes(1) < bnc1LowTimes(1)) && (bnc1HighTimes(end) < bnc1LowTimes(end)) % high starts and low ends
                bnc1StartEndTimes = [bnc1LowTimes(1:end-1), bnc1HighTimes(2:end)];
            elseif (bnc1HighTimes(1) > bnc1LowTimes(1)) && (bnc1HighTimes(end) < bnc1LowTimes(end)) % low starts and low ends
                bnc1StartEndTimes = [bnc1LowTimes(1:end-1), bnc1HighTimes];
            else
                error('BNC1High and BNC1Low times are not paired correctly')
            end
        else
            bnc1StartEndTimes = [nan nan];
        end

        if any(ismember(eventList, 'BNC2High')) && any(ismember(eventList, 'BNC2Low'))
            bnc2LowTimes = data.RawEvents.Trial{i}.Events.BNC2Low;
            bnc2LowTimes = reshape(bnc2LowTimes, length(bnc2LowTimes), 1);
            bnc2HighTimes = data.RawEvents.Trial{i}.Events.BNC2High;
            bnc2HighTimes = reshape(bnc2HighTimes, length(bnc2HighTimes), 1);

            % pair the high and low times together
            if (bnc2HighTimes(1) < bnc2LowTimes(1)) && (bnc2HighTimes(end) > bnc2LowTimes(end)) % high starts and high ends
                bnc2StartEndTimes = [bnc2LowTimes, bnc2HighTimes(2:end)];
            elseif (bnc2HighTimes(1) > bnc2LowTimes(1)) && (bnc2HighTimes(end) > bnc2LowTimes(end)) % low starts and high ends
                bnc2StartEndTimes = [bnc2LowTimes, bnc2HighTimes];
            elseif (bnc2HighTimes(1) < bnc2LowTimes(1)) && (bnc2HighTimes(end) < bnc2LowTimes(end)) % high starts and low ends
                bnc2StartEndTimes = [bnc2LowTimes(1:end-1), bnc2HighTimes(2:end)];
            elseif (bnc2HighTimes(1) > bnc2LowTimes(1)) && (bnc2HighTimes(end) < bnc2LowTimes(end)) % low starts and low ends
                bnc2StartEndTimes = [bnc2LowTimes(1:end-1), bnc2HighTimes];
            else
                error('BNC2High and BNC2Low times are not paired correctly')
            end
        else
            bnc2StartEndTimes = [nan nan];
        end

        trialInfo{i, 3} = [wire1StartEndTimes; wire2StartEndTimes; bnc1StartEndTimes; bnc2StartEndTimes];
        
    end
    trialInfo = cell2table(trialInfo, 'VariableNames', {'trialID', 'ropePullNum', 'wheelRunStartEndTimes'});
end
