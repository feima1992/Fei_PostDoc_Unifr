classdef Frames_IMcorr < Frames

    properties
        uenoMask
    end

    %% Methods
    methods
        % Constructor
        function obj = Frames_IMcorr(frameData, varargin)

            p = inputParser;
            addRequired(p, 'frameData', @isnumeric);
            addOptional(p, 'frameTime', [], @isnumeric);
            addOptional(p, 'uenoMask', []);
            parse(p, frameData, varargin{:});
            frameData = p.Results.frameData;
            frameTime = p.Results.frameTime;
            uenoMask = p.Results.uenoMask;

            obj = obj@Frames(frameData, frameTime);
            obj.uenoMask = uenoMask;
        end

        % Define activation map
        function obj = CalActMap(obj, threValue)

            arguments
                obj (1, 1) Frames_IMcorr
                threValue = []
            end

            if isempty(threValue)
                threValue = 0.5;
            end

            % find the maximum intensity of pixels in peak frame
            upLim = max(obj.framePeak, [], 'all'); % upper limit
            lowLim = upLim * threValue; % lower limit

            % set pixels with intensity lower than lower limit to lowLim
            obj.frameData(obj.frameData < lowLim) = lowLim;

            % scale the intensity of pixels to [0, 1]
            obj.frameData = (obj.frameData - lowLim) / (upLim - lowLim);
        end

        function obj = CalRegionProps(obj)
            CalRegionProps@Frames(obj);
            sensoryArea = zeros(height(obj.frameProps), 1);
            sensoryIntensity = zeros(height(obj.frameProps), 1);
            motorArea = zeros(height(obj.frameProps), 1);
            motorIntensity = zeros(height(obj.frameProps), 1);
            notSensoryMotorArea = zeros(height(obj.frameProps), 1);
            notSensoryMotorIntensity = zeros(height(obj.frameProps), 1);

            for i = 1:height(obj.frameProps)
                component = obj.frameProps{i, 'Component'}{1};
                frameSensory = component .* obj.uenoMask.maskSensory;
                sensoryArea(i) = sum(frameSensory > 0, 'all');
                sensoryIntensity(i) = sum(frameSensory, 'all');

                frameMotor = component .* obj.uenoMask.maskMotor;
                motorArea(i) = numel(find(frameMotor));
                motorIntensity(i) = sum(frameMotor, 'all');

                frameNotSensoryMotor = component .* obj.uenoMask.maskNotSensoryMotor;
                notSensoryMotorArea(i) = sum(frameNotSensoryMotor > 0, 'all');
                notSensoryMotorIntensity(i) = sum(frameNotSensoryMotor, 'all');
            end

            obj.frameProps.AreaSensory = sensoryArea;
            obj.frameProps.IntensitySensory = sensoryIntensity;
            obj.frameProps.AreaMotor = motorArea;
            obj.frameProps.IntensityMotor = motorIntensity;
            obj.frameProps.AreaNotSensoryMotor = notSensoryMotorArea;
            obj.frameProps.IntensityNotSensoryMotor = notSensoryMotorIntensity;
        end

    end

end
