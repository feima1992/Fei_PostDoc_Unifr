function filesWfBpod = alignWfBpod(filesWfBpod, P)

    % get session information
    mouse = filesWfBpod.mouse{1};
    session = filesWfBpod.session{1};
    stimType = filesWfBpod.stimulusType{1};
    matSavePath = filesWfBpod.pathActRawMat{1};
    tifSavePath = filesWfBpod.pathActRawTif{1};

    % skip already been processed
    if isfile(matSavePath) && isfile(tifSavePath)
        fprintf('   Skip aligned: %s %s\n', mouse, session)
        return
    end

    % get image width and height
    imAvgInfo = imfinfo(filesWfBpod.path{1});
    imAvgWidth = imAvgInfo(1, 1).Width;
    imAvgHeight = imAvgInfo(1, 1).Height;

    % get image time and number of frames
    imAvgTimeInterval = 1 / P.wfAlign.frameRate;
    imAvgTimes = [P.wfAlign.alignWin(1):imAvgTimeInterval:-imAvgTimeInterval, 0, imAvgTimeInterval:imAvgTimeInterval:P.wfAlign.alignWin(2)]';
    t = imAvgTimes;
    imAvgNframesPre = sum(imAvgTimes < 0);
    imAvgNframesPost = sum(imAvgTimes > 0);
    imAvgNframes = imAvgNframesPre + imAvgNframesPost + 1;

    % preallocate average images for imAvgBlue and imAvgViolet
    imAvgBlue = zeros(imAvgWidth, imAvgHeight, imAvgNframes);
    imAvgViolet = zeros(imAvgWidth, imAvgHeight, imAvgNframes);

    % load filesWfBpod frame by frame
    for i = progress(1:height(filesWfBpod), 'Title', ['   ', mouse, ' ', session])
        % file information
        imFile = filesWfBpod.path{i};
        imInfo = imfinfo(imFile);
        imWidth = imInfo(1, 1).Width;
        imHeight = imInfo(1, 1).Height;
        imNframes = size(imInfo, 1);
        imData = zeros(imWidth, imHeight, imNframes, 'uint16');
        imTimes = zeros(imNframes, 1);

        for cFrame = 1:imNframes
            imData(:, :, cFrame) = imread(filesWfBpod.path{i}, 'Index', cFrame);
            imTimes(cFrame, 1) = str2double(regexp(imInfo(cFrame, 1).ImageDescription, '(?<=Relative time = )\S*', 'match', 'once'));
        end

        imTimes(:, 1) = imTimes(:, 1) - imTimes(1, 1);
        % get blue and violet frames
        indBlue = 1:2:imNframes;
        indViolet = 2:2:imNframes;
        imBlue = double(imData(:, :, indBlue));
        imViolet = double(imData(:, :, indViolet));
        imTimesBlue = imTimes(indBlue);
        imTimesViolet = imTimes(indViolet);
        imTimesEqual = 0:imAvgTimeInterval:numel(imTimesBlue) * imAvgTimeInterval - imAvgTimeInterval;
        clear imData

        % interpolate violet and blue frames to equally spaced timepoints
        imBlue = shiftdim(imBlue, 2);
        imBlue = interp1(imTimesBlue, imBlue, imTimesEqual);
        imBlue = shiftdim(imBlue, 1);
        imViolet = shiftdim(imViolet, 2);
        imViolet = interp1(imTimesViolet, imViolet, imTimesEqual);
        imViolet = shiftdim(imViolet, 1);

        % align with the trigger
        switch stimType
            case {'LimbMvtTriggerWF', 'LimbMvtTriggerWFopto'}

                switch P.select.stimId
                    case 1
                        [~, frIDalignTrigger] = min(abs(imTimesBlue - filesWfBpod.t1stMvt(i)));
                    case 2
                        [~, frIDalignTrigger] = min(abs(imTimesBlue - filesWfBpod.t2ndMvt(i)));
                end
            case 'LimbTouchStimWF'
                [~, frIDalignTrigger] = min(abs(imTimesBlue - filesWfBpod.tStim(i)));
    
            case 'WhiskerMagnetWF'
                [~, frIDalignTrigger] = min(abs(imTimesBlue - filesWfBpod.tMagnetOn(i)));
        end

        imBlue = imBlue(:, :, frIDalignTrigger - imAvgNframesPre:frIDalignTrigger + imAvgNframesPost);
        imViolet = imViolet(:, :, frIDalignTrigger - imAvgNframesPre:frIDalignTrigger + imAvgNframesPost);

        imAvgBlue = imAvgBlue + imBlue / height(filesWfBpod);
        imAvgViolet = imAvgViolet + imViolet / height(filesWfBpod);
    end

    % flip images vertically and horizontally
    imAvgBlue = imAvgBlue(end:-1:1, end:-1:1, :);
    imAvgViolet = imAvgViolet(end:-1:1, end:-1:1, :);

    % regress violet from blue
    imAvgVioletREG = imAvgViolet;
    Nfr = size(imAvgBlue, 3);

    for m = 1:imAvgWidth
        outSig = zeros(Nfr, 1);
        inSig = zeros(Nfr, 1);

        for n = 1:imAvgHeight
            outSig(:, 1) = imAvgBlue(m, n, :);
            inSig(:, 1) = imAvgViolet(m, n, :);
            B = regress(outSig, [ones(Nfr, 1) inSig]);
            imAvgVioletREG(m, n, :) = imAvgViolet(m, n, :) * B(2) + B(1);
        end

    end

    % reference of baseline
    F0 = mean(imAvgBlue(:, :, 1:imAvgNframesPre), 3);
    IMblue = bsxfun(@minus, imAvgBlue, F0);
    IMblue = bsxfun(@rdivide, IMblue, F0);
    F0 = mean(imAvgVioletREG(:, :, 1:imAvgNframesPre), 3);
    IMviolet = bsxfun(@minus, imAvgVioletREG, F0);
    IMviolet = bsxfun(@rdivide, IMviolet, F0);

    % correct blue from violet
    IMcorr = IMblue - IMviolet;
    F0 = mean(IMcorr(:, :, 1:imAvgNframesPre), 3);
    IMcorr = bsxfun(@minus, IMcorr, F0); % normalize to baseline

    % smooth corrected frames
    order = 2;
    win = 9;

    for m = 1:imAvgWidth

        for n = 1:imAvgHeight
            IMcorr(m, n, :) = sgolayfilt(IMcorr(m, n, :), order, win);
        end

    end

    % generate activation map
    IMcorrNorm = (IMcorr - min(IMcorr(:))) / (max(IMcorr(:)) - min(IMcorr(:)));
    IMcorrNorm = imgaussfilt(IMcorrNorm, 2);

    % apply masks
    if P.wfAlign.reUseMask
        load(P.path.roiMaskForAlignTrig, 'imMask');
    else
        close all;
        imREF = imread(fullfile(P.dir.refImage, [mouse, '_', session, '_REF.tif']));
        imREF = imREF(end:-1:1, end:-1:1);
        f0 = figure();
        imshow(imREF);
        hF = drawpolygon();
        imMask = createMask(hF);
        close(f0);
    end

    % save activation map
    IMcorrNorm(~repmat(imMask, [1 1 size(IMcorrNorm, 3)])) = nan;
    peakFrame = IMcorrNorm(:, :, 28);
    upThreshold = max(IMcorrNorm, [], 'all', 'omitnan');
    lowThreshold = 0.5 * upThreshold;
    peakFrame(peakFrame < lowThreshold) = 0;
    peakFrame = (peakFrame - lowThreshold) / (upThreshold - lowThreshold);
    im = ind2rgb(im2uint8(peakFrame), fire(256));

    switch stimType
        case {'LimbMvtTriggerWF', 'LimbMvtTriggerWFopto'}

            switch P.select.stimId
                case 1
                    save(matSavePath, 'P', 'imAvgBlue', 'imAvgViolet', 'IMcorr', 'imMask', 't', 'filesWfBpod');
                    imwrite(im, tifSavePath, 'tif', 'Compression', 'none', 'WriteMode', 'overwrite');
                case 2
                    save(strrep(matSavePath, 'ACT.mat', 'ACT_Stim2.mat'), 'P', 'imAvgBlue', 'imAvgViolet', 'IMcorr', 'imMask', 't', 'filesWfBpod');
                    imwrite(im, strrep(tifSavePath, 'ACT.tif', 'ACT_Stim2.tif'), 'tif', 'Compression', 'none');
            end

        otherwise
            save(matSavePath, 'P', 'imAvgBlue', 'imAvgViolet', 'IMcorr', 'imMask', 't', 'filesWfBpod');
            imwrite(im, tifSavePath, 'tif', 'Compression', 'none', 'WriteMode', 'overwrite');
    end

    % save filesWfBpod to mat file
    fprintf('   Save file: %s %s\n', mouse, session);

end
