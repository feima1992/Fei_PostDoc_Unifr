classdef FileTable_Bpod_RunWheel < FileTable_Bpod
    properties
    
    end
    methods
        function obj = FileTable_Bpod_RunWheel()
            obj = obj@FileTable_Bpod('Z:\users\Fei\Bpod\', 'm237X');
            obj.LoadFile().Plot();
        end
        
        function obj = LoadFile(obj)
            % load data from mat files
            LoadFile@FileTable_Bpod(obj)
            obj.fileTable = loadDataBpodRunWheel(obj.fileTable);
            obj.fileTable = expendColumn(obj.fileTable, 'data');
            % check and set threshold for wheel run duration
            wheelRunSatrtEndTimes = cell2mat(obj.fileTable.wheelRunStartEndTimes);
            wheelRunDuration = wheelRunSatrtEndTimes(:, 2) - wheelRunSatrtEndTimes(:, 1);
            wheelRunDuration = rmoutliers(wheelRunDuration);
            figure('Color', 'w', 'Name', 'Wheel run duration')
            histogram(wheelRunDuration, 'Normalization', 'probability');
            axis tight;
            xlabel('Time(s)');
            ylabel('Probability');
            title('Time duration of single wheel turn');
            lowThreshold = 0.2; % low threshold is set according to the histogram plot (daul peak distribution)
            highThreshold = max(wheelRunDuration); % high threshold is the max value after removing outliers
            xline(lowThreshold,  'LineStyle', '--', 'LineWidth', 1, 'Color','r');
            % filter out wheel run duration that are too short or too long
            for i = 1:height(obj.fileTable)
                wheelRunStartEndTimes = obj.fileTable.wheelRunStartEndTimes{i};
                if isempty(wheelRunStartEndTimes)
                    continue;
                end
                wheelRunDuration = wheelRunStartEndTimes(:, 2) - wheelRunStartEndTimes(:, 1);
                idx = (wheelRunDuration >= lowThreshold & wheelRunDuration <= highThreshold);
                obj.fileTable.wheelRunStartEndTimes{i} = wheelRunStartEndTimes(idx, :);
                obj.fileTable.wheelRunDuration{i} = wheelRunDuration(idx);
                obj.fileTable.wheelRunTurns{i} = sum(idx);
            end
        end

        function obj = Plot(obj)
            % plot the number of wheel turns for each session
            [gIdx, gTable] = findgroups(obj.fileTable(:, {'mouse', 'session'}));

            for i = 1:height(gTable)
                sessionData = obj.fileTable(gIdx == i, :);
                trialNum = height(sessionData);
                ropePullNum = sum(sessionData.ropePullNum);
                wheelRunTurnNum = sum(cell2mat(sessionData.wheelRunTurns));
                wheelRunDist = wheelRunTurnNum * pi * 13 / 100000; % 13cm is the diameter of the wheel, convert to km
                wheelRunDuration = sum(cell2mat(sessionData.wheelRunDuration))/(60*60); % convert to hours
                wheelRunSpeed = wheelRunDist / wheelRunDuration; % km/h

                gTable.trialNum{i} = trialNum;
                gTable.ropePullNum{i} = ropePullNum;
                gTable.wheelRunDist{i} = wheelRunDist;
                gTable.wheelRunDuration{i} = wheelRunDuration;
                gTable.wheelRunSpeed{i} = wheelRunSpeed;
            end
            % remove sessions that have no wheel turns
            gTable(cell2mat(gTable.wheelRunDist) == 0, :) = [];
            % remove the first 5 sessions where the hardware was not working properly yet
            gTable(1:4, :) = []; 
            gTable(end, :) = [];

            % export the table to csv
            writetable(gTable, 'wheelRunAnalysis.csv', 'WriteVariableNames', true);

            
            nDays = height(gTable) + 4*2; % 4 weeks of weekends
            nMouse = 5;
            avgRopePullNum = sum(cell2mat(gTable.ropePullNum)) / nDays / nMouse;
            avgWheelRunDist = sum(cell2mat(gTable.wheelRunDist)) / nDays / nMouse;
            avgWheelRunDuration = sum(cell2mat(gTable.wheelRunDuration)) / nDays / nMouse;
            avgWheelRunSpeed = mean(cell2mat(gTable.wheelRunSpeed));
            
            % plot results
            figure('Color', 'w', 'Name', 'Wheel run analysis');
            
            subplot(2, 2, 1);
            plot(1:height(gTable), cell2mat(gTable.ropePullNum), 'o-');
            xticks(1:height(gTable));
            xticklabels(gTable.session);
            xtickangle(45);
            xlabel('Session');
            ylabel('Number of rope pulls');
            title(sprintf('Rope pull = %.2f (per mouse, per day)', avgRopePullNum));
            
            subplot(2, 2, 2);
            plot(1:height(gTable), cell2mat(gTable.wheelRunDuration), 'o-');
            xticks(1:height(gTable));
            xticklabels(gTable.session);
            xtickangle(45);
            xlabel('Session');
            ylabel('Duration (h)');
            title(sprintf('Duration = %.2fh (per mouse, per day)', avgWheelRunDuration));

            subplot(2, 2, 3);
            plot(1:height(gTable), cell2mat(gTable.wheelRunDist), 'o-');
            xticks(1:height(gTable));
            xticklabels(gTable.session);
            xtickangle(45);
            xlabel('Session');
            ylabel('Distance (km)');
            title(sprintf('Distance = %.2fkm (per mouse, per day)', avgWheelRunDist));

            subplot(2, 2, 4);
            plot(1:height(gTable), cell2mat(gTable.wheelRunSpeed), 'o-');
            xticks(1:height(gTable));
            xticklabels(gTable.session);
            xtickangle(45);
            xlabel('Session');
            ylabel('Speed (km/h)');
            title(sprintf('Speed = %.2fkm/h', avgWheelRunSpeed));
            ylim([0, gca().YLim(2)]);

        end
    end
end