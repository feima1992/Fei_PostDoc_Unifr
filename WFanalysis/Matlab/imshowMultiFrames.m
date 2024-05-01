function imshowMultiFrames(frameCell, options)

    % parse inputs
    arguments
        frameCell (:, 1) cell
        options.cmap = fire(256)
        options.title (:, 1) {mustBeText} = repmat({''}, numel(frameCell), 1)
        options.sgtitle {mustBeTextScalar} = ''
        options.abmTemplate (1, 1) {mustBeNumericOrLogical} = true
        options.flow (1, 1) {mustBeNumericOrLogical} = true
    end

    % plot frames
    nFrames = numel(frameCell);
    % if flow, plot use tiledlayout
    if options.flow
        % create tiledlayout
        tiledlayout('flow', 'TileSpacing', 'compact', 'Padding', 'compact');
        % plot frames
        for iFrame = 1:nFrames
            % show progress as i/total
            % fprintf('Plotting frame %d/%d\n', iFrame, nFrames);
            % plot frame
            nexttile;
            imshowFrame(frameCell{iFrame}, ...
                'ax', gca, ...
                'cmap', options.cmap, ...
                'title', options.title{iFrame}, ...
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
            imshowFrame(frameCell{iFrame}, ...
                'ax', gca, ...
                'cmap', options.cmap, ...
                'title', options.title{iFrame}, ...
                'abmTemplate', options.abmTemplate);
        end

    end

    % super title
    if ~isempty(options.sgtitle)
        sgtitle(options.sgtitle);
    end
end
