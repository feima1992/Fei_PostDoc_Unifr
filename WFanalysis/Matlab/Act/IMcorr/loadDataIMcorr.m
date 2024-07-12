function fileTable = loadDataIMcorr(fileTable, varargin)

    for i = 1:height(fileTable)
        % load IMcorr
        fileTable.IMcorr{i} = loadIMcorrHelper(fileTable.path{i}, varargin{:});
        % show progress i of height(fileTable)
        fprintf('   Loading IMcorr: %d of %d\n', i, height(fileTable));
    end

end

function result = loadIMcorrHelper(filePath, varargin)
    % validate input
    p = inputParser;
    p.addRequired('filePath', @(x) ischar(x) || isstring(x));
    p.addParameter('gaussFilterSigma', 2, @(x) isnumeric(x) && isscalar(x));
    p.addParameter('imMaskSource', 'external', @(x) ischar(x) && ismember(x, {'external', 'internal', 'draw'}));
    p.addParameter('loadIMcorrType', 'IMcorr', @(x) ischar(x) && ismember(x, {'IMcorr', 'IMcorrREG'}));
    p.parse(filePath, varargin{:});
    options = p.Results;

    % load IMcorr and imMask
    varNames = {whos('-file', filePath).name};
    % load IMcorr
    load(filePath, options.loadIMcorrType);

    % load Mask
    switch options.imMaskSource
        case 'external'
            imMask = load('imMask.mat');
            imMask = imMask.imMask;
        case 'internal'

            if ismember('imMask', varNames)
                load(filePath, 'imMask');
            elseif ismember('imMaskREG', varNames)
                load(filePath, 'imMaskREG');
                imMask = imMaskREG;
            end

        case 'draw'
            mouse = regexp(filePath, '[a-zA-Z]\d{4}(?=_)', 'match', 'once');
            session = regexp(filePath, '(?<=_)(20){0,1}2[3-9][0-1][0-9][0-3][0-9](?=_)', 'match', 'once');
            imREF = imread(fullfile(Param().dir.refImage, [mouse, '_', session, '_REF.tif']));
            imREF = imREF(end:-1:1, end:-1:1);

            if contains(mouse, '237')
                imREF = imread(fullfile(Param().dir.refImage, [mouse, '_', session, '_REF.jpg']));
            end

            f0 = figure();
            imshow(imadjust(imREF));
            hF = drawpolygon();
            imMask = createMask(hF);
            close(f0);
            save(filePath, 'imMask', '-append');
            load(filePath, options.loadIMcorrType);
    end

    % load t from params
    t = Param().wfAlign.frameTime;

    % apply Gaussian filter to IMcorr if gaussFilterSigma is not 0
    if options.gaussFilterSigma == 0
        result = Frames_IMcorr(eval(options.loadIMcorrType), t).ApplyMask(imMask).frameData;
    else
        result = Frames_IMcorr(eval(options.loadIMcorrType), t).ApplyGaussLowPass(options.gaussFilterSigma).ApplyMask(imMask).frameData;
    end

end
