function duration = loadTifDuration(tifFile)

    try
        tifInfo = imfinfo(tifFile);
        tifTime = findTifTime({tifInfo.ImageDescription});
        duration = tifTime(end) - tifTime(1);
        
    catch
        duration = nan;
    end

end
