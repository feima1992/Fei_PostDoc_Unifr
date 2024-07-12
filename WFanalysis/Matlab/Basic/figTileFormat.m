function figTileFormat(varargin)
    %% Axes

    axs = findobj('type', 'axes');

    if ~isempty(axs)
        % Font
        set(axs, 'FontName', 'Arial', 'FontWeight', 'normal', 'FontSize', 12, ...
            'LabelFontSizeMultiplier', 1, ...
            'TitleFontSizeMultiplier', 1.17, 'TitleFontWeight', 'normal', ...
            'LineWidth', 1.5, 'Box', 'off');
    end

    disp('...Format figur Done...')
end