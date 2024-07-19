classdef CoorTransform < matlab.mixin.Copyable % Handle class with copy functionality
    %% Properties
    properties
        % folder
        folder
        mouse
        session
        % image
        refImage % reference image
        recImage % record image
        recImageRecovered % recovered record image after transformation

        % coordinates
        refPointsCoorPixel = {} % reference points in pixel
        refPointsCoorReal = {[1, 0], [2, 0]}; % default ref points in mm
        bregmaCoorReal = [0, 0]; % default bregma point in mm
        bregmaCoorPixel % bregma point in pixel
        winCenterCoorReal = [-2.25, -0.5]; % default window center in mm
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
        function obj = CoorTransform()
            % get the folder of the reference image
            funcPath = mfilename('fullpath');
            funcDisk = funcPath(1:3);
            obj.folder = [funcDisk, 'users\Fei\DataAnalysis\Utilities\CoorTransformSingleCell\'];
        end

        function obj = Init(obj, refImage, recImage)
            % set the reference image and record image
            if nargin == 3

                if isfile(refImage)
                    obj.refImage = imread(refImage);
                else
                    refIm = findFile(obj.folder, refImage);

                    if height(refIm) == 1
                        obj.refImage = imread(refIm.path);
                    else
                        error('The reference image does not exist or multiple images are found');
                    end

                end

                if isfile(recImage)
                    obj.recImage = imadjust(imread(recImage));
                    obj.mouse = findMouse(recImage);
                    obj.session = findSession(recImage);
                else
                    recIm = findFile(obj.folder, recImage);

                    if height(recIm) == 1
                        obj.recImage = imadjust(imread(recIm.path));
                        obj.mouse = findMouse(recIm.path);
                        obj.session = findSession(recIm.path);
                    else
                        error('The record image does not exist or multiple images are found');
                    end

                end

            elseif nargin == 2

                if isfile(refImage)
                    obj.refImage = imread(refImage);
                else
                    refIm = findFile(obj.folder, refImage);

                    if height(refIm) == 1
                        obj.refImage = imread(refIm.path);
                    else
                        error('The reference image does not exist or multiple images are found');
                    end

                end

            end

            % set the reference image if not set
            if isempty(obj.refImage)
                [refImName, ~] = uigetfile({'*.jpg;*.png;*.tif', 'Image files'}, 'Select the reference image', obj.folder);

                if refImName == 0
                    error('No reference image selected');
                end

                obj.refImage = imread(fullfile(obj.folder, refImName));
            end

            % set the record image if not set
            if isempty(obj.recImage)
                [recImName, ~] = uigetfile({'*.jpg;*.png;*.tif', 'Image files'}, 'Select the record image', obj.folder);

                if recImName == 0
                    error('No record image selected');
                end

                obj.recImage = imadjust(imread(fullfile(obj.folder, recImName)));
                obj.mouse = findMouse(recImName);
                obj.session = findSession(recImName);
            end

            % try to load the object of this mouse if it exists
            try
                objMouse = load(fullfile(obj.folder, ['s',obj.mouse(2:end), '.mat'])).obj;
                obj.refPointsCoorPixel = objMouse.refPointsCoorPixel;
                obj.refPointsCoorReal = objMouse.refPointsCoorReal;
                obj.bregmaCoorPixel = objMouse.bregmaCoorPixel;
                obj.bregmaCoorReal = objMouse.bregmaCoorReal;
                obj.winCenterCoorPixel = objMouse.winCenterCoorPixel;
                obj.winCenterCoorReal = objMouse.winCenterCoorReal;
                obj.controlPointsRefInitial = objMouse.controlPointsRefInitial;
                obj.controlPointsRef = objMouse.controlPointsRef;
                obj.SelectRefPoints = objMouse.SelectRefPoints;
                fprintf('Load information from %s\n', [obj.mouse, '.mat']);
            catch
                % do nothing
            end

            % enhance the contrast of the reference image for better visualization when cpselect
            obj.refImage = rgb2hsv(obj.refImage);
            obj.refImage(:, :, 3) = histeq(obj.refImage(:, :, 3));
            obj.refImage = hsv2rgb(obj.refImage);

            % transform the coordinates
            obj = obj.TransformCoor();
            % convert the unit
            obj = obj.ConvertUnit();
            % save the Transformer
            obj.Save();

        end

        function obj = TransformCoor(obj)
            % perform the transformation
            [obj.controlPointsRec, obj.controlPointsRef] = cpselect(obj.recImage, obj.refImage, obj.controlPointsRecInitial, obj.controlPointsRefInitial, 'Wait', true);
            obj.controlPointsRefInitial = obj.controlPointsRef;
            obj.controlPointsRecInitial = obj.controlPointsRec;

            try % for matlab 2022b and later
                obj.transformer = fitgeotform2d(obj.controlPointsRec, obj.controlPointsRef, "similarity");
            catch % for matlab 2022b and earlier
                obj.transformer = fitgeotrans(obj.controlPointsRec, obj.controlPointsRef, "nonreflectivesimilarity");
            end

            obj.recImageRecovered = imwarp(obj.recImage, obj.transformer, 'OutputView', imref2d(size(obj.refImage)));
            figure('Name', 'Check the recovered image');
            imshowpair(obj.refImage, obj.recImageRecovered, 'falsecolor');

        end

        function obj = ConvertUnit(obj, options)

            arguments
                obj
                options.overwriteFlag (1, 1) logical = false
            end

            obj.objSelectRefPoints.figH = uifigure('Name', 'Select reference points');
            obj.objSelectRefPoints.gl = uigridlayout(obj.objSelectRefPoints.figH, [3, 2]);
            obj.objSelectRefPoints.gl.ColumnWidth = {'1x', '1x'};
            obj.objSelectRefPoints.gl.RowHeight = {20, 80, '1x'};
            obj.objSelectRefPoints.gl.Padding = [10, 10, 10, 10];
            obj.objSelectRefPoints.gl.BackgroundColor = [0.94, 0.94, 0.94];

            % create fugure elements
            obj.objSelectRefPoints.imAxes = uiaxes(obj.objSelectRefPoints.gl);
            obj.objSelectRefPoints.imAxes.Layout.Row = 3;
            obj.objSelectRefPoints.imAxes.Layout.Column = [1, 2];
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
            if options.overwriteFlag
                obj.refPointsCoorPixel = [];
            end

            if isempty(obj.refPointsCoorPixel)

                obj.objSelectRefPoints.refPoint1 = drawpoint(obj.objSelectRefPoints.imAxes, 'Color', 'r', 'Label', 'Ref1');
                obj.objSelectRefPoints.tbHref.Data{'Ref1', 'X(pixel)'} = obj.objSelectRefPoints.refPoint1.Position(1);
                obj.objSelectRefPoints.tbHref.Data{'Ref1', 'Y(pixel)'} = obj.objSelectRefPoints.refPoint1.Position(2);

                % get the reference point coordinate 2 in pixel
                obj.objSelectRefPoints.refPoint2 = drawpoint(obj.objSelectRefPoints.imAxes, 'Color', 'r', 'Label', 'Ref2');
                obj.objSelectRefPoints.tbHref.Data{'Ref2', 'X(pixel)'} = obj.objSelectRefPoints.refPoint2.Position(1);
                obj.objSelectRefPoints.tbHref.Data{'Ref2', 'Y(pixel)'} = obj.objSelectRefPoints.refPoint2.Position(2);

                % set obj.refPointsCoorPixel
                obj.refPointsCoorPixel{1} = obj.objSelectRefPoints.refPoint1.Position;
                obj.refPointsCoorPixel{2} = obj.objSelectRefPoints.refPoint2.Position;
            else
                % draw the reference points
                obj.objSelectRefPoints.refPoint1 = drawpoint(obj.objSelectRefPoints.imAxes, 'Position', obj.refPointsCoorPixel{1}, 'Color', 'r', 'Label', 'Ref1');
                obj.objSelectRefPoints.refPoint2 = drawpoint(obj.objSelectRefPoints.imAxes, 'Position', obj.refPointsCoorPixel{2}, 'Color', 'r', 'Label', 'Ref2');
            end

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
            p2r = (r2x - r1x) / (p2x - p1x);
            coorMm(1) = r1x + (xyPixel(1) - p1x) * p2r;
            coorMm(2) = mean([r1y, r2y]) + (xyPixel(2) - mean([p1y, p2y])) * p2r;
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
            r2p = (p2x - p1x) / (r2x - r1x);
            coorPixel(1) = p1x + (xyMm(1) - r1x) * r2p;
            coorPixel(2) = mean([p1y, p2y]) + (xyMm(2) - mean([r1y, r2y])) * r2p;
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

        %% Save the object
        function obj = Save(obj, overwriteFlag)
            % check the overwrite flag
            if nargin == 1
                overwriteFlag = true;
            end

            % save the mouse specific object
            savePathMouse = fullfile(obj.folder, [obj.mouse(2:end), '.mat']);
            savePathMouseSession = fullfile(obj.folder, [obj.mouse, '_', obj.session, '.mat']);

            if ~isfile(savePathMouseSession) || overwriteFlag
                save(savePathMouseSession, 'obj');
                fprintf('The object is saved to %s\n', savePathMouseSession);
            end

            if ~isfile(savePathMouse) || overwriteFlag
                obj2 = copy(obj);
                obj2.recImage = [];
                obj2.recImageRecovered = [];
                obj2.controlPointsRec = [];
                obj2.transformer = [];
                obj2.objSelectRefPoints = [];
                a.obj = obj2;
                save(savePathMouse, '-struct','a','obj')
                fprintf('The object is saved to %s\n', savePathMouse);
            end

        end

        %% Load the object
        function obj = Load(obj, fileFilter)
            objPath = findFile(obj.folder, fileFilter);

            if height(objPath) == 1
                % load the object
                loadResult = load(objPath.path);
                obj = loadResult.obj;

                try % close the figure for reference points selection if it exists
                    close(obj.objSelectRefPoints.figH);
                end

            else
                error('The object does not exist or multiple objects are found');
            end

        end

    end

end
