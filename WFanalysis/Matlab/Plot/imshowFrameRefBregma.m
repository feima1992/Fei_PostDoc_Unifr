function imshowFrameRefBregma(frameData, options)

    arguments
        frameData double
        options.title = ''
        options.showUeno (1, 1) logical = true
    end

    pix2mm_X = 18;
    h = imshow(frameData, [], 'Colormap', fire(256));
    set(h, 'AlphaData', frameData > 0)
    set(gca, ...
        'Visible', 'on', ...
        'Box', 'off', ...
        'TickDir', 'out', ...
        'XTick', 256 - (4000:-500:0) / pix2mm_X, ...
        'XTickLabel', -4:0.5:0, ...
        'YTick', 256 + (-3000:500:3000) / pix2mm_X, ...
        'YTickLabel', 3:-0.5:-3, ...
        'XLim', 256 - [4000 -500] / pix2mm_X, ...
        'YLim', 256 + [-2000 2000] / pix2mm_X, ...
        'XGrid', 'on', ...
        'YGrid', 'on')
    hold on
    plot(256, 256, 'o', 'MarkerSize', 12, 'MarkerEdgeColor', 'none', 'MarkerFaceColor', 'k')
    hold off
    xlabel('ML(mm)'); ylabel('AP(mm)')
    title(options.title)

    if options.showUeno
        maskUeno = MaskUeno();
        xSensory = maskUeno.coordsSensory(:, 1);
        ySensory = maskUeno.coordsSensory(:, 2);
        ySensory = 512 - ySensory; % flip y-axis
        xMotor = maskUeno.coordsMotor(:, 1);
        yMotor = maskUeno.coordsMotor(:, 2);
        yMotor = 512 - yMotor; % flip y-axis
        hold on
        plot(xSensory, ySensory, 'r', 'LineWidth', 1)
        plot(xMotor, yMotor, 'b', 'LineWidth', 1)
    end

end
