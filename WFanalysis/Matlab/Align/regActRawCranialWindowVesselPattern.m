function regActRawCranialWindowVesselPattern(refImPath, actTifPath, P)
% function to register the cranial window vessel pattern of the activation image to the template image collected during the surgery

% dir and path
mouse = strrep(char(strrep(findMouse(refImPath),'m','s')), 'b','s'); % for the template image, the mouse starts with 's'
session = findSession(refImPath);
templateImPath = fullfile(P.dir.coorTransformImage, [mouse, '.jpg']);
actTifRegPath = strrep(strrep(actTifPath, 'Raw', 'Reg'), 'ACT.tif', 'REG.tif');
actRefImRegPath = strrep(strrep(actTifPath, 'Raw', 'Reg'), 'ACT.tif', 'REF.jpg');
actDataPath = strrep(actTifPath, '.tif', '.mat');
actRegDataPath = strrep(strrep(actTifPath,'Raw','Reg'),'ACT.tif','REG.mat');
actRegXysPath = fullfile(P.dir.regXy, [mouse, '_', session, '_XYreg.mat']);

% skip if the registered data already exists
if exist(actRegDataPath, 'file') && exist(actRegXysPath, 'file') && exist(actRefImRegPath, 'file') && exist(actTifRegPath, 'file')
    return;
end

% read the template image
tfObj = load(fullfile(P.dir.coorTransformImage, [mouse, '.mat'])).obj;
templateControlPoints = tfObj.controlPointsRef;
templateBregmaPixel = tfObj.bregmaCoorPixel;
templateRefPointsPixel = tfObj.refPointsCoorPixel;
templateRefPointsReal = tfObj.refPointsCoorReal;
templateIm = imread(templateImPath);

% read the reference image
refIm = imadjust(imread(refImPath));

% read the activation image and frame
actIm = rot90(imread(actTifPath),2);
actData = load(actDataPath);
actData.imAvgBlue = rot90(actData.imAvgBlue,2);
actData.imAvgViolet = rot90(actData.imAvgViolet,2);
actData.IMcorr = rot90(actData.IMcorr,2);

% draw and create new imMask
figure('Color', 'w', 'Name', 'Draw the mask', 'Position', get(0, 'ScreenSize'));
imshow(refIm);
title('Draw the mask');
hF = drawpolygon();
actData.imMask = createMask(hF);
close(gcf);


% register the reference image to the template image
try
    controlPoints = load(actRegXysPath);
    refControlPoints = controlPoints.controlPointsRef;
    templateControlPoints = controlPoints.controlPointsTemplate;
catch
    refControlPoints = repmat([256, 256], 6, 1);
end

[controlPointsRef, controlPointsTemplate] = cpselect(refIm, templateIm, refControlPoints, templateControlPoints, 'Wait', true);
transformer = fitgeotform2d(controlPointsRef, controlPointsTemplate, 'similarity');
actImWarpped = imwarp(actIm, transformer, 'OutputView', imref2d(size(templateIm)));

% find the bregma position in the refIm
refImBregmaPixel = transformer.transformPointsInverse(templateBregmaPixel);
refImRefPointsPixel = cellfun(@(x) transformer.transformPointsInverse(x), templateRefPointsPixel, 'UniformOutput', false);

% rotate refIm around its center
refIm = imrotate(refIm, -transformer.RotationAngle, 'bilinear', 'crop'); % the rotation angle is negative because the rotation is in the opposite direction
actIm = imrotate(actIm, -transformer.RotationAngle, 'bilinear', 'crop'); % the rotation angle is negative because the rotation is in the opposite direction
actData.imAvgBlue = imrotate(actData.imAvgBlue, - transformer.RotationAngle, 'bilinear', 'crop');
actData.imAvgViolet = imrotate(actData.imAvgViolet, - transformer.RotationAngle, 'bilinear', 'crop');
actData.IMcorr = imrotate(actData.IMcorr, - transformer.RotationAngle, 'bilinear', 'crop');
actData.imMask = imrotate(actData.imMask, - transformer.RotationAngle, 'bilinear', 'crop');

% find the bregma position in the refIm after rotation
centerRotate = [size(refIm, 2), size(refIm, 1)] / 2;
refImBregmaPixelRelative = refImBregmaPixel - centerRotate;
% clockwise rotation matrix
R = [cosd(transformer.RotationAngle), -sind(transformer.RotationAngle); sind(transformer.RotationAngle), cosd(transformer.RotationAngle)];
refImBregmaPixelRotated = R * refImBregmaPixelRelative' + centerRotate';

% translate refIm so that bregma is at the center
refIm = imtranslate(refIm, [256 - refImBregmaPixelRotated(1), 256 - refImBregmaPixelRotated(2)]);
actIm = imtranslate(actIm, [256 - refImBregmaPixelRotated(1), 256 - refImBregmaPixelRotated(2)]);
actData.imAvgBlue = imtranslate(actData.imAvgBlue, [256 - refImBregmaPixelRotated(1), 256 - refImBregmaPixelRotated(2)]);
actData.imAvgViolet = imtranslate(actData.imAvgViolet, [256 - refImBregmaPixelRotated(1), 256 - refImBregmaPixelRotated(2)]);
actData.IMcorr = imtranslate(actData.IMcorr, [256 - refImBregmaPixelRotated(1), 256 - refImBregmaPixelRotated(2)]);
actData.imMask = imtranslate(actData.imMask, [256 - refImBregmaPixelRotated(1), 256 - refImBregmaPixelRotated(2)]);

% calculate pixel2mm for the refIm based on the scale of the transformer
refImPixel2mm = (templateRefPointsReal{2}(1) - templateRefPointsReal{1}(1)) / (refImRefPointsPixel{2}(1) - refImRefPointsPixel{1}(1));
% resize the refIm so that the refImPixel2mm is the same as before = 0.018, and crop the refIm to 512x512 around the center
refIm = imresize(refIm, refImPixel2mm / 0.018);
actIm = imresize(actIm, refImPixel2mm / 0.018);
actData.imAvgBlue = imresize(actData.imAvgBlue, refImPixel2mm / 0.018);
actData.imAvgViolet = imresize(actData.imAvgViolet, refImPixel2mm / 0.018);
actData.IMcorr = imresize(actData.IMcorr, refImPixel2mm / 0.018);
actData.imMask = imresize(actData.imMask, refImPixel2mm / 0.018);

% crop the refIm to 512x512 around the center
startPixelIdx = round(size(refIm, 1) / 2 - 256);
endPixelIdx = startPixelIdx + 511;
refIm = refIm(startPixelIdx:endPixelIdx, startPixelIdx:endPixelIdx);
actIm = actIm(startPixelIdx:endPixelIdx, startPixelIdx:endPixelIdx,:);
actData.imAvgBlue = actData.imAvgBlue(startPixelIdx:endPixelIdx, startPixelIdx:endPixelIdx,:);
actData.imAvgViolet = actData.imAvgViolet(startPixelIdx:endPixelIdx, startPixelIdx:endPixelIdx,:);
actData.IMcorr = actData.IMcorr(startPixelIdx:endPixelIdx, startPixelIdx:endPixelIdx,:);
actData.imMask = actData.imMask(startPixelIdx:endPixelIdx, startPixelIdx:endPixelIdx);

% show the refIm and the window center
figure('Color', 'w', 'Name', 'Registration', 'Position', get(0, 'ScreenSize'));
subplot(2,2,1);
imRefAct = imfuse(refIm, actIm, 'blend');
imshow(imRefAct);
hold on
plot(256, 256, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
hold off

subplot(2,2,2);
imTempAct = imfuse(templateIm, actImWarpped, 'blend');
imshow(imTempAct);
hold on
plot(templateBregmaPixel(1), templateBregmaPixel(2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');

subplot(2,2,3);
imshowFrame(actData.IMcorr(:,:,28));

subplot(2,2,4);
imshowFrameRefBregma(im2gray(actIm));

exportgraphics(gcf, strrep(actRefImRegPath, 'REF', 'REGIMG'), 'Resolution', 300);

% ask the user whether the registration is correct
answer = questdlg('Is the registration correct?', 'Registration', 'Yes', 'No', 'Yes');
if strcmp(answer, 'No')
    keyboard
else
    % save the registered data
    param = P;
    t = actData.t;
    IMcorrREG = actData.IMcorr;
    imMaskREG = actData.imMask;
    pixel2mm = refImPixel2mm;
    save(actRegDataPath, 'param', 't', 'IMcorrREG', 'imMaskREG', 'pixel2mm');
    save(actRegXysPath, 'controlPointsRef', 'controlPointsTemplate');
    imwrite(im2uint8(refIm), actRefImRegPath);
    imwrite(actIm, actTifRegPath);
end