classdef MaskRaw < handle
    %% Properties
    properties
        roiParam
        maskTable
    end

    properties (Access = private)
        roiParamInput
        fileTableRegXy = FileTableRegXy;
    end

    %% Methods
    methods
        %% Constructor
        function obj = MaskRaw(varargin)
            % Parse input
            p = inputParser;
            addOptional(p, 'roiParamInput', [-3.5, 0.5, 3.5, 0.5, 0.5, 2], @(x) isnumeric(x) && isvector(x) && length(x) == 6);
            parse(p, varargin{:});
            obj.roiParamInput = p.Results.roiParamInput;
        end

        %% Setter
        function set.roiParamInput(obj, value)
            validFun = @(x) isnumeric(x) && isvector(x) && length(x) == 6;

            if validFun(value)
                obj.roiParamInput = value;
            else
                error('Invalid roiParamInput');
            end

            obj.Update();
        end

        %% Update mask table
        function Update(obj)
            % raw roi parameters, [xOrigin1, xStep, xOrigin2, xWidth, yOrigin, yHeight]
            xOrigin1 = obj.roiParamInput(1);
            xStep = obj.roiParamInput(2);
            xOrigin2 = obj.roiParamInput(3);
            xWidth = obj.roiParamInput(4);
            yOrigin = obj.roiParamInput(5);
            yHeight = obj.roiParamInput(6);

            % raw ROI center coordinates, [x, y]
            roiCenterX = xOrigin1:xStep:xOrigin2; roiCenterY = repmat(yOrigin, 1, length(roiCenterX));

            % roiParam
            obj.roiParam.xWidth = xWidth; obj.roiParam.yHeight = yHeight; obj.roiParam.centerX = roiCenterX; obj.roiParam.centerY = roiCenterY;
            % raw ROI rectangle coordinates, [x1, x2, y1,y2]
            roiRectangle = [roiCenterX - xWidth / 2; roiCenterX + xWidth / 2; roiCenterY - yHeight / 2; roiCenterY + yHeight / 2]';

            % covert to a table
            roiRectangle = array2table(roiRectangle, 'VariableNames', {'x1', 'x2', 'y1', 'y2'});
            roiRectangle.roiId = (1:height(roiRectangle))';

            % combine with file table reg xy
            obj.fileTableRegXy.fileTable = hCombineTable(obj.fileTableRegXy.fileTable, roiRectangle);

            % calculate mask table
            calMaskTable = @(x, y, x1, x2, y1, y2) {x >= x1 & x <= x2 & y >= y1 & y <= y2};
            maskTableTem = rowfun(calMaskTable, obj.fileTableRegXy.fileTable, 'InputVariables', {'x', 'y', 'x1', 'x2', 'y1', 'y2'}, 'OutputVariableNames', 'maskTable', 'ExtractCellContents', true);
            obj.fileTableRegXy.CleanVar('maskTable', 'remove');
            obj.maskTable = [obj.fileTableRegXy.fileTable, maskTableTem];
        end

        function Plot(obj, varargin)
            % parse input
            p = inputParser;
            addRequired(p, 'obj');
            addOptional(p, 'ax', gca, @(x) isa(x, 'matlab.graphics.axis.Axes'));
            addOptional(p, 'fill', true, @(x) islogical(x) && isscalar(x));
            addOptional(p, 'roiId', [], @(x) isnumeric(x) && isvector(x));
            parse(p, obj, varargin{:});
            obj = p.Results.obj;
            ax = p.Results.ax;
            fill = p.Results.fill;
            roiId = p.Results.roiId;

            % plot

            % if ax is provided, plot on it
            if ~isempty(ax)
                axes(ax);
            end
            % if roiId is not provided, plot all
            if isempty(roiId)
                roiId = 1:length(obj.roiParam.centerX);
            end

            % extract the X and Y coordinates of the strip centers, as well as the strip width and height
            centerX = obj.roiParam.centerX(roiId);
            centerY = obj.roiParam.centerY(roiId);
            xWidth = obj.roiParam.xWidth;
            yHeight = obj.roiParam.yHeight;

            % load the ABM template image and set the Bregma coordinates
            abmTemplate = imread(Param().path.abmTemplate);
            abmTemplateBregmaXy = [256, 256];
            mm2pixel = 1/0.019; pixels2mm = 0.019;

            % plot the ABM template image
            imshow(abmTemplate);

            % get a set of face colors for the strips
            faceColorSetColor = jet(length(centerX));
            faceColorSetGrey = repmat([0.5, 0.5, 0.5], length(centerX), 1);
            faceAlpha = 0.7;
            faceColorSetColor(:, 4) = faceAlpha;
            faceColorSetGrey(:, 4) = faceAlpha;

            % plot the strips
            hold on;

            for j = 1:length(centerX)
                centerXNow = (centerX(j) - 0) * mm2pixel + abmTemplateBregmaXy(1);
                centerYNow = abmTemplateBregmaXy(2) - (centerY(j) - 0) * mm2pixel;

                switch fill
                    case 1
                        rectangle('Position', [centerXNow - xWidth / 2 * mm2pixel, centerYNow - yHeight / 2 * mm2pixel, xWidth * mm2pixel, yHeight * mm2pixel], 'Curvature', 0.5, 'EdgeColor', 'none', 'FaceColor', faceColorSetColor(j, :));
                        plot(centerXNow, centerYNow, 'k+');
                    case 0
                        rectangle('Position', [centerXNow - xWidth / 2 * mm2pixel, centerYNow - yHeight / 2 * mm2pixel, xWidth * mm2pixel, yHeight * mm2pixel], 'Curvature', 0.5, 'EdgeColor', 'r', 'FaceColor', faceColorSetGrey(j, :));
                        plot(centerXNow, centerYNow, 'r+');
                end

            end

            hold off;
            % set the axis, minor grid, major grid on
            axis image; axis on; grid on;
            set(get(gca, 'Title'), 'String', ['ROI: Strips ', sprintf('(W=%g, H=%d)', xWidth, yHeight)]);
            % set axis tick labels to mm, abmTemplateBregmaXy should be 0, 0 mm
            xTicks = 1:1:512;
            xTickLabels = round((xTicks - abmTemplateBregmaXy(1)) * pixels2mm, 1);
            yTicks = 1:1:512;
            yTickLabels = round((abmTemplateBregmaXy(2) - yTicks) * pixels2mm, 1);
            set(gca, 'XTick', xTicks(1:39:end), 'XTickLabel', xTickLabels(1:39:end), 'YTick', yTicks(1:39:end), 'YTickLabel', yTickLabels(1:39:end));
            % set the axis label
            xlabel('ML (mm)'); ylabel('AP (mm)');
        end

    end

end
