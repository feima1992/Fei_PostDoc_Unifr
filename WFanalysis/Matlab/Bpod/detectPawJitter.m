function NoJitterTrNums = detectPawJitter(GoodTrNums, SessionData, plotFlag)

    % set default plotFlag
    if nargin < 3
        plotFlag = 0;
    end

    % Tdelay = 0.028;     % measured delay of motor movement onset
    % CAPdelay = 0.007;   % measured delay of capacitive sensor response

    % to be measured
    Tdelay = 0;
    CAPdelay = 0;

    Tpre = 1;
    Tpost = 1;
    Fs = 1000;
    Npre = Tpre * Fs;
    Npost = Tpost * Fs;
    timePlot = -Tpre:1 / Fs:Tpost;

    Tbase = 1;
    Tana = [0 0.35];
    TanaFilt = [0 1]; % for filtering outliers
    Nana = TanaFilt(2) * 1000;

    indBase = find(timePlot >= -Tbase & timePlot < 0);
    indAna = find(timePlot > Tana(1) & timePlot <= Tana(2));
    indAnaFilt = find(timePlot > TanaFilt(1) & timePlot <= TanaFilt(2));

    TonAll = [];
    trialStats = nan(numel(GoodTrNums), 4); % baseline force, baseline max abs vel, max resp, post stim max abs vel
    sigForce = nan(numel(GoodTrNums), Npre + Npost + 1);
    sigForceDDT = nan(numel(GoodTrNums), Npre + Npost + 1);

    trCnt = 0;

    for trNum = GoodTrNums'
        trCnt = trCnt + 1;

        if ~isempty(SessionData.AIdata.Data{trNum, 1})
            Ton = SessionData.RawEvents.Trial{1, trNum}.States.MoveOut(1) - SessionData.RawEvents.Trial{1, trNum}.States.StartTrial(1) + Tdelay;
            TonAll = [TonAll; Ton];
            [~, indON] = min(abs(Ton + CAPdelay - SessionData.AIdata.Data{trNum, 1}.x));
            Tend = SessionData.AIdata.Data{trNum, 1}.x(end) - SessionData.AIdata.Data{trNum, 1}.x(indON);
            Nsamps = numel(SessionData.AIdata.Data{trNum, 1}.y(1, :));
            sigTrial = SessionData.AIdata.Data{trNum, 1}.y(1, indON - Npre:min([Nsamps indON + Npost]));

            if numel(sigTrial) < Npre + Npost + 1
                sigTrial(numel(sigTrial) + 1:Npre + Npost + 1) = nan;
            end

            sigTrialDDT = ddt(sigTrial, 0.001);

            sigForce(trCnt, 1:numel(sigTrial)) = sigTrial;
            sigForceDDT(trCnt, 1:numel(sigTrial)) = sigTrialDDT;

            trialStats(trCnt, 1) = mean(sigForce(trCnt, indBase)); % baseline force
            trialStats(trCnt, 2) = max(abs(sigForceDDT(trCnt, indBase))); % baseline max abs vel

            if numel(sigTrial) > Npre + Nana
                trialStats(trCnt, 3) = max(sigForce(trCnt, indAna)) - trialStats(trCnt, 1); % max resp
                trialStats(trCnt, 4) = max(abs(sigForceDDT(trCnt, indAnaFilt))); % post stim max abs vel
            end

        end

    end

    baseThr = 999;
    baseVelThr = 15;
    respThr = 999;
    velThr = 40;

    indGood = trialStats(:, 1) < baseThr & trialStats(:, 2) < baseVelThr & trialStats(:, 3) < respThr & trialStats(:, 4) < velThr;

    if plotFlag
        figure('Color', 'w')

        subplot(3, 2, 1)
        hold on
        plot(timePlot, sigForce(indGood, :), 'Color', [1 0.5 0.5])
        plot(timePlot, mean(sigForce(indGood, :)), 'Color', [1 0 0])
        hold off
        set(gca, 'YLim', [-1 11], 'XLim', [-1 1], 'Box', 'off', 'TickDir', 'out', 'TickLength', [0.03 0.03])
        line([0 0], [-1 11], 'LineStyle', '--', 'LineWidth', 1, 'Color', 'k')
        xlabel('Time (s)')
        ylabel('Voltage')

        subplot(3, 2, 5)
        hold on
        plot(timePlot, sigForceDDT(indGood, :), 'Color', [1 0.5 0.5])
        plot(timePlot, mean(sigForceDDT(indGood, :)), 'Color', [1 0 0])
        hold off
        set(gca, 'YLim', [-100 100], 'XLim', [-1 1], 'Box', 'off', 'TickDir', 'out', 'TickLength', [0.03 0.03])
        line([0 0], [-100 100], 'LineStyle', '--', 'LineWidth', 1, 'Color', 'k')
        xlabel('Time (s)')
        ylabel('Voltage/s')

        subplot(3, 2, 3)
        hold on
        plot(timePlot, bsxfun(@minus, sigForce(indGood, :), trialStats(indGood, 1)), 'Color', [1 0.5 0.5])
        plot(timePlot, mean(bsxfun(@minus, sigForce(indGood, :), trialStats(indGood, 1))), 'Color', [1 0 0])
        hold off
        set(gca, 'YLim', [-5 5], 'XLim', [-1 1], 'Box', 'off', 'TickDir', 'out', 'TickLength', [0.03 0.03])
        line([0 0], [-5 5], 'LineStyle', '--', 'LineWidth', 1, 'Color', 'k')
        xlabel('Time (s)')
        ylabel('Voltage')
        title(['N=' num2str(sum(indGood))])

        subplot(3, 2, 2)
        hold on
        plot(timePlot, sigForce(~indGood, :), 'Color', [0.5 0.5 1])
        plot(timePlot, mean(sigForce(~indGood, :)), 'Color', [0 0 1])
        hold off
        set(gca, 'YLim', [-1 11], 'XLim', [-1 1], 'Box', 'off', 'TickDir', 'out', 'TickLength', [0.03 0.03])
        line([0 0], [-1 11], 'LineStyle', '--', 'LineWidth', 1, 'Color', 'k')
        xlabel('Time (s)')
        ylabel('Voltage')

        subplot(3, 2, 4)
        hold on
        plot(timePlot, bsxfun(@minus, sigForce(~indGood, :), trialStats(~indGood, 1)), 'Color', [0.5 0.5 1])
        plot(timePlot, mean(bsxfun(@minus, sigForce(~indGood, :), trialStats(~indGood, 1))), 'Color', [0 0 1])
        hold off
        set(gca, 'YLim', [-5 5], 'XLim', [-1 1], 'Box', 'off', 'TickDir', 'out', 'TickLength', [0.03 0.03])
        line([0 0], [-5 5], 'LineStyle', '--', 'LineWidth', 1, 'Color', 'k')
        xlabel('Time (s)')
        ylabel('Voltage')
        title(['N=' num2str(sum(~indGood))])

        subplot(3, 2, 6)
        hold on
        plot(timePlot, sigForceDDT(~indGood, :), 'Color', [0.5 0.5 1])
        plot(timePlot, mean(sigForceDDT(~indGood, :)), 'Color', [0 0 1])
        hold off
        set(gca, 'YLim', [-100 100], 'XLim', [-1 1], 'Box', 'off', 'TickDir', 'out', 'TickLength', [0.03 0.03])
        line([0 0], [-100 100], 'LineStyle', '--', 'LineWidth', 1, 'Color', 'k')
        xlabel('Time (s)')
        ylabel('Voltage/s')
    end

    NoJitterTrNums = GoodTrNums(indGood);
