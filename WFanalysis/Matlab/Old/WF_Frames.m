classdef WF_Frames < handle
    properties
        filePath
        frameSize
        frameRate
        frameTime
        frameData
    end

    methods
        % Constructor
        function obj = WF_Frames(filePath)
            
            try
                info = imfinfo(filePath);
            catch
                error('File is not a valid image file');
            end

            % Read the image info

            obj.filePath = filePath;
            obj.frameSize = [info(1).Height, info(1).Width, length(info)];
            FuncExtractFrameTime = @(X)str2double(regexp(X, '(?<=Relative time = )\S*', 'match', 'once'));
            obj.frameTime = cellfun(FuncExtractFrameTime, {info.ImageDescription}, 'UniformOutput', true);
            obj.frameRate = 1/mean(diff(obj.frameTime));
            obj.Load();

        end

        % Load the image file
        function obj = Load(obj)
            obj.frameData = zeros(obj.frameSize);
            fprintf('Loading image file %s\n', obj.filePath);
            for i = 1:obj.frameSize(3)
                obj.frameData(:,:,i) = imread(obj.filePath, i);
            end
        end

        % Write the image file
        function obj = Write(obj, filePath)
            if nargin < 2
                filePath = obj.filePath;
            end
            fprintf('Writing image file %s\n', filePath);
            for i = 1:obj.frameSize(3)
                imwrite(obj.frameData(:,:,i), filePath, 'WriteMode', 'append');
            end
        end

        % Downsample the image
        function obj = Downsample(obj, spatialFactor, temporalFactor)
            arguments
                obj
                spatialFactor (1,1) {mustBeInteger, mustBePositive} = 1
                temporalFactor (1,1) {mustBeInteger, mustBePositive} = 1
            end
            obj.frameRate = obj.frameRate / temporalFactor;
            obj.frameTime = obj.frameTime(1:temporalFactor:end);
            obj.frameData = imresize(obj.frameData(:,:,1:temporalFactor:end), 1/spatialFactor, 'bilinear');
            obj.frameSize = size(obj.frameData);
        end

        % Smooth the image with a Gaussian filter
        function obj = FilterGaussian(obj, sigma, isTemporal)
            arguments
                obj
                sigma (1,1) {mustBePositive} = 1
                isTemporal (1,1) {islogical} = false
            end
            if isTemporal
                obj.frameData = imgaussfilt(obj.frameData, [0, 0, sigma]);
            else
                obj.frameData = imgaussfilt(obj.frameData, sigma);
            end
        end

        % Calculate the deltaF/F
        function obj = DeductMean(obj)
            obj.frameData = obj.frameData ./ mean(obj.frameData, 3) - 1;
        end

        % Rescale the deltaF/F to [0, 1]
        function obj = Rescale(obj)
            obj.frameData = (obj.frameData - min(obj.frameData(:))) ./ (max(obj.frameData(:)) - min(obj.frameData(:)));
        end
    end
end