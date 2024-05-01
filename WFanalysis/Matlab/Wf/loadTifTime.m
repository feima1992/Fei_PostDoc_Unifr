function [frameTime, frameIdx]  = loadTifTime(tifFile)
    tifInfo = imfinfo(tifFile);
    frameIdx = 1:length(tifInfo); 
    frameIdx = frameIdx';
    frameTime = findTifTime({tifInfo.ImageDescription}); 
    frameTime = frameTime';
end