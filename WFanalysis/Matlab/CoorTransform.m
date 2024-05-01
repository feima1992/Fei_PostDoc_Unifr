classdef CoorTransform < handle    
    %% Properties
    properties

        % image
        refImage % reference image
        recImage % record image
        recImageRecovered % recovered record image after transformation

        % coordinates
        refPointsCoorPixel = {} % reference points in pixel
        refPointsCoorReal = {[1,0], [2,0]}; % default ref points in mm
        bregmaCoorReal = [0, -0.5]; % default bregma point in mm
        bregmaCoorPixel % bregma point in pixel
        winCenterCoorReal = [-2.5, -0.5]; % default window center in mm
        winCenterCoorPixel % window center in pixel

        controlPointsRef % control points in the reference image
        controlPointsRefInitial = repmat([500, 500], 6, 1) % initial control points in the reference image
        controlPointsRec % control points in the record image
        controlPointsRecInitial = repmat([500, 500], 6, 1) % initial control points in the record image
        transformer % transformer for the coordinate transformation

        % GUI
        objSelectRefPoints % object for the GUI of selecting reference points
        objTransformCoorCpselect % object for the GUI of transforming coordinates using cpselect

    end
    %% Methods
    methods
    % constructor
        function  obj = CoorTransform()
        end

        function obj = Init(obj, refImage, recImage)
            % check the input arguments
            if nargin == 3
                if isfile(refImage)
                    obj.refImage = imread(refImage);
                else
                    error('The reference image does not exist');
                end
                if isfile(recImage)
                    obj.recImage = imadjust(imread(recImage));
                else
                    error('The record image does not exist');
                end
            elseif nargin == 2
                if isfile(refImage)
                    obj.refImage = imread(refImage);
                else
                    error('The reference image does not exist');
                end
            end

            % set the reference image if not set
            if isempty(obj.refImage)
                % get the disk name
                funcPath = mfilename('fullpath');
                funcDisk = funcPath(1:3);
                refImPath = [funcDisk, 'users\Fei\DataAnalysis\Utilities\CoorTransform\*.*'];
                [refImName, refImPath] = uigetfile(refImPath, 'Select the reference image');
                if refImName == 0
                    error('No reference image selected');
                end
                obj.refImage = imread(fullfile(refImPath, refImName));
            end

            % set the record image if not set
            if isempty(obj.recImage)
                % get the disk name
                funcPath = mfilename('fullpath');
                funcDisk = funcPath(1:3);
                recImPath = [funcDisk, 'users\Fei\DataAnalysis\Utilities\CoorTransform\*.*'];
                [recImName, recImPath] = uigetfile(recImPath, 'Select the record image');
                if recImName == 0
                    error('No record image selected');
                end
                obj.recImage = imadjust(imread(fullfile(recImPath, recImName)));
            end

            % transform the coordinates
            obj = obj.TransformCoor();
            % convert the unit
            obj = obj.ConvertUnit();
        end

        function obj = TransformCoor(obj)
            % perform the transformation
            [obj.controlPointsRec, obj.controlPointsRef] = cpselect(obj.recImage, obj.refImage, obj.controlPointsRecInitial, obj.controlPointsRefInitial, 'Wait', true);
            obj.controlPointsRefInitial = obj.controlPointsRef;
            try % for matlab 2022b and later
                obj.transformer = fitgeotform2d(obj.controlPointsRec,obj.controlPointsRef,"similarity");
            catch % for matlab 2022b and earlier
                obj.transformer = fitgeotrans(obj.controlPointsRec,obj.controlPointsRef,"nonreflectivesimilarity");
            end
            obj.recImageRecovered = imwarp(obj.recImage, obj.transformer, 'OutputView', imref2d(size(obj.refImage)));
            figure('Name', 'Check the recovered image');
            montage({obj.refImage, obj.recImageRecovered});
        end   

        function obj = ConvertUnit(obj)
            obj.objSelectRefPoints.figH = uifigure('Name', 'Select reference points');
            obj.objSelectRefPoints.gl  = uigridlayout(obj.objSelectRefPoints.figH, [3, 2]);
            obj.objSelectRefPoints.gl.ColumnWidth = {'1x', '1x'};
            obj.objSelectRefPoints.gl.RowHeight = {20, 80, '1x'};
            obj.objSelectRefPoints.gl.Padding = [10, 10, 10, 10];
            obj.objSelectRefPoints.gl.BackgroundColor = [0.94, 0.94, 0.94];

            % create fugure elements
            obj.objSelectRefPoints.imAxes = uiaxes(obj.objSelectRefPoints.gl);
            obj.objSelectRefPoints.imAxes.Layout.Row = 3;
            obj.objSelectRefPoints.imAxes.Layout.Column = [1,2];
            imshow(obj.refImage, 'Parent', obj.objSelectRefPoints.imAxes);

            % create the text elements
            obj.objSelectRefPoints.txtH1 = uilabel(obj.objSelectRefPoints.gl);
            obj.objSelectRefPoints.txtH1.Text = 'Reference points';
            obj.objSelectRefPoints.txtH1.Layout.Row = 1;
            obj.objSelectRefPoints.txtH1.Layout.Column = 1;

            obj.objSelectRefPoints.txtH2 = uilabel(obj.objSelectRefPoints.gl);
            obj.objSelectRefPoints.txtH2.Text = 'Bregma point';
            obj.objSelectRefPoints.txtH2.Layout.Row = 1;
            obj.objSelectRefPoints.txtH2.Layout.Column = 2;

            % create the table elements
            tbRef = array2table(zeros(2, 4), 'VariableNames', {'X(pixel)', 'Y(pixel)', 'X(mm)', 'Y(mm)'}, 'RowNames', {'Ref1', 'Ref2'});
            tbRef{'Ref1', 'X(mm)'} = obj.refPointsCoorReal{1}(1);
            tbRef{'Ref1', 'Y(mm)'} = obj.refPointsCoorReal{1}(2);
            tbRef{'Ref2', 'X(mm)'} = obj.refPointsCoorReal{2}(1);
            tbRef{'Ref2', 'Y(mm)'} = obj.refPointsCoorReal{2}(2);

            obj.objSelectRefPoints.tbHref = uitable(obj.objSelectRefPoints.gl);
            obj.objSelectRefPoints.tbHref.Data = tbRef;

            obj.objSelectRefPoints.tbHref.Layout.Row = 2;
            obj.objSelectRefPoints.tbHref.Layout.Column = 1;

            tbBregma = array2table(zeros(2, 4), 'VariableNames', {'X(pixel)', 'Y(pixel)', 'X(mm)', 'Y(mm)'}, 'RowNames', {'Bregma', 'Window center'});
            tbBregma{'Bregma', 'X(mm)'} = obj.bregmaCoorReal(1);
            tbBregma{'Bregma', 'Y(mm)'} = obj.bregmaCoorReal(2);
            tbBregma{'Window center', 'X(mm)'} = obj.winCenterCoorReal(1);
            tbBregma{'Window center', 'Y(mm)'} = obj.winCenterCoorReal(2);

            obj.objSelectRefPoints.tbHbregma = uitable(obj.objSelectRefPoints.gl);
            obj.objSelectRefPoints.tbHbregma.Data = tbBregma;
            obj.objSelectRefPoints.tbHbregma.Layout.Row = 2;
            obj.objSelectRefPoints.tbHbregma.Layout.Column = 2;

            % get the reference point coordinate 1 in pixel
            obj.objSelectRefPoints.refPoint1 = drawpoint(obj.objSelectRefPoints.imAxes,'Color', 'r', 'Label', 'Ref1');
            obj.objSelectRefPoints.tbHref.Data{'Ref1', 'X(pixel)'} = obj.objSelectRefPoints.refPoint1.Position(1);
            obj.objSelectRefPoints.tbHref.Data{'Ref1', 'Y(pixel)'} = obj.objSelectRefPoints.refPoint1.Position(2);

            % get the reference point coordinate 2 in pixel
            obj.objSelectRefPoints.refPoint2 = drawpoint(obj.objSelectRefPoints.imAxes,'Color', 'r', 'Label', 'Ref2');
            obj.objSelectRefPoints.tbHref.Data{'Ref2', 'X(pixel)'} = obj.objSelectRefPoints.refPoint2.Position(1);
            obj.objSelectRefPoints.tbHref.Data{'Ref2', 'Y(pixel)'} = obj.objSelectRefPoints.refPoint2.Position(2);

            % set obj.refPointsCoorPixel
            obj.refPointsCoorPixel{1} = obj.objSelectRefPoints.refPoint1.Position;
            obj.refPointsCoorPixel{2} = obj.objSelectRefPoints.refPoint2.Position;

            % get the coordinates of the bregma point in pixel
            obj.bregmaCoorPixel = obj.ConvertMm2pixel(obj.bregmaCoorReal);
            obj.winCenterCoorPixel = obj.ConvertMm2pixel(obj.winCenterCoorReal);

            % update the table
            obj.objSelectRefPoints.tbHbregma.Data{'Bregma', 'X(pixel)'} = obj.bregmaCoorPixel(1);
            obj.objSelectRefPoints.tbHbregma.Data{'Bregma', 'Y(pixel)'} = obj.bregmaCoorPixel(2);

            % draw the bregma point
            obj.objSelectRefPoints.bregmaPoint = drawpoint(obj.objSelectRefPoints.imAxes, 'Position', obj.bregmaCoorPixel, 'Color', 'g', 'Label', 'Bregma');

            % draw the window center
            obj.objSelectRefPoints.winCenterPoint = drawpoint(obj.objSelectRefPoints.imAxes, 'Position', obj.winCenterCoorPixel, 'Color', 'y', 'Label', 'Window center');

        end

        function coorMm = ConvertPixel2mm(obj, xyPixel)
            % get the reference points
            p1x = obj.refPointsCoorPixel{1}(1);
            p1y = obj.refPointsCoorPixel{1}(2);
            p2x = obj.refPointsCoorPixel{2}(1);
            p2y = obj.refPointsCoorPixel{2}(2);

            r1x = obj.refPointsCoorReal{1}(1);
            r1y = obj.refPointsCoorReal{1}(2);
            r2x = obj.refPointsCoorReal{2}(1);
            r2y = obj.refPointsCoorReal{2}(2);

            % calculate the transformed coordinates
            p2r = (r2x - r1x)/(p2x - p1x);
            coorMm(1) = r1x + (xyPixel(1) - p1x)*p2r;
            coorMm(2) = mean([r1y, r2y]) + (xyPixel(2) - mean([p1y, p2y]))*p2r;
        end

        function coorPixel = ConvertMm2pixel(obj, xyMm)
            % get the reference points
            % get the reference points
            p1x = obj.refPointsCoorPixel{1}(1);
            p1y = obj.refPointsCoorPixel{1}(2);
            p2x = obj.refPointsCoorPixel{2}(1);
            p2y = obj.refPointsCoorPixel{2}(2);

            r1x = obj.refPointsCoorReal{1}(1);
            r1y = obj.refPointsCoorReal{1}(2);
            r2x = obj.refPointsCoorReal{2}(1);
            r2y = obj.refPointsCoorReal{2}(2);

            % calculate the transformed coordinates
            r2p = (p2x - p1x)/(r2x - r1x);
            coorPixel(1) = p1x + (xyMm(1) - r1x)*r2p;
            coorPixel(2) = mean([p1y, p2y]) + (xyMm(2) - mean([r1y, r2y]))*r2p;
        end

        function newCoor = Apply(obj, coor)

            % check the input coor is a n*2 numeric array
            if ~isnumeric(coor) || size(coor, 2) ~= 2
                error('The input coordinate should be a n*2 numeric array');
            end

            % check the existence of the transformer
            if isempty(obj.transformer)
                obj = obj.TransformCoor();
            end

            % check existence of the unit conversion

            % convert the coordinates
            newCoor = zeros(size(coor));
            for i = 1:size(coor, 1)
                [x, y] = transformPointsForward(obj.transformer, coor(i, 1), coor(i, 2));
                newCoor(i, :) = obj.ConvertPixel2mm([x, y]);
            end

        end

        function Save(obj, savePath)

            if nargin == 1
                funcPath = mfilename('fullpath');
                funcDisk = funcPath(1:3);
                % get the disk name
                savePath = [funcDisk, 'users\Fei\DataAnalysis\Utilities\CoorTransform\CoorTransform.mat'];
            end
            
            % save the object
            obj.objSelectRefPoints = [];
            obj.objTransformCoorCpselect = [];
            save(savePath, 'obj');
        end

        function obj = Reset(obj)
            % reset the object
            obj.recImage = [];
            obj.recImageRecovered = [];
            obj.controlPointsRec = [];
            obj.transformer = [];
        end
        
    end

    methods(Static)
        function obj = Load(loadPath)
            % load the object
             loadResult = load(loadPath);
             obj = loadResult.obj;
        end
    end
    
end