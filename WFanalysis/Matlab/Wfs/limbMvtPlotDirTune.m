function figH = limbMvtPlotDirTune(trigData, cellNum)

plotMap = [6 3 2 1 4 7 8 9];
angles = [0:pi/4:2*pi-pi/4]';

UpLim = [];
LoLim = [];

figH = figure('Color', 'w', 'Position', [100 400 560 420]);
for dir=1:8
    subplot(3,3,plotMap(dir))

    idx = (trigData.Info(:,4)==dir & (trigData.Info(:,3)==5 | trigData.Info(:,3)==4 | trigData.Info(:,3)==3)...
        & trigData.Info(:,2)==1);   % outward mvt
    if sum(idx)>0
        plot(trigData.periTime,trigData.Traces{cellNum,1}(idx,:), 'Color', [0.7 0.7 0.7], 'LineWidth', 1)
        hold on
        plot(trigData.periTime,mean(trigData.Traces{cellNum,1}(idx,:)), 'Color', [1 0 0], 'LineWidth', 3.5)
        plot(trigData.periTime,mean(trigData.Traces{cellNum,1}(idx,:))+std(trigData.Traces{cellNum,1}(idx,:)), 'Color', [1 0 0], 'LineWidth', 0.5, 'LineStyle', '--')
        plot(trigData.periTime,mean(trigData.Traces{cellNum,1}(idx,:))-std(trigData.Traces{cellNum,1}(idx,:)), 'Color', [1 0 0], 'LineWidth', 0.5, 'LineStyle', '--')
        % add vertical line at time 0
        xline(0, 'Color', 'k', 'LineWidth', 0.5, 'LineStyle', ':')
        hold off
    end
    set(gca, 'Box', 'off', 'TickDir', 'out', 'XLim', [-trigData.Tpre trigData.Tpost], 'XTick', -trigData.Tpre:trigData.Tpost, 'TickLength', [0.03 0.03])
    switch dir
        case 3
            title('Outward movements', 'FontSize', 14, 'FontWeight', 'bold')
        case 5
            ylabel('df/f', 'FontSize', 14, 'FontWeight', 'bold')
        case 7
            xlabel('Time (s)', 'FontSize', 14, 'FontWeight', 'bold')
    end
    if sum(idx)>0
        UpLim = [UpLim max(max(trigData.Traces{cellNum,1}(idx,:)))];
        LoLim = [LoLim min(min(trigData.Traces{cellNum,1}(idx,:)))];
    end
    
end

[X,Y] = pol2cart(angles,trigData.Stats{cellNum,1}(:,1));
X = [X;X(1)];
Y = [Y;Y(1)];

subplot(3,3,5)
plot(X,Y,'o-k', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'none', 'MarkerSize', 4, 'LineWidth', 1)
line([-max(abs([X;Y]))-0.05 max(abs([X;Y]))+0.05], [0 0], 'LineStyle', ':', 'LineWidth', 0.5, 'Color', 'k')
line([0 0], [-max(abs([X;Y]))-0.05 max(abs([X;Y]))+0.05], 'LineStyle', ':', 'LineWidth', 0.5, 'Color', 'k')
line([-max(abs([X;Y]))-0.05 max(abs([X;Y]))+0.05], [-max(abs([X;Y]))-0.05 max(abs([X;Y]))+0.05], 'LineStyle', ':', 'LineWidth', 0.5, 'Color', 'k')
line([-max(abs([X;Y]))-0.05 max(abs([X;Y]))+0.05], [max(abs([X;Y]))+0.05 -max(abs([X;Y]))-0.05], 'LineStyle', ':', 'LineWidth', 0.5, 'Color', 'k')

axis equal 
set(gca, 'Box', 'off', 'TickDir', 'out', 'XLim', [-max(abs([X;Y]))-0.05 max(abs([X;Y]))+0.05], 'YLim', [-max(abs([X;Y]))-0.05 max(abs([X;Y]))+0.05], 'TickLength', [0.03 0.03])

end