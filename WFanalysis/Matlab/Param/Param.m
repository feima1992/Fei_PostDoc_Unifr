classdef Param < handle

    properties
        folderUser
        folderParent
        folderFigure
        folderName
        dataDrive
        select
        wfAlign
    end

    properties (Dependent)
        folderWf
        dir
        path

    end

    methods

        function obj = Param(varargin)
            %% parse input
            p = inputParser;
            addParameter(p, 'folderName', 'newAnalysis', @ischar);
            addParameter(p, 'mouse', '', @(X)ischar(X) | isstring(X) | iscellstr(X));
            addParameter(p, 'session', '', @(X)ischar(X) | isstring(X) | iscellstr(X) | isnumeric(X));
            parse(p, varargin{:});

            %% generate parameters structure

            %% data analysis folder
            fullPath = mfilename('fullpath');
            fullPath = strsplit(fullPath, '\');
            obj.folderUser = fullfile(fullPath{1:3});
            obj.folderParent = fullfile(obj.folderUser, 'DataAnalysis');
            obj.folderFigure = fullfile(obj.folderUser, 'DataAnalysis', 'Figures');
            obj.folderName = p.Results.folderName;

            %% select mouse and session
            obj.select.mouse = p.Results.mouse;

            if isnumeric(p.Results.session)
                obj.select.session = cellstr(string(p.Results.session));
            else
                obj.select.session = p.Results.session;
            end

            %% widefield alignment
            obj.wfAlign.reUseMask = true;
            obj.wfAlign.alignWin = [-1, 1.5]; % window for alignment, relative to the trigger onset
            obj.wfAlign.frameRate = 20; % frame rate of the WF video
            obj.wfAlign.frameTime = obj.wfAlign.alignWin(1):1 / obj.wfAlign.frameRate:obj.wfAlign.alignWin(2); % time line of the aligned WF video
        end

        %% Get methods for dependent properties
        % folderPath
        function folderWf = get.folderWf(obj)
            folderWf = fullfile(obj.folderUser, 'DataAnalysis', 'Wf', obj.folderName);
        end

        % dir
        function dir = get.dir(obj)

            dir.bp = fullfile(obj.folderUser, 'Bpod\Bpod Local\Data\'); % directory of bpod data
            dir.refImage = fullfile(obj.folderParent, 'Utilities\RefImage'); % directory of reference images
            dir.coorTransformImage = fullfile(obj.folderParent, 'Utilities\CoorTransformWF'); % directory of coordinate transformation images
            dir.regXy = fullfile(obj.folderParent, 'Utilities\RegXy'); % directory of coordinate registration files
            dir.actMap.raw = fullfile(obj.folderWf, 'ActMap\Raw'); % directory of activation maps: raw
            dir.actMap.reg = fullfile(obj.folderWf, 'ActMap\Reg'); % directory of activation maps: registered
        end

        % path
        function path = get.path(obj)
            path.abmTemplate = fullfile(obj.folderParent, 'Utilities', 'ABMTemplate.tif'); % path of the template for allen mouse brain atlas
            path.roiMaskForAlignTrig = fullfile(obj.folderParent, 'Utilities', 'roiMask.mat'); % path of the mask for ROI analysis
            path.fileTableTifWfTemp = fullfile(obj.folderParent, 'Utilities', 'fileTableTifWfTemp.txt'); % path of temporary widefield video file information table
        end

        %% creat folder
        function CreatDir(obj)
            %% creat obj.dir folders if not exist
            if ~exist(obj.folderWf, 'dir')
                mkdir(obj.folderWf);
            end

            dirPath = nestStruct2table(obj.dir).value;

            for i = 1:length(dirPath)

                if ~exist(dirPath{i}, 'dir')
                    mkdir(dirPath{i});
                end

            end

        end

    end

end
