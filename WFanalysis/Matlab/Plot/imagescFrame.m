function imagescFrame(frameData, options)
    % parse inputs
    arguments
        frameData (:,:) {mustBeNumeric}
        options.ax = gca
        options.cmap = polarmap
        options.clim (1,2) {mustBeNumeric} = max(abs([min(frameData(:)), max(frameData(:))])) * [-1, 1]
        options.title {mustBeTextScalar} = ''
        options.colorbar (1,1) {mustBeNumericOrLogical} = true
        options.colorbarLabel {mustBeTextScalar} = '\DeltaF/F'
        options.abmTemplate (1,1) {mustBeNumericOrLogical} = true
    end
    % if frameData if all NaNs, then just plot a blank image
    if all(frameData(:) == 0) || all(isnan(frameData(:)))
        frameData = zeros(size(frameData));
        options.clim = [-1, 1];
    end
    % plot the frame
    im = imagesc(options.ax, frameData, options.clim);
    set(im, 'AlphaData', ~isnan(frameData));
    colormap(options.ax, options.cmap);
    axis(options.ax, 'image');
    axis(options.ax, 'off');

    if ~isempty(options.title)
        title(options.ax, options.title);
    end

    if options.colorbar
        cBar = colorbar(options.ax, 'Location', 'eastoutside');
        cBar.Label.String = options.colorbarLabel;
    end

    if options.abmTemplate
        plotABMtemplate(options.ax);
    end

end
