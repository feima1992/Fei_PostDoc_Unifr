classdef regActRawClearSkull < handle

    properties
        images;
        flags;

        params; % parameters for GUI
        imREF; % reference image
        imACT; % ACT image
        baseFolder; % folder where the REF images are located
        baseName; % base name of the REF images, like m1221_230202

        objSliderL; % low limit of the contrast
        objSliderH; % high limit of the contrast
        objButtonReg; % button to register the images
        objButtonRegFlag; % flag = 1 if the button of registration is pressed
        objButtonLoadReg; % button to load the saved coordinates for registration

        P; % parameters for analysis
    end

    methods
        % constructor
        function obj = regActRawClearSkull(varargin)

            obj.objButtonRegFlag = 0; % set the REG button clicked flag to 0

            if isempty(varargin)
                [name, path] = uigetfile('*.tif', 'Select REF image');
                obj.imREF = fullfile(path, name);
                [name2, path2] = uigetfile('*.tif', 'Select ACT image');
                obj.imACT = fullfile(path2, name2);
                [name3, path3] = uigetfile('*.mat', 'Select parameters file');
                obj.P = load(fullfile(path3, name3), 'p');
            elseif length(varargin) == 2
                obj.imREF = varargin{1};
                obj.imACT = varargin{2};
                [name3, path3] = uigetfile('*.mat', 'Select parameters file');
                obj.P = load(fullfile(path3, name3), 'p');
            else
                obj.imREF = varargin{1};
                obj.imACT = varargin{2};
                obj.P = varargin{3};
            end

            obj.params.XYref = [[256 220]; [256 380]; [98 114]; [414 114]; [256 55]];
            obj.params.Npts = size(obj.params.XYref, 1);
            obj.params.XYrefCTX = obj.params.XYref;
            obj.params.cols = {[0.9 0.62 0], [0.34 0.71 0.91], [0 0.62 0.45], [0.94 0.89 0.26], [0 0.45 0.70], [0.84 0.37 0], [0.8 0.48 0.65]};
            obj.params.hXY = zeros(obj.params.Npts, 1);

            obj.params.IDselect = 0;
            obj.flags.CTXind = 0;

            [obj.baseFolder, obj.baseName, ~] = fileparts(obj.imREF);
            obj.baseName = replace(obj.baseName, '_REF', '');

            obj.images.IMctx = imread(obj.imREF);
            obj.images.IMctx = obj.images.IMctx(end:-1:1, end:-1:1);

            obj.images.IMctxV = imread(replace(obj.imREF, 'REF.tif', 'Refv.tif'));
            obj.images.IMctxV = obj.images.IMctxV(end:-1:1, end:-1:1);

            obj.images.IMact = imread(obj.imACT);

            obj.images.IMctxVREG = [];
            obj.images.IMctxREG = [];

            obj.params.Nx = size(obj.images.IMctx, 1);
            obj.params.Ny = size(obj.images.IMctx, 2);

            obj.images.ABM = imread(obj.P.path.abmTemplate);

            obj.params.Hfig = figure('Color', 'w', 'Name', 'WF registration', ...
                'DockControls', 'off', 'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'figure');
            addToolbarExplorationButtons(obj.params.Hfig)
            set(obj.params.Hfig, 'WindowButtonDownFcn', @obj.imageClick)
            set(obj.params.Hfig, 'WindowKeyReleaseFcn', @obj.imageKey)

            subplot(221)
            obj.params.hIMctx = imshow(obj.images.IMctx);
            hold on

            for k = 1:obj.params.Npts
                obj.params.hXY(k, 1) = plot(obj.params.XYref(k, 1), obj.params.XYref(k, 2), 'o', 'MarkerSize', 12, 'MarkerEdgeColor', 'none', 'MarkerFaceColor', obj.params.cols{k});
            end

            hold off
            obj.params.Hax_CTX = gca;

            subplot(222)
            obj.params.hIMctxREG = imshow(obj.images.IMctx);
            hold on
            ABM = zeros(obj.params.Nx, obj.params.Ny, 3);
            ABM(:, :, 1) = (2 ^ 16 - 1);
            ABM = uint16(ABM);
            h = imshow(ABM);
            set(h, 'AlphaData', ~obj.images.ABM)

            hold on

            for k = 1:obj.params.Npts
                plot(obj.params.XYref(k, 1), obj.params.XYref(k, 2), 'o', 'MarkerSize', 12, 'MarkerEdgeColor', 'none', 'MarkerFaceColor', obj.params.cols{k})
            end

            hold off
            obj.params.Hax_CTXreg = gca;

            subplot(223)
            imshow(obj.images.IMact)

            subplot(224)
            obj.params.hIMact = imshow(obj.images.IMact);
            hold on
            h = imshow(~obj.images.ABM);
            hold off
            set(h, 'AlphaData', ~obj.images.ABM)

            sgtitle(replace(obj.baseName, '_', '-'));

            p = uipanel(obj.params.Hfig, 'Position', [0.2 0.01 0.64 0.05]);

            uicontrol(p, 'Style', 'text', 'Position', [0, 2, 30, 10], 'String', 'Low', 'Units', 'normalized');
            obj.objSliderL = uicontrol(p, 'Style', 'slider', 'Position', [30, 2, 80, 15], 'Units', 'normalized');
            obj.objSliderL.String = 'lowLim';
            obj.objSliderL.Value = 0.4;
            obj.objSliderL.SliderStep = [0.01, 0.1];
            set(obj.objSliderL, 'Callback', @obj.setClimsCallback)

            uicontrol(p, 'Style', 'text', 'Position', [120, 2, 30, 10], 'String', 'High', 'Units', 'normalized');
            obj.objSliderH = uicontrol(p, 'Style', 'slider', 'Position', [150, 2, 80, 15], 'Units', 'normalized');
            obj.objSliderH.String = 'highLim';
            obj.objSliderH.Value = 0.7;
            obj.objSliderH.SliderStep = [0.01, 0.1];
            set(obj.objSliderH, 'Callback', @obj.setClimsCallback)

            obj.objButtonLoadReg = uicontrol(p, 'Style', 'pushbutton', 'Position', [280, 2, 20, 15], 'Units', 'normalized');
            obj.objButtonLoadReg.String = 'loadREG';
            set(obj.objButtonLoadReg, 'Callback', @obj.loadREGcoordsCallback);

            obj.objButtonReg = uicontrol(p, 'Style', 'pushbutton', 'Position', [320, 2, 20, 15], 'Units', 'normalized');
            obj.objButtonReg.String = 'REG IT';
            set(obj.objButtonReg, 'Callback', {@obj.affineRegisterCallback, 'affine'});

            % try auto load REGcoords
            try
                autoLoadREGcoords(obj);
                affineRegister(obj, 'affine');
                % pause 5 second to let user see the result
                pause(5);
                obj.objButtonRegFlag = 1;
            catch
            end

        end

        function imageClick(obj, src, evt)
            coor = get(obj.params.Hax_CTX, 'CurrentPoint');
            button = get(obj.params.Hfig, 'SelectionType');

            if strcmp(button, 'alt')
                obj.params.IDselect = mod(obj.params.IDselect + 1, obj.params.Npts + 1);

                for k = 1:obj.params.Npts
                    set(obj.params.hXY(k, 1), 'MarkerEdgeColor', 'none');
                end

                if obj.params.IDselect > 0
                    set(obj.params.hXY(obj.params.IDselect, 1), 'MarkerEdgeColor', 'w');
                end

            elseif strcmp(button, 'normal') && obj.params.IDselect > 0
                x = round(coor(1, 1));
                y = round(coor(1, 2));
                set(obj.params.hXY(obj.params.IDselect, 1), 'XData', x, 'YData', y);
                obj.params.XYrefCTX(obj.params.IDselect, 1) = x;
                obj.params.XYrefCTX(obj.params.IDselect, 2) = y;
            end

        end

        function imageKey(obj, src, evt)
            key = double(get(obj.params.Hfig, 'CurrentCharacter'));

            switch key
                case 31 % downArrow
                    obj.params.XYrefCTX(obj.params.IDselect, 2) = obj.params.XYrefCTX(obj.params.IDselect, 2) + 1;
                    set(obj.params.hXY(obj.params.IDselect, 1), 'YData', obj.params.XYrefCTX(obj.params.IDselect, 2));
                case 30 % upArrow
                    obj.params.XYrefCTX(obj.params.IDselect, 2) = obj.params.XYrefCTX(obj.params.IDselect, 2) - 1;
                    set(obj.params.hXY(obj.params.IDselect, 1), 'YData', obj.params.XYrefCTX(obj.params.IDselect, 2));
                case 29 % rightArrow
                    obj.params.XYrefCTX(obj.params.IDselect, 1) = obj.params.XYrefCTX(obj.params.IDselect, 1) + 1;
                    set(obj.params.hXY(obj.params.IDselect, 1), 'XData', obj.params.XYrefCTX(obj.params.IDselect, 1));
                case 28 % leftArrow
                    obj.params.XYrefCTX(obj.params.IDselect, 1) = obj.params.XYrefCTX(obj.params.IDselect, 1) - 1;
                    set(obj.params.hXY(obj.params.IDselect, 1), 'XData', obj.params.XYrefCTX(obj.params.IDselect, 1));
                case 116 % t
                    obj.flags.CTXind = ~obj.flags.CTXind;

                    if obj.flags.CTXind
                        set(obj.params.hIMctx, 'CData', obj.images.IMctxV);

                        if ~isempty(obj.images.IMctxVREG)
                            set(obj.params.hIMctxREG, 'CData', obj.images.IMctxVREG);
                        else
                            set(obj.params.hIMctxREG, 'CData', obj.images.IMctxV);
                        end

                    else
                        set(obj.params.hIMctx, 'CData', obj.images.IMctx);

                        if ~isempty(obj.images.IMctxREG)
                            set(obj.params.hIMctxREG, 'CData', obj.images.IMctxREG);
                        else
                            set(obj.params.hIMctxREG, 'CData', obj.images.IMctx);
                        end

                    end

                otherwise
            end

        end

        function setClimsCallback(obj, src, evt)
            limL = get(obj.objSliderL, 'Value');
            limH = get(obj.objSliderH, 'Value');
            setClims(obj, [limL * 5000, limH * 20000]);

        end

        function setClims(obj, Lims)
            set(obj.params.Hax_CTX, 'CLim', Lims);
            set(obj.params.Hax_CTXreg, 'CLim', Lims);
        end

        function affineRegisterCallback(obj, src, evt, type)
            affineRegister(obj, type);
            obj.objButtonRegFlag = 1;
        end

        function affineRegister(obj, type)
            %% register UI for peak act to visually check registration
            % 'affine' or 'pwl'
            tform = fitgeotrans(obj.params.XYrefCTX, obj.params.XYref, type);

            obj.images.IMactREG = imwarp(obj.images.IMact, tform, 'OutputView', imref2d(size(obj.images.IMact)));
            obj.images.IMctxREG = imwarp(obj.images.IMctx, tform, 'OutputView', imref2d(size(obj.images.IMctx)));
            obj.images.IMctxVREG = imwarp(obj.images.IMctxV, tform, 'OutputView', imref2d(size(obj.images.IMctxV)));

            set(obj.params.hIMact, 'CData', obj.images.IMactREG);

            if obj.flags.CTXind
                set(obj.params.hIMctxREG, 'CData', obj.images.IMctxVREG);
            else
                set(obj.params.hIMctxREG, 'CData', obj.images.IMctxREG);
            end

            obj.images.IMactREGexp = obj.images.IMactREG;

            for cIdx = 1:3
                tt = zeros(obj.params.Nx, obj.params.Ny);
                tt(:, :) = obj.images.IMactREGexp(:, :, cIdx);
                tt(~obj.images.ABM) = 2 ^ 8 - 1;
                obj.images.IMactREGexp(:, :, cIdx) = tt;
            end

            for indY = 1:obj.params.Ny
                indX = find(~obj.images.ABM(:, indY), 1);

                if isempty(indX)
                    indX = obj.params.Nx + 3;
                elseif indX == 1
                    indX = 4;
                end

                for cIdx = 1:3
                    obj.images.IMactREGexp(1:indX - 3, indY, cIdx) = 2 ^ 8 - 1;
                end

                indX = find(~obj.images.ABM(obj.params.Nx:-1:1, indY), 1);

                if isempty(indX)
                    indX = obj.params.Nx - 3;
                elseif indX == 1
                    indX = 4;
                end

                for cIdx = 1:3
                    obj.images.IMactREGexp(obj.params.Nx - indX + 4:obj.params.Nx, indY, cIdx) = 2 ^ 8 - 1;
                end

            end

            obj.images.IMactREGexp = imresize(obj.images.IMactREGexp, 1/2);
            
            XYrefCTX = obj.params.XYrefCTX;
            XYref = obj.params.XYref;
            regFile = fullfile(obj.P.dir.regXy, [obj.baseName '_XYreg.mat']);

            % if regFile not exist, save it
            if ~exist(regFile, 'file')
                save(regFile, 'XYrefCTX', 'XYref');
            end
            
            %% register all frames of act
            S = load(strrep(obj.imACT,'tif','mat'));

            param = S.P;
            t = S.t;
            imMask = S.imMask;

            IMcorr = S.IMcorr;
            IMcorrREG = zeros(size(IMcorr));

            for iFrame = 1:size(IMcorr, 3)
                IMcorrREG(:, :, iFrame) = imwarp(IMcorr(:, :, iFrame), tform, 'OutputView', imref2d(size(IMcorr(:, :, iFrame))));
            end

            imMaskREG = imwarp(imMask, tform, 'OutputView', imref2d(size(imMask)));

            % finally save all the data to actREG.mat
            save(strrep(strrep(obj.imACT,'Raw','Reg'),'ACT.tif','REG.mat'), 'IMcorrREG', 'param', 't', 'imMaskREG');
        end

        function loadREGcoordsCallback(obj, src, evt)
            loadREGcoords(obj)
        end

        function loadREGcoords(obj)
            [~, dfname] = fileparts(obj.imREF);
            dfname = replace(dfname, '_REF', '_XYreg.mat');
            dfname = fullfile(obj.P.dir.regXy, dfname);
            [fname, pname] = uigetfile('*.mat', 'Pick CTX reference coordinates', dfname);

            if fname == 0
                return
            else
                S = load([pname fname]);
                obj.params.XYrefCTX = S.XYrefCTX;
                obj.params.XYref = S.XYref;

                for k = 1:size(obj.params.XYrefCTX, 1)
                    set(obj.params.hXY(k, 1), 'YData', obj.params.XYrefCTX(k, 2));
                    set(obj.params.hXY(k, 1), 'XData', obj.params.XYrefCTX(k, 1));
                end

            end

        end

        function autoLoadREGcoords(obj)
            [~, dfname] = fileparts(obj.imREF);
            dfname = replace(dfname, '_REF', '_XYreg.mat');
            dfname = fullfile(obj.P.dir.regXy, dfname);
            S = load(dfname);
            obj.params.XYrefCTX = S.XYrefCTX;
            obj.params.XYref = S.XYref;

            for k = 1:size(obj.params.XYrefCTX, 1)
                set(obj.params.hXY(k, 1), 'YData', obj.params.XYrefCTX(k, 2));
                set(obj.params.hXY(k, 1), 'XData', obj.params.XYrefCTX(k, 1));
            end

        end

    end

end
