function figH = limbVibPlotResponses(trigData, cellNum, ax)
    if nargin < 3
        figH = gcf;
        ax = gca;
    else
        figH = ax.Parent;
    end
    axes(ax)
    plot(trigData.periTime, trigData.Traces{cellNum, 1}, 'Color', [0.7 0.7 0.7], 'LineWidth', 1)
    hold on
    plot(trigData.periTime, mean(trigData.Traces{cellNum, 1}), 'Color', [1 0 0], 'LineWidth', 3.5)
    plot(trigData.periTime, mean(trigData.Traces{cellNum, 1}) + std(trigData.Traces{cellNum, 1}), 'Color', [1 0 0], 'LineWidth', 0.5, 'LineStyle', '--')
    plot(trigData.periTime, mean(trigData.Traces{cellNum, 1}) - std(trigData.Traces{cellNum, 1}), 'Color', [1 0 0], 'LineWidth', 0.5, 'LineStyle', '--')
    % add vertical line at time 0
    xline(0, 'Color', 'k', 'LineWidth', 0.5, 'LineStyle', ':')
    hold off
    set(gca, 'Box', 'off', 'TickDir', 'out', 'XLim', [-trigData.Tpre trigData.Tpost], 'XTick', -trigData.Tpre:trigData.Tpost, 'TickLength', [0.03 0.03])
    ylabel('df/f', 'FontSize', 14, 'FontWeight', 'bold')
    xlabel('Time (s)', 'FontSize', 14, 'FontWeight', 'bold')
end
