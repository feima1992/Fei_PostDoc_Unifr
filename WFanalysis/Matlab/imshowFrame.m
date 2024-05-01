function im = imshowFrame(frameData, options)
    % parse inputs
    arguments
        frameData (:,:) {mustBeNumeric}
        options.plot (1,1) {mustBeNumericOrLogical} = true
        options.ax = gca
        options.cmap = fire(256)
        options.title {mustBeTextScalar} = ''
        options.abmTemplate (1,1) {mustBeNumericOrLogical} = true
    end

    % plot the frame
    im = ind2rgb(im2uint8(rescale(frameData)), options.cmap);

    % plot the image if requested
    if options.plot
        imshow(im,[]);
        
        axis(options.ax, 'image');
        axis(options.ax, 'off');

        if ~isempty(options.title)
            title(options.ax, options.title);
        end

        if options.abmTemplate
            plotABMtemplate(options.ax, 'w');
        end
    end
end