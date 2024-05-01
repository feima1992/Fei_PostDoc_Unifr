function dataOut = loadDataRegXy(filePath)
    % load the data from the file path
    dataTemp = cellfun(@(X)load(X, 'XYrefCTX'), filePath, 'UniformOutput', false);
    % calculate the coordinates of each pixel with respect to bregma as the origin
    [x, y, bregmaXy] = cellfun(@(X)loadDataRegXyHelper(X.XYrefCTX), dataTemp, 'UniformOutput', false);
    dataOut = table(x, y, bregmaXy);
end

function [x, y, bregmaXy] = loadDataRegXyHelper(XyRefCtx)
    bregmaX = XyRefCtx(1, 1);
    bregmaY = XyRefCtx(1, 2);
    % calculate the coordinates of each pixel with respect to bregma as the origin
    [x, y] = meshgrid(1:512, 1:512);
    x = x - bregmaX;
    y = y - bregmaY;
    % covert pixel coordinates to mm, 1 pixel = 0.019 mm
    x = x * 0.019;
    y = y * 0.019;
    bregmaXy = [bregmaX, bregmaY];
end
