function figResize(R, C)
    % resize figure to R rows and C columns
    % R,C must be positive integers

    arguments
        R (1, 1) {mustBePositive, mustBeInteger}
        C (1, 1) {mustBePositive, mustBeInteger}
    end

    Units = 'inches';

    switch R
        case 1
            height = 3.8;
        case 2
            height = 7.6;
        case 3
            height = 11.4;
        otherwise
            warning('Too many rows, better to separate into multiple pages')
    end

    switch C
        case 1
            width = 3.9;
        case 2
            width = 7.8;
        otherwise
            warning('Too many columns, better to separate into multiple pages')
    end

    set(gcf, 'Units', Units, 'Position', [0 0 width height])
end
