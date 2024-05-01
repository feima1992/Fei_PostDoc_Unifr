function imagescMultiFrames(frameCell, options)

    % parse inputs
    arguments
        frameCell (:, 1) cell
        options.cmap = polarmap
        options.clim double = []
        options.autoClim (1, 1) {mustBeNumericOrLogical} = true
        options.title (:, 1) {mustBeText} = repmat({''}, numel(frameCell), 1)
        options.sgtitle {mustBeTextScalar} = ''
        options.colorbar (1, 1) {mustBeNumericOrLogical} = true
        options.colorbarLabel {mustBeTextScalar} = '\DeltaF/F'
        options.abmTemplate (1, 1) {mustBeNumericOrLogical} = true
        options.flow (1, 1) {mustBeNumericOrLogical} = true
    end

    % automatic clim
    if isempty(options.clim)
        if options.autoClim
            options.clim = max(abs([min(cellfun(@(x) min(x(:)), frameCell)), max(cellfun(@(x) max(x(:)), frameCell))])) * [-1, 1];
            options.colorbar = false;
        end
    else
        options.colorbar = false;
    end

    % plot frames
    nFrames = numel(frameCell);
    % if flow, plot use tiledlayout
    if options.flow
        % create tiledlayout
        tiledlayout('flow', 'TileSpacing', 'none', 'Padding', 'none');
        % plot frames
        for iFrame = 1:nFrames
            % show progress as i/total
            fprintf('Plotting frame %d/%d\n', iFrame, nFrames);
            % plot frame
            nexttile;
            imagescFrame(frameCell{iFrame}, ...
                'ax', gca, ...
                'cmap', options.cmap, ...
                'clim', options.clim, ...
                'title', options.title{iFrame}, ...
                'colorbar', options.colorbar, ...
                'abmTemplate', options.abmTemplate);
        end

    else

        if nFrames > 3
            nCols = ceil(sqrt(nFrames));
            nRows = ceil(nFrames / nCols);
        else
            nCols = nFrames;
            nRows = 1;
        end

        for iFrame = 1:nFrames
            % show progress as i/total
            fprintf('Plotting frame %d/%d\n', iFrame, nFrames);
            % plot frame
            subplot(nRows, nCols, iFrame);
            imagescFrame(frameCell{iFrame}, ...
                'ax', gca, ...
                'cmap', options.cmap, ...
                'clim', options.clim, ...
                'title', options.title{iFrame}, ...
                'colorbar', options.colorbar, ...
                'abmTemplate', options.abmTemplate);
        end

    end

    % common colorbar at the right side of the figure
    if options.autoClim

        if options.flow
            c = colorbar;
            c.Layout.Tile = 'east';
            c.Label.String = options.colorbarLabel;
        else
            c = colorbar;
            c.Position = [0.92 0.2 0.01 0.6];
            c.Label.String = options.colorbarLabel;
        end

    end

    % super title
    if ~isempty(options.sgtitle)
        sgtitle(options.sgtitle);
    end
end
