function [fitStats, figH] = fitGaussOut(trigData, cNum, plotFlag)

    if nargin < 3
        plotFlag = 0;
    end

    x=(-180:45:180)';
    dirAng = 0:45:360-45;
    % Set up fittype and options.
    ft = fittype( 'gauss1' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    opts.Lower = [-Inf -Inf 0];
    opts.StartPoint = [1 0 60];

    NrepsThr = 5;

    y=trigData.Stats{cNum,1}(:,1);
    idxNan = trigData.Stats{cNum,1}(:,3) < NrepsThr;
    y(idxNan) = nan;
    [~,idxOUT] = max(y);
    y=circshift(y,5-idxOUT);
    y=[y;y(1)];

    % if min(y)<0
    %     y=y-min(y);
    % end

    [xData, yData] = prepareCurveData( x, y );
    % Fit model to data.
    try
        [fitresultOUT, gofOUT] = fit( xData, yData, ft, opts );
        CIs=confint(fitresultOUT);
        badFitOUT = any(CIs(1,[1 3])<0 & CIs(2,[1 3])>0);
        fitresultOUT.b1 = fitresultOUT.b1+dirAng(idxOUT);
        if plotFlag

            % Plot fit with data.
            figH = figure( 'Name', 'Direction tune fits', 'Color', 'w', 'Visible', 'off');
            subplot(121)
            plot( fitresultOUT, xData+dirAng(idxOUT), yData, 'bs-' );
            set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [0.03 0.03])
            subplot(122)
            plot(dirAng, trigData.Stats{cNum,1}(:,1), 'bs-' );
            set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [0.03 0.03])
        end
    catch
        fitresultOUT.b1 = nan;
        fitresultOUT.c1 = nan;
        gofOUT.rsquare = nan;
        badFitOUT = nan;
    end

    [~, prefDirId] = min(abs((fitresultOUT.b1 - dirAng)));
    PDround = dirAng(prefDirId);
    
    w = trigData.Stats{cNum,1}(:,1);
    
    w(w<0) = 0; % incase there are negative values
    circTest = circ_rtest(deg2rad(dirAng)',w);

    fitStats = [fitresultOUT.b1, fitresultOUT.c1, gofOUT.rsquare, badFitOUT, PDround, circTest];
end


