function combine_tifs(filePathList, outputFilePath)
    % Combine tifs into a single tif
    % filePathList: list of file paths to tifs to combine
    % Example: combine_tifs({'/path/to/file1.tif', '/path/to/file2.tif'})
    
    % Open dialog to select files if none are provided
    if nargin < 1
        [fileNames, filePaths] = uigetfile('*.tif', 'Select tif files to combine', 'MultiSelect', 'on');
        if isequal(fileNames, 0)
            return;
        end
        filePathList = cellfun(@(x) fullfile(filePaths, x), fileNames, 'UniformOutput', false);
    end

    % Open dialog to select output file if none is provided
    if nargin < 2
        [outputFileName, outputFilePath] = uiputfile('*.tif', 'Save combined tif as');
        if isequal(outputFileName, 0)
            return;
        end
        outputFilePath = fullfile(outputFilePath, outputFileName);
    end

    % Initialize tif writer
    tifWriter = Fast_BigTiff_Write(outputFilePath);

    % Combine tifs
    for i = 1:length(filePathList)
        % Display progress
        disp(['Processing ' filePathList{i} '...']);
        % Read tif
        tifFrames = tiffreadVolume(filePathList{i});
        for j = 1:size(tifFrames, 3)
            % Write frame
            tifWriter.WriteIMG(tifFrames(:, :, j));
        end
    end

    % Close tif writer
    tifWriter.close();

end